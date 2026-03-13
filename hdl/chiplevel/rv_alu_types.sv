package rv_alu_types;

    // ALU operation encodings
    typedef enum logic [3:0] {
        ALU_AND = 4'b0000,  // Bitwise AND
        ALU_OR  = 4'b0001,  // Bitwise OR
        ALU_ADD = 4'b0010,  // Addition
        ALU_SLL = 4'b0011,  // Shift Left Logical
        ALU_SRL = 4'b0100,  // Shift Right Logical
        ALU_SRA = 4'b0101,  // Shift Right Arithmetic
        ALU_SUB = 4'b0110,  // Subtraction
        ALU_SLT = 4'b0111,  // Set on Less Than
        ALU_XOR = 4'b1000,  // XOR
        ALU_NOR = 4'b1100   // Bitwise NOR
    } alu_op_e;

endpackage
