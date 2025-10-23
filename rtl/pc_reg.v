// ============================================================================
// Module: pc_counter
// Author: Zhong Litao
// Created: 2025-09-29
// Description: 
// - 
// ============================================================================

`timescale 1ns / 1ps
import my_pkg::*;
module pc_reg
(
    input  wire                         clk        ,
    input  wire                         rst_n      ,
    input  wire                         en         ,
    input  wire [ADDR_WIDTH - 1 : 0]    pc_next    ,
    output reg  [ADDR_WIDTH - 1 : 0]    pc_current 
);

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc_current <= {ADDR_WIDTH{1'b0}};
    end 
    else if(en) begin
        pc_current <= pc_next;
    end
end
endmodule