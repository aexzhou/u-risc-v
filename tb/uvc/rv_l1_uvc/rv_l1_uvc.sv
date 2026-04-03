module rv_l1_uvc;

    import uvm_pkg::*;
    import rv_l1_pkg::*;

    // ============================================================
    //  Parameters
    // ============================================================
    localparam ADDR_WIDTH  = 32;
    localparam DATA_WIDTH  = 32;
    localparam LINE_WIDTH  = 128;
    localparam NUM_SETS    = 16;
    localparam NUM_WAYS    = 2;
    localparam OFFSET_BITS = $clog2(LINE_WIDTH / 8);
    localparam CLK_PERIOD  = 10;

    // ============================================================
    //  Clock & reset
    // ============================================================
    logic clk;
    logic rst_n;

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // ============================================================
    //  Interface
    // ============================================================
    rv_l1_if #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .LINE_WIDTH (LINE_WIDTH)
    ) vif (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // ============================================================
    //  DUT
    // ============================================================
    l1_cache #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .LINE_WIDTH (LINE_WIDTH),
        .NUM_SETS   (NUM_SETS),
        .NUM_WAYS   (NUM_WAYS)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        // CPU side
        .req_valid      (vif.req_valid),
        .req_ready      (vif.req_ready),
        .req_addr       (vif.req_addr),
        .req_wr         (vif.req_wr),
        .req_wdata      (vif.req_wdata),
        .req_wmask      (vif.req_wmask),
        .resp_valid     (vif.resp_valid),
        .resp_rdata     (vif.resp_rdata),
        .resp_hit       (vif.resp_hit),
        // Memory side
        .mem_req_valid  (vif.mem_req_valid),
        .mem_req_ready  (vif.mem_req_ready),
        .mem_req_addr   (vif.mem_req_addr),
        .mem_req_wr     (vif.mem_req_wr),
        .mem_req_wdata  (vif.mem_req_wdata),
        .mem_wr_ack     (vif.mem_wr_ack),
        .mem_resp_valid (vif.mem_resp_valid),
        .mem_resp_rdata (vif.mem_resp_rdata)
    );

    // ============================================================
    //  Backing memory model
    // ============================================================
    logic [LINE_WIDTH-1:0] backing_mem [logic [ADDR_WIDTH-1:0]];

    function automatic logic [ADDR_WIDTH-1:0] align_addr(
        input logic [ADDR_WIDTH-1:0] a
    );
        return {a[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
    endfunction

    function automatic logic [LINE_WIDTH-1:0] gen_line(
        input logic [ADDR_WIDTH-1:0] line_addr
    );
        return {line_addr + 32'hC,
                line_addr + 32'h8,
                line_addr + 32'h4,
                line_addr + 32'h0};
    endfunction

    // ============================================================
    //  Memory responder (south-side model)
    //  Mirrors the standalone test's memory responder exactly.
    // ============================================================
    initial begin
        vif.mem_req_ready  = 1'b0;
        vif.mem_resp_valid = 1'b0;
        vif.mem_resp_rdata = '0;
        vif.mem_wr_ack     = 1'b0;

        forever begin
            @(posedge clk iff (vif.mem_req_valid === 1'b1));

            begin
                automatic logic [ADDR_WIDTH-1:0] capt_addr  = vif.mem_req_addr;
                automatic logic                  capt_wr    = vif.mem_req_wr;
                automatic logic [LINE_WIDTH-1:0] capt_wdata = vif.mem_req_wdata;

                @(negedge clk);
                vif.mem_req_ready = 1'b1;
                @(negedge clk);
                vif.mem_req_ready = 1'b0;

                if (capt_wr) begin
                    // Writeback
                    backing_mem[align_addr(capt_addr)] = capt_wdata;
                    repeat (2) @(posedge clk);
                    @(negedge clk);
                    vif.mem_wr_ack = 1'b1;
                    @(negedge clk);
                    vif.mem_wr_ack = 1'b0;
                end else begin
                    // Fill
                    repeat (3) @(posedge clk);
                    @(negedge clk);
                    begin
                        automatic logic [ADDR_WIDTH-1:0] la = align_addr(capt_addr);
                        if (backing_mem.exists(la))
                            vif.mem_resp_rdata = backing_mem[la];
                        else
                            vif.mem_resp_rdata = gen_line(la);
                    end
                    vif.mem_resp_valid = 1'b1;
                    @(negedge clk);
                    vif.mem_resp_valid = 1'b0;
                    vif.mem_resp_rdata = '0;
                end
            end
        end
    end

    // ============================================================
    //  Reset sequence
    // ============================================================
    initial begin
        rst_n = 1'b0;
        vif.req_valid = 1'b0;
        vif.req_addr  = '0;
        vif.req_wr    = 1'b0;
        vif.req_wdata = '0;
        vif.req_wmask = '0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
    end

    // ============================================================
    //  UVM entry point
    // ============================================================
    initial begin
        uvm_config_db #(virtual rv_l1_if)::set(null, "*.env.agent.*", "vif", vif);
        run_test();
    end

    // ============================================================
    //  Waveform dump
    // ============================================================
    initial begin
        $dumpfile("rv_l1_uvc.vcd");
        $dumpvars(0, rv_l1_uvc);
    end

    // ============================================================
    //  Global watchdog
    // ============================================================
    initial begin
        #1_000_000;
        `uvm_fatal("WATCHDOG", "Global timeout reached")
    end

endmodule : rv_l1_uvc
