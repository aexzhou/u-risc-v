// Hazard detection unit
module rv_hdu(
    input  logic [31:0] ifid_i,
    input  logic [4:0]  idex_rd,
    input  logic        mem_read,
    output logic        pc_write,
    output logic        ifid_write,
    output logic        hazard_flag
);
    logic [4:0] ifid_rs1, ifid_rs2;
    assign ifid_rs1 = ifid_i[19:15];
    assign ifid_rs2 = ifid_i[24:20];
    always_comb begin
        if (mem_read && ((idex_rd == ifid_rs1) || (idex_rd == ifid_rs2))) begin
            // Stalling the pipeline
            hazard_flag = 1'b1;
            ifid_write  = 0;
            pc_write    = 0;
        end else begin
            hazard_flag = 0;
            ifid_write  = 1;
            pc_write    = 1;
        end
    end
endmodule
