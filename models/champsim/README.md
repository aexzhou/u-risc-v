# CPU Microarchitectural Models

Trace-driven CPU modeling using [ChampSim](https://github.com/ChampSim/ChampSim).

## What is this?

ChampSim is a trace-driven microarchitectural simulator. Instead of executing real
programs, it replays **traces** — recordings of what a real CPU did when it ran a
program. Each trace entry captures an instruction's PC, whether it was a branch (and
if taken), and what memory addresses it touched.

ChampSim feeds these traces through a modeled CPU pipeline and memory hierarchy,
then reports performance metrics: IPC (instructions per cycle), cache hit/miss rates,
branch misprediction rates, and DRAM access patterns. This lets you experiment with
architectural changes (wider pipelines, bigger caches, different branch predictors)
and see how they affect performance — without writing or compiling any real programs.

## Quick Start

### 1. Build

```bash
./models/champsim/setup.sh
```

This initializes submodules, installs dependencies, and compiles ChampSim with the
baseline config. To build with a different config:

```bash
./models/champsim/setup.sh models/champsim/configs/my_config.json
```

### 2. Get a trace

Download a sample trace from the ChampSim community trace collection:
https://utexas.app.box.com/s/2k54kp8zvrqdfaa8cdhfquvcxwh7yn85/folder/132804598561

These are SPEC CPU 2017 workloads recorded as `.champsimtrace.xz` files (xz-compressed,
ChampSim decompresses on the fly). Each file is a few hundred MB. Pick any one to start.

Place trace files in `models/champsim/champsim/traces/`.

### 3. Run

```bash
models/champsim/champsim/bin/uriscv_baseline \
  --warmup-instructions 1000000 \
  --simulation-instructions 5000000 \
  models/champsim/champsim/traces/gcc_13B.trace.champsimtrace.xz
```

- `--warmup-instructions`: number of instructions to warm up caches/branch predictors
  before measurement begins (results from this phase are discarded)
- `--simulation-instructions`: number of instructions to actually measure
  (omit to run the entire trace)

Output goes to stdout — you'll see periodic heartbeat stats, then a final summary with
IPC, cache stats, and branch prediction accuracy. To get machine-readable output:

```bash
models/champsim/champsim/bin/uriscv_baseline \
  --warmup-instructions 1000000 \
  --simulation-instructions 5000000 \
  --json results.json \
  models/champsim/champsim/traces/gcc_13B.trace.champsimtrace.xz
```

## Baseline Config

`configs/uriscv_baseline.json` models the current uriscv RTL pipeline:

- Single-issue, in-order (all widths = 1, ROB = 1)
- 5-stage pipeline (IF/ID/EX/MEM/WB)
- Bimodal branch predictor (RTL currently has none — placeholder for experiments)
- Small L1I/L1D (1 KB each), minimal L2/LLC
- 100 MHz frequency

## Creating Custom Configs

1. Copy `configs/uriscv_baseline.json` to a new file
2. Modify parameters (pipeline width, cache sizes, branch predictor, etc.)
3. Rebuild: `./models/champsim/setup.sh models/champsim/configs/my_config.json`

Available branch predictors: `bimodal`, `gshare`, `perceptron`, `hashed_perceptron`
Available prefetchers: `no`, `next_line`, `ip_stride`, `spp_dev`, `va_ampm_lite`
Available replacement policies: `lru`, `random`, `drrip`, `srrip`, `ship`
