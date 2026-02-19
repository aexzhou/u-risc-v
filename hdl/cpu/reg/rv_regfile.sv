/*
 * 64 bit RISC-V 32I Register Module
 */

// Each register is 64 bits
// X0 is a zero-register 64'b0 
// 31 other general regisers, X1-X31, can hold any registers

module rv_regfile(i,writeR,write_data,write,clk,rst,data_out1,data_out2);
  input      [31:0] i; // Instruction Input
  input      [4:0]  writeR;
  input      [63:0] write_data; //write data
  input             write, clk, rst; //enable for write
  output reg [63:0] data_out1;
  output reg [63:0] data_out2;
  wire [4:0] readR1, readR2, writeR; // Register related instructions
  wire [63:0] write_data_protected;

  assign readR1 = i[19:15];
  assign readR2 = i[24:20];
  assign write_data_protected = (writeR == 5'd0)? 64'd0 : write_data; // Protects X0 to not be over-written by any value so X0 maintains having 64'd0.

  reg [63:0] X [0:31] = '{default:64'b0}; // 32 X 64-bit registers
 
  // WRITING LOGIC
  always @(posedge clk, rst, write, writeR, write_data) begin
    if(rst)begin
      X <= '{default:64'b0}; // Upon reset, set all reg data to 64'b0
    end else begin
      if(write) begin
        X[writeR] <= write_data_protected; // Writenum maps to the index of the specific register to be written in the array.
      end 
    end
  end
  
  // READING LOGIC
  always @(*)begin 
    if(readR1 < 32 && readR2 < 32) begin
      data_out1 <= X[readR1]; // data_out recieves data stored in the <readnum>-th register of the register array.
      data_out2 <= X[readR2];
    end else begin
      data_out1 <= 64'b0; // data_out recieves all 0s if otherwise. 
      data_out2 <= 64'b0;
    end 
  end
endmodule