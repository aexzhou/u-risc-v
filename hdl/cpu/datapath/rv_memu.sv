module rv_memu #(
    parameter int DW         = 64,
    parameter int DMEM_DEPTH = 256
) (
    input  logic           clk,
    input  logic           rst_n,

    // EX/MEM pipeline register inputs (from EXU)
    input  logic [DW-1:0]  exm_aluout,
    input  logic [DW-1:0]  exm_pc_plus_shimm,
    input  logic [DW-1:0]  exm_muxb,
    input  logic [4:0]     exm_rd,
    input  logic           exm_regwrite,
    input  logic           exm_memtoreg,
    input  logic           exm_branch,
    input  logic           exm_branch_taken,
    input  logic           exm_memread,
    input  logic           exm_memwrite,
    input  logic           exm_zflag,

    // MEM/WB pipeline register outputs (to WBU and IDU/EXU)
    output logic [DW-1:0]  mwb_dout,
    output logic [DW-1:0]  mwb_aluout,
    output logic [4:0]     mwb_rd,
    output logic           mwb_regwrite,
    output logic           mwb_memtoreg
);

mem #(.DEPTH(DMEM_DEPTH), .DW(DW)) u_dmem (
    .clk        (clk),
    .address    (exm_aluout),
    .write_data (exm_muxb),
    .mem_read   (exm_memread),
    .mem_write  (exm_memwrite),
    .read_data  (mwb_dout)
);

// MEM/WB pipeline registers
dffr #(.DW(DW)) u_mwb_aluout_r  (.clk(clk), .rst_n(rst_n), .din(exm_aluout),   .dout(mwb_aluout));
dffr #(.DW(5))  u_mwb_rd_r      (.clk(clk), .rst_n(rst_n), .din(exm_rd),       .dout(mwb_rd));
dffr #(.DW(1))  u_mwb_regwrite_r(.clk(clk), .rst_n(rst_n), .din(exm_regwrite), .dout(mwb_regwrite));
dffr #(.DW(1))  u_mwb_memtoreg_r(.clk(clk), .rst_n(rst_n), .din(exm_memtoreg), .dout(mwb_memtoreg));

endmodule : rv_memu
