///////////////////////////////////////////////////////////////////////////////
// File Name: t_transform_key.v
// Module Name: t_transform_key
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: T transformation for key expansion
// Change history: 
//      + 2020/6/18 create the module
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"
module t_transform_key
#(
    parameter WORD_WIDTH = `WORD_WIDTH
)
(
    input clk,
	input rst_n,
	input [WORD_WIDTH-1:0] data_in,
	output [WORD_WIDTH-1:0] data_out
);
    // 内部变量声明
    // delay two cycle
    wire [WORD_WIDTH-1:0] temp;
    // 功能实现
    tao_tranform_key tao_tranform_key_0(
    .clk(clk),
	.rst_n(rst_n),
    .data_in(data_in),
	.data_out(temp));
	
	l_transform_key l_transform_key_0(
    .clk(clk),
	.rst_n(rst_n),
    .data_in(temp),
	.data_out(data_out));
	
endmodule