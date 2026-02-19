//states for the fsm
`define RST      4'd0
`define IF1      4'd1
`define IF2      4'd2
`define UpdatePC 4'd3 
`define DECODE   4'd4
`define LoadA    4'd5
`define LoadB    4'd6
`define LoadC    4'd7
`define MEMldr   4'd8
`define Loadstr  4'd9
`define MEMstr   4'd10
`define MEMbuff  4'd11
`define WRITE    4'd12

// {opcode,op} definitions for operations
`define MOVi 5'b11010
`define MOVr 5'b11000
`define ADD  5'b10100
`define CMP  5'b10101
`define AND  5'b10110
`define MVN  5'b10111
`define LDR  5'b01100
`define STR  5'b10000
`define HALT 5'b11100