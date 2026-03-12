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
    input  logic           idex_branch_taken,
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
    output logic           exm_branch_taken,
    output logic           exm_memread,
    output logic           exm_memwrite,
    output logic           exm_zflag,

    output logic           pc_src,
    output logic [DW-1:0]  pc_branch_target
);

logic [1:0]    forward_a, forward_b;
logic [DW-1:0] alu_a, alu_b, idex_muxb;
logic [3:0]    alu_ctrl;
logic [DW-1:0] alu_out;
logic          zflag;
logic equal_flag;
logic less_flag;
logic greater_eq_flag;
logic unsigned_less_flag;
logic unsigned_greater_eq_flag;
logic branch_taken;

logic [2:0] funct3;
assign funct3 = idex_alucontrol[2:0];

assign pc_src = idex_branch & branch_taken;
assign pc_branch_target = idex_pc_plus_shimm;

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
    .zflag  (zflag),
    .equal_flag  (equal_flag),
    .less_flag  (less_flag),
    .greater_eq_flag  (greater_eq_flag),
    .unsigned_less_flag  (unsigned_less_flag),
    .unsigned_greater_eq_flag  (unsigned_greater_eq_flag)
);


always_comb begin
    case (funct3)
        3'h0: branch_taken = equal_flag;        // beq
        3'h1: branch_taken = ~equal_flag;       // bne
        3'h4: branch_taken = less_flag;         // blt (signed)
        3'h5: branch_taken = greater_eq_flag;   // bge
        3'h6: branch_taken = unsigned_less_flag;       // bltu
        3'h7: branch_taken = unsigned_greater_eq_flag; // bgeu
        default: branch_taken = 1'b0;
    endcase
end

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
dffr #(.DW(1))  u_exm_zflag_r        (.clk(clk), .rst_n(rst_n), .din(zflag),            .dout(exm_zflag));
dffr #(.DW(DW)) u_exm_aluout_r       (.clk(clk), .rst_n(rst_n), .din(alu_out),          .dout(exm_aluout));
dffr #(.DW(DW)) u_exm_pc_plus_shimm_r(.clk(clk), .rst_n(rst_n), .din(idex_pc_plus_shimm),.dout(exm_pc_plus_shimm));
dffr #(.DW(DW)) u_exm_muxb_r         (.clk(clk), .rst_n(rst_n), .din(idex_muxb),        .dout(exm_muxb));
dffr #(.DW(5))  u_exm_rd_r           (.clk(clk), .rst_n(rst_n), .din(idex_rd),          .dout(exm_rd));
dffr #(.DW(1))  u_exm_branch_taken_r (.clk(clk), .rst_n(rst_n), .din(branch_taken),     .dout(exm_branch_taken));
dffr #(.DW(1))  u_exm_regwrite_r     (.clk(clk), .rst_n(rst_n), .din(idex_regwrite),    .dout(exm_regwrite));
dffr #(.DW(1))  u_exm_memtoreg_r     (.clk(clk), .rst_n(rst_n), .din(idex_memtoreg),    .dout(exm_memtoreg));
dffr #(.DW(1))  u_exm_branch_r       (.clk(clk), .rst_n(rst_n), .din(idex_branch),      .dout(exm_branch));
dffr #(.DW(1))  u_exm_memread_r      (.clk(clk), .rst_n(rst_n), .din(idex_memread),     .dout(exm_memread));
dffr #(.DW(1))  u_exm_memwrite_r     (.clk(clk), .rst_n(rst_n), .din(idex_memwrite),    .dout(exm_memwrite));

endmodule : rv_exu
