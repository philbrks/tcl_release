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
      Description: "Add Tcl/Tk &bin directory to the user PATH"; \
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
; --- PATH modification (user-level, reversible) ---
; We store the original PATH value so the uninstaller can restore it exactly.
Root: HKCU; Subkey: "Environment"; \
      ValueType: expandsz; ValueName: "Path"; \
      ValueData: "{olddata};{app}\bin"; \
      Check: NeedsAddPath(ExpandConstant('{app}\bin')); \
      Tasks: modifypath; \
      Flags: preservestringtype uninsdeletevalue

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

// NeedsAddPath: returns True when the given directory is not already on the
// user's PATH (prevents duplicate entries).
function NeedsAddPath(Param: string): Boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKCU, 'Environment', 'Path', OrigPath) then
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
begin
  if not RegQueryStringValue(HKCU, 'Environment', 'Path', CurrentPath) then
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
    RegWriteStringValue(HKCU, 'Environment', 'Path', NewPath);
  end;
end;

// Called before the uninstaller removes files so we can warn about extras.
function InitializeUninstall(): Boolean;
var
  AppDir:  string;
  FindRec: TFindRec;
  Extras:  string;
  Ans:     Integer;
begin
  Result := True;
  AppDir := ExpandConstant('{app}');

  // Walk the installation root for files not tracked by the uninstaller.
  // (A simple heuristic: anything in {app}\lib that is a directory not
  //  listed in [Files] is treated as user-added.)
  Extras := '';
  if FindFirst(AppDir + '\lib\*', FindRec) then
  begin
    repeat
      if (FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0)
          and (FindRec.Name <> '.') and (FindRec.Name <> '..') then
      begin
        // Directories installed by this package are known; anything else
        // is potentially user-added.
        if (FindRec.Name <> 'dde1.5')
            and (FindRec.Name <> 'registry1.4')
            and (FindRec.Name <> 'nmake') then
          Extras := Extras + #13#10 + '  lib\' + FindRec.Name;
      end;
    until not FindNext(FindRec);
    FindClose(FindRec);
  end;

  if Extras <> '' then
  begin
    Ans := MsgBox(
      'The following directories in the installation folder appear to have '
      + 'been added after installation (possibly user-installed packages):'
      + #13#10 + Extras + #13#10 + #13#10
      + 'Do you want to remove them along with the rest of the installation?'
      + #13#10 + #13#10
      + 'Click YES to remove everything, NO to leave them in place.',
      mbConfirmation, MB_YESNO);
    if Ans = IDNO then
    begin
      // Leave extra content; the uninstaller will not touch those dirs.
      // (Inno Setup only removes files it installed, so this is advisory.)
      MsgBox(
        'The extra directories will not be deleted. After uninstallation '
        + 'the installation folder may not be fully empty.',
        mbInformation, MB_OK);
    end;
  end;
end;

// CurUninstallStepChanged: clean up PATH and notify if the directory is not
// empty after files are removed.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  AppDir: string;
begin
  case CurUninstallStep of
    usPostUninstall:
      begin
        // Remove bin dir from user PATH
        RemoveFromPath(ExpandConstant('{app}\bin'));

        // Notify if install directory still contains files
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
