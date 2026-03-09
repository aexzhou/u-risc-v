module rv_exu #(
    parameter int DW = 64
) (
    input  logic           clk,
    input  logic           rst_n,

    // ID/EX pipeline register inputs (from IDU)
    input  logic [DW-1:0]  idex_imm,
    input  logic [DW-1:0]  idex_pc_plus_shimm,
    input  logic [DW-1:0]  idex_a,
    input  logic [DW-1:0]  idex_b,
    input  logic [4:0]     idex_rs1,
    input  logic [4:0]     idex_rs2,
    input  logic [4:0]     idex_rd,
    input  logic           idex_regwrite,
    input  logic           idex_memtoreg,
    input  logic           idex_branch,
    input  logic           idex_branch_negate,
    input  logic           idex_memread,
    input  logic           idex_memwrite,
    input  logic           idex_alusrc,
    input  logic [1:0]     idex_alu_op,
    input  logic [3:0]     idex_alucontrol,

    // From WBU (for forwarding mux)
    input  logic [DW-1:0]  write_data,
    input  logic [4:0]     mwb_rd,
    input  logic           mwb_regwrite,

    // EX/MEM pipeline register outputs (to MEMU)
    output logic [DW-1:0]  exm_aluout,
    output logic [DW-1:0]  exm_pc_plus_shimm,
    output logic [DW-1:0]  exm_muxb,
    output logic [4:0]     exm_rd,
    output logic           exm_regwrite,
    output logic           exm_memtoreg,
    output logic           exm_branch,
    output logic           exm_branch_negate,
    output logic           exm_memread,
    output logic           exm_memwrite,
    output logic           exm_zflag
);

logic [1:0]    forward_a, forward_b;
logic [DW-1:0] alu_a, alu_b, idex_muxb;
logic [3:0]    alu_ctrl;
logic [DW-1:0] alu_out;
logic          zflag;

// Forward MUX for Rs1
always_comb begin
    case (forward_a)
        2'b00:   alu_a = idex_a;
        2'b01:   alu_a = write_data;
        2'b10:   alu_a = exm_aluout;
        default: alu_a = {DW{1'bx}};
    endcase
end

// Forward MUX for Rs2
always_comb begin
    case (forward_b)
        2'b00:   idex_muxb = idex_b;
        2'b01:   idex_muxb = write_data;
        2'b10:   idex_muxb = exm_aluout;
        default: idex_muxb = {DW{1'bx}};
    endcase
end

// Immediate MUX (selects ALU second operand)
assign alu_b = idex_alusrc ? idex_imm : idex_muxb;

rv_alu_ctrl u_alu_ctrl (
    .control (idex_alucontrol),
    .alu_op  (idex_alu_op),
    .opout   (alu_ctrl)
);

rv_alu #(.DW(DW)) u_alu (
    .in1    (alu_a),
    .in2    (alu_b),
    .alu_op (alu_ctrl),
    .out    (alu_out),
    .zflag  (zflag)
);

rv_fwdu u_fwdu (
    .idex_rs1     (idex_rs1),
    .idex_rs2     (idex_rs2),
    .exm_rd       (exm_rd),
    .exm_regwrite (exm_regwrite),
    .mwb_rd       (mwb_rd),
    .mwb_regwrite (mwb_regwrite),
    .forward_a    (forward_a),
    .forward_b    (forward_b)
);

// EX/MEM pipeline registers
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        exm_zflag  <= '0;
        exm_aluout <= '0;
        exm_pc_plus_shimm <= '0;
        exm_muxb   <= '0;
        exm_rd     <= '0;
        exm_branch_negate <= '0;
        {exm_regwrite, exm_memtoreg, exm_branch,
         exm_memread,  exm_memwrite} <= '0;
    end else begin
        exm_zflag  <= zflag;
        exm_aluout <= alu_out;
        exm_pc_plus_shimm <= idex_pc_plus_shimm;
        exm_muxb   <= idex_muxb;
        exm_rd     <= idex_rd;
        exm_branch_negate <= idex_branch_negate;
        {exm_regwrite, exm_memtoreg, exm_branch,
         exm_memread,  exm_memwrite}
            <= {idex_regwrite, idex_memtoreg, idex_branch,
                idex_memread,  idex_memwrite};
    end
end

endmodule : rv_exu
