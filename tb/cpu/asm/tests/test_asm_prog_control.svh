/*
* Program-control instruction test: auipc, lui, jal, jalr
*
* Copyright (C) 2026 Alex Zhou
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

class test_asm_prog_control extends test_asm_base;

    function new();
        super.new("test_asm_prog_control");
        hex_file = "test_asm_prog_control.hex";
    endfunction

    virtual task run();
        wait_cycles(200);
    endtask

    virtual task check();
        // lui t0, 1  =>  t0 (x5) = 4096
        `ASSERT_EQ(`U_REGFILE_PATH.X[5],  64'd4096)

        // auipc t1, 0 at PC=0x04  =>  t1 (x6) = 4
        `ASSERT_EQ(`U_REGFILE_PATH.X[6],  64'd4)

        // jal ra, func_a + jalr x0, ra, 0 reached func_a  =>  t2 (x7) = 42
        `ASSERT_EQ(`U_REGFILE_PATH.X[7],  64'd42)

        // jalr poison at 0x14 must have been skipped  =>  t3 (x28) = 0
        `ASSERT_EQ(`U_REGFILE_PATH.X[28], 64'd0)

        // auipc t4, 0 at PC=0x0C  =>  t4 (x29) = 12
        `ASSERT_EQ(`U_REGFILE_PATH.X[29], 64'd12)

        // store results in dmem (byte addr >> 2 = word index for 32-bit words)
        `ASSERT_EQ(`U_DMEM_PATH.memory[0], 64'd4096)  // sw x5, 0(x0)  -> word 0
        `ASSERT_EQ(`U_DMEM_PATH.memory[2], 64'd4)     // sw x6, 8(x0)  -> word 2
        `ASSERT_EQ(`U_DMEM_PATH.memory[4], 64'd42)    // sw x7, 16(x0) -> word 4
    endtask

    virtual task report();
        $display("[%s] t0(lui)=%0d(exp 4096)  t1(auipc)=%0d(exp 4)  t2(jal/jalr)=%0d(exp 42)  t3(poison)=%0d(exp 0)  t4(auipc2)=%0d(exp 12)",
                 testname,
                 `U_REGFILE_PATH.X[5],
                 `U_REGFILE_PATH.X[6],
                 `U_REGFILE_PATH.X[7],
                 `U_REGFILE_PATH.X[28],
                 `U_REGFILE_PATH.X[29]);
    endtask

endclass
