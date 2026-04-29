; =============================================================================
; tcl_windows.iss  --  Inno Setup script for the Tcl/Tk Windows installer
;
; All version-specific values are supplied as /D defines by the GitHub Action
; so this file needs no edits when the Tcl/Tk version changes.
;
; Required defines (pass with ISCC /Dname=value):
;   MyAppVersion   - full version string, e.g. 9.1.a1
;   MyMajorMinor   - major.minor only,    e.g. 9.1
;   MyInstallDir   - staging tree root,   e.g. C:\Tcl-tk
;   MyIconFile     - path to tclsh.ico,   e.g. tcl9.1a1/win/tclsh.ico
; =============================================================================

#ifndef MyAppVersion
  #error MyAppVersion must be defined with /DMyAppVersion=<version>
#endif
#ifndef MyMajorMinor
  #error MyMajorMinor must be defined with /DMyMajorMinor=<major.minor>
#endif
#ifndef MyInstallDir
  #error MyInstallDir must be defined with /DMyInstallDir=<path>
#endif
#ifndef MyIconFile
  #error MyIconFile must be defined with /DMyIconFile=<path to tclsh.ico>
#endif
#ifndef MyAppGuid
  #error MyIconFile must be defined with /DMyIconFile=<path to tclsh.ico>
#endif

; ---------------------------------------------------------------------------
; Product identity
; ---------------------------------------------------------------------------
#define MyAppName        "Tcl/Tk"
#define MyPublisher      "Tcl Community Association"
#define MyAppURL         "https://www.tcl-lang.org"
#define MyTclshExe       "tclsh" + StringChange(MyMajorMinor, ".", "") + ".exe"

[Setup]
AppId                    = {#MyAppGuid}
AppName                  = {#MyAppName}
AppVersion               = {#MyAppVersion}
AppPublisher             = {#MyPublisher}
AppPublisherURL          = {#MyAppURL}
AppSupportURL            = {#MyAppURL}
AppUpdatesURL            = {#MyAppURL}

; Install into %LOCALAPPDATA%\Tcl-Tk\<major.minor>
DefaultDirName           = {localappdata}\Tcl-Tk\{#MyMajorMinor}
DefaultGroupName         = Tcl-Tk {#MyMajorMinor}
DisableProgramGroupPage  = no
DisableWelcomePage       = no

; Output
OutputDir                = Output
OutputBaseFilename       = Tcl-Tk-{#MyAppVersion}-win64-setup
SetupIconFile            = {#MyIconFile}

; Target 64-bit Windows only
ArchitecturesAllowed     = x64compatible
ArchitecturesInstallIn64BitMode = x64compatible

; Compression
Compression              = lzma2/ultra64
SolidCompression         = yes

; Allow silent install (requirement 7 / Microsoft Store)
; Usage: setup.exe /SILENT or /VERYSILENT
AllowNoIcons             = yes

; Minimum OS: Windows 10
MinVersion               = 10.0

; Privilege level: install per-user into %LOCALAPPDATA%, no admin required
PrivilegesRequired       = lowest
PrivilegesRequiredOverridesAllowed = dialog

; Upgrade / reinstall behaviour:
;   - Same AppId + same AppVersion  -> offer Repair / Reinstall
;   - Same AppId + different version -> leave existing in place (side-by-side
;     is natural because the install path embeds the version number)
UsePreviousAppDir        = yes

; ---------------------------------------------------------------------------
; Languages
; ---------------------------------------------------------------------------
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

; ---------------------------------------------------------------------------
; File sources
; Note: {#MyInstallDir} is the staging tree built by the GitHub Action.
;       The {app} destination maps to the versioned install root.
; ---------------------------------------------------------------------------
[Files]
; --- bin ---
Source: "{#MyInstallDir}\bin\*"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs

; --- include ---
Source: "{#MyInstallDir}\include\*"; DestDir: "{app}\include"; Flags: ignoreversion recursesubdirs

; --- lib (files and subdirectories) ---
Source: "{#MyInstallDir}\lib\*"; DestDir: "{app}\lib"; Flags: ignoreversion recursesubdirs createallsubdirs

; ---------------------------------------------------------------------------
; Start menu shortcuts  (all optional -- user can deselect the group)
; ---------------------------------------------------------------------------
[Icons]
; tclsh console shell
Name: "{group}\Tcl Shell (tclsh {#MyMajorMinor})"; \
      Filename: "{app}\bin\{#MyTclshExe}"; \
      IconFilename: "{app}\bin\{#MyTclshExe}"; \
      Comment: "Tcl interactive shell"

; Desktop shortcuts (optional component, see [Components])
Name: "{userdesktop}\Tcl Shell {#MyMajorMinor}"; \
      Filename: "{app}\bin\{#MyTclshExe}"; \
      IconFilename: "{app}\bin\{#MyTclshExe}"; \
      Comment: "Tcl interactive shell"; \
      Tasks: desktopicon_tclsh

; ---------------------------------------------------------------------------
; Optional tasks presented to the user during setup
; ---------------------------------------------------------------------------
[Tasks]
; Desktop icon for tclsh
Name: "desktopicon_tclsh"; \
      Description: "Create a &desktop shortcut for Tcl Shell (tclsh)"; \
      GroupDescription: "Additional shortcuts:"; \
      Flags: unchecked

; PATH modification
Name: "modifypath"; \
      Description: "Add Tcl/Tk &bin directory to the PATH"; \
      GroupDescription: "Environment:"; \
      Flags: checkedonce

; .tcl file association
Name: "assoc_tcl"; \
      Description: "Associate .&tcl files with tclsh"; \
      GroupDescription: "File associations:"; \
      Flags: unchecked

; ---------------------------------------------------------------------------
; Registry entries
; ---------------------------------------------------------------------------
[Registry]
; --- PATH modification (reversible) ---
; Per-user install: write to HKCU.  The Check function skips this when
; running elevated (admin install uses the HKLM entry below instead).
Root: HKCU; Subkey: "Environment"; \
      ValueType: expandsz; ValueName: "Path"; \
      ValueData: "{olddata};{app}\bin"; \
      Check: NeedsAddPathUser(ExpandConstant('{app}\bin')); \
      Tasks: modifypath; \
      Flags: preservestringtype

; All-users install: write to HKLM system PATH instead.  The Check function
; skips this when NOT running elevated.
Root: HKLM; \
      Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; \
      ValueType: expandsz; ValueName: "Path"; \
      ValueData: "{olddata};{app}\bin"; \
      Check: NeedsAddPathSystem(ExpandConstant('{app}\bin')); \
      Tasks: modifypath; \
      Flags: preservestringtype

; --- .tcl file association ---
Root: HKCU; Subkey: "Software\Classes\.tcl"; \
      ValueType: string; ValueName: ""; ValueData: "TclFile"; \
      Tasks: assoc_tcl; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\TclFile"; \
      ValueType: string; ValueName: ""; ValueData: "Tcl Script"; \
      Tasks: assoc_tcl; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\TclFile\DefaultIcon"; \
      ValueType: string; ValueName: ""; \
      ValueData: "{app}\bin\{#MyTclshExe},0"; \
      Tasks: assoc_tcl; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\TclFile\shell\open\command"; \
      ValueType: string; ValueName: ""; \
      ValueData: """{app}\bin\{#MyTclshExe}"" ""%1"" %*"; \
      Tasks: assoc_tcl; Flags: uninsdeletekey

; ---------------------------------------------------------------------------
; Add/Remove Programs registration
; (Inno Setup fills in most fields automatically; we add the extras here.)
; ---------------------------------------------------------------------------
; AppId above drives the Uninstall registry key.
; Publisher, URLs, and version are set in [Setup] and appear automatically.
; The entries below add the optional fields required or recommended for the
; Microsoft Store MSI/EXE submission checklist.

; ---------------------------------------------------------------------------
; Pascal script helpers
; ---------------------------------------------------------------------------
[Code]

const
  SMTO_ABORTIFHUNG = 2;
  WM_SETTINGCHANGE = $001A;

function SendMessageTimeout(hWnd: LongWord; Msg: LongWord; wParam: LongWord;
  lParam: LongWord; fuFlags: LongWord; uTimeout: LongWord;
  var lpdwResult: LongWord): LongWord;
  external 'SendMessageTimeoutW@user32.dll stdcall';

// NeedsAddPathUser: returns True when NOT running in admin install mode and the given
// directory is not already on the user PATH (HKCU).
function NeedsAddPathUser(Param: string): Boolean;
var
  OrigPath: string;
begin
  if IsAdminInstallMode then
  begin
    Result := False;
    Exit;
  end;
  if not RegQueryStringValue(HKCU, 'Environment', 'Path', OrigPath) then
  begin
    Result := True;
    Exit;
  end;
  Result := Pos(';' + Uppercase(Param) + ';', ';' + Uppercase(OrigPath) + ';') = 0;
end;

// NeedsAddPathSystem: returns True when running in admin install mode and the given
// directory is not already on the system PATH (HKLM).
function NeedsAddPathSystem(Param: string): Boolean;
var
  OrigPath: string;
  SubKey:   string;
begin
  if not IsAdminInstallMode then
  begin
    Result := False;
    Exit;
  end;
  SubKey := 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';
  if not RegQueryStringValue(HKLM, SubKey, 'Path', OrigPath) then
  begin
    Result := True;
    Exit;
  end;
  Result := Pos(';' + Uppercase(Param) + ';', ';' + Uppercase(OrigPath) + ';') = 0;
end;

// RemoveFromPath: called by the uninstaller to strip our entry from PATH.
procedure RemoveFromPath(PathToRemove: string);
var
  CurrentPath: string;
  NewPath:     string;
  P:           Integer;
  SubKey:      string;
  RootKey:     Integer;
begin
  if IsAdminInstallMode then
  begin
    RootKey := HKLM;
    SubKey  := 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';
  end
  else
  begin
    RootKey := HKCU;
    SubKey  := 'Environment';
  end;

  if not RegQueryStringValue(RootKey, SubKey, 'Path', CurrentPath) then
    Exit;

  PathToRemove := ';' + Uppercase(PathToRemove);
  NewPath      := ';' + CurrentPath;
  P            := Pos(PathToRemove, Uppercase(NewPath));
  if P > 0 then
  begin
    Delete(NewPath, P, Length(PathToRemove));
    // Remove leading semicolon we prepended
    if Copy(NewPath, 1, 1) = ';' then
      Delete(NewPath, 1, 1);
    RegWriteStringValue(RootKey, SubKey, 'Path', NewPath);
  end;
end;

// CurUninstallStepChanged: clean up PATH, then check for user-added files.
// We check for leftover content *after* usUninstall (i.e. in usPostUninstall)
// so that anything remaining at that point is genuinely user-added -- the
// uninstaller has already removed every file it originally installed.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  AppDir: string;
begin
  case CurUninstallStep of
    usPostUninstall:
      begin
        // Remove bin dir from PATH
        RemoveFromPath(ExpandConstant('{app}\bin'));

        // If the installation directory still exists after the uninstaller has
        // finished, it must contain files that were not part of the original
        // install (e.g. user-installed Tcl packages).
        AppDir := ExpandConstant('{app}');
        if DirExists(AppDir) then
          MsgBox(
            'The installation directory still contains files that were not '
            + 'part of the original installation:' + #13#10 + AppDir + #13#10
            + #13#10
            + 'These files have not been removed. You may delete them manually.',
            mbInformation, MB_OK);
      end;
  end;
end;

// ---------------------------------------------------------------------------
// Final wizard page: show documentation URLs
// ---------------------------------------------------------------------------
var
  DocPage: TOutputMsgWizardPage;

procedure InitializeWizard;
begin
  // For all-users (admin) installs, default to 
  //    %PROGRAMFILES%\Tcl-Tk\<ver> - C:\Program Files\Tcl-Tk\<ver>
  // rather than the per-user %LOCALAPPDATA% path set in [Setup].
  if IsAdminInstallMode then
    WizardForm.DirEdit.Text :=
      ExpandConstant('{pf}\Tcl-Tk\{#MyMajorMinor}');

  DocPage := CreateOutputMsgPage(
    wpFinished,
    'Documentation and Resources',
    'Where to find Tcl/Tk documentation and community resources',
    'Tcl/Tk documentation and downloads:'       + #13#10
    + '  https://www.tcl-lang.org'              + #13#10
    + #13#10
    + 'Tcl/Tk community wiki:'                  + #13#10
    + '  https://wiki.tcl-lang.org'             + #13#10
    + #13#10
    + 'HTML documentation and man pages are not included in this installer. '
    + 'Please visit the URLs above to access the full documentation online.'
  );
end;

procedure BroadcastEnvironmentChange;
var
  Dummy: LongWord;
  EnvStr: string;
begin
  EnvStr := 'Environment';
  SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0,
    CastStringToInteger(EnvStr), SMTO_ABORTIFHUNG, 5000, Dummy);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    if IsTaskSelected('modifypath') then
      BroadcastEnvironmentChange;
end;

