///////////////////////////////////////////////////////////////////////////////
// File Name: l_transform_key.v
// Module Name: l_transform_key
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: L transformation for key expansion
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5 finish the module
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"
module l_transform_key
#(
    parameter WORD_WIDTH = `WORD_WIDTH
)
(
    input clk,
	input rst_n,
    input [WORD_WIDTH-1:0] data_in,
	output reg [WORD_WIDTH-1:0] data_out
);
    // 功能声明
    wire [WORD_WIDTH-1:0] shift_13;
    wire [WORD_WIDTH-1:0] shift_23;
    // 内部变量声明
    // ring shift 
    // <<<13
    assign shift_13 = {data_in[WORD_WIDTH-14:0],data_in[WORD_WIDTH-1:WORD_WIDTH-13]};
    // <<<23
    assign shift_23 = {data_in[WORD_WIDTH-24:0],data_in[WORD_WIDTH-1:WORD_WIDTH-23]};
    // delay one cycle
    always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    data_out <= 0;
        end
	    else begin
		    data_out <= data_in ^ shift_13 ^ shift_23; 
	    end
    end
endmodule