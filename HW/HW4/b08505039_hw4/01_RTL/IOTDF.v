`timescale 1ns/10ps
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [3:0]   fn_sel;
output         busy;
output         valid;
output [127:0] iot_out;

// Definition of states
parameter   IDLE    		= 4'd0;
parameter   IN_READ     	= 4'd1;

// Definition of operations
parameter   MAX    		    = 4'd1;
parameter   MIN    	        = 4'd2;
parameter   TOP2MAX       	= 4'd3;
parameter   LAST2MIN    	= 4'd4;
parameter   AVG   	        = 4'd5;
parameter   EXTRACT      	= 4'd6;
parameter   EXCLUDE         = 4'd7;
parameter   PEAKMAX    		= 4'd8;
parameter   PEAKMIN        	= 4'd9;

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //

// INPUT
reg  [  7:0] iot_in_data [15:0];
reg  [  6:0] in_cycle_cnt_r, in_cycle_cnt_w; // 16*8=128
// FSM
reg          state, state_nxt;
reg          peak_flag;
always @(*)
begin
    state_nxt = state;
    in_cycle_cnt_w = in_cycle_cnt_r;
	case(state)
		IDLE:
		begin
            state_nxt = IN_READ;
        end
		IN_READ:
		begin
            if(in_en)
            begin
                in_cycle_cnt_w = in_cycle_cnt_r + 1;
            end
        end
	endcase
end
// FSM & Cnt(16 cycles each for 8 datas = 128)
always @(posedge clk or posedge rst) begin
	if (rst) 
	begin		
		state 		 	  <= IDLE;
        in_cycle_cnt_r    <=    0;
	end
	else 
	begin	
		state 			  <= state_nxt;
        in_cycle_cnt_r    <= in_cycle_cnt_w;
	end
end
// After Round_0
always @(posedge clk or posedge rst) begin
	if (rst) 
	begin		
		peak_flag 	<= 0;
	end
	else if(in_cycle_cnt_r == 127)
	begin	
        peak_flag   <= 1;
	end
end

integer i;
// read iot_in
always@(posedge clk or posedge rst) begin
	if(rst) begin
		for(i=0; i<16; i=i+1) iot_in_data[i] <= 0;
	end
    else if (in_en) begin
        iot_in_data[in_cycle_cnt_r[3:0]] <= iot_in;
    end
end

// OUTPUT
wire [127:0] temp_out_data;
reg  [127:0] iot_out_data_x;
reg  [130:0] iot_out_data_y;
// Valid
wire         valid_a, valid_ext, valid_exc, valid_pmx, valid_pmn, valid_tl2;
// Bound
wire [127:0] high = (fn_sel == EXTRACT)? 128'h AFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF:
		   	                             128'h BFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
				 
wire [127:0] low = 	(fn_sel == EXTRACT)? 128'h 6FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF:
		   	                             128'h 7FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
// Assignment
assign temp_out_data = { iot_in_data[15], iot_in_data[14], iot_in_data[13], iot_in_data[12],
                         iot_in_data[11], iot_in_data[10], iot_in_data[ 9], iot_in_data[ 8],
                         iot_in_data[ 7], iot_in_data[ 6], iot_in_data[ 5], iot_in_data[ 4],
                         iot_in_data[ 3], iot_in_data[ 2], iot_in_data[ 1], iot_in_data[ 0]};
wire v1 = ((in_cycle_cnt_r != 0 || peak_flag) && in_cycle_cnt_r[3:0] ==  0);
wire v2 = (peak_flag && in_cycle_cnt_r == 1);
assign valid_a = (v2 && ((fn_sel == MAX)||(fn_sel == MIN)||(fn_sel == AVG)));
assign valid_ext = (v1 && fn_sel == EXTRACT &&  temp_out_data<high && temp_out_data>low);
assign valid_exc = (v1 && fn_sel == EXCLUDE && (temp_out_data>high || temp_out_data<low));
assign valid_pmx = (v2 && fn_sel == PEAKMAX && (iot_out_data_x > iot_out_data_y));
assign valid_pmn = (v2 && fn_sel == PEAKMIN && (iot_out_data_x < iot_out_data_y));
assign valid_tl2 =((v2 || (peak_flag && in_cycle_cnt_r == 2))
                    && ((fn_sel == TOP2MAX)||(fn_sel == LAST2MIN)));
// Functions : F1 ~ F9
always@(posedge clk or posedge rst) begin
	if(rst) 
    begin
        iot_out_data_x <= 0;
        iot_out_data_y <= 0;
	end
    else if (in_cycle_cnt_r       ==  2   && (fn_sel == MAX || fn_sel == TOP2MAX || fn_sel == AVG))
    begin
        iot_out_data_x <= 0;
        iot_out_data_y <= 0;
    end
    else if ((in_cycle_cnt_r      ==  2   && (fn_sel == MIN || fn_sel == LAST2MIN))
          || (state               == IDLE && (fn_sel == MIN || fn_sel == PEAKMIN || fn_sel == LAST2MIN)))
    begin
        iot_out_data_x <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;
        iot_out_data_y <= 131'h7_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;
    end
    else if (v1)      
    begin
		if( ((fn_sel == MAX || fn_sel == TOP2MAX || fn_sel == PEAKMAX)  && (temp_out_data > iot_out_data_x))
         || ((fn_sel == MIN || fn_sel == LAST2MIN || fn_sel == PEAKMIN) && (temp_out_data < iot_out_data_x)))
        begin
            iot_out_data_x <= temp_out_data;
        	iot_out_data_y <= {{3{1'b0}}, iot_out_data_x};
		end
		else if ((fn_sel == TOP2MAX  && (temp_out_data > iot_out_data_y))
              || (fn_sel == LAST2MIN && (temp_out_data < iot_out_data_y)))
    	begin
        	iot_out_data_y <= {{3{1'b0}}, temp_out_data};
    	end
		else if (fn_sel == AVG)
    	begin
        	iot_out_data_y <= iot_out_data_y + {{3{1'b0}}, temp_out_data};
    	end
	end
    else if( v2 && ((fn_sel == PEAKMAX && (iot_out_data_x > iot_out_data_y))
         || (fn_sel == PEAKMIN && (iot_out_data_x < iot_out_data_y))))
    begin
        iot_out_data_y <= {{3{1'b0}}, iot_out_data_x};
    end
end

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //

assign busy 	  = 0;
assign valid 	  = (fn_sel == EXTRACT) ? valid_ext : 
                    (fn_sel == EXCLUDE) ? valid_exc :
                    (fn_sel == PEAKMAX) ? valid_pmx :
                    (fn_sel == PEAKMIN) ? valid_pmn : 
                    (fn_sel == TOP2MAX || fn_sel == LAST2MIN) ? valid_tl2 :valid_a;
assign iot_out 	  = (valid_ext || valid_exc) ? temp_out_data : 
                    (valid_tl2 && in_cycle_cnt_r == 2) ? iot_out_data_y[127:0] : 
                    (fn_sel == AVG) ? iot_out_data_y[130:3] : iot_out_data_x;

endmodule
