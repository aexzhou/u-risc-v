// Verilator-compatible wrapper that compiles all UVM DPI sources.
//
// Key points:
//   - Everything must have C linkage (extern "C") because Verilator's
//     generated DPI wrappers call these symbols with C linkage.
//   - uvm_dpi.h must be included INSIDE the extern "C" block so that
//     its declarations match the definitions' linkage.
//   - Standard C++ headers go outside (they carry their own guards).

#include <climits>
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <sys/types.h>

extern "C" {

#include "svdpi.h"
#include "vpi_user.h"

#include "uvm_common.c"
#include "uvm_svcmd_dpi.c"
#include "uvm_hdl_verilator.c"
#include "uvm_regex.cc"

} // extern "C"
