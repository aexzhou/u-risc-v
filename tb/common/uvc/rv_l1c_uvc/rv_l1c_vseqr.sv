class rv_l1c_vseqr extends uvm_sequencer;
    `uvm_component_utils(rv_l1c_vseqr)

    uvm_sequencer #(rv_l1c_transaction) cpu_seqr;
    clk_rst_sequencer                   clk_rst_seqr;

    function new(string name = "rv_l1c_vseqr", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : rv_l1c_vseqr
