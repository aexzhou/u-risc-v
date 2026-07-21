// test_alu_golden.sv — barebones golden-reference-model self-checking test
//
// Instantiates the real rv_alu RTL (hdl/cpu/components/rv_alu.sv), drives it
// with random operands/ops, and compares its output each cycle against a
// C "golden" model (golden_alu.cpp) called via DPI-C.
//
// Run with:
//   scripts/run test_alu_golden -- tb/cpu/alu_golden/golden_alu.cpp

module test_alu_golden;

  import rv_alu_types::*;

  // DPI-C import: C reference model for the ALU
  import "DPI-C" function int golden_alu(input int in1, input int in2, input int op);

  logic [31:0] in1, in2, out;
  alu_op_e     op;
  logic        equal_flag, less_flag, greater_eq_flag, ult_flag, uge_flag;

  // DUT: the real ALU RTL
  rv_alu dut (
      .in1(in1),
      .in2(in2),
      .alu_op(op),
      .out(out),
      .equal_flag(equal_flag),
      .less_flag(less_flag),
      .greater_eq_flag(greater_eq_flag),
      .unsigned_less_flag(ult_flag),
      .unsigned_greater_eq_flag(uge_flag)
  );

  // All ALU ops exercised by this test
  alu_op_e ops[11] = '{
      ALU_AND, ALU_OR, ALU_ADD, ALU_SLL, ALU_SRL,
      ALU_SRA, ALU_SUB, ALU_SLT, ALU_XOR, ALU_SLTU, ALU_NOR
  };

  localparam int NUM_VECTORS = 50;
  int errors = 0;
  int expected;

  initial begin
    for (int i = 0; i < NUM_VECTORS; i++) begin
      in1 = $urandom;
      in2 = $urandom;
      op  = ops[$urandom_range(0, $size(ops) - 1)];

      #1;  // let the (combinational) RTL settle

      expected = golden_alu(in1, in2, int'(op));

      if (out !== expected[31:0]) begin
        $display("FAIL: op=%s in1=%0h in2=%0h  rtl=%0h golden=%0h",
                  op.name(), in1, in2, out, expected);
        errors++;
      end
    end

    if (errors == 0) $display("PASS: all %0d vectors matched the golden model", NUM_VECTORS);
    else $display("FAIL: %0d/%0d vectors mismatched", errors, NUM_VECTORS);

    $finish;
  end

endmodule
