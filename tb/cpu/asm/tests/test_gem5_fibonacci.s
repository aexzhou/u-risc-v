# test_gem5_fibonacci.s - Compute Fibonacci numbers for gem5 SE mode.
#
# Calculates the first N Fibonacci values and stores them to the stack.
# Uses sp-relative addressing (gem5 SE mode sets up sp automatically).
# Ends with exit ecall so the simulation terminates cleanly.
#
# Result: fib[0..N-1] stored on the stack, final value in x10 (a0).
#         For N=20: fib(19) = 4181

.section .text
.globl _start

_start:
    addi x5, x0, 20        # x5 = N (number of Fibonacci values to compute)

    # Allocate N words on the stack
    slli x6, x5, 2         # x6 = N * 4 (bytes needed)
    sub  x2, x2, x6        # sp -= N*4

    # fib[0] = 0, fib[1] = 1
    addi x10, x0, 0        # x10 = fib(n-2) = 0
    addi x11, x0, 1        # x11 = fib(n-1) = 1
    sw   x10, 0(x2)        # mem[sp + 0] = fib[0]
    sw   x11, 4(x2)        # mem[sp + 4] = fib[1]

    # Loop counter
    addi x12, x0, 2        # x12 = i = 2

fib_loop:
    bge  x12, x5, fib_done # if i >= N, done

    add  x13, x10, x11     # x13 = fib(n-2) + fib(n-1)

    # Store fib[i] to stack
    slli x14, x12, 2       # x14 = i * 4
    add  x15, x2, x14      # x15 = sp + i*4
    sw   x13, 0(x15)       # mem[sp + i*4] = fib[i]

    # Shift window: fib(n-2) = fib(n-1), fib(n-1) = fib(n)
    addi x10, x11, 0       # x10 = old x11
    addi x11, x13, 0       # x11 = new value

    addi x12, x12, 1       # i++
    jal  x0, fib_loop

fib_done:
    # x10 = fib(N-2), x11 = fib(N-1) — move final value to a0 for exit
    addi x10, x11, 0       # a0 = fib(N-1) = 4181

    # Clean up stack
    add  x2, x2, x6        # sp += N*4

    # Exit syscall
    addi x17, x0, 93       # a7 = 93 (__NR_exit)
    addi x10, x0, 0        # a0 = 0 (exit code)
    ecall
