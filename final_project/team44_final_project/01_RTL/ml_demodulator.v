module ml_demodulator(
    i_clk,
    i_reset,
    i_trig,
    i_y_hat,
    i_r,
    i_rd_rdy,
    o_rd_vld,
    o_llr,
    o_hard_bit
);

    // IO description
    input i_clk;
    input i_reset;
    input i_trig;
    input [159:0] i_y_hat;
    input [319:0] i_r;
    input i_rd_rdy;
    output o_rd_vld;
    output [7:0] o_llr;
    output o_hard_bit;
    
// **************************//
// *****   DECLARATION  *****//
// **************************//
integer i;

// BitLength
parameter   INT = 4;
parameter   FRAC = 7;
parameter   INT_TRUNC = 2;
parameter   FRAC_TRUNC = 9;
parameter   LENGTH = INT + FRAC;
parameter   TRUNCATION = INT_TRUNC + FRAC_TRUNC;
parameter   LENGTH_MUL = 2*LENGTH;

// Definition of states
parameter   IDLE    		= 4'd0;
parameter   COMPUTE_s4     	= 4'd1;
parameter   COMPUTE_s3_1st  = 4'd2;
parameter   COMPUTE_s3_2nd  = 4'd3;
parameter   COMPUTE_s2_1st  = 4'd4;
parameter   COMPUTE_s2_2nd  = 4'd5;
parameter   COMPUTE_s2_3rd  = 4'd6;
parameter   COMPUTE_s1_1st  = 4'd7;
parameter   COMPUTE_s1_2nd  = 4'd8;
parameter   COMPUTE_s1_3rd  = 4'd9;
parameter   COMPARE_4to1    = 4'd10;
parameter   LLR    		    = 4'd11;
parameter   COMPARE_4to2    = 4'd12;
parameter   COMPARE         = 4'd13;
parameter   COMPARE_3to1    = 4'd14;

// FSM
reg  [3:0] state, state_nxt;

// INPUT
reg signed [LENGTH - 1 : 0 ] i_y_hat_im_4;
reg signed [LENGTH - 1 : 0 ] i_y_hat_re_4;
reg signed [LENGTH - 1 : 0 ] i_y_hat_im_3;
reg signed [LENGTH - 1 : 0 ] i_y_hat_re_3;
reg signed [LENGTH - 1 : 0 ] i_y_hat_im_2;
reg signed [LENGTH - 1 : 0 ] i_y_hat_re_2;
reg signed [LENGTH - 1 : 0 ] i_y_hat_im_1;
reg signed [LENGTH - 1 : 0 ] i_y_hat_re_1;
reg signed [LENGTH - 1 : 0 ] i_r_re_44;
reg signed [LENGTH - 1 : 0 ] i_r_im_34;
reg signed [LENGTH - 1 : 0 ] i_r_re_34;
reg signed [LENGTH - 1 : 0 ] i_r_im_24;
reg signed [LENGTH - 1 : 0 ] i_r_re_24;
reg signed [LENGTH - 1 : 0 ] i_r_im_14;
reg signed [LENGTH - 1 : 0 ] i_r_re_14;
reg signed [LENGTH - 1 : 0 ] i_r_re_33;
reg signed [LENGTH - 1 : 0 ] i_r_im_23;
reg signed [LENGTH - 1 : 0 ] i_r_re_23;
reg signed [LENGTH - 1 : 0 ] i_r_im_13;
reg signed [LENGTH - 1 : 0 ] i_r_re_13;
reg signed [LENGTH - 1 : 0 ] i_r_re_22;
reg signed [LENGTH - 1 : 0 ] i_r_im_12;
reg signed [LENGTH - 1 : 0 ] i_r_re_12;
reg signed [LENGTH - 1 : 0 ] i_r_re_11;

wire signed [LENGTH - 1 : 0 ] i_r_re_44_pos;
wire signed [LENGTH - 1 : 0 ] i_r_im_34_pos;
wire signed [LENGTH - 1 : 0 ] i_r_re_34_pos;
wire signed [LENGTH - 1 : 0 ] i_r_im_24_pos;
wire signed [LENGTH - 1 : 0 ] i_r_re_24_pos;
wire signed [LENGTH - 1 : 0 ] i_r_im_14_pos;
wire signed [LENGTH - 1 : 0 ] i_r_re_14_pos;
wire signed [LENGTH - 1 : 0 ] i_r_re_33_pos;
wire signed [LENGTH - 1 : 0 ] i_r_im_23_pos;
wire signed [LENGTH - 1 : 0 ] i_r_re_23_pos;
wire signed [LENGTH - 1 : 0 ] i_r_im_13_pos;
wire signed [LENGTH - 1 : 0 ] i_r_re_13_pos;
wire signed [LENGTH - 1 : 0 ] i_r_re_22_pos;
wire signed [LENGTH - 1 : 0 ] i_r_im_12_pos;
wire signed [LENGTH - 1 : 0 ] i_r_re_12_pos;
wire signed [LENGTH - 1 : 0 ] i_r_re_11_pos;
wire signed [LENGTH - 1 : 0 ] i_r_re_44_neg;
wire signed [LENGTH - 1 : 0 ] i_r_im_34_neg;
wire signed [LENGTH - 1 : 0 ] i_r_re_34_neg;
wire signed [LENGTH - 1 : 0 ] i_r_im_24_neg;
wire signed [LENGTH - 1 : 0 ] i_r_re_24_neg;
wire signed [LENGTH - 1 : 0 ] i_r_im_14_neg;
wire signed [LENGTH - 1 : 0 ] i_r_re_14_neg;
wire signed [LENGTH - 1 : 0 ] i_r_re_33_neg;
wire signed [LENGTH - 1 : 0 ] i_r_im_23_neg;
wire signed [LENGTH - 1 : 0 ] i_r_re_23_neg;
wire signed [LENGTH - 1 : 0 ] i_r_im_13_neg;
wire signed [LENGTH - 1 : 0 ] i_r_re_13_neg;
wire signed [LENGTH - 1 : 0 ] i_r_re_22_neg;
wire signed [LENGTH - 1 : 0 ] i_r_im_12_neg;
wire signed [LENGTH - 1 : 0 ] i_r_re_12_neg;
wire signed [LENGTH - 1 : 0 ] i_r_re_11_neg;
assign i_r_re_44_pos = (i_r_re_44 >>> 1) + (i_r_re_44 >>> 3) + (i_r_re_44 >>> 4);
assign i_r_im_34_pos = (i_r_im_34 >>> 1) + (i_r_im_34 >>> 3) + (i_r_im_34 >>> 4);
assign i_r_re_34_pos = (i_r_re_34 >>> 1) + (i_r_re_34 >>> 3) + (i_r_re_34 >>> 4);
assign i_r_im_24_pos = (i_r_im_24 >>> 1) + (i_r_im_24 >>> 3) + (i_r_im_24 >>> 4);
assign i_r_re_24_pos = (i_r_re_24 >>> 1) + (i_r_re_24 >>> 3) + (i_r_re_24 >>> 4);
assign i_r_im_14_pos = (i_r_im_14 >>> 1) + (i_r_im_14 >>> 3) + (i_r_im_14 >>> 4);
assign i_r_re_14_pos = (i_r_re_14 >>> 1) + (i_r_re_14 >>> 3) + (i_r_re_14 >>> 4);
assign i_r_re_33_pos = (i_r_re_33 >>> 1) + (i_r_re_33 >>> 3) + (i_r_re_33 >>> 4);
assign i_r_im_23_pos = (i_r_im_23 >>> 1) + (i_r_im_23 >>> 3) + (i_r_im_23 >>> 4);
assign i_r_re_23_pos = (i_r_re_23 >>> 1) + (i_r_re_23 >>> 3) + (i_r_re_23 >>> 4);
assign i_r_im_13_pos = (i_r_im_13 >>> 1) + (i_r_im_13 >>> 3) + (i_r_im_13 >>> 4);
assign i_r_re_13_pos = (i_r_re_13 >>> 1) + (i_r_re_13 >>> 3) + (i_r_re_13 >>> 4);
assign i_r_re_22_pos = (i_r_re_22 >>> 1) + (i_r_re_22 >>> 3) + (i_r_re_22 >>> 4);
assign i_r_im_12_pos = (i_r_im_12 >>> 1) + (i_r_im_12 >>> 3) + (i_r_im_12 >>> 4);
assign i_r_re_12_pos = (i_r_re_12 >>> 1) + (i_r_re_12 >>> 3) + (i_r_re_12 >>> 4);
assign i_r_re_11_pos = (i_r_re_11 >>> 1) + (i_r_re_11 >>> 3) + (i_r_re_11 >>> 4);
assign i_r_re_44_neg = (-i_r_re_44 >>> 1) + (-i_r_re_44 >>> 3) + (-i_r_re_44 >>> 4);
assign i_r_im_34_neg = (-i_r_im_34 >>> 1) + (-i_r_im_34 >>> 3) + (-i_r_im_34 >>> 4);
assign i_r_re_34_neg = (-i_r_re_34 >>> 1) + (-i_r_re_34 >>> 3) + (-i_r_re_34 >>> 4);
assign i_r_im_24_neg = (-i_r_im_24 >>> 1) + (-i_r_im_24 >>> 3) + (-i_r_im_24 >>> 4);
assign i_r_re_24_neg = (-i_r_re_24 >>> 1) + (-i_r_re_24 >>> 3) + (-i_r_re_24 >>> 4);
assign i_r_im_14_neg = (-i_r_im_14 >>> 1) + (-i_r_im_14 >>> 3) + (-i_r_im_14 >>> 4);
assign i_r_re_14_neg = (-i_r_re_14 >>> 1) + (-i_r_re_14 >>> 3) + (-i_r_re_14 >>> 4);
assign i_r_re_33_neg = (-i_r_re_33 >>> 1) + (-i_r_re_33 >>> 3) + (-i_r_re_33 >>> 4);
assign i_r_im_23_neg = (-i_r_im_23 >>> 1) + (-i_r_im_23 >>> 3) + (-i_r_im_23 >>> 4);
assign i_r_re_23_neg = (-i_r_re_23 >>> 1) + (-i_r_re_23 >>> 3) + (-i_r_re_23 >>> 4);
assign i_r_im_13_neg = (-i_r_im_13 >>> 1) + (-i_r_im_13 >>> 3) + (-i_r_im_13 >>> 4);
assign i_r_re_13_neg = (-i_r_re_13 >>> 1) + (-i_r_re_13 >>> 3) + (-i_r_re_13 >>> 4);
assign i_r_re_22_neg = (-i_r_re_22 >>> 1) + (-i_r_re_22 >>> 3) + (-i_r_re_22 >>> 4);
assign i_r_im_12_neg = (-i_r_im_12 >>> 1) + (-i_r_im_12 >>> 3) + (-i_r_im_12 >>> 4);
assign i_r_re_12_neg = (-i_r_re_12 >>> 1) + (-i_r_re_12 >>> 3) + (-i_r_re_12 >>> 4);
assign i_r_re_11_neg = (-i_r_re_11 >>> 1) + (-i_r_re_11 >>> 3) + (-i_r_re_11 >>> 4);

// s_choose = 01101100 => s1=+1-1i s2=-1+1i s3=-1-1i s4=+1+1i
// s11/s12 s21/s22 s31/s32 s41/s42
reg [1:0] s_choose;

reg [7:0] s_fianl_1st;
reg [7:0] s_fianl_2nd;
reg [7:0] s_fianl_3rd;
reg [7:0] s_final_temp;
reg [7:0] s_final_temp2;

reg [7:0] s_fianl_1st_p;
reg [7:0] s_fianl_2nd_p;
reg [7:0] s_fianl_3rd_p;
reg [7:0] s_final_temp_p;
reg [7:0] s_final_temp2_p;

reg [3:0] s_cnt_r, s_cnt_w;
reg       comp_cnt;

// COMPUTE
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] s_temp [3:0];
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_1st;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_2nd;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_3rd;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_temp;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_temp2;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] s_temp_p [3:0];
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_1st_p;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_2nd_p;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_3rd_p;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_temp_p;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_temp2_p;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_01;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_02;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_03;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_04;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_05;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_06;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_07;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_08;

reg signed [LENGTH - 1 : 0 ] i_r_01;
reg signed [LENGTH - 1 : 0 ] i_r_02;
reg signed [LENGTH - 1 : 0 ] i_r_03;
reg signed [LENGTH - 1 : 0 ] i_r_04;
reg signed [LENGTH - 1 : 0 ] i_r_05;
reg signed [LENGTH - 1 : 0 ] i_r_06;
reg signed [LENGTH - 1 : 0 ] i_r_07;
reg signed [LENGTH - 1 : 0 ] i_r_08;
reg signed [LENGTH - 1 : 0 ] i_r_09;
reg signed [LENGTH - 1 : 0 ] i_r_10;
reg signed [LENGTH - 1 : 0 ] i_r_11;
reg signed [LENGTH - 1 : 0 ] i_r_12;
reg signed [LENGTH - 1 : 0 ] i_r_13;
reg signed [LENGTH - 1 : 0 ] i_r_14;
reg signed [LENGTH - 1 : 0 ] i_r_15;
reg signed [LENGTH - 1 : 0 ] i_r_16;
reg signed [LENGTH - 1 : 0 ] i_r_17;
reg signed [LENGTH - 1 : 0 ] i_r_18;
reg signed [LENGTH - 1 : 0 ] i_r_19;
reg signed [LENGTH - 1 : 0 ] i_r_20;
reg signed [LENGTH - 1 : 0 ] i_r_21;
reg signed [LENGTH - 1 : 0 ] i_r_22;
reg signed [LENGTH - 1 : 0 ] i_r_23;
reg signed [LENGTH - 1 : 0 ] i_r_24;
reg signed [LENGTH - 1 : 0 ] i_r_25;
reg signed [LENGTH - 1 : 0 ] i_r_26;

reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] s_temp_w [3:0];
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_1st_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_2nd_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] s_temp_p_w [3:0];
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_1st_p_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] min_PED_2nd_p_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_01_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_02_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_03_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_04_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_05_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_06_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_07_w;
reg  [LENGTH_MUL - 1 - TRUNCATION : 0 ] mul_temp_08_w;

reg signed [LENGTH - 1 : 0 ] i_r_01_w;
reg signed [LENGTH - 1 : 0 ] i_r_02_w;
reg signed [LENGTH - 1 : 0 ] i_r_03_w;
reg signed [LENGTH - 1 : 0 ] i_r_04_w;
reg signed [LENGTH - 1 : 0 ] i_r_05_w;
reg signed [LENGTH - 1 : 0 ] i_r_06_w;
reg signed [LENGTH - 1 : 0 ] i_r_07_w;
reg signed [LENGTH - 1 : 0 ] i_r_08_w;
reg signed [LENGTH - 1 : 0 ] i_r_09_w;
reg signed [LENGTH - 1 : 0 ] i_r_10_w;
reg signed [LENGTH - 1 : 0 ] i_r_11_w;
reg signed [LENGTH - 1 : 0 ] i_r_12_w;
reg signed [LENGTH - 1 : 0 ] i_r_13_w;
reg signed [LENGTH - 1 : 0 ] i_r_14_w;
reg signed [LENGTH - 1 : 0 ] i_r_15_w;
reg signed [LENGTH - 1 : 0 ] i_r_16_w;
reg signed [LENGTH - 1 : 0 ] i_r_17_w;
reg signed [LENGTH - 1 : 0 ] i_r_18_w;
reg signed [LENGTH - 1 : 0 ] i_r_19_w;
reg signed [LENGTH - 1 : 0 ] i_r_20_w;
reg signed [LENGTH - 1 : 0 ] i_r_21_w;
reg signed [LENGTH - 1 : 0 ] i_r_22_w;
reg signed [LENGTH - 1 : 0 ] i_r_23_w;
reg signed [LENGTH - 1 : 0 ] i_r_24_w;
reg signed [LENGTH - 1 : 0 ] i_r_25_w;
reg signed [LENGTH - 1 : 0 ] i_r_26_w;

// LLR
wire  [7:0] min111;
wire  [7:0] min110;
wire  [7:0] min121;
wire  [7:0] min120;
wire  [7:0] min211;
wire  [7:0] min210;
wire  [7:0] min221;
wire  [7:0] min220;
wire  [7:0] min311;
wire  [7:0] min310;
wire  [7:0] min321;
wire  [7:0] min320;
wire  [7:0] min411;
wire  [7:0] min410;
wire  [7:0] min421;
wire  [7:0] min420;

// OUTPUT
reg [ 7:0] i_cnt;
reg	[ 7:0] o_LLR [135:0];
reg [ 7:0] o_cnt;
reg [ 7:0] o_cnt_r;
reg        rd_vld;   

// FSM
always @(*) begin
    state_nxt = state;
    s_cnt_w = s_cnt_r;
    case (state)
        IDLE:
        begin
            s_cnt_w = 0;
            if(i_trig)
                state_nxt = COMPUTE_s4;
        end
        COMPUTE_s4:
        begin
            if(s_choose == 2'b11)
                state_nxt = COMPUTE_s3_1st;
        end
        COMPUTE_s3_1st:
        begin
            if(s_choose == 2'b11)
            begin
                state_nxt = COMPARE_4to2;
                s_cnt_w = s_cnt_r + 1;
            end
        end
        COMPUTE_s3_2nd:
        begin
            if(s_choose == 2'b11)
            begin
                state_nxt = COMPARE_4to2;
                s_cnt_w = s_cnt_r + 1;
            end
        end
        COMPUTE_s2_1st:
        begin
            if(s_choose == 2'b11)
            begin
                state_nxt = COMPARE_4to2;
                s_cnt_w = s_cnt_r + 1;
            end
        end
        COMPUTE_s2_2nd:
        begin
            if(s_choose == 2'b11)
            begin
                state_nxt = COMPARE_4to2;
                s_cnt_w = s_cnt_r + 1;
            end
        end
        COMPUTE_s2_3rd:
        begin
            if(s_choose == 2'b11)
            begin
                state_nxt = COMPARE_4to2;
                s_cnt_w = s_cnt_r + 1;
            end
        end
        COMPUTE_s1_1st:
        begin
            if(s_choose == 2'b11)
            begin
                state_nxt = COMPARE_4to1;
                s_cnt_w = s_cnt_r + 1;
            end
        end
        COMPUTE_s1_2nd:
        begin
            if(s_choose == 2'b11)
            begin
                state_nxt = COMPARE_4to1;
                s_cnt_w = s_cnt_r + 1;
            end
        end
        COMPUTE_s1_3rd:
        begin
            if(s_choose == 2'b11)
            begin
                state_nxt = COMPARE_4to1;
                s_cnt_w = s_cnt_r + 1;
            end
        end
        COMPARE_4to1:
        begin
            case(s_cnt_r)
                4'b0110:
                    state_nxt = COMPUTE_s1_2nd;
                4'b0111:
                    state_nxt = COMPUTE_s1_3rd;
                4'b1000:
                    state_nxt = COMPARE_3to1;
                default:
                    state_nxt = state;
            endcase
        end
        COMPARE_4to2:
        begin
            case(s_cnt_r)
                4'b0001:
                    state_nxt = COMPUTE_s3_2nd;
                4'b0010:
                    state_nxt = COMPARE;
                4'b0011:
                    state_nxt = COMPUTE_s2_2nd;
                4'b0100:
                    state_nxt = COMPUTE_s2_3rd;
                4'b0101:
                    state_nxt = COMPARE;
                default:
                    state_nxt = state;
            endcase
        end
        COMPARE:
        begin
            if(comp_cnt)
                case(s_cnt_r)
                    4'b0010:
                        state_nxt = COMPUTE_s2_1st;
                    4'b0101:
                        state_nxt = COMPUTE_s1_1st;
                endcase
        end
        COMPARE_3to1:
        begin
            state_nxt = LLR;
        end
        LLR:
        begin
            state_nxt = IDLE;
        end
    endcase    
end

// output_count
always @(*) begin
    o_cnt = o_cnt_r;
    if ((o_cnt_r != i_cnt) && rd_vld && i_rd_rdy)
    begin
        if (o_cnt_r == 135) o_cnt = 0;
		else        o_cnt = o_cnt_r +1;
	end
end

// read i_y_hat and i_r
always @(posedge i_clk or posedge i_reset) begin
	if(i_reset) 
    begin
		i_y_hat_im_4 <= 0;
        i_y_hat_re_4 <= 0;
        i_y_hat_im_3 <= 0;
        i_y_hat_re_3 <= 0;
        i_y_hat_im_2 <= 0;
        i_y_hat_re_2 <= 0;
        i_y_hat_im_1 <= 0;
        i_y_hat_re_1 <= 0;
        i_r_re_44 <= 0;
        i_r_im_34 <= 0;
        i_r_re_34 <= 0;
        i_r_im_24 <= 0;
        i_r_re_24 <= 0;
        i_r_im_14 <= 0;
        i_r_re_14 <= 0;
        i_r_re_33 <= 0;
        i_r_im_23 <= 0;
        i_r_re_23 <= 0;
        i_r_im_13 <= 0;
        i_r_re_13 <= 0;
        i_r_re_22 <= 0;
        i_r_im_12 <= 0;
        i_r_re_12 <= 0;
        i_r_re_11 <= 0;
	end
    else if (i_trig) 
    begin
        i_y_hat_im_4 <= $signed(i_y_hat[159:160 - LENGTH]);
        i_y_hat_re_4 <= $signed(i_y_hat[139:140 - LENGTH]);
        i_y_hat_im_3 <= $signed(i_y_hat[119:120 - LENGTH]);
        i_y_hat_re_3 <= $signed(i_y_hat[ 99:100 - LENGTH]);
        i_y_hat_im_2 <= $signed(i_y_hat[ 79: 80 - LENGTH]);
        i_y_hat_re_2 <= $signed(i_y_hat[ 59: 60 - LENGTH]);
        i_y_hat_im_1 <= $signed(i_y_hat[ 39: 40 - LENGTH]);
        i_y_hat_re_1 <= $signed(i_y_hat[ 19: 20 - LENGTH]);
        i_r_re_44 <= $signed(i_r[319:320 - LENGTH]);
        i_r_im_34 <= $signed(i_r[299:300 - LENGTH]);
        i_r_re_34 <= $signed(i_r[279:280 - LENGTH]);
        i_r_im_24 <= $signed(i_r[259:260 - LENGTH]);
        i_r_re_24 <= $signed(i_r[239:240 - LENGTH]);
        i_r_im_14 <= $signed(i_r[219:220 - LENGTH]);
        i_r_re_14 <= $signed(i_r[199:200 - LENGTH]);
        i_r_re_33 <= $signed(i_r[179:180 - LENGTH]);
        i_r_im_23 <= $signed(i_r[159:160 - LENGTH]);
        i_r_re_23 <= $signed(i_r[139:140 - LENGTH]);
        i_r_im_13 <= $signed(i_r[119:120 - LENGTH]);
        i_r_re_13 <= $signed(i_r[ 99:100 - LENGTH]);
        i_r_re_22 <= $signed(i_r[ 79: 80 - LENGTH]);
        i_r_im_12 <= $signed(i_r[ 59: 60 - LENGTH]);
        i_r_re_12 <= $signed(i_r[ 39: 40 - LENGTH]);
        i_r_re_11 <= $signed(i_r[ 19: 20 - LENGTH]);
    end
end

// Compute Blocking
always@ (*) begin
    s_temp_w[0] = s_temp[0];
    s_temp_w[1] = s_temp[1];
    s_temp_w[2] = s_temp[2];
    s_temp_w[3] = s_temp[3];
    min_PED_1st_w = min_PED_1st;
    min_PED_2nd_w = min_PED_2nd;
    s_temp_p_w[0] = s_temp_p[0];
    s_temp_p_w[1] = s_temp_p[1];
    s_temp_p_w[2] = s_temp_p[2];
    s_temp_p_w[3] = s_temp_p[3];
    min_PED_1st_p_w = min_PED_1st_p;
    min_PED_2nd_p_w = min_PED_2nd_p;
    mul_temp_01_w = mul_temp_01;
    mul_temp_02_w = mul_temp_02;
    mul_temp_03_w = mul_temp_03;
    mul_temp_04_w = mul_temp_04;
    mul_temp_05_w = mul_temp_05;
    mul_temp_06_w = mul_temp_06;
    mul_temp_07_w = mul_temp_07;
    mul_temp_08_w = mul_temp_08;
    i_r_01_w = i_r_01;
    i_r_02_w = i_r_02;
    i_r_03_w = i_r_03;
    i_r_04_w = i_r_04;
    i_r_05_w = i_r_05;
    i_r_06_w = i_r_06;
    i_r_07_w = i_r_07;
    i_r_08_w = i_r_08;
    i_r_09_w = i_r_09;
    i_r_10_w = i_r_10;
    i_r_11_w = i_r_11;
    i_r_12_w = i_r_12;
    i_r_13_w = i_r_13;
    i_r_14_w = i_r_14;
    i_r_15_w = i_r_15;
    i_r_16_w = i_r_16;
    i_r_17_w = i_r_17;
    i_r_18_w = i_r_18;
    i_r_19_w = i_r_19;
    i_r_20_w = i_r_20;
    i_r_21_w = i_r_21;
    i_r_22_w = i_r_22;
    i_r_23_w = i_r_23;
    i_r_24_w = i_r_24;
    i_r_25_w = i_r_25;
    i_r_26_w = i_r_26;

    case (state)
        COMPUTE_s4:
        begin
            case(s_choose)
                2'b00:
                begin
                    i_r_01_w = i_r_re_44_pos;
                    i_r_02_w = i_r_re_44_neg;
                end
                2'b01:
                begin
                    i_r_01_w = i_y_hat_re_4 - i_r_01;
                    i_r_02_w = i_y_hat_im_4 - i_r_01;
                    i_r_03_w = i_y_hat_re_4 - i_r_02;
                    i_r_04_w = i_y_hat_im_4 - i_r_02;
                end
                2'b10:
                begin
                    mul_temp_01_w = trunc(i_r_01 * i_r_01);
                    mul_temp_02_w = trunc(i_r_02 * i_r_02);
                    mul_temp_03_w = trunc(i_r_03 * i_r_03);
                    mul_temp_04_w = trunc(i_r_04 * i_r_04);
                end
                2'b11:
                begin
                    min_PED_1st_w = mul_temp_01 + mul_temp_02;
                    min_PED_2nd_w = mul_temp_01 + mul_temp_04;
                    min_PED_1st_p_w = mul_temp_03 + mul_temp_02;
                    min_PED_2nd_p_w = mul_temp_03 + mul_temp_04;
                end
            endcase
        end
        COMPUTE_s3_1st:
        begin
            case(s_choose)
                2'b00:
                begin
                    i_r_01_w = i_r_re_33_pos;
                    i_r_02_w = i_r_re_33_neg;
                    i_r_03_w = (s_fianl_1st[1])? i_r_re_34_neg : i_r_re_34_pos;
                    i_r_04_w = (s_fianl_1st[0])? i_r_re_34_neg : i_r_re_34_pos;
                    i_r_05_w = (s_fianl_1st_p[1])? i_r_re_34_neg: i_r_re_34_pos;
                    i_r_06_w = (s_fianl_1st_p[0])? i_r_re_34_neg : i_r_re_34_pos;
                    i_r_07_w = (s_fianl_1st[1])? i_r_im_34_neg : i_r_im_34_pos;
                    i_r_08_w = (s_fianl_1st[0])? i_r_im_34_neg : i_r_im_34_pos;
                    i_r_09_w = (s_fianl_1st_p[1])? i_r_im_34_neg: i_r_im_34_pos;
                    i_r_10_w = (s_fianl_1st_p[0])? i_r_im_34_neg : i_r_im_34_pos;
                end
                2'b01:
                begin
                    i_r_01_w = i_y_hat_re_3 - i_r_01 - (i_r_03 - i_r_08);
                    i_r_02_w = i_y_hat_im_3 - i_r_01 - (i_r_04 + i_r_07);
                    i_r_03_w = i_y_hat_re_3 - i_r_02 - (i_r_03 - i_r_08);
                    i_r_04_w = i_y_hat_im_3 - i_r_02 - (i_r_04 + i_r_07);
                    i_r_05_w = i_y_hat_re_3 - i_r_01 - (i_r_05 - i_r_10);
                    i_r_06_w = i_y_hat_im_3 - i_r_01 - (i_r_06 + i_r_09);
                    i_r_07_w = i_y_hat_re_3 - i_r_02 - (i_r_05 - i_r_10);
                    i_r_08_w = i_y_hat_im_3 - i_r_02 - (i_r_06 + i_r_09);
                end
                2'b10:
                begin
                    mul_temp_01_w = trunc(i_r_01 * i_r_01);
                    mul_temp_02_w = trunc(i_r_02 * i_r_02);
                    mul_temp_03_w = trunc(i_r_03 * i_r_03);
                    mul_temp_04_w = trunc(i_r_04 * i_r_04);
                    mul_temp_05_w = trunc(i_r_05 * i_r_05);
                    mul_temp_06_w = trunc(i_r_06 * i_r_06);
                    mul_temp_07_w = trunc(i_r_07 * i_r_07);
                    mul_temp_08_w = trunc(i_r_08 * i_r_08);
                end
                2'b11:
                begin
                    s_temp_w[0] = min_PED_1st + mul_temp_01 + mul_temp_02;
                    s_temp_w[1] = min_PED_1st + mul_temp_01 + mul_temp_04;
                    s_temp_w[2] = min_PED_1st + mul_temp_03 + mul_temp_02;
                    s_temp_w[3] = min_PED_1st + mul_temp_03 + mul_temp_04;
                    s_temp_p_w[0] = min_PED_1st_p + mul_temp_05 + mul_temp_06;
                    s_temp_p_w[1] = min_PED_1st_p + mul_temp_05 + mul_temp_08;
                    s_temp_p_w[2] = min_PED_1st_p + mul_temp_07 + mul_temp_06;
                    s_temp_p_w[3] = min_PED_1st_p + mul_temp_07 + mul_temp_08;
                end
            endcase
        end
        COMPUTE_s3_2nd:
        begin
            case(s_choose)
                2'b00:
                begin
                    i_r_01_w = i_r_re_33_pos;
                    i_r_02_w = i_r_re_33_neg;
                    i_r_03_w = (s_fianl_2nd[1])? i_r_re_34_neg : i_r_re_34_pos;
                    i_r_04_w = (s_fianl_2nd[0])? i_r_re_34_neg : i_r_re_34_pos;
                    i_r_05_w = (s_fianl_2nd_p[1])? i_r_re_34_neg: i_r_re_34_pos;
                    i_r_06_w = (s_fianl_2nd_p[0])? i_r_re_34_neg : i_r_re_34_pos;
                    i_r_07_w = (s_fianl_2nd[1])? i_r_im_34_neg : i_r_im_34_pos;
                    i_r_08_w = (s_fianl_2nd[0])? i_r_im_34_neg : i_r_im_34_pos;
                    i_r_09_w = (s_fianl_2nd_p[1])? i_r_im_34_neg: i_r_im_34_pos;
                    i_r_10_w = (s_fianl_2nd_p[0])? i_r_im_34_neg : i_r_im_34_pos;
                end
                2'b01:
                begin
                    i_r_01_w = i_y_hat_re_3 - i_r_01 - (i_r_03 - i_r_08);
                    i_r_02_w = i_y_hat_im_3 - i_r_01 - (i_r_04 + i_r_07);
                    i_r_03_w = i_y_hat_re_3 - i_r_02 - (i_r_03 - i_r_08);
                    i_r_04_w = i_y_hat_im_3 - i_r_02 - (i_r_04 + i_r_07);
                    i_r_05_w = i_y_hat_re_3 - i_r_01 - (i_r_05 - i_r_10);
                    i_r_06_w = i_y_hat_im_3 - i_r_01 - (i_r_06 + i_r_09);
                    i_r_07_w = i_y_hat_re_3 - i_r_02 - (i_r_05 - i_r_10);
                    i_r_08_w = i_y_hat_im_3 - i_r_02 - (i_r_06 + i_r_09);
                end
                2'b10:
                begin
                    mul_temp_01_w = trunc(i_r_01 * i_r_01);
                    mul_temp_02_w = trunc(i_r_02 * i_r_02);
                    mul_temp_03_w = trunc(i_r_03 * i_r_03);
                    mul_temp_04_w = trunc(i_r_04 * i_r_04);
                    mul_temp_05_w = trunc(i_r_05 * i_r_05);
                    mul_temp_06_w = trunc(i_r_06 * i_r_06);
                    mul_temp_07_w = trunc(i_r_07 * i_r_07);
                    mul_temp_08_w = trunc(i_r_08 * i_r_08);
                end
                2'b11:
                begin
                    s_temp_w[0] = min_PED_2nd + mul_temp_01 + mul_temp_02;
                    s_temp_w[1] = min_PED_2nd + mul_temp_01 + mul_temp_04;
                    s_temp_w[2] = min_PED_2nd + mul_temp_03 + mul_temp_02;
                    s_temp_w[3] = min_PED_2nd + mul_temp_03 + mul_temp_04;
                    s_temp_p_w[0] = min_PED_2nd_p + mul_temp_05 + mul_temp_06;
                    s_temp_p_w[1] = min_PED_2nd_p + mul_temp_05 + mul_temp_08;
                    s_temp_p_w[2] = min_PED_2nd_p + mul_temp_07 + mul_temp_06;
                    s_temp_p_w[3] = min_PED_2nd_p + mul_temp_07 + mul_temp_08;
                end
            endcase
        end
        COMPUTE_s2_1st:
        begin
            case(s_choose)
                2'b00:
                begin
                    i_r_01_w = i_r_re_22_pos;
                    i_r_02_w = i_r_re_22_neg;
                    i_r_03_w = (s_fianl_1st[1])? i_r_re_24_neg : i_r_re_24_pos;
                    i_r_04_w = (s_fianl_1st[0])? i_r_re_24_neg : i_r_re_24_pos;
                    i_r_05_w = (s_fianl_1st_p[1])? i_r_re_24_neg: i_r_re_24_pos;
                    i_r_06_w = (s_fianl_1st_p[0])? i_r_re_24_neg : i_r_re_24_pos;
                    i_r_07_w = (s_fianl_1st[1])? i_r_im_24_neg : i_r_im_24_pos;
                    i_r_08_w = (s_fianl_1st[0])? i_r_im_24_neg : i_r_im_24_pos;
                    i_r_09_w = (s_fianl_1st_p[1])? i_r_im_24_neg: i_r_im_24_pos;
                    i_r_10_w = (s_fianl_1st_p[0])? i_r_im_24_neg : i_r_im_24_pos;

                    i_r_11_w = (s_fianl_1st[3])? i_r_re_23_neg : i_r_re_23_pos;
                    i_r_12_w = (s_fianl_1st[2])? i_r_re_23_neg : i_r_re_23_pos;
                    i_r_13_w = (s_fianl_1st_p[3])? i_r_re_23_neg: i_r_re_23_pos;
                    i_r_14_w = (s_fianl_1st_p[2])? i_r_re_23_neg : i_r_re_23_pos;
                    i_r_15_w = (s_fianl_1st[3])? i_r_im_23_neg : i_r_im_23_pos;
                    i_r_16_w = (s_fianl_1st[2])? i_r_im_23_neg : i_r_im_23_pos;
                    i_r_17_w = (s_fianl_1st_p[3])? i_r_im_23_neg: i_r_im_23_pos;
                    i_r_18_w = (s_fianl_1st_p[2])? i_r_im_23_neg : i_r_im_23_pos;
                end
                2'b01:
                begin
                    i_r_01_w = i_y_hat_re_2 - i_r_01 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16);
                    i_r_02_w = i_y_hat_im_2 - i_r_01 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15);
                    i_r_03_w = i_y_hat_re_2 - i_r_02 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16);
                    i_r_04_w = i_y_hat_im_2 - i_r_02 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15);
                    i_r_05_w = i_y_hat_re_2 - i_r_01 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18);
                    i_r_06_w = i_y_hat_im_2 - i_r_01 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17);
                    i_r_07_w = i_y_hat_re_2 - i_r_02 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18);
                    i_r_08_w = i_y_hat_im_2 - i_r_02 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17);
                end
                2'b10:
                begin
                    mul_temp_01_w = trunc(i_r_01 * i_r_01);
                    mul_temp_02_w = trunc(i_r_02 * i_r_02);
                    mul_temp_03_w = trunc(i_r_03 * i_r_03);
                    mul_temp_04_w = trunc(i_r_04 * i_r_04);
                    mul_temp_05_w = trunc(i_r_05 * i_r_05);
                    mul_temp_06_w = trunc(i_r_06 * i_r_06);
                    mul_temp_07_w = trunc(i_r_07 * i_r_07);
                    mul_temp_08_w = trunc(i_r_08 * i_r_08);
                end
                2'b11:
                begin
                    s_temp_w[0] = min_PED_1st + mul_temp_01 + mul_temp_02;
                    s_temp_w[1] = min_PED_1st + mul_temp_01 + mul_temp_04;
                    s_temp_w[2] = min_PED_1st + mul_temp_03 + mul_temp_02;
                    s_temp_w[3] = min_PED_1st + mul_temp_03 + mul_temp_04;
                    s_temp_p_w[0] = min_PED_1st_p + mul_temp_05 + mul_temp_06;
                    s_temp_p_w[1] = min_PED_1st_p + mul_temp_05 + mul_temp_08;
                    s_temp_p_w[2] = min_PED_1st_p + mul_temp_07 + mul_temp_06;
                    s_temp_p_w[3] = min_PED_1st_p + mul_temp_07 + mul_temp_08;
                end
            endcase
        end
        COMPUTE_s2_2nd:
        begin
            case(s_choose)
                2'b00:
                begin
                    i_r_01_w= i_r_re_22_pos;
                    i_r_02_w= i_r_re_22_neg;
                    i_r_03_w= (s_fianl_2nd[1])? i_r_re_24_neg : i_r_re_24_pos;
                    i_r_04_w= (s_fianl_2nd[0])? i_r_re_24_neg : i_r_re_24_pos;
                    i_r_05_w= (s_fianl_2nd_p[1])? i_r_re_24_neg: i_r_re_24_pos;
                    i_r_06_w= (s_fianl_2nd_p[0])? i_r_re_24_neg : i_r_re_24_pos;
                    i_r_07_w= (s_fianl_2nd[1])? i_r_im_24_neg : i_r_im_24_pos;
                    i_r_08_w= (s_fianl_2nd[0])? i_r_im_24_neg : i_r_im_24_pos;
                    i_r_09_w= (s_fianl_2nd_p[1])? i_r_im_24_neg: i_r_im_24_pos;
                    i_r_10_w= (s_fianl_2nd_p[0])? i_r_im_24_neg : i_r_im_24_pos;
                    i_r_11_w= (s_fianl_2nd[3])? i_r_re_23_neg : i_r_re_23_pos;
                    i_r_12_w= (s_fianl_2nd[2])? i_r_re_23_neg : i_r_re_23_pos;
                    i_r_13_w= (s_fianl_2nd_p[3])? i_r_re_23_neg: i_r_re_23_pos;
                    i_r_14_w= (s_fianl_2nd_p[2])? i_r_re_23_neg : i_r_re_23_pos;
                    i_r_15_w= (s_fianl_2nd[3])? i_r_im_23_neg : i_r_im_23_pos;
                    i_r_16_w= (s_fianl_2nd[2])? i_r_im_23_neg : i_r_im_23_pos;
                    i_r_17_w= (s_fianl_2nd_p[3])? i_r_im_23_neg: i_r_im_23_pos;
                    i_r_18_w= (s_fianl_2nd_p[2])? i_r_im_23_neg : i_r_im_23_pos;
                end
                2'b01:
                begin
                    i_r_01_w = i_y_hat_re_2 - i_r_01 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16);
                    i_r_02_w = i_y_hat_im_2 - i_r_01 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15);
                    i_r_03_w = i_y_hat_re_2 - i_r_02 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16);
                    i_r_04_w = i_y_hat_im_2 - i_r_02 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15);
                    i_r_05_w = i_y_hat_re_2 - i_r_01 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18);
                    i_r_06_w = i_y_hat_im_2 - i_r_01 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17);
                    i_r_07_w = i_y_hat_re_2 - i_r_02 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18);
                    i_r_08_w = i_y_hat_im_2 - i_r_02 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17);
                end
                2'b10:
                begin
                    mul_temp_01_w = trunc(i_r_01 * i_r_01);
                    mul_temp_02_w = trunc(i_r_02 * i_r_02);
                    mul_temp_03_w = trunc(i_r_03 * i_r_03);
                    mul_temp_04_w = trunc(i_r_04 * i_r_04);
                    mul_temp_05_w = trunc(i_r_05 * i_r_05);
                    mul_temp_06_w = trunc(i_r_06 * i_r_06);
                    mul_temp_07_w = trunc(i_r_07 * i_r_07);
                    mul_temp_08_w = trunc(i_r_08 * i_r_08);
                end
                2'b11:
                begin
                    s_temp_w[0] = min_PED_2nd + mul_temp_01 + mul_temp_02;
                    s_temp_w[1] = min_PED_2nd + mul_temp_01 + mul_temp_04;
                    s_temp_w[2] = min_PED_2nd + mul_temp_03 + mul_temp_02;
                    s_temp_w[3] = min_PED_2nd + mul_temp_03 + mul_temp_04;
                    s_temp_p_w[0] = min_PED_2nd_p + mul_temp_05 + mul_temp_06;
                    s_temp_p_w[1] = min_PED_2nd_p + mul_temp_05 + mul_temp_08;
                    s_temp_p_w[2] = min_PED_2nd_p + mul_temp_07 + mul_temp_06;
                    s_temp_p_w[3] = min_PED_2nd_p + mul_temp_07 + mul_temp_08;
                end
            endcase
        end
        COMPUTE_s2_3rd:
        begin
            case(s_choose)
                2'b00:
                begin
                    i_r_01_w= i_r_re_22_pos;
                    i_r_02_w= i_r_re_22_neg;
                    i_r_03_w= (s_fianl_3rd[1])? i_r_re_24_neg : i_r_re_24_pos;
                    i_r_04_w= (s_fianl_3rd[0])? i_r_re_24_neg : i_r_re_24_pos;
                    i_r_05_w= (s_fianl_3rd_p[1])? i_r_re_24_neg: i_r_re_24_pos;
                    i_r_06_w= (s_fianl_3rd_p[0])? i_r_re_24_neg : i_r_re_24_pos;
                    i_r_07_w= (s_fianl_3rd[1])? i_r_im_24_neg : i_r_im_24_pos;
                    i_r_08_w= (s_fianl_3rd[0])? i_r_im_24_neg : i_r_im_24_pos;
                    i_r_09_w= (s_fianl_3rd_p[1])? i_r_im_24_neg: i_r_im_24_pos;
                    i_r_10_w= (s_fianl_3rd_p[0])? i_r_im_24_neg : i_r_im_24_pos;
                    i_r_11_w= (s_fianl_3rd[3])? i_r_re_23_neg : i_r_re_23_pos;
                    i_r_12_w= (s_fianl_3rd[2])? i_r_re_23_neg : i_r_re_23_pos;
                    i_r_13_w= (s_fianl_3rd_p[3])? i_r_re_23_neg: i_r_re_23_pos;
                    i_r_14_w= (s_fianl_3rd_p[2])? i_r_re_23_neg : i_r_re_23_pos;
                    i_r_15_w= (s_fianl_3rd[3])? i_r_im_23_neg : i_r_im_23_pos;
                    i_r_16_w= (s_fianl_3rd[2])? i_r_im_23_neg : i_r_im_23_pos;
                    i_r_17_w= (s_fianl_3rd_p[3])? i_r_im_23_neg: i_r_im_23_pos;
                    i_r_18_w= (s_fianl_3rd_p[2])? i_r_im_23_neg : i_r_im_23_pos;
                end
                2'b01:
                begin
                    i_r_01_w = i_y_hat_re_2 - i_r_01 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16);
                    i_r_02_w = i_y_hat_im_2 - i_r_01 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15);
                    i_r_03_w = i_y_hat_re_2 - i_r_02 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16);
                    i_r_04_w = i_y_hat_im_2 - i_r_02 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15);
                    i_r_05_w = i_y_hat_re_2 - i_r_01 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18);
                    i_r_06_w = i_y_hat_im_2 - i_r_01 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17);
                    i_r_07_w = i_y_hat_re_2 - i_r_02 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18);
                    i_r_08_w = i_y_hat_im_2 - i_r_02 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17);
                end
                2'b10:
                begin
                    mul_temp_01_w = trunc(i_r_01 * i_r_01);
                    mul_temp_02_w = trunc(i_r_02 * i_r_02);
                    mul_temp_03_w = trunc(i_r_03 * i_r_03);
                    mul_temp_04_w = trunc(i_r_04 * i_r_04);
                    mul_temp_05_w = trunc(i_r_05 * i_r_05);
                    mul_temp_06_w = trunc(i_r_06 * i_r_06);
                    mul_temp_07_w = trunc(i_r_07 * i_r_07);
                    mul_temp_08_w = trunc(i_r_08 * i_r_08);
                end
                2'b11:
                begin
                    s_temp_w[0] = min_PED_3rd + mul_temp_01 + mul_temp_02;
                    s_temp_w[1] = min_PED_3rd + mul_temp_01 + mul_temp_04;
                    s_temp_w[2] = min_PED_3rd + mul_temp_03 + mul_temp_02;
                    s_temp_w[3] = min_PED_3rd + mul_temp_03 + mul_temp_04;
                    s_temp_p_w[0] = min_PED_3rd_p + mul_temp_05 + mul_temp_06;
                    s_temp_p_w[1] = min_PED_3rd_p + mul_temp_05 + mul_temp_08;
                    s_temp_p_w[2] = min_PED_3rd_p + mul_temp_07 + mul_temp_06;
                    s_temp_p_w[3] = min_PED_3rd_p + mul_temp_07 + mul_temp_08;
                end
            endcase
        end
        COMPUTE_s1_1st:
        begin
            case(s_choose)
                2'b00:
                begin
                    i_r_01_w = i_r_re_11_pos;
                    i_r_02_w = i_r_re_11_neg;
                    i_r_03_w = (s_fianl_1st[1])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_04_w = (s_fianl_1st[0])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_05_w = (s_fianl_1st_p[1])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_06_w = (s_fianl_1st_p[0])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_07_w = (s_fianl_1st[1])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_08_w = (s_fianl_1st[0])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_09_w = (s_fianl_1st_p[1])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_10_w = (s_fianl_1st_p[0])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_11_w = (s_fianl_1st[3])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_12_w = (s_fianl_1st[2])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_13_w = (s_fianl_1st_p[3])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_14_w = (s_fianl_1st_p[2])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_15_w = (s_fianl_1st[3])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_16_w = (s_fianl_1st[2])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_17_w = (s_fianl_1st_p[3])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_18_w = (s_fianl_1st_p[2])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_19_w = (s_fianl_1st[5])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_20_w = (s_fianl_1st[4])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_21_w = (s_fianl_1st_p[5])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_22_w = (s_fianl_1st_p[4])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_23_w = (s_fianl_1st[5])? i_r_im_12_neg : i_r_im_12_pos;
                    i_r_24_w = (s_fianl_1st[4])? i_r_im_12_neg : i_r_im_12_pos;
                    i_r_25_w = (s_fianl_1st_p[5])? i_r_im_12_neg : i_r_im_12_pos;
                    i_r_26_w = (s_fianl_1st_p[4])? i_r_im_12_neg : i_r_im_12_pos;
                end
                2'b01:
                begin
                    i_r_01_w = i_y_hat_re_1 - i_r_01 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16) - (i_r_19 - i_r_24);
                    i_r_02_w = i_y_hat_im_1 - i_r_01 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15) - (i_r_20 + i_r_23);
                    i_r_03_w = i_y_hat_re_1 - i_r_02 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16) - (i_r_19 - i_r_24);
                    i_r_04_w = i_y_hat_im_1 - i_r_02 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15) - (i_r_20 + i_r_23);
                    i_r_05_w = i_y_hat_re_1 - i_r_01 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18) - (i_r_21 - i_r_26);
                    i_r_06_w = i_y_hat_im_1 - i_r_01 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17) - (i_r_22 + i_r_25);
                    i_r_07_w = i_y_hat_re_1 - i_r_02 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18) - (i_r_21 - i_r_26);
                    i_r_08_w = i_y_hat_im_1 - i_r_02 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17) - (i_r_22 + i_r_25);
                end
                2'b10:
                begin
                    mul_temp_01_w = trunc(i_r_01 * i_r_01);
                    mul_temp_02_w = trunc(i_r_02 * i_r_02);
                    mul_temp_03_w = trunc(i_r_03 * i_r_03);
                    mul_temp_04_w = trunc(i_r_04 * i_r_04);
                    mul_temp_05_w = trunc(i_r_05 * i_r_05);
                    mul_temp_06_w = trunc(i_r_06 * i_r_06);
                    mul_temp_07_w = trunc(i_r_07 * i_r_07);
                    mul_temp_08_w = trunc(i_r_08 * i_r_08);
                end
                2'b11:
                begin
                    s_temp_w[0] = min_PED_1st + mul_temp_01 + mul_temp_02;
                    s_temp_w[1] = min_PED_1st + mul_temp_01 + mul_temp_04;
                    s_temp_w[2] = min_PED_1st + mul_temp_03 + mul_temp_02;
                    s_temp_w[3] = min_PED_1st + mul_temp_03 + mul_temp_04;
                    s_temp_p_w[0] = min_PED_1st_p + mul_temp_05 + mul_temp_06;
                    s_temp_p_w[1] = min_PED_1st_p + mul_temp_05 + mul_temp_08;
                    s_temp_p_w[2] = min_PED_1st_p + mul_temp_07 + mul_temp_06;
                    s_temp_p_w[3] = min_PED_1st_p + mul_temp_07 + mul_temp_08;
                end
            endcase
        end
        COMPUTE_s1_2nd:
        begin
            case(s_choose)
                2'b00:
                begin
                    i_r_01_w = i_r_re_11_pos;
                    i_r_02_w = i_r_re_11_neg;
                    i_r_03_w = (s_fianl_2nd[1])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_04_w = (s_fianl_2nd[0])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_05_w = (s_fianl_2nd_p[1])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_06_w = (s_fianl_2nd_p[0])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_07_w = (s_fianl_2nd[1])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_08_w = (s_fianl_2nd[0])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_09_w = (s_fianl_2nd_p[1])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_10_w = (s_fianl_2nd_p[0])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_11_w = (s_fianl_2nd[3])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_12_w = (s_fianl_2nd[2])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_13_w = (s_fianl_2nd_p[3])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_14_w = (s_fianl_2nd_p[2])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_15_w = (s_fianl_2nd[3])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_16_w = (s_fianl_2nd[2])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_17_w = (s_fianl_2nd_p[3])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_18_w = (s_fianl_2nd_p[2])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_19_w = (s_fianl_2nd[5])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_20_w = (s_fianl_2nd[4])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_21_w = (s_fianl_2nd_p[5])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_22_w = (s_fianl_2nd_p[4])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_23_w = (s_fianl_2nd[5])? i_r_im_12_neg : i_r_im_12_pos;
                    i_r_24_w = (s_fianl_2nd[4])? i_r_im_12_neg : i_r_im_12_pos;
                    i_r_25_w = (s_fianl_2nd_p[5])? i_r_im_12_neg : i_r_im_12_pos;
                    i_r_26_w = (s_fianl_2nd_p[4])? i_r_im_12_neg : i_r_im_12_pos;
                end
                2'b01:
                begin
                    i_r_01_w = i_y_hat_re_1 - i_r_01 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16) - (i_r_19 - i_r_24);
                    i_r_02_w = i_y_hat_im_1 - i_r_01 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15) - (i_r_20 + i_r_23);
                    i_r_03_w = i_y_hat_re_1 - i_r_02 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16) - (i_r_19 - i_r_24);
                    i_r_04_w = i_y_hat_im_1 - i_r_02 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15) - (i_r_20 + i_r_23);
                    i_r_05_w = i_y_hat_re_1 - i_r_01 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18) - (i_r_21 - i_r_26);
                    i_r_06_w = i_y_hat_im_1 - i_r_01 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17) - (i_r_22 + i_r_25);
                    i_r_07_w = i_y_hat_re_1 - i_r_02 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18) - (i_r_21 - i_r_26);
                    i_r_08_w = i_y_hat_im_1 - i_r_02 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17) - (i_r_22 + i_r_25);
                end
                2'b10:
                begin
                    mul_temp_01_w = trunc(i_r_01 * i_r_01);
                    mul_temp_02_w = trunc(i_r_02 * i_r_02);
                    mul_temp_03_w = trunc(i_r_03 * i_r_03);
                    mul_temp_04_w = trunc(i_r_04 * i_r_04);
                    mul_temp_05_w = trunc(i_r_05 * i_r_05);
                    mul_temp_06_w = trunc(i_r_06 * i_r_06);
                    mul_temp_07_w = trunc(i_r_07 * i_r_07);
                    mul_temp_08_w = trunc(i_r_08 * i_r_08);
                end
                2'b11:
                begin
                    s_temp_w[0] = min_PED_2nd + mul_temp_01 + mul_temp_02;
                    s_temp_w[1] = min_PED_2nd + mul_temp_01 + mul_temp_04;
                    s_temp_w[2] = min_PED_2nd + mul_temp_03 + mul_temp_02;
                    s_temp_w[3] = min_PED_2nd + mul_temp_03 + mul_temp_04;
                    s_temp_p_w[0] = min_PED_2nd_p + mul_temp_05 + mul_temp_06;
                    s_temp_p_w[1] = min_PED_2nd_p + mul_temp_05 + mul_temp_08;
                    s_temp_p_w[2] = min_PED_2nd_p + mul_temp_07 + mul_temp_06;
                    s_temp_p_w[3] = min_PED_2nd_p + mul_temp_07 + mul_temp_08;
                end
            endcase
        end
        COMPUTE_s1_3rd:
        begin
            case(s_choose)
                2'b00:
                begin
                    i_r_01_w = i_r_re_11_pos;
                    i_r_02_w = i_r_re_11_neg;
                    i_r_03_w = (s_fianl_3rd[1])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_04_w = (s_fianl_3rd[0])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_05_w = (s_fianl_3rd_p[1])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_06_w = (s_fianl_3rd_p[0])? i_r_re_14_neg : i_r_re_14_pos;
                    i_r_07_w = (s_fianl_3rd[1])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_08_w = (s_fianl_3rd[0])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_09_w = (s_fianl_3rd_p[1])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_10_w = (s_fianl_3rd_p[0])? i_r_im_14_neg : i_r_im_14_pos;
                    i_r_11_w = (s_fianl_3rd[3])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_12_w = (s_fianl_3rd[2])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_13_w = (s_fianl_3rd_p[3])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_14_w = (s_fianl_3rd_p[2])? i_r_re_13_neg : i_r_re_13_pos;
                    i_r_15_w = (s_fianl_3rd[3])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_16_w = (s_fianl_3rd[2])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_17_w = (s_fianl_3rd_p[3])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_18_w = (s_fianl_3rd_p[2])? i_r_im_13_neg : i_r_im_13_pos;
                    i_r_19_w = (s_fianl_3rd[5])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_20_w = (s_fianl_3rd[4])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_21_w = (s_fianl_3rd_p[5])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_22_w = (s_fianl_3rd_p[4])? i_r_re_12_neg : i_r_re_12_pos;
                    i_r_23_w = (s_fianl_3rd[5])? i_r_im_12_neg : i_r_im_12_pos;
                    i_r_24_w = (s_fianl_3rd[4])? i_r_im_12_neg : i_r_im_12_pos;
                    i_r_25_w = (s_fianl_3rd_p[5])? i_r_im_12_neg : i_r_im_12_pos;
                    i_r_26_w = (s_fianl_3rd_p[4])? i_r_im_12_neg : i_r_im_12_pos;
                end
                2'b01:
                begin
                    i_r_01_w = i_y_hat_re_1 - i_r_01 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16) - (i_r_19 - i_r_24);
                    i_r_02_w = i_y_hat_im_1 - i_r_01 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15) - (i_r_20 + i_r_23);
                    i_r_03_w = i_y_hat_re_1 - i_r_02 - (i_r_03 - i_r_08) - (i_r_11 - i_r_16) - (i_r_19 - i_r_24);
                    i_r_04_w = i_y_hat_im_1 - i_r_02 - (i_r_04 + i_r_07) - (i_r_12 + i_r_15) - (i_r_20 + i_r_23);
                    i_r_05_w = i_y_hat_re_1 - i_r_01 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18) - (i_r_21 - i_r_26);
                    i_r_06_w = i_y_hat_im_1 - i_r_01 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17) - (i_r_22 + i_r_25);
                    i_r_07_w = i_y_hat_re_1 - i_r_02 - (i_r_05 - i_r_10) - (i_r_13 - i_r_18) - (i_r_21 - i_r_26);
                    i_r_08_w = i_y_hat_im_1 - i_r_02 - (i_r_06 + i_r_09) - (i_r_14 + i_r_17) - (i_r_22 + i_r_25);
                end
                2'b10:
                begin
                    mul_temp_01_w = trunc(i_r_01 * i_r_01);
                    mul_temp_02_w = trunc(i_r_02 * i_r_02);
                    mul_temp_03_w = trunc(i_r_03 * i_r_03);
                    mul_temp_04_w = trunc(i_r_04 * i_r_04);
                    mul_temp_05_w = trunc(i_r_05 * i_r_05);
                    mul_temp_06_w = trunc(i_r_06 * i_r_06);
                    mul_temp_07_w = trunc(i_r_07 * i_r_07);
                    mul_temp_08_w = trunc(i_r_08 * i_r_08);
                end
                2'b11:
                begin
                    s_temp_w[0] = min_PED_3rd + mul_temp_01 + mul_temp_02;
                    s_temp_w[1] = min_PED_3rd + mul_temp_01 + mul_temp_04;
                    s_temp_w[2] = min_PED_3rd + mul_temp_03 + mul_temp_02;
                    s_temp_w[3] = min_PED_3rd + mul_temp_03 + mul_temp_04;
                    s_temp_p_w[0] = min_PED_3rd_p + mul_temp_05 + mul_temp_06;
                    s_temp_p_w[1] = min_PED_3rd_p + mul_temp_05 + mul_temp_08;
                    s_temp_p_w[2] = min_PED_3rd_p + mul_temp_07 + mul_temp_06;
                    s_temp_p_w[3] = min_PED_3rd_p + mul_temp_07 + mul_temp_08;
                end
            endcase
        end  
    endcase    
end

always @(posedge i_clk or posedge i_reset) begin
	if(i_reset) 
    begin
        for(i=0;i<4;i=i+1)
        begin
            s_temp[i] <= 0;
        end
        s_choose    <= 0;
        s_fianl_1st <= 0;
        s_fianl_2nd <= 0;
        s_fianl_3rd <= 0;
        s_final_temp<= 0;
        s_final_temp2<= 0;
        min_PED_1st <= 0;
        min_PED_2nd <= 0;
        min_PED_3rd <= 0;
        min_PED_temp<= 0;
        min_PED_temp2<= 0;
        s_fianl_1st_p <= 0;
        s_fianl_2nd_p <= 0;
        s_fianl_3rd_p <= 0;
        s_final_temp_p<= 0;
        s_final_temp2_p<= 0;
        min_PED_1st_p <= 0;
        min_PED_2nd_p <= 0;
        min_PED_3rd_p <= 0;
        min_PED_temp_p<= 0;
        min_PED_temp2_p<= 0;
        comp_cnt <=0;
        s_temp[0] <= 0;
        s_temp[1] <= 0;
        s_temp[2] <= 0;
        s_temp[3] <= 0;
        min_PED_1st <= 0;
        min_PED_2nd <= 0;
        s_temp_p[0] <= 0;
        s_temp_p[1] <= 0;
        s_temp_p[2] <= 0;
        s_temp_p[3] <= 0;
        min_PED_1st_p <= 0;
        min_PED_2nd_p <= 0;
        mul_temp_01 <= 0;
        mul_temp_02 <= 0;
        mul_temp_03 <= 0;
        mul_temp_04 <= 0;
        mul_temp_05 <= 0;
        mul_temp_06 <= 0;
        mul_temp_07 <= 0;
        mul_temp_08 <= 0;
        i_r_01 <= 0;
        i_r_02 <= 0;
        i_r_03 <= 0;
        i_r_04 <= 0;
        i_r_05 <= 0;
        i_r_06 <= 0;
        i_r_07 <= 0;
        i_r_08 <= 0;
        i_r_09 <= 0;
        i_r_10 <= 0;
        i_r_11 <= 0;
        i_r_12 <= 0;
        i_r_13 <= 0;
        i_r_14 <= 0;
        i_r_15 <= 0;
        i_r_16 <= 0;
        i_r_17 <= 0;
        i_r_18 <= 0;
        i_r_19 <= 0;
        i_r_20 <= 0;
        i_r_21 <= 0;
        i_r_22 <= 0;
        i_r_23 <= 0;
        i_r_24 <= 0;
        i_r_25 <= 0;
        i_r_26 <= 0;
    end
    else if (state == IDLE)
    begin
        for(i=0;i<4;i=i+1)
        begin
            s_temp[i] <= 0;
        end
        s_choose    <= 0;
        s_fianl_1st <= 0;
        s_fianl_2nd <= 0;
        s_fianl_3rd <= 0;
        s_final_temp<= 0;
        s_final_temp2<= 0;
        min_PED_1st <= 0;
        min_PED_2nd <= 0;
        min_PED_3rd <= 0;
        min_PED_temp<= 0;
        min_PED_temp2<= 0;
        s_fianl_1st_p <= 0;
        s_fianl_2nd_p <= 0;
        s_fianl_3rd_p <= 0;
        s_final_temp_p<= 0;
        s_final_temp2_p<= 0;
        min_PED_1st_p <= 0;
        min_PED_2nd_p <= 0;
        min_PED_3rd_p <= 0;
        min_PED_temp_p<= 0;
        min_PED_temp2_p<= 0;
        comp_cnt <=0;
        s_temp[0] <= 0;
        s_temp[1] <= 0;
        s_temp[2] <= 0;
        s_temp[3] <= 0;
        min_PED_1st <= 0;
        min_PED_2nd <= 0;
        s_temp_p[0] <= 0;
        s_temp_p[1] <= 0;
        s_temp_p[2] <= 0;
        s_temp_p[3] <= 0;
        min_PED_1st_p <= 0;
        min_PED_2nd_p <= 0;
        mul_temp_01 <= 0;
        mul_temp_02 <= 0;
        mul_temp_03 <= 0;
        mul_temp_04 <= 0;
        mul_temp_05 <= 0;
        mul_temp_06 <= 0;
        mul_temp_07 <= 0;
        mul_temp_08 <= 0;
        i_r_01 <= 0;
        i_r_02 <= 0;
        i_r_03 <= 0;
        i_r_04 <= 0;
        i_r_05 <= 0;
        i_r_06 <= 0;
        i_r_07 <= 0;
        i_r_08 <= 0;
        i_r_09 <= 0;
        i_r_10 <= 0;
        i_r_11 <= 0;
        i_r_12 <= 0;
        i_r_13 <= 0;
        i_r_14 <= 0;
        i_r_15 <= 0;
        i_r_16 <= 0;
        i_r_17 <= 0;
        i_r_18 <= 0;
        i_r_19 <= 0;
        i_r_20 <= 0;
        i_r_21 <= 0;
        i_r_22 <= 0;
        i_r_23 <= 0;
        i_r_24 <= 0;
        i_r_25 <= 0;
        i_r_26 <= 0;
    end
    else if (state == COMPUTE_s4)
    begin
        case(s_choose)
            2'b00:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                s_fianl_1st <= 8'h00;
            end
            2'b01:
            begin
                i_r_01 <=i_r_01_w ;
                i_r_02 <=i_r_02_w ;
                i_r_03 <=i_r_03_w ;
                i_r_04 <=i_r_04_w ;
                s_fianl_2nd <= 8'h01;
            end
            2'b10:
            begin
                mul_temp_01 <= mul_temp_01_w;
                mul_temp_02 <= mul_temp_02_w;
                mul_temp_03 <= mul_temp_03_w;
                mul_temp_04 <= mul_temp_04_w;
                s_fianl_1st_p <= 8'h02;
            end
            2'b11:
            begin
                min_PED_1st <= min_PED_1st_w;
                min_PED_2nd <= min_PED_2nd_w;
                min_PED_1st_p <= min_PED_1st_p_w;
                min_PED_2nd_p <= min_PED_2nd_p_w;
                s_fianl_2nd_p <= 8'h03;
            end
        endcase
		s_choose <= s_choose + 1;
    end
    else if (state == COMPUTE_s3_1st)
    begin
        case(s_choose)
            2'b00:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
                i_r_09 <= i_r_09_w;
                i_r_10 <= i_r_10_w;
            end
            2'b01:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
            end
            2'b10:
            begin
                mul_temp_01 <= mul_temp_01_w;
                mul_temp_02 <= mul_temp_02_w;
                mul_temp_03 <= mul_temp_03_w;
                mul_temp_04 <= mul_temp_04_w;
                mul_temp_05 <= mul_temp_05_w;
                mul_temp_06 <= mul_temp_06_w;
                mul_temp_07 <= mul_temp_07_w;
                mul_temp_08 <= mul_temp_08_w;
            end
            2'b11:
            begin
                s_temp[0] <= s_temp_w[0];
                s_temp[1] <= s_temp_w[1];
                s_temp[2] <= s_temp_w[2];
                s_temp[3] <= s_temp_w[3];
                s_temp_p[0] <= s_temp_p_w[0];
                s_temp_p[1] <= s_temp_p_w[1];
                s_temp_p[2] <= s_temp_p_w[2];
                s_temp_p[3] <= s_temp_p_w[3];
            end
        endcase
        s_choose <= s_choose + 1;
    end
    else if (state == COMPUTE_s3_2nd)
    begin
	    case(s_choose)
            2'b00:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
                i_r_09 <= i_r_09_w;
                i_r_10 <= i_r_10_w;
            end
            2'b01:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
            end
            2'b10:
            begin
                mul_temp_01 <= mul_temp_01_w;
                mul_temp_02 <= mul_temp_02_w;
                mul_temp_03 <= mul_temp_03_w;
                mul_temp_04 <= mul_temp_04_w;
                mul_temp_05 <= mul_temp_05_w;
                mul_temp_06 <= mul_temp_06_w;
                mul_temp_07 <= mul_temp_07_w;
                mul_temp_08 <= mul_temp_08_w;
            end
            2'b11:
            begin
                s_temp[0] <= s_temp_w[0];
                s_temp[1] <= s_temp_w[1];
                s_temp[2] <= s_temp_w[2];
                s_temp[3] <= s_temp_w[3];
                s_temp_p[0] <= s_temp_p_w[0];
                s_temp_p[1] <= s_temp_p_w[1];
                s_temp_p[2] <= s_temp_p_w[2];
                s_temp_p[3] <= s_temp_p_w[3];
            end
        endcase
        s_choose <= s_choose + 1;
    end
    else if (state == COMPARE_4to1)
    begin
        case(s_cnt_r)
            4'b0110:
            begin
                if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                begin
                    min_PED_1st <= s_temp[0];
                    s_fianl_1st <= {{2'b00},s_fianl_1st[5:0]};
                end
                else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                begin
                    min_PED_1st <= s_temp[1];
                    s_fianl_1st <= {{2'b01},s_fianl_1st[5:0]};
                end
                else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                begin
                    min_PED_1st <= s_temp[2];
                    s_fianl_1st <= {{2'b10},s_fianl_1st[5:0]};
                end
                else
                begin
                    min_PED_1st <= s_temp[3];
                    s_fianl_1st <= {{2'b11},s_fianl_1st[5:0]};
                end

                if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                begin
                    min_PED_1st_p <= s_temp_p[0];
                    s_fianl_1st_p <= {{2'b00},s_fianl_1st_p[5:0]};
                end
                else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                begin
                    min_PED_1st_p <= s_temp_p[1];
                    s_fianl_1st_p <= {{2'b01},s_fianl_1st_p[5:0]};
                end
                else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                begin
                    min_PED_1st_p <= s_temp_p[2];
                    s_fianl_1st_p <= {{2'b10},s_fianl_1st_p[5:0]};
                end
                else
                begin
                    min_PED_1st_p <= s_temp_p[3];
                    s_fianl_1st_p <= {{2'b11},s_fianl_1st_p[5:0]};
                end
            end
            4'b0111:
            begin
                if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                begin
                    min_PED_2nd <= s_temp[0];
                    s_fianl_2nd <= {{2'b00},s_fianl_2nd[5:0]};
                end
                else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                begin
                    min_PED_2nd <= s_temp[1];
                    s_fianl_2nd <= {{2'b01},s_fianl_2nd[5:0]};
                end
                else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                begin
                    min_PED_2nd <= s_temp[2];
                    s_fianl_2nd <= {{2'b10},s_fianl_2nd[5:0]};
                end
                else
                begin
                    min_PED_2nd <= s_temp[3];
                    s_fianl_2nd <= {{2'b11},s_fianl_2nd[5:0]};
                end

                if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                begin
                    min_PED_2nd_p <= s_temp_p[0];
                    s_fianl_2nd_p <= {{2'b00},s_fianl_2nd_p[5:0]};
                end
                else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                begin
                    min_PED_2nd_p <= s_temp_p[1];
                    s_fianl_2nd_p <= {{2'b01},s_fianl_2nd_p[5:0]};
                end
                else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                begin
                    min_PED_2nd_p <= s_temp_p[2];
                    s_fianl_2nd_p <= {{2'b10},s_fianl_2nd_p[5:0]};
                end
                else
                begin
                    min_PED_2nd_p <= s_temp_p[3];
                    s_fianl_2nd_p <= {{2'b11},s_fianl_2nd_p[5:0]};
                end
            end
            4'b1000:
            begin
                if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                begin
                    min_PED_3rd <= s_temp[0];
                    s_fianl_3rd <= {{2'b00},s_fianl_3rd[5:0]};
                end
                else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                begin
                    min_PED_3rd <= s_temp[1];
                    s_fianl_3rd <= {{2'b01},s_fianl_3rd[5:0]};
                end
                else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                begin
                    min_PED_3rd <= s_temp[2];
                    s_fianl_3rd <= {{2'b10},s_fianl_3rd[5:0]};
                end
                else
                begin
                    min_PED_3rd <= s_temp[3];
                    s_fianl_3rd <= {{2'b11},s_fianl_3rd[5:0]};
                end

                if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                begin
                    min_PED_3rd_p <= s_temp_p[0];
                    s_fianl_3rd_p <= {{2'b00},s_fianl_3rd_p[5:0]};
                end
                else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                begin
                    min_PED_3rd_p <= s_temp_p[1];
                    s_fianl_3rd_p <= {{2'b01},s_fianl_3rd_p[5:0]};
                end
                else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                begin
                    min_PED_3rd_p <= s_temp_p[2];
                    s_fianl_3rd_p <= {{2'b10},s_fianl_3rd_p[5:0]};
                end
                else
                begin
                    min_PED_3rd_p <= s_temp_p[3];
                    s_fianl_3rd_p <= {{2'b11},s_fianl_3rd_p[5:0]};
                end
            end
        endcase
    end
    else if (state == COMPARE_4to2)
    begin
		case(s_cnt_r)
            4'b0001:
            begin
                if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                begin
                    min_PED_1st <= s_temp[0];
                    s_fianl_1st <= {s_fianl_1st[7:4],{2'b00},s_fianl_1st[1:0]};
                    if(s_temp[3]>s_temp[1] && s_temp[3]>s_temp[2])
                    begin
                        min_PED_3rd <= s_temp[1];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b01},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[2];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b10},s_fianl_1st[1:0]};
                    end
                    else if(s_temp[2]>s_temp[1] && s_temp[2]>s_temp[3])
                    begin
                        min_PED_3rd <= s_temp[1];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b01},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[3];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b11},s_fianl_1st[1:0]};
                    end
                    else
                    begin
                        min_PED_3rd <= s_temp[2];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b10},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[3];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b11},s_fianl_1st[1:0]};
                    end
                end
                else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                begin
                    min_PED_1st <= s_temp[1];
                    s_fianl_1st <= {s_fianl_1st[7:4],{2'b01},s_fianl_1st[1:0]};
                    if(s_temp[3]>s_temp[0] && s_temp[3]>s_temp[2])
                    begin
                        min_PED_3rd <= s_temp[0];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b00},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[2];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b10},s_fianl_1st[1:0]};
                    end
                    else if(s_temp[2]>s_temp[0] && s_temp[2]>s_temp[3])
                    begin
                        min_PED_3rd <= s_temp[0];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b00},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[3];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b11},s_fianl_1st[1:0]};
                    end
                    else
                    begin
                        min_PED_3rd <= s_temp[2];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b10},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[3];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b11},s_fianl_1st[1:0]};
                    end
                end
                else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                begin
                    min_PED_1st <= s_temp[2];
                    s_fianl_1st <= {s_fianl_1st[7:4],{2'b10},s_fianl_1st[1:0]};
                    if(s_temp[3]>s_temp[0] && s_temp[3]>s_temp[1])
                    begin
                        min_PED_3rd <= s_temp[0];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b00},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[1];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b01},s_fianl_1st[1:0]};
                    end
                    else if(s_temp[0]>s_temp[1] && s_temp[0]<s_temp[3])
                    begin
                        min_PED_3rd <= s_temp[1];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b01},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[3];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b11},s_fianl_1st[1:0]};
                    end
                    else
                    begin
                        min_PED_3rd <= s_temp[0];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b00},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[3];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b11},s_fianl_1st[1:0]};
                    end
                end
                else
                begin
                    min_PED_1st <= s_temp[3];
                    s_fianl_1st <= {s_fianl_1st[7:4],{2'b11},s_fianl_1st[1:0]};
                    if(s_temp[2]>s_temp[0] && s_temp[2]>s_temp[1])
                    begin
                        min_PED_3rd <= s_temp[0];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b00},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[1];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b01},s_fianl_1st[1:0]};
                    end
                    else if(s_temp[1]>s_temp[0] && s_temp[1]>s_temp[2])
                    begin
                        min_PED_3rd <= s_temp[0];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b00},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[2];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b10},s_fianl_1st[1:0]};
                    end
                    else
                    begin
                        min_PED_3rd <= s_temp[2];
                        s_fianl_3rd <= {s_fianl_1st[7:4],{2'b10},s_fianl_1st[1:0]};
                        min_PED_temp <= s_temp[1];
                        s_final_temp <= {s_fianl_1st[7:4],{2'b01},s_fianl_1st[1:0]};
                    end
                end

                if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                begin
                    min_PED_1st_p <= s_temp_p[0];
                    s_fianl_1st_p <= {s_fianl_1st_p[7:4],{2'b00},s_fianl_1st_p[1:0]};
                    if(s_temp_p[3]>s_temp_p[1] && s_temp_p[3]>s_temp_p[2])
                    begin
                        min_PED_3rd_p <= s_temp_p[1];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b01},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[2];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b10},s_fianl_1st_p[1:0]};
                    end
                    else if(s_temp_p[2]>s_temp_p[1] && s_temp_p[2]>s_temp_p[3])
                    begin
                        min_PED_3rd_p <= s_temp_p[1];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b01},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[3];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b11},s_fianl_1st_p[1:0]};
                    end
                    else
                    begin
                        min_PED_3rd_p <= s_temp_p[2];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b10},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[3];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b11},s_fianl_1st_p[1:0]};
                    end
                end
                else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                begin
                    min_PED_1st_p <= s_temp_p[1];
                    s_fianl_1st_p <= {s_fianl_1st_p[7:4],{2'b01},s_fianl_1st_p[1:0]};
                    if(s_temp_p[3]>s_temp_p[0] && s_temp_p[3]>s_temp_p[2])
                    begin
                        min_PED_3rd_p <= s_temp_p[0];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b00},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[2];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b10},s_fianl_1st_p[1:0]};
                    end
                    else if(s_temp_p[2]>s_temp_p[0] && s_temp_p[2]>s_temp_p[3])
                    begin
                        min_PED_3rd_p <= s_temp_p[0];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b00},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[3];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b11},s_fianl_1st_p[1:0]};
                    end
                    else
                    begin
                        min_PED_3rd_p <= s_temp_p[2];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b10},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[3];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b11},s_fianl_1st_p[1:0]};
                    end
                end
                else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                begin
                    min_PED_1st_p <= s_temp_p[2];
                    s_fianl_1st_p <= {s_fianl_1st_p[7:4],{2'b10},s_fianl_1st_p[1:0]};
                    if(s_temp_p[3]>s_temp_p[0] && s_temp_p[3]>s_temp_p[1])
                    begin
                        min_PED_3rd_p <= s_temp_p[0];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b00},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[1];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b01},s_fianl_1st_p[1:0]};
                    end
                    else if(s_temp_p[0]>s_temp_p[1] && s_temp_p[0]<s_temp_p[3])
                    begin
                        min_PED_3rd_p <= s_temp_p[1];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b01},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[3];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b11},s_fianl_1st_p[1:0]};
                    end
                    else
                    begin
                        min_PED_3rd_p <= s_temp_p[0];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b00},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[3];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b11},s_fianl_1st_p[1:0]};
                    end
                end
                else
                begin
                    min_PED_1st_p <= s_temp_p[3];
                    s_fianl_1st_p <= {s_fianl_1st_p[7:4],{2'b11},s_fianl_1st_p[1:0]};
                    if(s_temp_p[2]>s_temp_p[0] && s_temp_p[2]>s_temp_p[1])
                    begin
                        min_PED_3rd_p <= s_temp_p[0];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b00},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[1];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b01},s_fianl_1st_p[1:0]};
                    end
                    else if(s_temp_p[1]>s_temp_p[0] && s_temp_p[1]>s_temp_p[2])
                    begin
                        min_PED_3rd_p <= s_temp_p[0];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b00},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[2];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b10},s_fianl_1st_p[1:0]};
                    end
                    else
                    begin
                        min_PED_3rd_p <= s_temp_p[2];
                        s_fianl_3rd_p <= {s_fianl_1st_p[7:4],{2'b10},s_fianl_1st_p[1:0]};
                        min_PED_temp_p <= s_temp_p[1];
                        s_final_temp_p <= {s_fianl_1st_p[7:4],{2'b01},s_fianl_1st_p[1:0]};
                    end
                end
            end
            4'b0010:
            begin
                if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                begin
                    min_PED_2nd <= s_temp[0];
                    s_fianl_2nd <= {s_fianl_2nd[7:4],{2'b00},s_fianl_2nd[1:0]};
                    if(s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[1];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b01},s_fianl_2nd[1:0]};
                    end
                    else if(s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[2];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b10},s_fianl_2nd[1:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[3];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b11},s_fianl_2nd[1:0]};
                    end
                end
                else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                begin
                    min_PED_2nd <= s_temp[1];
                    s_fianl_2nd <= {s_fianl_2nd[7:4],{2'b01},s_fianl_2nd[1:0]};
                    if(s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[0];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b00},s_fianl_2nd[1:0]};
                    end
                    else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[2];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b10},s_fianl_2nd[1:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[3];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b11},s_fianl_2nd[1:0]};
                    end
                end
                else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                begin
                    min_PED_2nd <= s_temp[2];
                    s_fianl_2nd <= {s_fianl_2nd[7:4],{2'b10},s_fianl_2nd[1:0]};
                    if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[0];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b00},s_fianl_2nd[1:0]};
                    end
                    else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[1];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b01},s_fianl_2nd[1:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[3];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b11},s_fianl_2nd[1:0]};
                    end
                end
                else
                begin
                    min_PED_2nd <= s_temp[3];
                    s_fianl_2nd <= {s_fianl_2nd[7:4],{2'b11},s_fianl_2nd[1:0]};
                    if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2])
                    begin
                        min_PED_temp2 <= s_temp[0];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b00},s_fianl_2nd[1:0]};
                    end
                    else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2])
                    begin
                        min_PED_temp2 <= s_temp[1];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b01},s_fianl_2nd[1:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[2];
                        s_final_temp2 <= {s_fianl_2nd[7:4],{2'b10},s_fianl_2nd[1:0]};
                    end
                end

                if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                begin
                    min_PED_2nd_p <= s_temp_p[0];
                    s_fianl_2nd_p <= {s_fianl_2nd_p[7:4],{2'b00},s_fianl_2nd_p[1:0]};
                    if(s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[1];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b01},s_fianl_2nd_p[1:0]};
                    end
                    else if(s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[2];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b10},s_fianl_2nd_p[1:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[3];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b11},s_fianl_2nd_p[1:0]};
                    end
                end
                else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                begin
                    min_PED_2nd_p <= s_temp_p[1];
                    s_fianl_2nd_p <= {s_fianl_2nd_p[7:4],{2'b01},s_fianl_2nd_p[1:0]};
                    if(s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[0];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b00},s_fianl_2nd_p[1:0]};
                    end
                    else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[2];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b10},s_fianl_2nd_p[1:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[3];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b11},s_fianl_2nd_p[1:0]};
                    end
                end
                else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                begin
                    min_PED_2nd_p <= s_temp_p[2];
                    s_fianl_2nd_p <= {s_fianl_2nd_p[7:4],{2'b10},s_fianl_2nd_p[1:0]};
                    if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[0];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b00},s_fianl_2nd_p[1:0]};
                    end
                    else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[1];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b01},s_fianl_2nd_p[1:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[3];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b11},s_fianl_2nd_p[1:0]};
                    end
                end
                else
                begin
                    min_PED_2nd_p <= s_temp_p[3];
                    s_fianl_2nd_p <= {s_fianl_2nd_p[7:4],{2'b11},s_fianl_2nd_p[1:0]};
                    if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2])
                    begin
                        min_PED_temp2_p <= s_temp_p[0];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b00},s_fianl_2nd_p[1:0]};
                    end
                    else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2])
                    begin
                        min_PED_temp2_p <= s_temp_p[1];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b01},s_fianl_2nd_p[1:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[2];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:4],{2'b10},s_fianl_2nd_p[1:0]};
                    end
                end
            end

            4'b0011:
            begin
                if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                begin
                    min_PED_1st <= s_temp[0];
                    s_fianl_1st <= {s_fianl_1st[7:6],{2'b00},s_fianl_1st[3:0]};
                    if(s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                    begin
                        min_PED_temp <= s_temp[1];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b01},s_fianl_1st[3:0]};
                    end
                    else if(s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                    begin
                        min_PED_temp <= s_temp[2];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b10},s_fianl_1st[3:0]};
                    end
                    else
                    begin
                        min_PED_temp <= s_temp[3];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b11},s_fianl_1st[3:0]};
                    end
                end
                else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                begin
                    min_PED_1st <= s_temp[1];
                    s_fianl_1st <= {s_fianl_1st[7:6],{2'b01},s_fianl_1st[3:0]};
                    if(s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                    begin
                        min_PED_temp <= s_temp[0];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b00},s_fianl_1st[3:0]};
                    end
                    else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[3])
                    begin
                        min_PED_temp <= s_temp[2];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b10},s_fianl_1st[3:0]};
                    end
                    else
                    begin
                        min_PED_temp <= s_temp[3];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b11},s_fianl_1st[3:0]};
                    end
                end
                else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                begin
                    min_PED_1st <= s_temp[2];
                    s_fianl_1st <= {s_fianl_1st[7:6],{2'b10},s_fianl_1st[3:0]};
                    if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[3])
                    begin
                        min_PED_temp <= s_temp[0];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b00},s_fianl_1st[3:0]};
                    end
                    else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[3])
                    begin
                        min_PED_temp <= s_temp[1];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b01},s_fianl_1st[3:0]};
                    end
                    else
                    begin
                        min_PED_temp <= s_temp[3];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b11},s_fianl_1st[3:0]};
                    end
                end
                else
                begin
                    min_PED_1st <= s_temp[3];
                    s_fianl_1st <= {s_fianl_1st[7:4],{2'b11},s_fianl_1st[3:0]};
                    if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2])
                    begin
                        min_PED_temp <= s_temp[0];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b00},s_fianl_1st[3:0]};
                    end
                    else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2])
                    begin
                        min_PED_temp <= s_temp[1];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b01},s_fianl_1st[3:0]};
                    end
                    else
                    begin
                        min_PED_temp <= s_temp[2];
                        s_final_temp <= {s_fianl_1st[7:6],{2'b10},s_fianl_1st[3:0]};
                    end
                end

                if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                begin
                    min_PED_1st_p <= s_temp_p[0];
                    s_fianl_1st_p <= {s_fianl_1st_p[7:6],{2'b00},s_fianl_1st_p[3:0]};
                    if(s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                    begin
                        min_PED_temp_p <= s_temp_p[1];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b01},s_fianl_1st_p[3:0]};
                    end
                    else if(s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                    begin
                        min_PED_temp_p <= s_temp_p[2];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b10},s_fianl_1st_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp_p <= s_temp_p[3];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b11},s_fianl_1st_p[3:0]};
                    end
                end
                else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                begin
                    min_PED_1st_p <= s_temp_p[1];
                    s_fianl_1st_p <= {s_fianl_1st_p[7:6],{2'b01},s_fianl_1st_p[3:0]};
                    if(s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                    begin
                        min_PED_temp_p <= s_temp_p[0];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b00},s_fianl_1st_p[3:0]};
                    end
                    else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[3])
                    begin
                        min_PED_temp_p <= s_temp_p[2];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b10},s_fianl_1st_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp_p <= s_temp_p[3];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b11},s_fianl_1st_p[3:0]};
                    end
                end
                else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                begin
                    min_PED_1st_p <= s_temp_p[2];
                    s_fianl_1st_p <= {s_fianl_1st_p[7:6],{2'b10},s_fianl_1st_p[3:0]};
                    if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[3])
                    begin
                        min_PED_temp_p <= s_temp_p[0];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b00},s_fianl_1st_p[3:0]};
                    end
                    else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[3])
                    begin
                        min_PED_temp_p <= s_temp_p[1];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b01},s_fianl_1st_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp_p <= s_temp_p[3];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b11},s_fianl_1st_p[3:0]};
                    end
                end
                else
                begin
                    min_PED_1st_p <= s_temp_p[3];
                    s_fianl_1st_p <= {s_fianl_1st_p[7:4],{2'b11},s_fianl_1st_p[3:0]};
                    if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2])
                    begin
                        min_PED_temp_p <= s_temp_p[0];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b00},s_fianl_1st_p[3:0]};
                    end
                    else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2])
                    begin
                        min_PED_temp_p <= s_temp_p[1];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b01},s_fianl_1st_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp_p <= s_temp_p[2];
                        s_final_temp_p <= {s_fianl_1st_p[7:6],{2'b10},s_fianl_1st_p[3:0]};
                    end
                end
            end
            4'b0100:
            begin
                if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                begin
                    min_PED_2nd <= s_temp[0];
                    s_fianl_2nd <= {s_fianl_2nd[7:6],{2'b00},s_fianl_2nd[3:0]};
                    if(s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[1];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b01},s_fianl_2nd[3:0]};
                    end
                    else if(s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[2];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b10},s_fianl_2nd[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[3];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b11},s_fianl_2nd[3:0]};
                    end
                end
                else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                begin
                    min_PED_2nd <= s_temp[1];
                    s_fianl_2nd <= {s_fianl_2nd[7:6],{2'b01},s_fianl_2nd[3:0]};
                    if(s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[0];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b00},s_fianl_2nd[3:0]};
                    end
                    else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[2];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b10},s_fianl_2nd[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[3];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b11},s_fianl_2nd[3:0]};
                    end
                end
                else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                begin
                    min_PED_2nd <= s_temp[2];
                    s_fianl_2nd <= {s_fianl_2nd[7:6],{2'b10},s_fianl_2nd[3:0]};
                    if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[0];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b00},s_fianl_2nd[3:0]};
                    end
                    else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[1];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b01},s_fianl_2nd[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[3];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b11},s_fianl_2nd[3:0]};
                    end
                end
                else
                begin
                    min_PED_2nd <= s_temp[3];
                    s_fianl_2nd <= {s_fianl_2nd[7:6],{2'b11},s_fianl_2nd[3:0]};
                    if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2])
                    begin
                        min_PED_temp2 <= s_temp[0];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b00},s_fianl_2nd[3:0]};
                    end
                    else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2])
                    begin
                        min_PED_temp2 <= s_temp[1];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b01},s_fianl_2nd[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[2];
                        s_final_temp2 <= {s_fianl_2nd[7:6],{2'b10},s_fianl_2nd[3:0]};
                    end
                end

                if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                begin
                    min_PED_2nd_p <= s_temp_p[0];
                    s_fianl_2nd_p <= {s_fianl_2nd_p[7:6],{2'b00},s_fianl_2nd_p[3:0]};
                    if(s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[1];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b01},s_fianl_2nd_p[3:0]};
                    end
                    else if(s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[2];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b10},s_fianl_2nd_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[3];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b11},s_fianl_2nd_p[3:0]};
                    end
                end
                else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                begin
                    min_PED_2nd_p <= s_temp_p[1];
                    s_fianl_2nd_p <= {s_fianl_2nd_p[7:6],{2'b01},s_fianl_2nd_p[3:0]};
                    if(s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[0];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b00},s_fianl_2nd_p[3:0]};
                    end
                    else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[2];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b10},s_fianl_2nd_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[3];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b11},s_fianl_2nd_p[3:0]};
                    end
                end
                else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                begin
                    min_PED_2nd_p <= s_temp_p[2];
                    s_fianl_2nd_p <= {s_fianl_2nd_p[7:6],{2'b10},s_fianl_2nd_p[3:0]};
                    if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[0];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b00},s_fianl_2nd_p[3:0]};
                    end
                    else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[1];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b01},s_fianl_2nd_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[3];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b11},s_fianl_2nd_p[3:0]};
                    end
                end
                else
                begin
                    min_PED_2nd_p <= s_temp_p[3];
                    s_fianl_2nd_p <= {s_fianl_2nd_p[7:6],{2'b11},s_fianl_2nd_p[3:0]};
                    if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2])
                    begin
                        min_PED_temp2_p <= s_temp_p[0];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b00},s_fianl_2nd_p[3:0]};
                    end
                    else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2])
                    begin
                        min_PED_temp2_p <= s_temp_p[1];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b01},s_fianl_2nd_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[2];
                        s_final_temp2_p <= {s_fianl_2nd_p[7:6],{2'b10},s_fianl_2nd_p[3:0]};
                    end
                end
            end
            4'b0101:
            begin
                if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                begin
                    min_PED_3rd <= s_temp[0];
                    s_fianl_3rd <= {s_fianl_3rd[7:6],{2'b00},s_fianl_3rd[3:0]};
                    if(s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[1];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b01},s_fianl_3rd[3:0]};
                    end
                    else if(s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[2];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b10},s_fianl_3rd[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[3];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b11},s_fianl_3rd[3:0]};
                    end
                end
                else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2] && s_temp[1]<s_temp[3])
                begin
                    min_PED_3rd <= s_temp[1];
                    s_fianl_3rd <= {s_fianl_3rd[7:6],{2'b01},s_fianl_3rd[3:0]};
                    if(s_temp[0]<s_temp[2] && s_temp[0]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[0];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b00},s_fianl_3rd[3:0]};
                    end
                    else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[2];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b10},s_fianl_3rd[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[3];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b11},s_fianl_3rd[3:0]};
                    end
                end
                else if(s_temp[2]<s_temp[0] && s_temp[2]<s_temp[1] && s_temp[2]<s_temp[3])
                begin
                    min_PED_3rd <= s_temp[2];
                    s_fianl_3rd <= {s_fianl_3rd[7:6],{2'b10},s_fianl_3rd[3:0]};
                    if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[0];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b00},s_fianl_3rd[3:0]};
                    end
                    else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[3])
                    begin
                        min_PED_temp2 <= s_temp[1];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b01},s_fianl_3rd[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[3];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b11},s_fianl_3rd[3:0]};
                    end
                end
                else
                begin
                    min_PED_3rd <= s_temp[3];
                    s_fianl_3rd <= {s_fianl_3rd[7:6],{2'b11},s_fianl_3rd[3:0]};
                    if(s_temp[0]<s_temp[1] && s_temp[0]<s_temp[2])
                    begin
                        min_PED_temp2 <= s_temp[0];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b00},s_fianl_3rd[3:0]};
                    end
                    else if(s_temp[1]<s_temp[0] && s_temp[1]<s_temp[2])
                    begin
                        min_PED_temp2 <= s_temp[1];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b01},s_fianl_3rd[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2 <= s_temp[2];
                        s_final_temp2 <= {s_fianl_3rd[7:6],{2'b10},s_fianl_3rd[3:0]};
                    end
                end

                if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                begin
                    min_PED_3rd_p <= s_temp_p[0];
                    s_fianl_3rd_p <= {s_fianl_3rd_p[7:6],{2'b00},s_fianl_3rd_p[3:0]};
                    if(s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[1];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b01},s_fianl_3rd_p[3:0]};
                    end
                    else if(s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[2];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b10},s_fianl_3rd_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[3];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b11},s_fianl_3rd_p[3:0]};
                    end
                end
                else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2] && s_temp_p[1]<s_temp_p[3])
                begin
                    min_PED_3rd_p <= s_temp_p[1];
                    s_fianl_3rd_p <= {s_fianl_3rd_p[7:6],{2'b01},s_fianl_3rd_p[3:0]};
                    if(s_temp_p[0]<s_temp_p[2] && s_temp_p[0]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[0];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b00},s_fianl_3rd_p[3:0]};
                    end
                    else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[2];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b10},s_fianl_3rd_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[3];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b11},s_fianl_3rd_p[3:0]};
                    end
                end
                else if(s_temp_p[2]<s_temp_p[0] && s_temp_p[2]<s_temp_p[1] && s_temp_p[2]<s_temp_p[3])
                begin
                    min_PED_3rd_p <= s_temp_p[2];
                    s_fianl_3rd_p <= {s_fianl_3rd_p[7:6],{2'b10},s_fianl_3rd_p[3:0]};
                    if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[0];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b00},s_fianl_3rd_p[3:0]};
                    end
                    else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[3])
                    begin
                        min_PED_temp2_p <= s_temp_p[1];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b01},s_fianl_3rd_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[3];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b11},s_fianl_3rd_p[3:0]};
                    end
                end
                else
                begin
                    min_PED_3rd_p <= s_temp_p[3];
                    s_fianl_3rd_p <= {s_fianl_3rd_p[7:6],{2'b11},s_fianl_3rd_p[3:0]};
                    if(s_temp_p[0]<s_temp_p[1] && s_temp_p[0]<s_temp_p[2])
                    begin
                        min_PED_temp2_p <= s_temp_p[0];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b00},s_fianl_3rd_p[3:0]};
                    end
                    else if(s_temp_p[1]<s_temp_p[0] && s_temp_p[1]<s_temp_p[2])
                    begin
                        min_PED_temp2_p <= s_temp_p[1];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b01},s_fianl_3rd_p[3:0]};
                    end
                    else
                    begin
                        min_PED_temp2_p <= s_temp_p[2];
                        s_final_temp2_p <= {s_fianl_3rd_p[7:6],{2'b10},s_fianl_3rd_p[3:0]};
                    end
                end
            end
        endcase
    end
    else if (state == COMPARE)
    begin
        comp_cnt <= comp_cnt+1;
        if(comp_cnt)
        begin
            if(min_PED_1st > min_PED_2nd && min_PED_1st > min_PED_3rd)
            begin
                if(min_PED_temp < min_PED_1st)
                begin
                    min_PED_1st <= min_PED_temp;
                    s_fianl_1st <= s_final_temp;
                end
            end
            else if(min_PED_2nd > min_PED_1st && min_PED_2nd > min_PED_3rd)
            begin
                if(min_PED_temp < min_PED_2nd)
                begin
                    min_PED_2nd <= min_PED_temp;
                    s_fianl_2nd <= s_final_temp;
                end
            end
            else if(min_PED_3rd > min_PED_1st && min_PED_3rd > min_PED_2nd)
            begin
                if(min_PED_temp < min_PED_3rd)
                begin
                    min_PED_3rd <= min_PED_temp;
                    s_fianl_3rd <= s_final_temp;
                end
            end

            if(min_PED_1st_p > min_PED_2nd_p && min_PED_1st_p > min_PED_3rd_p)
            begin
                if(min_PED_temp_p < min_PED_1st_p)
                begin
                    min_PED_1st_p <= min_PED_temp_p;
                    s_fianl_1st_p <= s_final_temp_p;
                end
            end
            else if(min_PED_2nd_p > min_PED_1st_p && min_PED_2nd_p > min_PED_3rd_p)
            begin
                if(min_PED_temp_p < min_PED_2nd_p)
                begin
                    min_PED_2nd_p <= min_PED_temp_p;
                    s_fianl_2nd_p <= s_final_temp_p;
                end
            end
            else if(min_PED_3rd_p > min_PED_1st_p && min_PED_3rd_p > min_PED_2nd_p)
            begin
                if(min_PED_temp_p < min_PED_3rd_p)
                begin
                    min_PED_3rd_p <= min_PED_temp_p;
                    s_fianl_3rd_p <= s_final_temp_p;
                end
            end
        end
        else
        begin
            if(min_PED_1st > min_PED_2nd && min_PED_1st > min_PED_3rd)
            begin
                if(min_PED_temp2 < min_PED_1st)
                begin
                    min_PED_1st <= min_PED_temp2;
                    s_fianl_1st <= s_final_temp2;
                end
            end
            else if(min_PED_2nd > min_PED_1st && min_PED_2nd > min_PED_3rd)
            begin
                if(min_PED_temp2 < min_PED_2nd)
                begin
                    min_PED_2nd <= min_PED_temp2;
                    s_fianl_2nd <= s_final_temp2;
                end
            end
            else if(min_PED_3rd > min_PED_1st && min_PED_3rd > min_PED_2nd)
            begin
                if(min_PED_temp2 < min_PED_3rd)
                begin
                    min_PED_3rd <= min_PED_temp2;
                    s_fianl_3rd <= s_final_temp2;
                end
            end

            if(min_PED_1st_p > min_PED_2nd_p && min_PED_1st_p > min_PED_3rd_p)
            begin
                if(min_PED_temp2_p < min_PED_1st_p)
                begin
                    min_PED_1st_p <= min_PED_temp2_p;
                    s_fianl_1st_p <= s_final_temp2_p;
                end
            end
            else if(min_PED_2nd_p > min_PED_1st_p && min_PED_2nd_p > min_PED_3rd_p)
            begin
                if(min_PED_temp2_p < min_PED_2nd_p)
                begin
                    min_PED_2nd_p <= min_PED_temp2_p;
                    s_fianl_2nd_p <= s_final_temp2_p;
                end
            end
            else if(min_PED_3rd_p > min_PED_1st_p && min_PED_3rd_p > min_PED_2nd_p)
            begin
                if(min_PED_temp2_p < min_PED_3rd_p)
                begin
                    min_PED_3rd_p <= min_PED_temp2_p;
                    s_fianl_3rd_p <= s_final_temp2_p;
                end
            end
        end
    end
    else if (state == COMPUTE_s2_1st)
    begin
        case(s_choose)
            2'b00:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
                i_r_09 <= i_r_09_w;
                i_r_10 <= i_r_10_w;

                i_r_11 <= i_r_11_w;
                i_r_12 <= i_r_12_w;
                i_r_13 <= i_r_13_w;
                i_r_14 <= i_r_14_w;
                i_r_15 <= i_r_15_w;
                i_r_16 <= i_r_16_w;
                i_r_17 <= i_r_17_w;
                i_r_18 <= i_r_18_w;
            end
            2'b01:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
            end
            2'b10:
            begin
                mul_temp_01 <= mul_temp_01_w;
                mul_temp_02 <= mul_temp_02_w;
                mul_temp_03 <= mul_temp_03_w;
                mul_temp_04 <= mul_temp_04_w;
                mul_temp_05 <= mul_temp_05_w;
                mul_temp_06 <= mul_temp_06_w;
                mul_temp_07 <= mul_temp_07_w;
                mul_temp_08 <= mul_temp_08_w;
            end
            2'b11:
            begin
                s_temp[0] <= s_temp_w[0];
                s_temp[1] <= s_temp_w[1];
                s_temp[2] <= s_temp_w[2];
                s_temp[3] <= s_temp_w[3];
                s_temp_p[0] <= s_temp_p_w[0];
                s_temp_p[1] <= s_temp_p_w[1];
                s_temp_p[2] <= s_temp_p_w[2];
                s_temp_p[3] <= s_temp_p_w[3];
            end
        endcase
        s_choose <= s_choose + 1;
    end
    else if (state == COMPUTE_s2_2nd)
    begin
		case(s_choose)
            2'b00:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
                i_r_09 <= i_r_09_w;
                i_r_10 <= i_r_10_w;

                i_r_11 <= i_r_11_w;
                i_r_12 <= i_r_12_w;
                i_r_13 <= i_r_13_w;
                i_r_14 <= i_r_14_w;
                i_r_15 <= i_r_15_w;
                i_r_16 <= i_r_16_w;
                i_r_17 <= i_r_17_w;
                i_r_18 <= i_r_18_w;
            end
            2'b01:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
            end
            2'b10:
            begin
                mul_temp_01 <= mul_temp_01_w;
                mul_temp_02 <= mul_temp_02_w;
                mul_temp_03 <= mul_temp_03_w;
                mul_temp_04 <= mul_temp_04_w;
                mul_temp_05 <= mul_temp_05_w;
                mul_temp_06 <= mul_temp_06_w;
                mul_temp_07 <= mul_temp_07_w;
                mul_temp_08 <= mul_temp_08_w;
            end
            2'b11:
            begin
                s_temp[0] <= s_temp_w[0];
                s_temp[1] <= s_temp_w[1];
                s_temp[2] <= s_temp_w[2];
                s_temp[3] <= s_temp_w[3];
                s_temp_p[0] <= s_temp_p_w[0];
                s_temp_p[1] <= s_temp_p_w[1];
                s_temp_p[2] <= s_temp_p_w[2];
                s_temp_p[3] <= s_temp_p_w[3];
            end
        endcase
        s_choose <= s_choose + 1;
    end
    else if (state == COMPUTE_s2_3rd)
    begin
		case(s_choose)
            2'b00:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
                i_r_09 <= i_r_09_w;
                i_r_10 <= i_r_10_w;
                i_r_11 <= i_r_11_w;
                i_r_12 <= i_r_12_w;
                i_r_13 <= i_r_13_w;
                i_r_14 <= i_r_14_w;
                i_r_15 <= i_r_15_w;
                i_r_16 <= i_r_16_w;
                i_r_17 <= i_r_17_w;
                i_r_18 <= i_r_18_w;
            end
            2'b01:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
            end
            2'b10:
            begin
                mul_temp_01 <= mul_temp_01_w;
                mul_temp_02 <= mul_temp_02_w;
                mul_temp_03 <= mul_temp_03_w;
                mul_temp_04 <= mul_temp_04_w;
                mul_temp_05 <= mul_temp_05_w;
                mul_temp_06 <= mul_temp_06_w;
                mul_temp_07 <= mul_temp_07_w;
                mul_temp_08 <= mul_temp_08_w;
            end
            2'b11:
            begin
                s_temp[0] <= s_temp_w[0];
                s_temp[1] <= s_temp_w[1];
                s_temp[2] <= s_temp_w[2];
                s_temp[3] <= s_temp_w[3];
                s_temp_p[0] <= s_temp_p_w[0];
                s_temp_p[1] <= s_temp_p_w[1];
                s_temp_p[2] <= s_temp_p_w[2];
                s_temp_p[3] <= s_temp_p_w[3];
            end
        endcase
        s_choose <= s_choose + 1;
        if(min_PED_1st > min_PED_2nd && min_PED_1st > min_PED_temp && min_PED_1st > min_PED_temp2)
        begin
            min_PED_1st <= min_PED_temp2;
            s_fianl_1st <= s_final_temp2;
        end
        else if(min_PED_2nd > min_PED_1st && min_PED_2nd > min_PED_temp && min_PED_2nd > min_PED_temp2)
        begin
            min_PED_2nd <= min_PED_temp2;
            s_fianl_2nd <= s_final_temp2;
        end
        else if(min_PED_temp > min_PED_1st && min_PED_temp > min_PED_2nd && min_PED_temp > min_PED_temp2)
        begin
            min_PED_temp <= min_PED_temp2;
            s_final_temp <= s_final_temp2;
        end
        if(min_PED_1st_p > min_PED_2nd_p && min_PED_1st_p > min_PED_temp_p && min_PED_1st_p > min_PED_temp2_p)
        begin
            min_PED_1st_p <= min_PED_temp2_p;
            s_fianl_1st_p <= s_final_temp2_p;
        end
        else if(min_PED_2nd_p > min_PED_1st_p && min_PED_2nd_p > min_PED_temp_p && min_PED_2nd_p > min_PED_temp2_p)
        begin
            min_PED_2nd_p <= min_PED_temp2_p;
            s_fianl_2nd_p <= s_final_temp2_p;
        end
        else if(min_PED_temp_p > min_PED_1st_p && min_PED_temp_p > min_PED_2nd_p && min_PED_temp_p > min_PED_temp2_p)
        begin
            min_PED_temp_p <= min_PED_temp2_p;
            s_final_temp_p <= s_final_temp2_p;
        end
    end
    else if (state == COMPUTE_s1_1st)
    begin
        case(s_choose)
            2'b00:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
                i_r_09 <= i_r_09_w;
                i_r_10 <= i_r_10_w;
                i_r_11 <= i_r_11_w;
                i_r_12 <= i_r_12_w;
                i_r_13 <= i_r_13_w;
                i_r_14 <= i_r_14_w;
                i_r_15 <= i_r_15_w;
                i_r_16 <= i_r_16_w;
                i_r_17 <= i_r_17_w;
                i_r_18 <= i_r_18_w;
                i_r_19 <= i_r_19_w;
                i_r_20 <= i_r_20_w;
                i_r_21 <= i_r_21_w;
                i_r_22 <= i_r_22_w;
                i_r_23 <= i_r_23_w;
                i_r_24 <= i_r_24_w;
                i_r_25 <= i_r_25_w;
                i_r_26 <= i_r_26_w;
            end
            2'b01:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
            end
            2'b10:
            begin
                mul_temp_01 <= mul_temp_01_w;
                mul_temp_02 <= mul_temp_02_w;
                mul_temp_03 <= mul_temp_03_w;
                mul_temp_04 <= mul_temp_04_w;
                mul_temp_05 <= mul_temp_05_w;
                mul_temp_06 <= mul_temp_06_w;
                mul_temp_07 <= mul_temp_07_w;
                mul_temp_08 <= mul_temp_08_w;
            end
            2'b11:
            begin
                s_temp[0] <= s_temp_w[0];
                s_temp[1] <= s_temp_w[1];
                s_temp[2] <= s_temp_w[2];
                s_temp[3] <= s_temp_w[3];
                s_temp_p[0] <= s_temp_p_w[0];
                s_temp_p[1] <= s_temp_p_w[1];
                s_temp_p[2] <= s_temp_p_w[2];
                s_temp_p[3] <= s_temp_p_w[3];
            end
        endcase
        s_choose <= s_choose + 1;
    end
    else if (state == COMPUTE_s1_2nd)
    begin
		case(s_choose)
            2'b00:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
                i_r_09 <= i_r_09_w;
                i_r_10 <= i_r_10_w;
                i_r_11 <= i_r_11_w;
                i_r_12 <= i_r_12_w;
                i_r_13 <= i_r_13_w;
                i_r_14 <= i_r_14_w;
                i_r_15 <= i_r_15_w;
                i_r_16 <= i_r_16_w;
                i_r_17 <= i_r_17_w;
                i_r_18 <= i_r_18_w;
                i_r_19 <= i_r_19_w;
                i_r_20 <= i_r_20_w;
                i_r_21 <= i_r_21_w;
                i_r_22 <= i_r_22_w;
                i_r_23 <= i_r_23_w;
                i_r_24 <= i_r_24_w;
                i_r_25 <= i_r_25_w;
                i_r_26 <= i_r_26_w;
            end
            2'b01:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
            end
            2'b10:
            begin
                mul_temp_01 <= mul_temp_01_w;
                mul_temp_02 <= mul_temp_02_w;
                mul_temp_03 <= mul_temp_03_w;
                mul_temp_04 <= mul_temp_04_w;
                mul_temp_05 <= mul_temp_05_w;
                mul_temp_06 <= mul_temp_06_w;
                mul_temp_07 <= mul_temp_07_w;
                mul_temp_08 <= mul_temp_08_w;
            end
            2'b11:
            begin
                s_temp[0] <= s_temp_w[0];
                s_temp[1] <= s_temp_w[1];
                s_temp[2] <= s_temp_w[2];
                s_temp[3] <= s_temp_w[3];
                s_temp_p[0] <= s_temp_p_w[0];
                s_temp_p[1] <= s_temp_p_w[1];
                s_temp_p[2] <= s_temp_p_w[2];
                s_temp_p[3] <= s_temp_p_w[3];
            end
        endcase
        s_choose <= s_choose + 1;
    end
    else if (state == COMPUTE_s1_3rd)
    begin
		case(s_choose)
            2'b00:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
                i_r_09 <= i_r_09_w;
                i_r_10 <= i_r_10_w;
                i_r_11 <= i_r_11_w;
                i_r_12 <= i_r_12_w;
                i_r_13 <= i_r_13_w;
                i_r_14 <= i_r_14_w;
                i_r_15 <= i_r_15_w;
                i_r_16 <= i_r_16_w;
                i_r_17 <= i_r_17_w;
                i_r_18 <= i_r_18_w;
                i_r_19 <= i_r_19_w;
                i_r_20 <= i_r_20_w;
                i_r_21 <= i_r_21_w;
                i_r_22 <= i_r_22_w;
                i_r_23 <= i_r_23_w;
                i_r_24 <= i_r_24_w;
                i_r_25 <= i_r_25_w;
                i_r_26 <= i_r_26_w;
            end
            2'b01:
            begin
                i_r_01 <= i_r_01_w;
                i_r_02 <= i_r_02_w;
                i_r_03 <= i_r_03_w;
                i_r_04 <= i_r_04_w;
                i_r_05 <= i_r_05_w;
                i_r_06 <= i_r_06_w;
                i_r_07 <= i_r_07_w;
                i_r_08 <= i_r_08_w;
            end
            2'b10:
            begin
                mul_temp_01 <= mul_temp_01_w;
                mul_temp_02 <= mul_temp_02_w;
                mul_temp_03 <= mul_temp_03_w;
                mul_temp_04 <= mul_temp_04_w;
                mul_temp_05 <= mul_temp_05_w;
                mul_temp_06 <= mul_temp_06_w;
                mul_temp_07 <= mul_temp_07_w;
                mul_temp_08 <= mul_temp_08_w;
            end
            2'b11:
            begin
                s_temp[0] <= s_temp_w[0];
                s_temp[1] <= s_temp_w[1];
                s_temp[2] <= s_temp_w[2];
                s_temp[3] <= s_temp_w[3];
                s_temp_p[0] <= s_temp_p_w[0];
                s_temp_p[1] <= s_temp_p_w[1];
                s_temp_p[2] <= s_temp_p_w[2];
                s_temp_p[3] <= s_temp_p_w[3];
            end
        endcase
        s_choose <= s_choose + 1;
    end
    else if (state == COMPARE_3to1)
    begin
        if(min_PED_2nd < min_PED_1st && min_PED_2nd < min_PED_3rd)
        begin
            min_PED_1st <= min_PED_2nd;
            s_fianl_1st <= s_fianl_2nd;
        end
        else if(min_PED_3rd < min_PED_1st && min_PED_3rd < min_PED_2nd)
        begin
            min_PED_1st <= min_PED_3rd;
            s_fianl_1st <= s_fianl_3rd;
        end

        if(min_PED_2nd_p < min_PED_1st_p && min_PED_2nd_p < min_PED_3rd_p)
        begin
            min_PED_1st_p <= min_PED_2nd_p;
            s_fianl_1st_p <= s_fianl_2nd_p;
        end
        else if(min_PED_3rd_p < min_PED_1st_p && min_PED_3rd_p < min_PED_2nd_p)
        begin
            min_PED_1st_p <= min_PED_3rd_p;
            s_fianl_1st_p <= s_fianl_3rd_p;
        end
    end
end

// state
always @(posedge i_clk or posedge i_reset) begin
	if(i_reset) 
    begin
		state <= IDLE;
        o_cnt_r <= 0;
        s_cnt_r <= 0;
	end 
    else 
    begin
		state <= state_nxt;
        o_cnt_r <= o_cnt;
        s_cnt_r <= s_cnt_w;
	end
end
// output
always @(posedge i_clk or posedge i_reset) begin
	if(i_reset) 
    begin
        rd_vld <= 0;
	end 
    else if (state == LLR)
    begin
		rd_vld <= 1;
	end
    else if(i_cnt == o_cnt)
        rd_vld <= 0;
end

assign min111 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[7])   ? min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]  : 8'h7f :
                (s_fianl_1st_p[7]) ? min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]: 8'h7f : 8'h7f;
assign min110 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[7])   ? 8'h7f  : min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] :
                (s_fianl_1st_p[7]) ? 8'h7f  : min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] : 8'h7f;
assign min121 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[6])   ? min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]  : 8'h7f :
                (s_fianl_1st_p[6]) ? min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]: 8'h7f : 8'h7f;
assign min120 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[6])   ? 8'h7f  : min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] :
                (s_fianl_1st_p[6]) ? 8'h7f  : min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] : 8'h7f;
assign min211 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[5])   ? min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]  : 8'h7f :
                (s_fianl_1st_p[5]) ? min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]: 8'h7f : 8'h7f;
assign min210 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[5])   ? 8'h7f  : min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] :
                (s_fianl_1st_p[5]) ? 8'h7f  : min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] : 8'h7f;
assign min221 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[4])   ? min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]  : 8'h7f :
                (s_fianl_1st_p[4]) ? min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]: 8'h7f : 8'h7f;
assign min220 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[4])   ? 8'h7f  : min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] :
                (s_fianl_1st_p[4]) ? 8'h7f  : min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] : 8'h7f;
assign min311 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[3])   ? min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]  : 8'h7f :
                (s_fianl_1st_p[3]) ? min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]: 8'h7f : 8'h7f;
assign min310 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[3])   ? 8'h7f  : min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] :
                (s_fianl_1st_p[3]) ? 8'h7f  : min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] : 8'h7f;
assign min321 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[2])   ? min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]  : 8'h7f :
                (s_fianl_1st_p[2]) ? min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]: 8'h7f : 8'h7f;
assign min320 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[2])   ? 8'h7f  : min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] :
                (s_fianl_1st_p[2]) ? 8'h7f  : min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] : 8'h7f;
assign min411 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[1])   ? min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]  : 8'h7f :
                (s_fianl_1st_p[1]) ? min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]: 8'h7f : 8'h7f;
assign min410 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[1])   ? 8'h7f  : min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] :
                (s_fianl_1st_p[1]) ? 8'h7f  : min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] : 8'h7f;
assign min421 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[0])   ? min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]  : 8'h7f :
                (s_fianl_1st_p[0]) ? min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC]: 8'h7f : 8'h7f;
assign min420 = (state == LLR) ? 
                (min_PED_1st < min_PED_1st_p) ? 
                (s_fianl_1st[0])   ? 8'h7f  : min_PED_1st[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] :
                (s_fianl_1st_p[0]) ? 8'h7f  : min_PED_1st_p[LENGTH_MUL -1 -TRUNCATION - INT + INT_TRUNC : LENGTH_MUL - TRUNCATION -INT*3 + INT_TRUNC] : 8'h7f;

// LLR
always @(posedge i_clk or posedge i_reset) begin
	if(i_reset) 
    begin
		for(i=0; i<136; i=i+1) 
        begin
            o_LLR[i] <= 0;
        end
        i_cnt <= 0;
	end
    else if (state == LLR)
    begin
        o_LLR[i_cnt   ] <= (min111 - min110);
        o_LLR[i_cnt +1] <= (min121 - min120);
        o_LLR[i_cnt +2] <= (min211 - min210);
        o_LLR[i_cnt +3] <= (min221 - min220);
        o_LLR[i_cnt +4] <= (min311 - min310);
        o_LLR[i_cnt +5] <= (min321 - min320);
        o_LLR[i_cnt +6] <= (min411 - min410);
        o_LLR[i_cnt +7] <= (min421 - min420);
        if(i_cnt == 128) i_cnt <=0;
        else             i_cnt <= i_cnt +8;
    end 
end

assign o_rd_vld = rd_vld;
assign o_llr = (rd_vld)? o_LLR[o_cnt_r] : 0;
assign o_hard_bit = (rd_vld)? o_LLR[o_cnt_r][7] : 0;

function     [LENGTH_MUL -1 -INT_TRUNC : FRAC_TRUNC] trunc;
input [LENGTH_MUL - 1 : 0] a;  
begin
    trunc = a[LENGTH_MUL -1 -INT_TRUNC : FRAC_TRUNC];
end
endfunction

endmodule