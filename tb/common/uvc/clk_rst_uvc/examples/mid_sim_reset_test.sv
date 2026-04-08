// ============================================================
//  Example 2 : mid_sim_reset_test
//
//  Demonstrates:
//    - Starting clock + initial reset
//    - Running traffic for some cycles
//    - Injecting a reset pulse mid-simulation using
//      clk_rst_reset_sequence (assert -> hold N cycles -> deassert)
//    - Resuming normal operation after the reset pulse
//
//  Run:
//    +UVM_TESTNAME=clk_rst_mid_sim_reset_test
// ============================================================

// ----------------------------------------------------------------
//  Dummy DUT: 8-bit free-running counter that resets to 0
// ----------------------------------------------------------------
module dummy_counter (
    input  logic       clk,
    input  logic       rst_n,
    output logic [7:0] count
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 8'h00;
        else
            count <= count + 8'h01;
    end
endmodule : dummy_counter


// ----------------------------------------------------------------
//  Test class
// ----------------------------------------------------------------
class clk_rst_mid_sim_reset_test extends uvm_test;
    `uvm_component_utils(clk_rst_mid_sim_reset_test)

    clk_rst_env env;

    function new(string name = "clk_rst_mid_sim_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = clk_rst_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        clk_rst_start_sequence        start_seq;
        clk_rst_wait_clocks_sequence  wait_seq;
        clk_rst_reset_sequence        reset_seq;

        phase.raise_objection(this, "mid_sim_reset_test");

        // ---- Phase 1: Start clock (period=10) + initial reset (5 cycles) ----
        start_seq = clk_rst_start_sequence::type_id::create("start_seq");
        start_seq.clock_period = 10;
        start_seq.reset_delay  = 5;
        start_seq.start(env.agent.sequencer);
        `uvm_info(get_type_name(), "Phase 1: Clock started, initial reset done", UVM_LOW)

        // ---- Phase 2: Let the counter run for 30 cycles ----
        wait_seq = clk_rst_wait_clocks_sequence::type_id::create("wait_seq");
        wait_seq.num_clocks = 30;
        wait_seq.start(env.agent.sequencer);
        `uvm_info(get_type_name(), "Phase 2: Ran 30 cycles of normal operation", UVM_LOW)

        // ---- Phase 3: Inject a mid-simulation reset pulse (hold 8 cycles) ----
        reset_seq = clk_rst_reset_sequence::type_id::create("reset_seq");
        reset_seq.hold_cycles = 8;
        reset_seq.start(env.agent.sequencer);
        `uvm_info(get_type_name(), "Phase 3: Mid-sim reset pulse complete", UVM_LOW)

        // ---- Phase 4: Resume and run 20 more cycles post-reset ----
        wait_seq = clk_rst_wait_clocks_sequence::type_id::create("wait_seq2");
        wait_seq.num_clocks = 20;
        wait_seq.start(env.agent.sequencer);
        `uvm_info(get_type_name(), "Phase 4: Ran 20 post-reset cycles, test done", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass : clk_rst_mid_sim_reset_test


// ----------------------------------------------------------------
//  Top module
// ----------------------------------------------------------------
module mid_sim_reset_tb;

    import uvm_pkg::*;
    import clk_rst_pkg::*;

    // Clock/reset interface
    clk_rst_if clk_rst_vif();

    // Dummy DUT wired to the interface signals
    logic [7:0] counter_val;

    dummy_counter dut (
        .clk   (clk_rst_vif.clk),
        .rst_n (clk_rst_vif.rst_n),
        .count (counter_val)
    );

    // Monitor counter value on every posedge clk
    always @(posedge clk_rst_vif.clk) begin
        // Using $display so the value is visible even at UVM_NONE
        $display("[%0t] counter = %0d  rst_n = %0b", $time, counter_val, clk_rst_vif.rst_n);
    end

    // UVM entry
    initial begin
        uvm_config_db #(virtual clk_rst_if)::set(
            null, "uvm_test_top.env.agent.driver", "vif", clk_rst_vif);
        run_test("clk_rst_mid_sim_reset_test");
    end

    // Waveform dump
    initial begin
        $dumpfile("mid_sim_reset.vcd");
        $dumpvars(0, mid_sim_reset_tb);
    end

    // Watchdog
    initial begin
        #500_000;
        `uvm_fatal("WATCHDOG", "Global timeout reached")
    end

endmodule : mid_sim_reset_tb
