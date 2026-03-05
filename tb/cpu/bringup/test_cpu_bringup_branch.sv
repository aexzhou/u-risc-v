/*
* Branch bringup test: beq (not taken), bne (taken).
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

`timescale 1ps/1ps
/* verilator lint_off DECLFILENAME */

module test_cpu_bringup_branch;

    `include "test_cpu_bringup_hw.svh"
    `include "test_cpu_bringup_base.svh"

    class test_cpu_bringup_branch extends test_cpu_bringup_base;
        function new();
            super.new("test_cpu_bringup_branch");
        endfunction

        virtual function void set_imem();
            imem[0]  = 32'b00000000010100000000000010010011; // addi x1, x0, 5
            imem[1]  = 32'b00000000011000000000000100010011; // addi x2, x0, 6
            imem[2]  = 32'b00000010000100000000111001100011; // beq  x0, x1, +60 (not taken)
            imem[3]  = 32'b00000000001000001000001000110011; // add  x4, x1, x2
            imem[4]  = 32'b00000010001000001001111001100011; // bne  x1, x2, +60 (taken → imem[19])
            imem[5]  = 32'b00000000010100000000000010010011; // flushed
            imem[6]  = 32'b00000000011000000000000100010011; // flushed
            imem[7]  = 32'b00000000001000001000001000110011; // flushed
            imem[19] = 32'b00000000100000000000000010010011; // addi x1, x0, 8
            imem[20] = 32'b00000000100100000000000100010011; // addi x2, x0, 9
        endfunction

        virtual task run();
            wait_cycles(45);
        endtask

        virtual task check();
            `ASSERT_EQ(`U_REGFILE_PATH.X[1], 64'h8)
            `ASSERT_EQ(`U_REGFILE_PATH.X[2], 64'h9)
            `ASSERT_EQ(`U_REGFILE_PATH.X[4], 64'hb)
        endtask

        virtual task report();
            $display("[%s] X1=0x%0h X2=0x%0h X4=0x%0h",
                     testname,
                     `U_REGFILE_PATH.X[1],
                     `U_REGFILE_PATH.X[2],
                     `U_REGFILE_PATH.X[4]);
        endtask
    endclass

    `define BRINGUP_TEST_CLASS test_cpu_bringup_branch
    `include "test_cpu_bringup_run.svh"

endmodule
/* verilator lint_on DECLFILENAME */
