/*
* Branch bringup test: beq/bne/blt/bge/bltu/bgeu (all taken).
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

// Usage: scripts/run.pl test_cpu_bringup_branch

class test_cpu_bringup_branch extends test_cpu_bringup_base;
    function new();
        super.new("test_cpu_bringup_branch");
    endfunction

    virtual function void set_imem();
        imem[0] = 32'b00000000100000000000000010010011; // addi x1, x0, 8
        imem[1] = 32'b00000000100000000000000100010011; // addi x2, x0, 8
        imem[2] = 32'b00000000001000001000010001100011; // beq  x1, x2, +8 (taken)
        imem[3] = 32'b00000000000100000000001000010011; // addi x4, x0, 1  (skipped)
        imem[4] = 32'b00000000101100000000001000010011; // addi x4, x0, 11
        imem[5] = 32'b00000000010100000000001010010011; // addi x5, x0, 5
        imem[6] = 32'b00000000010000001001010001100011; // bne  x1, x4, +8 (taken)
        imem[7] = 32'b00000000000100000000001010010011; // addi x5, x0, 1  (skipped)
        imem[8] = 32'b00000001110000000000001010010011; // addi x5, x0, 28
        imem[9] = 32'b00000000010000001100010001100011; // blt  x1, x4, +8 (taken)
        imem[10] = 32'b00000000000100000000001100010011; // addi x6, x0, 1  (skipped)
        imem[11] = 32'b00000010101000000000001100010011; // addi x6, x0, 42
        imem[12] = 32'b00000000011100000000001110010011; // addi x7, x0, 7
        imem[13] = 32'b00000000000100100101010001100011; // bge  x4, x1, +8 (taken)
        imem[14] = 32'b00000000000100000000001110010011; // addi x7, x0, 1  (skipped)
        imem[15] = 32'b00000100110100000000001110010011; // addi x7, x0, 77
        imem[16] = 32'b00000000000100000000010000010011; // addi x8,  x0, 1
        imem[17] = 32'b11111111111100000000010010010011; // addi x9,  x0, -1
        imem[18] = 32'b00000000100101000110010001100011; // bltu x8, x9, +8 (taken)
        imem[19] = 32'b00000000000100000000010100010011; // addi x10, x0, 1  (skipped)
        imem[20] = 32'b00000110010000000000010100010011; // addi x10, x0, 100
        imem[21] = 32'b00000000100001001111010001100011; // bgeu x9, x8, +8 (taken)
        imem[22] = 32'b00000000000100000000010110010011; // addi x11, x0, 1  (skipped)
        imem[23] = 32'b00000110010100000000010110010011; // addi x11, x0, 101
    endfunction

    virtual task run();
        wait_cycles(80);
    endtask

    virtual task check();
        `ASSERT_EQ(`U_REGFILE_PATH.X[1], 64'h8)
        `ASSERT_EQ(`U_REGFILE_PATH.X[2], 64'h8)
        `ASSERT_EQ(`U_REGFILE_PATH.X[4], 64'hb)
        `ASSERT_EQ(`U_REGFILE_PATH.X[5], 64'h1c)
        `ASSERT_EQ(`U_REGFILE_PATH.X[6], 64'h2a)
        `ASSERT_EQ(`U_REGFILE_PATH.X[7], 64'h4d)
        `ASSERT_EQ(`U_REGFILE_PATH.X[10], 64'h64)
        `ASSERT_EQ(`U_REGFILE_PATH.X[11], 64'h65)
    endtask

    virtual task report();
        $display("[%s] X1=0x%0h X2=0x%0h X4=0x%0h X5=0x%0h X6=0x%0h X7=0x%0h X10=0x%0h X11=0x%0h",
                 testname,
                 `U_REGFILE_PATH.X[1],
                 `U_REGFILE_PATH.X[2],
                 `U_REGFILE_PATH.X[4],
                 `U_REGFILE_PATH.X[5],
                 `U_REGFILE_PATH.X[6],
                 `U_REGFILE_PATH.X[7],
                 `U_REGFILE_PATH.X[10],
                 `U_REGFILE_PATH.X[11]);
    endtask
endclass
