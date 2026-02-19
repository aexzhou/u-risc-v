REPO_ROOT   := $(shell pwd)
CPU_DIR     := $(REPO_ROOT)/hdl/cpu
COMMON_DIR  := $(REPO_ROOT)/hdl/common
TB_BRINGUP  := $(REPO_ROOT)/tb/cpu/bringup

CPU_F       := $(CPU_DIR)/top/cpu.f
TB_TOP      := $(TB_BRINGUP)/test_cpu_bringup.sv

RUN_DIR     := $(REPO_ROOT)/rundir

# Per-test output directories
TB_BRINGUP_NAME := test_cpu_bringup
TB_BRINGUP_DIR  := $(RUN_DIR)/$(TB_BRINGUP_NAME)
TB_BRINGUP_WORK := $(TB_BRINGUP_DIR)/work

VERILATOR        := verilator
VERILATOR_FLAGS  := --binary --sv -Wall --timing \
                    --top-module $(TB_BRINGUP_NAME)

# Expand ${CPU_DIR} in cpu.f at build time
CPU_F_EXPANDED := $(TB_BRINGUP_DIR)/cpu_expanded.f

.PHONY: all cpu test_datapath_bringup clean

all: cpu

$(TB_BRINGUP_DIR):
	mkdir -p $(TB_BRINGUP_WORK)

# Expand cpu.f variable references and write to a temp file
$(CPU_F_EXPANDED): $(CPU_F) | $(TB_BRINGUP_DIR)
	sed 's|$${CPU_DIR}|$(CPU_DIR)|g;s|$${COMMON_DIR}|$(COMMON_DIR)|g' $< > $@

cpu: $(CPU_F_EXPANDED)
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--Mdir $(TB_BRINGUP_WORK) \
		-f $(CPU_F_EXPANDED) \
		$(TB_TOP)

test_datapath_bringup: cpu
	$(TB_BRINGUP_WORK)/V$(TB_BRINGUP_NAME)

clean:
	rm -rf $(RUN_DIR)
