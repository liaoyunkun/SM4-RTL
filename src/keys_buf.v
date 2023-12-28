///////////////////////////////////////////////////////////////////////////////
// File Name: keys_buf.v
// Module Name: keys_buf
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: buffer for 32 generated keys
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5  finish the module
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"

module keys_buf
#(
    parameter KEY_EXPAND_NUM = `KEY_EXPAND_NUM,
    parameter ROUND_NUM = `ROUND_NUM,
    parameter ADDR_WIDTH = `ADDR_WIDTH,
    parameter PIPE_DEPTH = `PIPE_DEPTH,
    parameter WORD_WIDTH = `WORD_WIDTH
)
(
    input clk,
	input w_en,
    input stall,
	input [ADDR_WIDTH-1:0] w_addr,
    input [ADDR_WIDTH*PIPE_DEPTH-1:0] r_addr,
	input [WORD_WIDTH-1:0] data_in,
	output [WORD_WIDTH*PIPE_DEPTH-1:0] data_out
);
    // 内部变量声明
    reg[WORD_WIDTH-1:0] mem [31:0];
    
    wire[ADDR_WIDTH-1:0] paraller_r_addr [0:PIPE_DEPTH-1];
    reg[WORD_WIDTH-1:0] parallel_data_out [0:PIPE_DEPTH-1];
    // 功能声明
    genvar unpk_idx; 
    generate 
        for (unpk_idx=0; unpk_idx<(PIPE_DEPTH); unpk_idx=unpk_idx+1) begin :a
            assign paraller_r_addr[unpk_idx][((ADDR_WIDTH)-1):0] = r_addr[((ADDR_WIDTH)*unpk_idx+(ADDR_WIDTH-1)):((ADDR_WIDTH)*unpk_idx)]; 
        end 
    endgenerate

    genvar pk_idx; 
    generate 
        for (pk_idx=0; pk_idx<(PIPE_DEPTH); pk_idx=pk_idx+1) begin :b
            assign data_out[((WORD_WIDTH)*pk_idx+((WORD_WIDTH)-1)):((WORD_WIDTH)*pk_idx)] = parallel_data_out[pk_idx][((WORD_WIDTH)-1):0]; 
        end 
    endgenerate
    // write
    always@(posedge clk) begin
        if(w_en) begin
            mem[w_addr] <= data_in;
        end
    end
    // read
    genvar i;
    generate 
        for(i = 0; i < PIPE_DEPTH; i = i+1) begin :c
            always@(posedge clk) begin
                if(stall) begin
                    parallel_data_out[i] <= parallel_data_out[i];
                end
                else begin
                    parallel_data_out[i] <= mem[paraller_r_addr[i]]; 
                end
                           
            end
        end
    endgenerate
    
   

endmodule
