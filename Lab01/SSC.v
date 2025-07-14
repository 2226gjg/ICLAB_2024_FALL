//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price, 
    // Output signals
    out_valid,
    out_change
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [63:0] card_num;
input [8:0] input_money;
input [31:0] snack_num;
input [31:0] price;
output reg out_valid;
output reg [8:0] out_change;    
//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
reg [3:0] card_num_cal [0:7];
reg [7:0] check_sum;
reg [7:0] Total[0:7];
reg [7:0] n0[0:7];
reg [7:0] n1[0:7];
reg [7:0] n2[0:7];
reg [7:0] n3[0:3];
//reg [7:0] n3_2, n3_3, n3_4, n3_5;
//reg [7:0] n4[0:3];
reg [7:0] n4_1, n4_3, n4_4, n4_6;
//reg[7:0] n5[0:5];
reg [7:0] n5_1, n5_2, n5_3, n5_4, n5_5  ,n5_6;
reg [7:0] Total_sort[0:7];
reg signed [9:0] sub0,sub1;
reg signed [10:0] sub2,sub3;
reg signed [11:0] sub4,sub5,sub6,sub7;
//================================================================
//    DESIGN
//================================================================

Multi_2 Dig_0(card_num[7:4],card_num_cal[0]);
Multi_2 Dig_1(card_num[15:12],card_num_cal[1]);
Multi_2 Dig_2(card_num[23:20],card_num_cal[2]);
Multi_2 Dig_3(card_num[31:28],card_num_cal[3]);
Multi_2 Dig_4(card_num[39:36],card_num_cal[4]);
Multi_2 Dig_5(card_num[47:44],card_num_cal[5]);
Multi_2 Dig_6(card_num[55:52],card_num_cal[6]);
Multi_2 Dig_7(card_num[63:60],card_num_cal[7]);
always@* begin
    case (card_num_cal[0]+card_num_cal[1]+card_num_cal[2]+card_num_cal[3]+card_num_cal[4]+card_num_cal[5]+card_num_cal[6]+card_num_cal[7]+card_num[3:0]+card_num[11:8]+card_num[19:16]+card_num[27:24]+card_num[35:32]+card_num[43:40]+card_num[51:48]+card_num[59:56])
        8'd0:   out_valid=1;
        8'd10:  out_valid=1;
        8'd20:  out_valid=1;
        8'd30:  out_valid=1;
        8'd40:  out_valid=1;
        8'd50:  out_valid=1;
        8'd60:  out_valid=1;
        8'd70:  out_valid=1;
        8'd80:  out_valid=1;
        8'd90:  out_valid=1;
        8'd100: out_valid=1;
        8'd110: out_valid=1;
        8'd120: out_valid=1;
        8'd130: out_valid=1;
        8'd140: out_valid=1;
        default: out_valid=0;
    endcase
end
/*
Muiti_15by15 mul1(snack_num[3:0]  ,price[3:0]  ,Total[0]);
Muiti_15by15 mul2(snack_num[7:4]  ,price[7:4]  ,Total[1]);
Muiti_15by15 mul3(snack_num[11:8] ,price[11:8] ,Total[2]);
Muiti_15by15 mul4(snack_num[15:12],price[15:12],Total[3]);
Muiti_15by15 mul5(snack_num[19:16],price[19:16],Total[4]);
Muiti_15by15 mul6(snack_num[23:20],price[23:20],Total[5]);
Muiti_15by15 mul7(snack_num[27:24],price[27:24],Total[6]);
Muiti_15by15 mul8(snack_num[31:28],price[31:28],Total[7]);
*/
always@*begin //calculate total
    Total[0] = snack_num[3:0]   * price[3:0]   ;
    Total[1] = snack_num[7:4]   * price[7:4]   ;
    Total[2] = snack_num[11:8]  * price[11:8]  ;
    Total[3] = snack_num[15:12] * price[15:12] ;
    Total[4] = snack_num[19:16] * price[19:16] ;
    Total[5] = snack_num[23:20] * price[23:20] ;
    Total[6] = snack_num[27:24] * price[27:24] ;
    Total[7] = snack_num[31:28] * price[31:28] ;
end


always@*begin //sorting total
    if (Total[0] >= Total[2]) begin
        n0[0] = Total[0];
        n0[2] = Total[2];
    end 
    else begin
        n0[0] = Total[2];
        n0[2] = Total[0];
    end
    
    if (Total[1] >= Total[3]) begin
        n0[1] = Total[1];
        n0[3] = Total[3];
    end else begin
        n0[1] = Total[3];
        n0[3] = Total[1];
    end

    if (Total[4] >= Total[6]) begin
        n0[4] = Total[4];
        n0[6] = Total[6];
    end else begin
        n0[4] = Total[6];
        n0[6] = Total[4];
    end
    
    if (Total[5] >= Total[7]) begin
        n0[5] = Total[5];
        n0[7] = Total[7];
    end else begin
        n0[5] = Total[7];
        n0[7] = Total[5];
    end

    // 第 1 階段比較
    if (n0[0] >= n0[4]) begin
        n1[0] = n0[0];
        n1[4] = n0[4];
    end else begin
        n1[0] = n0[4];
        n1[4] = n0[0];
    end
    
    if (n0[1] >= n0[5]) begin
        n1[1] = n0[1];
        n1[5] = n0[5];
    end else begin
        n1[1] = n0[5];
        n1[5] = n0[1];
    end
    
    if (n0[2] >= n0[6]) begin
        n1[2] = n0[2];
        n1[6] = n0[6];
    end else begin
        n1[2] = n0[6];
        n1[6] = n0[2];
    end
    
    if (n0[3] >= n0[7]) begin
        n1[3] = n0[3];
        n1[7] = n0[7];
    end else begin
        n1[3] = n0[7];
        n1[7] = n0[3];
    end

    // 第 2 階段比較
    if (n1[0] >= n1[1]) begin
        Total_sort[0] = n1[0];
        n2[1] = n1[1];
    end else begin
        Total_sort[0] = n1[1];
        n2[1] = n1[0];
    end

    if (n1[2] >= n1[3]) begin
        n2[2] = n1[2];
        n2[3] = n1[3];
    end else begin
        n2[2] = n1[3];
        n2[3] = n1[2];
    end
    
    if (n1[4] >= n1[5]) begin
        n2[4] = n1[4];
        n2[5] = n1[5];
    end else begin
        n2[4] = n1[5];
        n2[5] = n1[4];
    end
    
    if (n1[6] >= n1[7]) begin
        n2[6] = n1[6];
        n2[7] = n1[7];
    end else begin
        n2[6] = n1[7];
        n2[7] = n1[6];
    end

    // 第 3 階段比較
    if (n2[2] >= n2[4]) begin
        n3[0] = n2[2];
        n3[2] = n2[4];
    end else begin
        n3[0] = n2[4];
        n3[2] = n2[2];
    end

    if (n2[3] >= n2[5]) begin
        n3[1] = n2[3];
        n3[3] = n2[5];
    end else begin
        n3[1] = n2[5];
        n3[3] = n2[3];
    end

    // 第 4 階段比較
    if (n2[1] >= n3[2]) begin
        n4_1 = n2[1];
        n4_4 = n3[2];
    end else begin
        n4_1 = n3[2];
        n4_4 = n2[1];
    end

    if (n3[1] >= n2[6]) begin
        n4_3 = n3[1];
        n4_6 = n2[6];
    end else begin
        n4_3 = n2[6];
        n4_6 = n3[1];
    end

    // 第 5 階段比較
    if (n4_1 >= n3[0]) begin
        n5_1 = n4_1;
        n5_2 = n3[0];
    end else begin
        n5_1 = n3[0];
        n5_2 = n4_1;
    end

    if (n4_3 >= n4_4) begin
        n5_3 = n4_3;
        n5_4 = n4_4;
    end else begin
        n5_3 = n4_4;
        n5_4 = n4_3;
    end

    if (n3[3] >= n4_6) begin
        n5_5 = n3[3];
        n5_6 = n4_6;
    end else begin
        n5_5 = n4_6;
        n5_6 = n3[3];
    end

    // 最終賦值
    Total_sort[1] = n5_1;
    Total_sort[2] = n5_2;
    Total_sort[3] = n5_3;
    Total_sort[4] = n5_4;
    Total_sort[5] = n5_5;
    Total_sort[6] = n5_6;
    Total_sort[7] = n2[7];
end

always@*begin
    sub0=$signed({1'b0,input_money})-$signed({1'b0,Total_sort[0]});
    sub1=sub0-$signed({1'b0,Total_sort[1]});
    sub2=sub1-$signed({1'b0,Total_sort[2]});
    sub3=sub2-$signed({1'b0,Total_sort[3]});
    sub4=sub3-$signed({1'b0,Total_sort[4]});
    sub5=sub4-$signed({1'b0,Total_sort[5]});
    sub6=sub5-$signed({1'b0,Total_sort[6]});
    sub7=sub6-$signed({1'b0,Total_sort[7]});
end

always@*begin 
    if(out_valid==0)begin
        out_change=input_money;
    end
    else begin
        if(sub7>=0)begin
            //sub=sum_7;
            out_change=sub7;
        end
        else if(sub6>=0)begin
            //sub=sum_6;
            out_change=sub6;
        end
        else if(sub5>=0)begin
            //sub=sum_5;
            out_change=sub5;
        end
        else if(sub4>=0)begin
            //sub=sum_4;
            out_change=sub4;
        end
        else if(sub3>=0)begin
            //sub=sum_3;
            out_change=sub3;
        end
        else if(sub2>=0)begin
            //sub=sum_2;
            out_change=sub2;
        end
        else if(sub1>=0)begin
            //sub=sum_1;
            out_change=sub1;
        end
        else if(sub0>=0)begin
            //sub=sum_0;
            out_change=sub0;
        end
        else begin
            out_change=input_money;
        end
    end
end


endmodule




module Multi_2(in,out);
	input [3:0] in;
	output reg [3:0] out;
    //design
    always@*begin
        case(in)
            4'd0: out=0;
            4'd1: out=2;
            4'd2: out=4;
            4'd3: out=6;
            4'd4: out=8;
            4'd5: out=1;
            4'd6: out=3;
            4'd7: out=5;
            4'd8: out=7;
            4'd9: out=9;
            default: out=0;

        endcase
    end
endmodule

module Muiti_15by15(in1,in2,out);
    input[3:0] in1;
    input[3:0] in2;
    output reg[7:0] out;
    always@* begin
        case({in1,in2})
            {4'd0, 4'd0}: out = 0;
            {4'd0, 4'd1}: out = 0;
            {4'd0, 4'd2}: out = 0;
            {4'd0, 4'd3}: out = 0;
            {4'd0, 4'd4}: out = 0;
            {4'd0, 4'd5}: out = 0;
            {4'd0, 4'd6}: out = 0;
            {4'd0, 4'd7}: out = 0;
            {4'd0, 4'd8}: out = 0;
            {4'd0, 4'd9}: out = 0;
            {4'd0, 4'd10}: out = 0;
            {4'd0, 4'd11}: out = 0;
            {4'd0, 4'd12}: out = 0;
            {4'd0, 4'd13}: out = 0;
            {4'd0, 4'd14}: out = 0;
            {4'd0, 4'd15}: out = 0;
            
            {4'd1, 4'd0}: out = 0;
            {4'd1, 4'd1}: out = 1;
            {4'd1, 4'd2}: out = 2;
            {4'd1, 4'd3}: out = 3;
            {4'd1, 4'd4}: out = 4;
            {4'd1, 4'd5}: out = 5;
            {4'd1, 4'd6}: out = 6;
            {4'd1, 4'd7}: out = 7;
            {4'd1, 4'd8}: out = 8;
            {4'd1, 4'd9}: out = 9;
            {4'd1, 4'd10}: out = 10;
            {4'd1, 4'd11}: out = 11;
            {4'd1, 4'd12}: out = 12;
            {4'd1, 4'd13}: out = 13;
            {4'd1, 4'd14}: out = 14;
            {4'd1, 4'd15}: out = 15;
            {4'd2, 4'd0}: out = 0;
            {4'd2, 4'd1}: out = 2;
            {4'd2, 4'd2}: out = 4;
            {4'd2, 4'd3}: out = 6;
            {4'd2, 4'd4}: out = 8;
            {4'd2, 4'd5}: out = 10;
            {4'd2, 4'd6}: out = 12;
            {4'd2, 4'd7}: out = 14;
            {4'd2, 4'd8}: out = 16;
            {4'd2, 4'd9}: out = 18;
            {4'd2, 4'd10}: out = 20;
            {4'd2, 4'd11}: out = 22;
            {4'd2, 4'd12}: out = 24;
            {4'd2, 4'd13}: out = 26;
            {4'd2, 4'd14}: out = 28;
            {4'd2, 4'd15}: out = 30;
            {4'd3, 4'd0}: out = 0;
            {4'd3, 4'd1}: out = 3;
            {4'd3, 4'd2}: out = 6;
            {4'd3, 4'd3}: out = 9;
            {4'd3, 4'd4}: out = 12;
            {4'd3, 4'd5}: out = 15;
            {4'd3, 4'd6}: out = 18;
            {4'd3, 4'd7}: out = 21;
            {4'd3, 4'd8}: out = 24;
            {4'd3, 4'd9}: out = 27;
            {4'd3, 4'd10}: out = 30;
            {4'd3, 4'd11}: out = 33;
            {4'd3, 4'd12}: out = 36;
            {4'd3, 4'd13}: out = 39;
            {4'd3, 4'd14}: out = 42;
            {4'd3, 4'd15}: out = 45;
            {4'd4, 4'd0}: out = 0;
            {4'd4, 4'd1}: out = 4;
            {4'd4, 4'd2}: out = 8;
            {4'd4, 4'd3}: out = 12;
            {4'd4, 4'd4}: out = 16;
            {4'd4, 4'd5}: out = 20;
            {4'd4, 4'd6}: out = 24;
            {4'd4, 4'd7}: out = 28;
            {4'd4, 4'd8}: out = 32;
            {4'd4, 4'd9}: out = 36;
            {4'd4, 4'd10}: out = 40;
            {4'd4, 4'd11}: out = 44;
            {4'd4, 4'd12}: out = 48;
            {4'd4, 4'd13}: out = 52;
            {4'd4, 4'd14}: out = 56;
            {4'd4, 4'd15}: out = 60;
            {4'd5, 4'd0}: out = 0;
            {4'd5, 4'd1}: out = 5;
            {4'd5, 4'd2}: out = 10;
            {4'd5, 4'd3}: out = 15;
            {4'd5, 4'd4}: out = 20;
            {4'd5, 4'd5}: out = 25;
            {4'd5, 4'd6}: out = 30;
            {4'd5, 4'd7}: out = 35;
            {4'd5, 4'd8}: out = 40;
            {4'd5, 4'd9}: out = 45;
            {4'd5, 4'd10}: out = 50;
            {4'd5, 4'd11}: out = 55;
            {4'd5, 4'd12}: out = 60;
            {4'd5, 4'd13}: out = 65;
            {4'd5, 4'd14}: out = 70;
            {4'd5, 4'd15}: out = 75;
            {4'd6, 4'd0}: out = 0;
            {4'd6, 4'd1}: out = 6;
            {4'd6, 4'd2}: out = 12;
            {4'd6, 4'd3}: out = 18;
            {4'd6, 4'd4}: out = 24;
            {4'd6, 4'd5}: out = 30;
            {4'd6, 4'd6}: out = 36;
            {4'd6, 4'd7}: out = 42;
            {4'd6, 4'd8}: out = 48;
            {4'd6, 4'd9}: out = 54;
            {4'd6, 4'd10}: out = 60;
            {4'd6, 4'd11}: out = 66;
            {4'd6, 4'd12}: out = 72;
            {4'd6, 4'd13}: out = 78;
            {4'd6, 4'd14}: out = 84;
            {4'd6, 4'd15}: out = 90;

            {4'd7, 4'd0}: out = 0;
            {4'd7, 4'd1}: out = 7;
            {4'd7, 4'd2}: out = 14;
            {4'd7, 4'd3}: out = 21;
            {4'd7, 4'd4}: out = 28;
            {4'd7, 4'd5}: out = 35;
            {4'd7, 4'd6}: out = 42;
            {4'd7, 4'd7}: out = 49;
            {4'd7, 4'd8}: out = 56;
            {4'd7, 4'd9}: out = 63;
            {4'd7, 4'd10}: out = 70;
            {4'd7, 4'd11}: out = 77;
            {4'd7, 4'd12}: out = 84;
            {4'd7, 4'd13}: out = 91;
            {4'd7, 4'd14}: out = 98;
            {4'd7, 4'd15}: out = 105;

            {4'd8, 4'd0}: out = 0;
            {4'd8, 4'd1}: out = 8;
            {4'd8, 4'd2}: out = 16;
            {4'd8, 4'd3}: out = 24;
            {4'd8, 4'd4}: out = 32;
            {4'd8, 4'd5}: out = 40;
            {4'd8, 4'd6}: out = 48;
            {4'd8, 4'd7}: out = 56;
            {4'd8, 4'd8}: out = 64;
            {4'd8, 4'd9}: out = 72;
            {4'd8, 4'd10}: out = 80;
            {4'd8, 4'd11}: out = 88;
            {4'd8, 4'd12}: out = 96;
            {4'd8, 4'd13}: out = 104;
            {4'd8, 4'd14}: out = 112;
            {4'd8, 4'd15}: out = 120;

            {4'd9, 4'd0}: out = 0;
            {4'd9, 4'd1}: out = 9;
            {4'd9, 4'd2}: out = 18;
            {4'd9, 4'd3}: out = 27;
            {4'd9, 4'd4}: out = 36;
            {4'd9, 4'd5}: out = 45;
            {4'd9, 4'd6}: out = 54;
            {4'd9, 4'd7}: out = 63;
            {4'd9, 4'd8}: out = 72;
            {4'd9, 4'd9}: out = 81;
            {4'd9, 4'd10}: out = 90;
            {4'd9, 4'd11}: out = 99;
            {4'd9, 4'd12}: out = 108;
            {4'd9, 4'd13}: out = 117;
            {4'd9, 4'd14}: out = 126;
            {4'd9, 4'd15}: out = 135;

            {4'd10, 4'd0}: out = 0;
            {4'd10, 4'd1}: out = 10;
            {4'd10, 4'd2}: out = 20;
            {4'd10, 4'd3}: out = 30;
            {4'd10, 4'd4}: out = 40;
            {4'd10, 4'd5}: out = 50;
            {4'd10, 4'd6}: out = 60;
            {4'd10, 4'd7}: out = 70;
            {4'd10, 4'd8}: out = 80;
            {4'd10, 4'd9}: out = 90;
            {4'd10, 4'd10}: out = 100;
            {4'd10, 4'd11}: out = 110;
            {4'd10, 4'd12}: out = 120;
            {4'd10, 4'd13}: out = 130;
            {4'd10, 4'd14}: out = 140;
            {4'd10, 4'd15}: out = 150;

            {4'd11, 4'd0}: out = 0;
            {4'd11, 4'd1}: out = 11;
            {4'd11, 4'd2}: out = 22;
            {4'd11, 4'd3}: out = 33;
            {4'd11, 4'd4}: out = 44;
            {4'd11, 4'd5}: out = 55;
            {4'd11, 4'd6}: out = 66;
            {4'd11, 4'd7}: out = 77;
            {4'd11, 4'd8}: out = 88;
            {4'd11, 4'd9}: out = 99;
            {4'd11, 4'd10}: out = 110;
            {4'd11, 4'd11}: out = 121;
            {4'd11, 4'd12}: out = 132;
            {4'd11, 4'd13}: out = 143;
            {4'd11, 4'd14}: out = 154;
            {4'd11, 4'd15}: out = 165;

            {4'd12, 4'd0}: out = 0;
            {4'd12, 4'd1}: out = 12;
            {4'd12, 4'd2}: out = 24;
            {4'd12, 4'd3}: out = 36;
            {4'd12, 4'd4}: out = 48;
            {4'd12, 4'd5}: out = 60;
            {4'd12, 4'd6}: out = 72;
            {4'd12, 4'd7}: out = 84;
            {4'd12, 4'd8}: out = 96;
            {4'd12, 4'd9}: out = 108;
            {4'd12, 4'd10}: out = 120;
            {4'd12, 4'd11}: out = 132;
            {4'd12, 4'd12}: out = 144;
            {4'd12, 4'd13}: out = 156;
            {4'd12, 4'd14}: out = 168;
            {4'd12, 4'd15}: out = 180;

            {4'd13, 4'd0}: out = 0;
            {4'd13, 4'd1}: out = 13;
            {4'd13, 4'd2}: out = 26;
            {4'd13, 4'd3}: out = 39;
            {4'd13, 4'd4}: out = 52;
            {4'd13, 4'd5}: out = 65;
            {4'd13, 4'd6}: out = 78;
            {4'd13, 4'd7}: out = 91;
            {4'd13, 4'd8}: out = 104;
            {4'd13, 4'd9}: out = 117;
            {4'd13, 4'd10}: out = 130;
            {4'd13, 4'd11}: out = 143;
            {4'd13, 4'd12}: out = 156;
            {4'd13, 4'd13}: out = 169;
            {4'd13, 4'd14}: out = 182;
            {4'd13, 4'd15}: out = 195;

            {4'd14, 4'd0}: out = 0;
            {4'd14, 4'd1}: out = 14;
            {4'd14, 4'd2}: out = 28;
            {4'd14, 4'd3}: out = 42;
            {4'd14, 4'd4}: out = 56;
            {4'd14, 4'd5}: out = 70;
            {4'd14, 4'd6}: out = 84;
            {4'd14, 4'd7}: out = 98;
            {4'd14, 4'd8}: out = 112;
            {4'd14, 4'd9}: out = 126;
            {4'd14, 4'd10}: out = 140;
            {4'd14, 4'd11}: out = 154;
            {4'd14, 4'd12}: out = 168;
            {4'd14, 4'd13}: out = 182;
            {4'd14, 4'd14}: out = 196;
            {4'd14, 4'd15}: out = 210;

            {4'd15, 4'd0}: out = 0;
            {4'd15, 4'd1}: out = 15;
            {4'd15, 4'd2}: out = 30;
            {4'd15, 4'd3}: out = 45;
            {4'd15, 4'd4}: out = 60;
            {4'd15, 4'd5}: out = 75;
            {4'd15, 4'd6}: out = 90;
            {4'd15, 4'd7}: out = 105;
            {4'd15, 4'd8}: out = 120;
            {4'd15, 4'd9}: out = 135;
            {4'd15, 4'd10}: out = 150;
            {4'd15, 4'd11}: out = 165;
            {4'd15, 4'd12}: out = 180;
            {4'd15, 4'd13}: out = 195;
            {4'd15, 4'd14}: out = 210;
            {4'd15, 4'd15}: out = 225;
            default: out=0;
        endcase
    end
    
endmodule
