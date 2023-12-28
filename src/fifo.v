///////////////////////////////////////////////////////////////////////////////
// File Name: fifo.v
// Module Name: fifo
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: synchronous FIFO
// Change history: 
//      + 2020/6/24 create the module
//      + 2020/7/5  finish the module
//      + 2020/7/26 add output signal, p2s_fifo_almost_full
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"
   
module fifo
#(
    parameter IO_WIDTH = `IO_WIDTH,
    parameter FIFO_DEPTH = `FIFO_DEPTH,
    parameter FIFO_DEPTH_MARGIN = `FIFO_DEPTH_MARGIN,
    parameter DATA_WIDTH = IO_WIDTH + 1 + 1,
    parameter FIFO_WIDTH = `CLOG2(FIFO_DEPTH)
)
( 
    input clk,
    input rst_n,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] fifo_in,
    output reg [DATA_WIDTH-1:0] fifo_out,
    output p2s_fifo_empty,
    output p2s_fifo_almost_full,
    output p2s_fifo_full
);
    // 内部变量声明
	reg [FIFO_WIDTH:0] fifo_cnt;
    
	reg [FIFO_WIDTH-1:0] rd_ptr;
    reg [FIFO_WIDTH-1:0] wr_ptr; 
    
	reg [DATA_WIDTH-1:0] buf_mem [0:FIFO_DEPTH-1];
	
    // 判空判满
	assign p2s_fifo_empty = (fifo_cnt == 0);
	assign p2s_fifo_full  = (fifo_cnt == FIFO_DEPTH);
    // 当FIFO剩余空间大小达到阈值，置高将满信号p2s_fifo_almost_full
    assign p2s_fifo_almost_full = (fifo_cnt >= FIFO_DEPTH - FIFO_DEPTH_MARGIN);
	
    // 功能实现
    // 使用一个计数器记录FIFO中的元素个数
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			fifo_cnt <= 0;
		else if((!p2s_fifo_full && wr_en) && (!p2s_fifo_empty && rd_en))
			fifo_cnt <= fifo_cnt;
		else if(!p2s_fifo_full && wr_en)
			fifo_cnt <= fifo_cnt + 1;
		else if(!p2s_fifo_empty && rd_en)
			fifo_cnt <= fifo_cnt - 1;
		else 
			fifo_cnt <= fifo_cnt;
	end
	
    // read
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			fifo_out <= 0;
        end
		else if(rd_en && !p2s_fifo_empty) begin
			fifo_out <= buf_mem[rd_ptr];
        end
        else begin
            fifo_out <= 0;
        end
	end
	
    // write
	always@(posedge clk) begin
		if(wr_en && !p2s_fifo_full) begin
			buf_mem[wr_ptr] <= fifo_in;
        end
        else begin
            buf_mem[wr_ptr] <= buf_mem[wr_ptr];
        end
	end
    
    // update wr_ptr
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wr_ptr <= 0;
        end
        else if(!p2s_fifo_full && wr_en && wr_ptr == FIFO_DEPTH-1) begin
            wr_ptr <= 0;
        end
        else if(!p2s_fifo_full && wr_en) begin
            wr_ptr <= wr_ptr + 1;
        end
        else begin
            wr_ptr <= wr_ptr;
        end
    end
    
    // update rd_ptr
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rd_ptr <= 0;
        end
        else if(!p2s_fifo_empty && rd_en && rd_ptr == FIFO_DEPTH-1) begin
            rd_ptr <= 0;
        end
        else if(!p2s_fifo_empty && rd_en) begin
            rd_ptr <= rd_ptr + 1;
        end
        else begin
            rd_ptr <= rd_ptr;
        end
    end
	
endmodule 