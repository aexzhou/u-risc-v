module dff #(
    parameter int DW = 32
) (
    input  logic          clk,
    input  logic          en,
    input  logic [DW-1:0] din,
    output logic [DW-1:0] dout
);

    logic [DW-1:0] dr;

    always_ff @(posedge clk) begin
        if (en)
            dr <= din;
    end

    assign dout = dr;

endmodule
