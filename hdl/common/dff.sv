module dff #(
    parameter int DW = 32
) (
    input                 clk,
    input        [DW-1:0] d,
    output logic [DW-1:0] q
);

    always_ff @(posedge clk) begin
        q <= d;
    end

endmodule
