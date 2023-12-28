///////////////////////////////////////////////////////////////////////////////
// File Name: sm4_top.v
// Module Name: sm4_top
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: top module of SM4.0 project
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5 finish the module
//      + 2020/7/13 modify eop related logic
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"  
module sm4_top
#(
    parameter KEY_EXPAND_NUM = `KEY_EXPAND_NUM,
    parameter ROUND_NUM = `ROUND_NUM,
    parameter WORD_WIDTH = `WORD_WIDTH,
    parameter IO_WIDTH = `IO_WIDTH,
    parameter BLOCK_LENGTH = `BLOCK_LENGTH,
    parameter ADDR_WIDTH = `ADDR_WIDTH,
    parameter PIPE_DEPTH = `PIPE_DEPTH
)
(
    input clk,
    input rst_n,
    input cfg,
	input cfg_mod,
	input [WORD_WIDTH-1:0] cfg_mk0,
	input [WORD_WIDTH-1:0] cfg_mk1,
	input [WORD_WIDTH-1:0] cfg_mk2,
	input [WORD_WIDTH-1:0] cfg_mk3,
	input hold_o,
	input eop_i,
	input val_i,
	input [IO_WIDTH-1:0] dat_i,
	
	output done,
	output err,
	output hold_i,
	output eop_o,
	output val_o,
	output [IO_WIDTH-1:0] dat_o
);
    // 内部变量声明
    wire stall;
    wire key_ready;
    wire key_0_ready;
    wire data_valid;
    wire start;
    wire keep_data;
    wire p2s_fifo_almost_full;
    wire p2s_fifo_full;
    wire result_valid;
    // 128bit data + 1bit eop
    wire [BLOCK_LENGTH-1+1:0] data;
    wire w_en;
    wire [ADDR_WIDTH-1:0] w_addr;
    wire [WORD_WIDTH-1:0] w_key;
    // 128bit data + 1bit eop
    wire [BLOCK_LENGTH-1+1:0] result;
    wire [ADDR_WIDTH*PIPE_DEPTH-1:0] rk_addr;
    wire [WORD_WIDTH*PIPE_DEPTH-1:0] rk;
    wire [1+1+IO_WIDTH-1:0] d_out;
    
    // 功能实现
    // when hold_i is high, stop s2p/encdec/p2s module
    // wait the keys or the lower modules start receiving
    // data
    assign {val_o, eop_o, dat_o} = d_out;
    
    ctrl ctrl_0(
    .clk(clk),
    .rst_n(rst_n),
    .cfg_mod(cfg_mod),
    .key_ready(key_ready),
    .key_0_ready(key_0_ready),
    .data_valid(data_valid),
    .p2s_fifo_almost_full(p2s_fifo_almost_full),
    .p2s_fifo_full(p2s_fifo_full),
    .hold_i(hold_i),
    .start(start),
    .stall(stall),
    .keep_data(keep_data)
    );
    
    s2p s2p_0(
    .clk(clk),
	.rst_n(rst_n),
    .cfg(cfg),
	.eop_i(eop_i),
	.val_i(val_i),
	.dat_i(dat_i),
	.err(err),
    .stall(stall),
    .keep_data(keep_data),
	.data_valid(data_valid),
	.data(data)
    );


    key_expansion key_expansion_0(
    .clk(clk),
    .rst_n(rst_n),
    .stall(stall),
    .cfg(cfg),
    .cfg_mk0(cfg_mk0),
    .cfg_mk1(cfg_mk1),
    .cfg_mk2(cfg_mk2),
    .cfg_mk3(cfg_mk3),
    .rk_addr(rk_addr),
    .key_0_ready(key_0_ready),
    .key_ready(key_ready),
    .rk(rk)
    );

    encdec encdec_0(
        .clk(clk),
        .rst_n(rst_n ),
        .cfg_mod(cfg_mod),
        .start(start),
        .data_valid(data_valid),
        .stall(stall),
        .data(data),
        .rk(rk),
        .result_valid(result_valid),
        .rk_addr(rk_addr),
        .result(result)
    );

    p2s p2s_0(
    .clk(clk),
	.rst_n(rst_n),
	.result_valid(result_valid),
    .stall(stall),
	.result(result),
    .hold_o(hold_o),
    .p2s_fifo_almost_full(p2s_fifo_almost_full),
    .p2s_fifo_full(p2s_fifo_full),
    .done(done),
    .d_out(d_out)
    );
endmodule