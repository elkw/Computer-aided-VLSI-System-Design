module alu #(
    parameter INT_W  = 4,
    parameter FRAC_W = 6,
    parameter INST_W = 4,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                     i_clk,
    input                     i_rst_n,
    input                     i_valid,
    input signed [DATA_W-1:0] i_data_a,
    input signed [DATA_W-1:0] i_data_b,
    input        [INST_W-1:0] i_inst,
    output                    o_valid,
    output       [DATA_W-1:0] o_data
); // Do not modify
    
// ---------------------------------------------------------------------------
// Wires and Registers
// ---- Add your own wires and registers here if needed ---- //
// ---------------------------------------------------------------------------

reg [DATA_W-1:0] o_data_w, o_data_r;
reg              o_valid_w, o_valid_r;
reg [3:0]        state_w, state_r;
reg [DATA_W:0]   sum_temp;
reg [2*DATA_W-1:0]mul_temp;
reg [2*DATA_W-1:0]mac_temp;
reg [DATA_W-1:0]        inv_a;
reg [DATA_W-1:0]        inv_out;
reg [DATA_W-1:0]        shift_temp;

parameter IDLE  = 4'd0;
parameter S_Add = 4'd1;
parameter S_Sub = 4'd2;
parameter S_Mul = 4'd3;
parameter MAC   = 4'd4;
parameter Tanh  = 4'd5;
parameter ORN   = 4'd6;
parameter CLZ   = 4'd7;
parameter CTZ   = 4'd8;
parameter CPOP  = 4'd9;
parameter ROL   = 4'd10;
parameter OUT   = 4'd11;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
assign o_valid = o_valid_r;
assign o_data = o_data_r;
// ---- Add your own wire data assignments here if needed ---- //

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always @(*)
begin
    o_valid_w = (state_r == 11) ? 1 : 0;
    case(state_r)
        IDLE:
        begin
            if(i_valid == 1)
            begin
                case(i_inst)
                    4'b0000: state_w = S_Add;
                    4'b0001: state_w = S_Sub;
                    4'b0010: state_w = S_Mul;
                    4'b0011: state_w = MAC;
                    4'b0100: state_w = Tanh;
                    4'b0101: state_w = ORN;
                    4'b0110: state_w = CLZ;
                    4'b0111: state_w = CTZ;
                    4'b1000: state_w = CPOP;
                    4'b1001: state_w = ROL;
                endcase
            end
            else
                state_w = state_r;
        end
        S_Add :
            state_w = OUT;
        S_Sub :
            state_w = OUT;
        S_Mul :
            state_w = OUT;
        MAC :
            state_w = OUT;
        Tanh :
            state_w = OUT;
        ORN :
            state_w = OUT;
        CLZ :
            state_w = OUT;
        CTZ :
            state_w = OUT;
        CPOP :
            state_w = OUT;
        ROL :
            state_w = OUT;
        OUT :
            state_w = IDLE;
        default :
            state_w = state_r;
    endcase
end
// ALU output
always @(*)
begin
    case(state_r)
        IDLE:
            o_data_w = o_data_r;
        S_Add :
        begin
            sum_temp = {i_data_a[DATA_W-1], i_data_a} + {i_data_b[DATA_W-1], i_data_b};
            o_data_w = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 10'b0111111111:
                       (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 10'b1000000000:
                       i_data_a + i_data_b;
        end
        S_Sub :
        begin
            sum_temp = {i_data_a[DATA_W-1], i_data_a} + (~{i_data_b[DATA_W-1], i_data_b} +1 );
            o_data_w = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 10'b0111111111:
                       (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 10'b1000000000:
                       i_data_a - i_data_b;
        end
        S_Mul :
        begin
            mul_temp = {{10{i_data_a[DATA_W-1]}}, i_data_a} * {{10{i_data_b[DATA_W-1]}}, i_data_b};
            if(&mul_temp[(2*DATA_W-1):(2*DATA_W-1-INT_W)] == 1)
                if(mul_temp[FRAC_W-1] == 1)
                    o_data_w = mul_temp[(2*DATA_W-1-INT_W):FRAC_W] + 1;
                else
                    o_data_w = mul_temp[(2*DATA_W-1-INT_W):FRAC_W];
            else if((|mul_temp[(2*DATA_W-1):(2*DATA_W-1-INT_W)] == 1) && (i_data_a[DATA_W-1]^i_data_b[DATA_W-1] == 0))
                o_data_w = 10'b0111111111;
            else if((|mul_temp[(2*DATA_W-1):(2*DATA_W-1-INT_W)] == 1) && (i_data_a[DATA_W-1]^i_data_b[DATA_W-1] == 1))
                o_data_w = 10'b1000000000;
            else
                if(mul_temp[FRAC_W-1] == 1)
                    o_data_w = mul_temp[(2*DATA_W-1-INT_W):FRAC_W] + 1;
                else
                    o_data_w = mul_temp[(2*DATA_W-1-INT_W):FRAC_W];
        end
        MAC :
        begin
            mac_temp = {{10{i_data_a[DATA_W-1]}}, i_data_a} * {{10{i_data_b[DATA_W-1]}}, i_data_b};
            mul_temp = {{INT_W{o_data_r[DATA_W-1]}}, o_data_r, {FRAC_W{1'b0}}} + mac_temp;
            if(&mul_temp[(2*DATA_W-1):(2*DATA_W-1-INT_W)] == 1)
                if(mul_temp[FRAC_W-1] == 1)
                    o_data_w = mul_temp[(2*DATA_W-1-INT_W):FRAC_W] + 1;
                else
                    o_data_w = mul_temp[(2*DATA_W-1-INT_W):FRAC_W];
            else if((|mul_temp[(2*DATA_W-1):(2*DATA_W-1-INT_W)] == 1) && (i_data_a[DATA_W-1]^i_data_b[DATA_W-1] == 0))
                o_data_w = 10'b0111111111;
            else if((|mul_temp[(2*DATA_W-1):(2*DATA_W-1-INT_W)] == 1) && (i_data_a[DATA_W-1]^i_data_b[DATA_W-1] == 1))
                o_data_w = 10'b1000000000;
            else
                if(mul_temp[FRAC_W-1] == 1)
                    o_data_w = mul_temp[(2*DATA_W-1-INT_W):FRAC_W] + 1;
                else
                    o_data_w = mul_temp[(2*DATA_W-1-INT_W):FRAC_W];
        end
        Tanh :
        begin
            if(i_data_a[DATA_W-1] == 0)
            begin
                if(i_data_a >= 10'b0001100000)
                    o_data_w = 10'b0001000000;
                else if(i_data_a >= 10'b0000100000)
                    o_data_w = (((i_data_a - 10'b0000100000)+i_data_a[0]) >> 1) + 10'b0000100000;
                else
                    o_data_w = i_data_a;
            end
            else
            begin
                inv_a = ~i_data_a +1;
                if(inv_a >= 10'b0001100000)
                    o_data_w = 10'b1111000000;
                else if(inv_a >= 10'b0000100000)
                begin
                    inv_out = (((inv_a - 10'b0000100000)-inv_a[0]) >> 1) + 10'b0000100000;
                    o_data_w = ~inv_out +1;
                end
                else
                    o_data_w = i_data_a;
            end
        end
        ORN :
            o_data_w = i_data_a | ~i_data_b;
        CLZ :
        begin
            if (i_data_a == 10'd0)
                o_data_w = 10'd10;
            else if (i_data_a == 10'b0000000001)
                o_data_w = 10'd9;
            else if (i_data_a  < 10'b0000000100)
                o_data_w = 10'd8;
            else if (i_data_a  < 10'b0000001000)
                o_data_w = 10'd7;
            else if (i_data_a  < 10'b0000010000)
                o_data_w = 10'd6;
            else if (i_data_a  < 10'b0000100000)
                o_data_w = 10'd5;
            else if (i_data_a  < 10'b0001000000)
                o_data_w = 10'd4;
            else if (i_data_a  < 10'b0010000000)
                o_data_w = 10'd3;
            else if (i_data_a  < 10'b0100000000)
                o_data_w = 10'd2;
            else if (i_data_a  < 10'b1000000000)
                o_data_w = 10'd1;
            else
                o_data_w = 10'd0;
        end
        CTZ :
        begin
            if (i_data_a == 10'd0)
                o_data_w = 10'd10;
            else if (i_data_a[0] == 1'b1)
                o_data_w = 10'd0;
            else if (i_data_a[1] == 1'b1)
                o_data_w = 10'd1;
            else if (i_data_a[2] == 1'b1)
                o_data_w = 10'd2;
            else if (i_data_a[3] == 1'b1)
                o_data_w = 10'd3;
            else if (i_data_a[4] == 1'b1)
                o_data_w = 10'd4;
            else if (i_data_a[5] == 1'b1)
                o_data_w = 10'd5;
            else if (i_data_a[6] == 1'b1)
                o_data_w = 10'd6;
            else if (i_data_a[7] == 1'b1)
                o_data_w = 10'd7;
            else if (i_data_a[8] == 1'b1)
                o_data_w = 10'd8;
            else
                o_data_w = 10'd9;
        end
        CPOP :
            o_data_w = i_data_a[0] + i_data_a[1] + i_data_a[2] + i_data_a[3] + i_data_a[4]
                 + i_data_a[5] + i_data_a[6] + i_data_a[7] + i_data_a[8] + i_data_a[9];
        ROL :
        begin
            shift_temp = i_data_a << i_data_b;
            if(i_data_b == 9)
                o_data_w = {shift_temp[9],i_data_a[9:1]};
            else if(i_data_b == 1)
                o_data_w = {shift_temp[9:1],i_data_a[9]};
            else if(i_data_b == 2)
                o_data_w = {shift_temp[9:2],i_data_a[9:8]};
            else if(i_data_b == 3)
                o_data_w = {shift_temp[9:3],i_data_a[9:7]};
            else if(i_data_b == 4)
                o_data_w = {shift_temp[9:4],i_data_a[9:6]};
            else if(i_data_b == 5)
                o_data_w = {shift_temp[9:5],i_data_a[9:5]};
            else if(i_data_b == 6)
                o_data_w = {shift_temp[9:6],i_data_a[9:4]};
            else if(i_data_b == 7)
                o_data_w = {shift_temp[9:7],i_data_a[9:3]};
            else if(i_data_b == 8)
                o_data_w = {shift_temp[9:8],i_data_a[9:2]};
            else
                o_data_w = i_data_a;
        end
        default:
            o_data_w = o_data_r;
    endcase
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_data_r <= 0;
        o_valid_r <= 0;
        state_r <= 0;
    end else begin
        o_data_r <= o_data_w;
        o_valid_r <= o_valid_w;
        state_r <= state_w;
    end
end

endmodule