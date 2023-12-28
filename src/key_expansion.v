///////////////////////////////////////////////////////////////////////////////
// File Name: key_expansion.v
// Module Name: key_expansion
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: key expansion and buffer the generated keys
// Change history: 
//      + 2020/6/18 create the module
//      + 2020/7/5 finish the module
//      + 2020/7/26 add stall to the read process of keys
///////////////////////////////////////////////////////////////////////////////
`include "./config.vh"
   
module key_expansion
#(
    parameter ROUND_NUM = `ROUND_NUM,
    parameter PIPE_DEPTH = `PIPE_DEPTH,
    parameter ROUND_DELAY = `ROUND_DELAY,
    parameter WORD_WIDTH = `WORD_WIDTH,
    parameter KEY_LENGTH = `KEY_LENGTH,
    parameter KEY_EXPAND_NUM = `KEY_EXPAND_NUM,
    parameter ROUND_CNT_WIDTH = `ROUND_CNT_WIDTH,    
    parameter ADDR_WIDTH = `ADDR_WIDTH
)
(
   input clk,
   input rst_n,
   input cfg,
   input stall,
   input [WORD_WIDTH-1:0] cfg_mk0,      // 密钥MK0~MK3
   input [WORD_WIDTH-1:0] cfg_mk1,
   input [WORD_WIDTH-1:0] cfg_mk2,
   input [WORD_WIDTH-1:0] cfg_mk3,
   input [ADDR_WIDTH*PIPE_DEPTH-1:0] rk_addr,       // 读轮密钥的地址索引
   output reg key_0_ready,      // 轮密钥rk0已经可以读取
   output reg key_ready,        // 全部轮密钥都可以读取
   output [WORD_WIDTH*PIPE_DEPTH-1:0] rk        // 读取的轮密钥
);

    // 内部参数声明
    // state definition
    // one-hot Encoding
    parameter IDLE = 2'b01;
    parameter KEY_GENERATION = 2'b10;
    
    // systematic parameters
    parameter FK_0 = 32'ha3b1bac6;
    parameter FK_1 = 32'h56aa3350;
    parameter FK_2 = 32'h677d9197;
    parameter FK_3 = 32'hb27022dc;
    // 内部变量声明
    reg [1:0] state;
    reg [1:0] next_state;

    // counter for one iteration of round function
    reg [ROUND_CNT_WIDTH-1:0] round_cnt;
    // counter for the 32 iterations of key expansion
    reg [ADDR_WIDTH-1:0] iter_cnt;
    reg [KEY_LENGTH-1:0] key_buffer;  
    wire [ADDR_WIDTH-1:0] index;
    wire [WORD_WIDTH-1:0] ck;
    wire [WORD_WIDTH-1:0] k_0_in;
    wire [WORD_WIDTH-1:0] k_1_in;
    wire [WORD_WIDTH-1:0] k_2_in;
    wire [WORD_WIDTH-1:0] k_3_in;
    wire [WORD_WIDTH-1:0] w_key;
    reg [ADDR_WIDTH-1:0] w_addr;
    reg w_en;

    assign {k_0_in, k_1_in, k_2_in, k_3_in} = key_buffer;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            key_buffer <= 0;
        end
        else if(cfg == 1'b1) begin
            // initial four words
            key_buffer <= {cfg_mk0 ^ FK_0, cfg_mk1 ^ FK_1, 
                            cfg_mk2 ^ FK_2, cfg_mk3 ^ FK_3};			 
        end
        else if(state == KEY_GENERATION && round_cnt == ROUND_DELAY - 1) begin
            key_buffer <= {key_buffer, w_key};
        end
        else begin
            key_buffer <= key_buffer;
        end
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always@(*) begin
        next_state = IDLE;
        case(state)
            IDLE: begin
                if(cfg == 1) begin
                    // load keys
                    next_state = KEY_GENERATION;
                end
                else begin
                    next_state = IDLE;
                end
            end
            KEY_GENERATION: begin
                if(round_cnt == ROUND_DELAY -1 && iter_cnt == KEY_EXPAND_NUM - 1) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = KEY_GENERATION;
                end
            end
        endcase
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            round_cnt <= 0;
        end
        else if(state == KEY_GENERATION) begin
            if(round_cnt == ROUND_DELAY - 1) begin
                round_cnt <= 0;
            end
            else begin
                round_cnt <= round_cnt + 1;
            end
        end
        else begin
            round_cnt <= 0;
        end
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            iter_cnt <= 0;
        end
        else if(round_cnt == ROUND_DELAY - 1) begin
            if(iter_cnt == KEY_EXPAND_NUM -1) begin
                iter_cnt <= 0;
            end
            else begin
                iter_cnt <= iter_cnt + 1;
            end
        end
        else begin
            iter_cnt <= iter_cnt;
        end
    end

    // index of ck parameter
    assign index = (state == KEY_GENERATION)? iter_cnt + 1 : 5'd0;
    
    get_cki get_cki_0(
        .clk(clk),
        .index(index),
        .cki_out(ck)
    );

    // delay four cycle
    round_func_key round_func_key_0(
        .clk(clk),
        .rst_n(rst_n),
        .ck(ck),
        .k_0_in(k_0_in),
        .k_1_in(k_1_in),
        .k_2_in(k_2_in),
        .k_3_in(k_3_in),
        .k_4_out(w_key)
    );

    reg key_ready_buf;
    // generate the output signal
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            key_ready_buf <= 1'b0;
        end
        else if(state == IDLE && next_state == KEY_GENERATION) begin
            // regenerate the keys, reset key_ready
            key_ready_buf <= 1'b0;
        end
        else if(state == KEY_GENERATION && next_state == IDLE) begin
            key_ready_buf <= 1'b1;
        end
        else begin
            key_ready_buf <= key_ready_buf;
        end
    end
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            key_ready <= 1'b0;
        end
        else begin
            key_ready <= key_ready_buf;
        end
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            key_0_ready <= 1'b0;
        end
        else if(state == IDLE && next_state == KEY_GENERATION) begin
            key_0_ready <= 1'b0;
        end
        else if(state == KEY_GENERATION && iter_cnt >= 1) begin
            key_0_ready <= 1'b1;
        end 	
        else begin
            key_0_ready <= key_0_ready;
        end
    end

    // w_en should synchronize with valid k_4_out
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            w_en <= 1'd0;
        end
        else if(state == KEY_GENERATION && round_cnt == ROUND_DELAY - 2) begin
            w_en <= 1'd1;
        end
        else begin
            w_en <= 1'd0;
        end
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            w_addr <= 0;
        end
        else if(round_cnt == ROUND_DELAY - 1) begin
            w_addr <= w_addr + 1;
        end
        else begin
            w_addr <= w_addr;
        end
    end
    
    // keys buffer
    keys_buf keys_buf_0(
    .clk(clk),
    .stall(stall),
	.w_en(w_en),
	.w_addr(w_addr),
    .r_addr(rk_addr),
	.data_in(w_key),
	.data_out(rk)
    );

endmodule