// ============================================================================
// Module: pc_counter
// Author: Zhong Litao
// Created: 2025-09-29
// Description: 
// - 
// ============================================================================

`timescale 1ns / 1ps
import my_pkg.sv::*;
module pc_counter
(
    input  wire                         clk        ,
    input  wire                         rst_n      ,
    input  wire [DATA_WIDTH - 1 : 0]    pc_next    ,
    output reg  [DATA_WIDTH - 1 : 0]    pc_current 
);

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc_current <= 'h0000_1000;
    end 
    else begin
        pc_current <= pc_next;
    end
end
endmodule