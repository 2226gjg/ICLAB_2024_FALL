/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module TETRIS (
	//INPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//OUTPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[2:0]	tetrominoes;
input		[2:0]	position;
output reg			tetris_valid, score_valid, fail;
output reg	[3:0]	score;
output reg 	[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
typedef enum reg[2:0]{IDLE=3'b000, CAL = 3'b001,SHIFT = 3'b010,FIN = 3'b011, FFIN = 3'b100,CHECK = 3'b110}state;
state cur_state,nxt_state;
integer i;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [5:0]tetris_nxt[0:13],tetris_ff[0:13];
reg [11:0]full_line_flag;
reg [71:0]	tetris_out_comb;
reg [3:0]score_comb,score_ff,score_out_comb;
reg tetris_valid_comb,score_valid_comb,fail_comb;
reg [2:0] position_nxt,position_ff;
reg [2:0] tetrominoes_nxt,tetrominoes_ff;
reg [3:0] offset[0:5];
reg [3:0] offset_ff[0:5];
reg [3:0]counter,counter_nxt;
//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
always@(*)begin
	if(nxt_state==IDLE)begin
		for(i=0;i<=5;i=i+1)begin
			offset[i]=6'b0;
		end
		
	end
	else if(nxt_state==CAL)begin
		for(i=0;i<=5;i=i+1)begin
			if(tetris_ff[11][i]==1)begin
				offset[i]=12;
			end
			else if(tetris_ff[10][i]==1)begin
				offset[i]=11;
			end
			else if(tetris_ff[9][i]==1)begin
				offset[i]=10;
			end
			else if(tetris_ff[8][i]==1)begin
				offset[i]=9;
			end
			else if(tetris_ff[7][i]==1)begin
				offset[i]=8;
			end
			else if(tetris_ff[6][i]==1)begin
				offset[i]=7;
			end
			else if(tetris_ff[5][i]==1)begin
				offset[i]=6;
			end
			else if(tetris_ff[4][i]==1)begin
				offset[i]=5;
			end
			else if(tetris_ff[3][i]==1)begin
				offset[i]=4;
			end
			else if(tetris_ff[2][i]==1)begin
				offset[i]=3;
			end
			else if(tetris_ff[1][i]==1)begin
				offset[i]=2;
			end
			else if(tetris_ff[0][i]==1)begin
				offset[i]=1;
			end
			else begin
				offset[i]=0;
			end
		end
	end
	else begin
		for(i=0;i<=5;i=i+1)begin
			offset[i]=offset_ff[i];
		end
	end
end
always@(posedge clk)begin
	for(i=0;i<=5;i=i+1)begin
			offset_ff[i]<=offset[i];
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		score_ff<=0;
		cur_state<=IDLE;
		for(i=0;i<=13;i=i+1)begin
			tetris_ff[i]<=6'b0;
		end
		position_ff<=0;
		tetrominoes_ff<=0;
		counter<=0;
	end
	else begin
		score_ff<=score_comb;
		cur_state<=nxt_state;
		tetris_ff<=tetris_nxt;
		position_ff<=position_nxt;
		tetrominoes_ff<=tetrominoes_nxt;
		counter<=counter_nxt;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		tetris_valid<=0;
		score_valid<=0;
		fail<=0;
		tetris<=72'b0;
		score<=0;
	end
	else begin
		if(nxt_state==FIN)begin
			score_valid<=1;
			tetris_valid<=0;
			fail<=0;
			tetris<=72'b0;
			score<=score_comb;
		end
		else if(nxt_state==FFIN)begin
			score<=score_comb;
			score_valid<=1;
			tetris_valid<=1;
			fail<=fail_comb;
			tetris<={tetris_ff[11],tetris_ff[10],tetris_ff[9],tetris_ff[8],tetris_ff[7],tetris_ff[6],tetris_ff[5],tetris_ff[4],tetris_ff[3],tetris_ff[2],tetris_ff[1],tetris_ff[0]};
		end
		else begin
			score<=0;
			tetris_valid<=0;
			score_valid<=0;
			tetris<=72'b0;
			fail<=0;
		end
	end
end
//FSM
always@(*)begin
	full_line_flag[0] = &tetris_ff[0];
	full_line_flag[1] = &tetris_ff[1];
	full_line_flag[2] = &tetris_ff[2];
	full_line_flag[3] = &tetris_ff[3];
	full_line_flag[4] = &tetris_ff[4];
	full_line_flag[5] = &tetris_ff[5];
	full_line_flag[6] = &tetris_ff[6];
	full_line_flag[7] = &tetris_ff[7];
	full_line_flag[8] = &tetris_ff[8];
	full_line_flag[9] = &tetris_ff[9];
	full_line_flag[10] = &tetris_ff[10];
	full_line_flag[11] = &tetris_ff[11];
	fail_comb=|{tetris_ff[12],tetris_ff[13]};
	position_nxt=position_ff;
	tetrominoes_nxt=tetrominoes_ff;
	counter_nxt=counter;
	for(i=0;i<=13;i=i+1)begin
			tetris_nxt[i]=tetris_ff[i];
	end
	case(cur_state)
		IDLE:begin
			if(in_valid)begin
				counter_nxt=counter+1;
				nxt_state=CAL;
				position_nxt=position;
				tetrominoes_nxt=tetrominoes;
			end
			else begin
				counter_nxt=counter;
				nxt_state=cur_state;
				position_nxt=0;
				tetrominoes_nxt=0;
			end
			
		end
		CAL:begin
			//put block on map
			case(tetrominoes_ff)
				3'd0:begin
					if (offset_ff[position_ff] > offset_ff[position_ff + 1]) begin
						tetris_nxt[offset_ff[position_ff]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff] + 1][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff] + 1][position_ff + 1] = 1;
					end 
					else begin
						tetris_nxt[offset[position_ff + 1]][position_ff + 1] = 1;
						tetris_nxt[offset[position_ff + 1]][position_ff] = 1;
						tetris_nxt[offset[position_ff + 1] + 1][position_ff] = 1;
						tetris_nxt[offset[position_ff + 1] + 1][position_ff + 1] = 1;
					end
				end
				3'd1:begin
					if(offset_ff[position_ff]==11)begin
						tetris_nxt[11][position_ff]=1;
						tetris_nxt[12][position_ff]=1;
						tetris_nxt[13][position_ff]=1;
					end
					else if(offset_ff[position_ff]==12)begin
						tetris_nxt[12][position_ff]=1;
						tetris_nxt[13][position_ff]=1;
					end
					else begin
						tetris_nxt[offset_ff[position_ff ]]  [position_ff ]=1;
						tetris_nxt[offset_ff[position_ff ]+1][position_ff ]=1;
						tetris_nxt[offset_ff[position_ff ]+2][position_ff ]=1;
						tetris_nxt[offset_ff[position_ff ]+3][position_ff ]=1;
					end
					
				end
				3'd2:begin
					if (offset_ff[position_ff] >= offset_ff[position_ff + 1] && 
						offset_ff[position_ff] >= offset_ff[position_ff + 2] && 
						offset_ff[position_ff] >= offset_ff[position_ff + 3]) begin

						tetris_nxt[offset_ff[position_ff]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff]][position_ff + 2] = 1;
						tetris_nxt[offset_ff[position_ff]][position_ff + 3] = 1;
					end 
					else if (offset_ff[position_ff + 1] >= offset_ff[position_ff] && 
							 offset_ff[position_ff + 1] >= offset_ff[position_ff + 2] && 
							 offset_ff[position_ff + 1] >= offset_ff[position_ff + 3]) begin
						tetris_nxt[offset_ff[position_ff + 1]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff + 1]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff + 1]][position_ff + 2] = 1;
						tetris_nxt[offset_ff[position_ff + 1]][position_ff + 3] = 1;
					end 
					else if(offset_ff[position_ff + 2] >= offset_ff[position_ff] && 
							offset_ff[position_ff + 2] >= offset_ff[position_ff + 1] && 
							offset_ff[position_ff + 2] >= offset_ff[position_ff + 3]) begin
						tetris_nxt[offset_ff[position_ff + 2]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff + 2]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff + 2]][position_ff + 2] = 1;
						tetris_nxt[offset_ff[position_ff + 2]][position_ff + 3] = 1;
					end 
					else begin
						tetris_nxt[offset_ff[position_ff + 3]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff + 3]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff + 3]][position_ff + 2] = 1;
						tetris_nxt[offset_ff[position_ff + 3]][position_ff + 3] = 1;
					end
				end
				3'd3:begin
					if (offset_ff[position_ff] >= offset_ff[position_ff + 1] + 2) begin
						if(offset_ff[position_ff]==14)begin
							tetris_nxt[offset_ff[position_ff] - 1][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff] - 2][position_ff + 1] = 1;
						end
						else begin
							tetris_nxt[offset_ff[position_ff]][position_ff] = 1;
							tetris_nxt[offset_ff[position_ff]][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff] - 1][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff] - 2][position_ff + 1] = 1;
						end	
					end 
					else begin
						if(offset_ff[position_ff]==12)begin
							tetris_nxt[offset_ff[position_ff + 1]][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 1][position_ff + 1] = 1;
						end
						else begin
							tetris_nxt[offset_ff[position_ff + 1]][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 1][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 2][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 2][position_ff] = 1;
						end
					end
				end
				3'd4:begin
					if (offset_ff[position_ff + 1] >= offset_ff[position_ff] + 1 && 
						offset_ff[position_ff + 1] >= offset_ff[position_ff + 2]) begin
						tetris_nxt[offset_ff[position_ff + 1]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff + 1]][position_ff + 2] = 1;
						tetris_nxt[offset_ff[position_ff + 1]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff + 1] - 1][position_ff] = 1;
					end else if (offset_ff[position_ff + 2] >= offset_ff[position_ff] + 1 && 
								offset_ff[position_ff + 2] >= offset_ff[position_ff + 1]) begin
						tetris_nxt[offset_ff[position_ff + 2]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff + 2]][position_ff + 2] = 1;
						tetris_nxt[offset_ff[position_ff + 2]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff + 2] - 1][position_ff] = 1;
					end else begin
						tetris_nxt[offset_ff[position_ff]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff] + 1][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff] + 1][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff] + 1][position_ff + 2] = 1;
					end
				end
				3'd5:begin
					if (offset_ff[position_ff] >= offset_ff[position_ff + 1]) begin
						if (offset_ff[position_ff] == 12) begin
							tetris_nxt[offset_ff[position_ff]][position_ff] = 1;
							tetris_nxt[offset_ff[position_ff]][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff] + 1][position_ff] = 1;
						end 
						else begin
							tetris_nxt[offset_ff[position_ff]][position_ff] = 1;
							tetris_nxt[offset_ff[position_ff]][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff] + 1][position_ff] = 1;
							tetris_nxt[offset_ff[position_ff] + 2][position_ff] = 1;
						end
					end else begin
						if (offset_ff[position_ff + 1] == 12) begin
							tetris_nxt[offset_ff[position_ff + 1]][position_ff] = 1;
							tetris_nxt[offset_ff[position_ff + 1]][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 1][position_ff] = 1;
						end 
						else begin
							tetris_nxt[offset_ff[position_ff + 1]][position_ff] = 1;
							tetris_nxt[offset_ff[position_ff + 1]][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 1][position_ff] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 2][position_ff] = 1;
						end
					end

				end
				3'd6:begin
					if (offset_ff[position_ff] >= offset_ff[position_ff + 1] + 1) begin
						tetris_nxt[offset_ff[position_ff]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff] + 1][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff] - 1][position_ff + 1] = 1;
					end 
					else begin
						if (offset_ff[position_ff + 1] == 12) begin
							tetris_nxt[offset_ff[position_ff + 1]][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 1][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 1][position_ff] = 1;
						end 
						else begin
							tetris_nxt[offset_ff[position_ff + 1]][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 1][position_ff + 1] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 1][position_ff] = 1;
							tetris_nxt[offset_ff[position_ff + 1] + 2][position_ff] = 1;
						end
					end

				end
				3'd7:begin
					if (offset_ff[position_ff + 2] >= (offset_ff[position_ff + 1] + 1) && 
						offset_ff[position_ff + 2] >= (offset_ff[position_ff] + 1)) begin
						tetris_nxt[offset_ff[position_ff + 2]][position_ff + 2] = 1;
						tetris_nxt[offset_ff[position_ff + 2]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff + 2] - 1][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff + 2] - 1][position_ff] = 1;
					end 
					else if (offset_ff[position_ff + 1] >= offset_ff[position_ff]) begin
						tetris_nxt[offset_ff[position_ff + 1]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff + 1]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff + 1] + 1][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff + 1] + 1][position_ff + 2] = 1;
					end 
					else begin
						tetris_nxt[offset_ff[position_ff]][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff]][position_ff] = 1;
						tetris_nxt[offset_ff[position_ff] + 1][position_ff + 1] = 1;
						tetris_nxt[offset_ff[position_ff] + 1][position_ff + 2] = 1;
					end

				end
			endcase
			nxt_state=CHECK;
		end
		CHECK:begin
			if(|full_line_flag)begin
				nxt_state=SHIFT;
			end
			else begin
				if(fail_comb==1||counter==0)begin
					nxt_state=FFIN;
				end
				else begin
					nxt_state=FIN;
				end
			end
		end
		SHIFT:begin
			if(|full_line_flag)begin
				nxt_state=SHIFT;
			end
			else begin
				if(fail_comb==1||counter==0)begin
					nxt_state=FFIN;
				end
				else begin
					nxt_state=FIN;
				end
			end
			casex(full_line_flag)
				12'b1xxxxxxxxxxx:begin
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b01xxxxxxxxxx:begin
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b001xxxxxxxxx:begin
					tetris_nxt[9]=tetris_ff[10];
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b0001xxxxxxxx:begin
					tetris_nxt[8]=tetris_ff[9];
					tetris_nxt[9]=tetris_ff[10];
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b00001xxxxxxx:begin
					tetris_nxt[7]=tetris_ff[8];
					tetris_nxt[8]=tetris_ff[9];
					tetris_nxt[9]=tetris_ff[10];
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b000001xxxxxx:begin
					tetris_nxt[6]=tetris_ff[7];
					tetris_nxt[7]=tetris_ff[8];
					tetris_nxt[8]=tetris_ff[9];
					tetris_nxt[9]=tetris_ff[10];
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b0000001xxxxx:begin
					tetris_nxt[5]=tetris_ff[6];
					tetris_nxt[6]=tetris_ff[7];
					tetris_nxt[7]=tetris_ff[8];
					tetris_nxt[8]=tetris_ff[9];
					tetris_nxt[9]=tetris_ff[10];
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b00000001xxxx:begin
					tetris_nxt[4]=tetris_ff[5];
					tetris_nxt[5]=tetris_ff[6];
					tetris_nxt[6]=tetris_ff[7];
					tetris_nxt[7]=tetris_ff[8];
					tetris_nxt[8]=tetris_ff[9];
					tetris_nxt[9]=tetris_ff[10];
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b000000001xxx:begin
					tetris_nxt[3]=tetris_ff[4];
					tetris_nxt[4]=tetris_ff[5];
					tetris_nxt[5]=tetris_ff[6];
					tetris_nxt[6]=tetris_ff[7];
					tetris_nxt[7]=tetris_ff[8];
					tetris_nxt[8]=tetris_ff[9];
					tetris_nxt[9]=tetris_ff[10];
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b0000000001xx:begin
					tetris_nxt[2]=tetris_ff[3];
					tetris_nxt[3]=tetris_ff[4];
					tetris_nxt[4]=tetris_ff[5];
					tetris_nxt[5]=tetris_ff[6];
					tetris_nxt[6]=tetris_ff[7];
					tetris_nxt[7]=tetris_ff[8];
					tetris_nxt[8]=tetris_ff[9];
					tetris_nxt[9]=tetris_ff[10];
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b00000000001x:begin
					tetris_nxt[1]=tetris_ff[2];
					tetris_nxt[2]=tetris_ff[3];
					tetris_nxt[3]=tetris_ff[4];
					tetris_nxt[4]=tetris_ff[5];
					tetris_nxt[5]=tetris_ff[6];
					tetris_nxt[6]=tetris_ff[7];
					tetris_nxt[7]=tetris_ff[8];
					tetris_nxt[8]=tetris_ff[9];
					tetris_nxt[9]=tetris_ff[10];
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				12'b000000000001:begin
					tetris_nxt[0]=tetris_ff[1];
					tetris_nxt[1]=tetris_ff[2];
					tetris_nxt[2]=tetris_ff[3];
					tetris_nxt[3]=tetris_ff[4];
					tetris_nxt[4]=tetris_ff[5];
					tetris_nxt[5]=tetris_ff[6];
					tetris_nxt[6]=tetris_ff[7];
					tetris_nxt[7]=tetris_ff[8];
					tetris_nxt[8]=tetris_ff[9];
					tetris_nxt[9]=tetris_ff[10];
					tetris_nxt[10]=tetris_ff[11];
					tetris_nxt[11]=tetris_ff[12];
					tetris_nxt[12]=tetris_ff[13];
					tetris_nxt[13]=0;
				end
				default:begin
					tetris_nxt=tetris_ff;
				end
			endcase

		end
		FIN:begin
			nxt_state=IDLE;
			
		end
		FFIN:begin
			nxt_state=IDLE;
			for(i=0;i<=13;i=i+1)begin
				tetris_nxt[i]=6'b0;
			end
			counter_nxt=0;
		end
		default:begin
			nxt_state=cur_state;
		end
	endcase
end
always@*begin
	if(cur_state==IDLE)begin
		score_comb=score_ff;
	end
	else if(cur_state==SHIFT)begin
		if(|full_line_flag)begin
			score_comb=score_ff+1;
		end
		else begin
			score_comb=score_ff;
		end
	end
	else if(cur_state==FFIN)begin
		score_comb=0;
	end
	else begin
		score_comb=score_ff;
	end
end
endmodule