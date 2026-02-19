module rv_datapath_ctrl #(
    parameter int AW = 32
) (
    input  logic [AW-1:0] i,
    input  logic          equal_flag,
    output logic [1:0]    aluop,
    output logic          branch,
    output logic          memread,
    output logic          memtoreg,
    output logic          memwrite,
    output logic          alusrc,
    output logic          regwrite,
    output logic          if_flush
);

always_comb begin
    case (i[6:0])
        7'b0010011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop} = 8'b10100000; // I-type
        7'b0110011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop} = 8'b00100010; // R-type
        7'b0000011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop} = 8'b11110000; // ld (I-type LOAD)
        7'b0100011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop} = 8'b1x001000; // sd (S-type)
        7'b1100011: {alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop} = 8'b0x000101; // beq (B-type)
        default:    {alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop} = 8'd0;
    endcase
end

assign if_flush = equal_flag && branch;  // Flush IFID registers to stall with NOP

endmodule
