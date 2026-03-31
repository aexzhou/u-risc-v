module onehot2bin #(
    parameter ONEHOT_WIDTH = 8
) (
    input  logic [ONEHOT_WIDTH-1:0]         in,
    output logic [$clog2(ONEHOT_WIDTH)-1:0] out
);

    always_comb begin
        out = '0;
        for (int i = 0; i < ONEHOT_WIDTH; i++) begin
            if (in[i]) begin
                out = i[$clog2(ONEHOT_WIDTH)-1:0];
            end
        end
    end

    // logic is_onehot;
    // assign is_onehot = ~(|(in & (in - 1'b1)));
    // assign valid = (|in) & is_onehot;

endmodule
