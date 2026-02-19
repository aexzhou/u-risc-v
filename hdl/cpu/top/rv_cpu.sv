module rv_cpu #(
    parameter int DW         = 64,
    parameter int IMEM_DEPTH = 256,
    parameter int DMEM_DEPTH = 256
) (
    input logic clk,
    input logic rst_n
);

rv_datapath #(
    .DW         (DW),
    .IMEM_DEPTH (IMEM_DEPTH),
    .DMEM_DEPTH (DMEM_DEPTH)
) u_datapath (
    .clk   (clk),
    .rst_n (rst_n)
);

endmodule
