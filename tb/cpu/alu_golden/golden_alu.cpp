// golden_alu.cpp — tiny C "golden" reference model for hdl/cpu/components/rv_alu.sv
//
// Mirrors the ALU op encodings defined in hdl/chiplevel/rv_alu_types.sv.
// The testbench calls this via DPI-C and compares its result against the
// actual RTL output for the same inputs (self-checking scoreboard).

#include <cstdint>
#include <cstdio>

extern "C" int golden_alu(int in1_i, int in2_i, int op) {
    uint32_t a = static_cast<uint32_t>(in1_i);
    uint32_t b = static_cast<uint32_t>(in2_i);
    int32_t  sa = static_cast<int32_t>(a);
    int32_t  sb = static_cast<int32_t>(b);
    uint32_t shamt = b & 0x3F;  // matches RTL's in2[5:0]
    uint32_t result = 0;

    switch (op) {
        case 0:  result = a & b; break;                                   // ALU_AND
        case 1:  result = a | b; break;                                   // ALU_OR
        case 2:  result = a + b; break;                                   // ALU_ADD
        case 3:  result = (shamt >= 32) ? 0 : (a << shamt); break;        // ALU_SLL
        case 4:  result = (shamt >= 32) ? 0 : (a >> shamt); break;        // ALU_SRL
        case 5:  result = (shamt >= 32)                                   // ALU_SRA
                              ? static_cast<uint32_t>(sa >> 31)
                              : static_cast<uint32_t>(sa >> shamt);
                 break;
        case 6:  result = a - b; break;                                   // ALU_SUB
        case 7:  result = (sa < sb) ? 1 : 0; break;                       // ALU_SLT
        case 8:  result = a ^ b; break;                                   // ALU_XOR
        case 10: result = (a < b) ? 1 : 0; break;                         // ALU_SLTU
        case 12: result = ~(a | b); break;                                // ALU_NOR
        default: result = 0; break;
    }

    return static_cast<int>(result);
}
