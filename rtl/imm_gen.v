// ============================================================================
// Module: imm_gen
// Author: Zhong Litao
// Created: 2025-09-29
// Description: 
// - 
// ============================================================================

`timescale 1ns / 1ps
import my_pkg.sv::*;
module imm_gen
(
    input  wire [DATA_WIDTH - 1 : 0] inst,
    output reg  [DATA_WIDTH - 1 : 0] imm    
);
    wire [6 : 0] opcode = inst[6 : 0];

    always@(*) begin
        case(opcode)
            //I-Type
            'b0010011, 'b0000011, 'b1100111:begin
                imm = {{20{inst[31]}}, inst[31 : 20]};
            end
            //S-Type
            'b0100011:begin
                imm = {{20{inst[31]}}, inst[31 : 25], inst[11 : 7]};
            end
            //B-Type
            'b1100011:begin
                imm = {{19{inst[31]}}, inst[31], inst[7], inst[30 : 25], inst[11 : 8], 1'b0};
            end
            //U-Type
            'b0110111, 'b0010111:begin
                imm = {inst[31 : 12], 12'b0};
            end
            //J-Type
            'b1101111:begin
                imm = {{11{inst[31]}}, inst[31], inst[19 : 12], inst[20], inst[30 : 21], 1'b0};
            end
            default : begin
                imm = 32'b0;
            end
        endcase
    end
endmodule