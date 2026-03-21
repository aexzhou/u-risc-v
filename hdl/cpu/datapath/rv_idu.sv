module rv_idu #(
    parameter int DW = 32
) (
    input  logic           clk,
    input  logic           rst_n,

    // From IFU
    input  logic [31:0]    ifid_i,
    input  logic [DW-1:0]  ifid_pc,

    // From WBU (register file write-back)
    input  logic [DW-1:0]  write_data,
    input  logic [4:0]     mwb_rd,
    input  logic           mwb_regwrite,
    input  logic           id_flush,

    // To IFU/EXU (control feedback)
    output logic           pc_write,
    output logic           ifid_write,

    // ID/EX pipeline register outputs (to EXU)
    output logic [DW-1:0]  idex_imm,
    output logic [DW-1:0]  idex_pc_plus_shimm,
    output logic [DW-1:0]  idex_a,
    output logic [DW-1:0]  idex_b,
    output logic [4:0]     idex_rs1,
    output logic [4:0]     idex_rs2,
    output logic [4:0]     idex_rd,
    output logic           idex_regwrite,
    output logic           idex_memtoreg,
    output logic           idex_branch,
    output logic           idex_memread,
    output logic           idex_memwrite,
    output logic           idex_alusrc,
    output logic [1:0]     idex_alu_op,
    output logic [3:0]     idex_alucontrol
);

logic [DW-1:0] imm, sh_imm, pc_plus_shimm;
logic          hazard_flag;
logic [DW-1:0] regout1, regout2;
logic [DW-1:0] id_rs1_val, id_rs2_val;

logic [`RV32I_RD_WIDTH-1:0]     ifid_rd;
logic [`RV32I_RS1_WIDTH-1:0]    ifid_rs1;
logic [`RV32I_RS2_WIDTH-1:0]    ifid_rs2;
logic [`RV32I_FUNCT3_WIDTH-1:0] ifid_funct3;
logic [`RV32I_OPCODE_WIDTH-1:0] ifid_opcode;
logic                           ifid_invert_op;

// Control outputs
logic [1:0]    alu_op;
logic          branch, memread, memtoreg, memwrite, alusrc, regwrite;

logic mwb_regwrite_non_x0;
logic forward_mwb_to_rs1, forward_mwb_to_rs2;

assign mwb_regwrite_non_x0 = mwb_regwrite && (mwb_rd != 0);
assign forward_mwb_to_rs1 = mwb_regwrite_non_x0 && (mwb_rd == ifid_i[19:15]);
assign forward_mwb_to_rs2 = mwb_regwrite_non_x0 && (mwb_rd == ifid_i[24:20]);

assign id_rs1_val = forward_mwb_to_rs1 ? write_data : regout1;
assign id_rs2_val = forward_mwb_to_rs2 ? write_data : regout2;

// Branch target: immediate left-shifted by 1 + ifid_pc
assign sh_imm        = imm;
assign pc_plus_shimm = sh_imm + ifid_pc;

rv_immgen #(.DW(DW)) u_immgen (
    .in      (ifid_i),
    .imm_out (imm)
);

assign ifid_funct3 = ifid_i[(`RV32I_FUNCT3_WIDTH + `RV32I_FUNCT3_LSB_POS - 1) : `RV32I_FUNCT3_LSB_POS];
assign ifid_opcode = ifid_i[(`RV32I_OPCODE_WIDTH + `RV32I_OPCODE_LSB_POS - 1) : `RV32I_OPCODE_LSB_POS];
assign ifid_rd  = ifid_i[(`RV32I_RD_WIDTH + `RV32I_RD_LSB_POS - 1) : `RV32I_RD_LSB_POS];
assign ifid_rs1 = ifid_i[(`RV32I_RS1_WIDTH + `RV32I_RS1_LSB_POS - 1) : `RV32I_RS1_LSB_POS];
assign ifid_rs2 = ifid_i[(`RV32I_RS2_WIDTH + `RV32I_RS2_LSB_POS - 1) : `RV32I_RS2_LSB_POS];
assign ifid_invert_op = ifid_i[`RV32I_R_INVERT_OP_BIT_POS];


rv_datapath_ctrl u_datapath_ctrl (
    .opcode   (ifid_i[6:0]),
    .alu_op   (alu_op),
    .branch   (branch),
    .memread  (memread),
    .memtoreg (memtoreg),
    .memwrite (memwrite),
    .alusrc   (alusrc),
    .regwrite (regwrite)
);

rv_regfile u_regfile (
    .rs1        (ifid_rs1),
    .rs2        (ifid_rs2),
    .writeR     (mwb_rd),
    .write_data (write_data),
    .write      (mwb_regwrite),
    .clk        (clk),
    .rst        (~rst_n),
    .data_out1  (regout1),
    .data_out2  (regout2)
);

rv_hdu u_hdu (
    .ifid_rs1    (ifid_rs1),
    .ifid_rs2    (ifid_rs2),
    .idex_rd     (idex_rd),
    .mem_read    (idex_memread),
    .pc_write    (pc_write),
    .ifid_write  (ifid_write),
    .hazard_flag (hazard_flag)
);

// ID/EX pipeline registers
// Data path registers
dffr_sync_flush #(.DW(5))  u_idex_rs1_r        (.clk(clk), .rst_n(rst_n), .flush(id_flush), .din(ifid_i[19:15]),               .dout(idex_rs1));
dffr_sync_flush #(.DW(5))  u_idex_rs2_r        (.clk(clk), .rst_n(rst_n), .flush(id_flush), .din(ifid_i[24:20]),               .dout(idex_rs2));
dffr_sync_flush #(.DW(5))  u_idex_rd_r         (.clk(clk), .rst_n(rst_n), .flush(id_flush), .din(ifid_i[11:7]),                .dout(idex_rd));
dffr_sync_flush #(.DW(DW)) u_idex_a_r          (.clk(clk), .rst_n(rst_n), .flush(id_flush), .din(id_rs1_val),                  .dout(idex_a));
dffr_sync_flush #(.DW(DW)) u_idex_b_r          (.clk(clk), .rst_n(rst_n), .flush(id_flush), .din(id_rs2_val),                  .dout(idex_b));
dffr_sync_flush #(.DW(4))  u_idex_alucontrol_r (.clk(clk), .rst_n(rst_n), .flush(id_flush), .din({ifid_i[30], ifid_i[14:12]}), .dout(idex_alucontrol));
dffr_sync_flush #(.DW(DW)) u_idex_imm_r        (.clk(clk), .rst_n(rst_n), .flush(id_flush), .din(imm),                         .dout(idex_imm));
dffr_sync_flush #(.DW(DW)) u_idex_pcs_r        (.clk(clk), .rst_n(rst_n), .flush(id_flush), .din(pc_plus_shimm),               .dout(idex_pc_plus_shimm));

// Control registers. These are also flushed on hazard_flag to insert NOP bubbles
dffr_sync_flush #(.DW(1)) u_idex_regwrite_r     (.clk(clk), .rst_n(rst_n), .flush(id_flush | hazard_flag), .din(regwrite),     .dout(idex_regwrite));
dffr_sync_flush #(.DW(1)) u_idex_memtoreg_r     (.clk(clk), .rst_n(rst_n), .flush(id_flush | hazard_flag), .din(memtoreg),     .dout(idex_memtoreg));
dffr_sync_flush #(.DW(1)) u_idex_branch_r       (.clk(clk), .rst_n(rst_n), .flush(id_flush | hazard_flag), .din(branch),       .dout(idex_branch));
dffr_sync_flush #(.DW(1)) u_idex_memread_r      (.clk(clk), .rst_n(rst_n), .flush(id_flush | hazard_flag), .din(memread),      .dout(idex_memread));
dffr_sync_flush #(.DW(1)) u_idex_memwrite_r     (.clk(clk), .rst_n(rst_n), .flush(id_flush | hazard_flag), .din(memwrite),     .dout(idex_memwrite));
dffr_sync_flush #(.DW(1)) u_idex_alusrc_r       (.clk(clk), .rst_n(rst_n), .flush(id_flush | hazard_flag), .din(alusrc),       .dout(idex_alusrc));
dffr_sync_flush #(.DW(2)) u_idex_alu_op_r       (.clk(clk), .rst_n(rst_n), .flush(id_flush | hazard_flag), .din(alu_op),       .dout(idex_alu_op));

endmodule : rv_idu
