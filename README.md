# u-RISC-V Chiplevel Project

u-RISC-V (micro-RISC-V) is an open source RISC-V CPU project that is developed and tested using Verilator, bypassing common licensed EDA tools. 

## How to run a test
Requirements: perl, make

```bash
cd <project_top_dir>
scripts/run.pl <test_name> # Example: scripts/run.pl test_cpu_bringup
# To find the test simulation output directory:
cd <project_top_dir>/rundir/<test_name>/
```

To view a waveform, simply pass `--trace` into `run.pl`. This will create `waveform.vcd` which is located under the test simulation output directory.


