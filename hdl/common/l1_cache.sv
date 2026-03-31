/*
* L1 Cache
* Copyright (C) 2026 Alex Zhou
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

module l1_cache #(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 32,
    parameter LINE_WIDTH  = 128,   // cache line = 4 words
    parameter NUM_SETS    = 16,
    parameter NUM_WAYS    = 2
)(
    input  logic                    clk,
    input  logic                    rst_n,

    // CPU side
    input  logic                    req_valid,
    output logic                    req_ready,
    input  logic [ADDR_WIDTH-1:0]   req_addr,
    input  logic                    req_wr,         // 0=read, 1=write
    input  logic [DATA_WIDTH-1:0]   req_wdata,      // write data
    input  logic [3:0]              req_wmask,      // byte write mask

    output logic                    resp_valid,     // response ready
    output logic [DATA_WIDTH-1:0]   resp_rdata,
    output logic                    resp_hit,       // 1=hit, 0=miss

    // Memory/ south side (connects to L2 / bus)
    output logic                    mem_req_valid,  // miss -> request to next $ level
    input  logic                    mem_req_ready,  // next level can accept
    output logic [ADDR_WIDTH-1:0]   mem_req_addr,   // line-aligned address
    output logic                    mem_req_wr,     // 0=read (fill), 1=write (evict)
    output logic [LINE_WIDTH-1:0]   mem_req_wdata,  // dirty line being evicted
    input  logic                    mem_wr_ack,     // writeback committed downstream

    input  logic                    mem_resp_valid, // fill data arriving
    input  logic [LINE_WIDTH-1:0]   mem_resp_rdata  // full cache line from memory
);


    localparam OFFSET_BITS      = $clog2(LINE_WIDTH / 8);
    localparam INDEX_BITS       = $clog2(NUM_SETS);
    localparam TAG_BITS         = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;
    localparam WORDS_PER_LINE   = LINE_WIDTH / DATA_WIDTH;       // 4
    localparam WORD_SEL_BITS    = $clog2(WORDS_PER_LINE);        // 2

    /*   [ TAG | INDEX | OFFSET ]   */

    wire [TAG_BITS-1:0]         req_tag;
    wire [INDEX_BITS-1:0]       req_index;
    wire [WORD_SEL_BITS-1:0]    req_word;

    assign req_tag      = req_addr[ADDR_WIDTH-1     -: TAG_BITS     ];
    assign req_index    = req_addr[OFFSET_BITS      +: INDEX_BITS   ];
    assign req_word     = req_addr[2      +: WORD_SEL_BITS ];


    // ========== RAM Structures ==============
    reg [TAG_BITS-1:0]   tag_ram   [NUM_SETS-1:0][NUM_WAYS-1:0];
    reg [LINE_WIDTH-1:0] data_ram  [NUM_SETS-1:0][NUM_WAYS-1:0];
    reg                  valid_ram [NUM_SETS-1:0][NUM_WAYS-1:0];
    reg                  dirty_ram [NUM_SETS-1:0][NUM_WAYS-1:0];
    reg                  lru_ram   [NUM_SETS-1:0];


    // Tag comparison
    logic [$clog2(NUM_WAYS)-1   : 0]    hit_way_val;
    logic [NUM_WAYS-1           : 0]    hit_way_onehot;
    logic hit_way_val_valid;
    logic cache_hit;
    
    genvar way_idx;
    generate
        for (way_idx = 0; way_idx < NUM_WAYS; way_idx++) begin : gen_hit_way_onehot
            assign hit_way_onehot[way_idx] = valid_ram[req_index][way_idx] && 
                                            (tag_ram[req_index][way_idx] == req_tag);
        end : gen_hit_way_onehot
    endgenerate
    assign cache_hit = |hit_way_onehot;
    
    onehot2bin #(.ONEHOT_WIDTH(NUM_WAYS)) u_hit_way_onehot2bin (.in(hit_way_onehot), 
                                                                .out(hit_way_val));


    // Extract word form a given cache line
    function automatic logic [DATA_WIDTH-1:0] line_word (
        input logic [LINE_WIDTH-1:0] line,
        input logic [WORD_SEL_BITS-1:0] sel
    );
        return line[ (sel*DATA_WIDTH) +: DATA_WIDTH ];
    endfunction

    // Byte-masked write into a single word of a line
    function automatic logic [LINE_WIDTH-1:0] line_write_word(
        input logic [LINE_WIDTH    -1 : 0]     old_line,
        input logic [WORD_SEL_BITS -1 : 0]     sel,
        input logic [DATA_WIDTH    -1 : 0]     wdata,
        input logic [3:0]                       wmask
    );
        logic [LINE_WIDTH-1:0] new_line;
        logic [DATA_WIDTH-1:0] old_word, merged;
        new_line = old_line;
        old_word = old_line[sel*DATA_WIDTH +: DATA_WIDTH];
        // todo: generate this???
        merged[7:0]   = wmask[0] ? wdata[7:0]   : old_word[7:0];
        merged[15:8]  = wmask[1] ? wdata[15:8]  : old_word[15:8];
        merged[23:16] = wmask[2] ? wdata[23:16] : old_word[23:16];
        merged[31:24] = wmask[3] ? wdata[31:24] : old_word[31:24];
        new_line[sel*DATA_WIDTH +: DATA_WIDTH] = merged;
        return new_line;
    endfunction

`ifndef __L1_STATE_T__
`define __L1_STATE_T__

    typedef enum logic [2:0] { 
        L1_IDLE             = 3'b000,
        L1_COMPARE_TAG      = 3'b001,
        L1_WRITEBACK        = 3'b010,
        L1_WRITEBACK_WAIT   = 3'b011,
        L1_FILL             = 3'b100,
        L1_FILL_WAIT        = 3'b101,
        L1_READOUT          = 3'b110
    } l1_state_t;

`endif // __L1_STATE_T__

    l1_state_t state;

    // Latched signals, these hold the original request 
    // across multiple cycles during a cache miss
    logic [ADDR_WIDTH-1:0]  lat_addr;
    logic                   lat_wr;
    logic [DATA_WIDTH-1:0]  lat_wdata;
    logic [3:0]             lat_wmask;

    wire [TAG_BITS-1:0]      lat_tag   = lat_addr[ADDR_WIDTH-1 -: TAG_BITS];
    wire [INDEX_BITS-1:0]    lat_index = lat_addr[OFFSET_BITS +: INDEX_BITS];
    wire [WORD_SEL_BITS-1:0] lat_word  = lat_addr[2 +: WORD_SEL_BITS];
    wire [ADDR_WIDTH-1:0]    lat_line_addr = {lat_addr[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};

    logic victim_way;
    logic lat_victim_way;
    logic victim_dirty;
    logic [TAG_BITS-1:0]   victim_tag;
    logic [LINE_WIDTH-1:0] victim_data;

    assign victim_way   = lru_ram[lat_index];
    assign victim_dirty = valid_ram[lat_index][victim_way] && dirty_ram[lat_index][victim_way];
    assign victim_tag   = tag_ram[lat_index][victim_way];
    assign victim_data  = data_ram[lat_index][victim_way];
    

    always_comb begin
        // North/cpu facing
        req_ready = 1'b0;
        resp_valid = 1'b0;
        resp_rdata = '0;
        resp_hit = 1'b0;
        // South/mem facing
        mem_req_valid = 1'b0;
        mem_req_addr = '0;
        mem_req_wr = 1'b0;
        mem_req_wdata = '0;

        /* verilator lint_off CASEINCOMPLETE */
        case (state)
            L1_IDLE : begin
                req_ready = 1'b1;
            end
            L1_COMPARE_TAG : begin
                if (cache_hit) begin
                    resp_valid = 1'b1;
                    resp_hit = 1'b1;
                    resp_rdata = line_word(data_ram[lat_index][hit_way_val], lat_word);
                    // Early signal readiness
                    req_ready = 1'b1;
                end
            end
            L1_WRITEBACK : begin // Send dirty victim line to memory
                mem_req_valid   = 1'b1;
                mem_req_wr      = 1'b1;
                mem_req_addr    = {victim_tag, lat_index, {OFFSET_BITS{1'b0}}};
                mem_req_wdata   = victim_data;
            end
            L1_FILL : begin
                mem_req_valid = 1'b1;
                mem_req_wr    = 1'b0;
                mem_req_addr  = lat_line_addr;
            end
            L1_READOUT : begin
                resp_valid  = 1'b1;
                resp_hit    = 1'b0; // $ miss
                resp_rdata  = line_word(data_ram[lat_index][lat_victim_way], lat_word);
                req_ready   = 1'b1;
            end
        endcase
        /* verilator lint_on CASEINCOMPLETE */
    end

    always_ff @( posedge clk or negedge rst_n ) begin : l1_fsm
        if (!rst_n) begin
            state <= L1_IDLE;
        end
        else begin
            case (state)
                L1_COMPARE_TAG : begin
                    if (cache_hit) begin
                        state <= (req_valid) ? L1_COMPARE_TAG : L1_IDLE;
                    end
                    else begin
                        state <= (victim_dirty) ? L1_WRITEBACK : L1_FILL;
                    end
                end
                L1_WRITEBACK : begin
                    if (mem_req_ready) 
                        state <= L1_WRITEBACK_WAIT; 
                end
                L1_WRITEBACK_WAIT : begin
                    if (mem_wr_ack)
                        state <= L1_FILL;
                end
                L1_FILL : begin
                    if (mem_req_ready)
                        state <= L1_FILL_WAIT;
                end
                L1_FILL_WAIT : begin
                    if (mem_resp_valid)
                        state <= L1_READOUT;
                end
                L1_READOUT : begin
                    if (req_valid)
                        state <= L1_COMPARE_TAG;
                    else
                        state <= L1_IDLE;
                end
                default : begin // L1_IDLE
                    if (req_valid)
                        state <= L1_COMPARE_TAG;
                end
            endcase    
        
        end
    end : l1_fsm

    // Data handling
    always_ff @( posedge clk or negedge rst_n ) begin
        if (!rst_n) begin
            lat_addr <= '0;
            lat_wr <= 1'b0;
            lat_wdata <= '0;
            lat_wmask <= '0;
            for (int set = 0; set < NUM_SETS; set++) begin
                for (int way = 0; way < NUM_WAYS; way++) begin
                    valid_ram[set][way] <= 1'b0;
                    dirty_ram[set][way] <= 1'b0;
                end
            end
        end
        else begin
            // Save by latching the incoming CPU request upon accepting
            if (req_ready && req_valid) begin
                lat_addr  <= req_addr;
                lat_wr    <= req_wr;
                lat_wdata <= req_wdata;
                lat_wmask <= req_wmask;
            end

            if (state == L1_COMPARE_TAG) begin
                if (cache_hit) begin
                    lru_ram[lat_index] <= ~hit_way_val;
                    if (lat_wr) begin
                        // data_ram[lat_index][hit_way_val] <= line_write_word(
                        //     mem_resp_rdata, lat_word, lat_wdata, lat_wmask
                        // );
                        data_ram[lat_index][hit_way_val] <= line_write_word(
                            data_ram[lat_index][hit_way_val], lat_word, lat_wdata, lat_wmask
                        );
                        dirty_ram[lat_index][hit_way_val] <= 1'b1;
                    end else begin
                        // data_ram[lat_index][victim_way]  <= mem_resp_rdata;
                        dirty_ram[lat_index][victim_way] <= 1'b0;
                    end
                end
                else begin // $ miss
                    lat_victim_way <= victim_way;
                end
                

                // lru_ram[lat_index] <= ~victim_way;
            end

            if (state == L1_FILL_WAIT && mem_resp_valid) begin
                if (lat_wr) begin
                    data_ram[lat_index][lat_victim_way] <= line_write_word(
                        mem_resp_rdata,
                        lat_word,
                        lat_wdata,
                        lat_wmask
                    );
                end
                else begin
                    data_ram[lat_index][lat_victim_way] <= mem_resp_rdata;
                end
                tag_ram[lat_index][lat_victim_way] <= lat_tag;
                valid_ram[lat_index][lat_victim_way] <= 1'b1;
                dirty_ram[lat_index][lat_victim_way] <= lat_wr;
                lru_ram[lat_index] <= ~lat_victim_way;
            end
        end
    end

 
endmodule : l1_cache