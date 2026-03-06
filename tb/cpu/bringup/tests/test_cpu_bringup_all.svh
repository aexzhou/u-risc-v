/*
* Aggregate bringup test: runs all bringup subtests sequentially.
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

// Usage: scripts/run test_cpu_bringup_all

`include "test_cpu_bringup.svh"
`include "test_cpu_bringup_basic.svh"
`include "test_cpu_bringup_arithmetic.svh"
`include "test_cpu_bringup_memory.svh"
`include "test_cpu_bringup_branch.svh"
`include "test_cpu_bringup_mem_hazard.svh"

`define RUN_SUBTEST(T) begin T t = new(); run_one(t); end

class test_cpu_bringup_all extends test_cpu_bringup_base;
    int total_tests;
    int passed_tests;

    function new();
        super.new("test_cpu_bringup_all");
        total_tests  = 0;
        passed_tests = 0;
    endfunction

    task automatic run_one(test_cpu_bringup_base subtest);
        $display("\n[%s] Running subtest: %s", testname, subtest.testname);

        subtest.init_imem();
        subtest.set_imem();
        subtest.load_imem();
        subtest.apply_reset();
        subtest.run();
        subtest.check();
        subtest.report();
        subtest.print_pass_fail();

        total_tests++;
        if (subtest.pass)
            passed_tests++;
        else
            pass = 0;
    endtask

    virtual task run();
        `RUN_SUBTEST(test_cpu_bringup)
        `RUN_SUBTEST(test_cpu_bringup_basic)
        `RUN_SUBTEST(test_cpu_bringup_arithmetic)
        `RUN_SUBTEST(test_cpu_bringup_memory)
        `RUN_SUBTEST(test_cpu_bringup_branch)
        `RUN_SUBTEST(test_cpu_bringup_mem_hazard)
    endtask

    virtual task report();
        $display("[%s] Subtest summary: %0d/%0d passed",
                 testname, passed_tests, total_tests);
    endtask
endclass
