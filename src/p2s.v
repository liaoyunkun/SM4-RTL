///////////////////////////////////////////////////////////////////////////////
// File Name: p2s.v
// Module Name: p2s
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: output the result serially, 8bit package
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5 finish the module
//      + 2020/7/13 modify eop related logic
//      + 2020/7/26 modify the naming of bufin_eop -> bufin_eop
//                  add output signal, done
//                  add output signal, p2s_fifo_almost_full
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"

module p2s
#(
    parameter BLOCK_LENGTH = `BLOCK_LENGTH,
    parameter IO_WIDTH = `IO_WIDTH,
    parameter FIFO_DEPTH = `FIFO_DEPTH,
    parameter ITER_NUM = `DIV128(IO_WIDTH),
    parameter COUNT_WIDTH = `CLOG2(ITER_NUM)
)
(
    input clk,
	input rst_n,
	input result_valid,     // 结果有效
    input stall,        // 暂停
    // 128bit data + 1bit eop
	input [BLOCK_LENGTH-1+1:0] result,      // 结果
    input hold_o,       // 停止输出数据
    output p2s_fifo_almost_full,        // p2s模块内部FIFO容量达到阈值，将满
    output p2s_fifo_full,       // p2s模块内部FIFO已满
    output reg done,        // 数据处理完成
    output[1+1+IO_WIDTH-1:0] d_out      // 输出数据包
);
    // 内部变量声明
    reg bufin_eop;
    reg bufin_val;
    wire [IO_WIDTH-1:0] bufin_dat;
    reg [BLOCK_LENGTH-1:0] result_buf;
    reg eop_buf;
    reg [COUNT_WIDTH-1:0] cnt; 
    wire wr_en;
    wire rd_en;
    wire [1+1+IO_WIDTH-1:0] fifo_in;
    wire p2s_fifo_empty;
    // 功能实现
    assign wr_en = bufin_val && !p2s_fifo_full;
    assign rd_en = ~hold_o && !p2s_fifo_empty;
    // pack the the output data
    assign fifo_in = {bufin_val, bufin_eop, bufin_dat};
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
	        result_buf <= 0;
	    end
        else if(stall) begin
            result_buf <= result_buf;
        end
	    else if(result_valid) begin
	        result_buf <= result[BLOCK_LENGTH:1];
	    end
	    else begin
	        result_buf <= {result_buf, {IO_WIDTH{1'b0}}};
	    end
    end
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            eop_buf <= 0;
        end
        else if(stall) begin
            eop_buf <= eop_buf;
        end
        else if(result_valid) begin
            eop_buf <= result[0];
        end
        else begin
            eop_buf <= eop_buf;
        end
    end   
	
	always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    cnt <= 0;
		end
        else if(stall) begin
            cnt <= cnt;
        end
        else if(result_valid) begin
		    cnt <= cnt + 1;
		end
		else if(cnt == 0 || cnt == ITER_NUM-1) begin
		    cnt <= 0;
		end 
		else begin
		    cnt <= cnt + 1;
		end
	end
    
    always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    bufin_val <= 0;
		end    
        else if(stall) begin
            bufin_val <= bufin_val;
        end
		else if(result_valid || cnt > 4'd0) begin
		    bufin_val <= 1;
		end
		else begin
		    bufin_val <= 0;
		end
	end
	always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    bufin_eop <= 0;
		end
        else if(stall) begin
            bufin_eop <= bufin_eop;
        end
		else if(cnt == ITER_NUM-1 && eop_buf) begin
		    bufin_eop <= 1;
		end
		else begin
		    bufin_eop <= 0;
		end
	end
    assign bufin_dat = result_buf[BLOCK_LENGTH-1: BLOCK_LENGTH-IO_WIDTH];

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            done <= 0;
        end
        else begin
            done <= d_out[1+IO_WIDTH] && d_out[IO_WIDTH];
        end
    end    

    fifo p2s_fifo_0
    ( 
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .fifo_in(fifo_in),
    .fifo_out(d_out),
    .p2s_fifo_empty(p2s_fifo_empty),
    .p2s_fifo_almost_full(p2s_fifo_almost_full),
    .p2s_fifo_full(p2s_fifo_full)
    );
endmodule