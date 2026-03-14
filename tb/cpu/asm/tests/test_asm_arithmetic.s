.section .text
.globl _start

_start:
    # Base values
    addi x1, x0, 5         # x1 = 5
    addi x2, x0, 6         # x2 = 6
    addi x3, x0, -42       # x3 = -42
    addi x4, x0, 1         # x4 = 1
    addi x5, x0, -1        # x5 = 0xFFFF_FFFF

    # R-type: add, sub, and, or, xor, sll, srl, sra, slt, sltu
    add  x10, x1, x2       # 11
    sub  x11, x2, x1       # 1
    and  x12, x1, x2       # 4
    or   x13, x1, x2       # 7
    xor  x14, x1, x2       # 3
    sll  x15, x1, x2       # 320
    srl  x16, x15, x2      # 5
    sra  x17, x3, x4       # -21
    slt  x18, x1, x2       # 1
    sltu x19, x4, x5       # 1

    # I-type: addi, andi, ori, xori, slli, srli, srai, slti, sltiu
    addi x20, x1, 7        # 12
    andi x21, x1, 3        # 1
    ori  x22, x1, 8        # 13
    xori x23, x1, 3        # 6
    slli x24, x1, 2        # 20
    srli x25, x24, 2       # 5
    srai x26, x3, 2        # -11
    slti x27, x1, 6        # 1
    sltiu x28, x4, -1      # 1

_end:
    addi x0, x0, 0
