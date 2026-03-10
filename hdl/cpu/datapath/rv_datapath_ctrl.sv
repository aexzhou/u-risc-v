module rv_datapath_ctrl (
    input  logic [6:0]    opcode,
    input  logic [2:0]    funct3,
    input  logic          equal_flag,
    input  logic          less_flag,
    input  logic          greater_eq_flag,
    input  logic          less_u_flag,
    input  logic          greater_eq_u_flag,
    output logic [1:0]    alu_op,
    output logic          branch,
    output logic          branch_taken,
    output logic          memread,
    output logic          memtoreg,
    output logic          memwrite,
    output logic          alusrc,
    output logic          regwrite,
    output logic          if_flush
);

always_comb begin
    case (opcode)
        7'b0010011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b10100000; // I-type
        7'b0110011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b00100010; // R-type
        7'b0000011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b11110000; // I-type: LOAD instructions
        7'b0100011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b1x001000; // S-type
        7'b1100011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b0x000101; // B-type
        default:    {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'd0;
    endcase
end

always_comb begin
    case (funct3)
        3'h0: branch_taken = equal_flag;        // beq
        3'h1: branch_taken = ~equal_flag;       // bne
        3'h4: branch_taken = less_flag;         // blt (signed)
        3'h5: branch_taken = greater_eq_flag;   // bge
        3'h6: branch_taken = less_u_flag;       // bltu
        3'h7: branch_taken = greater_eq_u_flag; // bgeu
        default: branch_taken = 1'b0;
    endcase
end

assign if_flush = branch && branch_taken;

endmodule
