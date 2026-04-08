class clk_rst_env extends uvm_env;
    `uvm_component_utils(clk_rst_env)

    clk_rst_agent agent;

    function new(string name = "clk_rst_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = clk_rst_agent::type_id::create("agent", this);
    endfunction

endclass : clk_rst_env
