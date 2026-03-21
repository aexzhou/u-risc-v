/*
* Comprehensive RV32I branch instruction test.
*
* Tests all six branch instructions (beq, bne, blt, bge, bltu, bgeu)
* in both the taken and not-taken cases, plus equal-edge cases for
* blt, bge, and bgeu.
*
* Each test writes 1 to a dedicated result register on success, or
* 255 (POISON) if the wrong control-flow path was taken.
*
* Result register map:
*   x10  TEST  1  beq  taken          (5 == 5)
*   x11  TEST  2  beq  not taken      (5 != 6)
*   x12  TEST  3  bne  taken          (5 != 6)
*   x13  TEST  4  bne  not taken      (5 == 5)
*   x14  TEST  5  blt  taken  signed  (-1 < 1)
*   x15  TEST  6  blt  not taken signed  (5 not < 3)
*   x16  TEST  7  blt  not taken signed, equal edge  (5 not < 5)
*   x17  TEST  8  bge  taken  signed  (5 >= 3)
*   x18  TEST  9  bge  taken  signed, equal edge  (5 >= 5)
*   x19  TEST 10  bge  not taken signed  (-1 not >= 1)
*   x20  TEST 11  bltu taken  unsigned  (1 < 0xFFFFFFFF)
*   x21  TEST 12  bltu not taken unsigned  (0xFFFFFFFF not < 1)
*   x22  TEST 13  bgeu taken  unsigned  (0xFFFFFFFF >= 1)
*   x23  TEST 14  bgeu taken  unsigned, equal edge  (7 >= 7)
*   x24  TEST 15  bgeu not taken unsigned  (1 not >= 0xFFFFFFFF)
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

class test_asm_branch_all extends test_asm_base;

    function new();
        super.new("test_asm_branch_all");
        hex_file = "test_asm_branch_all.hex";
    endfunction

    virtual task run();
        wait_cycles(200);
    endtask

    virtual task check();
        // ---- BEQ ----
        `ASSERT_EQ(`U_REGFILE_PATH.X[10], 64'd1)   // TEST  1: beq taken       (5 == 5)
        `ASSERT_EQ(`U_REGFILE_PATH.X[11], 64'd1)   // TEST  2: beq not taken   (5 != 6)

        // ---- BNE ----
        `ASSERT_EQ(`U_REGFILE_PATH.X[12], 64'd1)   // TEST  3: bne taken       (5 != 6)
        `ASSERT_EQ(`U_REGFILE_PATH.X[13], 64'd1)   // TEST  4: bne not taken   (5 == 5)

        // ---- BLT (signed) ----
        `ASSERT_EQ(`U_REGFILE_PATH.X[14], 64'd1)   // TEST  5: blt taken       (-1 < 1)
        `ASSERT_EQ(`U_REGFILE_PATH.X[15], 64'd1)   // TEST  6: blt not taken   (5 not < 3)
        `ASSERT_EQ(`U_REGFILE_PATH.X[16], 64'd1)   // TEST  7: blt not taken   (5 not < 5, equal)

        // ---- BGE (signed) ----
        `ASSERT_EQ(`U_REGFILE_PATH.X[17], 64'd1)   // TEST  8: bge taken       (5 >= 3)
        `ASSERT_EQ(`U_REGFILE_PATH.X[18], 64'd1)   // TEST  9: bge taken       (5 >= 5, equal)
        `ASSERT_EQ(`U_REGFILE_PATH.X[19], 64'd1)   // TEST 10: bge not taken   (-1 not >= 1)

        // ---- BLTU (unsigned) ----
        `ASSERT_EQ(`U_REGFILE_PATH.X[20], 64'd1)   // TEST 11: bltu taken      (1 < 0xFFFFFFFF)
        `ASSERT_EQ(`U_REGFILE_PATH.X[21], 64'd1)   // TEST 12: bltu not taken  (0xFFFFFFFF not < 1)

        // ---- BGEU (unsigned) ----
        `ASSERT_EQ(`U_REGFILE_PATH.X[22], 64'd1)   // TEST 13: bgeu taken      (0xFFFFFFFF >= 1)
        `ASSERT_EQ(`U_REGFILE_PATH.X[23], 64'd1)   // TEST 14: bgeu taken      (7 >= 7, equal)
        `ASSERT_EQ(`U_REGFILE_PATH.X[24], 64'd1)   // TEST 15: bgeu not taken  (1 not >= 0xFFFFFFFF)
    endtask

    virtual task report();
        $display("[%s]", testname);
        $display("  BEQ   taken      x10=%0d (exp 1)", `U_REGFILE_PATH.X[10]);
        $display("  BEQ   not taken  x11=%0d (exp 1)", `U_REGFILE_PATH.X[11]);
        $display("  BNE   taken      x12=%0d (exp 1)", `U_REGFILE_PATH.X[12]);
        $display("  BNE   not taken  x13=%0d (exp 1)", `U_REGFILE_PATH.X[13]);
        $display("  BLT   taken      x14=%0d (exp 1)", `U_REGFILE_PATH.X[14]);
        $display("  BLT   not taken  x15=%0d (exp 1)", `U_REGFILE_PATH.X[15]);
        $display("  BLT   eq edge    x16=%0d (exp 1)", `U_REGFILE_PATH.X[16]);
        $display("  BGE   taken      x17=%0d (exp 1)", `U_REGFILE_PATH.X[17]);
        $display("  BGE   eq edge    x18=%0d (exp 1)", `U_REGFILE_PATH.X[18]);
        $display("  BGE   not taken  x19=%0d (exp 1)", `U_REGFILE_PATH.X[19]);
        $display("  BLTU  taken      x20=%0d (exp 1)", `U_REGFILE_PATH.X[20]);
        $display("  BLTU  not taken  x21=%0d (exp 1)", `U_REGFILE_PATH.X[21]);
        $display("  BGEU  taken      x22=%0d (exp 1)", `U_REGFILE_PATH.X[22]);
        $display("  BGEU  eq edge    x23=%0d (exp 1)", `U_REGFILE_PATH.X[23]);
        $display("  BGEU  not taken  x24=%0d (exp 1)", `U_REGFILE_PATH.X[24]);
    endtask

endclass
