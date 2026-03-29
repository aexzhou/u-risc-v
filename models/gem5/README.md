# gem5 Simulation Environment

Execution-driven CPU modeling using [gem5](https://www.gem5.org/).

## What is this?

gem5 is a modular, full-system simulator. Unlike trace-driven simulators, gem5
actually executes programs on a modeled CPU, faithfully simulating the instruction
pipeline, memory hierarchy, and interconnect. This makes it suitable for:

- Evaluating microarchitectural changes with realistic program behavior
- Modeling cache coherence and memory consistency
- Full-system simulation (OS boot, interrupts, I/O devices)
- Syscall-emulation mode for faster user-space workload analysis

## Installation

gem5 is installed systemwide (not as a submodule). Follow these steps once per machine.

### 1. Install build dependencies

```bash
sudo apt install -y build-essential scons python3-dev zlib1g-dev \
    libprotobuf-dev protobuf-compiler libgoogle-perftools-dev \
    libhdf5-dev libpng-dev
```

### 2. Clone and build

```bash
sudo git clone https://github.com/gem5/gem5.git /opt/gem5
cd /opt/gem5 && sudo scons build/RISCV/gem5.opt -j$(nproc)
```

Build variants:
- `gem5.opt` — optimized with debug symbols (recommended)
- `gem5.debug` — full debug, assertions enabled
- `gem5.fast` — highest optimization, no debug support

### 3. Add to PATH

```bash
sudo ln -sf /opt/gem5/build/RISCV/gem5.opt /usr/local/bin/gem5
```

Verify: `gem5 --help`

## Quick Start

### Run the baseline config

```bash
rung uriscv_baseline --resource riscv-hello
```

### Run with a local RISC-V binary

```bash
rung uriscv_baseline --binary <path-to-riscv-elf>
```

The binary must be statically linked and compiled for RISC-V (e.g. with
`riscv64-unknown-elf-gcc -static`).

Output statistics are written to `m5out/stats.txt` by default.

## Baseline Config

`cpu/uriscv_baseline.py` models the current uriscv RTL pipeline:

- **CPU**: MinorCPU (in-order, single-issue) — maps to the 5-stage IF/ID/EX/MEM/WB pipeline
- **ISA**: RISC-V (RV32I base integer)
- **Clock**: 100 MHz
- **Branch prediction**: Minimal BiMode (RTL has none; gem5 requires one)
- **L1I / L1D**: 4 KiB each (RTL has 1 KB SRAM; 4 KiB is gem5's practical minimum)
- **L2**: 32 KiB
- **Memory**: 32 MiB DDR3-1600
- **Mode**: Syscall emulation (SE)

## Directory Structure

```
models/gem5/
  cpu/        # simulation configuration scripts
  README.md       # this file
```

## Creating Custom Configs

Place Python configuration scripts in `cpu/`. gem5 configs define the
system topology, CPU model, cache hierarchy, and memory controller. See
`cpu/uriscv_baseline.py` as a starting point and the gem5 documentation
for the full API: https://www.gem5.org/documentation/
