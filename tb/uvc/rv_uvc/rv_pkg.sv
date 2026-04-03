// RISC-V UVM Package
// Includes all UVM components

`ifndef RISCV_PKG_SV
`define RISCV_PKG_SV

package riscv_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Include all testbench components
    `include "riscv_transaction.sv"
    `include "riscv_sequence.sv"
    `include "riscv_driver.sv"
    `include "riscv_monitor.sv"
    `include "riscv_scoreboard.sv"
    `include "riscv_agent.sv"
    `include "riscv_env.sv"
    `include "riscv_test.sv"

endpackage

`endif // RISCV_PKG_SV
