module dffr #(
    parameter int               DW = 32,
    parameter logic [DW-1:0] RESET = {DW{1'b0}}
) (
    input  logic          clk,
    input  logic          rst_n,
    input  logic          en,
    input  logic [DW-1:0] din,
    output logic [DW-1:0] dout
);

    logic [DW-1:0] dr;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dr <= RESET;
        else if (en)
            dr <= din;
    end

    assign dout = dr;

endmodule
