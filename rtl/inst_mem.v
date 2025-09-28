// ============================================================================
// Module: inst_mem
// Author: Zhong Litao
// Created: 2025-09-28
// Description: 
// - instruction memory
// ============================================================================

`timescale 1ns / 1ps

module inst_mem #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)
(
    input  wire                             clk    ,
    input  wire                             rst_n  ,
    input  wire [ADDR_WIDTH - 1 : 0]        addr   ,
    output reg  [DATA_WIDTH - 1 : 0]        inst   
);

    reg [DATA_WIDTH - 1 : 0] mem [0 : 1023];

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inst <= '0;
        end
        else begin
            inst <= mem[addr[11 : 2]];
        end
    end
endmodule