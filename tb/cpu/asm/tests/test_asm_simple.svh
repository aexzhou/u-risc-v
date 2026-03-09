/* 
* Simple asm testsuite test
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

class test_asm_simple extends test_asm_base;

    function new();
        super.new("test_asm_simple");
        hex_file = "test_asm_simple.hex";
    endfunction

    virtual task run();
        wait_cycles(200);
    endtask

    virtual task check();
        `ASSERT_EQ(`U_REGFILE_PATH.X[10], 64'd20)  // a0 = dmem[0] loaded back
        `ASSERT_EQ(`U_REGFILE_PATH.X[11], 64'd7)   // a1 = dmem[1] loaded back
        `ASSERT_EQ(`U_REGFILE_PATH.X[12], 64'd27)  // a2 = a0 + a1
        `ASSERT_EQ(`U_DMEM_PATH.memory[0], 64'd20) // dmem[0] stored correctly
        `ASSERT_EQ(`U_DMEM_PATH.memory[1], 64'd7)  // dmem[1] stored correctly
    endtask

    virtual task report();
        $display("[%s] a0=%0d (exp 20)  a1=%0d (exp 7)  a2=%0d (exp 27)  dmem[0]=%0d  dmem[1]=%0d",
                 testname,
                 `U_REGFILE_PATH.X[10], `U_REGFILE_PATH.X[11], `U_REGFILE_PATH.X[12],
                 `U_DMEM_PATH.memory[0], `U_DMEM_PATH.memory[1]);
    endtask

endclass
