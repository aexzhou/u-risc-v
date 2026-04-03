class rv_l1c_coverage extends uvm_subscriber #(rv_l1c_transaction);
    `uvm_component_utils(rv_l1c_coverage)

    rv_l1c_transaction txn;

    covergroup cg_l1_ops;
        option.per_instance = 1;

        cp_op : coverpoint txn.wr {
            bins read  = {0};
            bins write = {1};
        }

        cp_hit : coverpoint txn.hit {
            bins miss = {0};
            bins hit  = {1};
        }

        cp_wmask : coverpoint txn.wmask iff (txn.wr) {
            bins full_word    = {4'hF};
            bins byte0_only   = {4'h1};
            bins byte1_only   = {4'h2};
            bins byte2_only   = {4'h4};
            bins byte3_only   = {4'h8};
            bins partial[]    = {4'h3, 4'h5, 4'h6, 4'h9, 4'hA, 4'hC};
            bins others       = default;
        }

        cp_set_index : coverpoint txn.addr[7:4] {
            bins sets[] = {[0:15]};
        }

        cp_word_sel : coverpoint txn.addr[3:2] {
            bins words[] = {[0:3]};
        }

        cx_op_hit : cross cp_op, cp_hit;

        cx_op_set : cross cp_op, cp_set_index;
    endgroup

    function new(string name = "rv_l1c_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_l1_ops = new();
    endfunction

    virtual function void write(rv_l1c_transaction t);
        txn = t;
        cg_l1_ops.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
            $sformatf("Coverage: %.1f%%", cg_l1_ops.get_coverage()), UVM_LOW)
    endfunction

endclass : rv_l1c_coverage
