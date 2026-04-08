// ============================================================
//  Example 1 : basic_start_test
//
//  This testbench demonstrates:
//    - Instantiating the clk_rst_if interface
//    - Passing it through the config DB
//    - Starting the clock + performing the initial reset
//    - Waiting a few cycles then ending the test
//
//  Compile (Questa / VCS style):
//    +incdir+<path-to>/clk_rst_uvc
//    <path-to>/clk_rst_uvc/clk_rst_if.sv
//    <path-to>/clk_rst_uvc/clk_rst_pkg.sv
//    <path-to>/clk_rst_uvc/examples/basic_start_test.sv
//
//  Run:
//    +UVM_TESTNAME=clk_rst_basic_test
// ============================================================

// ----------------------------------------------------------------
//  Test class
// ----------------------------------------------------------------
class clk_rst_basic_test extends uvm_test;
    `uvm_component_utils(clk_rst_basic_test)

    clk_rst_env env;

    function new(string name = "clk_rst_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = clk_rst_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        clk_rst_start_sequence        start_seq;
        clk_rst_wait_clocks_sequence  wait_seq;

        phase.raise_objection(this, "basic_start_test");

        // Start a 10-unit-period clock; hold reset for 5 cycles
        start_seq = clk_rst_start_sequence::type_id::create("start_seq");
        start_seq.clock_period = 10;
        start_seq.reset_delay  = 5;
        start_seq.start(env.agent.sequencer);

        `uvm_info(get_type_name(), "Clock running, reset deasserted", UVM_LOW)

        // Let the clock run for 20 cycles then end
        wait_seq = clk_rst_wait_clocks_sequence::type_id::create("wait_seq");
        wait_seq.num_clocks = 20;
        wait_seq.start(env.agent.sequencer);

        `uvm_info(get_type_name(), "Test complete", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass : clk_rst_basic_test


// ----------------------------------------------------------------
//  Top module
// ----------------------------------------------------------------
module basic_start_tb;

    import uvm_pkg::*;
    import clk_rst_pkg::*;

    // Interface instance
    clk_rst_if clk_rst_vif();

    // Register with config DB and launch UVM
    initial begin
        uvm_config_db #(virtual clk_rst_if)::set(
            null, "uvm_test_top.env.agent.driver", "vif", clk_rst_vif);
        run_test("clk_rst_basic_test");
    end

    // Waveform dump (optional)
    initial begin
        $dumpfile("basic_start.vcd");
        $dumpvars(0, basic_start_tb);
    end

    // Global watchdog
    initial begin
        #100_000;
        `uvm_fatal("WATCHDOG", "Global timeout reached")
    end

endmodule : basic_start_tb
