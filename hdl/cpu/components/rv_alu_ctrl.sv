/* ALU Control Module
 *
 * Provides ALU with the right operation by judging
 * the inputs from the Control Unit and Instructions.
 * This is useful since it lessens the load on the Control Module
 * and reducing its latency thus decreasing clk cycle time.
 */

module rv_alu_ctrl(control, alu_op, opout);
/* Inputs towards the ALU:
 * ALU_AND (4'b0000): AND
 * ALU_OR  (4'b0001): OR
 * ALU_ADD (4'b0010): ADD
 * ALU_SUB (4'b0110): SUB
 * ALU_SLT (4'b0111): SLT (Set on Less Than): will output 1 if A < B
 * ALU_NOR (4'b1100): NOR
 */
    import rv_alu_types::*;
    input [3:0] control; // 32-bit instruction input (funct7 bit)
    input [1:0] alu_op; // 2-bit alu_op from the Control Module
    output alu_op_e opout; // 4-bit output towards the ALU
    wire [2:0] funct3;
    assign funct3 = control[2:0];

    always_comb begin
        if      (alu_op == 2'b01)                                           opout = ALU_SUB; // sub (beq)
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b000)    opout = ALU_ADD; // add(r)
        else if (alu_op == 2'b10 && control[3] == 1 && funct3 == 3'b000)    opout = ALU_SUB; // sub
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b111)    opout = ALU_AND; // and
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b110)    opout = ALU_OR;  // or
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b001)    opout = ALU_SLL; // sll
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b101)    opout = ALU_SRL; // srl
        else if (alu_op == 2'b10 && control[3] == 1 && funct3 == 3'b101)    opout = ALU_SRA; // sra
        else if (alu_op == 2'b00 && funct3 == 3'b001)                       opout = ALU_SLL; // slli
        else if (alu_op == 2'b00 && funct3 == 3'b101 && control[3] == 0)    opout = ALU_SRL; // srli
        else if (alu_op == 2'b00 && funct3 == 3'b101 && control[3] == 1)    opout = ALU_SRA; // srai
        else if (alu_op == 2'b00 && funct3 == 3'b000)                       opout = ALU_ADD; // addi
        else if (alu_op == 2'b00 && funct3 == 3'b111)                       opout = ALU_AND; // andi
        else if (alu_op == 2'b00 && funct3 == 3'b110)                       opout = ALU_OR;  // ori
        else if (alu_op == 2'b00)                                           opout = ALU_ADD; // add (I-type default)
        else if (alu_op == 2'b10 && funct3 == 3'b100 && control[3] == 0)    opout = ALU_XOR;
        else                                                                opout = alu_op_e'(4'bxxxx);
    end
endmodule
