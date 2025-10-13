// ============================================================================
// Module: alu_src_sel
// Author: Zhong Litao
// Created: 2025-10-13
// Description: 
// - 
// ============================================================================

`timescale 1ns / 1ps
import my_pkg::*;
module alu_src_sel
(
    input  wire [DATA_WIDTH - 1 : 0]         rs1    ,
    input  wire [ADDR_WIDTH - 1 : 0]         pc     ,
    input  wire [DATA_WIDTH - 1 : 0]         rs2    ,
    input  wire [DATA_WIDTH - 1 : 0]         imm    ,
    input  wire [2 : 0]                      alu_src,
    output wire [DATA_WIDTH - 1 : 0]         data1  ,
    output wire [DATA_WIDTH - 1 : 0]         data2  
);

    assign data1 = (alu_src[0] == 'b0) ? rs1 : pc;
    assign data2 = (alu_src[2 : 1] == 'b00) ? rs2 :
                   (alu_src[2 : 1] == 'b01) ? imm :
                   'd4;
endmodule