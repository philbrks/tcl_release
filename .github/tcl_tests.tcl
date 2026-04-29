# tcl_package_checks.tcl -- Run inside tclsh by the installer test suite.
# Exit 0 on success, 1 on any failure.

set failed 0

# List of packages to verify.  Add new entries here as packages are added
# to the installer.
set packages {
    sqlite3
    thread
    tcl::zlib
    itcl
    dde
}

foreach pkg $packages {
    if {[catch {package require $pkg} ver]} {
        puts "FAIL: package require $pkg -> $ver"
        set failed 1
    } else {
        puts "PASS: package require $pkg -> $ver"
    }
}

exit $failed
