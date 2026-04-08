class rv_l1c_env extends uvm_env;
    `uvm_component_utils(rv_l1c_env)

    clk_rst_agent     clk_rst_agt;
    rv_l1c_agent      agent;
    rv_l1c_scoreboard scoreboard;
    rv_l1c_coverage   coverage;
    rv_l1c_vseqr      vseqr;

    function new(string name = "rv_l1c_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        clk_rst_agt = clk_rst_agent::type_id::create("clk_rst_agt", this);
        agent       = rv_l1c_agent::type_id::create("agent", this);
        scoreboard  = rv_l1c_scoreboard::type_id::create("scoreboard", this);
        coverage    = rv_l1c_coverage::type_id::create("coverage", this);
        vseqr       = rv_l1c_vseqr::type_id::create("vseqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.ap_imp);
        agent.monitor.ap.connect(coverage.analysis_export);
        vseqr.cpu_seqr     = agent.sequencer;
        vseqr.clk_rst_seqr = clk_rst_agt.sequencer;
    endfunction

endclass : rv_l1c_env
