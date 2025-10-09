// ============================================================================
// Module: inst_mem
// Author: Zhong Litao
// Created: 2025-09-28
// Description: 
// - instruction memory
// ============================================================================

`timescale 1ns / 1ps
import my_pkg.sv::*;
module inst_mem
(
    input  wire                             clk    ,
    input  wire                             rst_n  ,
    input  wire [ADDR_WIDTH - 1 : 0]        addr   ,
    output reg  [DATA_WIDTH - 1 : 0]        inst   
);

    reg [7 : 0] mem [0 : 2**ADDR_WIDTH - 1];

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inst <= '0;
        end
        else begin
            inst[7 : 0]   <= mem[addr + 0];
            inst[15 : 8]  <= mem[addr + 1];
            inst[23 : 16] <= mem[addr + 2];
            inst[31 : 24] <= mem[addr + 3];
        end
    end
endmodule