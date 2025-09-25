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

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset logic
    end 
    else begin
        // Sequential logic
    end
end
endmodule