// RISC-V Environment
// Top-level UVM environment containing agent and scoreboard

`ifndef RISCV_ENV_SV
`define RISCV_ENV_SV

class riscv_env extends uvm_env;
    `uvm_component_utils(riscv_env)

    riscv_agent agent;
    riscv_scoreboard scoreboard;

    function new(string name = "riscv_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent = riscv_agent::type_id::create("agent", this);
        scoreboard = riscv_scoreboard::type_id::create("scoreboard", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect monitor to scoreboard
        agent.monitor.ap.connect(scoreboard.ap_imp);
    endfunction

endclass

`endif // RISCV_ENV_SV
