/* ALU Control Module
 *
 * Provides ALU with the right operation by judging
 * the inputs from the Control Unit and Instructions.
 * This is useful since it lessens the load on the Control Module
 * and reducing its latency thus decreasing clk cycle time.
 */
module rv_alu_ctrl(control, alu_op, opout);
/* Inputs towards the ALU:
 * 4'b0000: AND
 * 4'b0001: OR
 * 4'b0010: ADD
 * 4'b0110: SUB
 * 4'b0111: SLT (Set on Less Than): will output 1 if A < B
 * 4'b1100: NOR
 */
    input [3:0] control; // 32-bit instruction input
    input [1:0] alu_op; // 2-bit alu_op from the Control Module
    output reg [3:0] opout; // 4-bit output towards the ALU
    wire [2:0] funct3;
    assign funct3 = control[2:0];

    always_comb begin
        if      (alu_op == 2'b01)                                           opout = 4'b0110; // sub (beq)
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b000)    opout = 4'b0010; // add(r)
        else if (alu_op == 2'b10 && control[3] == 1 && funct3 == 3'b000)    opout = 4'b0110; // sub
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b111)    opout = 4'b0000; // and
        else if (alu_op == 2'b10 && control[3] == 0 && funct3 == 3'b110)    opout = 4'b0001; // or
        else if (alu_op == 2'b00 && funct3 == 3'b000)                       opout = 4'b0010; // addi
        else if (alu_op == 2'b00 && funct3 == 3'b111)                       opout = 4'b0000; // andi
        else if (alu_op == 2'b00 && funct3 == 3'b110)                       opout = 4'b0001; // ori
        else if (alu_op == 2'b00)                                           opout = 4'b0010; // add (I-type default)
        else                                                                opout = 4'bxxxx;
    end
endmodule
