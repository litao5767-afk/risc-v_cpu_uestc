// ============================================================================
// Module: rv_scheduler_control
// Author: QiShui47
// Created: 2025-10-21
// Description: 
// - scheduler(control flow)
// ============================================================================
import my_pkg::*;
module rv_scheduler_control(
    input  wire [4:0]  decode_rs1,decode_rs2,ex_rs1,ex_rs2,wr_back_rd,mem_rd//���뼶��ִ�м���Դ�Ĵ���1,2,д�ؼ���Ŀ��Ĵ���,�洢������Ŀ��Ĵ���
    input  wire [4:0]  opcode,//inst[6:2]���ָ������
    input  wire        mem_to_reg,//��Memд��Reg
    input  wire        reg_write,//��ALUд��Reg
    output reg  [1:0]  forward_ex_rs1,forward_ex_rs2,//�ض��򿪹�
    output reg         stall_fetch,stall_decode,flush_ex//ȡָ�������뼶������ָ�ִ�м������ָ��
    );
always@(*)
begin
    //MEM and WB Forwarding EX
    if(ex_rs1 != 5'b0 && ex_rs1 == mem_rd && mem_to_reg)//���Զ�x0�Ĳ���/alu��ȡ��Դ�Ĵ����ʹ洢���������ļĴ�����ͬ/�洢����Ҫ����
        forward_ex_rs1 = 2'b11;
    else if(ex_rs1 != 5'b0 && ex_rs1 == wr_back_rd && reg_write)//alu��ȡ��Դ�Ĵ�����д�ؼ������ļĴ�����ͬ
        forward_ex_rs1 = 2'b10;
    else
        forward_ex_rs1 = 2'b00;

    if(ex_rs2 != 5'b0 && ex_rs2 == mem_rd && mem_to_reg)
        forward_ex_rs2 = 2'b11;
    else if(ex_rs2 != 5'b0 && ex_rs2 == wr_back_rd && reg_write)
        forward_ex_rs2 = 2'b10;
    else
        forward_ex_rs2 = 2'b00;

    //MEM Stalling DECODE and FETCH
    if(opcode == 5'b00000 && ((mem_rd == decode_rs1) or (mem_rd == decode_rs2)) && mem_to_reg)
    begin
        stall_decode = 1'b1;
        stall_fetch  = 1'b1;
        flush_ex     = 1'b1;
    end
    else
    begin
        stall_decode = 1'b0;
        stall_fetch  = 1'b0;
        flush_ex     = 1'b0;
    end

    //FETCH and EX Refreshing (Wrong prediction)
    if(opcode == 5'b11000)//branch or jump
    begin
        
    end
end
endmodule