// ============================================================================
// Module: rv_scheduler_control
// Author: QiShui47
// Created: 2025-10-21
// Description: 
// - scheduler(control flow)
// ============================================================================
import my_pkg::*;
module rv_scheduler_control(
    input  wire [4:0]  rs1D,rs2D,rs1E,rs2E,data_rdM,data_rdW//译码级和执行级的源寄存器1,2,存储器级的目标寄存器,写回级的目标寄存器
    input  wire        mem_to_regM,//存储器级，从Mem写回Reg
    input  wire        reg_writeW,//写回级，从ALU写回Reg
    input  wire        br_taken,//分支预测结果
    output reg  [1:0]  forward_rs1E,forward_rs2E,//执行级重定向开关
    output reg         stallF,stallD,flushD,flushE//取指级和译码级的阻塞指令，译码级和执行级的清除指令
    );
//端口信号名以结尾大写字母表示所处的流水级：F-Fetch, D-Decode, E-Execute, M-Memory, W-Writeback
always@(*)
begin
    //MEM and WB Forwarding EX
    if(rs1E != 5'b0 && rs1E == data_rdM && mem_to_regM)//忽略对x0的操作/alu所取的源寄存器和存储器级读出的寄存器相同/存储器需要读出
        forward_rs1E = 2'b11;
    else if(rs1E != 5'b0 && rs1E == data_rdW && reg_writeW)//alu所取的源寄存器和写回级操作的寄存器相同
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
    else
        flushD = 1'b0;
        flushE = 1'b0;
    end
end
endmodule