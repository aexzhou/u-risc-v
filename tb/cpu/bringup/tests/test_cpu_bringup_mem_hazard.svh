/*
* MEM-stage hazard bringup test: back-to-back ALU ops with data dependencies.
* Copyright (C) 2026 Ryan Liu
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

// Usage: scripts/run.pl test_cpu_bringup_mem_hazard

class test_cpu_bringup_mem_hazard extends test_cpu_bringup_base;
    function new();
        super.new("test_cpu_bringup_mem_hazard");
    endfunction

    virtual function void set_imem();
        // Setup
        imem[0] = 32'b00000000010100000000000010010011; // addi x1, x0, 5
        imem[1] = 32'b00000000011000000000000100010011; // addi x2, x0, 6
        imem[2] = 32'b00000000011100001000000110010011; // addi x3, x1, 7
        // MEM hazard sequence
        imem[3] = 32'b00000000001000001000000010110011; // add  x1, x1, x2
        imem[4] = 32'b00000000001100001111000010110011; // and  x1, x1, x3
        imem[5] = 32'b00000000010000001110000010110011; // or   x1, x1, x4
    endfunction

    virtual task run();
        wait_cycles(20);
    endtask

    virtual task check();
        `ASSERT_EQ(`U_REGFILE_PATH.X[1], 64'h8)
    endtask

    virtual task report();
        $display("[%s] X1=0x%0h",
                 testname,
                 `U_REGFILE_PATH.X[1]);
    endtask
endclass
