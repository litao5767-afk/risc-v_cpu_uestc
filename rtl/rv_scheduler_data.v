// ============================================================================
// Module: rv_scheduler_data
// Author: QiShui47
// Created: 2025-10-23
// Description: 
// - scheduler(data flow)
// ============================================================================
import my_pkg::*;
module rv_scheduler_data(
    input  wire  [DATA_WIDTH - 1:0] alu_src1_data,alu_src2_data,//alu_src_sel模块判决后送出的源操作数1,2
    input  wire  [DATA_WIDTH - 1:0] mem_rd_dataM,//从数据存储器读出的数据
    input  wire  [DATA_WIDTH - 1:0] dataW,//写回级的数据
    input  wire  [1:0]              forward_rs1E,forward_rs2E,//重定向开关
    output reg   [DATA_WIDTH - 1:0] data1E,data2E//执行级实际送入的源操作数1,2
    );
always@(*)
begin
    if(forward_rs1E[1])//需要重定向
    begin
        if(forward_rs1E[0])//MEM Forwarding EX
            data1E = mem_rd_dataM;
        else//WB Forwarding EX
            data1E = dataW;
    end
    else//不需要重定向
        data1E = alu_src1_data;
    
    if(forward_rs2E[1])//需要重定向
    begin
        if(forward_rs2E[0])//MEM Forwarding EX
            data2E =  mem_rd_dataM;
        else//WB Forwarding EX
            data2E = dataW;
    end
    else//不需要重定向
        data2E = alu_src2_data;
end
endmodule