package my_pkg;
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter MEM_DATA_DEPTH  = 4096;
    parameter MEM_INST_DEPTH  = 4096;

    parameter MEM_LB  = 'b000;
    parameter MEM_LH  = 'b001;
    parameter MEM_LW  = 'b010;
    parameter MEM_LBU = 'b011;
    parameter MEM_LHU = 'b100;
    parameter MEM_SB  = 'b101;
    parameter MEM_SH  = 'b110;
    parameter MEM_SW  = 'b111;
endpackage