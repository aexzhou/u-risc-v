/*
* Branch bringup test: beq (taken), bne (taken).
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
    endfunction

    virtual task run();
        wait_cycles(60);
    endtask

    virtual task check();
        `ASSERT_EQ(`U_REGFILE_PATH.X[1], 64'h8)
        `ASSERT_EQ(`U_REGFILE_PATH.X[2], 64'h8)
        `ASSERT_EQ(`U_REGFILE_PATH.X[4], 64'hb)
        `ASSERT_EQ(`U_REGFILE_PATH.X[5], 64'h1c)
    endtask

    virtual task report();
        $display("[%s] X1=0x%0h X2=0x%0h X4=0x%0h X5=0x%0h",
                 testname,
                 `U_REGFILE_PATH.X[1],
                 `U_REGFILE_PATH.X[2],
                 `U_REGFILE_PATH.X[4],
                 `U_REGFILE_PATH.X[5]);
    endtask
endclass
