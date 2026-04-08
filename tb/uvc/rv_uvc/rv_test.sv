// RISC-V Test
// Base test class and derived test cases

`ifndef RISCV_TEST_SV
`define RISCV_TEST_SV

// Base test class
class riscv_base_test extends uvm_test;
    `uvm_component_utils(riscv_base_test)

    riscv_env env;

    function new(string name = "riscv_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = riscv_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info(get_type_name(), "UVM Testbench Hierarchy:", UVM_NONE)
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting test...", UVM_NONE)

        // Wait for reset
        #100ns;

        // Default: run for some time
        #5000ns;

        `uvm_info(get_type_name(), "Test completed", UVM_NONE)
        phase.drop_objection(this);
    endtask

endclass

// Arithmetic test
class riscv_arithmetic_test extends riscv_base_test;
    `uvm_component_utils(riscv_arithmetic_test)

    function new(string name = "riscv_arithmetic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        riscv_arithmetic_sequence seq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting arithmetic test...", UVM_NONE)

        // Wait for reset
        #100ns;

        // Run arithmetic sequence
        seq = riscv_arithmetic_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        // Wait for pipeline to drain
        #1000ns;

        `uvm_info(get_type_name(), "Arithmetic test completed", UVM_NONE)
        phase.drop_objection(this);
    endtask

endclass

// Random test
class riscv_random_test extends riscv_base_test;
    `uvm_component_utils(riscv_random_test)

    function new(string name = "riscv_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        riscv_random_sequence seq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting random test...", UVM_NONE)

        // Wait for reset
        #100ns;

        // Run random sequence
        seq = riscv_random_sequence::type_id::create("seq");
        assert(seq.randomize());
        seq.start(env.agent.sequencer);

        // Wait for pipeline to drain
        #1000ns;

        `uvm_info(get_type_name(), "Random test completed", UVM_NONE)
        phase.drop_objection(this);
    endtask

endclass

`endif // RISCV_TEST_SV
