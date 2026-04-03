class rv_l1c_monitor extends uvm_monitor;
    `uvm_component_utils(rv_l1c_monitor)

    virtual rv_l1c_if vif;

    uvm_analysis_port #(rv_l1c_transaction) ap;

    function new(string name = "rv_l1c_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual rv_l1c_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
    endfunction

    virtual task run_phase(uvm_phase phase);
        rv_l1c_transaction txn;

        // Wait for reset de-assertion
        @(posedge vif.rst_n);
        @(posedge vif.clk);

        forever begin
            // Wait for a request handshake (req_valid && req_ready)
            @(posedge vif.clk);
            if (vif.req_valid && vif.req_ready) begin
                txn = rv_l1c_transaction::type_id::create("txn");
                txn.addr  = vif.req_addr;
                txn.wr    = vif.req_wr;
                txn.wdata = vif.req_wdata;
                txn.wmask = vif.req_wmask;

                // Wait for response
                wait_for_response(txn);

                `uvm_info(get_type_name(), {"Observed: ", txn.convert2string()}, UVM_HIGH)
                ap.write(txn);
            end
        end
    endtask

    virtual task wait_for_response(rv_l1c_transaction txn);
        for (int i = 0; i < 200; i++) begin
            @(posedge vif.clk);
            if (vif.resp_valid) begin
                txn.rdata = vif.resp_rdata;
                txn.hit   = vif.resp_hit;
                return;
            end
        end
        `uvm_error(get_type_name(),
            $sformatf("Timeout waiting for resp_valid (addr=0x%08h)", txn.addr))
    endtask

endclass : rv_l1c_monitor
