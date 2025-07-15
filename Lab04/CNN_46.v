//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//FSM NOT FINISH
module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
typedef enum reg[2:0]{IDLE=3'b000,CH1 = 3'b001,CH2 = 3'b10,CH3 = 3'b011,INPUT = 3'b100,MAXANDFULLY=3'b101,OUT=3'b110}state;
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel_ch1, Kernel_ch2, Weight;
input Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

integer i,j;
//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
state cur_state,nxt_state;
reg [7:0] counter,counter_nxt; // to 127
reg [inst_sig_width+inst_exp_width:0] Img_ff[0:6][0:6],img_nxt[0:6][0:6],Img_use[0:1][0:1];
reg Opt_ff;
reg [inst_sig_width+inst_exp_width:0] Kernel1_ff[0:11],Kernel2_ff[0:11];
reg [inst_sig_width+inst_exp_width:0] Kernel1_us00,Kernel1_us01,Kernel1_us10,Kernel1_us11,Kernel2_us00,Kernel2_us01,Kernel2_us10,Kernel2_us11;
reg [5:0]counter_st;
reg [3:0]counter_sort;
reg [inst_sig_width+inst_exp_width:0]a1,a2,a3,a4,b1,b2,b3,b4,A1,A2,A3,A4,B1,B2,B3,B4,c1,c2,C1,C2,d1,D1,d1_ff,D1_ff,t1,T1,t2,T2,Ftr1_nxt,Ftr2_nxt;
reg [inst_sig_width+inst_exp_width:0]Ftr1[0:5][0:5],Ftr2[0:5][0:5];
reg [inst_sig_width+inst_exp_width:0]cp[0:8],n1,n2,n3,n4,n5,n6,n7,n8,maximum_nxt,maximum_ff;
reg [inst_sig_width+inst_exp_width:0]exp_z_nxt,exp_negz_nxt,exp_z_ff,exp_negz_ff,exp_sub,exp_plus1,exp_add,div_nxt,dived_nxt,div_ff,dived_ff,act_ans_nxt,act_ans;
reg [inst_sig_width+inst_exp_width:0]weight_ff[0:2][0:7],weight_nxt[0:2][0:7],weight_choosed[0:2];
reg [inst_sig_width+inst_exp_width:0]mul0_nxt,mul1_nxt,mul2_nxt,mul0_ff,mul1_ff,mul2_ff;
reg [inst_sig_width+inst_exp_width:0]fully_ans0_ff,fully_ans1_ff,fully_ans2_ff,fully_ans0_nxt,fully_ans1_nxt,fully_ans2_nxt,fc_s0,fc_s1,fc_s2;
reg [inst_sig_width+inst_exp_width:0] exp_z1_ff,exp_z2_ff,exp_z3_ff,exp_z1_nxt,exp_z2_nxt,exp_z3_nxt,sumz,sumz_ff,exp_z1_ff1,exp_z2_ff1,exp_z3_ff1,final_ans_nxt;
reg out_valid_comb;
reg [inst_sig_width+inst_exp_width:0]final_div,final_dived,final_div_nxt;
reg [inst_sig_width+inst_exp_width:0]str0,str1,str2,str3,str4;
//---------------------------------------------------------------------
// IPs
//---------------------------------------------------------------------


//---------------------------------------------------------------------
// Design
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)begin //count the time
    if(!rst_n)begin
        counter<=0;
        cur_state<=INPUT;
    end
    else begin
        counter<=counter_nxt;
        cur_state<=nxt_state;
    end
end
//FSM
always@(posedge clk)begin
    if(nxt_state==cur_state)begin
        counter_st<=counter_st+1;
    end
    else begin
        counter_st<=0;
    end
end
always@*begin
    nxt_state=cur_state;
    case(cur_state)
        INPUT:begin
            if(counter_nxt==4) nxt_state=CH1;
        end
        CH1:begin
            if(counter_nxt==40) nxt_state=CH2;
        end
        CH2:begin
            if(counter_nxt==76)nxt_state=CH3;
        end
        CH3:begin
            if(counter_nxt==112)nxt_state=MAXANDFULLY;
        end
        MAXANDFULLY:begin
            if(counter==120)nxt_state=OUT;
        end
        OUT:begin
            if(counter==123)nxt_state=INPUT;
        end
    endcase
end

always@*begin //count the time
    if(in_valid)
        counter_nxt=counter+1;
    else if((counter>0&&counter< 123))
        counter_nxt=counter+1;
    else    
        counter_nxt=0;
end
always@(posedge clk)begin
    if(counter>=106&&counter<=113)
        counter_sort<=counter_sort+1;
    else begin
        counter_sort<=0;
    end
end
always@(posedge clk)begin
    weight_ff<=weight_nxt;
end
always@*begin
    weight_nxt=weight_ff;
    case(counter)
        0: weight_nxt[0][0]=Weight;
        1: weight_nxt[0][1]=Weight;
        2: weight_nxt[0][2]=Weight;
        3: weight_nxt[0][3]=Weight;
        4: weight_nxt[0][4]=Weight;
        5: weight_nxt[0][5]=Weight;
        6: weight_nxt[0][6]=Weight;
        7: weight_nxt[0][7]=Weight;
        8: weight_nxt[1][0]=Weight;
        9: weight_nxt[1][1]=Weight;
        10:weight_nxt[1][2]=Weight;
        11:weight_nxt[1][3]=Weight;
        12:weight_nxt[1][4]=Weight;
        13:weight_nxt[1][5]=Weight;
        14:weight_nxt[1][6]=Weight;
        15:weight_nxt[1][7]=Weight;
        16:weight_nxt[2][0]=Weight;
        17:weight_nxt[2][1]=Weight;
        18:weight_nxt[2][2]=Weight;
        19:weight_nxt[2][3]=Weight;
        20:weight_nxt[2][4]=Weight;
        21:weight_nxt[2][5]=Weight;
        22:weight_nxt[2][6]=Weight;
        23:weight_nxt[2][7]=Weight;
    endcase
end
always@(posedge clk or negedge rst_n)begin //Opt_ff
    if(!rst_n)
        Opt_ff<=0;
    else if(in_valid&&counter==0)
        Opt_ff<=Opt;
    else 
        Opt_ff<=Opt_ff;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<=6;i=i+1)begin
            for(j=0;j<=6;j=j+1)begin
                Img_ff[i][j]<=0;
            end 
        end
    end
    
    else begin
        Img_ff<=img_nxt;
    end
end
always@(posedge clk)begin
    if(counter==45)
        str0<=Img;
end
always@(posedge clk)begin
    if(counter==46)
        str1<=Img;
end
always@(posedge clk)begin
    if(counter==47)
        str2<=Img;
end
always@(posedge clk)begin
    if(counter==48)
        str3<=Img;
end
always@(posedge clk)begin
    if(counter==49)
        str4<=Img;
end
always@*begin //read image
    img_nxt=Img_ff;
    if(Opt_ff==1)begin
            img_nxt[0][0]=Img_ff[1][1];
            img_nxt[0][1]=Img_ff[1][1];
            img_nxt[0][2]=Img_ff[1][2];
            img_nxt[0][3]=Img_ff[1][3];
            img_nxt[0][4]=Img_ff[1][4];
            img_nxt[0][5]=Img_ff[1][5];
            img_nxt[0][6]=Img_ff[1][5];
            
            img_nxt[1][0]=Img_ff[1][1];
            img_nxt[1][6]=Img_ff[1][5];
            img_nxt[2][0]=Img_ff[2][1];
            img_nxt[2][6]=Img_ff[2][5];
            img_nxt[3][0]=Img_ff[3][1];
            img_nxt[3][6]=Img_ff[3][5];
            img_nxt[4][0]=Img_ff[4][1];
            img_nxt[4][6]=Img_ff[4][5];
            img_nxt[5][0]=Img_ff[5][1];
            img_nxt[5][6]=Img_ff[5][5];

            img_nxt[6][0]=Img_ff[5][1];
            img_nxt[6][1]=Img_ff[5][1];
            img_nxt[6][2]=Img_ff[5][2];
            img_nxt[6][3]=Img_ff[5][3];
            img_nxt[6][4]=Img_ff[5][4];
            img_nxt[6][5]=Img_ff[5][5];
            img_nxt[6][6]=Img_ff[5][5];
    end
    else if(Opt_ff==0)begin
        img_nxt[0][0]=0;
        img_nxt[0][1]=0;
        img_nxt[0][2]=0;
        img_nxt[0][3]=0;
        img_nxt[0][4]=0;
        img_nxt[0][5]=0;
        img_nxt[0][6]=0;
        
        img_nxt[1][0]=0;
        img_nxt[1][6]=0;
        img_nxt[2][0]=0;
        img_nxt[2][6]=0;
        img_nxt[3][0]=0;
        img_nxt[3][6]=0;
        img_nxt[4][0]=0;
        img_nxt[4][6]=0;
        img_nxt[5][0]=0;
        img_nxt[5][6]=0;

        img_nxt[6][0]=0;
        img_nxt[6][1]=0;
        img_nxt[6][2]=0;
        img_nxt[6][3]=0;
        img_nxt[6][4]=0;
        img_nxt[6][5]=0;
        img_nxt[6][6]=0;
    end
    case(counter)
        0, 25, 50: img_nxt[1][1]=Img;
        1, 26, 51: img_nxt[1][2]=Img;
        2, 27, 52: img_nxt[1][3]=Img;
        3, 28, 53: img_nxt[1][4]=Img;
        4, 29, 54: img_nxt[1][5]=Img;

        5, 30, 55: img_nxt[2][1]=Img;
        6, 31, 56: img_nxt[2][2]=Img;
        7, 32, 57: img_nxt[2][3]=Img;
        8, 33, 58: img_nxt[2][4]=Img;
        9, 34, 59: img_nxt[2][5]=Img;

        10, 35, 60: img_nxt[3][1]=Img;
        11, 36, 61: img_nxt[3][2]=Img;
        12, 37, 62: img_nxt[3][3]=Img;
        13, 38, 63: img_nxt[3][4]=Img;
        14, 39, 64: img_nxt[3][5]=Img;

        15, 40, 65: img_nxt[4][1]=Img;
        16, 41, 66: img_nxt[4][2]=Img;
        17, 42, 67: img_nxt[4][3]=Img;
        18, 43, 68: img_nxt[4][4]=Img;
        19, 44, 69: img_nxt[4][5]=Img;

        20, 45, 70: img_nxt[5][1]=Img;
        21, 46, 71: img_nxt[5][2]=Img;
        22, 47, 72: img_nxt[5][3]=Img;
        23, 48, 73: img_nxt[5][4]=Img;
        24, 49, 74: img_nxt[5][5]=Img;
    endcase
end
always @(posedge clk) begin//read kernel
    if(in_valid && counter < 12)begin
        Kernel1_ff[counter] <= Kernel_ch1;
        Kernel2_ff[counter] <= Kernel_ch2;
    end
end
always @(*)begin //calculate kernel use
    case(cur_state)
        CH1:begin
            Kernel1_us00=Kernel1_ff[0];
            Kernel1_us01=Kernel1_ff[1];
            Kernel1_us10=Kernel1_ff[2];
            Kernel1_us11=Kernel1_ff[3];
            Kernel2_us00=Kernel2_ff[0];
            Kernel2_us01=Kernel2_ff[1];
            Kernel2_us10=Kernel2_ff[2];
            Kernel2_us11=Kernel2_ff[3];
        end
        CH2:begin
            Kernel1_us00=Kernel1_ff[4];
            Kernel1_us01=Kernel1_ff[5];
            Kernel1_us10=Kernel1_ff[6];
            Kernel1_us11=Kernel1_ff[7];
            Kernel2_us00=Kernel2_ff[4];
            Kernel2_us01=Kernel2_ff[5];
            Kernel2_us10=Kernel2_ff[6];
            Kernel2_us11=Kernel2_ff[7];
        end
        CH3:begin
            Kernel1_us00=Kernel1_ff[8];
            Kernel1_us01=Kernel1_ff[9];
            Kernel1_us10=Kernel1_ff[10];
            Kernel1_us11=Kernel1_ff[11];
            Kernel2_us00=Kernel2_ff[8];
            Kernel2_us01=Kernel2_ff[9];
            Kernel2_us10=Kernel2_ff[10];
            Kernel2_us11=Kernel2_ff[11];
        end
        default:begin
            Kernel1_us00=0;
            Kernel1_us01=0;
            Kernel1_us10=0;
            Kernel1_us11=0;
            Kernel2_us00=0;
            Kernel2_us01=0;
            Kernel2_us10=0;
            Kernel2_us11=0;
        end
    endcase
end
always@(*)begin //calculate Img use
    Img_use[0][0] = 0; Img_use[0][1] = 0; Img_use[1][0] = 0; Img_use[1][1] = 0;
    case(cur_state)
        CH1, CH3: begin
            case(counter_st)
                0: begin
                    Img_use[0][0] = Img_ff[0][0]; Img_use[0][1] = Img_ff[0][1]; Img_use[1][0] = Img_ff[1][0]; Img_use[1][1] = Img_ff[1][1];
                end
                1: begin
                    Img_use[0][0] = Img_ff[0][1]; Img_use[0][1] = Img_ff[0][2]; Img_use[1][0] = Img_ff[1][1]; Img_use[1][1] = Img_ff[1][2];
                end
                2: begin
                    Img_use[0][0] = Img_ff[0][2]; Img_use[0][1] = Img_ff[0][3]; Img_use[1][0] = Img_ff[1][2]; Img_use[1][1] = Img_ff[1][3];
                end
                3: begin
                    Img_use[0][0] = Img_ff[0][3]; Img_use[0][1] = Img_ff[0][4]; Img_use[1][0] = Img_ff[1][3]; Img_use[1][1] = Img_ff[1][4];
                end
                4: begin
                    Img_use[0][0] = Img_ff[0][4]; Img_use[0][1] = Img_ff[0][5]; Img_use[1][0] = Img_ff[1][4]; Img_use[1][1] = Img_ff[1][5];
                end
                5: begin
                    Img_use[0][0] = Img_ff[0][5]; Img_use[0][1] = Img_ff[0][6]; Img_use[1][0] = Img_ff[1][5]; Img_use[1][1] = Img_ff[1][6];
                end
                
                6: begin
                    Img_use[0][0] = Img_ff[1][0]; Img_use[0][1] = Img_ff[1][1]; Img_use[1][0] = Img_ff[2][0]; Img_use[1][1] = Img_ff[2][1];
                end
                7: begin
                    Img_use[0][0] = Img_ff[1][1]; Img_use[0][1] = Img_ff[1][2]; Img_use[1][0] = Img_ff[2][1]; Img_use[1][1] = Img_ff[2][2];
                end
                8: begin
                    Img_use[0][0] = Img_ff[1][2]; Img_use[0][1] = Img_ff[1][3]; Img_use[1][0] = Img_ff[2][2]; Img_use[1][1] = Img_ff[2][3];
                end
                9: begin
                    Img_use[0][0] = Img_ff[1][3]; Img_use[0][1] = Img_ff[1][4]; Img_use[1][0] = Img_ff[2][3]; Img_use[1][1] = Img_ff[2][4];
                end
                10: begin
                    Img_use[0][0] = Img_ff[1][4]; Img_use[0][1] = Img_ff[1][5]; Img_use[1][0] = Img_ff[2][4]; Img_use[1][1] = Img_ff[2][5];
                end
                11: begin
                    Img_use[0][0] = Img_ff[1][5]; Img_use[0][1] = Img_ff[1][6]; Img_use[1][0] = Img_ff[2][5]; Img_use[1][1] = Img_ff[2][6];
                end
                
                12: begin
                    Img_use[0][0] = Img_ff[2][0]; Img_use[0][1] = Img_ff[2][1]; Img_use[1][0] = Img_ff[3][0]; Img_use[1][1] = Img_ff[3][1];
                end
                13: begin
                    Img_use[0][0] = Img_ff[2][1]; Img_use[0][1] = Img_ff[2][2]; Img_use[1][0] = Img_ff[3][1]; Img_use[1][1] = Img_ff[3][2];
                end
                14: begin
                    Img_use[0][0] = Img_ff[2][2]; Img_use[0][1] = Img_ff[2][3]; Img_use[1][0] = Img_ff[3][2]; Img_use[1][1] = Img_ff[3][3];
                end
                15: begin
                    Img_use[0][0] = Img_ff[2][3]; Img_use[0][1] = Img_ff[2][4]; Img_use[1][0] = Img_ff[3][3]; Img_use[1][1] = Img_ff[3][4];
                end
                16: begin
                    Img_use[0][0] = Img_ff[2][4]; Img_use[0][1] = Img_ff[2][5]; Img_use[1][0] = Img_ff[3][4]; Img_use[1][1] = Img_ff[3][5];
                end
                17: begin
                    Img_use[0][0] = Img_ff[2][5]; Img_use[0][1] = Img_ff[2][6]; Img_use[1][0] = Img_ff[3][5]; Img_use[1][1] = Img_ff[3][6];
                end

                18: begin
                    Img_use[0][0] = Img_ff[3][0]; Img_use[0][1] = Img_ff[3][1]; Img_use[1][0] = Img_ff[4][0]; Img_use[1][1] = Img_ff[4][1];
                end
                19: begin
                    Img_use[0][0] = Img_ff[3][1]; Img_use[0][1] = Img_ff[3][2]; Img_use[1][0] = Img_ff[4][1]; Img_use[1][1] = Img_ff[4][2];
                end
                20: begin
                    Img_use[0][0] = Img_ff[3][2]; Img_use[0][1] = Img_ff[3][3]; Img_use[1][0] = Img_ff[4][2]; Img_use[1][1] = Img_ff[4][3];
                end
                21: begin
                    Img_use[0][0] = Img_ff[3][3]; Img_use[0][1] = Img_ff[3][4]; Img_use[1][0] = Img_ff[4][3]; Img_use[1][1] = Img_ff[4][4];
                end
                22: begin
                    Img_use[0][0] = Img_ff[3][4]; Img_use[0][1] = Img_ff[3][5]; Img_use[1][0] = Img_ff[4][4]; Img_use[1][1] = Img_ff[4][5];
                end
                23: begin
                    Img_use[0][0] = Img_ff[3][5]; Img_use[0][1] = Img_ff[3][6]; Img_use[1][0] = Img_ff[4][5]; Img_use[1][1] = Img_ff[4][6];
                end
                
                24: begin
                    Img_use[0][0] = Img_ff[4][0]; Img_use[0][1] = Img_ff[4][1]; Img_use[1][0] = Img_ff[5][0]; Img_use[1][1] = Img_ff[5][1];
                end
                25: begin
                    Img_use[0][0] = Img_ff[4][1]; Img_use[0][1] = Img_ff[4][2]; Img_use[1][0] = Img_ff[5][1]; Img_use[1][1] = Img_ff[5][2];
                end
                26: begin
                    Img_use[0][0] = Img_ff[4][2]; Img_use[0][1] = Img_ff[4][3]; Img_use[1][0] = Img_ff[5][2]; Img_use[1][1] = Img_ff[5][3];
                end
                27: begin
                    Img_use[0][0] = Img_ff[4][3]; Img_use[0][1] = Img_ff[4][4]; Img_use[1][0] = Img_ff[5][3]; Img_use[1][1] = Img_ff[5][4];
                end
                28: begin
                    Img_use[0][0] = Img_ff[4][4]; Img_use[0][1] = Img_ff[4][5]; Img_use[1][0] = Img_ff[5][4]; Img_use[1][1] = Img_ff[5][5];
                end
                29: begin
                    Img_use[0][0] = Img_ff[4][5]; Img_use[0][1] = Img_ff[4][6]; Img_use[1][0] = Img_ff[5][5]; Img_use[1][1] = Img_ff[5][6];
                end

                30: begin
                    Img_use[0][0] = Img_ff[5][0]; Img_use[0][1] = Img_ff[5][1]; Img_use[1][0] = Img_ff[6][0]; Img_use[1][1] = Img_ff[6][1];
                end
                31: begin
                    Img_use[0][0] = Img_ff[5][1]; Img_use[0][1] = Img_ff[5][2]; Img_use[1][0] = Img_ff[6][1]; Img_use[1][1] = Img_ff[6][2];
                end
                32: begin
                    Img_use[0][0] = Img_ff[5][2]; Img_use[0][1] = Img_ff[5][3]; Img_use[1][0] = Img_ff[6][2]; Img_use[1][1] = Img_ff[6][3];
                end
                33: begin
                    Img_use[0][0] = Img_ff[5][3]; Img_use[0][1] = Img_ff[5][4]; Img_use[1][0] = Img_ff[6][3]; Img_use[1][1] = Img_ff[6][4];
                end
                34: begin
                    Img_use[0][0] = Img_ff[5][4]; Img_use[0][1] = Img_ff[5][5]; Img_use[1][0] = Img_ff[6][4]; Img_use[1][1] = Img_ff[6][5];
                end
                35: begin
                    Img_use[0][0] = Img_ff[5][5]; Img_use[0][1] = Img_ff[5][6]; Img_use[1][0] = Img_ff[6][5]; Img_use[1][1] = Img_ff[6][6];
                end
            endcase
        end
        CH2:begin
            case(counter_st)
                0: begin
                    Img_use[0][0] = Img_ff[0][0]; Img_use[0][1] = Img_ff[0][1]; Img_use[1][0] = Img_ff[1][0]; Img_use[1][1] = Img_ff[1][1];
                end
                1: begin
                    Img_use[0][0] = Img_ff[0][1]; Img_use[0][1] = Img_ff[0][2]; Img_use[1][0] = Img_ff[1][1]; Img_use[1][1] = Img_ff[1][2];
                end
                2: begin
                    Img_use[0][0] = Img_ff[0][2]; Img_use[0][1] = Img_ff[0][3]; Img_use[1][0] = Img_ff[1][2]; Img_use[1][1] = Img_ff[1][3];
                end
                3: begin
                    Img_use[0][0] = Img_ff[0][3]; Img_use[0][1] = Img_ff[0][4]; Img_use[1][0] = Img_ff[1][3]; Img_use[1][1] = Img_ff[1][4];
                end
                4: begin
                    Img_use[0][0] = Img_ff[0][4]; Img_use[0][1] = Img_ff[0][5]; Img_use[1][0] = Img_ff[1][4]; Img_use[1][1] = Img_ff[1][5];
                end
                5: begin
                    Img_use[0][0] = Img_ff[0][5]; Img_use[0][1] = Img_ff[0][6]; Img_use[1][0] = Img_ff[1][5]; Img_use[1][1] = Img_ff[1][6];
                end
                
                6: begin
                    Img_use[0][0] = Img_ff[1][0]; Img_use[0][1] = Img_ff[1][1]; Img_use[1][0] = Img_ff[2][0]; Img_use[1][1] = Img_ff[2][1];
                end
                7: begin
                    Img_use[0][0] = Img_ff[1][1]; Img_use[0][1] = Img_ff[1][2]; Img_use[1][0] = Img_ff[2][1]; Img_use[1][1] = Img_ff[2][2];
                end
                8: begin
                    Img_use[0][0] = Img_ff[1][2]; Img_use[0][1] = Img_ff[1][3]; Img_use[1][0] = Img_ff[2][2]; Img_use[1][1] = Img_ff[2][3];
                end
                9: begin
                    Img_use[0][0] = Img_ff[1][3]; Img_use[0][1] = Img_ff[1][4]; Img_use[1][0] = Img_ff[2][3]; Img_use[1][1] = Img_ff[2][4];
                end
                10: begin
                    Img_use[0][0] = Img_ff[1][4]; Img_use[0][1] = Img_ff[1][5]; Img_use[1][0] = Img_ff[2][4]; Img_use[1][1] = Img_ff[2][5];
                end
                11: begin
                    Img_use[0][0] = Img_ff[1][5]; Img_use[0][1] = Img_ff[1][6]; Img_use[1][0] = Img_ff[2][5]; Img_use[1][1] = Img_ff[2][6];
                end
                
                12: begin
                    Img_use[0][0] = Img_ff[2][0]; Img_use[0][1] = Img_ff[2][1]; Img_use[1][0] = Img_ff[3][0]; Img_use[1][1] = Img_ff[3][1];
                end
                13: begin
                    Img_use[0][0] = Img_ff[2][1]; Img_use[0][1] = Img_ff[2][2]; Img_use[1][0] = Img_ff[3][1]; Img_use[1][1] = Img_ff[3][2];
                end
                14: begin
                    Img_use[0][0] = Img_ff[2][2]; Img_use[0][1] = Img_ff[2][3]; Img_use[1][0] = Img_ff[3][2]; Img_use[1][1] = Img_ff[3][3];
                end
                15: begin
                    Img_use[0][0] = Img_ff[2][3]; Img_use[0][1] = Img_ff[2][4]; Img_use[1][0] = Img_ff[3][3]; Img_use[1][1] = Img_ff[3][4];
                end
                16: begin
                    Img_use[0][0] = Img_ff[2][4]; Img_use[0][1] = Img_ff[2][5]; Img_use[1][0] = Img_ff[3][4]; Img_use[1][1] = Img_ff[3][5];
                end
                17: begin
                    Img_use[0][0] = Img_ff[2][5]; Img_use[0][1] = Img_ff[2][6]; Img_use[1][0] = Img_ff[3][5]; Img_use[1][1] = Img_ff[3][6];
                end

                18: begin
                    Img_use[0][0] = Img_ff[3][0]; Img_use[0][1] = Img_ff[3][1]; Img_use[1][0] = Img_ff[4][0]; Img_use[1][1] = Img_ff[4][1];
                end
                19: begin
                    Img_use[0][0] = Img_ff[3][1]; Img_use[0][1] = Img_ff[3][2]; Img_use[1][0] = Img_ff[4][1]; Img_use[1][1] = Img_ff[4][2];
                end
                20: begin
                    Img_use[0][0] = Img_ff[3][2]; Img_use[0][1] = Img_ff[3][3]; Img_use[1][0] = Img_ff[4][2]; Img_use[1][1] = Img_ff[4][3];
                end
                21: begin
                    Img_use[0][0] = Img_ff[3][3]; Img_use[0][1] = Img_ff[3][4]; Img_use[1][0] = Img_ff[4][3]; Img_use[1][1] = Img_ff[4][4];
                end
                22: begin
                    Img_use[0][0] = Img_ff[3][4]; Img_use[0][1] = Img_ff[3][5]; Img_use[1][0] = Img_ff[4][4]; Img_use[1][1] = Img_ff[4][5];
                end
                23: begin
                    Img_use[0][0] = Img_ff[3][5]; Img_use[0][1] = Img_ff[3][6]; Img_use[1][0] = Img_ff[4][5]; Img_use[1][1] = Img_ff[4][6];
                end
                
                24: begin
                    Img_use[0][0] = Img_ff[4][0]; Img_use[0][1] = Img_ff[4][1]; Img_use[1][0] = Img_ff[5][0]; Img_use[1][1] = Img_ff[5][1];
                end
                25: begin
                    Img_use[0][0] = Img_ff[4][1]; Img_use[0][1] = Img_ff[4][2]; Img_use[1][0] = Img_ff[5][1]; Img_use[1][1] = Img_ff[5][2];
                end
                26: begin
                    Img_use[0][0] = Img_ff[4][2]; Img_use[0][1] = Img_ff[4][3]; Img_use[1][0] = Img_ff[5][2]; Img_use[1][1] = Img_ff[5][3];
                end
                27: begin
                    Img_use[0][0] = Img_ff[4][3]; Img_use[0][1] = Img_ff[4][4]; Img_use[1][0] = Img_ff[5][3]; Img_use[1][1] = Img_ff[5][4];
                end
                28: begin
                    Img_use[0][0] = Img_ff[4][4]; Img_use[0][1] = Img_ff[4][5]; Img_use[1][0] = Img_ff[5][4]; Img_use[1][1] = Img_ff[5][5];
                end
                29: begin
                    Img_use[0][0] = Img_ff[4][5]; Img_use[0][1] = Img_ff[4][6]; Img_use[1][0] = Img_ff[5][5]; Img_use[1][1] = Img_ff[5][6];
                end

                30: begin
                    Img_use[0][0] = Img_ff[5][0]; Img_use[0][1] = Img_ff[5][1]; Img_use[1][0] = Img_ff[6][0]; Img_use[1][1] = Img_ff[6][1];
                end
                31: begin
                    Img_use[0][0] = str0; Img_use[0][1] = Img_ff[5][2]; Img_use[1][0] = Img_ff[6][1]; Img_use[1][1] = Img_ff[6][2];
                end
                32: begin
                    Img_use[0][0] = str1; Img_use[0][1] = Img_ff[5][3]; Img_use[1][0] = Img_ff[6][2]; Img_use[1][1] = Img_ff[6][3];
                end
                33: begin
                    Img_use[0][0] = str2; Img_use[0][1] = Img_ff[5][4]; Img_use[1][0] = Img_ff[6][3]; Img_use[1][1] = Img_ff[6][4];
                end
                34: begin
                    Img_use[0][0] = str3; Img_use[0][1] = Img_ff[5][5]; Img_use[1][0] = Img_ff[6][4]; Img_use[1][1] = Img_ff[6][5];
                end
                35: begin
                    Img_use[0][0] = str4; Img_use[0][1] = Img_ff[5][6]; Img_use[1][0] = Img_ff[6][5]; Img_use[1][1] = Img_ff[6][6];
                end
            endcase
        end
    
    endcase
end

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CN_CH1_1(.a(Img_use[0][0]), .b(Kernel1_us00), .rnd(3'b000), .z(a1), .status());
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CN_CH1_2(.a(Img_use[0][1]), .b(Kernel1_us01), .rnd(3'b000), .z(a2), .status());
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CN_CH1_3(.a(Img_use[1][0]), .b(Kernel1_us10), .rnd(3'b000), .z(a3), .status());
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CN_CH1_4(.a(Img_use[1][1]), .b(Kernel1_us11), .rnd(3'b000), .z(a4), .status());
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CN_CH2_1(.a(Img_use[0][0]), .b(Kernel2_us00), .rnd(3'b000), .z(A1), .status());
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CN_CH2_2(.a(Img_use[0][1]), .b(Kernel2_us01), .rnd(3'b000), .z(A2), .status());
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CN_CH2_3(.a(Img_use[1][0]), .b(Kernel2_us10), .rnd(3'b000), .z(A3), .status());
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) CN_CH2_4(.a(Img_use[1][1]), .b(Kernel2_us11), .rnd(3'b000), .z(A4), .status());
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ADD_CH1_1(.a(a1), .b(a2), .rnd(3'b000), .z(c1),.status() );
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ADD_CH1_2(.a(a3), .b(a4), .rnd(3'b000), .z(c2),.status() );
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ADD_CH1_3(.a(c1), .b(c2), .rnd(3'b000), .z(d1),.status());
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ADD_CH2_1(.a(A1), .b(A2), .rnd(3'b000), .z(C1),.status());
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ADD_CH2_2(.a(A3), .b(A4), .rnd(3'b000), .z(C2),.status());
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ADD_CH2_3(.a(C1), .b(C2), .rnd(3'b000), .z(D1),.status());
always@(posedge clk)begin
    d1_ff<=d1;
    D1_ff<=D1;
end

always@(*)begin //choose which Feature to accumulate
    t1=0;T1=0;
    case(counter)           
                5, 41, 77:  begin t1=Ftr1[0][0]; T1=Ftr2[0][0]; end
                6, 42, 78:  begin t1=Ftr1[0][1]; T1=Ftr2[0][1]; end
                7, 43, 79:  begin t1=Ftr1[0][2]; T1=Ftr2[0][2]; end
                8, 44, 80:  begin t1=Ftr1[0][3]; T1=Ftr2[0][3]; end
                9, 45, 81:  begin t1=Ftr1[0][4]; T1=Ftr2[0][4]; end
                10, 46, 82: begin t1=Ftr1[0][5]; T1=Ftr2[0][5]; end
                11, 47, 83: begin t1=Ftr1[1][0]; T1=Ftr2[1][0]; end
                12, 48, 84: begin t1=Ftr1[1][1]; T1=Ftr2[1][1]; end
                13, 49, 85: begin t1=Ftr1[1][2]; T1=Ftr2[1][2]; end
                14, 50, 86: begin t1=Ftr1[1][3]; T1=Ftr2[1][3]; end
                15, 51, 87: begin t1=Ftr1[1][4]; T1=Ftr2[1][4]; end
                16, 52, 88: begin t1=Ftr1[1][5]; T1=Ftr2[1][5]; end
                17, 53, 89: begin t1=Ftr1[2][0]; T1=Ftr2[2][0]; end
                18, 54, 90: begin t1=Ftr1[2][1]; T1=Ftr2[2][1]; end
                19, 55, 91: begin t1=Ftr1[2][2]; T1=Ftr2[2][2]; end
                20, 56, 92: begin t1=Ftr1[2][3]; T1=Ftr2[2][3]; end
                21, 57, 93: begin t1=Ftr1[2][4]; T1=Ftr2[2][4]; end
                22, 58, 94: begin t1=Ftr1[2][5]; T1=Ftr2[2][5]; end
                23, 59, 95: begin t1=Ftr1[3][0]; T1=Ftr2[3][0]; end
                24, 60, 96: begin t1=Ftr1[3][1]; T1=Ftr2[3][1]; end
                25, 61, 97: begin t1=Ftr1[3][2]; T1=Ftr2[3][2]; end
                26, 62, 98: begin t1=Ftr1[3][3]; T1=Ftr2[3][3]; end
                27, 63, 99:  begin t1=Ftr1[3][4]; T1=Ftr2[3][4]; end
                28, 64, 100: begin t1=Ftr1[3][5]; T1=Ftr2[3][5]; end
                29, 65, 101: begin t1=Ftr1[4][0]; T1=Ftr2[4][0]; end
                30, 66, 102: begin t1=Ftr1[4][1]; T1=Ftr2[4][1]; end
                31, 67, 103: begin t1=Ftr1[4][2]; T1=Ftr2[4][2]; end
                32, 68, 104: begin t1=Ftr1[4][3]; T1=Ftr2[4][3]; end
                33, 69, 105: begin t1=Ftr1[4][4]; T1=Ftr2[4][4]; end
                34, 70, 106: begin t1=Ftr1[4][5]; T1=Ftr2[4][5]; end
                35, 71, 107: begin t1=Ftr1[5][0]; T1=Ftr2[5][0]; end
                36, 72, 108: begin t1=Ftr1[5][1]; T1=Ftr2[5][1]; end
                37, 73, 109: begin t1=Ftr1[5][2]; T1=Ftr2[5][2]; end
                38, 74, 110: begin t1=Ftr1[5][3]; T1=Ftr2[5][3]; end
                39, 75, 111: begin t1=Ftr1[5][4]; T1=Ftr2[5][4]; end
                40, 76, 112: begin t1=Ftr1[5][5]; T1=Ftr2[5][5]; end
    endcase
end
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ADDFEATURE_CH1(.a(t1), .b(d1_ff), .rnd(3'b000), .z(Ftr1_nxt), .status());
DW_fp_add  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ADDFEATURE_CH2(.a(T1), .b(D1_ff), .rnd(3'b000), .z(Ftr2_nxt), .status());
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(int i=0;i<=5;i=i+1)begin
            for(int j=0;j<=5;j=j+1)begin
                Ftr1[i][j]<=0;
                Ftr2[i][j]<=0;
            end
        end
    end
    else begin
        case(cur_state)
            INPUT:begin
                for(int i=0;i<=5;i=i+1)begin
                    for(int j=0;j<=5;j=j+1)begin
                        Ftr1[i][j]<=0;
                        Ftr2[i][j]<=0;
                    end
                end
            end
            default:begin
                case(counter)
                    5, 41, 77:  begin Ftr1[0][0]<=Ftr1_nxt; Ftr2[0][0]<=Ftr2_nxt;end
                    6, 42, 78:  begin Ftr1[0][1]<=Ftr1_nxt; Ftr2[0][1]<=Ftr2_nxt;end
                    7, 43, 79:  begin Ftr1[0][2]<=Ftr1_nxt; Ftr2[0][2]<=Ftr2_nxt;end
                    8, 44, 80:  begin Ftr1[0][3]<=Ftr1_nxt; Ftr2[0][3]<=Ftr2_nxt;end 
                    9, 45, 81:  begin Ftr1[0][4]<=Ftr1_nxt; Ftr2[0][4]<=Ftr2_nxt;end
                    10, 46, 82: begin Ftr1[0][5]<=Ftr1_nxt; Ftr2[0][5]<=Ftr2_nxt;end        
                    11, 47, 83: begin Ftr1[1][0]<=Ftr1_nxt; Ftr2[1][0]<=Ftr2_nxt;end
                    12, 48, 84: begin Ftr1[1][1]<=Ftr1_nxt; Ftr2[1][1]<=Ftr2_nxt;end
                    13, 49, 85: begin Ftr1[1][2]<=Ftr1_nxt; Ftr2[1][2]<=Ftr2_nxt;end
                    14, 50, 86: begin Ftr1[1][3]<=Ftr1_nxt; Ftr2[1][3]<=Ftr2_nxt;end 
                    15, 51, 87: begin Ftr1[1][4]<=Ftr1_nxt; Ftr2[1][4]<=Ftr2_nxt;end
                    16, 52, 88: begin Ftr1[1][5]<=Ftr1_nxt; Ftr2[1][5]<=Ftr2_nxt;end                
                    17, 53, 89: begin Ftr1[2][0]<=Ftr1_nxt; Ftr2[2][0]<=Ftr2_nxt;end
                    18, 54, 90: begin Ftr1[2][1]<=Ftr1_nxt; Ftr2[2][1]<=Ftr2_nxt;end
                    19, 55, 91: begin Ftr1[2][2]<=Ftr1_nxt; Ftr2[2][2]<=Ftr2_nxt;end
                    20, 56, 92: begin Ftr1[2][3]<=Ftr1_nxt; Ftr2[2][3]<=Ftr2_nxt;end
                    21, 57, 93: begin Ftr1[2][4]<=Ftr1_nxt; Ftr2[2][4]<=Ftr2_nxt;end
                    22, 58, 94: begin Ftr1[2][5]<=Ftr1_nxt; Ftr2[2][5]<=Ftr2_nxt;end
                    23, 59, 95: begin Ftr1[3][0]<=Ftr1_nxt; Ftr2[3][0]<=Ftr2_nxt;end
                    24, 60, 96: begin Ftr1[3][1]<=Ftr1_nxt; Ftr2[3][1]<=Ftr2_nxt;end
                    25, 61, 97: begin Ftr1[3][2]<=Ftr1_nxt; Ftr2[3][2]<=Ftr2_nxt;end
                    26, 62, 98: begin Ftr1[3][3]<=Ftr1_nxt; Ftr2[3][3]<=Ftr2_nxt;end
                    27, 63, 99: begin Ftr1[3][4]<=Ftr1_nxt; Ftr2[3][4]<=Ftr2_nxt;end
                    28, 64, 100:begin Ftr1[3][5]<=Ftr1_nxt; Ftr2[3][5]<=Ftr2_nxt;end
                    29, 65, 101:begin Ftr1[4][0]<=Ftr1_nxt; Ftr2[4][0]<=Ftr2_nxt;end
                    30, 66, 102:begin Ftr1[4][1]<=Ftr1_nxt; Ftr2[4][1]<=Ftr2_nxt;end
                    31, 67, 103:begin Ftr1[4][2]<=Ftr1_nxt; Ftr2[4][2]<=Ftr2_nxt;end
                    32, 68, 104:begin Ftr1[4][3]<=Ftr1_nxt; Ftr2[4][3]<=Ftr2_nxt;end
                    33, 69, 105:begin Ftr1[4][4]<=Ftr1_nxt; Ftr2[4][4]<=Ftr2_nxt;end
                    34, 70, 106:begin Ftr1[4][5]<=Ftr1_nxt; Ftr2[4][5]<=Ftr2_nxt;end
                    35, 71, 107:begin Ftr1[5][0]<=Ftr1_nxt; Ftr2[5][0]<=Ftr2_nxt;end
                    36, 72, 108:begin Ftr1[5][1]<=Ftr1_nxt; Ftr2[5][1]<=Ftr2_nxt;end
                    37, 73, 109:begin Ftr1[5][2]<=Ftr1_nxt; Ftr2[5][2]<=Ftr2_nxt;end
                    38, 74, 110:begin Ftr1[5][3]<=Ftr1_nxt; Ftr2[5][3]<=Ftr2_nxt;end
                    39, 75, 111:begin Ftr1[5][4]<=Ftr1_nxt; Ftr2[5][4]<=Ftr2_nxt;end
                    40, 76, 112:begin Ftr1[5][5]<=Ftr1_nxt; Ftr2[5][5]<=Ftr2_nxt;end
                endcase
            end
        endcase
    end
end
//==========================================================//
//                     MAXPOOLING AND FC                    //
//==========================================================//
always@*begin
    for(int i=0;i<=8;i=i+1)begin
        cp[i]=0;
    end
    case (counter_sort)
        1: begin
            cp[0]=Ftr1[0][0];
            cp[1]=Ftr1[0][1];
            cp[2]=Ftr1[0][2];
            cp[3]=Ftr1[1][0];
            cp[4]=Ftr1[1][1];
            cp[5]=Ftr1[1][2];
            cp[6]=Ftr1[2][0];
            cp[7]=Ftr1[2][1];
            cp[8]=Ftr1[2][2];
        end
        2:begin
            cp[0]=Ftr2[0][0];
            cp[1]=Ftr2[0][1];
            cp[2]=Ftr2[0][2];
            cp[3]=Ftr2[1][0];
            cp[4]=Ftr2[1][1];
            cp[5]=Ftr2[1][2];
            cp[6]=Ftr2[2][0];
            cp[7]=Ftr2[2][1];
            cp[8]=Ftr2[2][2];
        end
        3:begin
            cp[0]=Ftr1[0][3];
            cp[1]=Ftr1[0][4];
            cp[2]=Ftr1[0][5];
            cp[3]=Ftr1[1][3];
            cp[4]=Ftr1[1][4];
            cp[5]=Ftr1[1][5];
            cp[6]=Ftr1[2][3];
            cp[7]=Ftr1[2][4];
            cp[8]=Ftr1[2][5];
        end
        4:begin
            cp[0]=Ftr2[0][3];
            cp[1]=Ftr2[0][4];
            cp[2]=Ftr2[0][5];
            cp[3]=Ftr2[1][3];
            cp[4]=Ftr2[1][4];
            cp[5]=Ftr2[1][5];
            cp[6]=Ftr2[2][3];
            cp[7]=Ftr2[2][4];
            cp[8]=Ftr2[2][5];
        end
        5:begin
            cp[0]=Ftr1[3][0];
            cp[1]=Ftr1[3][1];
            cp[2]=Ftr1[3][2];
            cp[3]=Ftr1[4][0];
            cp[4]=Ftr1[4][1];
            cp[5]=Ftr1[4][2];
            cp[6]=Ftr1[5][0];
            cp[7]=Ftr1[5][1];
            cp[8]=Ftr1[5][2];
        end
        6:begin
            cp[0]=Ftr2[3][0];
            cp[1]=Ftr2[3][1];
            cp[2]=Ftr2[3][2];
            cp[3]=Ftr2[4][0];
            cp[4]=Ftr2[4][1];
            cp[5]=Ftr2[4][2];
            cp[6]=Ftr2[5][0];
            cp[7]=Ftr2[5][1];
            cp[8]=Ftr2[5][2];
        end
        7:begin
            cp[0]=Ftr1[3][3];
            cp[1]=Ftr1[3][4];
            cp[2]=Ftr1[3][5];
            cp[3]=Ftr1[4][3];
            cp[4]=Ftr1[4][4];
            cp[5]=Ftr1[4][5];
            cp[6]=Ftr1[5][3];
            cp[7]=Ftr1[5][4];
            cp[8]=Ftr1[5][5];
        end
        8:begin
            cp[0]=Ftr2[3][3];
            cp[1]=Ftr2[3][4];
            cp[2]=Ftr2[3][5];
            cp[3]=Ftr2[4][3];
            cp[4]=Ftr2[4][4];
            cp[5]=Ftr2[4][5];
            cp[6]=Ftr2[5][3];
            cp[7]=Ftr2[5][4];
            cp[8]=Ftr2[5][5];
        end
    endcase
end
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)  COMPARE1(.a(cp[0]), .b(cp[1]), .zctr(1'd0),.aeqb(),.unordered(), .z0(), .z1(n1),.status0(),.status1());
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)  COMPARE2(.a(cp[2]), .b(cp[3]), .zctr(1'd0),.aeqb(),.unordered(), .z0(), .z1(n2),.status0(),.status1());
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)  COMPARE3(.a(cp[4]), .b(cp[5]), .zctr(1'd0),.aeqb(),.unordered(), .z0(), .z1(n3),.status0(),.status1());
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)  COMPARE4(.a(cp[6]), .b(cp[7]), .zctr(1'd0),.aeqb(),.unordered(), .z0(), .z1(n4),.status0(),.status1());
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)  COMPARE5(.a(n1), .b(n2), .zctr(1'd0),.aeqb(), .unordered(),.z0(), .z1(n6),.status0(),.status1());
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)  COMPARE6(.a(n3), .b(n4), .zctr(1'd0),.aeqb(), .unordered(),.z0(), .z1(n7),.status0(),.status1());
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)  COMPARE7(.a(n6), .b(n7), .zctr(1'd0),.aeqb(), .unordered(),.z0(), .z1(n8),.status0(),.status1());
DW_fp_cmp #(inst_sig_width,inst_exp_width,inst_ieee_compliance)  COMPARE8(.a(n8), .b(cp[8]), .zctr(1'd0),.aeqb(), .unordered(),.z0(), .z1(maximum_nxt),.status0(),.status1());
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        maximum_ff<=0;
    end
    else begin
        maximum_ff<=maximum_nxt;
    end
end
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) exp_z(.a(maximum_ff),.z(exp_z_nxt),.status());
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) exp_negz(.a({!maximum_ff[31],maximum_ff[30:0]}),.z(exp_negz_nxt),.status());
DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) Sub( .a(exp_z_ff), .b(exp_negz_ff), .rnd(3'b0), .z(exp_sub), .status());
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) EXP_ADD(.a(exp_z_ff), .b(exp_negz_ff), .rnd(3'b0), .z(exp_add), .status());
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) ADD1(.a(exp_negz_ff), .b(32'h3f800000), .rnd(3'b0), .z(exp_plus1), .status());
always@(posedge clk)begin
    exp_z_ff<=exp_z_nxt;
    exp_negz_ff<=exp_negz_nxt;
end
always@(*)begin
    div_nxt=0;
    dived_nxt=32'h3f800000;
    case (Opt_ff)
        0:begin
            div_nxt=32'h3f800000;
            dived_nxt=exp_plus1;
        end
        1:begin
            div_nxt=exp_sub;
            dived_nxt=exp_add;
        end
    endcase
end
always@(posedge clk)begin
    div_ff<=div_nxt;
    dived_ff<=dived_nxt;
    act_ans<=act_ans_nxt;
end
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) Div( .a(div_ff), .b(dived_ff), .rnd(3'b0), .z(act_ans_nxt), .status());
always@(*)begin
    for(i=0;i<=2;i=i+1)begin
            weight_choosed[i]=0;
    end
    case(counter)
        111:begin
            weight_choosed[0]=weight_ff[0][0];
            weight_choosed[1]=weight_ff[1][0];
            weight_choosed[2]=weight_ff[2][0];
        end
        112:begin
            weight_choosed[0]=weight_ff[0][4];
            weight_choosed[1]=weight_ff[1][4];
            weight_choosed[2]=weight_ff[2][4];
        end
        113:begin
            weight_choosed[0]=weight_ff[0][1];
            weight_choosed[1]=weight_ff[1][1];
            weight_choosed[2]=weight_ff[2][1];
        end
        114:begin
            weight_choosed[0]=weight_ff[0][5];
            weight_choosed[1]=weight_ff[1][5];
            weight_choosed[2]=weight_ff[2][5];
        end
        115:begin
            weight_choosed[0]=weight_ff[0][2];
            weight_choosed[1]=weight_ff[1][2];
            weight_choosed[2]=weight_ff[2][2];
        end
        116:begin
            weight_choosed[0]=weight_ff[0][6];
            weight_choosed[1]=weight_ff[1][6];
            weight_choosed[2]=weight_ff[2][6];
        end
        117:begin
            weight_choosed[0]=weight_ff[0][3];
            weight_choosed[1]=weight_ff[1][3];
            weight_choosed[2]=weight_ff[2][3];
        end
        118:begin
            weight_choosed[0]=weight_ff[0][7];
            weight_choosed[1]=weight_ff[1][7];
            weight_choosed[2]=weight_ff[2][7];
        end
    endcase
end
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) FULLYCONNECT0(.a(act_ans), .b(weight_choosed[0]), .rnd(3'b000), .z(mul0_nxt),.status());
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) FULLYCONNECT1(.a(act_ans), .b(weight_choosed[1]), .rnd(3'b000), .z(mul1_nxt),.status());
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) FULLYCONNECT2(.a(act_ans), .b(weight_choosed[2]), .rnd(3'b000), .z(mul2_nxt),.status());

always@(posedge clk)begin
    fully_ans0_ff<=fully_ans0_nxt;
    fully_ans1_ff<=fully_ans1_nxt;
    fully_ans2_ff<=fully_ans2_nxt;
end
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) fc_ADD0(.a(fully_ans0_ff), .b(mul0_nxt), .rnd(3'b0), .z(fc_s0), .status());
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) fc_ADD1(.a(fully_ans1_ff), .b(mul1_nxt), .rnd(3'b0), .z(fc_s1), .status());
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) fc_ADD2(.a(fully_ans2_ff), .b(mul2_nxt), .rnd(3'b0), .z(fc_s2), .status());
always@(*)begin
    if(counter>=111&&counter<=119)begin
        fully_ans0_nxt=fc_s0;
        fully_ans1_nxt=fc_s1;
        fully_ans2_nxt=fc_s2;
    end
    else if(counter>119)begin
        fully_ans0_nxt=fully_ans0_ff;
        fully_ans1_nxt=fully_ans1_ff;
        fully_ans2_nxt=fully_ans2_ff;
    end
    else begin
        fully_ans0_nxt=0;
        fully_ans1_nxt=0;
        fully_ans2_nxt=0;
    end
end
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) exp_z1(.a(fully_ans0_ff),.z(exp_z1_nxt),.status());
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) exp_z2(.a(fully_ans1_ff),.z(exp_z2_nxt),.status());
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) exp_z3(.a(fully_ans2_ff),.z(exp_z3_nxt),.status());
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)Sum3 (.a(exp_z1_nxt), .b(exp_z2_nxt), .c(exp_z3_nxt), .rnd(3'b0), .z(sumz), .status());
always@*begin
    case(counter)
        119:final_div_nxt=exp_z1_nxt;
        120:final_div_nxt=exp_z2_nxt;
        121:final_div_nxt=exp_z3_nxt;
        default:begin
            final_div_nxt=0;
            final_div_nxt=0;
            final_div_nxt=0;
        end
    endcase
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        final_dived<=32'h3f800000;
    end
    else if(counter==119||counter==120||counter==121)begin
        final_dived<=sumz;
    end
    else begin
        final_dived<=32'h3f800000;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        final_div<=32'h3f800000;
    end
    else begin
        final_div<=final_div_nxt;
    end
end

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) Div1( .a(final_div), .b(final_dived), .rnd(3'b0), .z(final_ans_nxt), .status());
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid<= 0;
    end
    else begin
        out_valid<=out_valid_comb;
    end
    
end
always@(*)begin
    if(nxt_state==OUT)begin
        out_valid_comb=1;
    end
    else begin
        out_valid_comb=0;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out<= 0;
    end
    else if(nxt_state==OUT) begin
        out<=final_ans_nxt;
    end
    else begin
        out<=0;
    end
end
endmodule
