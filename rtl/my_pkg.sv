package my_pkg;
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter MEM_DATA_DEPTH  = 4096;
    parameter MEM_INST_DEPTH  = 4096;

    parameter MEM_LB  = 3'b000;
    parameter MEM_LH  = 3'b001;
    parameter MEM_LW  = 3'b010;
    parameter MEM_LBU = 3'b011;
    parameter MEM_LHU = 3'b100;
    parameter MEM_SB  = 3'b101;
    parameter MEM_SH  = 3'b110;
    parameter MEM_SW  = 3'b111;


endpackage