// ============================================================================
// Module: rv_scheduler_data
// Author: QiShui47
// Created: 2025-10-23
// Description: 
// - scheduler(data flow)
// ============================================================================
import my_pkg::*;
module rv_scheduler_data(
    input  wire  [DATA_WIDTH - 1:0] alu_src1_data,alu_src2_data,//alu_src_selģ���о����ͳ���Դ������1,2
    input  wire  [DATA_WIDTH - 1:0] mem_rd_dataM,//�����ݴ洢������������
    input  wire  [DATA_WIDTH - 1:0] dataW,//д�ؼ�������
    input  wire  [1:0]              forward_rs1E,forward_rs2E,//�ض��򿪹�
    output reg   [DATA_WIDTH - 1:0] data1E,data2E//ִ�м�ʵ�������Դ������1,2
    );
always@(*)
begin
    if(forward_rs1E[1])//��Ҫ�ض���
    begin
        if(forward_rs1E[0])//MEM Forwarding EX
            data1E = mem_rd_dataM;
        else//WB Forwarding EX
            data1E = dataW;
    end
    else//����Ҫ�ض���
        data1E = alu_src1_data;
    
    if(forward_rs2E[1])//��Ҫ�ض���
    begin
        if(forward_rs2E[0])//MEM Forwarding EX
            data2E =  mem_rd_dataM;
        else//WB Forwarding EX
            data2E = dataW;
    end
    else//����Ҫ�ض���
        data2E = alu_src2_data;
end
endmodule