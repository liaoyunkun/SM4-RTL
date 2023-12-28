///////////////////////////////////////////////////////////////////////////////
// File Name: cofig.vh
// Author: Yunkun Liao
// Email: 1211758834@qq.com
// Project: SM4.0 
// Description: macro definition and parameter definition
// Change history: 
//      + 2020/6/24 create the module
///////////////////////////////////////////////////////////////////////////////
`define CDIV32(x) \
   (x == 1) ? 32 : \
   (x == 2) ? 16 : \
   (x == 3) ? 11 : \
   (x == 4) ? 8 : \
   (x == 5) ? 7 : \
   (x == 6) ? 6 : \
   (x == 7) ? 5 : \
   (x <= 10)? 4 : \
   (x <= 15 )? 3 : \
   (x <= 31)? 2 : 1



`define DIV128(x) \
   (x == 1) ? 128 : \
   (x == 2) ? 64 : \
   (x == 4) ? 32 : \
   (x == 8) ? 16 : \
   (x == 16) ? 8 : \
   (x == 32) ? 4 : \
   (x == 64) ? 2 : \
   (x == 128) ? 1 : -1 


`define CLOG2(x) \
   (x <= 2) ? 1 : \
   (x <= 4) ? 2 : \
   (x <= 8) ? 3 : \
   (x <= 16) ? 4 : \
   (x <= 32) ? 5 : \
   (x <= 64) ? 6 : \
   (x <= 128) ? 7 : \
   (x <= 256) ? 8 : -1

// configurable, data width of I/O
`ifndef IO_WIDTH
`define IO_WIDTH 8 
`endif

// configurable, iteration number of a round_num instance in encdec module
`ifndef ROUND_NUM
`define ROUND_NUM  3
`endif

// configurable, total delay of one iteration of round function
`ifndef ROUND_DELAY
`define ROUND_DELAY  5
`endif

`ifndef ROUND_CNT_WIDTH
`define ROUND_CNT_WIDTH `CLOG2(ROUND_DELAY)
`endif

// configurable, depth of FIFO in p2s module
`ifndef FIFO_DEPTH
`define FIFO_DEPTH  48
`endif

`ifndef FIFO_DEPTH_MARGIN
`define FIFO_DEPTH_MARGIN 16
`endif

// protocol, non-configurable  
`ifndef WORD_WIDTH
`define WORD_WIDTH  32
`endif

// protocol, non-configurable
`ifndef BYTE_WIDTH
`define BYTE_WIDTH 8
`endif

// protocol, non-configurable, length of a data block
`ifndef BLOCK_LENGTH
`define BLOCK_LENGTH 128
`endif

// protocol, non-configurable, length of the key
`ifndef KEY_LENGTH
`define KEY_LENGTH 128
`endif

// non-configurable, pipeline depth of encdec module, 
`ifndef PIPE_DEPTH
`define PIPE_DEPTH `CDIV32(ROUND_NUM)
`endif

// protocol, non-configurable, iteration number of key expansion
`ifndef KEY_EXPAND_NUM
`define KEY_EXPAND_NUM 32
`endif

// non-configurable, address width of RAM for keys
`ifndef ADDR_WIDTH
`define ADDR_WIDTH `CLOG2(KEY_EXPAND_NUM) 
`endif