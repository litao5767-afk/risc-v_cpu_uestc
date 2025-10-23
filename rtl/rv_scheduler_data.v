// ============================================================================
// Module: rv_scheduler_data
// Author: QiShui47
// Created: 2025-10-23
// Description: 
// - scheduler(data flow)
// ============================================================================
import my_pkg::*;
module rv_scheduler_data(
    input  wire  [DATA_WIDTH - 1:0] alu_src1_data,alu_src2_data,//执行级顺序送入的源操作数1,2
    input  wire  [DATA_WIDTH - 1:0] mem_rd_data,//从数据存储器读出的数据
    input  wire  [DATA_WIDTH - 1:0] data_wr_back,//写回级的数据
    input  wire  [1:0]              forward_ex_rs1,forward_ex_rs2,//重定向开关
    output reg   [DATA_WIDTH - 1:0] ex_rs1_data,ex_rs2_data//执行级实际送入的源操作数1,2
    );
always@(*)
begin
    if(forward_ex_rs1[1])//需要重定向
    begin
        if(forward_ex_rs1[0])//MEM Forwarding EX
            ex_rs1_data = mem_rd_data;
        else//WB Forwarding EX
            ex_rs1_data = data_wr_back;
    end
    else//不需要重定向
        ex_rs1_data = alu_src1_data;
    
    if(forward_ex_rs2[1])//需要重定向
    begin
        if(forward_ex_rs2[0])//MEM Forwarding EX
            ex_rs2_data =  mem_rd_data;
        else//WB Forwarding EX
            ex_rs2_data = data_wr_back;
    end
    else//不需要重定向
        ex_rs2_data = alu_src2_data;
end
endmodule