// ============================================================
//  Example 3 : multi_clock_test
//
//  Demonstrates:
//    - Two independent clk_rst_if instances (fast + slow domains)
//    - Two clk_rst_agents, each controlling its own interface
//    - Starting both clocks from the same test, each with its
//      own period and reset delay
//    - A custom environment that contains both agents
//
//  Run:
//    +UVM_TESTNAME=clk_rst_multi_clock_test
// ============================================================

// ----------------------------------------------------------------
//  Custom environment with two clk_rst agents
// ----------------------------------------------------------------
class multi_clk_env extends uvm_env;
    `uvm_component_utils(multi_clk_env)

    clk_rst_agent fast_agent;   // e.g. 100 MHz core clock
    clk_rst_agent slow_agent;   // e.g.  25 MHz peripheral clock

    function new(string name = "multi_clk_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        fast_agent = clk_rst_agent::type_id::create("fast_agent", this);
        slow_agent = clk_rst_agent::type_id::create("slow_agent", this);
    endfunction

endclass : multi_clk_env


// ----------------------------------------------------------------
//  Test class
// ----------------------------------------------------------------
class clk_rst_multi_clock_test extends uvm_test;
    `uvm_component_utils(clk_rst_multi_clock_test)

    multi_clk_env env;

    function new(string name = "clk_rst_multi_clock_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = multi_clk_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        clk_rst_start_sequence        fast_start, slow_start;
        clk_rst_wait_clocks_sequence  wait_seq;

        phase.raise_objection(this, "multi_clock_test");

        // --- Start both clocks in parallel ---
        fork
            begin : fast_domain
                fast_start = clk_rst_start_sequence::type_id::create("fast_start");
                fast_start.clock_period = 10;   // 10 time-unit period
                fast_start.reset_delay  = 5;
                fast_start.start(env.fast_agent.sequencer);
                `uvm_info(get_type_name(), "Fast clock started (period=10)", UVM_LOW)
            end

            begin : slow_domain
                slow_start = clk_rst_start_sequence::type_id::create("slow_start");
                slow_start.clock_period = 40;   // 40 time-unit period
                slow_start.reset_delay  = 3;
                slow_start.start(env.slow_agent.sequencer);
                `uvm_info(get_type_name(), "Slow clock started (period=40)", UVM_LOW)
            end
        join

        // --- Let both clocks run for 50 fast-clock cycles ---
        wait_seq = clk_rst_wait_clocks_sequence::type_id::create("wait_seq");
        wait_seq.num_clocks = 50;
        wait_seq.start(env.fast_agent.sequencer);

        `uvm_info(get_type_name(), "Test complete - both domains ran successfully", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass : clk_rst_multi_clock_test


// ----------------------------------------------------------------
//  Top module
// ----------------------------------------------------------------
module multi_clock_tb;

    import uvm_pkg::*;
    import clk_rst_pkg::*;

    // Two independent clock/reset interfaces
    clk_rst_if fast_vif();
    clk_rst_if slow_vif();

    // Register both interfaces in the config DB
    initial begin
        uvm_config_db #(virtual clk_rst_if)::set(
            null, "uvm_test_top.env.fast_agent.driver", "vif", fast_vif);
        uvm_config_db #(virtual clk_rst_if)::set(
            null, "uvm_test_top.env.slow_agent.driver", "vif", slow_vif);
        run_test("clk_rst_multi_clock_test");
    end

    // Observe both domains
    always @(posedge fast_vif.clk)
        $display("[%0t] FAST  clk posedge  rst_n=%0b", $time, fast_vif.rst_n);

    always @(posedge slow_vif.clk)
        $display("[%0t] SLOW  clk posedge  rst_n=%0b", $time, slow_vif.rst_n);

    // Waveform dump
    initial begin
        $dumpfile("multi_clock.vcd");
        $dumpvars(0, multi_clock_tb);
    end

    // Watchdog
    initial begin
        #500_000;
        `uvm_fatal("WATCHDOG", "Global timeout reached")
    end

endmodule : multi_clock_tb
