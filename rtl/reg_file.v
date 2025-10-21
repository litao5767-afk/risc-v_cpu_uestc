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

reg [DATA_WIDTH - 1 : 0] r_reg_file [0 : 31]    ;

// read ports (simple read-first behavior). Removed combinational write-forwarding
// to prevent potential zero-delay combinational loops where write data depends
// on read data in the same cycle.
assign data_rd1 = (addr_rd1 != 5'b0) ? r_reg_file[addr_rd1] : {DATA_WIDTH{1'b0}};

assign data_rd2 = (addr_rd2 != 5'b0) ? r_reg_file[addr_rd2] : {DATA_WIDTH{1'b0}};

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