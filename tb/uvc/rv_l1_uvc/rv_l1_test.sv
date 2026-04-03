// ================================================================
//  Base test
// ================================================================
class rv_l1_base_test extends uvm_test;
    `uvm_component_utils(rv_l1_base_test)

    rv_l1_env env;

    function new(string name = "rv_l1_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = rv_l1_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        `ifdef UVM_VERSION
            // IEEE 1800.2 (UVM 2017+)
            uvm_root::get().print_topology();
        `else
            // UVM 1.1d
            uvm_top.print_topology();
        `endif
    endfunction

endclass : rv_l1_base_test


// ================================================================
//  Directed smoke test (tests 1-4)
// ================================================================
class rv_l1_smoke_test extends rv_l1_base_test;
    `uvm_component_utils(rv_l1_smoke_test)

    function new(string name = "rv_l1_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        rv_l1_smoke_sequence seq;
        phase.raise_objection(this);

        seq = rv_l1_smoke_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask

endclass : rv_l1_smoke_test


// ================================================================
//  Full directed regression (all 11 standalone test scenarios)
// ================================================================
class rv_l1_full_test extends rv_l1_base_test;
    `uvm_component_utils(rv_l1_full_test)

    function new(string name = "rv_l1_full_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        rv_l1_full_sequence seq;
        phase.raise_objection(this);

        seq = rv_l1_full_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask

endclass : rv_l1_full_test


// ================================================================
//  Random test
// ================================================================
class rv_l1_random_test extends rv_l1_base_test;
    `uvm_component_utils(rv_l1_random_test)

    function new(string name = "rv_l1_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        rv_l1_random_sequence seq;
        phase.raise_objection(this);

        seq = rv_l1_random_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask

endclass : rv_l1_random_test
