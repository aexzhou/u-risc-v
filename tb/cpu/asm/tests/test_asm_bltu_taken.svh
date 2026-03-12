/*
* BLTU taken (unsigned): 1 < 0xFFFFFFFF -> branch must be taken.
* 0xFFFFFFFF is the unsigned maximum; as signed it would be -1 (less than 1),
* so this case also verifies that the unsigned comparator is used, not signed.
* Checks x10 = 1 (PASS) and not 255 (POISON).
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

class test_asm_bltu_taken extends test_asm_base;

    function new();
        super.new("test_asm_bltu_taken");
        hex_file = "test_asm_bltu_taken.hex";
    endfunction

    virtual task run();
        wait_cycles(30);
    endtask

    virtual task check();
        `ASSERT_EQ(`U_REGFILE_PATH.X[10], 64'd1)   // bltu taken unsigned (1 <u 0xFFFFFFFF)
    endtask

    virtual task report();
        $display("[%s] x10=%0d (exp 1)", testname, `U_REGFILE_PATH.X[10]);
    endtask

endclass
