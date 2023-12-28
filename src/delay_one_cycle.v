///////////////////////////////////////////////////////////////////////////////
// File Name: delay_one_cycle.v
// Module Name: delay_one_cycle
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: generate one cycle delay
// Change history: 
//      + 2020/6/18 create the module
///////////////////////////////////////////////////////////////////////////////
module delay_one_cycle 
#(
    parameter WIDTH = 32		// 寄存器宽度
)
(
    input clk,      
	input rst_n,    
    input stall,		// 暂停，保持数据
	input [WIDTH-1:0] data_in,      
	output reg [WIDTH-1:0] data_out  
);
	// 功能实现
    always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    data_out <= 0;
		end
        else if(stall) begin
            data_out <= data_out;
        end
		else begin
		    data_out <= data_in;
		end
	end
endmodule