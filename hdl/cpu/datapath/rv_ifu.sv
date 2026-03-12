module rv_ifu #(
    parameter int DW         = 64,
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
logic [DW-1:0] pc_out, pc_incremented, pc_in;

always_comb pc_incremented = pc_out + DW'(4);

// pc_src = 1 -> take branch target; 0 -> PC+4
assign pc_in = pc_src ? pc_branch_target : pc_incremented;

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

        if (if_flush | pc_src)
            ifid_i <= 32'd0;        // insert NOP on branch taken
        else if (ifid_write)
            ifid_i <= imem_out;
    end
end

endmodule : rv_ifu
