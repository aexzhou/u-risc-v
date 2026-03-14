/*
* Arithmetic asm test: full RV32I ALU op coverage (R/I subsets).
*
* Copyright (C) 2026 Ryan Liu
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

class test_asm_arithmetic extends test_asm_base;

    function new();
        super.new("test_asm_arithmetic");
        hex_file = "test_asm_arithmetic.hex";
    endfunction

    virtual task run();
        wait_cycles(140);
    endtask

    virtual task check();
        // R-type checks
        `ASSERT_EQ(`U_REGFILE_PATH.X[10], 64'd11)                  // add
        `ASSERT_EQ(`U_REGFILE_PATH.X[11], 64'd1)                   // sub
        `ASSERT_EQ(`U_REGFILE_PATH.X[12], 64'd4)                   // and
        `ASSERT_EQ(`U_REGFILE_PATH.X[13], 64'd7)                   // or
        `ASSERT_EQ(`U_REGFILE_PATH.X[14], 64'd3)                   // xor
        `ASSERT_EQ(`U_REGFILE_PATH.X[15], 64'd320)                 // sll
        `ASSERT_EQ(`U_REGFILE_PATH.X[16], 64'd5)                   // srl
        `ASSERT_EQ(`U_REGFILE_PATH.X[17], 64'hFFFFFFFFFFFFFFEB)    // sra (-21)
        `ASSERT_EQ(`U_REGFILE_PATH.X[18], 64'd1)                   // slt
        `ASSERT_EQ(`U_REGFILE_PATH.X[19], 64'd1)                   // sltu

        // I-type checks
        `ASSERT_EQ(`U_REGFILE_PATH.X[20], 64'd12)                  // addi
        `ASSERT_EQ(`U_REGFILE_PATH.X[21], 64'd1)                   // andi
        `ASSERT_EQ(`U_REGFILE_PATH.X[22], 64'd13)                  // ori
        `ASSERT_EQ(`U_REGFILE_PATH.X[23], 64'd6)                   // xori
        `ASSERT_EQ(`U_REGFILE_PATH.X[24], 64'd20)                  // slli
        `ASSERT_EQ(`U_REGFILE_PATH.X[25], 64'd5)                   // srli
        `ASSERT_EQ(`U_REGFILE_PATH.X[26], 64'hFFFFFFFFFFFFFFF5)    // srai (-11)
        `ASSERT_EQ(`U_REGFILE_PATH.X[27], 64'd1)                   // slti
        `ASSERT_EQ(`U_REGFILE_PATH.X[28], 64'd1)                   // sltiu
    endtask

    virtual task report();
        $display("[%s] x10=%0d x11=%0d x12=%0d x13=%0d x14=%0d x15=%0d x16=%0d x17=0x%0h x18=%0d x19=%0d x20=%0d x21=%0d x22=%0d x23=%0d x24=%0d x25=%0d x26=0x%0h x27=%0d x28=%0d",
                 testname,
                 `U_REGFILE_PATH.X[10],
                 `U_REGFILE_PATH.X[11],
                 `U_REGFILE_PATH.X[12],
                 `U_REGFILE_PATH.X[13],
                 `U_REGFILE_PATH.X[14],
                 `U_REGFILE_PATH.X[15],
                 `U_REGFILE_PATH.X[16],
                 `U_REGFILE_PATH.X[17],
                 `U_REGFILE_PATH.X[18],
                 `U_REGFILE_PATH.X[19],
                 `U_REGFILE_PATH.X[20],
                 `U_REGFILE_PATH.X[21],
                 `U_REGFILE_PATH.X[22],
                 `U_REGFILE_PATH.X[23],
                 `U_REGFILE_PATH.X[24],
                 `U_REGFILE_PATH.X[25],
                 `U_REGFILE_PATH.X[26],
                 `U_REGFILE_PATH.X[27],
                 `U_REGFILE_PATH.X[28]);
    endtask

endclass
