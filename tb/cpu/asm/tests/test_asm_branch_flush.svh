/*
* Branch flush timing test.
*
* Verifies that when a branch is taken, the instructions between
* the branch and the target are not executed.
*
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

class test_asm_branch_flush extends test_asm_base;

    function new();
        super.new("test_asm_branch_flush");
        hex_file = "test_asm_branch_flush.hex";
    endfunction

    virtual task run();
        wait_cycles(30);
    endtask

    virtual task check();
        `ASSERT_EQ(`U_REGFILE_PATH.X[1],  64'd5)    // setup
        `ASSERT_EQ(`U_REGFILE_PATH.X[2],  64'd5)    // setup
        
        `ASSERT_EQ(`U_REGFILE_PATH.X[3],  64'd0)
        `ASSERT_EQ(`U_REGFILE_PATH.X[4],  64'd0)
        `ASSERT_EQ(`U_REGFILE_PATH.X[5],  64'd0)
        
        `ASSERT_EQ(`U_REGFILE_PATH.X[10], 64'd99)   // branch target
    endtask

    virtual task report();
        $display("[%s] x1=%0d x2=%0d x3=%0d (exp 0)  x4=%0d (exp 0)  x5=%0d (exp 0)  x10=%0d (exp 99)",
                 testname,
                 `U_REGFILE_PATH.X[1],
                 `U_REGFILE_PATH.X[2],
                 `U_REGFILE_PATH.X[3],
                 `U_REGFILE_PATH.X[4],
                 `U_REGFILE_PATH.X[5],
                 `U_REGFILE_PATH.X[10]);
    endtask

endclass
