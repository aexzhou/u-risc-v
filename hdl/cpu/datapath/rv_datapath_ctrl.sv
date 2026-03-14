module rv_datapath_ctrl (
    input  logic [6:0]    opcode,
    output logic [1:0]    alu_op,
    output logic          branch,
    output logic          memread,
    output logic          memtoreg,
    output logic          memwrite,
    output logic          alusrc,
    output logic          regwrite
);

always_comb begin
    case (opcode)
        7'b0010011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b10100000; // I-type
        7'b0110011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b00100010; // R-type
        7'b0000011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b11110011; // I-type: LOAD instructions
        7'b0100011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b1x001011; // S-type
        7'b1100011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b0x000101; // B-type
        default:    {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'd0;
    endcase
end


endmodule
