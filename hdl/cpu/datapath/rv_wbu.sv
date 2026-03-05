module rv_wbu #(
    parameter int DW = 64
) (
    input  logic [DW-1:0]  mwb_dout,
    input  logic [DW-1:0]  mwb_aluout,
    input  logic           mwb_memtoreg,

    output logic [DW-1:0]  write_data
);

assign write_data = mwb_memtoreg ? mwb_dout : mwb_aluout;

endmodule : rv_wbu
