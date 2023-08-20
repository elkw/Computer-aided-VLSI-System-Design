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
reg    [3:0]state, state_nxt;

// Regfile
reg    [ADDR_W-1:0] PC          ;             
reg    [ADDR_W-1:0] PC_nxt      ;              
wire          	  regWrite    ;              
wire   [ 4:0]     rs1, rs2, rs3;            
wire   [DATA_W-1:0] rs1_data    ;              
wire   [DATA_W-1:0] rs2_data    ;              
wire   [DATA_W-1:0] rs3_data     ;
// PC
wire   [DATA_W-1:0] PC_nxt_4;       // PC+4
// ImmediateGeneration
wire   [DATA_W-1:0] Immediate;      // immediate expansion
// Control
wire        Branch;
wire        MemRead;
wire        MemtoReg;
wire        MemWrite;
wire        WriteReg;
wire        ALUSrc;
// ALU
wire [DATA_W-1:0] PC_tmp;
wire [DATA_W-1:0] ALU_in1;
wire [DATA_W-1:0] ALU_in2;
wire [DATA_W-1:0] ALU_out;
wire        ALU_zero;
wire [1:0]	status;
wire		status_v;

reg  [1:0]	status_r, status_w;
reg		    status_v_r, status_v_w;
reg			MemWrite_r, MemWrite_w;
reg			regWrite_r, regWrite_w;
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign o_i_addr 	  = PC;
assign o_d_we 		  = MemWrite_r;
assign o_d_addr 	  = ALU_out;
assign o_d_wdata 	  = rs3_data;
assign o_status 	  = status_r;
assign o_status_valid = status_v_r;

assign regWrite = regWrite_r;
assign rs1_data = ( (MemtoReg) ? i_d_rdata : ALU_out);
assign PC_tmp = PC;
assign PC_nxt_4 = (PC + 32'd4);
assign ALU_in1 = rs2_data;
assign ALU_in2 = (ALUSrc ? Immediate : rs3_data);

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

RSImmdetermine rs0(
	.in_inst(i_i_inst),
	.out_rs1(rs1),
	.out_rs2(rs2),
	.out_rs3(rs3),
	.out_imm(Immediate));

Control c1(
	.OpCode(i_i_inst[31:26]), 
	.Branch_w(Branch),
	.MemRead_w(MemRead), 
	.MemtoReg_w(MemtoReg),	
	.MemWrite_w(MemWrite),
	.regWrite_w(WriteReg),
	.ALUSrc_w(ALUSrc));

ALU alu1(
	.OpCode(i_i_inst[31:26]),
	.PC(PC_tmp),
	.Imm(Immediate),
	.in1(ALU_in1), 
	.in2(ALU_in2), 
	.out(ALU_out),
	.zero_o(ALU_zero),
	.status(status),
	.status_v(status_v));
// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always @(*)
begin
	status_w = status_r;
	status_v_w = status_v_r;
	MemWrite_w = MemWrite_r;
	regWrite_w = regWrite_r;
	case(state)
		IDLE:
		begin
			if(i_i_inst != 0)
			begin
				if( i_i_inst[31:26] == 6'd19 )
				begin
					status_w = 3;
					status_v_w = 1;
					PC_nxt = PC;
				    state_nxt = PROCESS_END;
				end
				else
				begin
					PC_nxt = PC;
					state_nxt = INST_FETCH;
				end
			end
			else
			begin
				PC_nxt = PC;
				state_nxt = state;
			end
		end
		INST_FETCH:
		begin
			PC_nxt = PC;
			state_nxt = INST_DECOD;
		end
		INST_DECOD:
		begin
			PC_nxt = PC;
			state_nxt = ALU_LD;
		end
		ALU_LD:
		begin
			if( i_i_inst[31:26] == 6'd19 )
				begin
					status_w = 3;
					status_v_w = 1;
					PC_nxt = PC;
				    state_nxt = PROCESS_END;
				end
			else
			begin	
				PC_nxt = PC;
				state_nxt = DATA_WB;
			end
		end
		DATA_WB:
		begin
			MemWrite_w = MemWrite;
			regWrite_w = WriteReg;
			status_w = status;
			status_v_w = status_v;
			if(status_v && (status == 2)) 
			begin
				PC_nxt = PC;
				state_nxt = PROCESS_OVERFLOW;
			end
			else if(status_v && (status ==3)) 
			begin
				PC_nxt = PC;
				state_nxt = PROCESS_END;
			end
			else if(status_v && (status == 1 || status == 0)) 
			begin
				PC_nxt = PC;
				state_nxt = PC_NEXT;
			end
			else
			begin
				PC_nxt = PC;
				state_nxt = state;
			end
		end
		PC_NEXT:
		begin
			status_w = 0;
			status_v_w = 0;
			MemWrite_w = 0;
			regWrite_w = 0;
			PC_nxt = (Branch && ALU_zero) ? ALU_out : PC_nxt_4;
			state_nxt = INST_FETCH;
		end
		PROCESS_OVERFLOW:
		begin
			PC_nxt = PC;
			state_nxt = state;
		end
		PROCESS_END:
		begin
			PC_nxt = PC;
			state_nxt = state;
		end
		default :
		begin
			PC_nxt = PC;
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
		status_r = 0;
		status_v_r = 0;
		MemWrite_r = 0;
		regWrite_r = 0;
	end
	else 
	begin
		PC <= PC_nxt;
		state <= state_nxt;
		status_r = status_w;
		status_v_r = status_v_w;
		MemWrite_r = MemWrite_w;
		regWrite_r = regWrite_w;
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

module RSImmdetermine(in_inst, out_rs1, out_rs2, out_rs3, out_imm);
    input [31:0] in_inst;

	output reg [4:0] out_rs1;
	output reg [4:0] out_rs2;
	output reg [4:0] out_rs3;
	output reg [31:0] out_imm;

    always @(*)begin
        out_imm <= {{16{in_inst[15]}},in_inst[15:0]};
		if(in_inst[31:26] == 6'd0 ||
			in_inst[31:26] == 6'd1 ||
			in_inst[31:26] == 6'd2 ||
			in_inst[31:26] == 6'd3 ||
			in_inst[31:26] == 6'd7 ||
			in_inst[31:26] == 6'd8 ||
			in_inst[31:26] == 6'd9 ||
			in_inst[31:26] == 6'd12 ||
			in_inst[31:26] == 6'd13 ||
			in_inst[31:26] == 6'd14 )
		begin
			out_rs1 = in_inst[15:11];
			out_rs2 = in_inst[25:21];
			out_rs3 = in_inst[20:16];
		end
		else if(in_inst[31:26] == 6'd4 ||
				in_inst[31:26] == 6'd5 )
		begin
			out_rs1 = in_inst[20:16];
			out_rs2 = in_inst[25:21];
			out_rs3 = 0;
		end
		else
		begin 
			out_rs3 = in_inst[20:16];
			out_rs2 = in_inst[25:21];
			out_rs1 = 0;
		end
    end 
endmodule

module Control(OpCode, Branch_w, MemRead_w, MemtoReg_w,
             MemWrite_w, ALUSrc_w, regWrite_w);
	// Definition of operation
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

    input [5:0] OpCode;

	output Branch_w;          //beq
	output MemRead_w;         //lw
    output MemtoReg_w;        //lw
    output MemWrite_w;        //sw
	output regWrite_w;
    output ALUSrc_w;          //0: rs2, 1:immediate

    reg [5:0] control;
    
    assign {Branch_w, MemRead_w, MemtoReg_w, MemWrite_w, ALUSrc_w, regWrite_w} = control;

    always@(*) begin
        case(OpCode)
            OP_ADD :  control <= 6'b000001; //R-type
            OP_SUB :  control <= 6'b000001; //R-type
            OP_ADDU : control <= 6'b000001; //R-type
            OP_SUBU : control <= 6'b000001; //R-type
            OP_ADDI : control <= 6'b000011; //I-type
            OP_LW :   control <= 6'b011011; //I-type
            OP_SW :   control <= 6'b000110; //I-type
            OP_AND :  control <= 6'b000001; //R-type
			OP_OR :   control <= 6'b000001; //R-type
			OP_XOR :  control <= 6'b000001; //R-type
            OP_BEQ :  control <= 6'b100000; //I-type
            OP_BNE :  control <= 6'b100000; //I-type
            OP_SLT :  control <= 6'b000001; //R-type
            OP_SLL :  control <= 6'b000001; //R-type
            OP_SRL :  control <= 6'b000001; //R-type
            OP_BLT :  control <= 6'b100000; //I-type
            OP_BGE :  control <= 6'b100000; //I-type
			OP_BLTU : control <= 6'b100000; //I-type
			OP_BGEU : control <= 6'b100000; //I-type
			OP_EOF :  control <= 6'b111111; //EOF
            default:  control <= 6'bxxxxxx;
    endcase
    end
endmodule

module ALU(PC, Imm, OpCode, in1, in2, out, zero_o, status, status_v);
	// Definition of operation
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
	parameter 	DATA_W 		= 32;

	input [DATA_W-1:0]PC;
	input [DATA_W-1:0]Imm;
    input [5:0] OpCode;
    input [DATA_W-1:0]in1, in2;

	output reg [DATA_W-1:0] out;
	output reg            	zero_o;
	output reg [1:0]      	status;
	output reg        		status_v;

	reg [DATA_W:0] sum_temp;

    always @(*)begin
		zero_o = 0;
		case(OpCode)
				OP_ADD :
				begin
					sum_temp = {in1[DATA_W-1], in1} + {in2[DATA_W-1], in2};
					out = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 32'b0111_1111_1111_1111_1111_1111_1111_1111:
						  (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 32'b1000_0000_0000_0000_0000_0000_0000_0000:
						  in1 + in2;
					if(sum_temp[DATA_W] ^ sum_temp[DATA_W-1])
					begin
						status = 2;
						status_v = 1;
					end
					else
					begin
						status = 0;
						status_v = 1;
					end
				end
				OP_SUB :
				begin
					sum_temp  = {in1[DATA_W-1], in1} + (~{in2[DATA_W-1], in2} +1 );
					out = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 32'b0111_1111_1111_1111_1111_1111_1111_1111:
						  (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 32'b1000_0000_0000_0000_0000_0000_0000_0000:
						  in1 - in2;

					if(sum_temp[DATA_W] ^ sum_temp[DATA_W-1])
					begin
						status = 2;
						status_v = 1;
					end
					else
					begin
						status = 0;
						status_v = 1;
					end
				end
				OP_ADDU :
				begin
					sum_temp  = {1'b0, in1} + {1'b0, in2};
					out = (sum_temp[DATA_W]) ? 32'hffff_ffff:
						  in1 + in2;

					if(sum_temp[DATA_W])
					begin
						status = 2;
						status_v = 1;
					end
					else
					begin
						status = 0;
						status_v = 1;
					end
				end
				OP_SUBU :
				begin
					sum_temp = 0;
					out = (in1 < in2) ? 32'd0:
						  in1 - in2;
					
					if(in1 < in2)
					begin
						status = 2;
						status_v = 1;
					end
					else
					begin
						status = 0;
						status_v = 1;
					end
				end
				OP_ADDI :
				begin
					sum_temp  = {in1[DATA_W-1], in1} + {in2[DATA_W-1], in2};
					out = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 32'b0111_1111_1111_1111_1111_1111_1111_1111:
						  (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 32'b1000_0000_0000_0000_0000_0000_0000_0000:
						  in1 + in2;

					if(sum_temp[DATA_W] ^ sum_temp[DATA_W-1])
					begin
						status = 2;
						status_v = 1;
					end
					else
					begin
						status = 1;
						status_v = 1;
					end
				end
				OP_LW :
				begin
					sum_temp  = {in1[DATA_W-1], in1} + {in2[DATA_W-1], in2};
					out = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 32'b0111_1111_1111_1111_1111_1111_1111_1111:
						  (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 32'b1000_0000_0000_0000_0000_0000_0000_0000:
						  in1 + in2;

					if((sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) || (out[DATA_W-1:2] > 63))
					begin
						status = 2;
						status_v = 1;
					end
					else
					begin
						status = 1;
						status_v = 1;
					end
				end
				OP_SW :
				begin
					sum_temp  = {in1[DATA_W-1], in1} + {in2[DATA_W-1], in2};
					out = (~sum_temp[DATA_W] & sum_temp[DATA_W-1]) ? 32'b0111_1111_1111_1111_1111_1111_1111_1111:
						  (sum_temp[DATA_W] & ~sum_temp[DATA_W-1]) ? 32'b1000_0000_0000_0000_0000_0000_0000_0000:
						  in1 + in2;

					if((sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) || (out[DATA_W-1:2] > 63))
					begin
						status = 2;
						status_v = 1;
					end
					else
					begin
						status = 1;
						status_v = 1;
					end
				end
				OP_AND :
				begin
					sum_temp = 0;
					out = in1 & in2;
					status = 0;
					status_v = 1;
				end
				OP_OR :
				begin
					sum_temp = 0;
					out = in1 | in2;
					status = 0;
					status_v = 1;
				end
				OP_XOR :
				begin
					sum_temp = 0;
					out = in1 ^ in2;
					status = 0;
					status_v = 1;
				end
				OP_BEQ :
				begin
					sum_temp  = {PC[DATA_W-1], PC} + {Imm[DATA_W-1], Imm};
					out = PC + Imm;
					if(in1 == in2)
					begin
						if( (out[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
						begin
							status = 2;
							status_v = 1;
						end
						else
						begin
							zero_o = 1;
							status = 1;
							status_v = 1;
						end
					end
					else
					begin
						status = 1;
						status_v = 1;
					end
				end
				OP_BNE :
				begin
					sum_temp  = {PC[DATA_W-1], PC} + {Imm[DATA_W-1], Imm};
					out = PC + Imm;
					if(in1 != in2)
					begin
						if( (out[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
						begin
							status = 2;
							status_v = 1;
						end
						else
						begin
							zero_o = 1;
							status = 1;
							status_v = 1;
						end
					end
					else
					begin
						status = 1;
						status_v = 1;
					end
				end
				OP_SLT :
				begin
					out = (in1[DATA_W-1] ^ in2[DATA_W-1]) ?
						(in1[DATA_W-1] == 1'b0) ? 32'd0 : 32'd1:
						(in1 < in2) ? 32'd1 : 32'd0;
					sum_temp = 0;
					status = 0;
					status_v = 1;
				end
				OP_SLL :
				begin
					out = in1 << in2;
					sum_temp = 0;
					status = 0;
					status_v = 1;
				end
				OP_SRL :
				begin
					out = in1 >> in2;
					sum_temp = 0;
					status = 0;
					status_v = 1;
				end
				OP_BLT :
				begin
					sum_temp  = {PC[DATA_W-1], PC} + {Imm[DATA_W-1], Imm};
					out = PC + Imm;
					if((((in1[DATA_W-1] ^ in2[DATA_W-1]) && (in1[DATA_W-1] == 1'b1))
						|| (in2 < in1)))
					begin
						if( (out[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
							begin
								status = 2;
								status_v = 1;
							end
						else
							begin
								zero_o = 1;
								status = 1;
								status_v = 1;
							end
					end
					else
					begin
						status = 1;
						status_v = 1;
					end
				end
				OP_BGE :
				begin
					out = PC + Imm;
					sum_temp  = {PC[DATA_W-1], PC} + {Imm[DATA_W-1], Imm};

					if(( ( (in1[DATA_W-1] ^ in2[DATA_W-1]) && (in1[DATA_W-1] == 1'b0))
						|| (in2 >= in1) ) )
					begin
						if( (out[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
							begin
								status = 2;
								status_v = 1;
							end
						else
							begin
								zero_o = 1;
								status = 1;
								status_v = 1;
							end
					end
					else
					begin
						status = 1;
						status_v = 1;
					end
				end
				OP_BLTU :
				begin
					out = PC + Imm;
					sum_temp  = {PC[DATA_W-1], PC} + {Imm[DATA_W-1], Imm};

					if(in2 < in1)
					begin
						if( (out[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
							begin
								status = 2;
								status_v = 1;
							end
						else
							begin
								zero_o = 1;
								status = 1;
								status_v = 1;
							end
					end
					else
					begin
						status = 1;
						status_v = 1;
					end
				end
				OP_BGEU :
				begin
					out = PC + Imm;
					sum_temp  = {PC[DATA_W-1], PC} + {Imm[DATA_W-1], Imm};

					if(in2 >= in1)
					begin
						if( (out[DATA_W-1:2] > 1023) || (sum_temp[DATA_W] ^ sum_temp[DATA_W-1]) )
							begin
								status = 2;
								status_v = 1;
							end
						else
							begin
								zero_o = 1;
								status = 1;
								status_v = 1;
							end
					end
					else
					begin
						status = 1;
						status_v = 1;
					end
				end
				default :
				begin
					out = 0;
					sum_temp = 0;
					status = 1;
					status_v = 1;
				end
		endcase
    end
endmodule