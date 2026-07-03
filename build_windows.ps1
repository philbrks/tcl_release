mkdir "$Env:INSTALLDIR"
# Tcl
try {
  Push-Location $Env:TCL_BUILD_DIR\win
  &nmake -f makefile.vc release $Env:BUILD_CONFIG INSTALLDIR=$Env:INSTALLDIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=$Env:INSTALLDIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally { Pop-Location }

# Tk
try {
  Push-Location $Env:TK_BUILD_DIR/win
  &nmake -f makefile.vc release $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\tcl-main
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\tcl-main
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally { Pop-Location }

# TDom
try {
  Push-Location $Env:TDOM_BUILD_DIR/win
  &nmake -f makefile.vc $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\tcl-main
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\tcl-main
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally { Pop-Location }

# TclLib and TkLib
try {
  & $Env:TCLSH $Env:TCLLIB_BUILD_DIR/installer.tcl -no-gui -no-html -no-examples -pkgs -pkg-path $Env:INSTALLDIR/lib -no-apps -no-nroff -no-wait
  if ($lastexitcode -ne 0) { throw "tcllib installer exit code: $lastexitcode" }
  & $Env:TCLSH $Env:TKLIB_BUILD_DIR/installer.tcl -no-gui -no-html -no-examples -pkgs -pkg-path $Env:INSTALLDIR/lib -no-apps -no-nroff -no-wait
  if ($lastexitcode -ne 0) { throw "tklib installer exit code: $lastexitcode" }
}
finally { Pop-Location }

# TclTLS
try {
  Push-Location $Env:TCLTLS_BUILD_DIR\win
  &nmake -f makefile.vc $Env:BUILD_CONFIG SSL_INSTALL_FOLDER=$Env:SSL_INSTALL_FOLDER TCLDIR=..\..\$Env:TCL_BUILD_DIR INSTALLDIR=$Env:INSTALLDIR
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  &nmake -f makefile.vc install $Env:BUILD_CONFIG SSL_INSTALL_FOLDER=C:\OpenSSL INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\tcl-main
  if ($lastexitcode -ne 0) { throw "nmake install exit code: $lastexitcode" }
}
finally { Pop-Location }

# Tk-Img
try {
  Push-Location  $Env:IMG_BUILD_DIR/win
  &nmake -f makefile.vc all $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\tcl-main TKDIR=..\..\tk-main
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
  &nmake -f makefile.vc install $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\tcl-main TKDIR=..\..\tk-main
  if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally { Pop-Location }

# TkTable
try {
    Push-Location "$Env:TKTABLE_BUILD_DIR\win"
    # Copy-Item ..\..\..\debug_file makefile.vc -ErrorAction Stop
    &nmake -f makefile.vc $Env:BUILD_CONFIG INSTALLDIR=C:\Tcl-tk TCLDIR=..\..\tcl-main
    if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
}
finally {
    Pop-Location
}
