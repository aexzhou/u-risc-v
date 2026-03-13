/*
* Arithmetic bringup test: addi, add, sub, xor, xori, slt.
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

// Usage: scripts/run.pl test_cpu_bringup_arithmetic

class test_cpu_bringup_arithmetic extends test_cpu_bringup_base;
    function new();
        super.new("test_cpu_bringup_arithmetic");
    endfunction

    virtual function void set_imem();
        imem[0] = 32'b00000000010100000000000010010011; // addi x1, x0, 5
        imem[1] = 32'b00000000011000000000000100010011; // addi x2, x0, 6
        imem[2] = 32'b00000000011100001000000110010011; // addi x3, x1, 7
        imem[3] = 32'b00000000001000001000001000110011; // add  x4, x1, x2
        imem[4] = 32'b01000000001000100000001000110011; // sub  x4, x4, x2
        imem[5] = 32'b00000000001000001100001010110011; // xor  x5, x1, x2
        imem[6] = 32'b00000000001100001100001100010011; // xori x6, x1, 3
        imem[7] = 32'b00000000001000001010001110110011; // slt  x7, x1, x2
    endfunction

    virtual task run();
        wait_cycles(20);
    endtask

    virtual task check();
        `ASSERT_EQ(`U_REGFILE_PATH.X[1], 64'h5)
        `ASSERT_EQ(`U_REGFILE_PATH.X[2], 64'h6)
        `ASSERT_EQ(`U_REGFILE_PATH.X[3], 64'hc)
        `ASSERT_EQ(`U_REGFILE_PATH.X[4], 64'h5)
        `ASSERT_EQ(`U_REGFILE_PATH.X[5], 64'h3)
        `ASSERT_EQ(`U_REGFILE_PATH.X[6], 64'h6)
        `ASSERT_EQ(`U_REGFILE_PATH.X[7], 64'h1)
    endtask

    virtual task report();
        $display("[%s] X1=0x%0h X2=0x%0h X3=0x%0h X4=0x%0h X5=0x%0h X6=0x%0h X7=0x%0h",
                 testname,
                 `U_REGFILE_PATH.X[1],
                 `U_REGFILE_PATH.X[2],
                 `U_REGFILE_PATH.X[3],
                 `U_REGFILE_PATH.X[4],
                 `U_REGFILE_PATH.X[5],
                 `U_REGFILE_PATH.X[6],
                 `U_REGFILE_PATH.X[7]);
    endtask
endclass
