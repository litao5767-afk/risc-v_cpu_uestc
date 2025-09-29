// ============================================================================
// Module: imm_gen
// Author: Zhong Litao
// Created: 2025-09-29
// Description: 
// - 
// ============================================================================

`timescale 1ns / 1ps

module imm_gen #(
    parameter DATA_WIDTH = 32
)
(
    input  wire         clk    ,
    input  wire         rst_n  ,
    output wire         data   ,
);

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset logic
    end 
    else begin
        // Sequential logic
    end
end
endmodule