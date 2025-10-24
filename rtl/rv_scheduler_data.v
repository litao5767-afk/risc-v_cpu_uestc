// ============================================================================
// Module: rv_scheduler_data
// Author: QiShui47
// Created: 2025-10-23
// Description: 
// - scheduler(data flow)
// ============================================================================
import my_pkg::*;
module rv_scheduler_data(
    input  wire  [DATA_WIDTH - 1:0] alu_src1_data,   // alu_src_sel模块判决后送出的源操作数1,2
    input  wire  [DATA_WIDTH - 1:0] alu_src2_data,   // alu_src_sel模块判决后送出的源操作数1,2
    input  wire  [DATA_WIDTH - 1:0] alu_resultM  ,   // 从访存级前推的ALU结果 (MEM->EX)
    input  wire  [DATA_WIDTH - 1:0] dataW        ,   // 写回级的数据 (WB->EX)
    input  wire  [1:0]              forward_rs1E ,   // 重定向开关
    input  wire  [1:0]              forward_rs2E ,   // 重定向开关
    output reg   [DATA_WIDTH - 1:0] data1E       ,   // 执行级实际送入的源操作数1,2
    output reg   [DATA_WIDTH - 1:0] data2E           // 执行级实际送入的源操作数1,2
    );
always@(*)
begin
    // --- 源操作数1的数据前推 ---
    case (forward_rs1E)
        2'b00: data1E = alu_src1_data; // 无前推
        2'b01: data1E = dataW;        // 从写回阶段前推 (WB -> EX)
        2'b10: data1E = alu_resultM;  // 从访存阶段前推 (MEM -> EX)
        // 2'b11 原计划为 EX->EX 前推，但这会与当前 ALU 形成零延迟组合环，禁用
        default: data1E = alu_src1_data;
    endcase

    // --- 源操作数2的数据前推 ---
    case (forward_rs2E)
        2'b00: data2E = alu_src2_data; // 无前推
        2'b01: data2E = dataW;        // 从写回阶段前推 (WB -> EX)
        2'b10: data2E = alu_resultM;  // 从访存阶段前推 (MEM -> EX)
        // 2'b11 原计划为 EX->EX 前推，但这会与当前 ALU 形成零延迟组合环，禁用
        default: data2E = alu_src2_data;
    endcase
end
endmodule