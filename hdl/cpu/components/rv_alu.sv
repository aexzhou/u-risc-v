// alu_op inputs
// 4'b0000: AND
// 4'b0001: OR
// 4'b0010: ADD
// 4'b0110: SUB
// 4'b0111: SLT (Set on Less Than): will output 1 if A < B
// 4'b1100: NOR

// TODO: Define enums for these ops

module rv_alu #(
    parameter int DW = 32
) (
    input  logic [DW-1:0] in1,
    input  logic [DW-1:0] in2,
    input  logic [3:0]    alu_op,
    output logic [DW-1:0] out,
    output logic          zflag
);

always_comb begin
    case (alu_op)
        4'b0000: out = in1 & in2;
        4'b0001: out = in1 | in2;
        4'b0010: out = in1 + in2;
        4'b0110: out = in1 - in2;
        4'b0111: out = {{DW-1{1'b0}}, (in1 < in2)};  // SLT
        4'b1100: out = ~(in1 | in2);                 // NOR
        default: out = {DW{1'bx}};
    endcase

    zflag = (out == '0);  // Zero flag
end

endmodule
