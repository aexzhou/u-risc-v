module rv_alu
    import rv_alu_types::*;
#(
    parameter int DW = 32
) (
    input  logic [DW-1:0] in1,
    input  logic [DW-1:0] in2,
    input  alu_op_e        alu_op,
    output logic [DW-1:0] out,
    output logic          zflag
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
        ALU_SLTU: out = {{DW-1{1'b0}}, (in1 < in2)};
        ALU_SLT: out = {{DW-1{1'b0}}, ($signed(in1) < $signed(in2))};
        ALU_NOR: out = ~(in1 | in2);
		ALU_XOR: out = in1 ^ in2;
        default: out = {DW{1'bx}};
    endcase

    zflag = (out == '0);  // Zero flag
end

endmodule
