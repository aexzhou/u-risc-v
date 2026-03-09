.section .text
.globl _start

_start:
    addi t0, x0, 7       # t0 = 7
    addi t1, x0, 13      # t1 = 13
    add  t2, t0, t1      # t2 = 20
    sw   t2, 0(x0)       # dmem[0] = 20
    lw   a0, 0(x0)       # a0 = dmem[0] = 20
    sw   t0, 8(x0)       # dmem[1] = 7
    lw   a1, 8(x0)       # a1 = dmem[1] = 7
    add  a2, a0, a1      # a2 = 20 + 7 = 27

_end:
    addi x0, x0, 0
