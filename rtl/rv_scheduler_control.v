// ============================================================================
// Module: rv_scheduler_control
// Author: QiShui47
// Created: 2025-10-21
// Description: 
// - scheduler(control flow)
// ============================================================================
import my_pkg::*;
module rv_scheduler_control(
    input  wire [4:0]  rs1E          , // 译码级、执行级、访存级、写回级的源/目的寄存器地址
    input  wire [4:0]  rs2E          ,
    input  wire [4:0]  rdM           ,
    input  wire [4:0]  rdW           ,
    input  wire        reg_writeM    ,
    input  wire        reg_writeW    ,
    input  wire        mem_to_regM   ,
    input  wire        br_taken      , // 分支预测失败
    output reg  [1:0]  forward_rs1E  , // 执行级数据前推控制信号
    output reg  [1:0]  forward_rs2E  ,
    output reg         stallF        , // 取指、译码级暂停信号
    output reg         stallD        ,
    output reg         flushD        , // 译码、执行级冲刷信号
    output reg         flushE
    );
// 端口信号的后缀字母表示其所在的流水线阶段：F-Fetch, D-Decode, E-Execute, M-Memory, W-Writeback

    always@(*)
    begin
        // 默认值
        forward_rs1E = 2'b00;
        forward_rs2E = 2'b00;
        stallF       = 1'b0;
        stallD       = 1'b0;
        flushD       = 1'b0;
        flushE       = 1'b0;

        // --- 数据冒险：为执行阶段（EX）提供数据前推 ---
        // 优先级: MEM -> WB （去除 EX->EX 前推以避免组合环）

        // MEM -> EX forwarding for rs1
        if (reg_writeM && (rdM != 5'b0) && (rdM == rs1E)) begin
            forward_rs1E = 2'b10; // 从访存阶段前推
        end
        // WB -> EX forwarding for rs1
        else if (reg_writeW && (rdW != 5'b0) && (rdW == rs1E)) begin
            forward_rs1E = 2'b01; // 从写回阶段前推
        end

        // MEM -> EX forwarding for rs2
        if (reg_writeM && (rdM != 5'b0) && (rdM == rs2E)) begin
            forward_rs2E = 2'b10; // 从访存阶段前推
        end
        // WB -> EX forwarding for rs2
        else if (reg_writeW && (rdW != 5'b0) && (rdW == rs2E)) begin
            forward_rs2E = 2'b01; // 从写回阶段前推
        end

        // --- 控制冒险和结构冒险 ---
        // 优先级: 分支预测失败 > 加载-使用冒险

        // 控制冒险：分支预测失败
        if (br_taken)
        begin
            flushD = 1'b1; // 冲刷IF/ID流水线寄存器
            flushE = 1'b1; // 冲刷ID/EX流水线寄存器
        end
        // 结构冒险：加载-使用冒险 (Load-Use Hazard)
        // 如果访存阶段是load指令，并且其目标寄存器是译码阶段指令的源寄存器
        else if (mem_to_regM && (rdM != 5'b0) && ((rdM == rs1E) || (rdM == rs2E)))
        begin
            stallF = 1'b1; // 暂停PC和IF/ID寄存器
            stallD = 1'b1;
            flushE = 1'b1; // 将ID/EX寄存器中的指令转换成nop
        end
    end
endmodule