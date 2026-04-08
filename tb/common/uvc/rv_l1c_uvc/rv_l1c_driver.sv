class rv_l1c_driver extends uvm_driver #(rv_l1c_transaction);
    `uvm_component_utils(rv_l1c_driver)

    virtual rv_l1c_if vif;

    int unsigned timeout_cycles = 200;

    function new(string name = "rv_l1c_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual rv_l1c_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
    endfunction

    virtual task run_phase(uvm_phase phase);
        rv_l1c_transaction txn;

        // Wait for reset de-assertion
        @(posedge vif.rst_n);
        repeat (2) @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(txn);
            drive_transaction(txn);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_transaction(rv_l1c_transaction txn);
        // Drive request
        @(negedge vif.clk);
        vif.req_valid <= 1'b1;
        vif.req_addr  <= txn.addr;
        vif.req_wr    <= txn.wr;
        vif.req_wdata <= txn.wdata;
        vif.req_wmask <= txn.wmask;

        // Wait for req_ready handshake
        for (int i = 0; i < timeout_cycles; i++) begin
            @(posedge vif.clk);
            if (vif.req_ready) begin
                @(negedge vif.clk);
                vif.req_valid <= 1'b0;

                // Wait for resp_valid
                for (int j = 0; j < timeout_cycles; j++) begin
                    @(posedge vif.clk);
                    if (vif.resp_valid) begin
                        txn.rdata = vif.resp_rdata;
                        txn.hit   = vif.resp_hit;
                        return;
                    end
                end

                `uvm_error(get_type_name(),
                    $sformatf("Timeout waiting for resp_valid (addr=0x%08h)", txn.addr))
                return;
            end
        end

        `uvm_error(get_type_name(),
            $sformatf("Timeout waiting for req_ready (addr=0x%08h)", txn.addr))
        vif.req_valid <= 1'b0;
    endtask

endclass : rv_l1c_driver
