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
    input  logic           id_flush,

    // To IFU/EXU (control feedback and branch target pipeline)
    output logic           pc_write,
    output logic           ifid_write,
    output logic           if_flush,

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
    output logic           idex_branch_taken,
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

// Control outputs
logic [1:0]    alu_op;
logic          branch, branch_taken, memread, memtoreg, memwrite, alusrc, regwrite;

// Branch target: immediate left-shifted by 1 + ifid_pc
assign sh_imm        = imm;
assign pc_plus_shimm = sh_imm + ifid_pc;

rv_immgen #(.DW(DW)) u_immgen (
    .in      (ifid_i),
    .imm_out (imm)
);

rv_datapath_ctrl #(
    .DW(DW)
) u_datapath_ctrl (
    .opcode             (ifid_i[6:0]),
    .funct3             (ifid_i[14:12]),
    .id_rs1_val         (id_rs1_val),
    .id_rs2_val         (id_rs2_val),
    .alu_op             (alu_op),
    .branch             (branch),
    .branch_taken       (branch_taken),
    .memread            (memread),
    .memtoreg           (memtoreg),
    .memwrite           (memwrite),
    .alusrc             (alusrc),
    .regwrite           (regwrite),
    .if_flush           (if_flush)
);

rv_regfile u_regfile (
    .rs1        (ifid_i[19:15]),
    .rs2        (ifid_i[24:20]),
    .writeR     (mwb_rd),
    .write_data (write_data),
    .write      (mwb_regwrite),
    .clk        (clk),
    .rst        (~rst_n),
    .data_out1  (regout1),
    .data_out2  (regout2)
);

assign id_rs1_val = regout1;
assign id_rs2_val = regout2;

rv_hdu u_hdu (
    .ifid_rs1    (ifid_i[19:15]),
    .ifid_rs2    (ifid_i[24:20]),
    .idex_rd     (idex_rd),
    .mem_read    (idex_memread),
    .pc_write    (pc_write),
    .ifid_write  (ifid_write),
    .hazard_flag (hazard_flag)
);

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
        idex_pc_plus_shimm <= '0;
        idex_branch_taken <= '0;
        {idex_regwrite, idex_memtoreg, idex_branch,
         idex_memread,  idex_memwrite, idex_alusrc, idex_alu_op} <= '0;
    end else begin
        if (id_flush) begin
            idex_rs1        <= '0;
            idex_rs2        <= '0;
            idex_rd         <= '0;
            idex_a          <= '0;
            idex_b          <= '0;
            idex_alucontrol <= '0;
            idex_imm        <= '0;
            idex_pc_plus_shimm <= '0;
            idex_branch_taken <= '0;
            {idex_regwrite, idex_memtoreg, idex_branch,
            idex_memread,  idex_memwrite, idex_alusrc, idex_alu_op} <= '0;
        end else begin
            idex_rs1        <= ifid_i[19:15];
            idex_rs2        <= ifid_i[24:20];
            idex_rd         <= ifid_i[11:7];
            idex_a          <= id_rs1_val;
            idex_b          <= id_rs2_val;
            idex_alucontrol <= {ifid_i[30], ifid_i[14:12]};
            idex_imm        <= imm;
            idex_pc_plus_shimm <= pc_plus_shimm;

            // Insert bubble (NOP) on load-use hazard
            if (hazard_flag) begin
                idex_branch_taken <= '0;
                {idex_regwrite, idex_memtoreg, idex_branch,
                idex_memread,  idex_memwrite, idex_alusrc, idex_alu_op} <= '0;
            end else begin
                idex_branch_taken <= branch_taken;
                {idex_regwrite, idex_memtoreg, idex_branch,
                idex_memread,  idex_memwrite, idex_alusrc, idex_alu_op}
                    <= {regwrite, memtoreg, branch, memread, memwrite, alusrc, alu_op};
            end
        end
    end
end

endmodule : rv_idu
