# test_installer.ps1 -- Automated test for the Tcl/Tk Windows installer.
#
# Expected environment variables (set by the GitHub Action):
#   TCL_VERSION      e.g. 9.1.a1
#   TCL_MAJOR_MINOR  e.g. 9.1
#   TCLSH            e.g. C:\Tcl-tk\bin\tclsh91.exe  (build-tree tclsh,
#                    used only to locate the installer-under-test; the
#                    installed tclsh is discovered from the PATH after install)

param()
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Fail([string]$msg) {
    Write-Error "FAIL: $msg"
    exit 1
}

function Pass([string]$msg) {
    Write-Host "PASS: $msg" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Derived paths
# ---------------------------------------------------------------------------
$MajorMinor  = $env:TCL_MAJOR_MINOR          # e.g. 9.1
$Version     = $env:TCL_VERSION              # e.g. 9.1.a1
$InstallRoot = "$env:LOCALAPPDATA\Tcl-Tk\$MajorMinor"
$TclshName   = "tclsh" + $MajorMinor.Replace(".", "") + ".exe"   # tclsh91.exe
$InstallerExe = ".github\Output\Tcl-Tk-$Version-win64-setup.exe"

# Path to the expected-files manifest (one relative path per line, # comments ok)
$ManifestPath = ".github\tcl_installer_files.txt"

# ---------------------------------------------------------------------------
# 0. Sanity-check: installer exists
# ---------------------------------------------------------------------------
if (-not (Test-Path $InstallerExe)) {
    Fail "Installer not found: $InstallerExe"
}
Pass "Installer found: $InstallerExe"

# ---------------------------------------------------------------------------
# 1. Run the installer silently (per-user, no elevation needed)
# ---------------------------------------------------------------------------
Write-Host "Running installer..."
$proc = Start-Process -FilePath $InstallerExe `
    -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" `
    -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Fail "Installer exited with code $($proc.ExitCode)"
}
Pass "Installer completed successfully"

# ---------------------------------------------------------------------------
# 2. Check expected files
# ---------------------------------------------------------------------------
Write-Host "Checking installed files..."
$manifest = Get-Content $ManifestPath |
    Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' }

$missingFiles = @()
foreach ($rel in $manifest) {
    $full = Join-Path $InstallRoot $rel.Trim()
    if (-not (Test-Path $full)) {
        $missingFiles += $rel.Trim()
    }
}
if ($missingFiles.Count -gt 0) {
    Fail "Missing installed files:`n  $($missingFiles -join "`n  ")"
}
Pass "All $($manifest.Count) expected files present"

# ---------------------------------------------------------------------------
# 3. Check PATH contains the bin directory
# ---------------------------------------------------------------------------
Write-Host "Checking user PATH..."
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$expectedBin = "$InstallRoot\bin"
if ($userPath -notlike "*$expectedBin*") {
    Fail "Bin directory not found in user PATH.`n  Expected: $expectedBin`n  PATH: $userPath"
}
Pass "Bin directory present in user PATH"

# ---------------------------------------------------------------------------
# 4. Invoke tclsh and run package checks
# ---------------------------------------------------------------------------
Write-Host "Running tclsh package checks..."

# Locate tclsh via PATH (proves PATH was set correctly)
$tclsh = (Get-Command $TclshName -ErrorAction SilentlyContinue)?.Source
if (-not $tclsh) {
    # Fall back: look directly in install dir (PATH refresh may lag in CI)
    $tclsh = Join-Path $InstallRoot "bin\$TclshName"
}
if (-not (Test-Path $tclsh)) {
    Fail "tclsh not found: $tclsh"
}
Pass "tclsh located: $tclsh"

$tclScript = ".github\tcl_package_checks.tcl"
$proc = Start-Process -FilePath $tclsh `
    -ArgumentList $tclScript `
    -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -ne 0) {
    Fail "tclsh package checks failed (exit code $($proc.ExitCode))"
}
Pass "All tclsh package checks passed"

# ---------------------------------------------------------------------------
# 5. Run the uninstaller silently
# ---------------------------------------------------------------------------
Write-Host "Running uninstaller..."
$uninstExe = Join-Path $InstallRoot "unins000.exe"
if (-not (Test-Path $uninstExe)) {
    Fail "Uninstaller not found: $uninstExe"
}
$proc = Start-Process -FilePath $uninstExe `
    -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" `
    -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Fail "Uninstaller exited with code $($proc.ExitCode)"
}
Pass "Uninstaller completed successfully"

# ---------------------------------------------------------------------------
# 6. Check PATH no longer contains the bin directory
# ---------------------------------------------------------------------------
Write-Host "Checking user PATH after uninstall..."
# Re-read from registry; the current process environment is stale.
$userPathAfter = (Get-ItemProperty `
    -Path 'HKCU:\Environment' `
    -Name 'Path' `
    -ErrorAction SilentlyContinue).Path
if ($userPathAfter -and ($userPathAfter -like "*$expectedBin*")) {
    Fail "Bin directory still present in user PATH after uninstall: $userPathAfter"
}
Pass "Bin directory removed from user PATH"

# ---------------------------------------------------------------------------
# 7. Check installed files have been removed
# ---------------------------------------------------------------------------
Write-Host "Checking files removed after uninstall..."
$remainingFiles = @()
foreach ($rel in $manifest) {
    $full = Join-Path $InstallRoot $rel.Trim()
    if (Test-Path $full) {
        $remainingFiles += $rel.Trim()
    }
}
if ($remainingFiles.Count -gt 0) {
    Fail "Files still present after uninstall:`n  $($remainingFiles -join "`n  ")"
}
Pass "All installed files removed"

# Optionally warn (not fail) if the install root itself still exists,
# since the user may have added files of their own.
if (Test-Path $InstallRoot) {
    Write-Warning "Install directory still exists (may contain user-added files): $InstallRoot"
} else {
    Pass "Install directory removed"
}

Write-Host ""
Write-Host "All installer tests passed." -ForegroundColor Green
