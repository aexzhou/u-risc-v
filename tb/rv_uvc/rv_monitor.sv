// RISC-V Monitor
// Observes DUT signals and sends transactions to scoreboard

`ifndef RISCV_MONITOR_SV
`define RISCV_MONITOR_SV

class riscv_monitor extends uvm_monitor;
    `uvm_component_utils(riscv_monitor)

    virtual riscv_if vif;
    uvm_analysis_port#(riscv_transaction) ap;

    // Variables to track pipeline
    bit [63:0] last_pc;
    bit [31:0] last_instr;

    function new(string name = "riscv_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if(!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
    endfunction

    virtual task run_phase(uvm_phase phase);
        riscv_transaction txn;

        // Wait for reset to be released
        @(negedge vif.rst);

        forever begin
            @(posedge vif.clk);

            // Monitor instruction fetch
            if (vif.pc_write && !vif.rst) begin
                txn = riscv_transaction::type_id::create("txn");

                // Capture instruction fetch
                txn.pc = vif.pc_out;
                txn.instruction = vif.iMem_out;

                `uvm_info(get_type_name(),
                         $sformatf("Monitored: PC=0x%0h, Instr=0x%0h",
                                   txn.pc, txn.instruction),
                         UVM_HIGH)

                // Send to scoreboard
                ap.write(txn);
            end

            // Monitor register writes (in WB stage)
            if (vif.reg_write && !vif.rst && vif.wb_rd != 0) begin
                `uvm_info(get_type_name(),
                         $sformatf("Register Write: x%0d = 0x%0h",
                                   vif.wb_rd, vif.write_data),
                         UVM_MEDIUM)
            end
        end
    endtask

endclass

`endif // RISCV_MONITOR_SV
