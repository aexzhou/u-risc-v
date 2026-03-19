/*
* Hardware boilerplate for ASM-based CPU testbench.
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

// Include inside a module body. Declares DUT, clock, reset, VCD dump,
// and the hierarchical path macros used by asm test classes.
// IMEM/DMEM are sized to 4096 words (16 KB each) to accommodate real
// programs assembled by scripts/assemble.py.

`define U_IMEM_PATH    u_cpu.u_ifu.u_imem
`define U_DMEM_PATH    u_cpu.u_memu.u_dmem
`define U_REGFILE_PATH u_cpu.u_idu.u_regfile

localparam CLK_HALF_PERIOD = 5;

logic clk   = 0;
logic rst_n = 1;
logic ecall;

rv_cpu #(
    .IMEM_DEPTH(4096),
    .DMEM_DEPTH(4096)
) u_cpu (
    .clk  (clk),
    .rst_n(rst_n),
    .ecall(ecall)
);

initial forever #CLK_HALF_PERIOD clk = ~clk;

// VCD Dump
initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0);
end
