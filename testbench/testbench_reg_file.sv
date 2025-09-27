module testbench_reg_file();

`define DUMP;
string dump_file;
initial begin
    `ifdef DUMP
        if($value$plusargs("FSDB=%s",dump_file))
            $display("dump_file = %s",dump_file);
        $fsdbDumpfile(dump_file);        
        $fsdbDumpvars(0, testbench_reg_file);
        $fsdbDumpMDA();
    `endif

end

parameter vcd_start = 100000;
parameter vcd_hold = 100;

initial begin
    `ifdef VCD_ON
        #vcd_start;
        $dumpfile("./vcd_reg_file.vcd");
        $dumpvars(0,testbench_reg_file.dut);
        #vcd_hold;
        # 100;
        $fclose("./vcd_reg_file.vcd");
    `endif
end


parameter t = 100;
parameter rst_time = 5;
parameter rst_time_delete = 10;
parameter finish_time = 1000001;
parameter DATA_WIDTH = 32;
logic clk     ;
logic rst_n   ;
logic wr_en   ;
logic [4 : 0]          addr_wr ;
logic [4 : 0]          addr_rd1;
logic [4 : 0]          addr_rd2;
logic [DATA_WIDTH - 1 : 0] data_wr ;
logic [DATA_WIDTH - 1 : 0] data_rd1;
logic [DATA_WIDTH - 1 : 0] data_rd2;
reg_file dut(
	.clk     (clk     ),
	.rst_n   (rst_n   ),
	.wr_en   (wr_en   ),
	.addr_wr (addr_wr ),
	.addr_rd1(addr_rd1),
	.addr_rd2(addr_rd2),
	.data_wr (data_wr ),
	.data_rd1(data_rd1),
	.data_rd2(data_rd2)
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
    @(posedge rst_n);
    for(int i = 0 ; i <= 31 ; i ++) begin
        dut.r_reg_file[i] = $urandom;
    end
    #100;
    fork
        begin
            repeat(10) begin
                repeat($urandom_range(4, 1)) @(posedge clk);
                addr_rd1 = $urandom;
                addr_rd2 = $urandom;
            end
        end

        begin
            repeat(10) begin
                repeat($urandom_range(3, 1)) @(posedge clk);
                wr_en   = $urandom_range(1, 0);
                addr_wr = $urandom;
                data_wr = $urandom;
            end
        end
    join
    # finish_time;
    $finish;
end

endmodule