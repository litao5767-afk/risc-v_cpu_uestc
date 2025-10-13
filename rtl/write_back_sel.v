// ============================================================================
// Module: write_back_sel
// Author: Zhong Litao
// Created: 2025-10-13
// Description: 
// - 
// ============================================================================

`timescale 1ns / 1ps
import my_pkg::*;
module write_back_sel
(
    input  wire                      mem_to_reg         ,
    input  wire [DATA_WIDTH - 1 : 0] data_mem_read      ,
    input  wire [DATA_WIDTH - 1 : 0] data_alu_result    ,
    output wire [DATA_WIDTH - 1 : 0] data_wr_back       
);
    assign data_wr_back = (mem_to_reg == 'b1) ? data_mem_read : data_alu_result;
endmodule