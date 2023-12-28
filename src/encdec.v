///////////////////////////////////////////////////////////////////////////////
// File Name: encdec.v
// Module Name: encdec
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: encode, decode module
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5 finish the module
//      + 2020/7/13 modify eop related logic
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"

module encdec
#(   
    parameter ROUND_NUM = `ROUND_NUM,
    parameter ROUND_DELAY = `ROUND_DELAY,
    parameter BLOCK_LENGTH = `BLOCK_LENGTH,
    parameter KEY_EXPAND_NUM = `KEY_EXPAND_NUM,
    parameter WORD_WIDTH = `WORD_WIDTH,
    parameter PIPE_DEPTH = `PIPE_DEPTH,
    parameter ADDR_WIDTH = `ADDR_WIDTH
)
(
    input clk,
	input rst_n,
	input cfg_mod,      // 工作模式，0为加密，1为解密
	input start,        // 第一级round_num模块开始迭代
    input data_valid,       // 输入明文/密文有效
    input stall,        // 暂停
    // 128bit data + 1bit eop 
	input [BLOCK_LENGTH-1+1:0] data,        // 128bit明文/密文+1bit结束标识位
    input [WORD_WIDTH*PIPE_DEPTH-1:0] rk,       // 轮密钥
	output result_valid,        // 结果有效
    output [ADDR_WIDTH*PIPE_DEPTH-1:0] rk_addr,     // 轮密钥地址
    // 128bit data + 1bit eop 
 	output [BLOCK_LENGTH-1+1:0] result      // 128bit迭代结果+1bit结束标识位
);
    // 内部变量声明    
    wire [BLOCK_LENGTH-1:0] pipe_result [0:PIPE_DEPTH];
    wire pipe_eop [0:PIPE_DEPTH];
    
    wire pipe_result_valid [0:PIPE_DEPTH-1];
    
    wire pipe_cfg_mod [0:PIPE_DEPTH];
    wire pipe_start [0:PIPE_DEPTH];
    wire pipe_data_valid [0:PIPE_DEPTH];
    
    wire [WORD_WIDTH-1:0] pipe_rk [0:PIPE_DEPTH-1]; 
    wire [ADDR_WIDTH-1:0] pipe_rk_addr [0:PIPE_DEPTH-1];
    
    reg cfg_mod_reg;
    reg [BLOCK_LENGTH-1+1:0] data_reg;
    reg data_valid_reg;
    reg start_reg;
    //  功能实现
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cfg_mod_reg <= 0;
        end
        else if(stall) begin
            cfg_mod_reg <= cfg_mod_reg;
        end
        else if(data_valid) begin
            cfg_mod_reg <= cfg_mod;
        end
        else begin
            cfg_mod_reg <= cfg_mod_reg;
        end
    end
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_reg <= 0;
        end
        else if(stall) begin
            data_reg <= data_reg;
        end
        else begin
            data_reg <= data;
        end
    end
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_valid_reg <= 0;
        end
        else if(stall) begin
            data_valid_reg <= data_valid_reg;
        end
        else begin
            data_valid_reg <= data_valid;
        end
    end
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            start_reg <= 0;
        end
        else if(stall) begin
            start_reg <= start_reg;
        end
        else begin
            start_reg <= start;
        end
    end
    
    assign pipe_cfg_mod[0] = cfg_mod_reg;
    assign pipe_start[0] = start_reg;
    assign pipe_data_valid[0] = data_valid_reg;
    assign pipe_result[0] = data_reg[BLOCK_LENGTH-1+1:1];
    assign pipe_eop[0] = data_reg[0];
    
    assign result_valid = pipe_result_valid[PIPE_DEPTH-1];
    // antitone transform
    assign result = {pipe_result[PIPE_DEPTH][WORD_WIDTH-1:0],
                    pipe_result[PIPE_DEPTH][2*WORD_WIDTH-1:WORD_WIDTH],
                    pipe_result[PIPE_DEPTH][3*WORD_WIDTH-1:2*WORD_WIDTH],
                    pipe_result[PIPE_DEPTH][BLOCK_LENGTH-1:3*WORD_WIDTH],
                    pipe_eop[PIPE_DEPTH]};
    // debug
    wire[127:0] result_debug;
    assign result_debug = {pipe_result[PIPE_DEPTH][WORD_WIDTH-1:0],
                    pipe_result[PIPE_DEPTH][2*WORD_WIDTH-1:WORD_WIDTH],
                    pipe_result[PIPE_DEPTH][3*WORD_WIDTH-1:2*WORD_WIDTH],
                    pipe_result[PIPE_DEPTH][BLOCK_LENGTH-1:3*WORD_WIDTH]};
    
    // unpack rk
    genvar unpk_idx; 
    generate 
        for (unpk_idx=0; unpk_idx<(PIPE_DEPTH); unpk_idx=unpk_idx+1) begin :b
            assign pipe_rk[unpk_idx][((WORD_WIDTH)-1):0] = rk[((WORD_WIDTH)*unpk_idx+(WORD_WIDTH-1)):((WORD_WIDTH)*unpk_idx)]; 
        end 
    endgenerate
    // pack rk_addr
    
    genvar pk_idx; 
    generate 
        for (pk_idx=0; pk_idx<(PIPE_DEPTH); pk_idx=pk_idx+1) begin :a
            assign rk_addr[((ADDR_WIDTH)*pk_idx+((ADDR_WIDTH)-1)):((ADDR_WIDTH)*pk_idx)] = pipe_rk_addr[pk_idx][((ADDR_WIDTH)-1):0]; 
        end 
    endgenerate
    
    genvar i;
    generate 
        for(i = 0; i < PIPE_DEPTH; i = i + 1) begin: ENC_DEC
            assign pipe_start[i+1] = pipe_result_valid[i]; 
            assign pipe_data_valid[i+1] = pipe_result_valid[i];
            if(i == PIPE_DEPTH-1) begin
                // the last stage
                round_num 
                #(
                .ROUND_NUM(32 - i * ROUND_NUM),
                .OFFSET(ROUND_NUM*i)
                )
                round_num_0
                (
                .clk(clk),
                .rst_n(rst_n),
                .cfg_mod_in(pipe_cfg_mod[i]),
                .start(pipe_start[i]),
                .data_valid(pipe_data_valid[i]),
                .stall(stall),
                .eop_in(pipe_eop[i]),
                .data(pipe_result[i]),
                .rk(pipe_rk[i]),
                .cfg_mod_out(pipe_cfg_mod[i+1]),
                .eop_out(pipe_eop[i+1]),
                .result_valid(pipe_result_valid[i]),
                .rk_addr(pipe_rk_addr[i]),
                .result(pipe_result[i+1]));                              
            end
            else begin
                round_num 
                #(
                .ROUND_NUM(ROUND_NUM),
                .OFFSET(ROUND_NUM*i)
                )
                round_num_0
                (
                .clk(clk),
                .rst_n(rst_n),
                .cfg_mod_in(pipe_cfg_mod[i]),
                .start(pipe_start[i]),
                .data_valid(pipe_data_valid[i]),
                .stall(stall),
                .eop_in(pipe_eop[i]),
                .data(pipe_result[i]),
                .rk(pipe_rk[i]),
                .cfg_mod_out(pipe_cfg_mod[i+1]),
                .eop_out(pipe_eop[i+1]),
                .result_valid(pipe_result_valid[i]),
                .rk_addr(pipe_rk_addr[i]),
                .result(pipe_result[i+1]));
            end

        end
    endgenerate   
    
    
endmodule