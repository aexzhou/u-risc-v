class clk_rst_agent extends uvm_agent;
    `uvm_component_utils(clk_rst_agent)

    clk_rst_driver      driver;
    clk_rst_sequencer   sequencer;

    function new(string name = "clk_rst_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver    = clk_rst_driver::type_id::create("driver", this);
            sequencer = clk_rst_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass : clk_rst_agent
