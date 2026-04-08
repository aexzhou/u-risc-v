class clk_rst_seq_item extends uvm_sequence_item;

    // ============================================================
    //  Request type
    // ============================================================
    typedef enum bit [2:0] {
        START_CLOCK    = 3'b000,
        STOP_CLOCK     = 3'b001,
        ASSERT_RESET   = 3'b010,
        DEASSERT_RESET = 3'b011,
        COUNT_CLOCKS   = 3'b100
    } req_type_e;

    rand req_type_e       req_type;

    // ============================================================
    //  Clock configuration (used with START_CLOCK)
    // ============================================================
    rand int unsigned     clock_period;
    rand int unsigned     reset_delay;
    rand bit              run_clock;

    // ============================================================
    //  Cycle count (used with COUNT_CLOCKS)
    // ============================================================
    rand int unsigned     clock_cycles_to_count;
    bit                   cycle_count_must_happen;

    // ============================================================
    //  Field automation
    //  UVM 1800.2-2017-1.0 : field macros are the standard way.
    //  UVM 1800.2-2020+    : do_* methods are preferred; field
    //                        macros still compile but are deprecated.
    // ============================================================
`ifdef UVM_1800_2_2020
    `uvm_object_utils(clk_rst_seq_item)

    virtual function void do_copy(uvm_object rhs);
        clk_rst_seq_item rhs_;
        super.do_copy(rhs);
        if (!$cast(rhs_, rhs))
            `uvm_fatal(get_type_name(), "Cast failed in do_copy")
        req_type               = rhs_.req_type;
        clock_period           = rhs_.clock_period;
        reset_delay            = rhs_.reset_delay;
        run_clock              = rhs_.run_clock;
        clock_cycles_to_count  = rhs_.clock_cycles_to_count;
        cycle_count_must_happen = rhs_.cycle_count_must_happen;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        clk_rst_seq_item rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return super.do_compare(rhs, comparer) &&
               (req_type              == rhs_.req_type)              &&
               (clock_period          == rhs_.clock_period)          &&
               (reset_delay           == rhs_.reset_delay)           &&
               (run_clock             == rhs_.run_clock)             &&
               (clock_cycles_to_count == rhs_.clock_cycles_to_count);
    endfunction

    virtual function string convert2string();
        return $sformatf("req_type=%s period=%0d rst_dly=%0d run=%0b cycles=%0d must_happen=%0b",
                         req_type.name(), clock_period, reset_delay, run_clock,
                         clock_cycles_to_count, cycle_count_must_happen);
    endfunction
`else
    `uvm_object_utils_begin(clk_rst_seq_item)
        `uvm_field_enum(req_type_e, req_type,            UVM_ALL_ON)
        `uvm_field_int (clock_period,                    UVM_ALL_ON)
        `uvm_field_int (reset_delay,                     UVM_ALL_ON)
        `uvm_field_int (run_clock,                       UVM_ALL_ON)
        `uvm_field_int (clock_cycles_to_count,           UVM_ALL_ON)
        `uvm_field_int (cycle_count_must_happen,         UVM_ALL_ON)
    `uvm_object_utils_end

    function string convert2string();
        return $sformatf("req_type=%s period=%0d rst_dly=%0d run=%0b cycles=%0d must_happen=%0b",
                         req_type.name(), clock_period, reset_delay, run_clock,
                         clock_cycles_to_count, cycle_count_must_happen);
    endfunction
`endif

    function new(string name = "clk_rst_seq_item");
        super.new(name);
    endfunction

    // ============================================================
    //  Constraints
    // ============================================================
    constraint clock_period_c {
        clock_period >= 2;
        soft clock_period == 10;
    }

    constraint reset_delay_c {
        soft reset_delay == 5;
    }

    constraint run_clock_c {
        soft run_clock == 1'b1;
    }

    constraint count_clocks_c {
        (req_type != COUNT_CLOCKS) -> clock_cycles_to_count == 0;
    }

endclass : clk_rst_seq_item
