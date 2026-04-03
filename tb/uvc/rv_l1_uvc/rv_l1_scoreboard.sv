class rv_l1_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(rv_l1_scoreboard)

    uvm_analysis_imp #(rv_l1_transaction, rv_l1_scoreboard) ap_imp;

    // Reference model parameters (must match DUT)
    localparam ADDR_WIDTH     = 32;
    localparam DATA_WIDTH     = 32;
    localparam LINE_WIDTH     = 128;
    localparam NUM_SETS       = 16;
    localparam NUM_WAYS       = 2;
    localparam OFFSET_BITS    = $clog2(LINE_WIDTH / 8);       // 4
    localparam INDEX_BITS     = $clog2(NUM_SETS);              // 4
    localparam WORDS_PER_LINE = LINE_WIDTH / DATA_WIDTH;       // 4
    localparam WORD_SEL_BITS  = $clog2(WORDS_PER_LINE);        // 2
    localparam TAG_BITS       = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

    // Reference cache model
    typedef struct {
        bit                  valid;
        bit                  dirty;
        bit [TAG_BITS-1:0]   tag;
        bit [LINE_WIDTH-1:0] data;
    } cache_way_t;

    cache_way_t ref_cache [NUM_SETS][NUM_WAYS];
    bit         ref_lru   [NUM_SETS];

    // Backing memory (associative array keyed by line-aligned address)
    bit [LINE_WIDTH-1:0] backing_mem [bit [ADDR_WIDTH-1:0]];

    // Counters
    int transactions_received;
    int transactions_passed;
    int transactions_failed;

    function new(string name = "rv_l1_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);
        transactions_received = 0;
        transactions_passed   = 0;
        transactions_failed   = 0;

        // Clear reference model
        for (int s = 0; s < NUM_SETS; s++) begin
            ref_lru[s] = 0;
            for (int w = 0; w < NUM_WAYS; w++) begin
                ref_cache[s][w].valid = 0;
                ref_cache[s][w].dirty = 0;
                ref_cache[s][w].tag   = '0;
                ref_cache[s][w].data  = '0;
            end
        end
    endfunction

    // Address field extraction
    function automatic bit [TAG_BITS-1:0] get_tag(bit [ADDR_WIDTH-1:0] addr);
        return addr[ADDR_WIDTH-1 -: TAG_BITS];
    endfunction

    function automatic bit [INDEX_BITS-1:0] get_index(bit [ADDR_WIDTH-1:0] addr);
        return addr[OFFSET_BITS +: INDEX_BITS];
    endfunction

    function automatic bit [WORD_SEL_BITS-1:0] get_word(bit [ADDR_WIDTH-1:0] addr);
        return addr[2 +: WORD_SEL_BITS];
    endfunction

    function automatic bit [ADDR_WIDTH-1:0] align_addr(bit [ADDR_WIDTH-1:0] addr);
        return {addr[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
    endfunction

    // Generate default line data (matches standalone test pattern)
    function automatic bit [LINE_WIDTH-1:0] gen_line(bit [ADDR_WIDTH-1:0] line_addr);
        return {line_addr + 32'hC, line_addr + 32'h8, line_addr + 32'h4, line_addr + 32'h0};
    endfunction

    // Read backing memory (returns default pattern if not written)
    function automatic bit [LINE_WIDTH-1:0] read_backing(bit [ADDR_WIDTH-1:0] addr);
        bit [ADDR_WIDTH-1:0] la = align_addr(addr);
        return backing_mem.exists(la) ? backing_mem[la] : gen_line(la);
    endfunction

    // Extract word from a cache line
    function automatic bit [DATA_WIDTH-1:0] line_word(
        bit [LINE_WIDTH-1:0]   line,
        bit [WORD_SEL_BITS-1:0] sel
    );
        return line[sel * DATA_WIDTH +: DATA_WIDTH];
    endfunction

    // Byte-masked write into a single word of a line
    function automatic bit [LINE_WIDTH-1:0] line_write_word(
        bit [LINE_WIDTH-1:0]    old_line,
        bit [WORD_SEL_BITS-1:0] sel,
        bit [DATA_WIDTH-1:0]    wdata,
        bit [3:0]               wmask
    );
        bit [LINE_WIDTH-1:0] new_line;
        bit [DATA_WIDTH-1:0] old_word, merged;
        new_line = old_line;
        old_word = old_line[sel * DATA_WIDTH +: DATA_WIDTH];
        merged[7:0]   = wmask[0] ? wdata[7:0]   : old_word[7:0];
        merged[15:8]  = wmask[1] ? wdata[15:8]  : old_word[15:8];
        merged[23:16] = wmask[2] ? wdata[23:16] : old_word[23:16];
        merged[31:24] = wmask[3] ? wdata[31:24] : old_word[31:24];
        new_line[sel * DATA_WIDTH +: DATA_WIDTH] = merged;
        return new_line;
    endfunction

    // Main check function called by analysis port
    virtual function void write(rv_l1_transaction txn);
        bit [TAG_BITS-1:0]      tag;
        bit [INDEX_BITS-1:0]    idx;
        bit [WORD_SEL_BITS-1:0] word;
        bit                     exp_hit;
        bit [DATA_WIDTH-1:0]    exp_rdata;
        int                     hit_way;

        transactions_received++;

        tag  = get_tag(txn.addr);
        idx  = get_index(txn.addr);
        word = get_word(txn.addr);

        // Lookup in reference model
        hit_way = -1;
        for (int w = 0; w < NUM_WAYS; w++) begin
            if (ref_cache[idx][w].valid && ref_cache[idx][w].tag == tag) begin
                hit_way = w;
                break;
            end
        end

        exp_hit = (hit_way >= 0);

        if (exp_hit) begin
            // Cache hit
            exp_rdata = line_word(ref_cache[idx][hit_way].data, word);

            if (txn.wr) begin
                // Write hit: update cache line
                ref_cache[idx][hit_way].data = line_write_word(
                    ref_cache[idx][hit_way].data, word, txn.wdata, txn.wmask);
                ref_cache[idx][hit_way].dirty = 1;
            end

            ref_lru[idx] = ~hit_way[0];
        end else begin
            // Cache miss
            bit victim_way;
            bit [ADDR_WIDTH-1:0] la = align_addr(txn.addr);
            bit [LINE_WIDTH-1:0] fill_data;

            victim_way = ref_lru[idx];

            // If victim is dirty, write back to backing memory
            if (ref_cache[idx][victim_way].valid && ref_cache[idx][victim_way].dirty) begin
                bit [ADDR_WIDTH-1:0] wb_addr;
                wb_addr = {ref_cache[idx][victim_way].tag, idx, {OFFSET_BITS{1'b0}}};
                backing_mem[wb_addr] = ref_cache[idx][victim_way].data;
            end

            // Fill from backing memory
            fill_data = read_backing(la);

            if (txn.wr) begin
                // Write-allocate: fill then apply write
                ref_cache[idx][victim_way].data = line_write_word(
                    fill_data, word, txn.wdata, txn.wmask);
                ref_cache[idx][victim_way].dirty = 1;
            end else begin
                ref_cache[idx][victim_way].data = fill_data;
                ref_cache[idx][victim_way].dirty = 0;
            end

            ref_cache[idx][victim_way].valid = 1;
            ref_cache[idx][victim_way].tag   = tag;
            ref_lru[idx] = ~victim_way;

            exp_rdata = line_word(ref_cache[idx][victim_way].data, word);
        end

        // Check hit/miss
        if (txn.hit !== exp_hit) begin
            `uvm_error(get_type_name(),
                $sformatf("HIT mismatch: addr=0x%08h got=%0b exp=%0b",
                          txn.addr, txn.hit, exp_hit))
            transactions_failed++;
        end else if (!txn.wr) begin
            // Check read data (only for reads)
            if (txn.rdata !== exp_rdata) begin
                `uvm_error(get_type_name(),
                    $sformatf("DATA mismatch: addr=0x%08h got=0x%08h exp=0x%08h",
                              txn.addr, txn.rdata, exp_rdata))
                transactions_failed++;
            end else begin
                transactions_passed++;
            end
        end else begin
            transactions_passed++;
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
            $sformatf("\n========================================\n  Scoreboard Results\n  Received: %0d  Passed: %0d  Failed: %0d\n========================================",
                      transactions_received, transactions_passed, transactions_failed),
            UVM_LOW)

        if (transactions_failed > 0)
            `uvm_error(get_type_name(),
                $sformatf("%0d transaction(s) FAILED", transactions_failed))
    endfunction

endclass : rv_l1_scoreboard
