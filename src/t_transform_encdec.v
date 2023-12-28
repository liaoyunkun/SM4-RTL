///////////////////////////////////////////////////////////////////////////////
// File Name: t_transform_encdec.v
// Module Name: t_transform_encdec
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: T transformation for encode/decode
// Change history: 
//      + 2020/6/18 create the module
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"
module t_transform_encdec
#(
    parameter WORD_WIDTH = `WORD_WIDTH
)
(
    input clk,
	input rst_n,
    input stall,
	input [WORD_WIDTH-1:0] data_in,
	output [WORD_WIDTH-1:0] data_out
);
    // 内部变量声明
    wire [WORD_WIDTH-1:0] temp;
    // 功能实现
    tao_tranform_encdec tao_tranform_encdec_0(
    .clk(clk),
	.rst_n(rst_n),
    .stall(stall),
    .data_in(data_in),
	.data_out(temp));
	
	l_transform_encdec l_transform_encdec_0(
    .clk(clk),
	.rst_n(rst_n),
    .stall(stall),
    .data_in(temp),
	.data_out(data_out));
endmodule