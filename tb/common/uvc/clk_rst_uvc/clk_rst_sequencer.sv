class clk_rst_sequencer extends uvm_sequencer #(clk_rst_seq_item);
    `uvm_component_utils(clk_rst_sequencer)

    function new(string name = "clk_rst_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : clk_rst_sequencer
