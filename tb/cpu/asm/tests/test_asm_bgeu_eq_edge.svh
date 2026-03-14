/*
* BGEU equal edge (unsigned): 7 >= 7 -> branch must be taken.
* BGEU is greater-than-or-equal unsigned; equal operands MUST trigger the branch.
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

class test_asm_bgeu_eq_edge extends test_asm_base;

    function new();
        super.new("test_asm_bgeu_eq_edge");
        hex_file = "test_asm_bgeu_eq_edge.hex";
    endfunction

    virtual task run();
        wait_cycles(30);
    endtask

    virtual task check();
        `ASSERT_EQ(`U_REGFILE_PATH.X[10], 64'd1)   // bgeu equal edge: 7 >=u 7 -> taken
    endtask

    virtual task report();
        $display("[%s] x10=%0d (exp 1)", testname, `U_REGFILE_PATH.X[10]);
    endtask

endclass
