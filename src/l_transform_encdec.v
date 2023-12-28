///////////////////////////////////////////////////////////////////////////////
// File Name: l_transform_encdec.v
// Module Name: l_transform_encdec
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: L transformation for encode/decode
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5 finish the module
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"
module l_transform_encdec
#(
    parameter WORD_WIDTH = `WORD_WIDTH
)
(
    input clk,
	input rst_n,
    input stall,
    input [WORD_WIDTH-1:0] data_in,
	output reg [WORD_WIDTH-1:0] data_out
);
    // 内部变量声明
    // delay one cycle
    wire [WORD_WIDTH-1:0] shift_2;
    wire [WORD_WIDTH-1:0] shift_10;
    wire [WORD_WIDTH-1:0] shift_18;
    wire [WORD_WIDTH-1:0] shift_24;
    // 功能实现
    // ring shift
    // <<<2
    assign shift_2 = {data_in[WORD_WIDTH-3:0],data_in[WORD_WIDTH-1:WORD_WIDTH-2]};
    // <<<10
    assign shift_10 = {data_in[WORD_WIDTH-11:0],data_in[WORD_WIDTH-1:WORD_WIDTH-10]};
    // <<<18
    assign shift_18 = {data_in[WORD_WIDTH-19:0],data_in[WORD_WIDTH-1:WORD_WIDTH-18]};
    // <<<24
    assign shift_24 = {data_in[WORD_WIDTH-25:0],data_in[WORD_WIDTH-1:WORD_WIDTH-24]};
    
    always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    data_out <= 0;
		end
        else if(stall == 1'b1) begin
            data_out <= data_out;
        end
		else begin
		    data_out <= data_in ^ shift_2 ^ shift_10 ^ shift_18 ^ shift_24; 
		end
	end
endmodule