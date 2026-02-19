// SystemVerilog Testbench for RISC-V Datapath
module test_cpu_bringup;

    // Clock and reset signals
    logic clk;
    logic rst;

    // Instantiate the DUT (Device Under Test)
    rv_cpu u_cpu (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation - 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Waveform dumping for GTKWave
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_datapath);
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

        // Display some register values
        $display("Final Register Values:");
        $display("  X1 = 0x%h", dut.REGFILE.X[1]);
        $display("  X2 = 0x%h", dut.REGFILE.X[2]);
        $display("  X3 = 0x%h", dut.REGFILE.X[3]);
        $display("  X4 = 0x%h", dut.REGFILE.X[4]);
        $display("  X5 = 0x%h", dut.REGFILE.X[5]);
        $display("  X6 = 0x%h", dut.REGFILE.X[6]);
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
        if (!rst && dut.PC_Write) begin
            $display("Time %0t: PC=0x%h, Instruction=0x%h",
                     $time, dut.PC_out, dut.iMem_out);
        end
    end

endmodule
