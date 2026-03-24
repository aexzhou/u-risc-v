`define RV32I_R_OPCODE          7'b0110011
`define RV32I_I_ALSL_OPCODE     7'b0010011
`define RV32I_I_LOAD_OPCODE     7'b0000011
`define RV32I_I_JALR_OPCODE     7'b1100111
`define RV32I_S_OPCODE          7'b0100011
`define RV32I_B_OPCODE          7'b1100011
`define RV32I_J_OPCODE          7'b1101111
`define RV32I_U_LUI_OPCODE      7'b0110111
`define RV32I_U_AUIPC_OPCODE    7'b0010111

`define RV32I_FUNCT7_LSB_POS        25
`define RV32I_FUNCT7_WIDTH          7
`define RV32I_FUNCT3_LSB_POS        12
`define RV32I_FUNCT3_WIDTH          3
`define RV32I_RS1_LSB_POS           15
`define RV32I_RS1_WIDTH             5
`define RV32I_RS2_LSB_POS           20
`define RV32I_RS2_WIDTH             5
`define RV32I_RD_LSB_POS            7
`define RV32I_RD_WIDTH              5
`define RV32I_OPCODE_LSB_POS        0
`define RV32I_OPCODE_WIDTH          7

`define RV32I_R_INVERT_OP_BIT_POS   30

`define RV32I_U_IMM_LSB_POS         12
`define RV32I_U_IMM_WIDTH           20

`define RV32I_J_IMM0_LSB_POS        12
`define RV32I_J_IMM0_WIDTH          8
`define RV32I_J_IMM1_LSB_POS        11
`define RV32I_J_IMM1_WIDTH          1
`define RV32I_J_IMM2_LSB_POS        1
`define RV32I_J_IMM2_WIDTH          10
`define RV32I_J_IMM3_LSB_POS        20
`define RV32I_J_IMM3_WIDTH          1
