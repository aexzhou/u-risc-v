module rv_fwdu(
    input  logic [4:0]  idex_rs1, idex_rs2, exm_rd, mwb_rd,
    input  logic        exm_regwrite, mwb_regwrite,
    output logic [1:0]  forward_a, forward_b
);

    always_comb begin
        if (exm_regwrite && (exm_rd != 0) && (exm_rd == idex_rs1)) begin
            forward_a = 2'b10; // Forward from EX/MEM
            forward_b = 2'b00;
        end
        else if (exm_regwrite && (exm_rd != 0) && (exm_rd == idex_rs2)) begin
            forward_a = 2'b00;
            forward_b = 2'b10; // Forward from EX/MEM
        end
        // Forward from MEM/WB pipeline register
        else if (mwb_regwrite
                && (mwb_rd != 0)
                && ~(exm_regwrite && (exm_rd != 0) && (exm_rd == idex_rs1))
                && (mwb_rd == idex_rs1)) begin
            forward_a = 2'b01;
            forward_b = 2'b00;
        end
        else if (mwb_regwrite
                && (mwb_rd != 0)
                && ~(exm_regwrite && (exm_rd != 0) && (exm_rd == idex_rs2))
                && (mwb_rd == idex_rs2)) begin
            forward_a = 2'b00;
            forward_b = 2'b01;
        end
        else begin
            // No forwarding, ALU operands come from the register file
            forward_a = 2'b00;
            forward_b = 2'b00;
        end
    end

endmodule
