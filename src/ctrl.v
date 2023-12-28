///////////////////////////////////////////////////////////////////////////////
// File Name: ctrl.v
// Module Name: ctrl
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: control module
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5 finish the module
//      + 2020/7/26 debug
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"
module ctrl(
    input clk,      
	input rst_n,        
	input cfg_mod,      // 工作模式，0为加密，1为解密
	input key_0_ready,      // 轮密钥rk0已经可以读取
    input key_ready,        // 全部轮密钥都可以读取
	input data_valid,       // 接收到一个完整的有效数据
    input p2s_fifo_almost_full,     // p2s模块内部FIFO容量达到阈值，将满
    input p2s_fifo_full,        // p2s模块内部FIFO已满
    output reg hold_i,      // 通知上级模块停止发送数据包
	output reg start,       // 通知encdec模块的第一级round_num模块启动加密/解密
    output stall,        // 通知s2p,encdec,p2s模块暂停接受数据和运算
    output keep_data        // 由于hold_i置高后，上游模块仍旧发送少量数据，缓存该数据？
);
    wire key_not_ready;

    always@(*) begin
        if(cfg_mod == 1'b0) begin
            // 加密，顺序使用轮密钥，第一个轮密钥可读取即可启动
            start = (data_valid && key_0_ready)? 1'b1 : 1'b0;
        end
        else begin
            // 解密，逆序使用轮密钥，需要全部密钥均可读取
            start = (data_valid && key_ready)? 1'b1 : 1'b0;
        end
    end

    

    always@(*) begin
        if(cfg_mod == 1'b1 && !key_ready) begin
            // 解密运算迭代需要的轮密钥还未生成
            hold_i = 1'b1;
        end
        else if(p2s_fifo_almost_full) begin
            // p2s模块内部FIFO容量达到阈值，将满时通知上级模块停止发送数据
            hold_i = 1'b1;
        end
        else begin
            hold_i = 1'b0;
        end
    end
    // 只在p2s模块内部FIFO已满的情况下暂停s2p,p2s,encdec模块
    // 置高stall前，hold_i已被置高，即使上级模块仍旧发送少量
    // 数据，由于stall未被置高，s2p,encdec,p2s模块仍可正常工作
    assign stall = p2s_fifo_full;
    assign key_not_ready = (cfg_mod == 1'b1 && !key_ready);
    assign keep_data = data_valid && key_not_ready; 
    
endmodule