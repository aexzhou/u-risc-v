/*
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

class test_cpu_bringup_shift extends test_cpu_bringup_base;
    function new();
        super.new("test_cpu_bringup_shift");
    endfunction

    virtual function void set_imem();
        imem[0] = 32'b00000000001100000000000010010011; // addi x1, x0, 3
        imem[1] = 32'b00000000001000001001000010010011; // slli x1, x1, 2 (x1 is 0xc here)
        imem[2] = 32'b00000000001000001101000100010011; // srli x2, x1, 2 (x2 is 0x3 here)
        imem[3] = 32'b11111101011000000000000110010011; // addi x3, x0, -42
        imem[4] = 32'b01000000001000011101001000010011; // srai x4, x3, 2 (should be sign extended)
        imem[5] = 32'b00000000001000001001001010110011; // sll  x5, x1, x2  (x5 = 0xc << 3 = 0x60)
        imem[6] = 32'b00000000001000001101001100110011; // srl  x6, x1, x2  (x6 = 0xc >> 3 = 0x1)
    endfunction

    virtual task run();
        wait_cycles(20);
    endtask

    virtual task check();
        `ASSERT_EQ(`U_REGFILE_PATH.X[1], 64'hc)
        `ASSERT_EQ(`U_REGFILE_PATH.X[2], 64'h3)
        `ASSERT_EQ(`U_REGFILE_PATH.X[4], 64'hFFFFFFFFFFFFFFF5)
        `ASSERT_EQ(`U_REGFILE_PATH.X[5], 64'h60)
        `ASSERT_EQ(`U_REGFILE_PATH.X[6], 64'h1)
    endtask

    virtual task report();
        $display("[%s] X1=0x%0h X2=0x%0h X4=0x%0h X5=0x%0h X6=0x%0h",
                 testname,
                 `U_REGFILE_PATH.X[1],
                 `U_REGFILE_PATH.X[2],
                 `U_REGFILE_PATH.X[4],
                 `U_REGFILE_PATH.X[5],
                 `U_REGFILE_PATH.X[6]);
    endtask
endclass
