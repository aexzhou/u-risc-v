// SystemVerilog bringup tests for RISC-V CPU split by scenario.

/*
* to make a certain module in this testbench, run "make test_datapath_bringup
* TB_BRINGUP_NAME=<module_name>"
*/


/* verilator lint_off DECLFILENAME */
module cpu_bringup_tb_env #(
    parameter string TB_NAME = "cpu_bringup",
    parameter string VCD_FILE = "waveform.vcd"
);

    logic clk;
    logic rst;

    rv_cpu u_cpu (
        .clk(clk),
        .rst_n(~rst)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile(VCD_FILE);
        $dumpvars(0);
    end

    task automatic init_imem_with_nops();
        for (int i = 0; i < 256; i++)
            u_cpu.u_datapath.u_imem.memory[i] = 32'b00000000000000000000000000010011; // addi x0, x0, 0
    endtask

    task automatic apply_reset();
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    endtask

    task automatic run_cycles(input int cycles);
        repeat (cycles) @(posedge clk);
    endtask

    initial begin
        #10000;
        $display("[%s] ERROR: Simulation timeout!", TB_NAME);
        $finish;
    end

    always @(posedge clk) begin
        if (!rst && u_cpu.u_datapath.pc_write) begin
            $display("[%s] Time %0t: PC=0x%h, Instruction=0x%h",
                     TB_NAME, $time, u_cpu.u_datapath.pc_out, u_cpu.u_datapath.imem_out);
        end
    end

endmodule
/* verilator lint_on DECLFILENAME */

module test_cpu_bringup_arithmetic;
    cpu_bringup_tb_env #(.TB_NAME("arith"), .VCD_FILE("waveform_arith.vcd")) env();
    bit pass;

    initial begin
        pass = 1'b1;
        env.init_imem_with_nops();

        // addi x1, x0, 5
        env.u_cpu.u_datapath.u_imem.memory[0] = 32'b00000000010100000000000010010011;
        // addi x2, x0, 6
        env.u_cpu.u_datapath.u_imem.memory[1] = 32'b00000000011000000000000100010011;
        // addi x3, x1, 7
        env.u_cpu.u_datapath.u_imem.memory[2] = 32'b00000000011100001000000110010011;
        // add x4, x1, x2
        env.u_cpu.u_datapath.u_imem.memory[3] = 32'b00000000001000001000001000110011;
        // sub x4, x4, x2
      //  env.u_cpu.u_datapath.u_imem.memory[4] = 32'b01000000001000100000001000110011;

        env.apply_reset();
        env.run_cycles(20);

        if (env.u_cpu.u_datapath.u_regfile.X[1] != 64'h5) pass = 1'b0;
        if (env.u_cpu.u_datapath.u_regfile.X[2] != 64'h6) pass = 1'b0;
        if (env.u_cpu.u_datapath.u_regfile.X[3] != 64'hc) pass = 1'b0;
        if (env.u_cpu.u_datapath.u_regfile.X[4] != 64'hb) pass = 1'b0;

        $display("[arith] X1=0x%0h X2=0x%0h X3=0x%0h X4=0x%0h => %s",
                 env.u_cpu.u_datapath.u_regfile.X[1],
                 env.u_cpu.u_datapath.u_regfile.X[2],
                 env.u_cpu.u_datapath.u_regfile.X[3],
                 env.u_cpu.u_datapath.u_regfile.X[4],
                 pass ? "PASS" : "FAIL");
        $finish;
    end
endmodule

module test_cpu_bringup_mem_hazard;
    cpu_bringup_tb_env #(.TB_NAME("mem_hazard"), .VCD_FILE("waveform_mem_hazard.vcd")) env();
    bit pass;

    initial begin
        pass = 1'b1;
        env.init_imem_with_nops();

        // Setup sequence
        env.u_cpu.u_datapath.u_imem.memory[0] = 32'b00000000010100000000000010010011; // addi x1, x0, 5
        env.u_cpu.u_datapath.u_imem.memory[1] = 32'b00000000011000000000000100010011; // addi x2, x0, 6
        env.u_cpu.u_datapath.u_imem.memory[2] = 32'b00000000011100001000000110010011; // addi x3, x1, 7
        // MEM hazard sequence
        env.u_cpu.u_datapath.u_imem.memory[3] = 32'b00000000001000001000000010110011; // add x1, x1, x2
        env.u_cpu.u_datapath.u_imem.memory[4] = 32'b00000000001100001111000010110011; // and x1, x1, x3
        env.u_cpu.u_datapath.u_imem.memory[5] = 32'b00000000010000001110000010110011; // or x1, x1, x4

        env.apply_reset();
        env.run_cycles(20);

        if (env.u_cpu.u_datapath.u_regfile.X[1] != 64'hd) pass = 1'b0;
        $display("[mem_hazard] X1=0x%0h => %s",
                 env.u_cpu.u_datapath.u_regfile.X[1],
                 pass ? "PASS" : "FAIL");
        $finish;
    end
endmodule

module test_cpu_bringup_memory;
    cpu_bringup_tb_env #(.TB_NAME("memory"), .VCD_FILE("waveform_memory.vcd")) env();
    bit pass;

    initial begin
        pass = 1'b1;
        env.init_imem_with_nops();

        env.u_cpu.u_datapath.u_imem.memory[0] = 32'b00000000010100000000000010010011; // addi x1, x0, 5
        env.u_cpu.u_datapath.u_imem.memory[1] = 32'b00000000011000000000000100010011; // addi x2, x0, 6
        env.u_cpu.u_datapath.u_imem.memory[2] = 32'b00000000001000001000001000110011; // add x4, x1, x2
        env.u_cpu.u_datapath.u_imem.memory[3] = 32'b00000000010000010010000000100011; // sw x4, 0(x2)
        env.u_cpu.u_datapath.u_imem.memory[4] = 32'b00000000000000010101000100000011; // lw x2, 0(x2)

        env.apply_reset();
        env.run_cycles(20);

        if (env.u_cpu.u_datapath.u_dmem.memory[0] != env.u_cpu.u_datapath.u_regfile.X[4]) pass = 1'b0;
        if (env.u_cpu.u_datapath.u_regfile.X[2] != env.u_cpu.u_datapath.u_dmem.memory[0]) pass = 1'b0;

        $display("[memory] dmem[0]=0x%0h X2=0x%0h X4=0x%0h => %s",
                 env.u_cpu.u_datapath.u_dmem.memory[0],
                 env.u_cpu.u_datapath.u_regfile.X[2],
                 env.u_cpu.u_datapath.u_regfile.X[4],
                 pass ? "PASS" : "FAIL");
        $finish;
    end
endmodule

module test_cpu_bringup_branch;
    cpu_bringup_tb_env #(.TB_NAME("branch"), .VCD_FILE("waveform_branch.vcd")) env();
    bit pass;

    initial begin
        pass = 1'b1;
        env.init_imem_with_nops();

        env.u_cpu.u_datapath.u_imem.memory[0]  = 32'b00000000010100000000000010010011; // addi x1, x0, 5
        env.u_cpu.u_datapath.u_imem.memory[1]  = 32'b00000000011000000000000100010011; // addi x2, x0, 6
        env.u_cpu.u_datapath.u_imem.memory[2]  = 32'b00000010000100000000111001100011; // beq x0, x1, #60 (not taken)
        env.u_cpu.u_datapath.u_imem.memory[3]  = 32'b00000000001000001000001000110011; // add x4, x1, x2
        env.u_cpu.u_datapath.u_imem.memory[4]  = 32'b00000010001000001001111001100011; // bne x1, x2, #60 (taken)
        env.u_cpu.u_datapath.u_imem.memory[5]  = 32'b00000000010100000000000010010011; // flushed
        env.u_cpu.u_datapath.u_imem.memory[6]  = 32'b00000000011000000000000100010011; // flushed
        env.u_cpu.u_datapath.u_imem.memory[7]  = 32'b00000000001000001000001000110011; // flushed
        env.u_cpu.u_datapath.u_imem.memory[19] = 32'b00000000100000000000000010010011; // addi x1, x0, 8
        env.u_cpu.u_datapath.u_imem.memory[20] = 32'b00000000100100000000000100010011; // addi x2, x0, 9

        env.apply_reset();
        env.run_cycles(45);

        if (env.u_cpu.u_datapath.u_regfile.X[1] != 64'h8) pass = 1'b0;
        if (env.u_cpu.u_datapath.u_regfile.X[2] != 64'h9) pass = 1'b0;
        if (env.u_cpu.u_datapath.u_regfile.X[4] != 64'hb) pass = 1'b0;

        $display("[branch] X1=0x%0h X2=0x%0h X4=0x%0h => %s",
                 env.u_cpu.u_datapath.u_regfile.X[1],
                 env.u_cpu.u_datapath.u_regfile.X[2],
                 env.u_cpu.u_datapath.u_regfile.X[4],
                 pass ? "PASS" : "FAIL");
        $finish;
    end
endmodule

// Compatibility top used by current Makefile target.
module test_cpu_bringup;
    test_cpu_bringup_arithmetic u_default_test();
endmodule
