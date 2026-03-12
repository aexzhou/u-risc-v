module rv_datapath_ctrl #(
    parameter int DW = 64
) (
    input  logic [6:0]    opcode,
    input  logic [2:0]    funct3,
    input  logic [DW-1:0]        id_rs1_val,
    input  logic [DW-1:0]         id_rs2_val,
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

// logic equal_flag, less_flag, greater_eq_flag, less_u_flag, greater_eq_u_flag;

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

// always_comb begin
//     case (funct3)
//         3'h0: branch_taken = equal_flag;        // beq
//         3'h1: branch_taken = ~equal_flag;       // bne
//         3'h4: branch_taken = less_flag;         // blt (signed)
//         3'h5: branch_taken = greater_eq_flag;   // bge
//         3'h6: branch_taken = less_u_flag;       // bltu
//         3'h7: branch_taken = greater_eq_u_flag; // bgeu
//         default: branch_taken = 1'b0;
//     endcase
// end

// // Early branch resolution: compare the two source registers (held in idex_a/b)
// assign equal_flag        = (id_rs1_val == id_rs2_val); // FIXME: HERE, ID_RS1_VAL == ID_RS2_VAL CHECK? IF THIS DOESNT FIRE THEN THIS WONT EVENTUALLY TRIGGER PC_SRC!!!
// assign less_flag         = ($signed(id_rs1_val) < $signed(id_rs2_val));
// assign greater_eq_flag   = ($signed(id_rs1_val) >= $signed(id_rs2_val));
// assign less_u_flag       = id_rs1_val < id_rs2_val;
// assign greater_eq_u_flag = id_rs1_val >= id_rs2_val;

assign if_flush = branch && branch_taken;

endmodule
