module core #(                             //Don't modify interface
	parameter ADDR_W = 32,
	parameter INST_W = 32,
	parameter DATA_W = 32
)(
	input                   i_clk,
	input                   i_rst_n,
	output [ ADDR_W-1 : 0 ] o_i_addr,
	input  [ INST_W-1 : 0 ] i_i_inst,
	output                  o_d_we,
	output [ ADDR_W-1 : 0 ] o_d_addr,
	output [ DATA_W-1 : 0 ] o_d_wdata,
	input  [ DATA_W-1 : 0 ] i_d_rdata,
	output [        1 : 0 ] o_status,
	output                  o_status_valid
);

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
// Definition of states
parameter   IDLE    	= 4'd0;
parameter   INST_FETCH  = 4'd1;
parameter   INST_DECOD  = 4'd2;
parameter   ALU_LD     	= 4'd3;
parameter   DATA_WB     = 4'd4;
parameter   PC_NEXT		= 4'd5;
parameter   PROCESS_OVERFLOW = 4'd6;
parameter   PROCESS_END = 4'd7;
parameter	DATA_WB_A	= 4'd8;

parameter	OP_ADD  	= 6'd0;
parameter	OP_SUB  	= 6'd1;
parameter	OP_ADDU 	= 6'd2;
parameter	OP_SUBU 	= 6'd3;
parameter	OP_ADDI 	= 6'd4;
parameter	OP_LW   	= 6'd5;
parameter	OP_SW   	= 6'd6;
parameter	OP_AND  	= 6'd7;
parameter	OP_OR   	= 6'd8;
parameter	OP_XOR  	= 6'd9;
parameter	OP_BEQ  	= 6'd10;
parameter	OP_BNE  	= 6'd11;
parameter	OP_SLT  	= 6'd12;
parameter	OP_SLL  	= 6'd13;
parameter	OP_SRL  	= 6'd14;
parameter	OP_BLT  	= 6'd15;
parameter	OP_BGE  	= 6'd16;
parameter	OP_BLTU 	= 6'd17;
parameter	OP_BGEU 	= 6'd18;
parameter	OP_EOF  	= 6'd19;

reg    [3:0]state, state_nxt;
reg    [ADDR_W-1:0] PC, PC_nxt;  
reg    [1:0]status, status_nxt;
reg			status_v, status_v_nxt;
reg         MemWrite, MemWrite_nxt; 
reg			regWrite, regWrite_nxt;
reg	   [DATA_W-1:0] d_wdata, d_wdata_nxt;
reg	   [DATA_W-1:0] d_addr, d_addr_nxt;

reg    [ 4:0] rs1, rs2, rs3;
reg    [15:0] immediate;              
wire   [DATA_W-1:0] rs2_data, rs3_data;
reg	   [DATA_W-1:0] rs1_data, rs1_d_tmp, rs2_d_tmp, rs3_d_tmp, PC_tmp;
reg	   [DATA_W:0] 	sum_temp;
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign o_i_addr 	  = PC;
assign o_d_we 		  = MemWrite;
assign o_d_addr 	  = d_addr;
assign o_d_wdata 	  = d_wdata;
assign o_status 	  = status;
assign o_status_valid = status_v;

reg_file reg0(                           
        .clk(i_clk),                           
        .rst_n(i_rst_n),                       
        .wen(regWrite),                      
        .a1(rs2),                            
        .a2(rs3),                            
        .aw(rs1),                             
        .d(rs1_data),                         
        .q1(rs2_data),                       
        .q2(rs3_data)); 

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always @(*)
begin
	case(state)
		IDLE:
		begin
			rs1 = 0;
			rs2 = 0;
			rs3 = 0;
			immediate = 0;
			rs1_data = 0;
			rs1_d_tmp = 0;
			rs2_d_tmp = 0;
			rs3_d_tmp = 0;
			sum_temp = 0;
			PC_nxt = PC;
/*			PC_tmp = PC;
			state_nxt = 0;
			status_nxt = 0;
			status_v_nxt = 0;
			MemWrite_nxt = 0;
			regWrite_nxt = 0;
			d_wdata_nxt = 0;
			d_addr_nxt = 0;
			*/
			if(i_i_inst != 0)
			begin
				state_nxt = INST_FETCH;
			end
			else
			begin
				state_nxt = state;
			end
		end
		INST_FETCH:
		begin
			state_nxt = INST_DECOD;
			regWrite_nxt = 0;
		end
		INST_DECOD:
		begin
			if(i_i_inst[31:26] == 6'd19)
			begin
				state_nxt = PROCESS_END;
				status_nxt = 3;
				status_v_nxt = 1;
			end
			else if(i_i_inst[31:26] == 6'd0 ||
					i_i_inst[31:26] == 6'd1 ||
					i_i_inst[31:26] == 6'd2 ||
					i_i_inst[31:26] == 6'd3 ||
					i_i_inst[31:26] == 6'd7 ||
					i_i_inst[31:26] == 6'd8 ||
					i_i_inst[31:26] == 6'd9 ||
					i_i_inst[31:26] == 6'd12 ||
					i_i_inst[31:26] == 6'd13 ||
					i_i_inst[31:26] == 6'd14 )
			begin
				rs1 = i_i_inst[15:11];
				rs2 = i_i_inst[25:21];
				rs3 = i_i_inst[20:16];
				state_nxt = ALU_LD;
			end
			else if(i_i_inst[31:26] == 6'd4 ||
					i_i_inst[31:26] == 6'd5 )
			begin
				rs1 = i_i_inst[20:16];
				rs2 = i_i_inst[25:21];
				immediate = i_i_inst[15:0];
				state_nxt = ALU_LD;
			end
			else
			begin 
				rs3 = i_i_inst[20:16];
				rs2 = i_i_inst[25:21];
				immediate = i_i_inst[15:0];
				state_nxt = ALU_LD;
			end
		end
		ALU_LD:
		begin
			rs2_d_tmp = rs2_data;
			rs3_d_tmp = rs3_data;
			case(i_i_inst[31:26])
					OP_ADD :
					begin
						sum_temp  = {rs2_d_tmp[DATA_W-1], rs2_d_tmp} + {rs3_d_tmp[DATA_W-1], rs3_d_tmp};
            			rs1_d_tmp = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 32'b0111_1111_1111_1111_1111_1111_1111_1111:
                       			    (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 32'b1000_0000_0000_0000_0000_0000_0000_0000:
                       			    rs2_d_tmp + rs3_d_tmp;

						if(sum_temp[DATA_W] ^ sum_temp[DATA_W-1])
						begin
							status_nxt = 2;
							status_v_nxt = 1;
							state_nxt = PROCESS_OVERFLOW;
						end
						else
						begin
							state_nxt = DATA_WB;
						end
					end
					OP_SUB :
					begin
						sum_temp  = {rs2_d_tmp[DATA_W-1], rs2_d_tmp} + (~{rs3_d_tmp[DATA_W-1], rs3_d_tmp} +1 );
            			rs1_d_tmp = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 32'b0111_1111_1111_1111_1111_1111_1111_1111:
                        		    (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 32'b1000_0000_0000_0000_0000_0000_0000_0000:
                                    rs2_d_tmp - rs3_d_tmp;

						if(sum_temp[DATA_W] ^ sum_temp[DATA_W-1])
						begin
							status_nxt = 2;
							status_v_nxt = 1;
							state_nxt = PROCESS_OVERFLOW;
						end
						else
						begin
							state_nxt = DATA_WB;
						end
					end
					OP_ADDU :
					begin
						sum_temp  = {1'b0, rs2_d_tmp} + {1'b0, rs3_d_tmp};
            			rs1_d_tmp = (sum_temp[DATA_W]) ? 32'hffff_ffff:
                       			    rs2_d_tmp + rs3_d_tmp;

						if(sum_temp[DATA_W])
						begin
							status_nxt = 2;
							status_v_nxt = 1;
							state_nxt = PROCESS_OVERFLOW;
						end
						else
						begin
							state_nxt = DATA_WB;
						end
					end
					OP_SUBU :
					begin
						rs1_d_tmp = (rs2_d_tmp < rs3_d_tmp) ? 32'd0:
                       			    rs2_d_tmp - rs3_d_tmp;
						
						if(rs2_d_tmp < rs3_d_tmp)
						begin
							status_nxt = 2;
							status_v_nxt = 1;
							state_nxt = PROCESS_OVERFLOW;
						end
						else
						begin
							state_nxt = DATA_WB;
						end
					end
					OP_ADDI :
					begin
						sum_temp  = {rs2_d_tmp[DATA_W-1], rs2_d_tmp} + {{17{immediate[15]}}, immediate};
            			rs1_d_tmp = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 32'b0111_1111_1111_1111_1111_1111_1111_1111:
                       			    (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 32'b1000_0000_0000_0000_0000_0000_0000_0000:
                       			    rs2_d_tmp + {{16{immediate[15]}}, immediate};

						if(sum_temp[DATA_W] ^ sum_temp[DATA_W-1])
						begin
							status_nxt = 2;
							status_v_nxt = 1;
							state_nxt = PROCESS_OVERFLOW;
						end
						else
						begin
							state_nxt = DATA_WB;
						end
					end
					OP_LW :
					begin
						sum_temp  = {rs2_d_tmp[DATA_W-1], rs2_d_tmp} + {{17{immediate[15]}}, immediate};
            			rs1_d_tmp = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 32'b0111_1111_1111_1111_1111_1111_1111_1111:
                       			    (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 32'b1000_0000_0000_0000_0000_0000_0000_0000:
                       			    rs2_d_tmp + {{16{immediate[15]}}, immediate};
						MemWrite_nxt = 0;

						if((sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) || (rs1_d_tmp[DATA_W-1:2] > 63))
						begin
							status_nxt = 2;
							status_v_nxt = 1;
							state_nxt = PROCESS_OVERFLOW;
							d_addr_nxt = 0;
						end
						else
						begin
							state_nxt = DATA_WB;
							d_addr_nxt = rs1_d_tmp;
						end
					end
					OP_SW :
					begin
						sum_temp  = {rs2_d_tmp[DATA_W-1], rs2_d_tmp} + {{17{immediate[15]}}, immediate};
            			rs1_d_tmp = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 32'b0111_1111_1111_1111_1111_1111_1111_1111:
                       			    (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 32'b1000_0000_0000_0000_0000_0000_0000_0000:
                       			    rs2_d_tmp + {{16{immediate[15]}}, immediate};
						MemWrite_nxt = 1;

						if((sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) || (rs1_d_tmp[DATA_W-1:2] > 63))
						begin
							status_nxt = 2;
							status_v_nxt = 1;
							state_nxt = PROCESS_OVERFLOW;
							d_wdata_nxt = 0;
							d_addr_nxt = 0;
						end
						else
						begin
							state_nxt = DATA_WB;
							d_wdata_nxt = rs3_data;
							d_addr_nxt = rs1_d_tmp;
						end
					end
					OP_AND :
					begin
						rs1_d_tmp = rs2_d_tmp & rs3_d_tmp;
						state_nxt = DATA_WB;
					end
					OP_OR :
					begin
						rs1_d_tmp = rs2_d_tmp | rs3_d_tmp;
						state_nxt = DATA_WB;
					end
					OP_XOR :
					begin
						rs1_d_tmp = rs2_d_tmp ^ rs3_d_tmp;
						state_nxt = DATA_WB;
					end
					OP_BEQ :
					begin
						sum_temp  = {PC[DATA_W-1], PC} + {{17{immediate[15]}}, immediate};
						rs1_d_tmp = PC + {{16{immediate[15]}}, immediate};
						if(rs3_d_tmp == rs2_d_tmp)
						begin
							if( (rs1_d_tmp[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
							begin
								status_nxt = 2;
								status_v_nxt = 1;
								state_nxt = PROCESS_OVERFLOW;
							end
							else
							begin
								PC_tmp = rs1_d_tmp;
								status_nxt = 1;
								status_v_nxt = 1;
								state_nxt = PC_NEXT;
							end
						end
						else
						begin
							PC_tmp = PC + 4;
							status_nxt = 1;
							status_v_nxt = 1;
							state_nxt = PC_NEXT;
						end
					end
					OP_BNE :
					begin
						sum_temp  = {PC[DATA_W-1], PC} + {{17{immediate[15]}}, immediate};
						rs1_d_tmp = PC + {{16{immediate[15]}}, immediate};
						if(rs3_d_tmp != rs2_d_tmp)
						begin
							if( (rs1_d_tmp[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
							begin
								status_nxt = 2;
								status_v_nxt = 1;
								state_nxt = PROCESS_OVERFLOW;
							end
							else
							begin
								PC_tmp = rs1_d_tmp;
								status_nxt = 1;
								status_v_nxt = 1;
								state_nxt = PC_NEXT;
							end
						end
						else
						begin
							PC_tmp = PC + 4;
							status_nxt = 1;
							status_v_nxt = 1;
							state_nxt = PC_NEXT;
						end
					end
					OP_SLT :
					begin
						rs1_d_tmp = (rs2_d_tmp[DATA_W-1] ^ rs3_d_tmp[DATA_W-1]) ?
									(rs2_d_tmp[DATA_W-1] == 1'b0) ? 32'd0 : 32'd1:
									(rs2_d_tmp < rs3_d_tmp) ? 32'd1 : 32'd0;
						state_nxt = DATA_WB;
					end
					OP_SLL :
					begin
						rs1_d_tmp = rs2_d_tmp << rs3_d_tmp;
						state_nxt = DATA_WB;
					end
					OP_SRL :
					begin
						rs1_d_tmp = rs2_d_tmp >> rs3_d_tmp;
						state_nxt = DATA_WB;
					end
					OP_BLT :
					begin
						sum_temp  = {PC[DATA_W-1], PC} + {{17{immediate[15]}}, immediate};
						rs1_d_tmp = PC + {{16{immediate[15]}}, immediate};
						if((((rs3_d_tmp[DATA_W-1] ^ rs2_d_tmp[DATA_W-1]) && (rs3_d_tmp[DATA_W-1] == 1'b1))
							|| (rs3_d_tmp < rs2_d_tmp)))
						begin
							if( (rs1_d_tmp[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
								begin
									status_nxt = 2;
									status_v_nxt = 1;
									state_nxt = PROCESS_OVERFLOW;
								end
							else
								begin
									PC_tmp = rs1_d_tmp;
									status_nxt = 1;
									status_v_nxt = 1;
									state_nxt = PC_NEXT;
								end
						end
						else
						begin
							PC_tmp = PC + 4;
							status_nxt = 1;
							status_v_nxt = 1;
							state_nxt = PC_NEXT;
						end
					end
					OP_BGE :
					begin
						PC_tmp = (rs3_d_tmp[DATA_W-1] ^ rs2_d_tmp[DATA_W-1]) ?
									(rs3_d_tmp[DATA_W-1] == 1'b0) ? PC + {{16{immediate[15]}}, immediate} : PC + 4:
									(rs3_d_tmp >= rs2_d_tmp) ? PC + {{16{immediate[15]}}, immediate} : PC + 4;
						rs1_d_tmp = PC + {{16{immediate[15]}}, immediate};
						sum_temp  = {PC[DATA_W-1], PC} + {{17{immediate[15]}}, immediate};

						if(( ( (rs3_d_tmp[DATA_W-1] ^ rs2_d_tmp[DATA_W-1]) && (rs3_d_tmp[DATA_W-1] == 1'b0))
							|| (rs3_d_tmp >= rs2_d_tmp) ) )
						begin
							if( (rs1_d_tmp[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
								begin
									status_nxt = 2;
									status_v_nxt = 1;
									state_nxt = PROCESS_OVERFLOW;
								end
							else
								begin
									PC_tmp = rs1_d_tmp;
									status_nxt = 1;
									status_v_nxt = 1;
									state_nxt = PC_NEXT;
								end
						end
						else
						begin
							PC_tmp = PC + 4;
							status_nxt = 1;
							status_v_nxt = 1;
							state_nxt = PC_NEXT;
						end
					end
					OP_BLTU :
					begin
						sum_temp  = {PC[DATA_W-1], PC} + {{17{immediate[15]}}, immediate};
						rs1_d_tmp = PC + {{16{immediate[15]}}, immediate};

						if(rs3_d_tmp < rs2_d_tmp)
						begin
							if( (rs1_d_tmp[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
								begin
									status_nxt = 2;
									status_v_nxt = 1;
									state_nxt = PROCESS_OVERFLOW;
								end
							else
								begin
									PC_tmp = rs1_d_tmp;
									status_nxt = 1;
									status_v_nxt = 1;
									state_nxt = PC_NEXT;
								end
						end
						else
						begin
							PC_tmp = PC + 4;
							status_nxt = 1;
							status_v_nxt = 1;
							state_nxt = PC_NEXT;
						end
					end
					OP_BGEU :
					begin
						sum_temp  = {PC[DATA_W-1], PC} + {{17{immediate[15]}}, immediate};
						rs1_d_tmp = PC + {{16{immediate[15]}}, immediate};

						if(rs3_d_tmp >= rs2_d_tmp)
						begin
							if( (rs1_d_tmp[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
								begin
									status_nxt = 2;
									status_v_nxt = 1;
									state_nxt = PROCESS_OVERFLOW;
								end
							else
								begin
									PC_tmp = rs1_d_tmp;
									status_nxt = 1;
									status_v_nxt = 1;
									state_nxt = PC_NEXT;
								end
						end
						else
						begin
							PC_tmp = PC + 4;
							status_nxt = 1;
							status_v_nxt = 1;
							state_nxt = PC_NEXT;
						end
					end
					default :
						state_nxt = IDLE;
			endcase
		end
		DATA_WB:
		begin
			state_nxt = PC_NEXT;
			PC_tmp = PC + 4;
			if(i_i_inst[31:26] == 6'd4 
				|| i_i_inst[31:26] == 6'd5
				|| i_i_inst[31:26] == 6'd6)
			begin
				status_nxt = 1;
				status_v_nxt = 1;
			end
			else 
			begin
				status_nxt = 0;
				status_v_nxt = 1;
			end
			if(i_i_inst[31:26] == 6'd6)
				regWrite_nxt = 0;
			else
				regWrite_nxt = 1;
		end
		PC_NEXT:
		begin
			if(i_i_inst[31:26] == 6'd5)
			begin
				rs1_data = i_d_rdata;
			end
			else rs1_data = rs1_d_tmp;
			state_nxt = INST_FETCH;
			status_nxt = 0;
			status_v_nxt = 0;
			PC_nxt = PC_tmp;
			MemWrite_nxt = 0;
		end
		PROCESS_OVERFLOW:
		begin
			state_nxt = state;
		end
		PROCESS_END:
		begin
			state_nxt = state;
		end
		default :
		begin
			state_nxt = IDLE;
		end
	endcase
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) 
	begin
		PC <= 32'd0;
		state <= IDLE;
		status <= 0;
		status_v <= 0;
        MemWrite <= 0; 
		regWrite <= 0;
		d_wdata <= 0;
		d_addr <= 0;
	end
	else 
	begin
		PC <= PC_nxt;
		state <= state_nxt;
		status <= status_nxt;
		status_v <= status_v_nxt;
        MemWrite <= MemWrite_nxt; 
		regWrite <= regWrite_nxt;
		d_wdata <= d_wdata_nxt;
		d_addr <= d_addr_nxt;
	end
end

endmodule
module reg_file(clk, rst_n, wen, a1, a2, aw, d, q1, q2);

    parameter BITS = 32;
    parameter word_depth = 32;
    parameter addr_width = 5; // 2^addr_width >= word_depth

    input clk, rst_n, wen; // wen: 0:read | 1:write
    input [BITS-1:0] d;
    input [addr_width-1:0] a1, a2, aw;

    output [BITS-1:0] q1, q2;

    reg [BITS-1:0] mem [0:word_depth-1];
    reg [BITS-1:0] mem_nxt [0:word_depth-1];

    integer i;

    assign q1 = mem[a1];
    assign q2 = mem[a2];

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (aw == i)) ? d : mem[i];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<word_depth; i=i+1)
            	mem[i] <= 32'h0;
        end
        else begin
            for (i=0; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];
        end
    end
endmodule