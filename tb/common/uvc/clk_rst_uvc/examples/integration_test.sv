// ============================================================
//  Example 4 : integration_test
//
//  Demonstrates how to compose the clk_rst UVC alongside a
//  DUT-specific UVC inside a shared top-level environment.
//
//  This example shows a realistic integration pattern:
//    - clk_rst agent owns clock generation and reset
//    - DUT agent drives/monitors the DUT-specific protocol
//    - A virtual sequence coordinates startup: first start the
//      clock, then run DUT traffic
//
//  Run:
//    +UVM_TESTNAME=clk_rst_integration_test
// ============================================================

// ----------------------------------------------------------------
//  Top-level environment: clk_rst + DUT agent(s)
//
//  In a real project you would replace "stub_dut_agent" with
//  your actual DUT agent.
// ----------------------------------------------------------------

// Minimal stub agent to represent any DUT-specific UVC
class stub_dut_driver extends uvm_driver #(uvm_sequence_item);
    `uvm_component_utils(stub_dut_driver)

    function new(string name = "stub_dut_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info(get_type_name(), "Driving DUT transaction (stub)", UVM_LOW)
            #10;
            seq_item_port.item_done();
        end
    endtask
endclass : stub_dut_driver

class stub_dut_agent extends uvm_agent;
    `uvm_component_utils(stub_dut_agent)

    stub_dut_driver                        driver;
    uvm_sequencer #(uvm_sequence_item)     sequencer;

    function new(string name = "stub_dut_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = stub_dut_driver::type_id::create("driver", this);
        sequencer = uvm_sequencer #(uvm_sequence_item)::type_id::create("sequencer", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass : stub_dut_agent


// ----------------------------------------------------------------
//  Integrated environment
// ----------------------------------------------------------------
class integration_env extends uvm_env;
    `uvm_component_utils(integration_env)

    clk_rst_agent   clk_rst_agt;
    stub_dut_agent  dut_agt;

    function new(string name = "integration_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        clk_rst_agt = clk_rst_agent::type_id::create("clk_rst_agt", this);
        dut_agt     = stub_dut_agent::type_id::create("dut_agt", this);
    endfunction

endclass : integration_env


// ----------------------------------------------------------------
//  Virtual sequence: orchestrates clk/reset then DUT traffic
//
//  This is the recommended pattern for coordinating the clk_rst
//  UVC with a DUT UVC.  The virtual sequence:
//    1. Starts the clock and performs initial reset via clk_rst
//    2. Optionally waits a few cycles for the DUT to stabilise
//    3. Launches DUT-specific sequences on the DUT sequencer
// ----------------------------------------------------------------
class integration_vseq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(integration_vseq)

    // Sequencer handles - set by the test before starting
    clk_rst_sequencer                    clk_rst_seqr;
    uvm_sequencer #(uvm_sequence_item)   dut_seqr;

    function new(string name = "integration_vseq");
        super.new(name);
    endfunction

    virtual task body();
        clk_rst_start_sequence        start_seq;
        clk_rst_wait_clocks_sequence  wait_seq;
        uvm_sequence_item             dut_item;

        // Step 1: Start clock + initial reset
        start_seq = clk_rst_start_sequence::type_id::create("start_seq");
        start_seq.clock_period = 10;
        start_seq.reset_delay  = 5;
        start_seq.start(clk_rst_seqr);
        `uvm_info(get_type_name(), "Clock + reset sequence done", UVM_LOW)

        // Step 2: Post-reset stabilisation delay
        wait_seq = clk_rst_wait_clocks_sequence::type_id::create("wait_seq");
        wait_seq.num_clocks = 3;
        wait_seq.start(clk_rst_seqr);
        `uvm_info(get_type_name(), "Post-reset stabilisation done", UVM_LOW)

        // Step 3: Drive DUT traffic (stub: send 5 generic items)
        repeat (5) begin
            dut_item = uvm_sequence_item::type_id::create("dut_item");
            start_item(dut_item, -1, dut_seqr);
            finish_item(dut_item, -1);
        end
        `uvm_info(get_type_name(), "DUT traffic complete", UVM_LOW)

        // Step 4: Optional - inject a mid-sim reset, then run more traffic
        begin
            clk_rst_reset_sequence rst_seq;
            rst_seq = clk_rst_reset_sequence::type_id::create("rst_seq");
            rst_seq.hold_cycles = 4;
            rst_seq.start(clk_rst_seqr);
            `uvm_info(get_type_name(), "Mid-sim reset complete, resuming", UVM_LOW)
        end

        // Step 5: Post-reset DUT traffic
        repeat (3) begin
            dut_item = uvm_sequence_item::type_id::create("dut_item");
            start_item(dut_item, -1, dut_seqr);
            finish_item(dut_item, -1);
        end
        `uvm_info(get_type_name(), "Post-reset DUT traffic complete", UVM_LOW)
    endtask

endclass : integration_vseq


// ----------------------------------------------------------------
//  Test class
// ----------------------------------------------------------------
class clk_rst_integration_test extends uvm_test;
    `uvm_component_utils(clk_rst_integration_test)

    integration_env env;

    function new(string name = "clk_rst_integration_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = integration_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        integration_vseq vseq;

        phase.raise_objection(this, "integration_test");

        vseq = integration_vseq::type_id::create("vseq");
        vseq.clk_rst_seqr = env.clk_rst_agt.sequencer;
        vseq.dut_seqr     = env.dut_agt.sequencer;
        vseq.start(null);

        `uvm_info(get_type_name(), "Integration test complete", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass : clk_rst_integration_test


// ----------------------------------------------------------------
//  Top module
// ----------------------------------------------------------------
module integration_tb;

    import uvm_pkg::*;
    import clk_rst_pkg::*;

    // Clock/reset interface
    clk_rst_if clk_rst_vif();

    // Wire the interface to a DUT (using dummy_counter from example 2,
    // or any other DUT).  For this example we just observe the signals.

    // Register interface and launch UVM
    initial begin
        uvm_config_db #(virtual clk_rst_if)::set(
            null, "uvm_test_top.env.clk_rst_agt.driver", "vif", clk_rst_vif);
        run_test("clk_rst_integration_test");
    end

    // Signal monitor
    always @(posedge clk_rst_vif.clk)
        $display("[%0t] clk posedge  rst_n=%0b", $time, clk_rst_vif.rst_n);

    // Waveform dump
    initial begin
        $dumpfile("integration.vcd");
        $dumpvars(0, integration_tb);
    end

    // Watchdog
    initial begin
        #1_000_000;
        `uvm_fatal("WATCHDOG", "Global timeout reached")
    end

endmodule : integration_tb
