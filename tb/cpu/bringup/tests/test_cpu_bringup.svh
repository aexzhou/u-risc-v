/*
* Default / smoke bringup test — runs the CPU with all NOPs.
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

// Usage: scripts/run.pl test_cpu_bringup

class test_cpu_bringup extends test_cpu_bringup_base;
    function new();
        super.new("test_cpu_bringup");
    endfunction

    // No overrides - uses base class defaults (NOP sled, 20-cycle run)
    virtual task run();
        wait_cycles(20);
    endtask
endclass
