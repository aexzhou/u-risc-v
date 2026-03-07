module rv_fwdu(
    input  logic [4:0]  idex_rs1, idex_rs2, exm_rd, mwb_rd,
    input  logic        exm_regwrite, mwb_regwrite,
    output logic [1:0]  forward_a, forward_b
);

    always_comb begin
        // No forwarding by default, then resolve each operand independently
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (exm_regwrite && (exm_rd != 0) && (exm_rd == idex_rs1))
            forward_a = 2'b10; // Forward from EX/MEM
        else if (mwb_regwrite && (mwb_rd != 0) && (mwb_rd == idex_rs1))
            forward_a = 2'b01; // Forward from MEM/WB

        if (exm_regwrite && (exm_rd != 0) && (exm_rd == idex_rs2))
            forward_b = 2'b10; // Forward from EX/MEM
        else if (mwb_regwrite && (mwb_rd != 0) && (mwb_rd == idex_rs2))
            forward_b = 2'b01; // Forward from MEM/WB
    end

endmodule
