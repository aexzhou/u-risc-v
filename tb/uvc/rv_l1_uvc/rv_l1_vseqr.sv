class rv_l1_vseqr extends uvm_sequencer;
    `uvm_component_utils(rv_l1_vseqr)

    uvm_sequencer #(rv_l1_transaction) cpu_seqr;

    function new(string name = "rv_l1_vseqr", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : rv_l1_vseqr
