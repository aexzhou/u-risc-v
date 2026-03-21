.section .text
.globl _start

_start:
    addi x5, x0, 7       # x5 = 7
    addi x6, x0, 13      # x6 = 13
    add  x7, x5, x6      # x7 = 20
    sw   x7, 0(x0)       # dmem[0] = 20
    lw   x10, 0(x0)      # x10 = dmem[0] = 20
    sw   x5, 8(x0)       # dmem[1] = 7
    lw   x11, 8(x0)      # x11 = dmem[1] = 7
    add  x12, x10, x11   # x12 = 20 + 7 = 27

_end:
    addi x0, x0, 0
