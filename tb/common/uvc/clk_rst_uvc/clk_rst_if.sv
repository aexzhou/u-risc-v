interface clk_rst_if;

    // ============================================================
    //  Clock and reset signals (directly connectable to DUT ports)
    // ============================================================
    logic clk;
    logic rst_n;

    // Active-high reset alias for DUTs that use active-high reset
    wire rst = ~rst_n;

    // ============================================================
    //  Internal configuration
    // ============================================================
    int unsigned  half_period;
    bit           clk_running;

    // ============================================================
    //  Cycle countdown (used by driver for delay requests)
    // ============================================================
    int           cycle_countdown;
    event         clock_cycle_count_reached;

    // ============================================================
    //  Initialization
    // ============================================================
    initial begin
        clk             = 1'b0;
        rst_n           = 1'b0;
        half_period     = 5;
        clk_running     = 1'b0;
        cycle_countdown = 0;
    end

    // ============================================================
    //  Clock oscillator
    //  Blocks while clk_running == 0; resumes when set to 1.
    // ============================================================
    always begin
        wait (clk_running == 1'b1);
        #(half_period);
        clk = ~clk;
    end

    // ============================================================
    //  Cycle countdown process
    //  Decrements every posedge clk and triggers the event at zero.
    // ============================================================
    always @(posedge clk) begin
        if (cycle_countdown > 0) begin
            cycle_countdown--;
            if (cycle_countdown == 0)
                -> clock_cycle_count_reached;
        end
    end

    // ============================================================
    //  Driver-callable tasks
    // ============================================================

    // Start clock and perform a synchronous reset sequence.
    //   |period|      : full clock period in time units (must be >= 2).
    //   |reset_delay| : posedge clk count before rst_n deasserts.
    //   |run|         : when 0 the call is silently ignored.
    task automatic start_clock(
        input int unsigned period,
        input int unsigned reset_delay,
        input bit          run
    );
        if (!run) return;
        half_period = period / 2;
        rst_n       = 1'b0;
        if (!clk_running)
            clk_running = 1'b1;
        if (reset_delay > 0)
            repeat (reset_delay) @(posedge clk);
        rst_n = 1'b1;
    endtask : start_clock

    // Stop the clock oscillator. Clock output holds its last value.
    task automatic stop_clock();
        clk_running = 1'b0;
    endtask : stop_clock

    // Assert reset (drive rst_n low).
    task automatic assert_reset();
        @(posedge clk);
        rst_n <= 1'b0;
    endtask : assert_reset

    // Deassert reset (drive rst_n high).
    task automatic deassert_reset();
        @(posedge clk);
        rst_n <= 1'b1;
    endtask : deassert_reset

    // Start a new cycle countdown.
    // Triggers clock_cycle_count_reached when it expires.
    task automatic count_clocks(input int unsigned cycles);
        cycle_countdown = cycles;
    endtask : count_clocks

    // Return remaining countdown value.
    task automatic get_current_cycle_count(output int count);
        count = cycle_countdown;
    endtask : get_current_cycle_count

    // Convenience: block for |n| positive clock edges.
    task automatic wait_n_clocks(input int unsigned n);
        repeat (n) @(posedge clk);
    endtask : wait_n_clocks

endinterface : clk_rst_if
