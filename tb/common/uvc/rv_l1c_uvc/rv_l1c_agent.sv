class rv_l1c_agent extends uvm_agent;
    `uvm_component_utils(rv_l1c_agent)

    rv_l1c_driver                          driver;
    rv_l1c_monitor                         monitor;
    uvm_sequencer #(rv_l1c_transaction)    sequencer;

    function new(string name = "rv_l1c_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = rv_l1c_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            driver    = rv_l1c_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer #(rv_l1c_transaction)::type_id::create("sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass : rv_l1c_agent
