/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / SA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SA(
    //Input signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
    );

input clk;
input rst_n;
input in_valid;
input cg_en;
input [3:0] T;
input signed [7:0] in_data;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [63:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
integer i,j;
genvar r,c;
typedef enum reg[3:0]{IDLE=0 ,INPUT=1, INPUT_K=3,INPUT_V=4,OUT=5}state;
state nxt_state,cur_state;
//==============================================//
//           reg & wire declaration             //
//==============================================//
reg signed [7:0] in_data_ff[0:7][0:7],wq[0:7][0:7],wq_nxt[0:7][0:7],w_K_ff,w_V_ff,in_data_nxt[0:7][0:7],in_ff,w_Q_ff;
reg signed [18:0] q[0:7][0:7],k[0:7][0:7],v[0:7][0:7],q_nxt[0:7][0:7],k_nxt[0:7][0:7],v_nxt[0:7][0:7];
reg signed [40:0] s[0:7][0:7],s_nxt[0:7][0:7];
reg signed [63:0] out_comb;
reg [3:0]T_ff;
reg [0:2] counter_row,counter_column,counter_row_nxt,counter_column_nxt; //
reg [0:6] counter_st,counter_st_nxt;
reg [1:0]flag;

reg signed[18:0]mul1[0:7];
reg signed[40:0]mul2[0:7];
reg signed[63:0]mul_res[0:7],mul_sum;

reg signed[7:0]mul_small1[0:7],mul_small2[0:7];
reg signed[18:0]mul_small_res[0:7],mul_small_sum;
reg out_valid_comb;
//==============================================//
//                  design                      //
//==============================================//

//==============================================//
//                  FSM		                    //
//==============================================//
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cur_state<=IDLE;
	end
	else begin
		cur_state<=nxt_state;
	end
end
always@(*)begin
	nxt_state=cur_state;
	case (cur_state)
		IDLE:begin
			if(in_valid)begin
				nxt_state=INPUT;
			end
		end
		INPUT:begin
			if(counter_row==7&&counter_column==7)begin
				nxt_state=INPUT_K;
			end
		end
		INPUT_K:begin
			if(counter_row==7&&counter_column==7)begin
				nxt_state=INPUT_V;
			end
		end
		INPUT_V:begin
			if(counter_row==7&&counter_column==7)begin
				nxt_state=OUT;
			end
		end
		OUT:begin
			if(counter_row==T_ff-1&&counter_column==7)
				nxt_state=IDLE;
		end
	endcase
end

//==============================================//
//                  counter                      //
//==============================================//
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		counter_column<=0;
	end
	else begin
		case(cur_state)
			IDLE:begin 
				counter_column<=0;
			end
			INPUT:begin
				counter_column<=(counter_column==7)?0:counter_column+1;
			end
			INPUT_K:begin
				counter_column<=(counter_column==7)?0:counter_column+1;
			end
			INPUT_V:begin
				counter_column<=(counter_column==7)?0:counter_column+1;
			end
			OUT:begin
				counter_column<=(counter_column==7)?0:counter_column+1;
			end
			default:begin
				counter_column<=counter_column+1;
			end
		endcase
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		counter_row<=0;
	end
	else begin
		case(cur_state)
			IDLE:begin
				counter_row<=0;
			end
			INPUT:begin
				if(counter_column==7)begin
					if(counter_row==7)begin
						counter_row<=0;
					end
					else 
						counter_row<=counter_row+1;
				end
			end
			INPUT_K:begin
				if(counter_column==7)begin
					if(counter_row==7)begin
						counter_row<=0;
					end
					else 
						counter_row<=counter_row+1;
				end
			end
			INPUT_V:begin
				if(counter_column==7)begin
					if(counter_row==7)begin
						counter_row<=0;
					end
					else 
						counter_row<=counter_row+1;
				end
			end
			OUT:begin
				if(counter_column==7)begin
					if(counter_row==T_ff-1)begin
						counter_row<=0;
					end
					else 
						counter_row<=counter_row+1;
				end
			end
			default:begin
				counter_row<=counter_row+1;
			end
		endcase
	end
end
//==============================================//
//                  INPUT	                    //
//==============================================//

wire in_ff_clk;
GATED_OR GATED_in_ff (.CLOCK(clk), .SLEEP_CTRL(!(nxt_state==INPUT&&(counter_row<T_ff)||cur_state==IDLE) && cg_en), .RST_N(rst_n), .CLOCK_GATED(in_ff_clk));
always@(posedge in_ff_clk or negedge rst_n)begin
	if(!rst_n)begin
		in_ff<=0;
	end
	else begin
		if(nxt_state==INPUT&&counter_row<T_ff)begin
			in_ff<=in_data;
		end
		else begin
			in_ff<=0;
		end
	end
end
wire w_Q_ff_clk;
GATED_OR GATED_w_Q_ff (.CLOCK(clk), .SLEEP_CTRL(!(nxt_state==INPUT||cur_state==IDLE) && cg_en), .RST_N(rst_n), .CLOCK_GATED(w_Q_ff_clk));
always@(posedge w_Q_ff_clk or negedge rst_n)begin
	if(!rst_n)begin
		w_Q_ff<=0;
	end
	else begin
		if(nxt_state==INPUT)begin
			w_Q_ff<=w_Q;
		end
		else begin
			w_Q_ff<=0;
		end
	end
end

wire w_k_ff_clk;
GATED_OR GATED_w_k_ff (.CLOCK(clk), .SLEEP_CTRL(!(nxt_state==INPUT_K||cur_state==IDLE) && cg_en), .RST_N(rst_n), .CLOCK_GATED(w_k_ff_clk));
always@(posedge w_k_ff_clk or negedge rst_n)begin
	if(!rst_n)begin
		w_K_ff<=0;
	end
	else begin
		if(nxt_state==INPUT_K)begin
			w_K_ff<=w_K;
		end
		else begin
			w_K_ff<=0;
		end
	end
end
wire w_v_ff_clk;
GATED_OR GATED_w_v_ff (.CLOCK(clk), .SLEEP_CTRL(!(nxt_state==INPUT_V||cur_state==IDLE) && cg_en), .RST_N(rst_n), .CLOCK_GATED(w_v_ff_clk));
always@(posedge w_v_ff_clk or negedge rst_n)begin
	if(!rst_n)begin
		w_V_ff<=0;
	end
	else begin
		if(nxt_state==INPUT_V)begin
			w_V_ff<=w_V;
		end
		else begin
			w_V_ff<=0;
		end
	end
end
wire T_ff_clk;
GATED_OR GATED_T_ff (.CLOCK(clk), .SLEEP_CTRL(!(cur_state==IDLE) && cg_en), .RST_N(rst_n), .CLOCK_GATED(T_ff_clk));
always@(posedge T_ff_clk or negedge rst_n)begin
	if(!rst_n)begin
		T_ff<=8;
	end
	else begin
		if(in_valid&&cur_state==IDLE)
			T_ff<=T;
	end
end
//in_data_ff

wire in_data_ff_clk[0:7][0:7];
generate
	for(r=0; r<=7; r=r+1)begin
    	for(c=0; c<=7; c=c+1) begin
			GATED_OR GATED_in_data_ff (.CLOCK(clk), .SLEEP_CTRL( !((cur_state==INPUT&&counter_row==r&&counter_column==c)||cur_state==OUT)&& cg_en), .RST_N(rst_n), .CLOCK_GATED(in_data_ff_clk[r][c]));
			always@(posedge in_data_ff_clk[r][c] or negedge rst_n)begin
                if(!rst_n)begin
                    in_data_ff[r][c]<=0;
                end
                else begin
                    in_data_ff[r][c]<=in_data_nxt[r][c];
                end
                
            end
		end
	end
endgenerate
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				in_data_ff[i][j]<=0;
			end
		end
		
	end
	else begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				in_data_ff[i][j]<=in_data_nxt[i][j];
			end
		end
	end
end
*/
always@(*)begin
    for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				in_data_nxt[i][j]=in_data_ff[i][j];
			end
		end
    
    case(cur_state)
		INPUT:begin
			if((counter_row<T_ff))
				in_data_nxt[counter_row][counter_column]=in_ff;
		end
		OUT:begin
			for(i=0;i<=7;i++)begin
				for(j=0;j<=7;j++)begin
					in_data_nxt[i][j]=0;
				end
			end
		end
		default:begin
			for(i=0;i<=7;i++)begin
				for(j=0;j<=7;j++)begin
					in_data_nxt[i][j]=in_data_ff[i][j];
				end
			end
		end
		
	endcase
end
//======================================================//
//                         read Wq                      //
//======================================================//
wire wq_clk[0:7][0:7];
generate
	for(r=0; r<=7; r=r+1)begin
    	for(c=0; c<=7; c=c+1) begin
			GATED_OR GATED_wq (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==INPUT)&&counter_row==r&&counter_column==c)&& cg_en), .RST_N(rst_n), .CLOCK_GATED(wq_clk[r][c]));
			always@(posedge wq_clk[r][c] or negedge rst_n)begin
                if(!rst_n)begin
                    wq[r][c]<=0;
                end
                else begin
                    wq[r][c]<=wq_nxt[r][c];
                end
                
            end
		end
	end
endgenerate
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				wq[i][j]<=0;
			end
		end

	end
	else begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				wq[i][j]<=wq_nxt[i][j];
			end
		end
	end
end
*/
always @(*) begin
	for(i=0;i<=7;i++)begin
		for(j=0;j<=7;j++)begin
			wq_nxt[i][j]=wq[i][j];
		end
	end
	case(cur_state)
		INPUT:begin
			wq_nxt[counter_row][counter_column]=w_Q_ff;
			
		end
		default:begin
			for(i=0;i<=7;i++)begin
				for(j=0;j<=7;j++)begin
					wq_nxt[i][j]=wq[i][j];
				end
			end
		end
	endcase
end
//==============================================//
//            INPUT_K and CAL k,q               //
//==============================================//
wire k_clk[0:7][0:7];
generate
    for(c=0; c<=7; c=c+1) begin
		GATED_OR GATED_k0 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_K))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(k_clk[0][c]));
        GATED_OR GATED_k1 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_K))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(k_clk[1][c]));
        GATED_OR GATED_k2 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_K))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(k_clk[2][c]));
        GATED_OR GATED_k3 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_K))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(k_clk[3][c]));
        GATED_OR GATED_k4 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_K))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(k_clk[4][c]));
        GATED_OR GATED_k5 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_K))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(k_clk[5][c]));
        GATED_OR GATED_k6 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_K))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(k_clk[6][c]));
        GATED_OR GATED_k7 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_K))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(k_clk[7][c]));
		always@(posedge k_clk[0][c] or negedge rst_n)begin
            if(!rst_n)begin
                k[0][c]<=0;
            end
            else begin
                k[0][c]<=k_nxt[0][c];
            end
            
        end
        always@(posedge k_clk[1][c] or negedge rst_n)begin
            if(!rst_n)begin
                k[1][c]<=0;
            end
            else begin
                k[1][c]<=k_nxt[1][c];
            end
            
        end
        always@(posedge k_clk[2][c] or negedge rst_n)begin
            if(!rst_n)begin
                k[2][c]<=0;
            end
            else begin
                k[2][c]<=k_nxt[2][c];
            end
            
        end
        always@(posedge k_clk[3][c] or negedge rst_n)begin
            if(!rst_n)begin
                k[3][c]<=0;
            end
            else begin
                k[3][c]<=k_nxt[3][c];
            end
            
        end
        always@(posedge k_clk[4][c] or negedge rst_n)begin
            if(!rst_n)begin
                k[4][c]<=0;
            end
            else begin
                k[4][c]<=k_nxt[4][c];
            end
            
        end
        always@(posedge k_clk[5][c] or negedge rst_n)begin
            if(!rst_n)begin
                k[5][c]<=0;
            end
            else begin
                k[5][c]<=k_nxt[5][c];
            end
            
        end
        always@(posedge k_clk[6][c] or negedge rst_n)begin
            if(!rst_n)begin
                k[6][c]<=0;
            end
            else begin
                k[6][c]<=k_nxt[6][c];
            end
            
        end
        always@(posedge k_clk[7][c] or negedge rst_n)begin
            if(!rst_n)begin
                k[7][c]<=0;
            end
            else begin
                k[7][c]<=k_nxt[7][c];
            end
            
        end
	end
	
endgenerate
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				k[i][j]<=0;
			end
		end
	end
	else begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				k[i][j]<=k_nxt[i][j];
			end
		end
	end
end
*/
always @(*) begin
	for(i=0;i<=7;i++)begin
		for(j=0;j<=7;j++)begin
			k_nxt[i][j]=k[i][j];
		end
	end
	case(cur_state)
		IDLE:begin
			for(i=0;i<=7;i++)begin
				for(j=0;j<=7;j++)begin
					k_nxt[i][j]=0;
				end
			end
		end
		INPUT_K:begin
			k_nxt[0][counter_column]=k[0][counter_column]+mul_small_res[0];
			k_nxt[1][counter_column]=k[1][counter_column]+mul_small_res[1];
			k_nxt[2][counter_column]=k[2][counter_column]+mul_small_res[2];
			k_nxt[3][counter_column]=k[3][counter_column]+mul_small_res[3];
			k_nxt[4][counter_column]=k[4][counter_column]+mul_small_res[4];
			k_nxt[5][counter_column]=k[5][counter_column]+mul_small_res[5];
			k_nxt[6][counter_column]=k[6][counter_column]+mul_small_res[6];
			k_nxt[7][counter_column]=k[7][counter_column]+mul_small_res[7];
		end
	endcase
end

//cal q
wire q_clk[0:7][0:7];
generate
	for(r=0; r<=7; r=r+1)begin
    	for(c=0; c<=7; c=c+1) begin
			GATED_OR GATED_q (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(cur_state==INPUT_K&&counter_row==r&&counter_column==c))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(q_clk[r][c]));
			always@(posedge q_clk[r][c] or negedge rst_n)begin
                if(!rst_n)begin
                    q[r][c]<=0;
                end
                else begin
                    q[r][c]<=q_nxt[r][c];
                end
                
            end
		end
	end
endgenerate
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				q[i][j]<=0;
			end
		end
	end
	else begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				q[i][j]<=q_nxt[i][j];
			end
		end
	end
end
*/
always@(*)begin
	for(i=0;i<=7;i++)begin
		for(j=0;j<=7;j++)begin
			q_nxt[i][j]=q[i][j];
		end
	end
	case(cur_state)
		IDLE:begin
			for(i=0;i<=7;i++)begin
				for(j=0;j<=7;j++)begin
					q_nxt[i][j]=0;
				end
			end
		end
		INPUT_K:begin
			q_nxt[counter_row][counter_column]=mul_sum;
		end
	endcase
end
//==============================================//
//            INPUT_V and CAL v,s               //
//==============================================//
wire v_clk[0:7][0:7];
generate
    for(c=0; c<=7; c=c+1) begin
		GATED_OR GATED_v0 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_V))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(v_clk[0][c]));
        GATED_OR GATED_v1 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_V))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(v_clk[1][c]));
        GATED_OR GATED_v2 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_V))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(v_clk[2][c]));
        GATED_OR GATED_v3 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_V))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(v_clk[3][c]));
        GATED_OR GATED_v4 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_V))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(v_clk[4][c]));
        GATED_OR GATED_v5 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_V))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(v_clk[5][c]));
        GATED_OR GATED_v6 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_V))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(v_clk[6][c]));
        GATED_OR GATED_v7 (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(counter_column==c&&cur_state==INPUT_V))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(v_clk[7][c]));
		always@(posedge v_clk[0][c] or negedge rst_n)begin
            if(!rst_n)begin
                v[0][c]<=0;
            end
            else begin
                v[0][c]<=v_nxt[0][c];
            end
            
        end
        always@(posedge v_clk[1][c] or negedge rst_n)begin
            if(!rst_n)begin
                v[1][c]<=0;
            end
            else begin
                v[1][c]<=v_nxt[1][c];
            end
            
        end
        always@(posedge v_clk[2][c] or negedge rst_n)begin
            if(!rst_n)begin
                v[2][c]<=0;
            end
            else begin
                v[2][c]<=v_nxt[2][c];
            end
            
        end
        always@(posedge v_clk[3][c] or negedge rst_n)begin
            if(!rst_n)begin
                v[3][c]<=0;
            end
            else begin
                v[3][c]<=v_nxt[3][c];
            end
            
        end
        always@(posedge v_clk[4][c] or negedge rst_n)begin
            if(!rst_n)begin
                v[4][c]<=0;
            end
            else begin
                v[4][c]<=v_nxt[4][c];
            end
            
        end
        always@(posedge v_clk[5][c] or negedge rst_n)begin
            if(!rst_n)begin
                v[5][c]<=0;
            end
            else begin
                v[5][c]<=v_nxt[5][c];
            end
            
        end
        always@(posedge v_clk[6][c] or negedge rst_n)begin
            if(!rst_n)begin
                v[6][c]<=0;
            end
            else begin
                v[6][c]<=v_nxt[6][c];
            end
            
        end
        always@(posedge v_clk[7][c] or negedge rst_n)begin
            if(!rst_n)begin
                v[7][c]<=0;
            end
            else begin
                v[7][c]<=v_nxt[7][c];
            end
            
        end
	end
	
endgenerate
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				v[i][j]<=0;
			end
		end

	end
	else begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				v[i][j]<=v_nxt[i][j];
			end
		end
	end
end
*/
always @(*) begin
	for(i=0;i<=7;i++)begin
		for(j=0;j<=7;j++)begin
			v_nxt[i][j]=v[i][j];
		end
	end
	case(cur_state)
		IDLE:begin
			for(i=0;i<=7;i++)begin
				for(j=0;j<=7;j++)begin
					v_nxt[i][j]=0;
				end
			end
		end
		INPUT_V:begin
			v_nxt[0][counter_column]=v[0][counter_column]+mul_small_res[0];
			v_nxt[1][counter_column]=v[1][counter_column]+mul_small_res[1];
			v_nxt[2][counter_column]=v[2][counter_column]+mul_small_res[2];
			v_nxt[3][counter_column]=v[3][counter_column]+mul_small_res[3];
			v_nxt[4][counter_column]=v[4][counter_column]+mul_small_res[4];
			v_nxt[5][counter_column]=v[5][counter_column]+mul_small_res[5];
			v_nxt[6][counter_column]=v[6][counter_column]+mul_small_res[6];
			v_nxt[7][counter_column]=v[7][counter_column]+mul_small_res[7];
		end
		default:begin //unused
			for(i=0;i<=7;i++)begin
				for(j=0;j<=7;j++)begin
					v_nxt[i][j]=v[i][j];
				end
			end
		end
	endcase
end
//cal s
wire s_clk[0:7][0:7];
generate
	for(r=0; r<=7; r=r+1)begin
    	for(c=0; c<=7; c=c+1) begin
			GATED_OR GATED_s (.CLOCK(clk), .SLEEP_CTRL( ~((cur_state==IDLE)||(cur_state==INPUT_V&&counter_row==r&&counter_column==c))&& cg_en), .RST_N(rst_n), .CLOCK_GATED(s_clk[r][c]));
			always@(posedge s_clk[r][c] or negedge rst_n)begin
                if(!rst_n)begin
                    s[r][c]<=0;
                end
                else begin
                    s[r][c]<=s_nxt[r][c];
                end
                
            end
		end
	end
endgenerate
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				s[i][j]<=0;
			end
		end
	end
	else begin
		for(i=0;i<=7;i++)begin
			for(j=0;j<=7;j++)begin
				s[i][j]<=s_nxt[i][j];
			end
		end
	end
end
*/
always@(*)begin
	for(i=0;i<=7;i++)begin
		for(j=0;j<=7;j++)begin
			s_nxt[i][j]=s[i][j];
		end
	end
	case(cur_state)
		IDLE:begin
			for(i=0;i<=7;i++)begin
				for(j=0;j<=7;j++)begin
					s_nxt[i][j]=0;
				end
			end
		end
		INPUT_V:begin
			s_nxt[counter_row][counter_column]=(mul_sum>=0)?mul_sum/3:0;
		end

	endcase
end

//==============================================//
//           cal P and output                   //
//==============================================//
/*always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_data<=0;
	end
	else begin
		out_data<=out_comb;
	end
end

always@(*)begin
	out_comb=0;
	case(cur_state)
		OUT:begin
			out_comb=mul_sum;
		end
		default:begin
			out_comb=0;
		end
	endcase
end
*/

always@(*)begin
    if(cur_state==OUT)begin
        out_data=mul_sum;
    end
	else begin
        out_data=0;
    end
end
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid<=0;
	end
	else begin
		out_valid<=out_valid_comb;
	end
end
always@(*)begin
	out_valid_comb=0;
	case(cur_state)
		OUT:begin
			out_valid_comb=1;
		end
		default:begin
			out_valid_comb=0;
		end
	endcase
end
*/
always@(*)begin
	if(cur_state==OUT)begin
        out_valid=1;
    end
	else begin
        out_valid=0;
    end
		
end
//==============================================//
//           multiplier   	                    //
//==============================================//
always@(*)begin
	mul1[0]=0;  mul2[0]=0;
	mul1[1]=0;  mul2[1]=0;
	mul1[2]=0;  mul2[2]=0;
	mul1[3]=0;  mul2[3]=0;
	mul1[4]=0;  mul2[4]=0;
	mul1[5]=0;  mul2[5]=0;
	mul1[6]=0;  mul2[6]=0;
	mul1[7]=0;  mul2[7]=0;
	case(cur_state)
		INPUT_K:begin
			mul1[0]=in_data_ff[counter_row][0];
			mul1[1]=in_data_ff[counter_row][1];
			mul1[2]=in_data_ff[counter_row][2];
			mul1[3]=in_data_ff[counter_row][3];
			mul1[4]=in_data_ff[counter_row][4];
			mul1[5]=in_data_ff[counter_row][5];
			mul1[6]=in_data_ff[counter_row][6];
			mul1[7]=in_data_ff[counter_row][7];

			mul2[0]=wq[0][counter_column];
			mul2[1]=wq[1][counter_column];
			mul2[2]=wq[2][counter_column];
			mul2[3]=wq[3][counter_column];
			mul2[4]=wq[4][counter_column];
			mul2[5]=wq[5][counter_column];
			mul2[6]=wq[6][counter_column];
			mul2[7]=wq[7][counter_column];
		end
		INPUT_V:begin
			mul1[0]=q[counter_row][0]; mul2[0]=k[counter_column][0];
			mul1[1]=q[counter_row][1]; mul2[1]=k[counter_column][1];
			mul1[2]=q[counter_row][2]; mul2[2]=k[counter_column][2];
			mul1[3]=q[counter_row][3]; mul2[3]=k[counter_column][3];
			mul1[4]=q[counter_row][4]; mul2[4]=k[counter_column][4];
			mul1[5]=q[counter_row][5]; mul2[5]=k[counter_column][5];
			mul1[6]=q[counter_row][6]; mul2[6]=k[counter_column][6];
			mul1[7]=q[counter_row][7]; mul2[7]=k[counter_column][7];
		end
		
		OUT:begin
			mul2[0]=s[counter_row][0];mul1[0]=v[0][counter_column];
			mul2[1]=s[counter_row][1];mul1[1]=v[1][counter_column];
			mul2[2]=s[counter_row][2];mul1[2]=v[2][counter_column];
			mul2[3]=s[counter_row][3];mul1[3]=v[3][counter_column];
			mul2[4]=s[counter_row][4];mul1[4]=v[4][counter_column];
			mul2[5]=s[counter_row][5];mul1[5]=v[5][counter_column];
			mul2[6]=s[counter_row][6];mul1[6]=v[6][counter_column];
			mul2[7]=s[counter_row][7];mul1[7]=v[7][counter_column];
		end
		default:begin
			mul1[0]=0;  mul2[0]=0;
			mul1[1]=0;  mul2[1]=0;
			mul1[2]=0;  mul2[2]=0;
			mul1[3]=0;  mul2[3]=0;
			mul1[4]=0;  mul2[4]=0;
			mul1[5]=0;  mul2[5]=0;
			mul1[6]=0;  mul2[6]=0;
			mul1[7]=0;  mul2[7]=0;
		end
	endcase
	for(i=0;i<=7;i++)begin
		mul_res[i]=mul1[i]*mul2[i];
	end
	mul_sum=mul_res[0]+mul_res[1]+mul_res[2]+mul_res[3]+mul_res[4]+mul_res[5]+mul_res[6]+mul_res[7];
end
always@*begin
	mul_small1[0]=0;  mul_small2[0]=0;
	mul_small1[1]=0;  mul_small2[1]=0;
	mul_small1[2]=0;  mul_small2[2]=0;
	mul_small1[3]=0;  mul_small2[3]=0;
	mul_small1[4]=0;  mul_small2[4]=0;
	mul_small1[5]=0;  mul_small2[5]=0;
	mul_small1[6]=0;  mul_small2[6]=0;
	mul_small1[7]=0;  mul_small2[7]=0;
	case(cur_state)
		INPUT_K:begin
			mul_small1[0]=in_data_ff[0][counter_row];
			mul_small1[1]=in_data_ff[1][counter_row];
			mul_small1[2]=in_data_ff[2][counter_row];
			mul_small1[3]=in_data_ff[3][counter_row];
			mul_small1[4]=in_data_ff[4][counter_row];
			mul_small1[5]=in_data_ff[5][counter_row];
			mul_small1[6]=in_data_ff[6][counter_row];
			mul_small1[7]=in_data_ff[7][counter_row];
			mul_small2[0]=w_K_ff;
			mul_small2[1]=w_K_ff;
			mul_small2[2]=w_K_ff;
			mul_small2[3]=w_K_ff;
			mul_small2[4]=w_K_ff;
			mul_small2[5]=w_K_ff;
			mul_small2[6]=w_K_ff;
			mul_small2[7]=w_K_ff;
		end
		INPUT_V:begin
			mul_small1[0]=in_data_ff[0][counter_row];
			mul_small1[1]=in_data_ff[1][counter_row];
			mul_small1[2]=in_data_ff[2][counter_row];
			mul_small1[3]=in_data_ff[3][counter_row];
			mul_small1[4]=in_data_ff[4][counter_row];
			mul_small1[5]=in_data_ff[5][counter_row];
			mul_small1[6]=in_data_ff[6][counter_row];
			mul_small1[7]=in_data_ff[7][counter_row];
			mul_small2[0]=w_V_ff;
			mul_small2[1]=w_V_ff;
			mul_small2[2]=w_V_ff;
			mul_small2[3]=w_V_ff;
			mul_small2[4]=w_V_ff;
			mul_small2[5]=w_V_ff;
			mul_small2[6]=w_V_ff;
			mul_small2[7]=w_V_ff;
		end
	endcase
	for(i=0;i<=7;i++)begin
		mul_small_res[i]=mul_small1[i]*mul_small2[i];
	end
	mul_small_sum=mul_small_res[0]+mul_small_res[1]+mul_small_res[2]+mul_small_res[3]+mul_small_res[4]+mul_small_res[5]+mul_small_res[6]+mul_small_res[7];
end
endmodule