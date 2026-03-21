module sram #(
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter DATA_WIDTH = 32
) (
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data_in,
    input cs,                  // Chip select
    input we,                  // Write enable
    input oe,                  // Output enable
    output reg [DATA_WIDTH-1:0] data_out
);

    localparam int BYTE_SHIFT  = $clog2(DATA_WIDTH) - 3;  // byte -> word address shift
    localparam int IDX_BITS    = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] memory [DEPTH-1:0];

    logic [IDX_BITS-1:0] word_addr;
    assign word_addr = IDX_BITS'(addr >> BYTE_SHIFT);

    // Write
    always_ff @(posedge clk) begin
        if (cs && we) begin
            memory[word_addr] <= data_in;
        end
    end

    // Synchronous read
    always_ff @(posedge clk) begin
        if (cs && !we && oe) begin
            data_out <= memory[word_addr];
        end else if (!cs || we || !oe) begin
            // data_out <= {DATA_WIDTH{1'bZ}};
            data_out <= {DATA_WIDTH{1'b0}}; // High impedance when disabled
        end
    end

endmodule
