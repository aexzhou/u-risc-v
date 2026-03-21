module rv_datapath_ctrl (
    input  logic [6:0]    opcode,
    output logic [1:0]    alu_op,
    output logic          branch,
    output logic          lui,
    output logic          auipc,
    output logic          pc_write,
    output logic          memread,
    output logic          memtoreg,
    output logic          memwrite,
    output logic          alusrc,
    output logic          regwrite
);

always_comb begin
    
    alusrc   = 1'b0;
    memtoreg = 1'b0;
    regwrite = 1'b0;
    memread  = 1'b0;
    memwrite = 1'b0;
    branch   = 1'b0;
    lui      = 1'b0;
    auipc    = 1'b0;
    pc_write = 1'b0;
    alu_op   = 2'b00;

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
                                end
        `RV32I_I_JALR_OPCODE  : begin
                                end
        `RV32I_S_OPCODE       : begin
                                    alusrc   = 1'b1;
                                    memwrite = 1'b1;
                                end
        `RV32I_B_OPCODE       : begin
                                    branch   = 1'b1;
                                    alu_op   = 2'b01;
                                end
        `RV32I_J_OPCODE       : begin
                                end
        `RV32I_U_LUI_OPCODE   : begin
                                    lui      = 1'b1;
                                    regwrite = 1'b1;
                                    pc_write = 1'b1;
                                end
        `RV32I_U_AUIPC_OPCODE : begin
                                    auipc    = 1'b1;
                                    regwrite = 1'b1;
                                    pc_write = 1'b1;
                                end
        default               : begin
                                end
    endcase
end


endmodule
