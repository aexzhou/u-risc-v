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
from m5.objects.RiscvCPU import RiscvO3CPU
from m5.objects.IQUnit import IQUnit


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
parser = argparse.ArgumentParser(description="uriscv OoO CPU gem5 config")
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

class uRiscvO3CPU(RiscvO3CPU):
    # only fetch 2 instructions at a time
    fetchWidth = 2
    decodeWidth = 2
    renameWidth = 2
    dispatchWidth = 2
    issueWidth = 2
    commitWidth = 2

    # Fetch 
    fetchBufferSize = 32 # bytes
    fetchQueueSize = 16 
    
    # Decode
    
    # Rename
    numPhysIntRegs = 128 # 32 arch X0-31 regs + 96 rename regs
    numPhysFloatRegs = 128 # WIP on rtl side
    
    # Issue
    instQueues = [IQUnit(numEntries=32)] # reservation stations
    numROBEntries = 64
    
    # Commit
    
    # ----- end of pipeline ---- #
    
    # Memory ordering
    LQEntries = 16
    SQEntries = 16

    # Branching   
    branchPred = BranchPredictor(
        conditionalBranchPred=LocalBP(
            localPredictorSize=2048,
            localCtrBits=2,
        ),
        btb=SimpleBTB(numEntries=256),
        ras=ReturnAddrStack(numEntries=16)
    )
    


# ---------------------------------------------------------------------------
# Processor wrapper (1 core)
# ---------------------------------------------------------------------------

core = uRiscvO3CPU(cpu_id=0)

from gem5.components.processors.base_cpu_core import BaseCPUCore

processor = BaseCPUProcessor(
    cores=[BaseCPUCore(core=core, isa=ISA.RISCV)]
)

# Set RV32 after processor init to avoid creatThreads() from overwriting
for wrapped_core in processor.get_cores():
    for isa in wrapped_core.core.isa:
        isa.riscv_type = "RV32"

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
print(f"  CPU model : O3CPU (2-wide, out-of-order)")
print(f"  ISA       : RISC-V")
print(f"  Clock     : 100 MHz")
print(f"  L1I / L1D : 4 KiB / 4 KiB")
print(f"  L2        : 32 KiB")
print(f"  Memory    : 32 MiB DDR3-1600")
print("=" * 60)

simulator.run()

print()
print("Simulation complete. Stats written to m5out/stats.txt")
