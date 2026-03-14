# BGEU not taken (unsigned): 1 not >=u 0xFFFFFFFF -> fall through.
# 0xFFFFFFFF is the unsigned maximum; as signed it is -1 which IS less than 1,
# so this case verifies the unsigned comparator is used, not signed.
# x10 = 1 on success, 255 (POISON) if wrong path executed.
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
    addi x1, x0, 1             # x1 = 1
    addi x2, x0, -1            # x2 = 0xFFFFFFFF (unsigned max)
    bgeu x1, x2, skip          # 1 not >=u 0xFFFFFFFF -> not taken
    addi x10, x0, 1            # PASS: fall-through
    j    _end
skip:
    addi x10, x0, 255          # POISON: must not execute

_end:
    addi x0, x0, 0
