          # Tcl
          try {
            Push-Location ${{ env.TCL_BUILD_DIR }}\win
            &nmake -f makefile.vc release ${{ matrix.config }} INSTALLDIR=$Env:INSTALLDIR
            if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
            &nmake -f makefile.vc install ${{ matrix.config }} INSTALLDIR=$Env:INSTALLDIR
            if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
          }
          finally { Pop-Location }

          # Tk
          try {
            Push-Location ${{ env.TK_BUILD_DIR }}/win
            &nmake -f makefile.vc release ${{ matrix.config }} INSTALLDIR=$Env:INSTALLDIR TCLDIR=..\..\$Env:TCL_BUILD_DIR
            if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
            &nmake -f makefile.vc install ${{ matrix.config }} INSTALLDIR=$Env:INSTALLDIR TCLDIR=..\..\$Env:TCL_BUILD_DIR
            if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
          }
          finally { Pop-Location }

          # TDom
          try {
            Push-Location ${{ env.TDOM_BUILD_DIR }}/win
            &nmake -f makefile.vc ${{ matrix.config }} INSTALLDIR=$Env:INSTALLDIR TCLDIR=..\..\$Env:TCL_BUILD_DIR
            if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
            &nmake -f makefile.vc install ${{ matrix.config }} INSTALLDIR=$Env:INSTALLDIR TCLDIR=..\..\$Env:TCL_BUILD_DIR
            if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
          }
          finally { Pop-Location }

          # TclLib and TkLib
          try {
            & ${{ env.TCLSH }} ${{ env.TCLLIB_BUILD_DIR }}/installer.tcl -no-gui -no-html -no-examples -pkgs -pkg-path ${{ env.INSTALLDIR }}/lib -no-apps -no-nroff -no-wait
            if ($lastexitcode -ne 0) { throw "tcllib installer exit code: $lastexitcode" }
            & ${{ env.TCLSH }} ${{ env.TKLIB_BUILD_DIR }}/installer.tcl -no-gui -no-html -no-examples -pkgs -pkg-path ${{ env.INSTALLDIR }}/lib -no-apps -no-nroff -no-wait
            if ($lastexitcode -ne 0) { throw "tklib installer exit code: $lastexitcode" }
          }
          finally { Pop-Location }

          # TclTLS
          try {
            Push-Location ${{ env.TCLTLS_BUILD_DIR }}\win
            &nmake -f makefile.vc ${{ matrix.config }} SSL_INSTALL_FOLDER=${{ env.SSL_INSTALL_FOLDER }} TCLDIR=..\..\${{ env.TCL_BUILD_DIR }} INSTALLDIR=${{ env.INSTALLDIR }}
            if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
            &nmake -f makefile.vc install ${{ matrix.config }} SSL_INSTALL_FOLDER=$Env:SSL_INSTALL_FOLDER INSTALLDIR=$Env:INSTALLDIR TCLDIR=..\..\$Env:TCL_BUILD_DIR
            if ($lastexitcode -ne 0) { throw "nmake install exit code: $lastexitcode" }
          }
          finally { Pop-Location }

          # Tk-Img
          try {
            Push-Location  ${{ env.IMG_BUILD_DIR }}/win
            &nmake -f makefile.vc all ${{ matrix.config }} INSTALLDIR=$Env:INSTALLDIR TCLDIR=..\..\$Env:TCL_BUILD_DIR TKDIR=..\..\$Env:TK_BUILD_DIR
            if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
            &nmake -f makefile.vc install ${{ matrix.config }} INSTALLDIR=$Env:INSTALLDIR TCLDIR=..\..\$Env:TCL_BUILD_DIR TKDIR=..\..\$Env:TK_BUILD_DIR
            if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
          }
          finally { Pop-Location }

          # TkTable
          try {
              Push-Location "${{ env.TKTABLE_BUILD_DIR }}\win"
              Copy-Item ..\..\..\debug_file makefile.vc -ErrorAction Stop
              &nmake -f makefile.vc ${{ matrix.config }} INSTALLDIR=$Env:INSTALLDIR TCLDIR=..\..\$Env:TCL_BUILD_DIR
              if ($lastexitcode -ne 0) { throw "nmake exit code: $lastexitcode" }
          }
          finally {
              Pop-Location
          }

