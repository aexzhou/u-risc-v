// RISC-V Transaction Class
// Defines the basic transaction items for the testbench

`ifndef RISCV_TRANSACTION_SV
`define RISCV_TRANSACTION_SV

class riscv_transaction extends uvm_sequence_item;

    // Instruction fields
    rand bit [31:0] instruction;
    rand bit [63:0] pc;

    // Expected results
    bit [63:0] expected_result;
    bit [4:0]  dest_reg;

    // Actual results (populated by monitor)
    bit [63:0] actual_result;
    bit        compare_result;

    // Control signals observed
    bit        reg_write;
    bit        mem_read;
    bit        mem_write;
    bit        branch_taken;

    // UVM automation macros
    `uvm_object_utils_begin(riscv_transaction)
        `uvm_field_int(instruction, UVM_ALL_ON)
        `uvm_field_int(pc, UVM_ALL_ON)
        `uvm_field_int(expected_result, UVM_ALL_ON)
        `uvm_field_int(dest_reg, UVM_ALL_ON)
        `uvm_field_int(actual_result, UVM_ALL_ON)
        `uvm_field_int(compare_result, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "riscv_transaction");
        super.new(name);
    endfunction

    // Constraint for valid RISC-V instructions
    constraint valid_instruction {
        // Limit to I-type and R-type for now
        instruction[6:0] inside {7'b0010011, 7'b0110011}; // addi, add, sub, etc.
    }

    // Helper function to decode instruction type
    function string get_instr_type();
        case (instruction[6:0])
            7'b0010011: return "I-TYPE";
            7'b0110011: return "R-TYPE";
            7'b0000011: return "LOAD";
            7'b0100011: return "STORE";
            7'b1100011: return "BRANCH";
            default: return "UNKNOWN";
        endcase
    endfunction

    // Convert to string for debugging
    function string convert2string();
        string s;
        s = $sformatf("PC=0x%0h, Instr=0x%0h (%s), DestReg=x%0d, Expected=0x%0h, Actual=0x%0h",
                      pc, instruction, get_instr_type(), dest_reg, expected_result, actual_result);
        return s;
    endfunction

endclass

`endif // RISCV_TRANSACTION_SV
