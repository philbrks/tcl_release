if (!$Env:INSTALLDIR) {
    Set-Item -Path "Env:INSTALLDIR" -Value "C:\Tcl-Tk"
    if (Test-Path -Path $Env:INSTALLDIR) {
	throw "INSTALLDIR $Env:INSTALLDIR already exists.  Please set Env:INSTALLDIR to a directory name that does not exist."
    }
}
if (! $Env:SSL_INSTALL_FOLDER) {
    Set-Item -Path "Env:SSL_INSTALL_FOLDER" -Value "C:\OpenSSL"
}
if (!(Test-Path -Path $Env:SSL_INSTALL_FOLDER)) {
    throw "SSL_INSTALL_FOLDER $Env:SSL_INSTALL_FOLDER does not exist.  An OpenSSL installation is necessecary for this build."
}

$varsFile = "build-vars.json"
if ($env:TCL_BUILD_DIR) {
    echo "Using Env:TCL_BUILD_DIR=$Env:TCL_BUILD_DIR"
} elseif (Test-Path -Path "$varsFile" -PathType Leaf) {
    echo "Loading build variables from $varsFile"
    if (-not (Test-Path $varsFile)) {
      throw "Build vars file not found: $varsFile"
    }
    $vars = Get-Content $varsFile | ConvertFrom-Json 
    foreach ($prop in $vars.PSObject.Properties) {
      echo "Setting $($prop.Name)=$($prop.Value)"
      Set-Item -Path "Env:$($prop.Name)" -Value $($prop.Value)
    }
}
echo "INSTALLDIR=$Env:INSTALLDIR"
echo "TCLSH=$Env:TCLSH"
echo "TCL_BUILD_DIR=$Env:TCL_BUILD_DIR"
echo "SSL_INSTALL_FOLDER=$Env:SSL_INSTALL_FOLDER"

New-Item -Path $Env:INSTALLDIR -ItemType Directory -Force | Out-Null

if (Test-Path -Path $Env:INSTALLDIR -PathType Container) {
    Write-Host "$Env:INSTALLDIR Directory created successfully: $dirPath"
} else {
    throw "Failed to create directory: $dirPath"
}

# Tcl
dir
try {
  echo "Building Tcl and subprojects"
  Push-Location $Env:TCL_BUILD_DIR\win
  &nmake -f makefile.vc release $Env:BUILD_CONFIG INSTALLDIR=$Env:INSTALLDIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=$Env:INSTALLDIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally { Pop-Location }

# Tk
try {
  echo "Building Tk"
  Push-Location $Env:TK_BUILD_DIR/win
  pwd
  &nmake -f makefile.vc release $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally { Pop-Location }

# TDom
try {
  echo "Building TDom"
  Push-Location $Env:TDOM_BUILD_DIR/win
  &nmake -f makefile.vc $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally { Pop-Location }

# TclLib and TkLib
try {
  echo "Installing tcllib"
  & $Env:TCLSH $Env:TCLLIB_BUILD_DIR/installer.tcl -no-gui -no-html -no-examples -pkgs -pkg-path $Env:INSTALLDIR/lib -no-apps -no-nroff -no-wait
  if ($lastexitcode -ne 0) { throw "tcllib installer exit code: $lastexitcode" }
  echo "Installing tklib"
  & $Env:TCLSH $Env:TKLIB_BUILD_DIR/installer.tcl -no-gui -no-html -no-examples -pkgs -pkg-path $Env:INSTALLDIR/lib -no-apps -no-nroff -no-wait
  if ($lastexitcode -ne 0) { throw "tklib installer exit code: $lastexitcode" }
}
finally { Pop-Location }

# TclTLS
try {
  echo "Building TclTLS"
  Push-Location $Env:TCLTLS_BUILD_DIR\win
  &nmake -f makefile.vc $Env:BUILD_CONFIG SSL_INSTALL_FOLDER=$Env:SSL_INSTALL_FOLDER TCLDIR=..\..\$Env:TCL_BUILD_DIR INSTALLDIR=$Env:INSTALLDIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  &nmake -f makefile.vc install $Env:BUILD_CONFIG SSL_INSTALL_FOLDER=C:\OpenSSL INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake install exit code: $lastexitcode" }
}
finally { Pop-Location }

# Tk-Img
try {
  echo "Building Img"
  Push-Location  $Env:IMG_BUILD_DIR/win
  &nmake -f makefile.vc all $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR TKDIR=..\..\$Env:TK_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR TKDIR=..\..\$Env:TK_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally { Pop-Location }

# TkTable
try {
  echo "Building TkTable"
  Push-Location "$Env:TKTABLE_BUILD_DIR\win"
  &nmake -f makefile.vc $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR TKDIR=..\..\$Env:TK_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  echo "Installing TkTable"
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR TKDIR=..\..\$Env:TK_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally {
    Pop-Location
}

# TclUDP
try {
  echo "Building TclUDP"
  Push-Location "$Env:TCLUDP_BUILD_DIR\win"
  &nmake -f makefile.vc $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  echo "Installing TclUDP"
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally {
    Pop-Location
}

# TWAPI
try {
  echo "Building TWAPI"
  Push-Location "$Env:TWAPI_BUILD_DIR\win"
  &nmake -f makefile.vc $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  echo "Installing TWAPI"
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally {
    Pop-Location
}

# TKTREECTRL
try {
  echo "Building TkTreectrl"
  Push-Location "$Env:TKTREECTRL_BUILD_DIR\win"
  &nmake -f makefile.vc $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR TKDIR=..\..\$Env:TK_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  echo "Installing TkTreectrl"
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\$Env:TCL_BUILD_DIR TKDIR=..\..\$Env:TK_BUILD_DIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally {
    Pop-Location
}
