"""
gem5 configuration for the uriscv baseline 5-stage in-order RISC-V CPU.

Models the current RTL pipeline:
  - RV32I ISA, single-issue, in-order
  - 5 stages: IF / ID / EX / MEM / WB
  - Data forwarding from EX/MEM and MEM/WB
  - Load-use hazard stall (1 cycle)
  - No branch predictor (static not-taken), 2-cycle misprediction penalty
  - Small L1 caches (RTL uses 1 KB SRAM each; gem5 minimum is larger)

Usage (gem5 is installed systemwide at /opt/gem5):
  rung uriscv_baseline --binary <path-to-riscv-binary>

  To use a gem5 resource instead of a local binary:
      rung uriscv_baseline --resource riscv-hello
"""

import argparse

from gem5.components.boards.simple_board import SimpleBoard
from gem5.components.cachehierarchies.classic.private_l1_private_l2_cache_hierarchy import (
    PrivateL1PrivateL2CacheHierarchy,
)
from gem5.components.memory import SingleChannelDDR3_1600
from gem5.components.processors.base_cpu_processor import BaseCPUProcessor
from gem5.components.processors.cpu_types import CPUTypes
from gem5.isas import ISA
from gem5.resources.resource import obtain_resource, BinaryResource
from gem5.simulate.simulator import Simulator
from gem5.utils.requires import requires

from m5.objects import *
from m5.objects.BranchPredictor import (
    BranchPredictor,
    LocalBP,
    SimpleBTB,
    ReturnAddrStack,
)
from m5.objects.RiscvCPU import RiscvMinorCPU


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
parser = argparse.ArgumentParser(description="uriscv basic 5 stage gem5 config")
parser.add_argument(
    "--binary",
    type=str,
    default=None,
    help="Path to a statically-linked RISC-V ELF binary",
)
parser.add_argument(
    "--resource",
    type=str,
    default=None,
    help="gem5-resources identifier (e.g. riscv-hello)",
)
args = parser.parse_args()

requires(isa_required=ISA.RISCV)


# ---------------------------------------------------------------------------
# CPU core
# ---------------------------------------------------------------------------
# All widths are constrained to 1 to model single-issue

class UriscvMinorCPU(RiscvMinorCPU):
    """Single-issue in-order RISC-V core"""

    # IF
    fetch1LineSnapWidth = 0          # no line-snap alignmeant constraint
    fetch1LineWidth = 0              # fetch full cache line
    fetch1FetchLimit = 1             # fetch 1 instruction per cycle
    fetch1ToFetch2ForwardDelay = 1   # 1-cycle IF->ID forward latency
    fetch1ToFetch2BackwardDelay = 1  # branch redirect penalty (cycles)

    # ID
    fetch2InputBufferSize = 1
    fetch2ToDecodeForwardDelay = 1   # 1-cycle fetch2->decode
    decodeInputBufferSize = 1
    decodeToExecuteForwardDelay = 1  # 1-cycle ID->EX
    decodeInputWidth = 1             # decode 1 instruction per cycle

    # EX + MEM + WB
    executeInputWidth = 1            # issue 1 instruction per cycle
    executeIssueLimit = 1            # single issue
    executeCommitLimit = 1           # retire 1 per cycle
    executeInputBufferSize = 1
    executeCycleInput = True
    executeBranchDelay = 1           # 1 extra cycle after branch resolves

    # Branch predictor
    # gem5 MinorCPU requires a branch predictor
    # This configures a simple, static not-taken branching beahviour
    branchPred = BranchPredictor(
        conditionalBranchPred=LocalBP(
            localPredictorSize=64,
            localCtrBits=2,
        ),
        btb=SimpleBTB(numEntries=16),
        ras=ReturnAddrStack(numEntries=4),
    )


# ---------------------------------------------------------------------------
# Processor wrapper (1 core)
# ---------------------------------------------------------------------------

core = UriscvMinorCPU(cpu_id=0)

from gem5.components.processors.base_cpu_core import BaseCPUCore

processor = BaseCPUProcessor(
    cores=[BaseCPUCore(core=core, isa=ISA.RISCV)]
)

# ---------------------------------------------------------------------------
# Cache hierarchy
# ---------------------------------------------------------------------------

cache_hierarchy = PrivateL1PrivateL2CacheHierarchy(
    l1i_size="4KiB",
    l1d_size="4KiB",
    l2_size="32KiB",
)

# ---------------------------------------------------------------------------
# Memory
# ---------------------------------------------------------------------------

memory = SingleChannelDDR3_1600(size="32MiB")

# ---------------------------------------------------------------------------
# Board
# ---------------------------------------------------------------------------

board = SimpleBoard(
    clk_freq="100MHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)

# ---------------------------------------------------------------------------
# Workload/binary
# ---------------------------------------------------------------------------

if args.binary:
    board.set_se_binary_workload(BinaryResource(args.binary))
elif args.resource:
    board.set_se_binary_workload(obtain_resource(args.resource))
else:
    board.set_se_binary_workload(obtain_resource("riscv-hello")) # Default gem5 smoke test

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

simulator = Simulator(board=board)
print("=" * 60)
print(f"{__file__} --- gem5 SE simulation")
print("=" * 60)
print(f"  CPU model : MinorCPU (single-issue, in-order)")
print(f"  ISA       : RISC-V")
print(f"  Clock     : 100 MHz")
print(f"  L1I / L1D : 4 KiB / 4 KiB")
print(f"  L2        : 32 KiB")
print(f"  Memory    : 32 MiB DDR3-1600")
print("=" * 60)

simulator.run()

print()
print("Simulation complete. Stats written to m5out/stats.txt")
