//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/9
//		Version		: v1.0
//   	File Name   : MDC.v
//   	Module Name : MDC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "HAMMING_IP.v"
//synopsys translate_on

module MDC(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Output signals
    out_valid, 
	out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [8:0] in_mode;
input [14:0] in_data;

output reg out_valid;
output reg [206:0] out_data;
integer i,j;
typedef enum reg[2:0]{IDLE=0 ,IN=1 ,CAL2=2 ,CAL3=3 ,CAL4=4 ,OUT=5,WAIT=6 }state;
state cur_state,nxt_state;
reg [8:0]in_mode_ff;
reg [4:0]mode_ff,in_mode_decoded;
reg [2:0]counter_row,counter_column;
reg [3:0]counter_st;
reg [14:0]in_data_ff;
reg signed[10:0] in_data_decoded,img[0:3][0:3],img_nxt[0:3][0:3];
reg signed[10:0] m1_nxt,m1_ff,m2_nxt,m2_ff,m3_nxt,m3_ff,m4_ff,m4_nxt;
reg signed[21:0] r1,r2,r1_ff,r2_ff;
reg signed[50:0] sum_nxt,sum_ff;
reg signed[206:0]out_comb,out_ff;
reg signed [11:0] weight;
reg signed[43:0]mul_res;
// ===============================================================
// Design
// ===============================================================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cur_state<=IDLE;
    end
    else begin
        cur_state<=nxt_state;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        counter_st<=0;
    end
    else begin
        case(cur_state)
            IN,WAIT:
                counter_st<=0;
            CAL3:
                counter_st<=(counter_st==5)?0:counter_st+1;
            CAL4:
                counter_st<=(counter_column==5)?counter_st+1:counter_st;
            default:
                counter_st<=0;
        endcase
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        counter_row<=0;
        counter_column<=0;
    end
    else begin
        case(cur_state)
            IDLE:begin
                counter_row<=0;
                counter_column<=0;
            end
            IN:begin
                counter_row<=(counter_column==3)?counter_row+1:counter_row;
                counter_column<=(counter_column==3)?0:counter_column+1;
            end
            WAIT:begin
                counter_row<=0;
                counter_column<=0;
            end
            CAL2:begin
                counter_row<=(counter_column==2)?counter_row+1:counter_row;
                counter_column<=(counter_column==2)?0:counter_column+1;
            end
            CAL3:begin
                counter_row<=(counter_column==1&&counter_st==5)?counter_row+1:counter_row;
                if(counter_column==0&&counter_st==5)
                    counter_column<=1;
                else if(counter_column==1&&counter_st==5)
                    counter_column<=0;
                else 
                    counter_column<=counter_column;
            end
            CAL4:begin
                counter_row<=0;
                counter_column<=(counter_column==5)?0:counter_column+1;
            end
            OUT:begin
                counter_row<=0;
                counter_column<=0;
            end
        endcase
    end
end
// ===============================================================
// FSM
// ===============================================================
always@*begin
    nxt_state=cur_state;
    case(cur_state)
        IDLE:begin
            if(in_valid)
                nxt_state=IN;
            else 
                nxt_state=cur_state;
        end
        IN:begin
            if(counter_row==3&&counter_column==3)
                nxt_state=WAIT;
            else 
                nxt_state=cur_state;
        end
        WAIT:begin
            case(mode_ff)
                5'b00100: nxt_state=CAL2;
                5'b00110: nxt_state=CAL3;
                5'b10110: nxt_state=CAL4;
            endcase
        end
        CAL2:begin
            if(counter_row==3&&counter_column==0)
                nxt_state=OUT;
            else
                nxt_state=cur_state;
        end
        CAL3:begin
            if(counter_row==2&&counter_st==2)
                nxt_state=OUT;
            else 
                nxt_state=cur_state;
        end
        CAL4:begin
            if(counter_st==4&&counter_column==2)
                nxt_state=OUT;
            else 
                nxt_state=cur_state;
        end
        OUT:begin
            nxt_state=IDLE;
        end
    endcase
end
// ===============================================================
// read decoded data
// ===============================================================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_data_ff<=0;
    end
    else begin
        if(in_valid)
            in_data_ff<=in_data;
        else 
            in_data_ff<=0;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<=3;i=i+1)begin
            for(j=0;j<=3;j=j+1)begin
                img[i][j]<=0;
            end
        end
    end
    else begin
        for(i=0;i<=3;i=i+1)begin
            for(j=0;j<=3;j=j+1)begin
                img[i][j]<=img_nxt[i][j];
            end
        end
    end 
end
always@*begin
    for(i=0;i<=3;i=i+1)begin
        for(j=0;j<=3;j=j+1)begin
            img_nxt[i][j]=img[i][j];
        end
    end
    case(cur_state)
        IN:begin
            img_nxt[counter_row][counter_column]=in_data_decoded;
        end
        default:begin
            for(i=0;i<=3;i=i+1)begin
                for(j=0;j<=3;j=j+1)begin
                    img_nxt[i][j]=img[i][j];
                end
            end
        end
    endcase
end
HAMMING_IP #(.IP_BIT(11)) (.IN_code(in_data_ff),.OUT_code(in_data_decoded));

// ===============================================================
// read decoded mode
// ===============================================================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        mode_ff<=0;
    end
    else if(cur_state==IN&&counter_row==0&&counter_column==0)begin
        mode_ff<=in_mode_decoded;
    end
    else begin
        mode_ff<=mode_ff;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_mode_ff<=0;
    end
    else begin
        if(in_valid)
            in_mode_ff<=in_mode;
        else 
            in_mode_ff<=0;
    end
end
HAMMING_IP #(.IP_BIT(5))  (.IN_code(in_mode_ff),.OUT_code(in_mode_decoded));

// ===============================================================
// determinant
// ===============================================================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        m1_ff<=0;
        m2_ff<=0;
        m3_ff<=0;
        m4_ff<=0;
        r1_ff<=0;
        r2_ff<=0;
    end
    else begin
        m1_ff<=m1_nxt;
        m2_ff<=m2_nxt;
        m3_ff<=m3_nxt;
        m4_ff<=m4_nxt;
        r1_ff<=r1;
        r2_ff<=r2;
    end
    
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        out_ff<=207'd0;
    else 
        out_ff<=out_comb;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        sum_ff<=0;
    else 
        sum_ff<=sum_nxt;
end
always@*begin
    r1=m1_ff*m2_ff;
    r2=m3_ff*m4_ff;
    mul_res=r1_ff*r2_ff;
end
always@*begin
    m1_nxt=0;
    m2_nxt=0;
    m3_nxt=0;
    m4_nxt=1;
    case(cur_state)
        CAL2:begin
            if(counter_row<=2)begin
                m1_nxt=img[counter_row][counter_column];
                m2_nxt=img[counter_row+1][counter_column+1];
                m3_nxt=img[counter_row+1][counter_column];
                m4_nxt=img[counter_row][counter_column+1];
            end
        end
        CAL3:begin
            case(counter_st)
                0:begin
                    m1_nxt=img[counter_row][counter_column];
                    m2_nxt=img[counter_row+1][counter_column+1];
                    m3_nxt=img[counter_row+2][counter_column+2];
                    m4_nxt=1;
                end
                1:begin
                    m1_nxt=img[counter_row+2][counter_column];
                    m2_nxt=img[counter_row][counter_column+1];
                    m3_nxt=img[counter_row+1][counter_column+2];
                    m4_nxt=1;
                end
                2:begin
                    m1_nxt=img[counter_row+1][counter_column];
                    m2_nxt=img[counter_row+2][counter_column+1];
                    m3_nxt=img[counter_row][counter_column+2];
                    m4_nxt=1;
                end
                3:begin
                    m1_nxt=img[counter_row][counter_column+2];
                    m2_nxt=img[counter_row+1][counter_column+1];
                    m3_nxt=img[counter_row+2][counter_column];
                    m4_nxt=1;
                end
                4:begin
                    m1_nxt=img[counter_row][counter_column];
                    m2_nxt=img[counter_row+2][counter_column+1];
                    m3_nxt=img[counter_row+1][counter_column+2];
                    m4_nxt=1;
                end
                5:begin
                    m1_nxt=img[counter_row][counter_column+1];
                    m2_nxt=img[counter_row+1][counter_column];
                    m3_nxt=img[counter_row+2][counter_column+2];
                    m4_nxt=1;
                end
                default:begin
                    m1_nxt=0;
                    m2_nxt=0;
                    m3_nxt=0;
                    m4_nxt=0;
                end
            endcase
        end
        CAL4:begin
            m4_nxt=1;
            case(counter_st)
                
                0:begin
                    case(counter_column)
                        0:begin
                            m1_nxt=img[1][1];
                            m2_nxt=img[2][2];
                            m3_nxt=img[3][3];
                        end
                        1:begin
                            m1_nxt=img[1][2];
                            m2_nxt=img[2][3];
                            m3_nxt=img[3][1];
                        end
                        2:begin
                            m1_nxt=img[1][3];
                            m2_nxt=img[2][1];
                            m3_nxt=img[3][2];
                        end
                        3:begin
                            m1_nxt=img[1][3];
                            m2_nxt=img[2][2];
                            m3_nxt=img[3][1];
                        end
                        4:begin
                            m1_nxt=img[1][1];
                            m2_nxt=img[2][3];
                            m3_nxt=img[3][2];
                        end
                        5:begin
                            m1_nxt=img[1][2];
                            m2_nxt=img[2][1];
                            m3_nxt=img[3][3];
                        end
                    endcase
                end
                1:begin
                    case(counter_column)
                        0:begin
                            m1_nxt=img[1][0];
                            m2_nxt=img[2][2];
                            m3_nxt=img[3][3];
                        end
                        1:begin
                            m1_nxt=img[1][2];
                            m2_nxt=img[2][3];
                            m3_nxt=img[3][0];
                        end
                        2:begin
                            m1_nxt=img[1][3];
                            m2_nxt=img[2][0];
                            m3_nxt=img[3][2];
                        end
                        3:begin
                            m1_nxt=img[1][3];
                            m2_nxt=img[2][2];
                            m3_nxt=img[3][0];
                        end
                        4:begin
                            m1_nxt=img[1][0];
                            m2_nxt=img[2][3];
                            m3_nxt=img[3][2];
                        end
                        5:begin
                            m1_nxt=img[1][2];
                            m2_nxt=img[2][0];
                            m3_nxt=img[3][3];
                        end
                    endcase
                end
                2:begin
                    case(counter_column)
                        0:begin
                            m1_nxt=img[1][0];
                            m2_nxt=img[2][1];
                            m3_nxt=img[3][3];
                        end
                        1:begin
                            m1_nxt=img[1][1];
                            m2_nxt=img[2][3];
                            m3_nxt=img[3][0];
                        end
                        2:begin
                            m1_nxt=img[1][3];
                            m2_nxt=img[2][0];
                            m3_nxt=img[3][1];
                        end
                        3:begin
                            m1_nxt=img[1][3];
                            m2_nxt=img[2][1];
                            m3_nxt=img[3][0];
                        end
                        4:begin
                            m1_nxt=img[1][0];
                            m2_nxt=img[2][3];
                            m3_nxt=img[3][1];
                        end
                        5:begin
                            m1_nxt=img[1][1];
                            m2_nxt=img[2][0];
                            m3_nxt=img[3][3];
                        end
                    endcase
                end
                3:begin
                    case(counter_column)
                        0:begin
                            m1_nxt=img[1][0];
                            m2_nxt=img[2][1];
                            m3_nxt=img[3][2];
                        end
                        1:begin
                            m1_nxt=img[1][1];
                            m2_nxt=img[2][2];
                            m3_nxt=img[3][0];
                        end
                        2:begin
                            m1_nxt=img[1][2];
                            m2_nxt=img[2][0];
                            m3_nxt=img[3][1];
                        end
                        3:begin
                            m1_nxt=img[1][2];
                            m2_nxt=img[2][1];
                            m3_nxt=img[3][0];
                        end
                        4:begin
                            m1_nxt=img[1][0];
                            m2_nxt=img[2][2];
                            m3_nxt=img[3][1];
                        end
                        5:begin
                            m1_nxt=img[1][1];
                            m2_nxt=img[2][0];
                            m3_nxt=img[3][2];
                        end
                    endcase
                end
                
            endcase
        end
    endcase
end
always@(*)begin
    sum_nxt=0;
    case(cur_state)
        IN,WAIT:begin
            sum_nxt=0;
        end
        CAL2:begin
            sum_nxt=r1-r2;
        end
        CAL3:begin
            sum_nxt=0;
            case(counter_st)
                2:begin
                    sum_nxt=mul_res;
                end
                3,4:begin
                    sum_nxt=sum_ff+mul_res;
                end
                5,0,1:begin
                    sum_nxt=sum_ff-mul_res;
                end
            endcase
        end
        CAL4:begin
            sum_nxt=0;
            case(counter_column)
                2:begin
                    sum_nxt=mul_res;
                end
                3,4:begin
                    sum_nxt=sum_ff+mul_res;
                end
                5,0,1:begin
                    sum_nxt=sum_ff-mul_res;
                end
            endcase
        end
    endcase
end

always@(*)begin //out_comb
    out_comb=out_ff;
    case(cur_state)
        IDLE:
            out_comb=207'd0;
        IN,WAIT:
            out_comb=207'd0;
        CAL2:begin
            if(!(counter_row==0&&counter_column==0))begin
                out_comb=out_ff<<23;
                out_comb[22:0]=sum_nxt[22:0];
            end
        end
        CAL3:begin
            if(counter_st==2)begin
                out_comb=out_ff<<51;
                out_comb[206:204]=3'b000;
                out_comb[50:0]=sum_ff[50:0];
            end
            else 
                out_comb=out_ff;
        end
        CAL4:begin
            if(counter_column==2&&counter_st!=0)begin
                out_comb=(sum_ff*weight)+out_ff;
            end
            else 
                out_comb=out_ff;
        end
    endcase
end
always@*begin
    weight=0;
    if(cur_state==CAL4)begin
        case(counter_st)
            1:weight=img[0][0];
            2:weight= -img[0][1];
            3:weight= img[0][2];
            4:weight= -img[0][3];
        endcase
    end
    else begin
        weight=0;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_data<=207'd0;
    end
    else begin
        if(nxt_state==OUT)
            out_data<=out_comb;
        else
            out_data<=out_comb; 
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid<=207'd0;
    end
    else begin
        if(nxt_state==OUT)
            out_valid<=1;
        else
            out_valid<=0; 
    end
end











endmodule