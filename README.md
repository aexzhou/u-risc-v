# u-RISC-V Chiplevel Project

u-RISC-V (micro-RISC-V) is an open source RISC-V CPU project that is developed and tested using Verilator, bypassing commonly licensed EDA tools.

## Table of Contents
- [Setting up](#setting-up)
  - [1. Clone the repository](#1-clone-the-repository)
  - [2. Install Verilator](#2-install-verilator)
  - [3. Set up the project environment](#3-set-up-the-project-environment)
- [Running a test](#running-a-test)
- [Running a regression](#running-a-regression)
  - [Creating a regression list](#creating-a-regression-list)

## Setting up

### 1. Clone the repository

```bash
git clone <repo-url> uriscv
cd uriscv
```

### 2. Install Verilator

If you have not set up Verilator before, follow the installation instructions on the [Verilator repository](https://github.com/verilator/verilator).

### 3. Set up the project environment

Source the environment script to add `scripts/` to your PATH and enable tab completion:

```bash
source env.sh
```

To make this permanent, add it to your `~/.bashrc`:

```bash
echo "source $(pwd)/env.sh" >> ~/.bashrc
```

## Running a test

```bash
run <testname>
```

Example:

```bash
run test_cpu_bringup_basic
```

To generate a waveform (`waveform.vcd`), pass `--trace`:

```bash
run --trace test_cpu_bringup_basic
```

Simulation outputs and the waveform are written to `rundir/<testname>/`.

With tab completion active (from `env.sh`), pressing `<Tab>` after `run ` will suggest available test names.

## Running a regression

Regressions are named lists of tests stored as `<regressname>.list` files under `tb/`. Any name beginning with `regress_` is treated as a regression instead of a single test.

```bash
run <regressname>
```

Example:

```bash
run regress_cpu_bringup
```

By default, regressions run **2 tests in parallel**. Use `-j N` to control parallelism:

```bash
run regress_cpu_bringup -j 4   # run 4 tests in parallel
run regress_cpu_bringup -j 1   # run sequentially
```

Each test's output is captured to `rundir/<regressname>/<testname>/run.log`. A summary is printed at the end:

```
  PASS   test_cpu_bringup_arithmetic
  PASS   test_cpu_bringup_branch
  FAIL   test_cpu_bringup_mem_hazard  (see rundir/regress_cpu_bringup/test_cpu_bringup_mem_hazard/run.log)
  PASS   test_cpu_bringup_memory
```

### Creating a regression list

Create a `.list` file under `tb/` with one test name per line. Lines starting with `#` are treated as comments:

```
# tb/cpu/bringup/regressions/regress_my_suite.list
test_cpu_bringup_arithmetic
test_cpu_bringup_branch
test_cpu_bringup_memory
```

Run it with:

```bash
run regress_my_suite
```
