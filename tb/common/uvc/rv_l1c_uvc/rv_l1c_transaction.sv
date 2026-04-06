class rv_l1c_transaction extends uvm_sequence_item;

    // Stimulus fields
    rand bit [31:0] addr;
    rand bit        wr;
    rand bit [31:0] wdata;
    rand bit [3:0]  wmask;

    //The following fields are set by monitor
    bit [31:0] rdata;
    bit        hit;

    `uvm_object_utils_begin(rv_l1c_transaction)
        `uvm_field_int(addr,   UVM_ALL_ON)
        `uvm_field_int(wr,     UVM_ALL_ON)
        `uvm_field_int(wdata,  UVM_ALL_ON)
        `uvm_field_int(wmask,  UVM_ALL_ON)
        `uvm_field_int(rdata,  UVM_ALL_ON)
        `uvm_field_int(hit,    UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "rv_l1c_transaction");
        super.new(name);
    endfunction

    constraint addr_word_aligned_c {
        addr[1:0] == 2'b00;
    }

    constraint wmask_default_c {
        soft wmask == 4'hF; // full word
    }

    constraint read_fields_c {
        !wr -> wdata == 32'h0;
        !wr -> wmask == 4'h0;
    }

    function string convert2string();
        return $sformatf("%s addr=0x%08h wdata=0x%08h wmask=0x%01h | rdata=0x%08h hit=%0b",
                         wr ? "WR" : "RD", addr, wdata, wmask, rdata, hit);
    endfunction

endclass : rv_l1c_transaction
