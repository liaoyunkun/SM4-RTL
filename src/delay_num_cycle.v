///////////////////////////////////////////////////////////////////////////////
// File Name: delay_num_cycle.v
// Module Name: delay_num_cycle
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: generate specified number delay
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5  finish the module
//      + 2023/7/23 debug
///////////////////////////////////////////////////////////////////////////////
module delay_num_cycle
#(
    parameter WORD_WIDTH = 32,      // 寄存器宽度
    parameter NUM = 1,      // 寄存器数量
    parameter TOTAL_WIDTH = WORD_WIDTH * NUM
)
(
    input clk,
    input rst_n,
    input stall,        // 暂停，保持数据
    input [WORD_WIDTH-1:0] data_in,
    output [WORD_WIDTH-1:0] data_out
);
    // 内部变量声明
    wire [WORD_WIDTH-1:0] pipe [0:NUM];
    assign pipe[0] = data_in;
    assign data_out = pipe[NUM];
    // 功能实现
    genvar i;
    generate 
        for(i = 0; i < NUM; i = i+1) begin: DELAY
            delay_one_cycle 
            #(.WIDTH(WORD_WIDTH)
            )
            instance_0
            (
                .clk(clk),
                .rst_n(rst_n),
                .stall(stall),
                .data_in(pipe[i]),
                .data_out(pipe[i+1])
            );
        end
    endgenerate
endmodule