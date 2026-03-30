# test_gem5_insertionsort.s — Insertion sort + verification for gem5 SE mode.
#
# Builds a 32-element pseudo-random array on the stack, sorts it with
# insertion sort, then verifies the result is in ascending order.
#
# Exercises for the OoO pipeline:
#   - Nested loops with data-dependent branches (hard to predict during sort)
#   - Back-to-back load/store pairs in the inner shift loop
#   - Independent address computation alongside comparisons (ILP opportunity)
#   - A predictable verification pass for contrast
#
# Exit code (a0): 0 = PASS, 1 = FAIL (array not sorted)

.section .text
.globl _start

.equ N, 32

_start:
    # ---------------------------------------------------------------
    # Allocate array: sp -= N * 4
    # ---------------------------------------------------------------
    addi x5, x0, N             # x5 = N
    slli x6, x5, 2             # x6 = N * 4
    sub  x2, x2, x6            # sp -= N*4 (x2 = base of array)

    # ---------------------------------------------------------------
    # Fill array with pseudo-random values using xorshift32.
    # seed = 12345, iterate: x ^= x<<13; x ^= x>>17; x ^= x<<5
    # Store lower 10 bits (0..1023) to keep values small.
    # ---------------------------------------------------------------
    lui  x7, 3                  # x7 = seed (12288, close enough to 12345)
    addi x7, x7, 57            # x7 = 12345
    addi x8, x0, 0             # x8 = i = 0

fill_loop:
    bge  x8, x5, fill_done     # if i >= N, done filling

    # xorshift32 step
    slli x9, x7, 13            # x9 = seed << 13
    xor  x7, x7, x9            # seed ^= (seed << 13)
    srai x9, x7, 17            # x9 = seed >> 17 (arithmetic)
    xor  x7, x7, x9            # seed ^= (seed >> 17)
    slli x9, x7, 5             # x9 = seed << 5
    xor  x7, x7, x9            # seed ^= (seed << 5)

    # Mask to lower 10 bits: val = seed & 0x3FF
    andi x10, x7, 0x3FF        # x10 = seed & 1023

    # arr[i] = val
    slli x11, x8, 2            # x11 = i * 4
    add  x11, x2, x11          # x11 = &arr[i]
    sw   x10, 0(x11)           # arr[i] = val

    addi x8, x8, 1             # i++
    jal  x0, fill_loop

fill_done:

    # ---------------------------------------------------------------
    # Insertion sort.
    # for (i = 1; i < N; i++):
    #     key = arr[i]
    #     j = i - 1
    #     while (j >= 0 && arr[j] > key):
    #         arr[j+1] = arr[j]
    #         j--
    #     arr[j+1] = key
    # ---------------------------------------------------------------
    addi x18, x0, 1            # x18 = i = 1 (outer loop counter)

sort_outer:
    bge  x18, x5, sort_done    # if i >= N, sorting complete

    # key = arr[i]
    slli x19, x18, 2           # x19 = i * 4
    add  x20, x2, x19          # x20 = &arr[i]
    lw   x21, 0(x20)           # x21 = key = arr[i]

    # j = i - 1
    addi x22, x18, -1          # x22 = j

sort_inner:
    blt  x22, x0, sort_insert  # if j < 0, insert key

    # load arr[j]
    slli x23, x22, 2           # x23 = j * 4
    add  x24, x2, x23          # x24 = &arr[j]
    lw   x25, 0(x24)           # x25 = arr[j]

    # if arr[j] <= key, stop shifting
    bge  x21, x25, sort_insert # if key >= arr[j], insert here

    # arr[j+1] = arr[j] (shift right)
    sw   x25, 4(x24)           # arr[j+1] = arr[j]

    addi x22, x22, -1          # j--
    jal  x0, sort_inner

sort_insert:
    # arr[j+1] = key
    addi x23, x22, 1           # x23 = j + 1
    slli x23, x23, 2           # x23 = (j+1) * 4
    add  x24, x2, x23          # x24 = &arr[j+1]
    sw   x21, 0(x24)           # arr[j+1] = key

    addi x18, x18, 1           # i++
    jal  x0, sort_outer

sort_done:

    # ---------------------------------------------------------------
    # Verify: walk the array and check arr[k] <= arr[k+1] for all k.
    # ---------------------------------------------------------------
    addi x26, x0, 0            # x26 = k = 0
    addi x27, x5, -1           # x27 = N - 1

verify_loop:
    bge  x26, x27, verify_pass # if k >= N-1, all checks passed

    slli x28, x26, 2           # x28 = k * 4
    add  x29, x2, x28          # x29 = &arr[k]
    lw   x30, 0(x29)           # x30 = arr[k]
    lw   x31, 4(x29)           # x31 = arr[k+1]

    blt  x31, x30, verify_fail # if arr[k+1] < arr[k], not sorted

    addi x26, x26, 1           # k++
    jal  x0, verify_loop

verify_pass:
    addi x10, x0, 0            # a0 = 0 (PASS)
    jal  x0, exit

verify_fail:
    addi x10, x0, 1            # a0 = 1 (FAIL)

exit:
    # Restore stack
    add  x2, x2, x6            # sp += N*4

    # Exit syscall
    addi x17, x0, 93           # a7 = 93 (__NR_exit)
    ecall
