module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
//newest
input clk;
input rst_n;
input in_valid;
input [17:0] in_row;
input [11:0] in_kernel;
input out_idle;
output reg handshake_sready;
output reg [29:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output reg fifo_rinc;
output reg out_valid;
output reg [7:0] out_data;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;

//==================================================================//
//                          REG_DECLARERATION                       //
//==================================================================//
integer i;
reg [29:0]din_to_handshake_nxt[0:5],din_to_handshake_ff[0:5];
typedef enum reg[2:0]{IDLE=0 ,INPUT=1 ,SEND_HANDSHAKE=2 ,READ_FIFO=3}state;
state cur_state,nxt_state;
reg [2:0]counter_din;
reg fifo_rinc_delay1,fifo_rinc_delay2;
reg [7:0]counter_out;

//==================================================================//
//                          FSM                                     //
//==================================================================//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cur_state<=IDLE;        
    end
    else begin
        cur_state<=nxt_state;
    end
end
always@*begin
    nxt_state=cur_state;
    case(cur_state)
        IDLE:begin
            if(in_valid)
                nxt_state=INPUT;
            else 
                nxt_state=IDLE;
        end
        INPUT:begin
            if(!in_valid)
                nxt_state=SEND_HANDSHAKE;
            else 
                nxt_state=INPUT;
        end
        SEND_HANDSHAKE:begin
            if(counter_din==6)begin
                nxt_state=READ_FIFO;
            end
            else begin
                nxt_state=SEND_HANDSHAKE;
            end
        end
        READ_FIFO:begin
            if(counter_out==150)begin
                nxt_state=IDLE;
            end
            else begin
                nxt_state=READ_FIFO;
            end
        end
    endcase
end
//counter
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        counter_din<=0;
    end
    else begin
        if(cur_state==SEND_HANDSHAKE)begin
            if(handshake_sready==1&&out_idle==0)begin
                counter_din<=counter_din+1;
            end
        end
        else begin
            counter_din<=0;
        end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        counter_out<=0;
    end
    else begin
        case(cur_state)
            READ_FIFO:begin
                if(fifo_rinc_delay2)
                    counter_out<=counter_out+1;
                else 
                    counter_out<=counter_out;
            end
            default:begin
                counter_out<=0;
            end
        endcase
    end
end
//INPUT
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<=5;i=i+1)begin
            din_to_handshake_ff[i]<=30'b0;
        end
    end
    else begin
        if(in_valid)begin
            din_to_handshake_ff[5]<={in_row,in_kernel};
            for(i=0;i<=4;i=i+1)begin
                din_to_handshake_ff[i]<=din_to_handshake_ff[i+1];
            end
        end
        else if(cur_state==SEND_HANDSHAKE)begin
            if(flag_handshake_to_clk1==1)begin
                din_to_handshake_ff[5]<=30'b0;
                for(i=0;i<=4;i=i+1)begin
                    din_to_handshake_ff[i]<=din_to_handshake_ff[i+1];
                end
            end
        end
    end
end
//USE HANDSHAKE SYNCHRONISER TO SEND DATA  
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        handshake_sready<=0;
        handshake_din<=0;
    end
    else begin
        case(cur_state)
            SEND_HANDSHAKE:begin
                handshake_sready<=out_idle;
                if(out_idle)begin
                    handshake_din<=din_to_handshake_ff[0];
                end
                else begin
                    handshake_din<=handshake_din;
                end
                
            end
            default:begin
                handshake_sready<=0;
                handshake_din<=0;
            end
        endcase
    end
end
//READ DATA FROM FIFO AND OUTPUT TO PATTERN
always@(*)begin
    if(cur_state==READ_FIFO)
        fifo_rinc=!fifo_empty;
    else begin
        fifo_rinc=0;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        fifo_rinc_delay1<=0;
        fifo_rinc_delay2<=0;
    end
    else begin
        fifo_rinc_delay1<=fifo_rinc;
        fifo_rinc_delay2<=fifo_rinc_delay1;
    end
    
end
//output_valid to PATTERN
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid<=0;
    end
    else begin
        if(nxt_state==READ_FIFO)begin
            if(fifo_rinc_delay2)
                out_valid<=1;
            else
                out_valid<=0;
        end
        else begin
            out_valid<=0;
        end
    end
end
//OUT_DATA to PATTERN
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_data<=0;
    end
    else begin
        if(nxt_state==READ_FIFO)begin
            if(fifo_rinc_delay2)
                out_data<=fifo_rdata;
            else
                out_data<=0;
        end
        else begin
            out_data<=0;
        end
    end
end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [29:0] in_data;
output reg out_valid;
output reg [7:0] out_data;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;

//==================================================================//
//                          REG_DECLARERATION                       //
//==================================================================//
integer i,j;
typedef enum reg[2:0]{IDLE=0 ,INPUT=1 ,CAL_OUT=2,WAIT=3}state;
state cur_state,nxt_state;
reg [2:0]counter_in;
reg [2:0]counter_row,counter_column,counter_channel;
reg [2:0] img_ff[0:5][0:5],img_nxt[0:5][0:5];
reg [2:0] kernel_ff[0:5][0:3],kernel_nxt[0:5][0:3];
reg [7:0]ans;
reg fifo_full_delay1;
//==================================================================//
//                          REG_DECLARERATION                       //
//==================================================================//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cur_state<=IDLE;        
    end
    else begin
        cur_state<=nxt_state;
    end
end
always@*begin
    nxt_state=cur_state;
    case(cur_state)
        IDLE:begin
            if(in_valid)
                nxt_state=INPUT;
            else 
                nxt_state=IDLE;
        end
        INPUT:begin
            if(in_valid&&counter_in==5)
                nxt_state=CAL_OUT;
            else 
                nxt_state=INPUT;
        end
        CAL_OUT:begin
            if(counter_channel==6)
                nxt_state=IDLE;
            else 
                nxt_state=CAL_OUT;
        end
    endcase
end
always@(*)begin
    if(cur_state==CAL_OUT)begin
        busy=1;
    end
    else begin
        busy=0;
    end
end
//==================================================================//
//                          counter                                 //
//==================================================================//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        counter_in<=0;
    end
    else begin
        case(cur_state)
            IDLE:begin
                if(in_valid)begin
                    counter_in<=counter_in+1;
                end
                else begin
                    counter_in<=0;
                end
            end
            INPUT:begin
                if(in_valid)begin
                    counter_in<=counter_in+1;
                end
            end
            CAL_OUT:begin
                counter_in<=0;
            end
        endcase
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        counter_row<=0;
        counter_column<=0; 
        counter_channel<=0;
    end
    else begin
        case(cur_state)
            IDLE,INPUT:begin
                counter_row<=0;
                counter_column<=0; 
                counter_channel<=0;
            end
            CAL_OUT:begin
                if(!fifo_full)begin
                    if(counter_column==4&&counter_row==4)begin
                        counter_row<=0;
                        counter_channel<=counter_channel+1;
                    end
                    else if(counter_column==4)begin
                        counter_row<=counter_row+1;
                    end
                    counter_column<=(counter_column==4)?0:counter_column+1; 
                end
            end
            
        endcase
        
    end
end 
//==================================================================//
//                          INPUT DATA                               //
//==================================================================//

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<=5;i++)begin
            for(j=0;j<=5;j++)begin
                img_ff[i][j]<=0;
            end
        end
        
    end
    else begin
        for(i=0;i<=5;i++)begin
            for(j=0;j<=5;j++)begin
                img_ff[i][j]<=img_nxt[i][j];
            end
        end
    end
end
always@(*)begin
    for(i=0;i<=5;i++)begin
        for(j=0;j<=5;j++)begin
            img_nxt[i][j]=img_ff[i][j];
        end
    end
    case(cur_state)
        IDLE:begin
            if(in_valid)begin
                img_nxt[counter_in][0]=in_data[14:12];
                img_nxt[counter_in][1]=in_data[17:15];
                img_nxt[counter_in][2]=in_data[20:18];
                img_nxt[counter_in][3]=in_data[23:21];
                img_nxt[counter_in][4]=in_data[26:24];
                img_nxt[counter_in][5]=in_data[29:27];
            end
            else begin
                for(i=0;i<=5;i++)begin
                    for(j=0;j<=5;j++)begin
                        img_nxt[i][j]=0;
                    end
                end
            end
        end
        INPUT:begin
            if(in_valid)begin
                img_nxt[counter_in][0]=in_data[14:12];
                img_nxt[counter_in][1]=in_data[17:15];
                img_nxt[counter_in][2]=in_data[20:18];
                img_nxt[counter_in][3]=in_data[23:21];
                img_nxt[counter_in][4]=in_data[26:24];
                img_nxt[counter_in][5]=in_data[29:27];
            end
        end
    endcase
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<=5;i++)begin
            for(j=0;j<=3;j++)begin
                kernel_ff[i][j]<=0;
            end
        end
    end
    else begin
        for(i=0;i<=5;i++)begin
            for(j=0;j<=3;j++)begin
                kernel_ff[i][j]<=kernel_nxt[i][j];
            end
        end
    end
end
always@*begin
    for(i=0;i<=5;i++)begin
        for(j=0;j<=3;j++)begin
            kernel_nxt[i][j]=kernel_ff[i][j];
        end
    end
    case(cur_state)
        IDLE:begin
            if(in_valid)begin
                kernel_nxt[counter_in][0]=in_data[2:0];
                kernel_nxt[counter_in][1]=in_data[5:3];
                kernel_nxt[counter_in][2]=in_data[8:6];
                kernel_nxt[counter_in][3]=in_data[11:9];
            end
            else begin
                for(i=0;i<=5;i++)begin
                    for(j=0;j<=3;j++)begin
                        kernel_nxt[i][j]=0;
                    end
                end
            end
        end
        INPUT:begin
            if(in_valid)begin
                kernel_nxt[counter_in][0]=in_data[2:0];
                kernel_nxt[counter_in][1]=in_data[5:3];
                kernel_nxt[counter_in][2]=in_data[8:6];
                kernel_nxt[counter_in][3]=in_data[11:9];
            end
        end
    endcase
end
//==================================================================//
//                    CAL and OUTPUT DATA                           //
//==================================================================//

always@(posedge clk)begin
    fifo_full_delay1<=fifo_full;
end
always@(*)begin
    ans=img_ff[counter_row][counter_column]*kernel_ff[counter_channel][0]+img_ff[counter_row][counter_column+1]*kernel_ff[counter_channel][1]+ img_ff[counter_row+1][counter_column]*kernel_ff[counter_channel][2] + img_ff[counter_row+1][counter_column+1]*kernel_ff[counter_channel][3];
    out_data=ans;
    out_valid=(!fifo_full&&cur_state==CAL_OUT);
end
endmodule