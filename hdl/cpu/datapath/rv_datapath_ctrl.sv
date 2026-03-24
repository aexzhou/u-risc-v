module rv_datapath_ctrl (
    input  logic [6:0]    opcode,
    output logic [1:0]    alu_op,
    output logic          branch,
    output logic          jump,
    output logic          jalr,
    output logic [1:0]    result_src,
    output logic          memread,
    output logic          memtoreg,
    output logic          memwrite,
    output logic          alusrc,
    output logic          regwrite
);

always_comb begin

    alusrc     = 1'b0;
    memtoreg   = 1'b0;
    regwrite   = 1'b0;
    memread    = 1'b0;
    memwrite   = 1'b0;
    branch     = 1'b0;
    jump       = 1'b0;
    jalr       = 1'b0;
    result_src = 2'b00;
    alu_op     = 2'b00;

    case (opcode)
        `RV32I_R_OPCODE       : begin
                                    alusrc   = 1'b0;
                                    regwrite = 1'b1;
                                    alu_op   = 2'b10;
                                end
        `RV32I_I_ALSL_OPCODE  : begin
                                    alusrc   = 1'b1;
                                    regwrite = 1'b1;
                                end
        `RV32I_I_LOAD_OPCODE  : begin
                                    alusrc   = 1'b1;
                                    memtoreg = 1'b1;
                                    regwrite = 1'b1;
                                    memread  = 1'b1;
                                    alu_op   = 2'b11; // add needed to calc address
                                end
        `RV32I_I_JALR_OPCODE  : begin
                                    jump       = 1'b1;
                                    jalr       = 1'b1;
                                    alusrc     = 1'b1;
                                    regwrite   = 1'b1;
                                    result_src = 2'b11;
                                    alu_op     = 2'b11;
                                end
        `RV32I_S_OPCODE       : begin
                                    alusrc   = 1'b1;
                                    memwrite = 1'b1;
                                    alu_op   = 2'b11; // add needed to calc address
                                end
        `RV32I_B_OPCODE       : begin
                                    branch   = 1'b1;
                                    alu_op   = 2'b01;
                                end
        `RV32I_J_OPCODE       : begin
                                    jump       = 1'b1;
                                    regwrite   = 1'b1;
                                    result_src = 2'b11;
                                end
        `RV32I_U_LUI_OPCODE   : begin
                                    regwrite   = 1'b1;
                                    result_src = 2'b01;
                                end
        `RV32I_U_AUIPC_OPCODE : begin
                                    regwrite   = 1'b1;
                                    result_src = 2'b10;
                                end
        default               : begin
                                end
    endcase
end


endmodule
