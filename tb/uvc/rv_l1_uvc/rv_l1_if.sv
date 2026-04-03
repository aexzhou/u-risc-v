interface rv_l1_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LINE_WIDTH = 128
)(
    input logic clk,
    input logic rst_n
);

    logic                    req_valid;
    logic                    req_ready;
    logic [ADDR_WIDTH-1:0]   req_addr;
    logic                    req_wr;
    logic [DATA_WIDTH-1:0]   req_wdata;
    logic [3:0]              req_wmask;

    logic                    resp_valid;
    logic [DATA_WIDTH-1:0]   resp_rdata;
    logic                    resp_hit;

    logic                    mem_req_valid;
    logic                    mem_req_ready;
    logic [ADDR_WIDTH-1:0]   mem_req_addr;
    logic                    mem_req_wr;
    logic [LINE_WIDTH-1:0]   mem_req_wdata;
    logic                    mem_wr_ack;
    logic                    mem_resp_valid;
    logic [LINE_WIDTH-1:0]   mem_resp_rdata;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output req_valid, req_addr, req_wr, req_wdata, req_wmask;
        input  req_ready, resp_valid, resp_rdata, resp_hit;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input req_valid, req_ready, req_addr, req_wr, req_wdata, req_wmask;
        input resp_valid, resp_rdata, resp_hit;
        input mem_req_valid, mem_req_ready, mem_req_addr, mem_req_wr, mem_req_wdata;
        input mem_wr_ack, mem_resp_valid, mem_resp_rdata;
    endclocking

    modport driver  (clocking drv_cb, input clk, input rst_n);
    modport monitor (clocking mon_cb, input clk, input rst_n);

endinterface : rv_l1_if
