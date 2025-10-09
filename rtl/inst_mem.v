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

    wire addr_fault = (addr[1 : 0] != 2'b00) ? 'b1 : 'b0;
    reg [7 : 0] mem [0 : MEM_INST_DEPTH - 1];

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inst <= '0;
        end
        else begin
            if(addr_fault) begin
                inst <= 'h0000_0013;    //NOP
            end
            else begin
                inst <= {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr + 0]};
            end
        end
    end
endmodule