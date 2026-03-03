// SystemVerilog Testbench for RISC-V Datapath
module test_cpu_bringup;

    // Clock and reset signals
    logic clk;
    logic rst;

    // Instantiate the DUT (Device Under Test)
    rv_cpu u_cpu (
        .clk(clk),
        .rst_n(~rst)
    );

    // Clock generation - 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Waveform dumping for GTKWave
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, test_cpu_bringup);
    end

    initial begin
        // fill all with addi x0, x0, 0
        for (int i = 0; i < 256; i++)
            u_cpu.u_datapath.u_imem.memory[i] = 32'b00000000000000000000000000010011;

        // addi x1, x0, 5
        u_cpu.u_datapath.u_imem.memory[0] = 32'b00000000010100000000000010010011;
        // addi x2, x0, 6
        u_cpu.u_datapath.u_imem.memory[1] = 32'b00000000011000000000000100010011;
        // addi x3, x1, 7
        u_cpu.u_datapath.u_imem.memory[2] = 32'b00000000011100001000000110010011;
        // add x4, x1, x2
        u_cpu.u_datapath.u_imem.memory[3] = 32'b00000000001000001000001000110011;
        // sub x4, x4, x2
        u_cpu.u_datapath.u_imem.memory[4] = 32'b01000000001000100000001000110011;

        // // MEM Hazard seems to have some issues
        // add x1, x1, x2
        u_cpu.u_datapath.u_imem.memory[5] = 32'b00000000001000001000000010110011;
        // and x1, x1, x3
        u_cpu.u_datapath.u_imem.memory[6] = 32'b00000000001100001111000010110011;
        // or x1, x1, x4
        u_cpu.u_datapath.u_imem.memory[7] = 32'b00000000010000001110000010110011;
        // sw x4, 0(x2)
        u_cpu.u_datapath.u_imem.memory[8] = 32'b00000000010000010010000000100011;
        // lw x2, 0(x2)
        u_cpu.u_datapath.u_imem.memory[9] = 32'b00000000000000010101000100000011;

        // beq x0, x1, #60 (branch NOT taken: x0=0 != x1=5, fall through)
        u_cpu.u_datapath.u_imem.memory[10] = 32'b00000010000100000000111001100011;
        // addi x1, x0, 5
        u_cpu.u_datapath.u_imem.memory[11] = 32'b00000000010100000000000010010011;
        // addi x2, x0, 6
        u_cpu.u_datapath.u_imem.memory[12] = 32'b00000000011000000000000100010011;
        // add x4, x1, x2
        u_cpu.u_datapath.u_imem.memory[13] = 32'b00000000001000001000001000110011;

        // bne x1, x2, #60 (branch TAKEN: x1=5 != x2=6, slots 15-17 flushed)
        u_cpu.u_datapath.u_imem.memory[14] = 32'b00000010001000001001111001100011;
        // addi x1, x0, 5  (NOT executed - branch taken)
        u_cpu.u_datapath.u_imem.memory[15] = 32'b00000000010100000000000010010011;
        // addi x2, x0, 6  (NOT executed - branch taken)
        u_cpu.u_datapath.u_imem.memory[16] = 32'b00000000011000000000000100010011;
        // add x4, x1, x2  (NOT executed - branch taken)
        u_cpu.u_datapath.u_imem.memory[17] = 32'b00000000001000001000001000110011;

        // bne target (PC=116, word 29): addi x1, x0, 8
        u_cpu.u_datapath.u_imem.memory[29] = 32'b00000000100000000000000010010011;
        // addi x2, x0, 9
        u_cpu.u_datapath.u_imem.memory[30] = 32'b00000000100100000000000100010011;

    end

    // Test sequence
    initial begin
        $display("Starting RISC-V Datapath Simulation");
        $display("=====================================");

        // Initialize signals
        rst = 1;

        // Hold reset for a few cycles
        repeat(5) @(posedge clk);

        $display("Time %0t: Releasing reset", $time);
        rst = 0;

        // Run simulation for some cycles
        repeat(50) @(posedge clk);

        $display("Time %0t: Simulation completed", $time);
        $display("=====================================");

        $display("arithmetic ins test:");
        $display("  addi x1, x0, 5  (expect x1 = 0x5)");
        $display("  X1 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[1],
                 (u_cpu.u_datapath.u_regfile.X[1] == 64'h5) ? "PASS" : "FAIL");
        $display("  addi x2, x0, 6  (expect x2 = 0x6)");
        $display("  X2 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[2],
                 (u_cpu.u_datapath.u_regfile.X[2] == 64'h6) ? "PASS" : "FAIL");
        $display("  addi x3, x1, 7  (expect x3 = 0xc)");
        $display("  X3 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[3],
                 (u_cpu.u_datapath.u_regfile.X[3] == 64'hc) ? "PASS" : "FAIL");
        $display("  add x4, x1, x2  (expect x4 = 0xb)");
        $display("  X4 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[4],
                 (u_cpu.u_datapath.u_regfile.X[4] == 64'hb) ? "PASS" : "FAIL");
        $display("  sub x4, x4, x2  (expect x4 = 0x5)");
        $display("  X4 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[4],
                 (u_cpu.u_datapath.u_regfile.X[4] == 64'h5) ? "PASS" : "FAIL");

        $display("");
        $display("MEM hazard test:");
        $display("  add x1, x1, x2  (expect x1 = 0xb)");
        $display("  and x1, x1, x3  (expect x1 = 0x8)");
        $display("  or  x1, x1, x4  (expect x1 = 0xd)");
        $display("  X1 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[1],
                 (u_cpu.u_datapath.u_regfile.X[1] == 64'hd) ? "PASS" : "FAIL");

        $display("");
        $display("mem ins test:");
        $display("  sw x4, 0(x2)  (expect dmem[0] = x4 = 0x%0h)", u_cpu.u_datapath.u_regfile.X[4]);
        $display("  dmem[0] = 0x%0h %s", u_cpu.u_datapath.u_dmem.memory[0],
                 (u_cpu.u_datapath.u_dmem.memory[0] == u_cpu.u_datapath.u_regfile.X[4]) ? "PASS" : "FAIL");
        $display("  lw x2, 0(x2)  (expect dmem[0] = x2 = 0x%0h)", u_cpu.u_datapath.u_dmem.memory[0]);
        $display("  X2 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[2],
                 (u_cpu.u_datapath.u_regfile.X[2] == u_cpu.u_datapath.u_dmem.memory[0]) ? "PASS" : "FAIL");

        $display("");
        $display("branch test:");
        $display("  beq x0, x1, #60  (branch NOT taken: x0=0 != x1=5, fall through)");
        $display("  addi x1, x0, 5   (expect x1 = 0x5)");
        $display("  X1 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[1],
                 (u_cpu.u_datapath.u_regfile.X[1] == 64'h5) ? "PASS" : "FAIL");
        $display("  addi x2, x0, 6   (expect x2 = 0x6)");
        $display("  X2 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[2],
                 (u_cpu.u_datapath.u_regfile.X[2] == 64'h6) ? "PASS" : "FAIL");
        $display("  add x4, x1, x2   (expect x4 = 0xb)");
        $display("  X4 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[4],
                 (u_cpu.u_datapath.u_regfile.X[4] == 64'hb) ? "PASS" : "FAIL");

        $display("");
        $display("bne test:");
        $display("  bne x1, x2, #60  (branch TAKEN: x1=5 != x2=6, fall-through flushed)");
        $display("  x1 unchanged = 0x5, x2 unchanged = 0x6, x4 unchanged = 0xb");
        $display("  X1 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[1],
                 (u_cpu.u_datapath.u_regfile.X[1] == 64'h5) ? "PASS" : "FAIL");
        $display("  X2 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[2],
                 (u_cpu.u_datapath.u_regfile.X[2] == 64'h6) ? "PASS" : "FAIL");
        $display("  X4 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[4],
                 (u_cpu.u_datapath.u_regfile.X[4] == 64'hb) ? "PASS" : "FAIL");

        $display("");
        $display("bne target test (PC=116):");
        $display("  addi x1, x0, 8  (expect x1 = 0x8)");
        $display("  X1 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[1],
                 (u_cpu.u_datapath.u_regfile.X[1] == 64'h8) ? "PASS" : "FAIL");
        $display("  addi x2, x0, 9  (expect x2 = 0x9)");
        $display("  X2 = 0x%0h %s", u_cpu.u_datapath.u_regfile.X[2],
                 (u_cpu.u_datapath.u_regfile.X[2] == 64'h9) ? "PASS" : "FAIL");

        $display("");

        $display("Final Register Values:");
        for (int i = 1; i <= 6; i++)
            $display("  X%-20d = 0x%h", i, u_cpu.u_datapath.u_regfile.X[i]);

        $display("");
        $display("Waveform saved to waveform.vcd");
        $display("View with: gtkwave waveform.vcd");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #10000; // 10us timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    // Optional: Monitor instructions being executed
    always @(posedge clk) begin
        if (!rst && u_cpu.u_datapath.pc_write) begin
            $display("Time %0t: PC=0x%h, Instruction=0x%h",
                     $time, u_cpu.u_datapath.pc_out, u_cpu.u_datapath.imem_out);
        end
    end

endmodule
