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
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mwb_aluout   <= '0;
        mwb_rd       <= '0;
        mwb_regwrite <= '0;
        mwb_memtoreg <= '0;
    end else begin
        mwb_aluout   <= exm_aluout;
        mwb_rd       <= exm_rd;
        mwb_regwrite <= exm_regwrite;
        mwb_memtoreg <= exm_memtoreg;
    end
end

endmodule : rv_memu
