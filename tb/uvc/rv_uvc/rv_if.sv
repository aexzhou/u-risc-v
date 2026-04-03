// RISC-V Interface
// Defines the interface between testbench and DUT

`ifndef RISCV_IF_SV
`define RISCV_IF_SV

interface riscv_if(input logic clk);

    // Primary signals
    logic rst;

    // Monitored signals from DUT
    logic [63:0] pc_out;
    logic [31:0] iMem_out;
    logic        pc_write;

    // Write-back stage signals
    logic        reg_write;
    logic [4:0]  wb_rd;
    logic [63:0] write_data;

    // Pipeline stage signals (for monitoring)
    logic [31:0] ifid_i;
    logic [63:0] ifid_pc;

    // Control signals
    logic        branch_taken;
    logic        mem_read;
    logic        mem_write;

    // Clocking block for driver
    clocking driver_cb @(posedge clk);
        output rst;
    endclocking

    // Clocking block for monitor
    clocking monitor_cb @(posedge clk);
        input pc_out;
        input iMem_out;
        input pc_write;
        input reg_write;
        input wb_rd;
        input write_data;
        input ifid_i;
        input ifid_pc;
    endclocking

    // Modports
    modport driver (clocking driver_cb, input clk, output rst);
    modport monitor (clocking monitor_cb, input clk, input rst);

endinterface

`endif // RISCV_IF_SV
