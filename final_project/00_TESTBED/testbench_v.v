`timescale 1ns/1ps
`define CYCLE       15.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   70000
`define RST_DELAY   2
`define IN_PERIOD   64

`ifdef tb1
    `define YFILE       "../00_TESTBED/PATTERN/packet1/SNR10dB_pat_y_hat.dat"
    `define RFILE       "../00_TESTBED/PATTERN/packet1/SNR10dB_pat_r.dat"
    `define GOLDEN_LLR  "../00_TESTBED/PATTERN/packet1/SNR10dB_llr.dat"
    `define GOLDEN_HB   "../00_TESTBED/PATTERN/packet1/SNR10dB_hb.dat"
    `define TEST_DATA_NUM 1000
    `define GOLDEN_NUM 8000
`elsif tb2
    `define YFILE       "../00_TESTBED/PATTERN/packet2/SNR10dB_pat_y_hat.dat"
    `define RFILE       "../00_TESTBED/PATTERN/packet2/SNR10dB_pat_r.dat"
    `define GOLDEN_LLR  "../00_TESTBED/PATTERN/packet2/SNR10dB_llr.dat"
    `define GOLDEN_HB   "../00_TESTBED/PATTERN/packet2/SNR10dB_hb.dat"
    `define TEST_DATA_NUM 1000
    `define GOLDEN_NUM 8000
`elsif tb3
    `define YFILE       "../00_TESTBED/PATTERN/packet3/SNR10dB_pat_y_hat.dat"
    `define RFILE       "../00_TESTBED/PATTERN/packet3/SNR10dB_pat_r.dat"
    `define GOLDEN_LLR  "../00_TESTBED/PATTERN/packet3/SNR10dB_llr.dat"
    `define GOLDEN_HB   "../00_TESTBED/PATTERN/packet3/SNR10dB_hb.dat"
    `define TEST_DATA_NUM 1000
    `define GOLDEN_NUM 8000
`elsif tb4
    `define YFILE       "../00_TESTBED/PATTERN/packet4/SNR15dB_pat_y_hat.dat"
    `define RFILE       "../00_TESTBED/PATTERN/packet4/SNR15dB_pat_r.dat"
    `define GOLDEN_LLR  "../00_TESTBED/PATTERN/packet4/SNR15dB_llr.dat"
    `define GOLDEN_HB   "../00_TESTBED/PATTERN/packet4/SNR15dB_hb.dat"
    `define TEST_DATA_NUM 1000
    `define GOLDEN_NUM 8000
`elsif tb5
    `define YFILE       "../00_TESTBED/PATTERN/packet5/SNR15dB_pat_y_hat.dat"
    `define RFILE       "../00_TESTBED/PATTERN/packet5/SNR15dB_pat_r.dat"
    `define GOLDEN_LLR  "../00_TESTBED/PATTERN/packet5/SNR15dB_llr.dat"
    `define GOLDEN_HB   "../00_TESTBED/PATTERN/packet5/SNR15dB_hb.dat"
    `define TEST_DATA_NUM 1000
    `define GOLDEN_NUM 8000
`else
    `define YFILE       "../00_TESTBED/PATTERN/packet6/SNR15dB_pat_y_hat.dat"
    `define RFILE       "../00_TESTBED/PATTERN/packet6/SNR15dB_pat_r.dat"
    `define GOLDEN_LLR  "../00_TESTBED/PATTERN/packet6/SNR15dB_llr.dat"
    `define GOLDEN_HB   "../00_TESTBED/PATTERN/packet6/SNR15dB_hb.dat"
    `define TEST_DATA_NUM 1000
    `define GOLDEN_NUM 8000
`endif

`define SDFFILE "../02_SYN/Netlist/ml_demodulator_syn.sdf"  // Modify your sdf file name
//`define SDFFILE    "../04_APR/ml_demodulator.sdf" //Modify your sdf file name

module testbed;
     
    reg                  clk, reset;
    reg                  trig;
    reg          [159:0] y_hat;
    reg          [319:0] r;
    reg                  rd_rdy;
    wire                 rd_vld;
    wire                 hard_bit;
    wire           [7:0] llr;

    integer              i;
    integer              j;
    integer              k;
    integer              temp;
    integer              l;
    integer              m;
    integer              error;
    integer              cycle_count;

    parameter IN_R_BW         = 320;
    parameter IN_R_SIZE       = `TEST_DATA_NUM;

    parameter IN_Y_HAT_BW     = 160;
    parameter IN_Y_HAT_SIZE   = `TEST_DATA_NUM;

    parameter GOLDEN_HB_SIZE  = `GOLDEN_NUM;

    parameter GOLDEN_LLR_BW   = 8;
    parameter GOLDEN_LLR_SIZE = `GOLDEN_NUM;

    reg  [  IN_Y_HAT_BW - 1 : 0] y_mem   [0 : IN_Y_HAT_SIZE     - 1];
    reg  [      IN_R_BW - 1 : 0] r_mem   [0 : IN_R_SIZE         - 1];
    reg  [GOLDEN_LLR_BW - 1 : 0] llr_mem [0 : GOLDEN_LLR_SIZE   - 1];
    reg                          hb_mem  [0 : GOLDEN_HB_SIZE    - 1];

    real                 DER, error_rate;

    // For gate-level simulation only
    `ifdef SDF
        initial $sdf_annotate(`SDFFILE, u_ml_demodulator);
        initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
    `endif

    // Write out waveform file
    initial begin
        `ifdef tb1
            $fsdbDumpfile("ml_demodulator_tb1.fsdb");
            DER = 120;
        `elsif tb2
            $fsdbDumpfile("ml_demodulator_tb2.fsdb");
            DER = 120;
        `elsif tb3
            $fsdbDumpfile("ml_demodulator_tb3.fsdb");
            DER = 120;
        `elsif tb4
            $fsdbDumpfile("ml_demodulator_tb4.fsdb");
            DER = 10;
        `elsif tb5
            $fsdbDumpfile("ml_demodulator_tb5.fsdb");
            DER = 10;
        `else
            $fsdbDumpfile("ml_demodulator_tb6.fsdb");
            DER = 10;
        `endif
        $fsdbDumpvars(0, "+mda");
    end

    ml_demodulator u_ml_demodulator (
    	.i_clk(clk),
    	.i_reset(reset),
    	.i_trig(trig),
    	.i_y_hat(y_hat),
        .i_r(r),
    	.i_rd_rdy(rd_rdy),
    	.o_rd_vld(rd_vld),
    	.o_hard_bit(hard_bit),
    	.o_llr(llr)
    );

    // Read in test pattern and golden pattern
    initial $readmemh(`YFILE, y_mem);
    initial $readmemh(`RFILE, r_mem);
    initial $readmemh(`GOLDEN_LLR, llr_mem);
    initial $readmemb(`GOLDEN_HB, hb_mem);

    // Clock generation
    initial clk = 1'b0;
    always begin #(`CYCLE/2) clk = ~clk; end

    // Reset generation
    initial begin
        reset = 0; # (               0.25 * `CYCLE);
        reset = 1; # ((`RST_DELAY - 0.25) * `CYCLE);
        reset = 0; # (         `MAX_CYCLE * `CYCLE);
        $display("Error! Runtime exceeded!");
        $finish;
    end

    // Cycle count
    initial begin
        cycle_count = 0;
        @(negedge clk);
        while (1) begin
            cycle_count = cycle_count + 1;
            @(negedge clk);
        end
    end

    // ==============================================
    // TODO: Check pattern after process finish
    // ==============================================

    // i_trig
    initial begin
        i       = 0;
        j       = 0;
        trig    = 0;
        while (i < `TEST_DATA_NUM)begin
            @(posedge clk);
            #(1.0);
            if (j == 2) begin
                trig = 1;
                y_hat = y_mem[i];
                r = r_mem[i];
                j = j + 1;
                i = i + 1;
                @(posedge clk);
                #(1.0);
                trig = 0;
            end
            if (j == 64) begin
                j = 0;         
            end
            j = j + 1;
        end
    end
    // check output
    reg [7:0] golden_llr;
    reg       golden_hb;
    initial begin
        k = 0;
        temp =0;
        error = 0;
        while (k < `GOLDEN_NUM) begin
            @(posedge clk);
            #(`CYCLE - 1.0);
            if (rd_rdy && rd_vld) begin
                golden_llr = llr_mem[k][7:0];
                golden_hb  = hb_mem [k];
                if (hard_bit !== golden_hb || llr === 0) begin
                    if (hard_bit !== golden_hb)
                    $display ("Test[%4d]: Error! HB  GOLDEN=(%d), yours=(%d)", k, golden_hb, hard_bit);
                    else
                    $display ("Test[%4d]: Right! HB  GOLDEN=(%d), yours=(%d)", k, golden_hb, hard_bit);
                    if (llr === 0)
                    $display ("Test[%4d]: Error! LLR GOLDEN=(%h), yours=(%h)", k, golden_llr, llr);
                    else
                    $display ("Test[%4d]: Right! LLR GOLDEN=(%h), yours=(%h)", k, golden_llr, llr);
                    if(k/8 != temp/8) begin
                        error = error+1;
                        temp = k;
                    end
                end     
                // else begin
                //     $display("Test[%4d]: Right! GOLDEN=(%d), yours=(%d)", k, golden_hb, hard_bit);
                //     $display ("Test[%4d]: LLR GOLDEN=(%h), yours=(%h)", k, golden_llr, llr);
                // end 
                k = k + 1;
            end
        end
        //error_rate = error / `TEST_DATA_NUM;
        if(error < DER) begin
                $display("----------------------------------------------");
                $display("-                 ALL PASS!                  -");
                $display("-                 error: %d            ", error);
                $display("----------------------------------------------");
            end else begin
                $display("----------------------------------------------");
                $display("                    Wrong!                    ");
                $display("                 Total error: %d       ", error);
                $display("----------------------------------------------");
            end
        # ( 2 * `CYCLE);
        $display("End of Process, total cycle = %d",cycle_count);
        $finish;
    end
    // i_rd_rdy
    initial 
    begin
        l       = 0;
        m       = 10;
        rd_rdy  = 0;
        while (k < `GOLDEN_NUM)begin
            @(posedge clk);
            #(1.0);
            if (l == 1) begin
                m = {$random} % 513 +2;
            end
            if (l == m) begin
                rd_rdy = 1;
            end
            if (l == m+128) begin
                rd_rdy = 0;
            end
            if (l == 640) begin
                l = 0;
            end
            l = l + 1;
        end
    end

endmodule
