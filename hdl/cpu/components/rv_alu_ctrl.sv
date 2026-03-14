/* ALU Control Module
 *
 * Provides ALU with the right operation by judging
 * the inputs from the Control Unit and Instructions.
 * This is useful since it lessens the load on the Control Module
 * and reducing its latency thus decreasing clk cycle time.
 */

/*
* alu-op values simplified:
* 2'b00 -> I type
* 2'b01 -> B type
* 2'b10 -> R type
* 2'b11 -> LOAD/STORE address (always ADD)
*/

module rv_alu_ctrl(control, alu_op, opout);
   import rv_alu_types::*;
    input [3:0] control;     // 32-bit instruction input (funct7 bit)
    input [1:0] alu_op;      // 2-bit alu_op from the Control Module, values specified above
    output alu_op_e opout;   // 4-bit output towards the actual ALU for computation
    wire [2:0] funct3;
    assign funct3 = control[2:0];

    always_comb begin
        if      (alu_op == 2'b11)                                           opout = ALU_ADD; // LOAD/STORE address
        else if (alu_op == 2'b01)                                           opout = ALU_SUB; // sub (beq)
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b000)    opout = ALU_ADD; // add(r)
        else if (alu_op == 2'b10 && control[3] == 1 && funct3 == 3'b000)    opout = ALU_SUB; // sub
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b111)    opout = ALU_AND; // and
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b110)    opout = ALU_OR;  // or
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b001)    opout = ALU_SLL; // sll
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b101)    opout = ALU_SRL; // srl
        else if (alu_op == 2'b10 && control[3] == 1 && funct3 == 3'b101)    opout = ALU_SRA; // sra
        else if (alu_op == 2'b10 && funct3 == 3'b100 && control[3] == 0)    opout = ALU_XOR; // xor
		else if (alu_op == 2'b10 && funct3 == 3'b010 && control[3] == 0)    opout = ALU_SLT;  // slt
		else if (alu_op == 2'b10 && funct3 == 3'b011 && control[3] == 0)    opout = ALU_SLTU; // sltu
        else if (alu_op == 2'b00 && funct3 == 3'b000)                       opout = ALU_ADD; // addi
        else if (alu_op == 2'b00 && funct3 == 3'b001)                       opout = ALU_SLL; // slli
        else if (alu_op == 2'b00 && funct3 == 3'b010)                       opout = ALU_SLT; // slti
        else if (alu_op == 2'b00 && funct3 == 3'b011)                       opout = ALU_SLTU; // sltiu
        else if (alu_op == 2'b00 && funct3 == 3'b101 && control[3] == 0)    opout = ALU_SRL; // srli
        else if (alu_op == 2'b00 && funct3 == 3'b101 && control[3] == 1)    opout = ALU_SRA; // srai
        else if (alu_op == 2'b00 && funct3 == 3'b111)                       opout = ALU_AND; // andi
        else if (alu_op == 2'b00 && funct3 == 3'b110)                       opout = ALU_OR;  // ori
        else if (alu_op == 2'b00 && funct3 == 3'b100)                       opout = ALU_XOR; // xori
	
        else                                                                opout = alu_op_e'(4'bxxxx);
    end
endmodule
