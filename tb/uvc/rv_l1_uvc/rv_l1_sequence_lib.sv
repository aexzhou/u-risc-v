// ================================================================
//  Base sequence
// ================================================================
class rv_l1_base_sequence extends uvm_sequence #(rv_l1_transaction);
    `uvm_object_utils(rv_l1_base_sequence)

    function new(string name = "rv_l1_base_sequence");
        super.new(name);
    endfunction

    // Helper: build address from {tag, index, word_sel, 2'b00}
    function automatic bit [31:0] make_addr(
        bit [23:0] tag,
        bit [3:0]  idx,
        bit [1:0]  word
    );
        return {tag, idx, word, 2'b00};
    endfunction

    // Helper: send a read
    task do_read(bit [31:0] addr);
        rv_l1_transaction txn = rv_l1_transaction::type_id::create("txn");
        start_item(txn);
        txn.wr    = 0;
        txn.addr  = addr;
        txn.wdata = 0;
        txn.wmask = 4'h0;
        finish_item(txn);
    endtask

    // Helper: send a write
    task do_write(bit [31:0] addr, bit [31:0] data, bit [3:0] mask = 4'hF);
        rv_l1_transaction txn = rv_l1_transaction::type_id::create("txn");
        start_item(txn);
        txn.wr    = 1;
        txn.addr  = addr;
        txn.wdata = data;
        txn.wmask = mask;
        finish_item(txn);
    endtask

endclass : rv_l1_base_sequence


// ================================================================
//  Smoke test: cold read miss -> read hit -> write hit -> read-back
//  (Tests 1-4 from standalone)
// ================================================================
class rv_l1_smoke_sequence extends rv_l1_base_sequence;
    `uvm_object_utils(rv_l1_smoke_sequence)

    function new(string name = "rv_l1_smoke_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] addr;

        `uvm_info(get_type_name(), "Cold read miss", UVM_LOW)
        addr = make_addr(24'h01, 4'h0, 2'h0);
        do_read(addr);

        `uvm_info(get_type_name(), "Read hit (same address)", UVM_LOW)
        do_read(addr);

        `uvm_info(get_type_name(), "Read hit (different word in same line)", UVM_LOW)
        addr = make_addr(24'h01, 4'h0, 2'h2);
        do_read(addr);

        `uvm_info(get_type_name(), "Write hit + read-back", UVM_LOW)
        addr = make_addr(24'h01, 4'h0, 2'h1);
        do_write(addr, 32'hDEAD_BEEF);
        do_read(addr);
    endtask

endclass : rv_l1_smoke_sequence


// ================================================================
//  Byte-masked write test (Test 5 from standalone)
// ================================================================
class rv_l1_byte_mask_sequence extends rv_l1_base_sequence;
    `uvm_object_utils(rv_l1_byte_mask_sequence)

    function new(string name = "rv_l1_byte_mask_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] addr = make_addr(24'h01, 4'h0, 2'h3);

        `uvm_info(get_type_name(), "Byte-masked write (mask=0101)", UVM_LOW)
        do_read(addr);
        do_write(addr, 32'hAA_BB_CC_DD, 4'b0101);
        do_read(addr);
    endtask

endclass : rv_l1_byte_mask_sequence


// ================================================================
//  Multi-set and multi-way test (Tests 6-8 from standalone)
// ================================================================
class rv_l1_multi_way_sequence extends rv_l1_base_sequence;
    `uvm_object_utils(rv_l1_multi_way_sequence)

    function new(string name = "rv_l1_multi_way_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] addr_a, addr_b;

        `uvm_info(get_type_name(), "Read miss in different set (set 5)", UVM_LOW)
        addr_a = make_addr(24'h02, 4'h5, 2'h0);
        do_read(addr_a);

        `uvm_info(get_type_name(), "Fill second way in same set", UVM_LOW)
        addr_b = make_addr(24'h03, 4'h5, 2'h0);
        do_read(addr_b);

        `uvm_info(get_type_name(), "Both ways occupied, verify hits", UVM_LOW)
        do_read(addr_a);
        do_read(addr_b);
    endtask

endclass : rv_l1_multi_way_sequence


// ================================================================
//  Dirty eviction test (Test 9 from standalone)
// ================================================================
class rv_l1_eviction_sequence extends rv_l1_base_sequence;
    `uvm_object_utils(rv_l1_eviction_sequence)

    function new(string name = "rv_l1_eviction_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] a0, a1, a2;

        a0 = make_addr(24'h10, 4'hA, 2'h0);
        a1 = make_addr(24'h20, 4'hA, 2'h0);
        a2 = make_addr(24'h30, 4'hA, 2'h0);

        `uvm_info(get_type_name(), "Fill way 0", UVM_LOW)
        do_read(a0);

        `uvm_info(get_type_name(), "Fill way 1", UVM_LOW)
        do_read(a1);

        `uvm_info(get_type_name(), "Dirty way 0", UVM_LOW)
        do_write(a0, 32'hCAFE_BABE);

        `uvm_info(get_type_name(), "Touch way 1 (make way 0 LRU)", UVM_LOW)
        do_read(a1);

        `uvm_info(get_type_name(), "Evict dirty way 0 with third tag", UVM_LOW)
        do_read(a2);
    endtask

endclass : rv_l1_eviction_sequence


// ================================================================
//  Sequential reads across sets (Test 10 from standalone)
// ================================================================
class rv_l1_sequential_sequence extends rv_l1_base_sequence;
    `uvm_object_utils(rv_l1_sequential_sequence)

    function new(string name = "rv_l1_sequential_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), "Sequential reads across sets 0-7", UVM_LOW)
        for (int s = 0; s < 8; s++) begin
            do_read(make_addr(24'hFF, s[3:0], 2'h0));
        end
    endtask

endclass : rv_l1_sequential_sequence


// ================================================================
//  Write miss / write-allocate test (Test 11 from standalone)
// ================================================================
class rv_l1_write_allocate_sequence extends rv_l1_base_sequence;
    `uvm_object_utils(rv_l1_write_allocate_sequence)

    function new(string name = "rv_l1_write_allocate_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] addr = make_addr(24'hAB, 4'hC, 2'h0);

        `uvm_info(get_type_name(), "Write miss (write-allocate)", UVM_LOW)
        do_write(addr, 32'h1234_5678);
        do_read(addr);
    endtask

endclass : rv_l1_write_allocate_sequence


// ================================================================
//  Full regression: runs all directed sequences back-to-back
// ================================================================
class rv_l1_full_sequence extends rv_l1_base_sequence;
    `uvm_object_utils(rv_l1_full_sequence)

    function new(string name = "rv_l1_full_sequence");
        super.new(name);
    endfunction

    virtual task body();
        rv_l1_smoke_sequence          smoke_seq;
        rv_l1_byte_mask_sequence      bmask_seq;
        rv_l1_multi_way_sequence      mway_seq;
        rv_l1_eviction_sequence       evict_seq;
        rv_l1_sequential_sequence     seq_seq;
        rv_l1_write_allocate_sequence walloc_seq;

        smoke_seq  = rv_l1_smoke_sequence::type_id::create("smoke_seq");
        bmask_seq  = rv_l1_byte_mask_sequence::type_id::create("bmask_seq");
        mway_seq   = rv_l1_multi_way_sequence::type_id::create("mway_seq");
        evict_seq  = rv_l1_eviction_sequence::type_id::create("evict_seq");
        seq_seq    = rv_l1_sequential_sequence::type_id::create("seq_seq");
        walloc_seq = rv_l1_write_allocate_sequence::type_id::create("walloc_seq");

        smoke_seq.start(m_sequencer);
        bmask_seq.start(m_sequencer);
        mway_seq.start(m_sequencer);
        evict_seq.start(m_sequencer);
        seq_seq.start(m_sequencer);
        walloc_seq.start(m_sequencer);
    endtask

endclass : rv_l1_full_sequence


// ================================================================
//  Random test sequence
// ================================================================
class rv_l1_random_sequence extends rv_l1_base_sequence;
    `uvm_object_utils(rv_l1_random_sequence)

    rand int unsigned num_transactions;

    constraint num_txn_c {
        num_transactions inside {[20:100]};
    }

    function new(string name = "rv_l1_random_sequence");
        super.new(name);
    endfunction

    virtual task body();
        rv_l1_transaction txn;

        `uvm_info(get_type_name(),
            $sformatf("Running %0d random transactions", num_transactions), UVM_LOW)

        for (int i = 0; i < num_transactions; i++) begin
            txn = rv_l1_transaction::type_id::create($sformatf("txn_%0d", i));
            start_item(txn);
            if (!txn.randomize()) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end
            finish_item(txn);
        end
    endtask

endclass : rv_l1_random_sequence
