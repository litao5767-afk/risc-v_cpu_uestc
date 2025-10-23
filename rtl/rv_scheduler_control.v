// ============================================================================
// Module: rv_scheduler_control
// Author: QiShui47
// Created: 2025-10-21
// Description: 
// - scheduler(control flow)
// ============================================================================
import my_pkg::*;
module rv_scheduler_control(
    input  wire [4:0]  decode_rs1,decode_rs2,ex_rs1,ex_rs2,wr_back_rd,mem_rd//译码级和执行级的源寄存器1,2,写回级的目标寄存器,存储器级的目标寄存器
    input  wire [4:0]  opcode,//inst[6:2]检测指令类型
    input  wire        mem_to_reg,//从Mem写回Reg
    input  wire        reg_write,//从ALU写回Reg
    output reg  [1:0]  forward_ex_rs1,forward_ex_rs2,//重定向开关
    output reg         stall_fetch,stall_decode,flush_ex//取指级和译码级的阻塞指令，执行级的清除指令
    );
always@(*)
begin
    //MEM and WB Forwarding EX
    if(ex_rs1 != 5'b0 && ex_rs1 == mem_rd && mem_to_reg)//忽略对x0的操作/alu所取的源寄存器和存储器级读出的寄存器相同/存储器需要读出
        forward_ex_rs1 = 2'b11;
    else if(ex_rs1 != 5'b0 && ex_rs1 == wr_back_rd && reg_write)//alu所取的源寄存器和写回级操作的寄存器相同
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