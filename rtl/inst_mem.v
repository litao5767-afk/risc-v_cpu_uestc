// ============================================================================
// Module: inst_mem
// Author: Zhong Litao
// Created: 2025-09-28
// Description: 
// - instruction memory
// ============================================================================

`timescale 1ns / 1ps
import my_pkg::*;
module inst_mem
(
    input  wire                             clk    ,
    input  wire                             rst_n  ,
    input  wire [ADDR_WIDTH - 1 : 0]        addr   ,
    output wire [DATA_WIDTH - 1 : 0]        inst   
);

    // word address (memory is organized as 32-bit words)
    wire [1 : 0] byte_offset = addr[1 : 0];
    wire [ADDR_WIDTH - 3 : 0] word_addr = addr[ADDR_WIDTH - 1 : 2];

    wire addr_fault = (byte_offset != 2'b00);
    reg [31 : 0] mem [0 : MEM_INST_DEPTH - 1];

    // If address is fault or word_addr out of range, return 0
    assign inst = (!addr_fault && (word_addr < MEM_INST_DEPTH)) ? mem[word_addr] : {DATA_WIDTH{1'b0}};
endmodule