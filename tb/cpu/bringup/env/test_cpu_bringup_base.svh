/*
* Base class for directed CPU bringup tests.
* Copyright (C) 2026 Alex Zhou
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// Include inside a module body, AFTER test_cpu_bringup_hw.svh.
// The class accesses clk, rst_n, and DUT paths from the enclosing module scope.

`define ASSERT_EQ(a, b) \
    if ((a) !== (b)) begin \
        $display("\033[1;31mASSERT_EQ FAIL!!!: %s = 0x%016h, %s = 0x%016h\033[0m", `"a`", (a), `"b`", (b)); \
        pass = 0; \
    end

class test_cpu_bringup_base;
    localparam IMEM_DW    = 32;
    localparam IMEM_DEPTH = 256;

    // Local instruction buffer — populated by set_imem(), written to DUT by load_imem()
    logic [IMEM_DW-1:0] imem [0:IMEM_DEPTH-1];

    string testname;
    bit    pass = 1;

    function new(string _testname = "test_cpu_bringup_base");
        this.testname = _testname;
    endfunction

    // Pulse reset: deassert rst_n for 5 cycles, then release
    virtual task apply_reset();
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

    // Fill local instruction buffer with NOPs (addi x0, x0, 0)
    virtual function void init_imem();
        for (int i = 0; i < IMEM_DEPTH; i++)
            imem[i] = 32'h0000_0013;
    endfunction

    // Override in derived class to load test instructions into this.imem[]
    virtual function void set_imem();
    endfunction

    // Write local instruction buffer to the DUT instruction memory
    virtual function void load_imem();
        for (int i = 0; i < IMEM_DEPTH; i++)
            `U_IMEM_PATH.memory[i] = imem[i];
    endfunction

    // Override in derived class: run the test
    virtual task run();
    endtask

    // Override in derived class: sample outputs and set pass/fail
    virtual task check();
    endtask

    // Override in derived class: display pass/fail summary
    virtual task report();
    endtask

    virtual function void print_pass_fail();
        $display("\n====== Simulation Results ======\n");
        $display("[%s]  %s", testname, pass ? "\033[1;32mPASSED\033[0m" : "\033[1;31mFAILED!!!\033[0m");
        $display("\n");
    endfunction

    virtual task wait_cycles(int cycles);
        repeat(cycles) @(posedge clk);
    endtask

endclass
