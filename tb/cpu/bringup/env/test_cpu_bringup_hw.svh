/*
* Hardware boilerplate for CPU bringup testbench.
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
// and the hierarchical path macros used by bringup test classes.

// ---------------------------------------------------------------------------
// Hierarchical path macros (relative to the enclosing module)
// ---------------------------------------------------------------------------
`define U_IMEM_PATH    u_cpu.u_ifu.u_imem
`define U_DMEM_PATH    u_cpu.u_memu.u_dmem
`define U_REGFILE_PATH u_cpu.u_idu.u_regfile

// ---------------------------------------------------------------------------
// Signals
// ---------------------------------------------------------------------------
localparam CLK_HALF_PERIOD = 5;

logic clk   = 0;
logic rst_n = 1;

// ---------------------------------------------------------------------------
// DUT
// ---------------------------------------------------------------------------
rv_cpu u_cpu (
    .clk  (clk),
    .rst_n(rst_n)
);

// ---------------------------------------------------------------------------
// Clock generator
// ---------------------------------------------------------------------------
initial forever #CLK_HALF_PERIOD clk = ~clk;

// ---------------------------------------------------------------------------
// VCD dump
// ---------------------------------------------------------------------------
initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0);
end
