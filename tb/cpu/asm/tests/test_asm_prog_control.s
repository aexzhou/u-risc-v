.section .text
.globl _start

# Program control instruction test: auipc, lui, jal, jalr
#
# Memory map (PC = byte address, program loaded at 0x00):
#
#   0x00  lui  x5, 1          x5 = 0x1000 = 4096
#   0x04  auipc x6, 0         x6 = 0x04   (PC of this instruction)
#   0x08  jal  x1, func_a     x1 = 0x0C, jump to func_a; proves jal
#
#   ---- after_call (x1 points here) ----
#
#   0x0C  auipc x29, 0        x29 = 0x0C = 12  (for jalr base)
#   0x10  jalr x0, x29, 12    PC = 0x0C+12 = 0x18, skip poison; proves jalr
#   0x14  addi x28, x0, 255   JALR POISON, must NOT execute (x28 stays 0)
#
#   ---- after_jalr ----
#
#   0x18  sw   x5, 0(x0)      dmem[0] = 4096
#   0x1C  sw   x6, 8(x0)      dmem[1] = 4
#   0x20  sw   x7, 16(x0)     dmem[2] = 42
#   0x24  addi x0, x0, 0      _end / halt
#
#   ---- func_a ----
#
#   0x28  addi x7, x0, 42     x7 = 42  (marker: func_a was reached via jal)
#   0x2C  jalr x0, x1, 0      return to x1 = 0x0C (after_call)

_start:
    lui   x5, 1             # x5 = 1 << 12 = 4096
    auipc x6, 0             # x6 = PC (= 0x04)
    jal   x1, func_a        # x1 = 0x0C, jump to func_a

after_call:
    auipc x29, 0            # x29 = PC (= 0x0C = 12)
    jalr  x0, x29, 12       # PC = x29 + 12 = 0x18, skip poison
    addi  x28, x0, 255      # JALR POISON: x28 must stay 0

after_jalr:
    sw    x5, 0(x0)         # dmem[0] = lui result  (4096)
    sw    x6, 8(x0)         # dmem[1] = auipc result (4)
    sw    x7, 16(x0)        # dmem[2] = func_a marker (42)

_end:
    addi  x0, x0, 0         # halt

func_a:
    addi  x7, x0, 42        # x7 = 42 (proves jal reached func_a)
    jalr  x0, x1, 0         # return to x1 = after_call (0x0C)
