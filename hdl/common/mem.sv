module mem #(
    parameter int DEPTH = 256,
    parameter int DW    = 32
) (
    input  logic           clk,
    input  logic [63:0]    address,
    input  logic [DW-1:0]  write_data,
    input  logic           mem_read,
    input  logic           mem_write,
    output logic [DW-1:0]  read_data
);

    localparam int BYTE_SHIFT  = $clog2(DW) - 3;  // byte -> word address shift
    localparam int IDX_BITS    = $clog2(DEPTH);

    logic [DW-1:0] memory [0:DEPTH-1];

    // Word index: drop the byte-offset bits, keep only as many bits as needed
    logic [IDX_BITS-1:0] word_addr;
    assign word_addr = IDX_BITS'(address >> BYTE_SHIFT);

    // Read data
    always_ff @(posedge clk) begin
        if (mem_read)
            read_data <= memory[word_addr];
    end

    // Write data
    always_ff @(posedge clk) begin
        if (mem_write)
            memory[word_addr] <= write_data;
    end

endmodule
