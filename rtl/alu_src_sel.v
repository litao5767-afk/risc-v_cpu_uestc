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
    // data1 selects between rs1 and pc (pc may be wider than DATA_WIDTH - truncate if needed)
    assign data1 = (alu_src[0] == 1'b0) ? rs1 : pc[DATA_WIDTH-1:0];

    // data2 selects rs2 / imm / constant 4 (constant width should match DATA_WIDTH)
    assign data2 = (alu_src[2 : 1] == 2'b00) ? rs2 :
                   (alu_src[2 : 1] == 2'b01) ? imm :
                   { { (DATA_WIDTH-3){1'b0} }, 3'b100}; // 4
endmodule