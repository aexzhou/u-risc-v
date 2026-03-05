/*
* Basic bringup test: addi, add, sw, lw sequence.
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

// Usage: scripts/run.pl test_cpu_bringup_basic

`timescale 1ps/1ps
/* verilator lint_off DECLFILENAME */

module test_cpu_bringup_basic;

    `include "test_cpu_bringup_hw.svh"
    `include "test_cpu_bringup_base.svh"

    class test_cpu_bringup_basic extends test_cpu_bringup_base;
        function new();
            super.new("test_cpu_bringup_basic");
        endfunction

        virtual function void set_imem();
            imem[0] = 32'b00000000010100000000000010010011; // addi x1, x0, 5
            imem[1] = 32'b00000000011000000000000100010011; // addi x2, x0, 6
            imem[2] = 32'b00000000001000001000001000110011; // add  x4, x1, x2
            imem[3] = 32'b00000000010000010010000000100011; // sw   x4, 0(x2)
            imem[4] = 32'b00000000000000010101000100000011; // lw   x2, 0(x2)
        endfunction

        virtual task run();
            wait_cycles(20);
        endtask

        virtual task check();
            `ASSERT_EQ(`U_DMEM_PATH.memory[0], `U_REGFILE_PATH.X[4])
            `ASSERT_EQ(`U_REGFILE_PATH.X[2], `U_DMEM_PATH.memory[0])
        endtask

        virtual task report();
            $display("[%s] dmem[0]=0x%0h X2=0x%0h X4=0x%0h",
                     testname,
                     `U_DMEM_PATH.memory[0],
                     `U_REGFILE_PATH.X[2],
                     `U_REGFILE_PATH.X[4]);
        endtask
    endclass

    `define BRINGUP_TEST_CLASS test_cpu_bringup_basic
    `include "test_cpu_bringup_run.svh"

endmodule
/* verilator lint_on DECLFILENAME */
