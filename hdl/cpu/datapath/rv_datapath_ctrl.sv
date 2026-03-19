module rv_datapath_ctrl (
    input  logic [6:0]    opcode,
    output logic [1:0]    alu_op,
    output logic          branch,
    output logic          memread,
    output logic          memtoreg,
    output logic          memwrite,
    output logic          alusrc,
    output logic          regwrite,
    output logic          ecall
);

always_comb begin
    ecall = 1'b0;
    case (opcode)
        7'b0010011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b10100000; // I-type
        7'b0110011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b00100010; // R-type
        7'b0000011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b11110011; // I-type: LOAD instructions
        7'b0100011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b1x001011; // S-type
        7'b1100011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'b0x000101; // B-type
        7'b1110011: begin // SYSTEM (ecall)
            {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'd0;
            ecall = 1'b1;
        end
        default:    {alusrc, memtoreg, regwrite, memread, memwrite, branch, alu_op} = 8'd0;
    endcase
end


endmodule
