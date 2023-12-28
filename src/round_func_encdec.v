///////////////////////////////////////////////////////////////////////////////
// File Name: round_func_encdec.v
// Module Name: round_func_encdec
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: round function for encode/decode
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5  finish the module
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"

module round_func_encdec
#(
    parameter WORD_WIDTH = `WORD_WIDTH
)
(
    input clk,
	input rst_n,
    input stall,		// 暂停
	input [WORD_WIDTH-1:0] rk,		// 轮密钥		
	input [WORD_WIDTH-1:0] x_0_in,
	input [WORD_WIDTH-1:0] x_1_in,
	input [WORD_WIDTH-1:0] x_2_in,
	input [WORD_WIDTH-1:0] x_3_in,
	output reg [WORD_WIDTH-1:0] x_4_out
);
	// 内部变量声明
    reg[WORD_WIDTH-1:0] psum1;
	wire[WORD_WIDTH-1:0] word_transformed;
	reg[WORD_WIDTH-1:0] x_0_in_d1;
	reg[WORD_WIDTH-1:0] x_0_in_d2;
    reg[WORD_WIDTH-1:0] x_0_in_d3;
	
	// 功能实现
	// one cycle
 	always@(posedge clk or negedge rst_n) begin
	    if(~rst_n) begin
		    psum1 <= 0;
		end
        else if(stall) begin
            psum1 <= psum1;
        end
		else begin
	        psum1 <= rk ^ x_1_in ^ x_2_in ^ x_3_in;
		end
	end
	
	// two cycle, T transformation
	t_transform_encdec t_transform_encdec_0(
    .clk(clk),
	.rst_n(rst_n),
    .stall(stall),
	.data_in(psum1),
	.data_out(word_transformed));
	
    // synchronize word_transformed and x_0_in
    always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    x_0_in_d1 <= 0;
		end
        else if(stall) begin
            x_0_in_d1 <= x_0_in_d1;
        end
		else begin
		    x_0_in_d1 <= x_0_in;
		end
	end
    
    always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    x_0_in_d2 <= 0;
		end
        else if(stall) begin
            x_0_in_d2 <= x_0_in_d2;
        end
		else begin
		    x_0_in_d2 <= x_0_in_d1;
		end
	end
    
    always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    x_0_in_d3 <= 0;
		end
        else if(stall) begin
            x_0_in_d3 <= x_0_in_d3;
        end
		else begin
		    x_0_in_d3 <= x_0_in_d2;
		end
	end
    
    
	// one cycle
	always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    x_4_out <= 0;
		end
        else if(stall) begin
            x_4_out <= x_4_out;
        end
		else begin
		    x_4_out <= word_transformed ^ x_0_in_d3;
		end
	end
endmodule