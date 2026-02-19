// RISC-V Driver
// Drives stimulus into the DUT

`ifndef RISCV_DRIVER_SV
`define RISCV_DRIVER_SV

class riscv_driver extends uvm_driver#(riscv_transaction);
    `uvm_component_utils(riscv_driver)

    virtual riscv_if vif;

    function new(string name = "riscv_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
    endfunction

    virtual task run_phase(uvm_phase phase);
        riscv_transaction txn;

        forever begin
            seq_item_port.get_next_item(txn);
            drive_transaction(txn);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_transaction(riscv_transaction txn);
        `uvm_info(get_type_name(), $sformatf("Driving transaction: %s", txn.convert2string()), UVM_HIGH)

        // In this simple testbench, we don't actively drive anything
        // The instruction memory is pre-loaded
        // This driver would be more useful for a bus-functional model

        // Wait for a clock cycle
        @(posedge vif.clk);
    endtask

endclass

`endif // RISCV_DRIVER_SV
