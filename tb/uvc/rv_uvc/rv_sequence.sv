// RISC-V Sequences
// Defines test sequences for generating instruction streams

`ifndef RISCV_SEQUENCE_SV
`define RISCV_SEQUENCE_SV

// Base sequence
class riscv_base_sequence extends uvm_sequence#(riscv_transaction);
    `uvm_object_utils(riscv_base_sequence)

    function new(string name = "riscv_base_sequence");
        super.new(name);
    endfunction

endclass

// Simple arithmetic sequence
class riscv_arithmetic_sequence extends riscv_base_sequence;
    `uvm_object_utils(riscv_arithmetic_sequence)

    function new(string name = "riscv_arithmetic_sequence");
        super.new(name);
    endfunction

    virtual task body();
        riscv_transaction txn;

        `uvm_info(get_type_name(), "Starting arithmetic sequence", UVM_MEDIUM)

        // Test 1: addi x1, x0, 5
        txn = riscv_transaction::type_id::create("txn");
        start_item(txn);
        txn.instruction = 32'h00500093;
        txn.pc = 64'h0;
        txn.dest_reg = 5'd1;
        txn.expected_result = 64'd5;
        finish_item(txn);

        // Test 2: addi x2, x0, 10
        txn = riscv_transaction::type_id::create("txn");
        start_item(txn);
        txn.instruction = 32'h00A00113;
        txn.pc = 64'h4;
        txn.dest_reg = 5'd2;
        txn.expected_result = 64'd10;
        finish_item(txn);

        // Test 3: add x3, x1, x2
        txn = riscv_transaction::type_id::create("txn");
        start_item(txn);
        txn.instruction = 32'h002081B3;
        txn.pc = 64'h8;
        txn.dest_reg = 5'd3;
        txn.expected_result = 64'd15;
        finish_item(txn);

        // Test 4: sub x4, x2, x1
        txn = riscv_transaction::type_id::create("txn");
        start_item(txn);
        txn.instruction = 32'h40110233;
        txn.pc = 64'hC;
        txn.dest_reg = 5'd4;
        txn.expected_result = 64'd5;
        finish_item(txn);

        `uvm_info(get_type_name(), "Arithmetic sequence completed", UVM_MEDIUM)
    endtask

endclass

// Random instruction sequence
class riscv_random_sequence extends riscv_base_sequence;
    `uvm_object_utils(riscv_random_sequence)

    rand int num_instructions;

    constraint num_instr_c {
        num_instructions inside {[10:50]};
    }

    function new(string name = "riscv_random_sequence");
        super.new(name);
    endfunction

    virtual task body();
        riscv_transaction txn;

        `uvm_info(get_type_name(), $sformatf("Starting random sequence with %0d instructions", num_instructions), UVM_MEDIUM)

        repeat(num_instructions) begin
            txn = riscv_transaction::type_id::create("txn");
            start_item(txn);
            assert(txn.randomize());
            finish_item(txn);
        end

        `uvm_info(get_type_name(), "Random sequence completed", UVM_MEDIUM)
    endtask

endclass

`endif // RISCV_SEQUENCE_SV
