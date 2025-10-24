// ============================================================================
// Module: rv_scheduler_control
// Author: QiShui47
// Created: 2025-10-21
// Description: 
// - scheduler(control flow)
// ============================================================================
import my_pkg::*;
module rv_scheduler_control(
    input  wire [4:0]  rs1D,rs2D,rs1E,rs2E,data_rdM,data_rdW//���뼶��ִ�м���Դ�Ĵ���1,2,�洢������Ŀ��Ĵ���,д�ؼ���Ŀ��Ĵ���
    input  wire        mem_to_regM,//�洢��������Memд��Reg
    input  wire        reg_writeW,//д�ؼ�����ALUд��Reg
    input  wire        br_taken,//��֧Ԥ����
    output reg  [1:0]  forward_rs1E,forward_rs2E,//ִ�м��ض��򿪹�
    output reg         stallF,stallD,flushD,flushE//ȡָ�������뼶������ָ����뼶��ִ�м������ָ��
    );
//�˿��ź����Խ�β��д��ĸ��ʾ��������ˮ����F-Fetch, D-Decode, E-Execute, M-Memory, W-Writeback
always@(*)
begin
    //MEM and WB Forwarding EX
    if(rs1E != 5'b0 && rs1E == data_rdM && mem_to_regM)//���Զ�x0�Ĳ���/alu��ȡ��Դ�Ĵ����ʹ洢���������ļĴ�����ͬ/�洢����Ҫ����
        forward_rs1E = 2'b11;
    else if(rs1E != 5'b0 && rs1E == data_rdW && reg_writeW)//alu��ȡ��Դ�Ĵ�����д�ؼ������ļĴ�����ͬ
        forward_rs1E = 2'b10;
    else
        forward_rs1E = 2'b00;

    if(rs2E != 5'b0 && rs2E == data_rdM && mem_to_regM)
        forward_rs2E = 2'b11;
    else if(rs2E != 5'b0 && rs2E == data_rdW && reg_writeW)
        forward_rs2E = 2'b10;
    else
        forward_rs2E = 2'b00;

    //MEM Stalling DECODE and FETCH (read after load)
    if(( (data_rdM == rs1D) or (data_rdM == rs2D) ) && mem_to_regM)
    begin
        stallF = 1'b1;
        stallD = 1'b1;
        flushE = 1'b1;
    end
    else
    begin
        stallF = 1'b0;
        stallD = 1'b0;
        flushE = 1'b0;
    end

    //FETCH and EX Refreshing (wrong prediction)
    if(br_taken)
    begin
        flushD = 1'b1;
        flushE = 1'b1;
    end
    else begin
        flushD = 1'b0;
        flushE = 1'b0;
    end
end
endmodule