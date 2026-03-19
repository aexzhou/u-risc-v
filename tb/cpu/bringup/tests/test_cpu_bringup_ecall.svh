/*
 * Ecall bringup test: verify ecall decode, pipeline, flush, and top-level output.
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

class test_cpu_bringup_ecall extends test_cpu_bringup_base;

    bit ecall_seen;

    function new();
        super.new("test_cpu_bringup_ecall");
        ecall_seen = 0;
    endfunction

    virtual function void set_imem();
        imem[0] = 32'h05d00893; // addi x17, x0, 93   (a7 = 93)
        imem[1] = 32'h00000013; // nop
        imem[2] = 32'h00000073; // ecall
        imem[3] = 32'h02a00093; // addi x1, x0, 42    (should be flushed)
        imem[4] = 32'h02a00093; // addi x1, x0, 42    (should be flushed)
    endfunction

    virtual task run();
        for (int i = 0; i < 30; i++) begin
            @(posedge clk);
            if (ecall === 1'b1) begin
                ecall_seen = 1;
                $display("[%s] ecall output asserted at cycle %0d", testname, i);
            end
        end
    endtask

    virtual task check();
        `ASSERT_EQ(ecall_seen, 1'b1)                   // ecall must have pulsed
        `ASSERT_EQ(`U_REGFILE_PATH.X[17], 64'd93)      // a7 = 93
        `ASSERT_EQ(`U_REGFILE_PATH.X[1],  64'd0)       // x1 should stay 0 (flushed)
    endtask

    virtual task report();
        $display("[%s] ecall_seen=%0b  x17=%0d  x1=%0d",
                 testname, ecall_seen,
                 `U_REGFILE_PATH.X[17], `U_REGFILE_PATH.X[1]);
    endtask

endclass
