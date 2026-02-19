// CPU source file list for Verilator

// Common modules
${COMMON_DIR}/dff.sv
${COMMON_DIR}/dffr.sv
${COMMON_DIR}/mem.sv

// Components
${CPU_DIR}/components/rv_alu_ctrl.sv
${CPU_DIR}/components/rv_alu.sv
${CPU_DIR}/components/rv_fwdu.sv
${CPU_DIR}/components/rv_hdu.sv
${CPU_DIR}/components/rv_immgen.sv
${CPU_DIR}/components/rv_shifter.sv

// Registers
${CPU_DIR}/reg/rv_regfile.sv

// Datapath
${CPU_DIR}/datapath/rv_datapath_ctrl.sv
${CPU_DIR}/datapath/rv_datapath.sv

// Top-level
${CPU_DIR}/top/rv_cpu.sv
