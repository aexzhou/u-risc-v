module rv_idu #(
    parameter int DW = 64
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

    // To IFU (control feedback)
    output logic [DW-1:0]  pc_plus_shimm,
    output logic           pc_write,
    output logic           ifid_write,
    output logic           if_flush,

    // ID/EX pipeline register outputs (to EXU)
    output logic [DW-1:0]  idex_imm,
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

logic [DW-1:0] imm, sh_imm;
logic          hazard_flag, equal_flag;
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

// Branch target: immediate left-shifted by 1 + ifid_pc
assign sh_imm        = {imm[DW-2:0], 1'b0};
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
    .opcode     (ifid_opcode),
    .equal_flag (equal_flag),
    .alu_op     (alu_op),
    .branch     (branch),
    .memread    (memread),
    .memtoreg   (memtoreg),
    .memwrite   (memwrite),
    .alusrc     (alusrc),
    .regwrite   (regwrite),
    .if_flush   (if_flush)
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

logic mwb_regwrite_non_x0;
logic forward_mwb_to_rs1, forward_mwb_to_rs2;

assign mwb_regwrite_non_x0 = mwb_regwrite && (mwb_rd != 0);
assign forward_mwb_to_rs1 = mwb_regwrite_non_x0 && (mwb_rd == ifid_rs1);
assign forward_mwb_to_rs2 = mwb_regwrite_non_x0 && (mwb_rd == ifid_rs2);

assign id_rs1_val = forward_mwb_to_rs1 ? write_data : regout1;
assign id_rs2_val = forward_mwb_to_rs2 ? write_data : regout2;

rv_hdu u_hdu (
    .ifid_rs1    (ifid_rs1),
    .ifid_rs2    (ifid_rs2),
    .idex_rd     (idex_rd),
    .mem_read    (idex_memread),
    .pc_write    (pc_write),
    .ifid_write  (ifid_write),
    .hazard_flag (hazard_flag)
);

// Early branch resolution: compare the two source registers (held in idex_a/b)
assign equal_flag = (id_rs1_val == id_rs2_val);

// ID/EX pipeline registers
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        idex_rs1        <= '0;
        idex_rs2        <= '0;
        idex_rd         <= '0;
        idex_a          <= '0;
        idex_b          <= '0;
        idex_alucontrol <= '0;
        idex_imm        <= '0;
        {idex_regwrite, idex_memtoreg, idex_branch,
         idex_memread,  idex_memwrite, idex_alusrc, idex_alu_op} <= '0;
    end else begin
        idex_rs1        <= ifid_rs1;
        idex_rs2        <= ifid_rs2;
        idex_rd         <= ifid_rd;
        idex_a          <= id_rs1_val;
        idex_b          <= id_rs2_val;
        idex_alucontrol <= {ifid_invert_op, ifid_funct3};
        idex_imm        <= imm;

        // Insert bubble (NOP) on load-use hazard
        if (hazard_flag)
            {idex_regwrite, idex_memtoreg, idex_branch,
             idex_memread,  idex_memwrite, idex_alusrc, idex_alu_op} <= '0;
        else
            {idex_regwrite, idex_memtoreg, idex_branch,
             idex_memread,  idex_memwrite, idex_alusrc, idex_alu_op}
                <= {regwrite, memtoreg, branch, memread, memwrite, alusrc, alu_op};
    end
end

endmodule : rv_idu
