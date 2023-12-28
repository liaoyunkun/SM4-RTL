///////////////////////////////////////////////////////////////////////////////
// File Name: round_func_key.v
// Module Name: round_func_key
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: round function for key expansion
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5  finish the module
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"
module round_func_key
#(
    parameter WORD_WIDTH = `WORD_WIDTH
)
(
    input clk,
	input rst_n,
	input [WORD_WIDTH-1:0] ck,
	input [WORD_WIDTH-1:0] k_0_in,
	input [WORD_WIDTH-1:0] k_1_in,
	input [WORD_WIDTH-1:0] k_2_in,
	input [WORD_WIDTH-1:0] k_3_in,
	output reg [WORD_WIDTH-1:0] k_4_out
);
	// 内部变量声明
    reg [WORD_WIDTH-1:0] psum1;
	wire [WORD_WIDTH-1:0] word_transformed;
    
	reg [WORD_WIDTH-1:0] k_0_in_d1;
	reg [WORD_WIDTH-1:0] k_0_in_d2;
    reg [WORD_WIDTH-1:0] k_0_in_d3;
	// 功能实现
	// one cycle
 	always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    psum1 <= 0;
		end
		else begin
	        psum1 <= ck ^ k_1_in ^ k_2_in ^ k_3_in;
		end
	end
	
	// two cycle
	t_transform_key t_transform_key_0(
    .clk(clk),
	.rst_n(rst_n),
	.data_in(psum1),
	.data_out(word_transformed));
	
    // synchronize word_transformed and k_0 
    always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    k_0_in_d1 <= 0;
		end
		else begin
		    k_0_in_d1 <= k_0_in;
		end
	end
    always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    k_0_in_d2 <= 0;
		end
		else begin
		    k_0_in_d2 <= k_0_in_d1;
		end
	end
    always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    k_0_in_d3 <= 0;
		end
		else begin
		    k_0_in_d3 <= k_0_in_d2;
		end
	end
	
	// one cycle
	always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    k_4_out <= 0;
		end
		else begin
		    k_4_out <= word_transformed ^ k_0_in_d3;
		end
	end
endmodule