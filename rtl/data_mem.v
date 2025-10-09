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

    //对应mem大小2^(ADDR_WIDTH-2)Bytes
    reg [7 : 0] mem [0 : 2**ADDR_WIDTH - 1];

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_rd <= '0;
        end 
        else begin
            if(rd_en) begin
                case(mem_op)
                    MEM_LB:begin
                        data_rd <= {{24{mem[addr][7]}}, mem[addr]};
                    end
                    MEM_LH:begin
                        data_rd <= {{16{mem[addr + 1][15]}} ,mem[addr + 1], mem[addr]};
                    end
                    MEM_LW:begin
                        data_rd <= mem[addr];
                    end
                    MEM_LBU:begin
                        data_rd <= {{24{1'b0}} ,mem[addr]};
                    end
                    MEM_LHU:begin
                        data_rd <= {{16{1'b0}} ,mem[addr + 1], mem[addr]};
                    end
                    default:begin
                        data_rd <= 'b0;
                    end
                endcase
            end
        end
    end

    always@(posedge clk or negedge rst_n) begin
        if(wr_en) begin
            case(mem_op)
                MEM_SB:begin
                    mem[addr + 0] <= data_wr[7 : 0];
                end
                MEM_SH:begin
                    mem[addr + 0] <= data_wr[7 : 0];
                    mem[addr + 1] <= data_wr[15 : 8];
                end
                MEM_SW:begin
                    mem[addr + 0] <= data_wr[7 : 0];
                    mem[addr + 1] <= data_wr[15 : 8];
                    mem[addr + 2] <= data_wr[23 : 16];
                    mem[addr + 3] <= data_wr[31 : 24];
                end
            endcase
        end
    end
endmodule