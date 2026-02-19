module mem #(
    parameter int DEPTH = 256,
    parameter int DW    = 32
) (
    input  logic           clk,
    input  logic           rst,
    input  logic [63:0]    address,
    input  logic [DW-1:0]  write_data,
    input  logic           mem_read,
    input  logic           mem_write,
    output logic [DW-1:0]  read_data
);

    localparam int BYTE_SHIFT = $clog2(DW) - 3;  // byte -> word address shift

    logic [DW-1:0] memory [0:DEPTH-1];

    // Read data
    always_ff @(posedge clk) begin
        if (mem_read)
            read_data <= memory[address[63:BYTE_SHIFT]];  // Address is byte-aligned
    end

    // Write data
    always_ff @(posedge clk) begin
        if (mem_write)
            memory[address[63:BYTE_SHIFT]] <= write_data;  // Address is byte-aligned
    end

endmodule
