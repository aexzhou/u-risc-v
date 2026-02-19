/*
 * rv_datapath.sv
 *
 * 5-stage pipelined RISC-V datapath:
 *   IF -> ID -> EX -> MEM -> WB
 *
 */

module rv_datapath #(
    parameter int DW    = 64,   // data width
    parameter int IMEM_DEPTH = 256,  // instruction memory depth (words)
    parameter int DMEM_DEPTH = 256   // data memory depth (words)
) (
    input logic clk,
    input logic rst_n           // active-low reset
);

// =========================================================================
// IF|ID Pipeline Registers
// =========================================================================
logic [DW-1:0] ifid_pc;
logic [31:0]   ifid_i;

// ID|EX Pipeline Registers
logic [DW-1:0] idex_imm, idex_a, idex_b;
logic [4:0]    idex_rs1, idex_rs2, idex_rd;
logic          idex_regwrite, idex_memtoreg, idex_branch;
logic          idex_memread, idex_memwrite, idex_alusrc;
logic [1:0]    idex_alu_op;
logic [3:0]    idex_alucontrol;

// EX|MEM Pipeline Registers
logic [DW-1:0] exm_aluout, exm_muxb;
logic [4:0]    exm_rd;
logic          exm_regwrite, exm_memtoreg, exm_branch;
logic          exm_memread, exm_memwrite;
logic          exm_zflag;

// MEM|WB Pipeline Registers
logic [DW-1:0] mwb_dout, mwb_aluout;
logic [4:0]    mwb_rd;
logic          mwb_regwrite, mwb_memtoreg;

// =========================================================================
// (1) IF Instruction Fetch
// =========================================================================
logic [DW-1:0] pc_out, pc_incremented, pc_plus_shimm, pc_in;
logic          pc_write, pc_src, ifid_write, if_flush;

always_comb pc_incremented = pc_out + DW'(4);

// pc_src = 1 -> take branch target; 0 -> PC+4
assign pc_in = pc_src ? pc_plus_shimm : pc_incremented;

// PC register: resetable, write-enabled by pc_write
dffr #(.DW(DW), .RESET({DW{1'b0}})) u_pc_r (
    .clk   (clk),
    .rst_n (rst_n),
    .en    (pc_write),
    .din   (pc_in),
    .dout  (pc_out)
);

// Instruction memory (read-only; mem_write tied low)
logic [31:0] imem_out;
mem #(.DEPTH(IMEM_DEPTH), .DW(32)) u_imem (
    .clk        (clk),
    .address    (pc_out),
    .write_data (32'b0),
    .mem_read   (1'b1),
    .mem_write  (1'b0),
    .read_data  (imem_out)
);

// IF/ID pipeline registers
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ifid_pc <= '0;
        ifid_i  <= '0;
    end else begin
        if (ifid_write)
            ifid_pc <= pc_out;

        if (if_flush)
            ifid_i <= 32'd0;        // insert NOP on branch taken
        else if (ifid_write)
            ifid_i <= imem_out;
    end
end

// =========================================================================
// (2) ID Instruction Decode
// =========================================================================
logic [DW-1:0] imm, sh_imm;
logic          hazard_flag;
logic          equal_flag;
logic [DW-1:0] regout1, regout2;

// Control outputs
logic [1:0]    alu_op;
logic          branch, memread, memtoreg, memwrite, alusrc, regwrite;

// Branch target: immediate left-shifted by 1 + ifid_pc
assign sh_imm        = {imm[DW-2:0], 1'b0};
assign pc_plus_shimm = sh_imm + ifid_pc;

rv_immgen #(.DW(DW)) u_immgen (
    .in      (ifid_i),
    .imm_out (imm)
);

rv_datapath_ctrl u_datapath_ctrl (
    .opcode     (ifid_i[6:0]),
    .equal_flag (equal_flag),
    .alu_op      (alu_op),
    .branch     (branch),
    .memread    (memread),
    .memtoreg   (memtoreg),
    .memwrite   (memwrite),
    .alusrc     (alusrc),
    .regwrite   (regwrite),
    .if_flush   (if_flush)
);

// WB write-back data declared here as it feeds back into REGFILE and forwarding
logic [DW-1:0] write_data;
assign write_data = mwb_memtoreg ? mwb_dout : mwb_aluout;

rv_regfile u_regfile (
    .rs1        (ifid_i[19:15]),
    .rs2        (ifid_i[24:20]),
    .writeR     (mwb_rd),
    .write_data (write_data),
    .write      (mwb_regwrite),
    .clk        (clk),
    .rst        (~rst_n),
    .data_out1  (regout1),
    .data_out2  (regout2)
);

rv_hdu u_hdu (
    .ifid_rs1   (ifid_i[19:15]),
    .ifid_rs2   (ifid_i[24:20]),
    .idex_rd    (idex_rd),
    .mem_read   (idex_memread),
    .pc_write   (pc_write),
    .ifid_write (ifid_write),
    .hazard_flag(hazard_flag)
);

// Early branch resolution: compare the two source registers (held in idex_a/b)
assign equal_flag = (idex_a == idex_b);

// ID/EX pipeline registers
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        idex_rs1        <= '0;
        idex_rs2        <= '0;
        idex_rd         <= '0;
        idex_a          <= '0;
        idex_b          <= '0;
        idex_alucontrol <= '0;
        idex_imm        <= '0;
        {idex_regwrite, idex_memtoreg, idex_branch,
         idex_memread,  idex_memwrite, idex_alusrc, idex_alu_op} <= '0;
    end else begin
        idex_rs1        <= ifid_i[19:15];
        idex_rs2        <= ifid_i[24:20];
        idex_rd         <= ifid_i[11:7];
        idex_a          <= regout1;
        idex_b          <= regout2;
        idex_alucontrol <= {ifid_i[30], ifid_i[14:12]};
        idex_imm        <= imm;

        // Insert bubble (NOP) on load-use hazard
        if (hazard_flag)
            {idex_regwrite, idex_memtoreg, idex_branch,
             idex_memread,  idex_memwrite, idex_alusrc, idex_alu_op} <= '0;
        else
            {idex_regwrite, idex_memtoreg, idex_branch,
             idex_memread,  idex_memwrite, idex_alusrc, idex_alu_op}
                <= {regwrite, memtoreg, branch, memread, memwrite, alusrc, alu_op};
    end
end

// =========================================================================
// (3) EX Execute
// =========================================================================
logic [1:0]    forward_a, forward_b;
logic [DW-1:0] alu_a, alu_b, idex_muxb;
logic [3:0]    alu_ctrl;
logic [DW-1:0] alu_out;
logic          zflag;

// Forward MUX for Rs1
always_comb begin
    case (forward_a)
        2'b00:   alu_a = idex_a;
        2'b01:   alu_a = write_data;
        2'b10:   alu_a = exm_aluout;
        default: alu_a = {DW{1'bx}};
    endcase
end

// Forward MUX for Rs2
always_comb begin
    case (forward_b)
        2'b00:   idex_muxb = idex_b;
        2'b01:   idex_muxb = write_data;
        2'b10:   idex_muxb = exm_aluout;
        default: idex_muxb = {DW{1'bx}};
    endcase
end

// Immediate MUX (selects ALU second operand)
assign alu_b = idex_alusrc ? idex_imm : idex_muxb;

rv_alu_ctrl u_alu_ctrl (
    .control (idex_alucontrol),
    .alu_op   (idex_alu_op),
    .opout   (alu_ctrl)
);

rv_alu #(.DW(DW)) u_alu (
    .in1   (alu_a),
    .in2   (alu_b),
    .alu_op (alu_ctrl),
    .out   (alu_out),
    .zflag (zflag)
);

rv_fwdu u_fwdu (
    .idex_rs1    (idex_rs1),
    .idex_rs2    (idex_rs2),
    .exm_rd      (exm_rd),
    .exm_regwrite(exm_regwrite),
    .mwb_rd      (mwb_rd),
    .mwb_regwrite(mwb_regwrite),
    .forward_a   (forward_a),
    .forward_b   (forward_b)
);

// EX/MEM pipeline registers
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        exm_zflag  <= '0;
        exm_aluout <= '0;
        exm_muxb   <= '0;
        exm_rd     <= '0;
        {exm_regwrite, exm_memtoreg, exm_branch,
         exm_memread,  exm_memwrite} <= '0;
    end else begin
        exm_zflag  <= zflag;
        exm_aluout <= alu_out;
        exm_muxb   <= idex_muxb;
        exm_rd     <= idex_rd;
        {exm_regwrite, exm_memtoreg, exm_branch,
         exm_memread,  exm_memwrite}
            <= {idex_regwrite, idex_memtoreg, idex_branch,
                idex_memread,  idex_memwrite};
    end
end

// =========================================================================
// (4) MEM Memory Access
// =========================================================================
assign pc_src = exm_branch & exm_zflag;

mem #(.DEPTH(DMEM_DEPTH), .DW(DW)) u_dmem (
    .clk        (clk),
    .address    (exm_aluout),
    .write_data (exm_muxb),
    .mem_read   (exm_memread),
    .mem_write  (exm_memwrite),
    .read_data  (mwb_dout)
);

// MEM/WB pipeline registers
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mwb_aluout   <= '0;
        mwb_rd       <= '0;
        mwb_regwrite <= '0;
        mwb_memtoreg <= '0;
    end else begin
        mwb_aluout   <= exm_aluout;
        mwb_rd       <= exm_rd;
        mwb_regwrite <= exm_regwrite;
        mwb_memtoreg <= exm_memtoreg;
    end
end

// =========================================================================
// (5) WB Write Back
// =========================================================================
// write_data = mwb_memtoreg ? mwb_dout : mwb_aluout
// Declared and driven combinationally in the ID section above so that the
// register file and forwarding muxes can see it in the same cycle.

endmodule
