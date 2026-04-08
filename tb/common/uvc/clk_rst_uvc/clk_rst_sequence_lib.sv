// ================================================================
//  Base sequence
// ================================================================
class clk_rst_base_sequence extends uvm_sequence #(clk_rst_seq_item);
    `uvm_object_utils(clk_rst_base_sequence)

    function new(string name = "clk_rst_base_sequence");
        super.new(name);
    endfunction

    // Helper: send a single request item and return when accepted
    virtual task send_req(clk_rst_seq_item::req_type_e rtype);
        clk_rst_seq_item item = clk_rst_seq_item::type_id::create("item");
        start_item(item);
        item.req_type = rtype;
        finish_item(item);
    endtask

endclass : clk_rst_base_sequence


// ================================================================
//  Start clock + reset sequence
//
//  Starts the clock oscillator and performs a synchronous reset.
//  Configurable clock period and reset hold duration (in cycles).
// ================================================================
class clk_rst_start_sequence extends clk_rst_base_sequence;
    `uvm_object_utils(clk_rst_start_sequence)

    rand int unsigned clock_period;
    rand int unsigned reset_delay;

    constraint defaults_c {
        soft clock_period == 10;
        soft reset_delay  == 5;
    }

    function new(string name = "clk_rst_start_sequence");
        super.new(name);
    endfunction

    virtual task body();
        clk_rst_seq_item item = clk_rst_seq_item::type_id::create("item");
        start_item(item);
        item.req_type     = clk_rst_seq_item::START_CLOCK;
        item.clock_period = clock_period;
        item.reset_delay  = reset_delay;
        item.run_clock    = 1'b1;
        finish_item(item);
        `uvm_info(get_type_name(),
            $sformatf("Clock started: period=%0d, reset held for %0d cycles",
                      clock_period, reset_delay), UVM_LOW)
    endtask

endclass : clk_rst_start_sequence


// ================================================================
//  Stop clock sequence
// ================================================================
class clk_rst_stop_sequence extends clk_rst_base_sequence;
    `uvm_object_utils(clk_rst_stop_sequence)

    function new(string name = "clk_rst_stop_sequence");
        super.new(name);
    endfunction

    virtual task body();
        send_req(clk_rst_seq_item::STOP_CLOCK);
        `uvm_info(get_type_name(), "Clock stopped", UVM_LOW)
    endtask

endclass : clk_rst_stop_sequence


// ================================================================
//  Assert reset sequence
//
//  Drives rst_n low. Use clk_rst_deassert_reset_sequence or
//  clk_rst_reset_sequence (which does both) to release.
// ================================================================
class clk_rst_assert_reset_sequence extends clk_rst_base_sequence;
    `uvm_object_utils(clk_rst_assert_reset_sequence)

    function new(string name = "clk_rst_assert_reset_sequence");
        super.new(name);
    endfunction

    virtual task body();
        send_req(clk_rst_seq_item::ASSERT_RESET);
        `uvm_info(get_type_name(), "Reset asserted (rst_n=0)", UVM_LOW)
    endtask

endclass : clk_rst_assert_reset_sequence


// ================================================================
//  Deassert reset sequence
// ================================================================
class clk_rst_deassert_reset_sequence extends clk_rst_base_sequence;
    `uvm_object_utils(clk_rst_deassert_reset_sequence)

    function new(string name = "clk_rst_deassert_reset_sequence");
        super.new(name);
    endfunction

    virtual task body();
        send_req(clk_rst_seq_item::DEASSERT_RESET);
        `uvm_info(get_type_name(), "Reset deasserted (rst_n=1)", UVM_LOW)
    endtask

endclass : clk_rst_deassert_reset_sequence


// ================================================================
//  Reset pulse sequence
//
//  Asserts reset, waits |hold_cycles| clocks, then deasserts.
//  Uses the COUNT_CLOCKS mechanism so the driver's run_phase is
//  not blocked during the hold period.
// ================================================================
class clk_rst_reset_sequence extends clk_rst_base_sequence;
    `uvm_object_utils(clk_rst_reset_sequence)

    rand int unsigned hold_cycles;

    constraint hold_c {
        hold_cycles >= 1;
        soft hold_cycles == 5;
    }

    function new(string name = "clk_rst_reset_sequence");
        super.new(name);
    endfunction

    virtual task body();
        clk_rst_seq_item item;

        // Assert reset
        send_req(clk_rst_seq_item::ASSERT_RESET);

        // Wait |hold_cycles| via COUNT_CLOCKS (sends response when done)
        item = clk_rst_seq_item::type_id::create("wait_item");
        start_item(item);
        item.req_type              = clk_rst_seq_item::COUNT_CLOCKS;
        item.clock_cycles_to_count = hold_cycles;
        finish_item(item);
        get_response(rsp);

        // Deassert reset
        send_req(clk_rst_seq_item::DEASSERT_RESET);

        `uvm_info(get_type_name(),
            $sformatf("Reset pulse complete (held %0d cycles)", hold_cycles), UVM_LOW)
    endtask

endclass : clk_rst_reset_sequence


// ================================================================
//  Wait clocks sequence
//
//  Blocks the calling sequence for |num_clocks| clock cycles by
//  using the driver's COUNT_CLOCKS mechanism.  The body() returns
//  only after the driver sends back a response.
// ================================================================
class clk_rst_wait_clocks_sequence extends clk_rst_base_sequence;
    `uvm_object_utils(clk_rst_wait_clocks_sequence)

    rand int unsigned num_clocks;
    bit               must_happen;

    constraint num_c {
        num_clocks >= 1;
        soft num_clocks == 10;
    }

    function new(string name = "clk_rst_wait_clocks_sequence");
        super.new(name);
    endfunction

    virtual task body();
        clk_rst_seq_item item = clk_rst_seq_item::type_id::create("wait_item");
        start_item(item);
        item.req_type               = clk_rst_seq_item::COUNT_CLOCKS;
        item.clock_cycles_to_count  = num_clocks;
        item.cycle_count_must_happen = must_happen;
        finish_item(item);
        get_response(rsp);
        `uvm_info(get_type_name(),
            $sformatf("Waited %0d clock cycles", num_clocks), UVM_HIGH)
    endtask

endclass : clk_rst_wait_clocks_sequence
