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
    input  wire [2 : 0]                      mem_op     ,
    input  wire [ADDR_WIDTH - 1 : 0]         addr       ,
    input  wire [DATA_WIDTH - 1 : 0]         data_wr    ,
    output reg  [DATA_WIDTH - 1 : 0]         data_rd    
);
    // word address (memory is organized as 32-bit words)
    wire [ADDR_WIDTH-1:0] addr_w = addr; // keep type
    wire [1:0] byte_offset = addr_w[1:0];
    wire [ADDR_WIDTH-3:0] word_addr = addr_w[ADDR_WIDTH-1:2];

    // memory array (32-bit words)
    reg [31 : 0] mem [0 : MEM_DATA_DEPTH - 1];

    // alignment checks per operation
    wire misalign_load = (mem_op == MEM_LH || mem_op == MEM_LHU) ? (byte_offset[0]) :
                         (mem_op == MEM_LW ? (byte_offset != 2'b00) : 1'b0);
    wire misalign_store = (mem_op == MEM_SH) ? (byte_offset[0]) :
                          (mem_op == MEM_SW ? (byte_offset != 2'b00) : 1'b0);

    // prepare read word and write mask/shift
    reg [31:0] read_word;
    // compute write byte enables and masks
    wire [3:0] we_byte;
    wire [31:0] write_mask;
    wire [31:0] data_wr_shifted;

    // byte enables depending on mem_op and byte_offset
    assign we_byte = (mem_op == MEM_SB) ? (4'b0001 << byte_offset) :
                     (mem_op == MEM_SH) ? ( (byte_offset[1] == 1'b0) ? 4'b0011 << {1'b0, byte_offset[0]} : 4'b0011 << 2 ) :
                     (mem_op == MEM_SW) ? 4'b1111 : 4'b0000;

    assign write_mask = { {8{we_byte[3]}}, {8{we_byte[2]}}, {8{we_byte[1]}}, {8{we_byte[0]}} };
    assign data_wr_shifted = (data_wr << (byte_offset * 8)) & write_mask;

    // combinational read: support write-through when a write to same word occurs in same cycle
    always @(*) begin
        // default
        data_rd = 'b0;

        // read current word from memory
        read_word = mem[word_addr];

        // if write in same cycle to same word, apply write mask to get forwarded word
        if (wr_en && (mem_op == MEM_SB || mem_op == MEM_SH || mem_op == MEM_SW)) begin
            // If write to same word address, forward the written bytes
            // Note: compare word addresses using same slice
            if (word_addr == addr_w[ADDR_WIDTH-1:2]) begin
                read_word = (mem[word_addr] & ~write_mask) | data_wr_shifted;
            end
        end

        // check alignment for loads
        if (misalign_load) begin
            data_rd = 'b0;
        end else begin
            case (mem_op)
                MEM_LB: begin
                    case (byte_offset)
                        2'b00: data_rd = {{24{read_word[7]}},  read_word[7:0]};
                        2'b01: data_rd = {{24{read_word[15]}}, read_word[15:8]};
                        2'b10: data_rd = {{24{read_word[23]}}, read_word[23:16]};
                        2'b11: data_rd = {{24{read_word[31]}}, read_word[31:24]};
                        default: data_rd = 'b0;
                    endcase
                end
                MEM_LBU: begin
                    case (byte_offset)
                        2'b00: data_rd = {24'b0,  read_word[7:0]};
                        2'b01: data_rd = {24'b0,  read_word[15:8]};
                        2'b10: data_rd = {24'b0,  read_word[23:16]};
                        2'b11: data_rd = {24'b0,  read_word[31:24]};
                        default: data_rd = 'b0;
                    endcase
                end
                MEM_LH: begin
                    // halfword aligned at bit[0]==0, select lower or upper half
                    if (byte_offset[1] == 1'b0) begin
                        data_rd = {{16{read_word[15]}}, read_word[15:0]};
                    end else begin
                        data_rd = {{16{read_word[31]}}, read_word[31:16]};
                    end
                end
                MEM_LHU: begin
                    if (byte_offset[1] == 1'b0) begin
                        data_rd = {16'b0, read_word[15:0]};
                    end else begin
                        data_rd = {16'b0, read_word[31:16]};
                    end
                end
                MEM_LW: begin
                    data_rd = read_word;
                end
                default: begin
                    data_rd = 'b0;
                end
            endcase
        end
    end

    // sequential write: synchronous on rising edge only
    always @(posedge clk) begin
        if (wr_en && !misalign_store) begin
            case (mem_op)
                MEM_SB, MEM_SH, MEM_SW: begin
                    // apply byte mask and write shifted data
                    mem[word_addr] <= (mem[word_addr] & ~write_mask) | data_wr_shifted;
                end
                default: begin
                    // no write
                end
            endcase
        end
    end
endmodule