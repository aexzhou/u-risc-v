//----------------------------------------------------------------------
// Verilator stub implementation of UVM HDL backdoor access functions.
// Verilator does not support VPI-based HDL backdoor access, so these
// functions return failure (0) unconditionally.
//----------------------------------------------------------------------

#include "uvm_dpi.h"

int uvm_hdl_check_path(char *path) {
    return 0;
}

int uvm_hdl_read(char *path, p_vpi_vecval value) {
    return 0;
}

int uvm_hdl_deposit(char *path, p_vpi_vecval value) {
    return 0;
}

int uvm_hdl_force(char *path, p_vpi_vecval value) {
    return 0;
}

int uvm_hdl_release_and_read(char *path, p_vpi_vecval value) {
    return 0;
}

int uvm_hdl_release(char *path) {
    return 0;
}
