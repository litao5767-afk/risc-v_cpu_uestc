// ============================================================================
// Module: cpu_top
// Author: Zhong Litao
// Created: 2025-09-25
// Description: 
// top connection
// ============================================================================

`timescale 1ns / 1ps

module cpu_top #(
    parameter DATA_WIDTH = 32
)
(
    input wire         clk      ,
    input wire         rst_n    ,
);
//IMM-Gen
assign immI = {{20{inst[31]}}, inst[31:20]};                              //IMM-OP = 3‘b001
assign immU = {inst[31:12], 12'b0};                                       //IMM-OP = 3‘b010
assign immS = {{20{inst[31]}}, inst[31:25], inst[11:7]};                  //IMM-OP = 3‘b011
assign immB = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};   //IMM-OP = 3‘b100
assign immJ = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; //IMM-OP = 3‘b101

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset logic
    end 
    else begin
        // Sequential logic
    end
end
endmodule