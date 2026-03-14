module rv_ifu #(
    parameter int DW         = 32,
    parameter int IMEM_DEPTH = 256
) (
    input  logic           clk,
    input  logic           rst_n,

    // Control inputs
    input  logic           pc_write,
    input  logic           pc_src,
    input  logic           ifid_write,
    input  logic           if_flush,

    // Branch target (latched with branch instruction)
    input  logic [DW-1:0]  pc_branch_target,

    // Outputs to ID stage
    output logic [DW-1:0]  ifid_pc,
    output logic [31:0]    ifid_i
);

// =========================================================================
// IF Instruction Fetch
// =========================================================================
logic [DW-1:0] pc_r, pc_incremented, pc_next, pc_prev, pc_out;

always_comb pc_incremented = pc_r + DW'(4);

// pc_src = 1 -> take branch target; 0 -> PC+4
assign pc_next = pc_src ? pc_branch_target : pc_incremented;

always_ff @(posedge clk) begin
    pc_prev <= pc_r;
end

// PC register: resetable, write-enabled by pc_write
dffre #(.DW(DW), .RESET({DW{1'b0}})) u_pc_r (
    .clk   (clk),
    .rst_n (rst_n),
    .en    (pc_write),
    .din   (pc_next),
    .dout  (pc_r)
);

assign pc_out = if_flush ? pc_prev : pc_r;

// Instruction memory (read-only; mem_write tied low)
logic [31:0] imem_out;

sram #(
    .DEPTH(IMEM_DEPTH), 
    .DATA_WIDTH(32),
    .ADDR_WIDTH(64)
) u_imem (
    .clk        (clk),
    .addr       (pc_out),
    .data_in    (32'd0),
    .cs         (1'b1),
    .oe         (1'b1),
    .we         (1'b0),
    .data_out   (imem_out)
);

// IF/ID pipeline registers
dffre            #(.DW(DW)) u_ifid_pc_r (.clk(clk), .rst_n(rst_n), .en(ifid_write), .din(pc_out), .dout(ifid_pc));

dffre_sync_flush #(.DW(32)) u_ifid_i_r  (.clk(clk), .rst_n(rst_n), .en(ifid_write), .flush(if_flush | pc_src), .din(imem_out), .dout(ifid_i));

endmodule : rv_ifu
