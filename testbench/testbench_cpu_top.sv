module testbench_cpu_top();

`define DUMP;
string dump_file;
initial begin
    `ifdef DUMP
        if($value$plusargs("FSDB=%s",dump_file))
            $display("dump_file = %s",dump_file);
        $fsdbDumpfile(dump_file);        
        $fsdbDumpvars(0, testbench_cpu_top);
        $fsdbDumpMDA();
    `endif

end

parameter vcd_start = 100000;
parameter vcd_hold = 100;
parameter IMEM_INIT_FILE = "testbench/test_compiled_new/rv32ui-p-add.mem"; // 指令存储器的初始化文件路径
initial begin
    `ifdef VCD_ON
        #vcd_start;
        $dumpfile("./vcd_cpu_top.vcd");
        $dumpvars(0,testbench_cpu_top.dut);
        #vcd_hold;
        # 100;
        $fclose("./vcd_cpu_top.vcd");
    `endif
end

parameter t = 100;
parameter rst_time = 5;
parameter rst_time_delete = 10;
parameter finish_time = 1000001;

logic clk  ;
logic rst_n;
cpu_top u_cpu_top(
	.clk  (clk  ),
	.rst_n(rst_n)
);

initial begin   //clock
    clk = 1'b0;
    forever begin
        #(t/2) clk = ~clk;
    end
end

initial begin   //reset
    rst_n = 1'b1;
    #rst_time rst_n = 1'b0;
    #rst_time_delete rst_n = 1'b1;
end

initial begin       //finish
    # finish_time;
    $finish;
end

initial begin
    $readmemh(IMEM_INIT_FILE, u_cpu_top.u_inst_mem.mem);
end
endmodule