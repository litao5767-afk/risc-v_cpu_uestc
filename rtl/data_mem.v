// ============================================================================
// Module: data_mem
// Author: Zhong Litao
// Created: 2025-09-28
// Description: 
// - data_memory
// ============================================================================

`timescale 1ns / 1ps
import my_pkg::*;
module data_mem
(
    input  wire                              clk        ,
    input  wire                              rst_n      ,
    input  wire                              wr_en      ,
    input  wire                              rd_en      ,
    input  wire [2 : 0]                      mem_op     ,
    input  wire [ADDR_WIDTH - 1 : 0]         addr       ,
    input  wire [DATA_WIDTH - 1 : 0]         data_wr    ,
    output reg  [DATA_WIDTH - 1 : 0]         data_rd    
);

    wire addr_fault = (addr[1 : 0] != 2'b00) ? 'b1 : 'b0;
    reg [7 : 0] mem [0 : MEM_DEPTH - 1];

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_rd <= '0;
        end
        else begin
            if(rd_en && !addr_fault) begin
                case(mem_op)
                    MEM_LB:begin
                        data_rd <= {{24{mem[addr][7]}}, mem[addr]};
                    end
                    MEM_LH:begin
                        data_rd <= {{16{mem[addr + 1][7]}} ,mem[addr + 1], mem[addr]};
                    end
                    MEM_LW:begin
                        data_rd <= {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};
                    end
                    MEM_LBU:begin
                        data_rd <= {24'b0 ,mem[addr]};
                    end
                    MEM_LHU:begin
                        data_rd <= {16'b0 ,mem[addr + 1], mem[addr]};
                    end
                    default:begin
                        data_rd <= 'b0;
                    end
                endcase
            end
        end
    end

    always@(posedge clk or negedge rst_n) begin
        if(wr_en && !addr_fault) begin
            case(mem_op)
                MEM_SB:begin
                    mem[addr + 0] <= data_wr[7 : 0];
                end
                MEM_SH:begin
                    {mem[addr + 1], mem[addr]} <= data_wr[15:0];
                end
                MEM_SW:begin
                    {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]} <= data_wr;
                end
            endcase
        end
    end
endmodule