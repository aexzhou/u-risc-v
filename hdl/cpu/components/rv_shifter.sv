/*
Shifter Module

Accomodates the following operations:

name | imm[11:5] | imm[4:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[5:0]
-----|-----------|----------|----------|-------------|---------|-------------
SLLI |  0000000  |  shift   |   src    | 101         |  dest   |
SRLI |  0000000  |   amt    |   reg    | 110         |   reg   |
SRAI |  0100000  |          |          | 111         |         |

*/

module rv_shifter #(
    parameter int DW = 32
) (
    input  logic [DW-1:0] in,
    input  logic [1:0]    shift,     // Shift operation
    output logic [DW-1:0] sout
);

    always_comb begin
        case (shift)
            2'b00: sout = in;                           // No shift
            2'b01: sout = in << 1;                      // Shift left by 1
            2'b10: sout = in >> 1;                      // Shift right logical by 1
            2'b11: sout = {in[DW-1], in[DW-1:1]};       // Shift right arithmetic by 1
            default: sout = {DW{1'bx}};
        endcase
    end

endmodule
