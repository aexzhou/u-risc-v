# u-RISC-V Chiplevel Project

u-RISC-V (micro-RISC-V) is an open source RISC-V CPU project that is developed and tested using Verilator, bypassing commonly licensed EDA tools.

## Table of Contents
- [Setting up](#setting-up)
  - [1. Clone the repository](#1-clone-the-repository)
  - [2. Install Verilator](#2-install-verilator)
  - [3. Set up the project environment](#3-set-up-the-project-environment)
- [Running a test](#running-a-test)

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
