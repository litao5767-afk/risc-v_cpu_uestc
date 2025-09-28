module testbench_inst_mem();

`define DUMP;
string dump_file;
initial begin
    `ifdef DUMP
        if($value$plusargs("FSDB=%s",dump_file))
            $display("dump_file = %s",dump_file);
        $fsdbDumpfile(dump_file);        
        $fsdbDumpvars(0, testbench_inst_mem);
        $fsdbDumpMDA();
    `endif

end

parameter vcd_start = 100000;
parameter vcd_hold = 100;

initial begin
    `ifdef VCD_ON
        #vcd_start;
        $dumpfile("./vcd_inst_mem.vcd");
        $dumpvars(0,testbench_inst_mem.dut);
        #vcd_hold;
        # 100;
        $fclose("./vcd_inst_mem.vcd");
    `endif
end


parameter t = 100;
parameter rst_time = 5;
parameter rst_time_delete = 10;
parameter finish_time = 1000001;
parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 32;
logic clk  ;
logic rst_n;
logic [DATA_WIDTH - 1 : 0] addr ;
logic [DATA_WIDTH - 1 : 0] inst ;

class addr_class;
    rand logic [11 : 0] addr   ;
    constraint addr_cons{
        addr[1 : 0] == 'b00;
    }
endclass

inst_mem dut(
	.clk  (clk  ),
	.rst_n(rst_n),
	.addr (addr ),
	.inst (inst )
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
    addr_class addr_exp;
    addr_exp = new();
    for(int i = 0 ; i <= 1023 ; i ++) begin     //todo
        dut.mem[i] = $urandom;
    end
    @(posedge rst_n);
    repeat(10) begin
        addr_exp.randomize();
        repeat($urandom_range(5, 1)) @(posedge clk);
        addr  = addr_exp.addr;
    end
    # finish_time;
    $finish;
end

endmodule

