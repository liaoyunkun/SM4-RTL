///////////////////////////////////////////////////////////////////////////////
// File Name: tao_tranform_key.v
// Module Name: tao_tranform_key
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: tao transformation
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5 finish the module
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"
module tao_tranform_key
#(
    parameter BYTE_WIDTH = `BYTE_WIDTH, 
    parameter WORD_WIDTH = `WORD_WIDTH 
)
(
    input clk,
	input rst_n,
    input [WORD_WIDTH-1:0] data_in,
	output reg[WORD_WIDTH-1:0] data_out
);
	// 内部变量声明
    wire [BYTE_WIDTH-1:0] byte0;
	wire [BYTE_WIDTH-1:0] byte1;
	wire [BYTE_WIDTH-1:0] byte2;
	wire [BYTE_WIDTH-1:0] byte3;
	wire [BYTE_WIDTH-1:0] byte0_replaced;
	wire [BYTE_WIDTH-1:0] byte1_replaced;
	wire [BYTE_WIDTH-1:0] byte2_replaced;
	wire [BYTE_WIDTH-1:0] byte3_replaced;
	wire [WORD_WIDTH-1:0] word_replaced;
	// 功能实现
	assign {byte0,byte1,byte2,byte3} = data_in;
	
    sbox_replace sbox_0(
    .data_in(byte0),
	.result_out(byte0_replaced)
	);
	
	sbox_replace sbox_1(
    .data_in(byte1),
	.result_out(byte1_replaced)
	);
	
	sbox_replace sbox_2(
    .data_in(byte2),
	.result_out(byte2_replaced)
	);
	
	sbox_replace sbox_3(
    .data_in(byte3),
	.result_out(byte3_replaced)
	);
	
	assign word_replaced = {byte0_replaced,byte1_replaced,byte2_replaced,byte3_replaced};

	always@(posedge clk) begin
	    if(~rst_n) begin
		    data_out <= 0;
		end
		else begin 
		    data_out <= word_replaced;
		end
	end
	
endmodule