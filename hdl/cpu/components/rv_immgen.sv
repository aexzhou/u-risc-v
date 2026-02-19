/* Immediate Generation Unit Module

 * Selects a 12-bit field for LOAD, STORE, and BRANCH IF EQUAL that is
 * sign-extended into a DW-bit result as output.

 * LW  = {offset[11:0],               src1[4:0], 3'b000, dest[4:0],      7'b0100000}
 * SW  = {offset[11:5],    src2[4:0], src1[4:0], 3'b000, dest[4:0],      7'b1000000}
 * BEQ = {offset[12,10:5], src2[4:0], src1[4:0], 3'b000, offset[4:1,11], 7'b1100000}
 */

/* Instruction Formats for RISC-V Architecture
 *
 * R-Type Instructions                                      I-Type Instructions
 * |31      25|24  20|19  15|14  12|11   7|6      0|        |31          20|19  15|14  12|11   7|6      0|
 * |  funct7  |  rs2 |  rs1 |func3 |  rd  | opcode |        |    imm[11:0] |  rs1 |func3 |  rd  | opcode |
 * Uses: R-R ops (add, sub, sll ...)                        Uses: Imm ops (addi, lw, srai ...)
 *
 * S-Type Instructions                                      B-Type Instructions
 * |31      25|24  20|19  15|14  12|11   7|6      0|        |31    25|24  20|19  15|14  12|11      7|6     0|
 * | imm[11:5]|  rs2 |  rs1 |func3 |imm[4:0]|opcode|        |imm[12| |  rs2 |  rs1 |func3 |imm[4:1| | opcode|
 * Uses: Store ops (sw, sh ...)                             |  10:5] |      |      |      |     11] |
 *                                                          Uses: Branch ops (beq, bne ...)
 *
 * U-Type Instructions                                      J-Type Instructions
 * |31              12|11   7|6      0|                     |31             12|11   7|6      0|
 * |      imm[31:12]  |  rd  | opcode |                     |     imm[20|10:1]|  rd  | opcode |
 * Uses: Long jumps and large constants (lui, auipc ...)    |       |11|19:12]|      |        |
 *                                                          Uses: Jump operations (jal ...)
 */

module rv_immgen #(
    parameter int DW = 32
) (
    input  logic [31:0]  in,       // 32-bit instruction input (RISC-V fixed width)
    output logic [DW-1:0] imm_out  // Sign-extended DW-bit immediate
);

always_comb begin
    case (in[6:0])
        7'b1101111: imm_out = DW'(signed'({ in[31], in[19:12], in[20], in[30:21], 1'b0 }));  // J-Type
        7'b1100111: imm_out = DW'(signed'(in[31:20]));                                        // I-Type JALR
        7'b0010011: imm_out = DW'(signed'(in[31:20]));                                        // I-Type imm
        7'b0000011: imm_out = DW'(signed'(in[31:20]));                                        // I-Type load
        7'b0100011: imm_out = DW'(signed'({ in[31:25], in[11:7] }));                          // S-Type
        7'b1100011: imm_out = DW'(signed'({ in[31], in[7], in[30:25], in[11:8], 1'b0 }));    // B-Type
        7'b0110111: imm_out = DW'(signed'({ in[31:12], 12'b0 }));                             // U-Type
        default:    imm_out = '0;
    endcase
end

endmodule
