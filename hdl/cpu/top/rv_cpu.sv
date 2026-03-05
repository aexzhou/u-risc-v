/*
 * rv_cpu.sv
 *
 * 5-stage pipelined RISC-V CPU:
 *   IF -> ID -> EX -> MEM -> WB
 *
 */

module rv_cpu #(
    parameter int DW         = 64,
    parameter int IMEM_DEPTH = 256,
    parameter int DMEM_DEPTH = 256
) (
    input logic clk,
    input logic rst_n
);

// =========================================================================
// Inter-stage signals
// =========================================================================

// IFU <-> IDU
logic [DW-1:0] ifid_pc;
logic [31:0]   ifid_i;
logic [DW-1:0] pc_plus_shimm;
logic          pc_write, pc_src, ifid_write, if_flush;

// IDU -> EXU (ID/EX pipeline registers)
logic [DW-1:0] idex_imm, idex_a, idex_b;
logic [4:0]    idex_rs1, idex_rs2, idex_rd;
logic          idex_regwrite, idex_memtoreg, idex_branch;
logic          idex_memread, idex_memwrite, idex_alusrc;
logic [1:0]    idex_alu_op;
logic [3:0]    idex_alucontrol;

// EXU -> MEMU (EX/MEM pipeline registers)
logic [DW-1:0] exm_aluout, exm_muxb;
logic [4:0]    exm_rd;
logic          exm_regwrite, exm_memtoreg, exm_branch;
logic          exm_memread, exm_memwrite, exm_zflag;

// MEMU -> WBU (MEM/WB pipeline registers)
logic [DW-1:0] mwb_dout, mwb_aluout;
logic [4:0]    mwb_rd;
logic          mwb_regwrite, mwb_memtoreg;

// WBU -> IDU/EXU
logic [DW-1:0] write_data;

// =========================================================================
// Stage instantiations
// =========================================================================

rv_ifu #(.DW(DW), .IMEM_DEPTH(IMEM_DEPTH)) u_ifu (
    .clk           (clk),
    .rst_n         (rst_n),
    .pc_write      (pc_write),
    .pc_src        (pc_src),
    .ifid_write    (ifid_write),
    .if_flush      (if_flush),
    .pc_plus_shimm (pc_plus_shimm),
    .ifid_pc       (ifid_pc),
    .ifid_i        (ifid_i)
);

rv_idu #(.DW(DW)) u_idu (
    .clk            (clk),
    .rst_n          (rst_n),
    .ifid_i         (ifid_i),
    .ifid_pc        (ifid_pc),
    .write_data     (write_data),
    .mwb_rd         (mwb_rd),
    .mwb_regwrite   (mwb_regwrite),
    .pc_plus_shimm  (pc_plus_shimm),
    .pc_write       (pc_write),
    .ifid_write     (ifid_write),
    .if_flush       (if_flush),
    .idex_imm       (idex_imm),
    .idex_a         (idex_a),
    .idex_b         (idex_b),
    .idex_rs1       (idex_rs1),
    .idex_rs2       (idex_rs2),
    .idex_rd        (idex_rd),
    .idex_regwrite  (idex_regwrite),
    .idex_memtoreg  (idex_memtoreg),
    .idex_branch    (idex_branch),
    .idex_memread   (idex_memread),
    .idex_memwrite  (idex_memwrite),
    .idex_alusrc    (idex_alusrc),
    .idex_alu_op    (idex_alu_op),
    .idex_alucontrol(idex_alucontrol)
);

rv_exu #(.DW(DW)) u_exu (
    .clk            (clk),
    .rst_n          (rst_n),
    .idex_imm       (idex_imm),
    .idex_a         (idex_a),
    .idex_b         (idex_b),
    .idex_rs1       (idex_rs1),
    .idex_rs2       (idex_rs2),
    .idex_rd        (idex_rd),
    .idex_regwrite  (idex_regwrite),
    .idex_memtoreg  (idex_memtoreg),
    .idex_branch    (idex_branch),
    .idex_memread   (idex_memread),
    .idex_memwrite  (idex_memwrite),
    .idex_alusrc    (idex_alusrc),
    .idex_alu_op    (idex_alu_op),
    .idex_alucontrol(idex_alucontrol),
    .write_data     (write_data),
    .mwb_rd         (mwb_rd),
    .mwb_regwrite   (mwb_regwrite),
    .exm_aluout     (exm_aluout),
    .exm_muxb       (exm_muxb),
    .exm_rd         (exm_rd),
    .exm_regwrite   (exm_regwrite),
    .exm_memtoreg   (exm_memtoreg),
    .exm_branch     (exm_branch),
    .exm_memread    (exm_memread),
    .exm_memwrite   (exm_memwrite),
    .exm_zflag      (exm_zflag)
);

rv_memu #(.DW(DW), .DMEM_DEPTH(DMEM_DEPTH)) u_memu (
    .clk            (clk),
    .rst_n          (rst_n),
    .exm_aluout     (exm_aluout),
    .exm_muxb       (exm_muxb),
    .exm_rd         (exm_rd),
    .exm_regwrite   (exm_regwrite),
    .exm_memtoreg   (exm_memtoreg),
    .exm_branch     (exm_branch),
    .exm_memread    (exm_memread),
    .exm_memwrite   (exm_memwrite),
    .exm_zflag      (exm_zflag),
    .pc_src         (pc_src),
    .mwb_dout       (mwb_dout),
    .mwb_aluout     (mwb_aluout),
    .mwb_rd         (mwb_rd),
    .mwb_regwrite   (mwb_regwrite),
    .mwb_memtoreg   (mwb_memtoreg)
);

rv_wbu #(.DW(DW)) u_wbu (
    .mwb_dout     (mwb_dout),
    .mwb_aluout   (mwb_aluout),
    .mwb_memtoreg (mwb_memtoreg),
    .write_data   (write_data)
);

endmodule
