# Comprehensive RV32I branch instruction test.
#
# Tests all six branch instructions (beq, bne, blt, bge, bltu, bgeu),
# each in both the taken and not-taken cases.  For each test a dedicated
# result register is written:
#   1   -> branch behaved correctly
#   255 -> POISON (branch misbehaved — wrong-path instruction executed)
#
# Result register map:
#   x10  TEST  1  beq  taken        (5 == 5)
#   x11  TEST  2  beq  not taken    (5 != 6)
#   x12  TEST  3  bne  taken        (5 != 6)
#   x13  TEST  4  bne  not taken    (5 == 5)
#   x14  TEST  5  blt  taken  signed  (-1 < 1)
#   x15  TEST  6  blt  not taken signed (5 not < 3)
#   x16  TEST  7  blt  not taken signed, equal edge (5 not < 5)
#   x17  TEST  8  bge  taken  signed  (5 >= 3)
#   x18  TEST  9  bge  taken  signed, equal edge (5 >= 5)
#   x19  TEST 10  bge  not taken signed (-1 not >= 1)
#   x20  TEST 11  bltu taken  unsigned (1 < 0xFFFFFFFF)
#   x21  TEST 12  bltu not taken unsigned (0xFFFFFFFF not < 1)
#   x22  TEST 13  bgeu taken  unsigned (0xFFFFFFFF >= 1)
#   x23  TEST 14  bgeu taken  unsigned, equal edge (7 >= 7)
#   x24  TEST 15  bgeu not taken unsigned (1 not >= 0xFFFFFFFF)
#
# Copyright (C) 2026 Alex Zhou
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

.section .text
.globl _start

_start:

# ============================================================
# TEST 1 — BEQ taken: 5 == 5 -> branch must be taken -> x10 = 1
# ============================================================
    addi x1, x0, 5             # x1 = 5
    addi x2, x0, 5             # x2 = 5  (equal)
    beq  x1, x2, beq_taken
    addi x10, x0, 255          # POISON: must not execute
    j    beq_taken_end
beq_taken:
    addi x10, x0, 1            # PASS
beq_taken_end:

# ============================================================
# TEST 2 — BEQ not taken: 5 != 6 -> fall through -> x11 = 1
# ============================================================
    addi x1, x0, 5             # x1 = 5
    addi x2, x0, 6             # x2 = 6  (not equal)
    beq  x1, x2, beq_nt_skip
    addi x11, x0, 1            # PASS: fall-through
    j    beq_nt_end
beq_nt_skip:
    addi x11, x0, 255          # POISON: must not execute
beq_nt_end:

# ============================================================
# TEST 3 — BNE taken: 5 != 6 -> branch must be taken -> x12 = 1
# ============================================================
    addi x1, x0, 5             # x1 = 5
    addi x2, x0, 6             # x2 = 6  (not equal)
    bne  x1, x2, bne_taken
    addi x12, x0, 255          # POISON
    j    bne_taken_end
bne_taken:
    addi x12, x0, 1            # PASS
bne_taken_end:

# ============================================================
# TEST 4 — BNE not taken: 5 == 5 -> fall through -> x13 = 1
# ============================================================
    addi x1, x0, 5             # x1 = 5
    addi x2, x0, 5             # x2 = 5  (equal)
    bne  x1, x2, bne_nt_skip
    addi x13, x0, 1            # PASS: fall-through
    j    bne_nt_end
bne_nt_skip:
    addi x13, x0, 255          # POISON
bne_nt_end:

# ============================================================
# TEST 5 — BLT taken (signed): -1 < 1 -> branch taken -> x14 = 1
# ============================================================
    addi x1, x0, -1            # x1 = -1 (signed)
    addi x2, x0, 1             # x2 =  1
    blt  x1, x2, blt_taken
    addi x14, x0, 255          # POISON
    j    blt_taken_end
blt_taken:
    addi x14, x0, 1            # PASS
blt_taken_end:

# ============================================================
# TEST 6 — BLT not taken (signed): 5 not < 3 -> fall through -> x15 = 1
# ============================================================
    addi x1, x0, 5             # x1 = 5
    addi x2, x0, 3             # x2 = 3
    blt  x1, x2, blt_nt_skip
    addi x15, x0, 1            # PASS: fall-through
    j    blt_nt_end
blt_nt_skip:
    addi x15, x0, 255          # POISON
blt_nt_end:

# ============================================================
# TEST 7 — BLT not taken, equal edge (signed): 5 not < 5 -> fall through -> x16 = 1
# ============================================================
    addi x1, x0, 5             # x1 = 5
    addi x2, x0, 5             # x2 = 5  (equal -> BLT must NOT be taken)
    blt  x1, x2, blt_eq_nt_skip
    addi x16, x0, 1            # PASS: fall-through
    j    blt_eq_nt_end
blt_eq_nt_skip:
    addi x16, x0, 255          # POISON
blt_eq_nt_end:

# ============================================================
# TEST 8 — BGE taken (signed): 5 >= 3 -> branch taken -> x17 = 1
# ============================================================
    addi x1, x0, 5             # x1 = 5
    addi x2, x0, 3             # x2 = 3
    bge  x1, x2, bge_taken
    addi x17, x0, 255          # POISON
    j    bge_taken_end
bge_taken:
    addi x17, x0, 1            # PASS
bge_taken_end:

# ============================================================
# TEST 9 — BGE taken, equal edge (signed): 5 >= 5 -> branch taken -> x18 = 1
# ============================================================
    addi x1, x0, 5             # x1 = 5
    addi x2, x0, 5             # x2 = 5  (equal -> BGE must be taken)
    bge  x1, x2, bge_eq_taken
    addi x18, x0, 255          # POISON
    j    bge_eq_taken_end
bge_eq_taken:
    addi x18, x0, 1            # PASS
bge_eq_taken_end:

# ============================================================
# TEST 10 — BGE not taken (signed): -1 not >= 1 -> fall through -> x19 = 1
# ============================================================
    addi x1, x0, -1            # x1 = -1
    addi x2, x0, 1             # x2 =  1
    bge  x1, x2, bge_nt_skip
    addi x19, x0, 1            # PASS: fall-through
    j    bge_nt_end
bge_nt_skip:
    addi x19, x0, 255          # POISON
bge_nt_end:

# ============================================================
# TEST 11 — BLTU taken (unsigned): 1 < 0xFFFFFFFF -> branch taken -> x20 = 1
# (0xFFFFFFFF is large unsigned, even though -1 signed)
# ============================================================
    addi x1, x0, 1             # x1 = 1
    addi x2, x0, -1            # x2 = 0xFFFFFFFF (unsigned max)
    bltu x1, x2, bltu_taken
    addi x20, x0, 255          # POISON
    j    bltu_taken_end
bltu_taken:
    addi x20, x0, 1            # PASS
bltu_taken_end:

# ============================================================
# TEST 12 — BLTU not taken (unsigned): 0xFFFFFFFF not < 1 -> fall through -> x21 = 1
# ============================================================
    addi x1, x0, -1            # x1 = 0xFFFFFFFF
    addi x2, x0, 1             # x2 = 1
    bltu x1, x2, bltu_nt_skip
    addi x21, x0, 1            # PASS: fall-through
    j    bltu_nt_end
bltu_nt_skip:
    addi x21, x0, 255          # POISON
bltu_nt_end:

# ============================================================
# TEST 13 — BGEU taken (unsigned): 0xFFFFFFFF >= 1 -> branch taken -> x22 = 1
# ============================================================
    addi x1, x0, -1            # x1 = 0xFFFFFFFF
    addi x2, x0, 1             # x2 = 1
    bgeu x1, x2, bgeu_taken
    addi x22, x0, 255          # POISON
    j    bgeu_taken_end
bgeu_taken:
    addi x22, x0, 1            # PASS
bgeu_taken_end:

# ============================================================
# TEST 14 — BGEU taken, equal edge (unsigned): 7 >= 7 -> branch taken -> x23 = 1
# ============================================================
    addi x1, x0, 7             # x1 = 7
    addi x2, x0, 7             # x2 = 7  (equal -> BGEU must be taken)
    bgeu x1, x2, bgeu_eq_taken
    addi x23, x0, 255          # POISON
    j    bgeu_eq_taken_end
bgeu_eq_taken:
    addi x23, x0, 1            # PASS
bgeu_eq_taken_end:

# ============================================================
# TEST 15 — BGEU not taken (unsigned): 1 not >= 0xFFFFFFFF -> fall through -> x24 = 1
# ============================================================
    addi x1, x0, 1             # x1 = 1
    addi x2, x0, -1            # x2 = 0xFFFFFFFF
    bgeu x1, x2, bgeu_nt_skip
    addi x24, x0, 1            # PASS: fall-through
    j    bgeu_nt_end
bgeu_nt_skip:
    addi x24, x0, 255          # POISON
bgeu_nt_end:

_end:
    addi x0, x0, 0
