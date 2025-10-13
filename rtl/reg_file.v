// ============================================================================
// Module: reg_file
// Author: Zhong Litao
// Created: 2025-09-27
// Description: 
// - 
// ============================================================================

`timescale 1ns / 1ps
import my_pkg::*;
module reg_file
(
    input  wire                          clk        ,
    input  wire                          rst_n      ,
    input  wire                          wr_en      ,
    input  wire [4 : 0]                  addr_wr    ,
    input  wire [4 : 0]                  addr_rd1   ,
    input  wire [4 : 0]                  addr_rd2   ,
    input  wire [DATA_WIDTH - 1 : 0]     data_wr    ,
    output wire [DATA_WIDTH - 1 : 0]     data_rd1   ,
    output wire [DATA_WIDTH - 1 : 0]     data_rd2   
);

/****************************register****************************/
reg [DATA_WIDTH - 1 : 0] r_reg_file [0 : 31]    ;

/****************************comb_assign****************************/
assign data_rd1 = r_reg_file[addr_rd1];
assign data_rd2 = r_reg_file[addr_rd2];

/****************************process****************************/
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(int i = 0 ; i <= 31 ; i ++) begin
            r_reg_file[i] <= '0;
        end
    end 
    else begin
        if((wr_en) && (addr_wr != 'b0)) begin
            r_reg_file[addr_wr] <= data_wr;
        end
    end
end
endmodule