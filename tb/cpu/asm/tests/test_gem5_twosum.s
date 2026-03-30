# test_gem5_twosum.s — Two Sum (LeetCode #1) for gem5 SE mode.
#
# Given an array of integers and a target value, find two indices
# such that arr[i] + arr[j] == target. Return the pair in a0/a1.
#
# Uses the brute-force O(n^2) approach: nested loops over all pairs.
# This is intentional — the nested loops with early-exit create an
# interesting branch prediction profile for the OoO pipeline.
#
# Test cases (run sequentially, each verified):
#   1. arr=[2,7,11,15]       target=9   -> (0,1)
#   2. arr=[3,2,4]           target=6   -> (1,2)
#   3. arr=[1,5,3,8,2,9,4,7] target=11  -> (0,3)  [larger, more work]
#   4. arr=[10,20,30,40,50,60,70,80,90,100,
#           15,25,35,45,55,65,75,85,95,5]
#                             target=105 -> (0,19)  [worst case: answer at end]
#
# Exit code (a0): 0 = all PASS, 1 = FAIL

.section .text
.globl _start

_start:
    # Use x3 (gp) as pass/fail flag: 0 = passing
    addi x3, x0, 0

    # ---------------------------------------------------------------
    # Test 1: arr=[2,7,11,15], target=9, expect (0,1)
    # ---------------------------------------------------------------
    addi x2, x2, -16           # alloc 4 words
    addi x5, x0, 2
    sw   x5, 0(x2)
    addi x5, x0, 7
    sw   x5, 4(x2)
    addi x5, x0, 11
    sw   x5, 8(x2)
    addi x5, x0, 15
    sw   x5, 12(x2)

    addi x10, x2, 0            # a0 = arr base
    addi x11, x0, 4             # a1 = len
    addi x12, x0, 9             # a2 = target
    jal  x1, two_sum            # call two_sum -> (a0=i, a1=j)

    # Verify: expect a0=0, a1=1
    bne  x10, x0, fail          # a0 != 0 -> fail
    addi x5, x0, 1
    bne  x11, x5, fail          # a1 != 1 -> fail
    addi x2, x2, 16             # free

    # ---------------------------------------------------------------
    # Test 2: arr=[3,2,4], target=6, expect (1,2)
    # ---------------------------------------------------------------
    addi x2, x2, -12
    addi x5, x0, 3
    sw   x5, 0(x2)
    addi x5, x0, 2
    sw   x5, 4(x2)
    addi x5, x0, 4
    sw   x5, 8(x2)

    addi x10, x2, 0
    addi x11, x0, 3
    addi x12, x0, 6
    jal  x1, two_sum

    addi x5, x0, 1
    bne  x10, x5, fail          # a0 != 1 -> fail
    addi x5, x0, 2
    bne  x11, x5, fail          # a1 != 2 -> fail
    addi x2, x2, 12

    # ---------------------------------------------------------------
    # Test 3: arr=[1,5,3,8,2,9,4,7], target=11, expect (0,3)
    # ---------------------------------------------------------------
    addi x2, x2, -32
    addi x5, x0, 1
    sw   x5, 0(x2)
    addi x5, x0, 5
    sw   x5, 4(x2)
    addi x5, x0, 3
    sw   x5, 8(x2)
    addi x5, x0, 8
    sw   x5, 12(x2)
    addi x5, x0, 2
    sw   x5, 16(x2)
    addi x5, x0, 9
    sw   x5, 20(x2)
    addi x5, x0, 4
    sw   x5, 24(x2)
    addi x5, x0, 7
    sw   x5, 28(x2)

    addi x10, x2, 0
    addi x11, x0, 8
    addi x12, x0, 11
    jal  x1, two_sum

    bne  x10, x0, fail          # a0 != 0 -> fail
    addi x5, x0, 3
    bne  x11, x5, fail          # a1 != 3 -> fail
    addi x2, x2, 32

    # ---------------------------------------------------------------
    # Test 4: arr=[10,20,30,...,100,15,25,...,95,5], target=105
    #         20 elements, expect (0,19) — worst case, answer is the
    #         last pair checked by the outer loop's first iteration.
    # ---------------------------------------------------------------
    addi x2, x2, -80           # 20 words
    # Store values: 10,20,30,40,50,60,70,80,90,100
    addi x5, x0, 10
    sw   x5, 0(x2)
    addi x5, x0, 20
    sw   x5, 4(x2)
    addi x5, x0, 30
    sw   x5, 8(x2)
    addi x5, x0, 40
    sw   x5, 12(x2)
    addi x5, x0, 50
    sw   x5, 16(x2)
    addi x5, x0, 60
    sw   x5, 20(x2)
    addi x5, x0, 70
    sw   x5, 24(x2)
    addi x5, x0, 80
    sw   x5, 28(x2)
    addi x5, x0, 90
    sw   x5, 32(x2)
    addi x5, x0, 100
    sw   x5, 36(x2)
    # 15,25,35,45,55,65,75,85,95,5
    addi x5, x0, 15
    sw   x5, 40(x2)
    addi x5, x0, 25
    sw   x5, 44(x2)
    addi x5, x0, 35
    sw   x5, 48(x2)
    addi x5, x0, 45
    sw   x5, 52(x2)
    addi x5, x0, 55
    sw   x5, 56(x2)
    addi x5, x0, 65
    sw   x5, 60(x2)
    addi x5, x0, 75
    sw   x5, 64(x2)
    addi x5, x0, 85
    sw   x5, 68(x2)
    addi x5, x0, 95
    sw   x5, 72(x2)
    addi x5, x0, 5
    sw   x5, 76(x2)

    addi x10, x2, 0
    addi x11, x0, 20
    addi x12, x0, 105
    jal  x1, two_sum

    # Expect (9, 19): arr[9]=100, arr[19]=5, 100+5=105
    addi x5, x0, 9
    bne  x10, x5, fail          # a0 != 9 -> fail
    addi x5, x0, 19
    bne  x11, x5, fail          # a1 != 19 -> fail
    addi x2, x2, 80

    # ---------------------------------------------------------------
    # All tests passed
    # ---------------------------------------------------------------
    addi x10, x0, 0            # a0 = 0 (PASS)
    jal  x0, exit

fail:
    addi x10, x0, 1            # a0 = 1 (FAIL)

exit:
    addi x17, x0, 93           # a7 = __NR_exit
    ecall


# ===================================================================
# two_sum — brute-force O(n^2) Two Sum
#
#   Args:   a0 (x10) = arr base pointer
#           a1 (x11) = array length N
#           a2 (x12) = target sum
#   Returns: a0 = index i, a1 = index j  (i < j, arr[i]+arr[j]=target)
#            a0 = -1, a1 = -1 if no solution
#
#   Clobbers: x5-x9, x13-x16
# ===================================================================
two_sum:
    addi x13, x0, 0            # x13 = i = 0

ts_outer:
    bge  x13, x11, ts_notfound # if i >= N, no solution

    # Load arr[i]
    slli x5, x13, 2            # x5 = i * 4
    add  x5, x10, x5           # x5 = &arr[i]
    lw   x6, 0(x5)             # x6 = arr[i]

    # complement = target - arr[i]
    sub  x7, x12, x6           # x7 = target - arr[i]

    addi x14, x13, 1           # x14 = j = i + 1

ts_inner:
    bge  x14, x11, ts_next_i   # if j >= N, try next i

    # Load arr[j]
    slli x8, x14, 2            # x8 = j * 4
    add  x8, x10, x8           # x8 = &arr[j]
    lw   x9, 0(x8)             # x9 = arr[j]

    # Check arr[j] == complement
    beq  x9, x7, ts_found      # if arr[j] == complement, found it

    addi x14, x14, 1           # j++
    jal  x0, ts_inner

ts_next_i:
    addi x13, x13, 1           # i++
    jal  x0, ts_outer

ts_found:
    addi x10, x13, 0           # a0 = i
    addi x11, x14, 0           # a1 = j
    jalr x0, x1, 0             # return

ts_notfound:
    addi x10, x0, -1           # a0 = -1
    addi x11, x0, -1           # a1 = -1
    jalr x0, x1, 0             # return
