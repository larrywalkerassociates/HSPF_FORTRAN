# HSPF 12.5 ifx build (Linux)

This repository was compiled with Intel oneAPI ifx using the Visual Studio
.vfproj source lists as the build reference.

## Environment
- Intel oneAPI ifx (source /opt/intel/oneapi/setvars.sh)
- Fortran flags: -assume byterecl -extend-source
- Static libraries built: util, adwdm, wdm, hspf125, hec, hspdss

## Build output
The compiled executable is:
- build_ifx_byterecl_wdopux_hspfext/bin/hspf12_5

Build artifacts (objects and static libs) are under
build_ifx_byterecl_wdopux_hspfext/{obj,lib,bin}.

## Run example
```
source /opt/intel/oneapi/setvars.sh
./build_ifx_byterecl_wdopux_hspfext/bin/hspf12_5 /path/to/your.uci
```
