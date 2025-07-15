//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/10
//		Version		: v1.0
//   	File Name   : HAMMING_IP.v
//   	Module Name : HAMMING_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module HAMMING_IP #(parameter IP_BIT ) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
);

// ===============================================================
// Input & Output
// ===============================================================
input [(IP_BIT+4-1):0]  IN_code;
output reg [(IP_BIT-1):0] OUT_code;

// ===============================================================
// Design
// ===============================================================
wire [3:0]cal_xor[0:15];
reg [3:0]error_code;
reg [(IP_BIT+4-1):0]temp_out;
genvar i;
generate
    assign cal_xor[0]=4'b0000;
    for (i=1; i<=IP_BIT+4; i=i+1)begin
        assign cal_xor[i] = (IN_code[IP_BIT+4-i]==1)?i:4'b0000;
    end    
    for (i=IP_BIT+5; i<=15; i=i+1)begin
        assign cal_xor[i] = 4'b0000;
    end 
endgenerate
integer j;
always@(*)begin
    error_code[0]= cal_xor[1][0] ^ cal_xor[2][0] ^ cal_xor[3][0] ^ cal_xor[4][0] ^
                   cal_xor[5][0] ^ cal_xor[6][0] ^ cal_xor[7][0] ^ cal_xor[8][0] ^
                   cal_xor[9][0] ^ cal_xor[10][0] ^ cal_xor[11][0] ^ cal_xor[12][0] ^
                   cal_xor[13][0] ^ cal_xor[14][0] ^ cal_xor[15][0]; 
    error_code[1]= cal_xor[1][1] ^  cal_xor[2][1] ^ cal_xor[3][1] ^ cal_xor[4][1] ^
                   cal_xor[5][1] ^  cal_xor[6][1] ^ cal_xor[7][1] ^ cal_xor[8][1] ^
                   cal_xor[9][1] ^ cal_xor[10][1] ^ cal_xor[11][1] ^ cal_xor[12][1] ^
                   cal_xor[13][1] ^cal_xor[14][1] ^ cal_xor[15][1];      
    error_code[2]= cal_xor[1 ][2] ^  cal_xor[2][2] ^ cal_xor[3 ][2] ^ cal_xor[4 ][2] ^
                   cal_xor[5 ][2] ^  cal_xor[6][2] ^ cal_xor[7 ][2] ^ cal_xor[8 ][2] ^
                   cal_xor[9 ][2] ^ cal_xor[10][2] ^ cal_xor[11][2] ^ cal_xor[12][2] ^
                   cal_xor[13][2] ^ cal_xor[14][2] ^ cal_xor[15][2]; 
    error_code[3]= cal_xor[1 ][3] ^  cal_xor[2][3] ^ cal_xor[3 ][3] ^ cal_xor[4 ][3] ^
                   cal_xor[5 ][3] ^  cal_xor[6][3] ^ cal_xor[7 ][3] ^ cal_xor[8 ][3] ^
                   cal_xor[9 ][3] ^ cal_xor[10][3] ^ cal_xor[11][3] ^ cal_xor[12][3] ^
                   cal_xor[13][3] ^ cal_xor[14][3] ^ cal_xor[15][3];
    if(error_code==0)begin
        temp_out= IN_code;
    end
    else begin
        temp_out= IN_code;
        temp_out[IP_BIT+4-error_code]=~IN_code[IP_BIT+4-error_code];
    end    

    OUT_code[IP_BIT-1]=temp_out[IP_BIT+4-3];
    OUT_code[IP_BIT-2]=temp_out[IP_BIT+4-5];
    OUT_code[IP_BIT-3]=temp_out[IP_BIT+4-6];
    OUT_code[IP_BIT-4]=temp_out[IP_BIT+4-7];
    OUT_code[IP_BIT-5]=temp_out[IP_BIT+4-9];
    for(j=10;j<=9+(IP_BIT-5);j=j+1)begin
        OUT_code[IP_BIT-(j-4)]=temp_out[IP_BIT+4-j];
    end
end


endmodule