module core (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [13:0] o_out_data
);

// Definition of states
parameter   IDLE    		= 4'd0;
parameter   OP_READY    	= 4'd1;
parameter   OP_RECEIVE    	= 4'd2;
parameter   OP_LOAD    		= 4'd3;

parameter   OP_DISP			= 4'd4;
parameter   OP_CONV			= 4'd5;
parameter   OP_MEDI			= 4'd6;
parameter   OP_HAAR			= 4'd7;

parameter   BUFF0		    = 4'd8;
parameter   BUFF1			= 4'd9;
parameter   BUFF2			= 4'd10;
parameter   BUFF3			= 4'd11;

// Definition of operations
parameter   LOAD    		= 4'd0;
parameter   RIGHT_shift    	= 4'd1;
parameter   LEFT_shift    	= 4'd2;
parameter   UP_shift    	= 4'd3;
parameter   DOWN_shift   	= 4'd4;
parameter   REDUCE_depth   	= 4'd5;
parameter   INCREASE_depth  = 4'd6;
parameter   DISPLAY    		= 4'd7;
parameter   CONVOLUTION    	= 4'd8;
parameter   MEDIAN_filter   = 4'd9;
parameter   HAAR_wavelet    = 4'd10;

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //

// LOAD
reg  [10:0] addr, addr_nxt;
// DISPLAY
reg  [ 7:0] cnt_disp, cnt_disp_nxt;
// ORIGIN
reg  [ 2:0] origin_row_r, origin_row_w;
reg  [ 2:0] origin_col_r, origin_col_w;
reg  [ 5:0] depth_r, depth_w; 
// FSM
reg  [ 3:0] state, state_nxt;
// OUTPUT
reg			o_op_ready_r, o_op_ready_w;
reg			o_out_valid_r, o_out_valid_w;
reg			o_conv_valid_r, o_conv_valid_w;
reg			o_median_valid_r, o_median_valid_w;
reg			o_haar_valid_r, o_haar_valid_w;
reg	 [ 3:0] op;

// CONVOLUTION
reg  [ 1:0]	conv_num;
wire [ 2:0] conv_row    [3:0];
wire [ 2:0] conv_col    [3:0];
wire [ 1:0] sram_choose [3:0];
reg  [10:0]	sram_addr_renew;

// MEDIAN
reg  [ 1:0]	median_num;

// HARR
reg	 [ 1:0] haar_num;

assign conv_row[0] = origin_row_r-1;
assign conv_row[1] = origin_row_r;
assign conv_row[2] = origin_row_r+1;
assign conv_row[3] = origin_row_r+2;

assign conv_col[0] = origin_col_r-1;
assign conv_col[1] = origin_col_r;
assign conv_col[2] = origin_col_r+1;
assign conv_col[3] = origin_col_r+2;

assign sram_choose[0] = conv_col[0][1:0];
assign sram_choose[1] = conv_col[1][1:0];
assign sram_choose[2] = conv_col[2][1:0];
assign sram_choose[3] = conv_col[3][1:0];

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

always @(*)
begin
	o_op_ready_w = 0;
	state_nxt = state;
	depth_w = depth_r;
	origin_col_w = origin_col_r;
	origin_row_w = origin_row_r;
	o_out_valid_w = o_out_valid_r;
	o_conv_valid_w = o_conv_valid_r;
	addr_nxt = addr;
	cnt_disp_nxt = cnt_disp;
	o_median_valid_w = o_median_valid_r;
	o_haar_valid_w = o_haar_valid_r;
	case(state)
		IDLE:
		begin
			o_op_ready_w = 1;
			o_out_valid_w = 0;
			addr_nxt = 0;
			o_median_valid_w = 0;
			o_haar_valid_w = 0;
			state_nxt = OP_READY;
		end
		OP_READY:
		begin
			o_op_ready_w = 0;
			cnt_disp_nxt = 0;
			state_nxt = OP_RECEIVE;
		end
		OP_RECEIVE:
		begin
			if(i_op_valid)
			begin
				case(i_op_mode)
					LOAD:
					begin
						state_nxt = OP_LOAD;
					end
					RIGHT_shift:
					begin
						state_nxt = IDLE;
						if(origin_col_r == 3'b110)
							origin_col_w = origin_col_r;
						else origin_col_w = origin_col_r + 1;
					end
					LEFT_shift:
					begin
						state_nxt = IDLE;
						if(origin_col_r == 3'b000)
							origin_col_w = origin_col_r;
						else origin_col_w = origin_col_r - 1;
					end
					UP_shift:
					begin
						state_nxt = IDLE;
						if(origin_row_r == 3'b000)
							origin_row_w = origin_row_r;
						else origin_row_w = origin_row_r - 1;
					end
					DOWN_shift:
					begin
						state_nxt = IDLE;
						if(origin_row_r == 3'b110)
							origin_row_w = origin_row_r;
						else origin_row_w = origin_row_r + 1;
					end
					REDUCE_depth:
					begin
						state_nxt = IDLE;
						if(depth_r == 8) depth_w = depth_r;
						else 			 depth_w = depth_r >> 1;
					end
					INCREASE_depth:
					begin
						state_nxt = IDLE;
						if(depth_r == 32) depth_w = depth_r;
						else 			  depth_w = depth_r << 1;
					end
					DISPLAY:
					begin
						state_nxt = OP_DISP;
					end
					CONVOLUTION:
					begin
						state_nxt = OP_CONV;
					end
					MEDIAN_filter:
					begin
						state_nxt = OP_MEDI;
					end
					HAAR_wavelet:
					begin
						state_nxt = OP_HAAR;
					end
					default:
						state_nxt = IDLE;
				endcase
			end
		end
		OP_LOAD:
		begin
			addr_nxt = addr + 1;
			if(addr == 2047)
			begin
				state_nxt = IDLE;
			end
		end
		OP_DISP:
		begin
			o_out_valid_w = 1;
			cnt_disp_nxt = cnt_disp + 1;
			if( op == DISPLAY && cnt_disp == (4*depth_r -1) )
			begin
				state_nxt = IDLE;
			end
			else if( op == CONVOLUTION && cnt_disp == (4*depth_r +2))
			begin
				o_conv_valid_w = 1;
				state_nxt = BUFF0;
			end
			else if( op == MEDIAN_filter && cnt_disp > 3)
			begin
				o_median_valid_w = 1;
				if(cnt_disp == (4*4 +3)) state_nxt = IDLE;
			end
			else if( op == HAAR_wavelet && cnt_disp > 4)
			begin
				o_haar_valid_w = 1;
				if(cnt_disp == (4*4 +4)) state_nxt = IDLE;
			end
		end
		OP_CONV:
		begin
			state_nxt = OP_DISP;
		end
		OP_MEDI:
		begin
			state_nxt = OP_DISP;
		end
		OP_HAAR:
		begin
			state_nxt = OP_DISP;
		end
		BUFF0 : state_nxt = BUFF1;
		BUFF1 : state_nxt = BUFF2;
		BUFF2 : state_nxt = BUFF3;
		BUFF3 : 
		begin
			o_conv_valid_w = 0;
			o_op_ready_w = 1;
			state_nxt = OP_READY;
		end
		default :
		begin
			state_nxt = IDLE;
		end
	endcase
end

// SRAM
reg  [10:0] sram_addr [3:0]; 
wire [ 7:0] sram_q	  [3:0];
wire sram0_wen = ((state == OP_LOAD) && i_in_valid)? (sram_addr[0][1:0] != 0) : 1;
wire sram1_wen = ((state == OP_LOAD) && i_in_valid)? (sram_addr[1][1:0] != 1) : 1;
wire sram2_wen = ((state == OP_LOAD) && i_in_valid)? (sram_addr[2][1:0] != 2) : 1;
wire sram3_wen = ((state == OP_LOAD) && i_in_valid)? (sram_addr[3][1:0] != 3) : 1;

always@(*) 
begin
	sram_addr[0] = addr;
	sram_addr[1] = addr;
	sram_addr[2] = addr;
	sram_addr[3] = addr;
	if((op == DISPLAY) && (state == OP_DISP)) 
	begin
		case(cnt_disp[1:0])
			2'b00: begin
				sram_addr[0] = {cnt_disp[6:2], origin_row_r, origin_col_r};
				sram_addr[1] = {cnt_disp[6:2], origin_row_r, origin_col_r};
				sram_addr[2] = {cnt_disp[6:2], origin_row_r, origin_col_r};
				sram_addr[3] = {cnt_disp[6:2], origin_row_r, origin_col_r};
			end
			2'b01: begin
				sram_addr[0] = {cnt_disp[6:2], origin_row_r, origin_col_r}+1;
				sram_addr[1] = {cnt_disp[6:2], origin_row_r, origin_col_r}+1;
				sram_addr[2] = {cnt_disp[6:2], origin_row_r, origin_col_r}+1;
				sram_addr[3] = {cnt_disp[6:2], origin_row_r, origin_col_r}+1;
			end
			2'b10: begin
				sram_addr[0] = {cnt_disp[6:2], origin_row_r, origin_col_r}+8;
				sram_addr[1] = {cnt_disp[6:2], origin_row_r, origin_col_r}+8;
				sram_addr[2] = {cnt_disp[6:2], origin_row_r, origin_col_r}+8;
				sram_addr[3] = {cnt_disp[6:2], origin_row_r, origin_col_r}+8;
			end
			2'b11: begin
				sram_addr[0] = {cnt_disp[6:2], origin_row_r, origin_col_r}+9;
				sram_addr[1] = {cnt_disp[6:2], origin_row_r, origin_col_r}+9;
				sram_addr[2] = {cnt_disp[6:2], origin_row_r, origin_col_r}+9;
				sram_addr[3] = {cnt_disp[6:2], origin_row_r, origin_col_r}+9;
			end
		endcase 
	end
	else if((op == CONVOLUTION || op == MEDIAN_filter  || op == HAAR_wavelet) && (state == OP_DISP)) 
	begin
		case(cnt_disp[1:0])
			2'b00: begin
				sram_addr[conv_col[0][1:0]] = {cnt_disp[6:2], conv_row[0], conv_col[0]};
				sram_addr[conv_col[1][1:0]] = {cnt_disp[6:2], conv_row[0], conv_col[1]};
				sram_addr[conv_col[2][1:0]] = {cnt_disp[6:2], conv_row[0], conv_col[2]};
				sram_addr[conv_col[3][1:0]] = {cnt_disp[6:2], conv_row[0], conv_col[3]};
			end
			2'b01: begin
				sram_addr[conv_col[0][1:0]] = {cnt_disp[6:2], conv_row[1], conv_col[0]};
				sram_addr[conv_col[1][1:0]] = {cnt_disp[6:2], conv_row[1], conv_col[1]};
				sram_addr[conv_col[2][1:0]] = {cnt_disp[6:2], conv_row[1], conv_col[2]};
				sram_addr[conv_col[3][1:0]] = {cnt_disp[6:2], conv_row[1], conv_col[3]};
			end
			2'b10: begin
				sram_addr[conv_col[0][1:0]] = {cnt_disp[6:2], conv_row[2], conv_col[0]};
				sram_addr[conv_col[1][1:0]] = {cnt_disp[6:2], conv_row[2], conv_col[1]};
				sram_addr[conv_col[2][1:0]] = {cnt_disp[6:2], conv_row[2], conv_col[2]};
				sram_addr[conv_col[3][1:0]] = {cnt_disp[6:2], conv_row[2], conv_col[3]};
			end
			2'b11: begin
				sram_addr[conv_col[0][1:0]] = {cnt_disp[6:2], conv_row[3], conv_col[0]};
				sram_addr[conv_col[1][1:0]] = {cnt_disp[6:2], conv_row[3], conv_col[1]};
				sram_addr[conv_col[2][1:0]] = {cnt_disp[6:2], conv_row[3], conv_col[2]};
				sram_addr[conv_col[3][1:0]] = {cnt_disp[6:2], conv_row[3], conv_col[3]};
			end
		endcase
	end
end

sram_512x8 s0 (.Q(sram_q[0]), .CLK(i_clk), .CEN(1'b0), .WEN(sram0_wen), .A(sram_addr[0][10:2]), .D(i_in_data));
sram_512x8 s1 (.Q(sram_q[1]), .CLK(i_clk), .CEN(1'b0), .WEN(sram1_wen), .A(sram_addr[1][10:2]), .D(i_in_data));
sram_512x8 s2 (.Q(sram_q[2]), .CLK(i_clk), .CEN(1'b0), .WEN(sram2_wen), .A(sram_addr[2][10:2]), .D(i_in_data));
sram_512x8 s3 (.Q(sram_q[3]), .CLK(i_clk), .CEN(1'b0), .WEN(sram3_wen), .A(sram_addr[3][10:2]), .D(i_in_data));

// CONVOLUTION
reg [7:0]            x [15:0];
reg [17:0]           y [ 3:0];
reg [13:0]           z [ 3:0];
reg	[55:0]		  temp	 	 ; 
wire       conv_row_ok [ 3:0]; 
wire       conv_col_ok [ 3:0];

assign conv_row_ok[0] = (origin_row_r !=0);
assign conv_row_ok[1] = 1;
assign conv_row_ok[2] = 1;
assign conv_row_ok[3] = (origin_row_r !=6);

assign conv_col_ok[0] = (origin_col_r !=0);
assign conv_col_ok[1] = 1;
assign conv_col_ok[2] = 1;
assign conv_col_ok[3] = (origin_col_r !=6);

integer i;
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		temp <= 0;
		for(i=0 ; i<16 ; i=i+1)
			x[i] <= 0;
	end
	else if(state == OP_RECEIVE) begin
		temp <= 0;
		for(i=0 ; i<16 ; i=i+1)
			x[i] <= 0;
	end
	else if((op == CONVOLUTION || op == MEDIAN_filter) && (state == OP_DISP) && (cnt_disp > 0)) begin	
		case(cnt_disp[1:0])
			2'b01: begin
				x[0] <= (conv_row_ok[0] && conv_col_ok[0])? sram_q[sram_choose[0]] : 0;
				x[1] <= (conv_row_ok[0] && conv_col_ok[1])? sram_q[sram_choose[1]] : 0;
				x[2] <= (conv_row_ok[0] && conv_col_ok[2])? sram_q[sram_choose[2]] : 0;
				x[3] <= (conv_row_ok[0] && conv_col_ok[3])? sram_q[sram_choose[3]] : 0;
			end
			2'b10: begin
				x[4] <= (conv_row_ok[1] && conv_col_ok[0])? sram_q[sram_choose[0]] : 0;
				x[5] <= sram_q[sram_choose[1]];
				x[6] <= sram_q[sram_choose[2]];
				x[7] <= (conv_row_ok[1] && conv_col_ok[3])? sram_q[sram_choose[3]] : 0;
			end
			2'b11: begin
				x[8]  <= (conv_row_ok[2] && conv_col_ok[0])? sram_q[sram_choose[0]] : 0;
				x[9]  <= sram_q[sram_choose[1]];
				x[10] <= sram_q[sram_choose[2]];
				x[11] <= (conv_row_ok[2] && conv_col_ok[3])? sram_q[sram_choose[3]] : 0;
			end
			2'b00: begin
				x[12] <= (conv_row_ok[3] && conv_col_ok[0])? sram_q[sram_choose[0]] : 0;
				x[13] <= (conv_row_ok[3] && conv_col_ok[1])? sram_q[sram_choose[1]] : 0;
				x[14] <= (conv_row_ok[3] && conv_col_ok[2])? sram_q[sram_choose[2]] : 0;
				x[15] <= (conv_row_ok[3] && conv_col_ok[3])? sram_q[sram_choose[3]] : 0;
			end
		endcase
	end
	else if((op == HAAR_wavelet) && (state == OP_DISP) && (cnt_disp > 0)) begin	
		case(cnt_disp[1:0])
			2'b10: begin
				x[15] <= sram_q[sram_choose[1]];
				x[14] <= sram_q[sram_choose[2]];
				end
			2'b11: begin
				x[13] <= sram_q[sram_choose[1]];
				x[12] <= sram_q[sram_choose[2]];
				end
			2'b00: begin
				temp <= haar({6'b0,x[15]}, {6'b0,x[14]}, {6'b0,x[13]}, {6'b0,x[12]});
				end
		endcase
	end	
end

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		y[0] <= 0;
		y[1] <= 0;
		y[2] <= 0;
		y[3] <= 0;
	end	
	else if(state == OP_RECEIVE) begin
		y[0] <= 0;
		y[1] <= 0;
		y[2] <= 0;
		y[3] <= 0;
	end	
	else if((op == CONVOLUTION) && (state == OP_DISP) && (cnt_disp[1:0] == 0) && (cnt_disp > 0) ) begin
		y[0] <= y[0] + (x[5] <<2) + ((x[1]+x[4]+ x[6]+ x[9]) <<1) + (x[0]+x[2]+ x[8]+x[10]);
		y[1] <= y[1] + (x[6] <<2) + ((x[2]+x[5]+ x[7]+x[10]) <<1) + (x[1]+x[3]+ x[9]+x[11]);	
	end
	else if((op == CONVOLUTION) && (state == OP_DISP) && (cnt_disp[1:0] == 1) && (cnt_disp > 1) ) begin
		y[2] <= y[2] + (x[9] <<2) + ((x[5]+x[8]+x[10]+x[13]) <<1) + (x[4]+x[6]+x[12]+x[14]);
		y[3] <= y[3] + (x[10]<<2) + ((x[6]+x[9]+x[11]+x[14]) <<1) + (x[5]+x[7]+x[13]+x[15]);
	end
	else if((op == MEDIAN_filter) && (state == OP_DISP) && (cnt_disp[1:0] == 0) && (cnt_disp > 0) ) begin
		y[0] <= median_9(x[0], x[1], x[2], x[4], x[5], x[6], x[8],  x[9], x[10]);
		y[1] <= median_9(x[1], x[2], x[3], x[5], x[6], x[7], x[9], x[10], x[11]);
		end
	else if((op == MEDIAN_filter) && (state == OP_DISP) && (cnt_disp[1:0] == 1) && (cnt_disp > 1) ) begin
		y[2] <= median_9(x[4], x[5], x[6], x[8],  x[9], x[10], x[12], x[13], x[14]);
		y[3] <= median_9(x[5], x[6], x[7], x[9], x[10], x[11], x[13], x[14], x[15]);
	end
	else if((op == HAAR_wavelet) && (state == OP_DISP) && (cnt_disp[1:0] == 1) && (cnt_disp > 1) ) begin
		y[0] <= temp[55:42];
		y[1] <= temp[41:28];
		end
	else if((op == HAAR_wavelet) && (state == OP_DISP) && (cnt_disp[1:0] == 3) && (cnt_disp > 3) ) begin
		y[2] <= temp[27:14];
		y[3] <= temp[13: 0];
	end
end	

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		z[0] <= 0;
		z[1] <= 0;
		z[2] <= 0;
		z[3] <= 0;
	end	
	else if(state == OP_RECEIVE) begin
		z[0] <= 0;
		z[1] <= 0;
		z[2] <= 0;
		z[3] <= 0;
	end	
	else if((op == CONVOLUTION) && (state == OP_DISP) && (cnt_disp == (4*depth_r +1)) ) begin
		z[0] <= y[0][17:4]+y[0][3];
		z[1] <= y[1][17:4]+y[1][3];
	end
	else if((op == CONVOLUTION) && (state == OP_DISP) && (cnt_disp == (4*depth_r +2)) ) begin
		z[2] <= y[2][17:4]+y[2][3];
		z[3] <= y[3][17:4]+y[3][3];
	end	
end	

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //

always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) 
	begin
		addr			  <= 0;
		cnt_disp		  <= 0;				
		state 		 	  <= IDLE;
		o_op_ready_r 	  <= 1'd0;
		op                <= 4'd0;
		depth_r			  <= 6'd32;
		origin_col_r	  <= 3'd0;
		origin_row_r	  <= 3'd0;
		o_out_valid_r     <= 1'd0;
		sram_addr_renew   <= 12'd0;
		o_conv_valid_r 	  <= 0;
		conv_num		  <= 0;
		o_median_valid_r  <= 0;
		median_num		  <= 0;
		o_haar_valid_r    <= 0;
		haar_num		  <= 0;
	end
	else 
	begin
		addr			  <= addr_nxt;
		cnt_disp 		  <= cnt_disp_nxt;		
		state 			  <= state_nxt;
		o_op_ready_r 	  <= o_op_ready_w;
		if(i_op_valid) op <= i_op_mode;
		depth_r 		  <= depth_w;
		origin_col_r	  <= origin_col_w;
		origin_row_r	  <= origin_row_w;
		o_out_valid_r     <= o_out_valid_w;
		sram_addr_renew   <= sram_addr[0];
		o_conv_valid_r 	  <= o_conv_valid_w;
		conv_num		  <= conv_num + o_conv_valid_r;		
		o_median_valid_r  <= o_median_valid_w;
		median_num		  <= median_num + o_median_valid_r;
		o_haar_valid_r    <= o_haar_valid_w;
		haar_num		  <= haar_num + o_haar_valid_r;
	end
end

// OUTPUT
wire [13:0] disp_data	= {6'b0, sram_q[sram_addr_renew[1:0]]}; 
wire [13:0]	conv_data	= z[conv_num];
wire [13:0] median_data	= y[median_num][13:0];
wire [13:0] haar_data 	= y[haar_num][13:0];

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //

assign o_op_ready 	  = o_op_ready_r;
assign o_in_ready 	  = 1;
assign o_out_valid 	  = (op == DISPLAY) ? o_out_valid_r : (op == CONVOLUTION) ? o_conv_valid_r : (op == MEDIAN_filter) ? o_median_valid_r : o_haar_valid_r;
assign o_out_data 	  = (op == DISPLAY) ? disp_data : (op == CONVOLUTION) ? conv_data : (op == MEDIAN_filter) ? median_data : haar_data;

function [23:0]	sort;
input [7:0]	a;
input [7:0]	b;
input [7:0]	c;

begin
	if(a >= c && a <= b)
		sort = {c,a,b};
	else if(a >= b && a <= c)
		sort = {b,a,c};
	else if(b >= a && b <= c)
		sort = {a,b,c};
	else if(b >= c && b <= a)
		sort = {c,b,a};
	else if(c >= a && c <= b)
		sort = {a,c,b};
	else if(c >= b && c <= a)
		sort = {b,c,a};	
end
endfunction

function	[7:0] median_9;
input	 	[7:0] aa;  
input	 	[7:0] ab;
input	 	[7:0] ac;
input		[7:0] ba;
input	 	[7:0] bb;
input	 	[7:0] bc;
input	 	[7:0] ca;
input	 	[7:0] cb;
input	 	[7:0] cc;
reg   		[23:0] AA;
reg     	[23:0] BB;
reg     	[23:0] CC;
reg   		[23:0] AAA;
reg     	[23:0] BBB;
reg     	[23:0] CCC;
reg     	[23:0] D;

begin
AA = sort(aa, ab, ac);
BB = sort(ba, bb, bc);
CC = sort(ca, cb, cc);
AAA = sort(AA[23:16], BB[23:16], CC[23:16]);
BBB = sort(AA[15: 8], BB[15: 8], CC[15: 8]);
CCC = sort(AA[ 7: 0], BB[ 7: 0], CC[ 7: 0]);
D   = sort(AAA[ 7: 0], BBB[15: 8], CCC[23:16]);
median_9 = D[15: 8];
end
endfunction

function	[55:0] haar;
input	 	[13:0] a;  
input	 	[13:0] b;
input	 	[13:0] c;
input		[13:0] d;
reg   		[13:0] aa;
reg     	[13:0] bb;
reg     	[13:0] cc;
reg   		[13:0] dd;
reg   		[13:0] ta;
reg   		[13:0] tb;
reg   		[13:0] tc;
reg   		[13:0] td;
reg   		[13:0] aaa;
reg     	[13:0] bbb;
reg     	[13:0] ccc;
reg   		[13:0] ddd;

begin
aa = a + b + c + d;
bb = a + c + (~b + 1) + (~d + 1);
cc = a + b + (~c + 1) + (~d + 1);
dd = a + d + (~b + 1) + (~c + 1);
ta = (aa+aa[0])>>>1;
tb = (bb+bb[0])>>>1;
tc = (cc+cc[0])>>>1;
td = (dd+dd[0])>>>1;
aaa = (aa[13]) ? ({1'b1,ta[12:0]}) : ({1'b0,ta[12:0]});
bbb = (bb[13]) ? ({1'b1,tb[12:0]}) : ({1'b0,tb[12:0]});
ccc = (cc[13]) ? ({1'b1,tc[12:0]}) : ({1'b0,tc[12:0]});
ddd = (dd[13]) ? ({1'b1,td[12:0]}) : ({1'b0,td[12:0]});
haar = { aaa, bbb, ccc, ddd };
end
endfunction

endmodule
