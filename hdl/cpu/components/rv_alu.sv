// alu_op inputs
// ALU_AND (4'b0000): AND
// ALU_OR  (4'b0001): OR
// ALU_ADD (4'b0010): ADD
// ALU_SUB (4'b0110): SUB
// ALU_SLT (4'b0111): SLT (Set on Less Than): will output 1 if A < B
// ALU_NOR (4'b1100): NOR

module rv_alu
    import rv_alu_types::*;
#(
    parameter int DW = 32
) (
    input  logic [DW-1:0] in1,
    input  logic [DW-1:0] in2,
    input  alu_op_e        alu_op,
    output logic [DW-1:0] out,
    output logic          zflag,
    output logic equal_flag,
    output logic less_flag,
    output logic greater_eq_flag,
    output logic unsigned_less_flag,
    output logic unsigned_greater_eq_flag
);

always_comb begin
    case (alu_op)
        ALU_AND: out = in1 & in2;
        ALU_OR:  out = in1 | in2;
        ALU_ADD: out = in1 + in2;
        ALU_SLL: out = in1 << in2[5:0];
        ALU_SRL: out = in1 >> in2[5:0];
        ALU_SRA: out = $signed(in1) >>> in2[5:0];
        ALU_SUB: out = in1 - in2;
        ALU_SLT: out = {{DW-1{1'b0}}, (in1 < in2)};  // SLT
        ALU_NOR: out = ~(in1 | in2);                 // NOR
        default: out = {DW{1'bx}};
    endcase

    zflag = (out == '0);  // Zero flag
end

assign equal_flag        = (in1 == in2); // FIXME: HERE, in1 == in2 CHECK? IF THIS DOESNT FIRE THEN THIS WONT EVENTUALLY TRIGGER PC_SRC!!!
assign less_flag         = ($signed(in1) < $signed(in2));
assign greater_eq_flag   = ($signed(in1) >= $signed(in2));
assign unsigned_less_flag       = in1 < in2;
assign unsigned_greater_eq_flag = in1 >= in2;

endmodule
