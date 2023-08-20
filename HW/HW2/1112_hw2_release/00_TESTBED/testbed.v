`timescale 1ns/100ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   120000
`ifdef p0
    `define Inst "../00_TESTBED/PATTERN/p0/inst.dat"
	`define Ans  "../00_TESTBED/PATTERN/p0/data.dat"
	`define Data "../00_TESTBED/PATTERN/p0/data_zero.dat"
	`define Status "../00_TESTBED/PATTERN/p0/status.dat"
`endif
`ifdef p1
    `define Inst "../00_TESTBED/PATTERN/p1/inst.dat"
	`define Ans "../00_TESTBED/PATTERN/p1/data.dat"
	`define Data "../00_TESTBED/PATTERN/p1/data_zero.dat"
	`define Status "../00_TESTBED/PATTERN/p1/status.dat"
`endif
module testbed;

	reg clk = 0;
	reg rst_n ;
	reg  [31:0 ] ans [0:63];
	reg  [1:0] mem_status_ans [0:80];
	reg  [1:0] mem_status ;
	wire [ 31 : 0 ] imem_addr;
	wire [ 31 : 0 ] imem_inst;
	wire            dmem_we;
	wire [ 31 : 0 ] dmem_addr;
	wire [ 31 : 0 ] dmem_wdata;
	wire [ 31 : 0 ] dmem_rdata;
	wire [  1 : 0 ] mips_status;
	wire            mips_status_valid;
	integer error_num,status_error_num;
	integer i;
	integer j=0;
	core u_core (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.o_i_addr(imem_addr),
		.i_i_inst(imem_inst),
		.o_d_we(dmem_we),
		.o_d_addr(dmem_addr),
		.o_d_wdata(dmem_wdata),
		.i_d_rdata(dmem_rdata),
		.o_status(mips_status),
		.o_status_valid(mips_status_valid)
	);

	inst_mem  u_inst_mem (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_addr(imem_addr),
		.o_inst(imem_inst)
	);

	data_mem  u_data_mem (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_we(dmem_we),
		.i_addr(dmem_addr),
		.i_wdata(dmem_wdata),
		.o_rdata(dmem_rdata)
	);
	
    always #(`CYCLE/2.0) clk = ~clk;
	
	initial begin
		$readmemb (`Inst, u_inst_mem.mem_r);
		$readmemb (`Data, u_data_mem.mem_r);
		$readmemb (`Ans, ans);
		$readmemb (`Status, mem_status_ans);
    	$fsdbDumpfile("core.fsdb");
    	$fsdbDumpvars(0, testbed, "+mda");
		clk = 0;
		rst_n = 1;
		#(`CYCLE*0.5) rst_n = 1'b0;
    	#(`CYCLE*2.0) rst_n = 1'b1;
    end
	always @(negedge clk)
	begin
		if(mips_status_valid)
            begin
                if (mem_status_ans[j] !== mips_status)
                begin
                    if (status_error_num == 0)
                        $display("Error!");
                    status_error_num = status_error_num + 1;
                    $display("wrong:#%d  Correct ans: %2d  Your ans: %2d", j, mem_status_ans[j], mips_status);
                end
                else $display("#%d  Correct ans: %2d  Your ans: %2d", j, mem_status_ans[j], mips_status);
				j=j+1;
				if(mips_status == 2'd3||mips_status==2'd2) $display("total error: %2d", status_error_num);
            end
	
    	if (mips_status == 2'd3||mips_status==2'd2) //eof
    	begin
        	error_num = 0;
        	for (i=0; i<64; i=i+1)
        	begin
            	if (u_data_mem.mem_r[i] !== ans[i])
            	begin
            	    if (error_num == 0)
            	        $display("Error!");
            	    error_num = error_num + 1;
            	    $display("  Addr = 0x%8h  Correct ans: 0x%8h  Your ans: 0x%8h", dmem_addr[i], ans[i], u_data_mem.mem_r[i]);
            	end
        	end
			
        	if (error_num > 0)
        	begin
            $display(" ");
            $display("******************************           /\\__^__/\\    ");
            $display("*      ***         ***       *         //  _   _  \\\\  ");
            $display("*    **   **     **   **     *        <      W      >   ");
            $display("*   *   *   *   *   *   *    *     A+  \\           /  F");
            $display("*    **   **     **   **     *       \\ / `---Q---` \\ /");
            $display("*      ***  *      ***  *    *        /             \\  ");
            $display("******************************        \\   ^     ^   /  ");
            $display("There are total %4d errors in the data memory\n", error_num);
        	end
        	else
        	begin
            $display(" ");
            $display("******************************                          ");
            $display("*                            *            /|____|\\     ");
            $display("*    Congratulations !!      *          ((´-___- `))    ");
            $display("*                            *         ///        \\\\\\");
            $display("*    You pass this test!!    *        /||          ||\\ ");
            $display("*                            *        w|\\ m      m /|w ");
            $display("******************************          \\(o)____(o)/   ");
            $display(" ");
        	end
			$display("stop at overflow(2) or eof(3): %2b",mips_status);
			$finish;
    	end
	end

	initial begin
        # (`MAX_CYCLE * `CYCLE);
        $display("----------------------------------------------");
        $display("Latency of your design is over 120000 cycles!!");
        $display("----------------------------------------------");
        $finish;
    end
	
endmodule



