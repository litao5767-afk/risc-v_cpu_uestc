// ============================================================================
// Module: rv_scheduler
// Author: QiShui47
// Created: 2025-10-21
// Description: 
// - Scheduler
// ============================================================================
import my_pkg::*;
module rv_scheduler(
    input wire [4:0] rsE1,rsE2,wr_back_rd,mem_rd//源寄存器1,2,写回级的目标寄存器,存储器级的目标寄存器
    input wire       mem_to_reg,//从Mem写回Reg
    input wire       reg_write,//从ALU写回Reg
    );
always@(*)
begin
    if(rsE1 != 5'b0 && rsE1 == mem_rd && mem_to_reg)
        ForwardAE = 2'b11;
    else if(rsE1 != 5'b0 && rsE1 == wr_back_rd && reg_write)
        ForwardAE = 2'b10;
    else
        ForwardAE = 2'b00;
end
endmodule