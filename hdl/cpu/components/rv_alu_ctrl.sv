/* ALU Control Module
 *
 * Provides ALU with the right operation by judging 
 * the inputs from the Control Unit and Instructions. 
 * This is useful since it lessens the load on the Control Module
 * and reducing its latency thus decreasing clk cycle time. 
 */
module rv_alu_ctrl(control, ALUop, opout);
/* Inputs towards the ALU:
 * 4'b0000: AND
 * 4'b0001: OR
 * 4'b0010: ADD
 * 4'b0110: SUB
 * 4'b0111: SLT (Set on Less Than): will output 1 if A < B
 * 4'b1100: NOR
 */
    input [3:0] control; // 32-bit instruction input 
    input [1:0] ALUop; // 2-bit ALUop from the Control Module
    output reg [3:0] opout; // 4-bit output towards the ALU
    wire [2:0] funct3;
    assign funct3 = control[2:0];

    always_comb begin
        casex({ALUop, control[3], funct3})
            7'b00x000: opout = 4'b0010; // addi
            7'b00x111: opout = 4'b0000; // andi
            7'b00x110: opout = 4'b0001; // ori
            7'b00xxxx: opout = 4'b0010; // add
            7'bx1xxxx: opout = 4'b0110; // sub
            7'b1x0000: opout = 4'b0010; // add(r)
            7'b1x1000: opout = 4'b0110; // sub
            7'b1x0111: opout = 4'b0000; // and
            7'b1x0110: opout = 4'b0001; // or
            default: opout = 4'bxxxx;
        endcase
    end
endmodule