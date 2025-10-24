// ============================================================================
// Module: rv_scheduler_data
// Author: QiShui47
// Created: 2025-10-23
// Description: 
// - scheduler(data flow)
// ============================================================================
import my_pkg::*;
module rv_scheduler_data(
    input  wire  [DATA_WIDTH - 1:0] alu_src1_data,   // alu_src_selģ���о����ͳ���Դ������1,2
    input  wire  [DATA_WIDTH - 1:0] alu_src2_data,   // alu_src_selģ���о����ͳ���Դ������1,2
    input  wire  [DATA_WIDTH - 1:0] alu_resultM  ,   // �ӷô漶ǰ�Ƶ�ALU��� (MEM->EX)
    input  wire  [DATA_WIDTH - 1:0] dataW        ,   // д�ؼ������� (WB->EX)
    input  wire  [1:0]              forward_rs1E ,   // �ض��򿪹�
    input  wire  [1:0]              forward_rs2E ,   // �ض��򿪹�
    output reg   [DATA_WIDTH - 1:0] data1E       ,   // ִ�м�ʵ�������Դ������1,2
    output reg   [DATA_WIDTH - 1:0] data2E           // ִ�м�ʵ�������Դ������1,2
    );
always@(*)
begin
    // --- Դ������1������ǰ�� ---
    case (forward_rs1E)
        2'b00: data1E = alu_src1_data; // ��ǰ��
        2'b01: data1E = dataW;        // ��д�ؽ׶�ǰ�� (WB -> EX)
        2'b10: data1E = alu_resultM;  // �ӷô�׶�ǰ�� (MEM -> EX)
        // 2'b11 ԭ�ƻ�Ϊ EX->EX ǰ�ƣ�������뵱ǰ ALU �γ����ӳ���ϻ�������
        default: data1E = alu_src1_data;
    endcase

    // --- Դ������2������ǰ�� ---
    case (forward_rs2E)
        2'b00: data2E = alu_src2_data; // ��ǰ��
        2'b01: data2E = dataW;        // ��д�ؽ׶�ǰ�� (WB -> EX)
        2'b10: data2E = alu_resultM;  // �ӷô�׶�ǰ�� (MEM -> EX)
        // 2'b11 ԭ�ƻ�Ϊ EX->EX ǰ�ƣ�������뵱ǰ ALU �γ����ӳ���ϻ�������
        default: data2E = alu_src2_data;
    endcase
end
endmodule