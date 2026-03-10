# Branch flush timing test.
#
# Verifies that when a branch is taken, the instructions between
# the branch and the target are not executed.
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
    addi x1, x0, 5         # x1 = 5
    addi x2, x0, 5         # x2 = 5  (x1 == x2 → beq taken)
    beq  x1, x2, target    # x1 == x2 -> beq taken -> target (+16 bytes)

    # Wrong-path: must NOT execute
    addi x3, x0, 1         # Should be flushed in IF
    addi x4, x0, 11        # Tests pc_src and if_flush
    addi x5, x0, 22        #

target:
    addi x10, x0, 99       # branch target: x10 = 99 = 0x63

_end:
    addi x0, x0, 0
