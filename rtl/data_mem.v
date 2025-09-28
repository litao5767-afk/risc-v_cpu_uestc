// ============================================================================
// Module: data_mem
// Author: Zhong Litao
// Created: 2025-09-28
// Description: 
// - data_memory
// ============================================================================

`timescale 1ns / 1ps

module data_mem #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)
(
    input  wire                              clk        ,
    input  wire                              rst_n      ,
    input  wire                              wr_en      ,
    input  wire [ADDR_WIDTH - 1 : 0]         addr       ,
    input  wire [DATA_WIDTH - 1 : 0]         data_wr    ,
    output reg  [DATA_WIDTH - 1 : 0]         data_rd    
);

    reg [DATA_WIDTH - 1 : 0] mem [0 : 1023];

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_rd <= '0;
        end 
        else begin
            if(wr_en) begin
                mem[addr[11 : 2]] <= data_wr;
            end
            data_rd <= mem[addr[11 : 2]];
        end
    end
endmodule