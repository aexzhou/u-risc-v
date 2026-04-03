// RISC-V Agent
// Contains driver, monitor, and sequencer

`ifndef RISCV_AGENT_SV
`define RISCV_AGENT_SV

class riscv_agent extends uvm_agent;
    `uvm_component_utils(riscv_agent)

    riscv_driver driver;
    riscv_monitor monitor;
    uvm_sequencer#(riscv_transaction) sequencer;

    function new(string name = "riscv_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        monitor = riscv_monitor::type_id::create("monitor", this);

        if (get_is_active() == UVM_ACTIVE) begin
            driver = riscv_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer#(riscv_transaction)::type_id::create("sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass

`endif // RISCV_AGENT_SV
