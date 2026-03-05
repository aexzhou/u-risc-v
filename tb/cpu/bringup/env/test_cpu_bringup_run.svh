/*
* Run sequencer for CPU bringup tests.
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

// Include inside a module body, AFTER the derived test class is defined.
// Requires `BRINGUP_TEST_CLASS to be defined to the derived class name, e.g.:
//   `define BRINGUP_TEST_CLASS test_cpu_bringup_basic

`BRINGUP_TEST_CLASS test;

initial begin
    test = new();
    test.init_imem();
    test.set_imem();
    test.load_imem();
    test.apply_reset();
    test.run();
    test.check();
    test.report();
    test.print_pass_fail();
    $finish;
end

initial begin
    #100000;
    $display("[TIMEOUT] Simulation exceeded time limit");
    $finish;
end
