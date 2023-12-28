///////////////////////////////////////////////////////////////////////////////
// File Name: round_num.v
// Module Name: round_num
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: specified number of round function iteration
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5 finish the module
//      + 2020/7/13 modify eop related logic
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"

module round_num
#(
    parameter KEY_EXPAND_NUM = `KEY_EXPAND_NUM,
    parameter BLOCK_LENGTH = `BLOCK_LENGTH,
    parameter WORD_WIDTH = `WORD_WIDTH,
    parameter ADDR_WIDTH = `ADDR_WIDTH,
    parameter ROUND_NUM = `ROUND_NUM,
    parameter ROUND_DELAY = `ROUND_DELAY,
    parameter ROUND_CNT_WIDTH = `ROUND_CNT_WIDTH,
    parameter OFFSET = 0        // 读取轮密钥的偏移地址
)
(
    input clk,      
	input rst_n,
	input cfg_mod_in,       // 和数据同步的工作模式，输入
	input start,
    input data_valid,
    input stall,
    input eop_in,
	input [BLOCK_LENGTH-1:0] data,
	input [WORD_WIDTH-1:0] rk,
    output cfg_mod_out,     // 和结果同步的工作模式，输出
    output eop_out,
	output reg result_valid,
	output [ADDR_WIDTH-1:0] rk_addr,
	output [BLOCK_LENGTH-1:0] result
);
    // 内部参数声明
    // state definition
    parameter IDLE = 2'b01;
	parameter ENC_DEC = 2'b10;
	// 内部变量声明
	reg [1:0] state;
	reg [1:0] next_state;
	reg [ROUND_CNT_WIDTH-1:0] round_cnt;
	reg [ADDR_WIDTH-1:0] iter_cnt;
	reg [BLOCK_LENGTH-1:0] data_buffer;
	
    wire [WORD_WIDTH-1:0] x_0_in;
	wire [WORD_WIDTH-1:0] x_1_in;
	wire [WORD_WIDTH-1:0] x_2_in;
	wire [WORD_WIDTH-1:0] x_3_in;
	wire [WORD_WIDTH-1:0] x_4_out;
    
	wire [ADDR_WIDTH-1:0] index;
	// 功能实现
	assign {x_0_in, x_1_in, x_2_in, x_3_in} = data_buffer;
	
	always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
	       data_buffer <= 0;
	    end
        else if(stall) begin
            data_buffer <= data_buffer;
        end
	    else if(state == IDLE && data_valid) begin
	       data_buffer <= data;			 
	    end
	    else if(state == ENC_DEC && round_cnt == ROUND_DELAY - 1) begin
	       data_buffer <= {data_buffer, x_4_out};
	    end
	    else begin
	       data_buffer <= data_buffer;
	    end
    end
	
	always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
	        state <= IDLE;
        end
	    else begin
	        state <= next_state;
	    end
    end

    always@(*) begin
        next_state = IDLE;
	    case(state)
            IDLE: begin
                if(stall) begin
                    next_state = IDLE;    
                end
                else if(start == 1) begin
                    next_state = ENC_DEC;
                end
                else begin
                    next_state = IDLE;
                end
            end
            ENC_DEC: begin
                if(stall) begin
                    next_state = ENC_DEC;
                end
                else if(round_cnt == ROUND_DELAY -1 && iter_cnt == ROUND_NUM - 1) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = ENC_DEC;
                end
            end
	    endcase
    end
	
	always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
	        round_cnt <= 0;
	    end
        else if(stall) begin
            round_cnt <= round_cnt;
        end
        else if(state == ENC_DEC) begin
            if(round_cnt == ROUND_DELAY - 1) begin
                round_cnt <= 0;
            end
            else begin
                round_cnt <= round_cnt + 1;
            end
        end
	    else begin
	        round_cnt <= 0;
	    end
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
	        iter_cnt <= 0;
	    end
        else if(stall == 1'b1) begin
            iter_cnt <= iter_cnt;
        end
        else if(round_cnt == ROUND_DELAY - 1) begin
            if(iter_cnt == ROUND_NUM - 1) begin
                iter_cnt <= 0;
            end
            else begin
                iter_cnt <= iter_cnt + 1;
            end
        end
	    else begin
	        iter_cnt <= iter_cnt;
	    end
    end
	
	assign index = (state == ENC_DEC)? iter_cnt + 1 + OFFSET : OFFSET;
    // for decode, rk is reversed
	assign rk_addr = (cfg_mod_in == 1)? (5'd31 - index) : index; 

    round_func_encdec round_func_encdec_0(
    .clk(clk),
	.rst_n(rst_n),
	.rk(rk),
    .stall(stall),
	.x_0_in(x_0_in),
	.x_1_in(x_1_in),
	.x_2_in(x_2_in),
	.x_3_in(x_3_in),
	.x_4_out(x_4_out));
	
	always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
	        result_valid <= 1'd0;
	    end
        else if(stall) begin
            result_valid <= result_valid;
        end
	    else if(state == ENC_DEC && next_state == IDLE) begin
	        result_valid <= 1'd1;
	    end
	    else begin
	        result_valid <= 1'd0;
	    end
    end
	
	assign result = data_buffer;	
    
    
    // why pass cfg_mod along this stage?
    // in some case, the user may change the 
    // cfg_mod, if all the stages share the 
    // same cfg_mod signal from the input of sm4_top,
    // then, the other stages except for the first 
    // will execute in wrong mode
    delay_num_cycle
    #(
    .WORD_WIDTH(1),
    .NUM(ROUND_NUM*ROUND_DELAY+1)
    )
    delay_num_cycle_0
    (
    .clk(clk),
    .rst_n(rst_n),
    .stall(stall),
    .data_in(cfg_mod_in),
    .data_out(cfg_mod_out)
    );
    
    delay_num_cycle
    #(
    .WORD_WIDTH(1),
    .NUM(ROUND_NUM*ROUND_DELAY+1)
    )
    delay_num_cycle_1
    (
    .clk(clk),
    .rst_n(rst_n),
    .stall(stall),
    .data_in(eop_in),
    .data_out(eop_out)
    );
endmodule