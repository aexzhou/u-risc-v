// ================================================================
//  rv_l1c base virtual sequence
//
//  Coordinates clock/reset bring-up (via the clk_rst UVC) and the
//  test-specific cpu sequence (via the rv_l1c agent).
//
//  Usage from a test:
//      rv_l1c_base_vseq      vseq;
//      rv_l1c_smoke_sequence cpu_seq;
//
//      cpu_seq      = rv_l1c_smoke_sequence::type_id::create("cpu_seq");
//      vseq         = rv_l1c_base_vseq::type_id::create("vseq");
//      vseq.cpu_seq = cpu_seq;
//      vseq.start(env.vseqr);
// ================================================================
class rv_l1c_base_vseq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(rv_l1c_base_vseq)

    // Parent vseqr handle (set automatically in pre_body)
    rv_l1c_vseqr p_seqr;

    // Test-supplied cpu-side sequence to run after clock/reset
    rv_l1c_base_sequence cpu_seq;

    // Clock configuration (override before calling start())
    int unsigned clock_period = 10;
    int unsigned reset_delay  = 5;

    function new(string name = "rv_l1c_base_vseq");
        super.new(name);
    endfunction

    // ------------------------------------------------------------
    //  pre_body : grab the parent vseqr handle so derived bodies
    //  (and helpers below) can dispatch to sub-sequencers.
    // ------------------------------------------------------------
    virtual task pre_body();
        if (m_sequencer != null) begin
            if (!$cast(p_seqr, m_sequencer))
                `uvm_fatal(get_type_name(),
                    "rv_l1c_base_vseq must be started on a rv_l1c_vseqr")
        end
    endtask

    // ------------------------------------------------------------
    //  body : standard flow - start clock + reset, then run the
    //  test-specific cpu sequence (if any).
    // ------------------------------------------------------------
    virtual task body();
        start_clock_and_reset();

        if (cpu_seq != null) begin
            `uvm_info(get_type_name(),
                $sformatf("Starting cpu sequence: %s", cpu_seq.get_type_name()),
                UVM_LOW)
            cpu_seq.start(p_seqr.cpu_seqr);
        end
        else begin
            `uvm_warning(get_type_name(),
                "cpu_seq was not set; vseq has nothing to do after clock startup")
        end
    endtask

    // ------------------------------------------------------------
    //  Helper : kick off the clock + initial reset on the
    //  clk_rst sub-sequencer.
    // ------------------------------------------------------------
    virtual task start_clock_and_reset();
        clk_rst_start_sequence start_seq;
        start_seq = clk_rst_start_sequence::type_id::create("start_seq");
        start_seq.clock_period = clock_period;
        start_seq.reset_delay  = reset_delay;
        start_seq.start(p_seqr.clk_rst_seqr);
        `uvm_info(get_type_name(),
            $sformatf("Clock + reset done (period=%0d, hold=%0d cycles)",
                      clock_period, reset_delay), UVM_LOW)
    endtask

    // ------------------------------------------------------------
    //  Helper : pulse rst_n mid-simulation while keeping clock
    //  running.  Useful for reset-recovery tests.
    // ------------------------------------------------------------
    virtual task pulse_reset(int unsigned hold_cycles = 5);
        clk_rst_reset_sequence rst_seq;
        rst_seq = clk_rst_reset_sequence::type_id::create("rst_seq");
        rst_seq.hold_cycles = hold_cycles;
        rst_seq.start(p_seqr.clk_rst_seqr);
    endtask

    // ------------------------------------------------------------
    //  Helper : block for |n| clock cycles via the clk_rst UVC.
    // ------------------------------------------------------------
    virtual task wait_clocks(int unsigned n);
        clk_rst_wait_clocks_sequence wait_seq;
        wait_seq = clk_rst_wait_clocks_sequence::type_id::create("wait_seq");
        wait_seq.num_clocks = n;
        wait_seq.start(p_seqr.clk_rst_seqr);
    endtask

endclass : rv_l1c_base_vseq
