// CPU source file list for Verilator

// Common modules
${COMMON_DIR}/dff.sv
${COMMON_DIR}/dffr.sv
${COMMON_DIR}/mem.sv

// Types package
${CHIPLEVEL_DIR}/rv_alu_types.sv

// Components
${CPU_DIR}/components/rv_alu_ctrl.sv
${CPU_DIR}/components/rv_alu.sv
${CPU_DIR}/components/rv_fwdu.sv
${CPU_DIR}/components/rv_hdu.sv
${CPU_DIR}/components/rv_immgen.sv

// Registers
${CPU_DIR}/reg/rv_regfile.sv

// Datapath
${CPU_DIR}/datapath/rv_ifu.sv
${CPU_DIR}/datapath/rv_idu.sv
${CPU_DIR}/datapath/rv_exu.sv
${CPU_DIR}/datapath/rv_memu.sv
${CPU_DIR}/datapath/rv_wbu.sv
${CPU_DIR}/datapath/rv_datapath_ctrl.sv

// Top-level
${CPU_DIR}/top/rv_cpu.sv
