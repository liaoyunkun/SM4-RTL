///////////////////////////////////////////////////////////////////////////////
// File Name: s2p.v
// Module Name: s2p
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: buffer the serial 8bit data, and output the full data parallelly
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5  finish the module
//      + 2020/7/13 modify eop related logic
//		+ 2020/7/27 modify err related logic
///////////////////////////////////////////////////////////////////////////////  
`include "./config.vh"
module s2p
#(
    parameter IO_WIDTH = `IO_WIDTH,
    parameter BLOCK_LENGTH = `BLOCK_LENGTH,
    parameter ITER_NUM = `DIV128(IO_WIDTH),
    parameter COUNT_WIDTH = `CLOG2(ITER_NUM)
)
(
    input clk,
	input rst_n,
	input cfg,
	input eop_i,
	input val_i,
	input [IO_WIDTH-1:0]dat_i,
    input stall,
	input keep_data,
	output reg err,
	output reg data_valid,
    // 128bit data + 1bit eop signal
	output reg [BLOCK_LENGTH-1+1:0] data
);
	// 内部变量声明
	wire wr_en;
	reg rd_en;
	reg fake_rd;
	wire [IO_WIDTH-1+1+1:0] fifo_in;
	wire bufout_val;
	wire bufout_eop;
	wire [IO_WIDTH-1:0] bufout_dat;
	wire [IO_WIDTH-1+1+1:0] fifo_out;
	wire p2s_fifo_empty;
	wire p2s_fifo_full;
	reg [COUNT_WIDTH-1:0] cnt;
    wire [BLOCK_LENGTH-1:0] data_debug;

	// 功能实现
    
	assign wr_en = val_i;
	assign fifo_in = {val_i, eop_i, dat_i};
	assign {bufout_val, bufout_eop, bufout_dat} = fifo_out;
	s2p_fifo s2p_fifo_0(
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
	.fake_rd(fake_rd),
    .fifo_in(fifo_in),
    .fifo_out(fifo_out),
    .p2s_fifo_empty(p2s_fifo_empty),
    .p2s_fifo_full(p2s_fifo_full)
	);
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			rd_en <= 0;
		end
		else begin
			rd_en <= 1;
		end
	end
    always@(*) begin
        if(bufout_val && bufout_eop && cnt <= 14) begin
            fake_rd = 1;
        end
        else begin
            fake_rd = 0;
        end
    end
	always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    cnt <= 0;
		end
		else if(stall) begin
			cnt <= cnt;
		end
		else if(bufout_val && cnt == ITER_NUM-1) begin
		    cnt <= 0;
		end
		else if(bufout_val) begin
		    cnt <= cnt + 1;
		end
		else begin
		    cnt <= cnt;
		end
	end
	
	always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    data <= 0;
		end
		else if(stall || keep_data) begin
			data <= data;
		end
		else if(bufout_val) begin
            if(cnt == ITER_NUM-1) begin
                // TODO: if eop_i is high, but cnt != ITER_NUM-1
                // err is set high
                data <= {data, bufout_dat, bufout_eop};
            end
            else begin
                data <= {data, bufout_dat};
            end
		end
		else begin
		    data <= data;
		end
	end
	assign data_debug = data >> 1;
	
	always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    data_valid <= 1'b0;
		end
        else if(stall || keep_data) begin
            data_valid <= data_valid;
        end
		else if(bufout_val && cnt == ITER_NUM-1) begin
            // only last for one cycle
		    data_valid <= 1'b1;
		end
		else begin
		    data_valid <= 1'b0;
		end
	end
	
	always@(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    err <= 1'b0;
		end
		else if(cfg == 1'b1) begin
		    err <= 1'b0;
		end
		else if(bufout_val && bufout_eop && cnt != ITER_NUM-1) begin
            // check the integrity of the data
		    err <= 1'b1;
		end
		else begin
		    err <= err;
		end
	end
endmodule