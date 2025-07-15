module TMIP(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    
    image,
    template,
    image_size,
	action,
	
    // output signals
    out_valid,
    out_value
    );

input            clk, rst_n;
input            in_valid, in_valid2;

input      [7:0] image;
input      [7:0] template;
input      [1:0] image_size;
input      [2:0] action;

output reg       out_valid;
output reg       out_value;

//==================================================================
// parameter & integer
//==================================================================
typedef enum reg[3:0]{IDLE=4'b0000, IN1 = 4'b0001,IN2 = 4'b0010,MEDIAN = 4'b0011, POOL = 4'b0100,CONV = 4'b0110,FLIP=4'b0111,WAIT_IN2=4'b1000,NEG=4'b1001,CAL_FLIP=4'b1010,GRAY=4'b1011}state;
integer i,j;
//==================================================================
// reg & wire
//==================================================================
state cur_state,nxt_state;
reg [7:0] template_ff[0:2][0:2];
reg [7:0] img_ff,img_nxt;
reg [7:0] cal_ff[0:15][0:15],cal_nxt[0:15][0:15];
reg [9:0] counter_st;
reg [4:0] counter_row,counter_column;
reg [4:0] counter_20;
reg [4:0] counter_sup;
reg [19:0] ans_nxt,ans_ff,ans_store;
reg [15:0] mul_ans_nxt,mul_ans_ff;
reg [7:0] pix_chosed_nxt,pix_chosed_ff,tem_chosed_nxt,tem_chosed_ff;
reg [5:0] counter_acc;
reg [2:0]action_ff[0:6];
reg [2:0]action_gray;
reg [1:0]size_ff,size_ff_origin;
reg [9:0]tmp_nxt,tmp_ff,tmp1_nxt,tmp1_ff;
reg web_big,web_small,web_gray;
reg MEDIAN_finish,POOL_finish,OUT_finish,GRAY_finish;
reg [4:0]m;
reg [7:0]biggest;
reg [6:0]addr1;
reg [63:0]data_in1,data_in2,data_out1,data_out2;
reg [7:0]cmp[0:3],max,n1,n2;
reg [7:0]sort[0:8],sort_nxt[0:8],n[0:30],n10_ff,n11_ff,n13_ff,n14_ff,n20_ff,n16_ff,n17_ff,mid;
reg [7:0]queue[0:14],queue_nxt[0:14];
reg out_valid_comb,out_value_comb;
reg NEG_finish,FLIP_finish;
//==================================================================
//                              FSM
//==================================================================

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
        GRAY_finish<=0;
    end
    else if(cur_state==GRAY)begin
        if(GRAY_finish==1)begin
            GRAY_finish<=0;
        end
        else if(size_ff==0&&counter_st==1)begin        
            GRAY_finish<=1;
        end
        else if(size_ff==1&&counter_st==7)begin
            GRAY_finish<=1;
        end
        else if(size_ff==2&&counter_st==31)begin
            GRAY_finish<=1;
        end
    end
    else begin
        GRAY_finish<=0;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        POOL_finish<=0;
    end
    else if(((cur_state==MEDIAN&&MEDIAN_finish)||(cur_state==GRAY&&GRAY_finish))&&size_ff==0&&action_ff[0]==3)begin
        POOL_finish<=1;
    end
    else if((cur_state==NEG||cur_state==FLIP)&&action_ff[0]==3&&size_ff==0)begin
        POOL_finish<=1;
    end
    else if(cur_state==POOL)begin
        if(size_ff==1&&counter_st==14)begin
            POOL_finish<=1;
        end
        else if(size_ff==2&&counter_st==62)begin
            POOL_finish<=1;
        end
        else if(POOL_finish==1&&action_ff[0]==3&&(size_ff==1||size_ff==0))begin
            POOL_finish<=1;
        end
        else begin
            POOL_finish<=0;
        end
    end
    else begin
        POOL_finish<=0;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        MEDIAN_finish<=0;
    end
    else if(cur_state==MEDIAN)begin
        if(MEDIAN_finish==1)begin
            MEDIAN_finish<=0;
        end
        else if(size_ff==0&&counter_st==19)begin   //counter_st==20:finish     
            MEDIAN_finish<=1;
        end
        else if(size_ff==1&&counter_st==71)begin
            MEDIAN_finish<=1;
        end
        else if(size_ff==2&&counter_st==271)begin
            MEDIAN_finish<=1;
        end
    end
    else begin
        MEDIAN_finish<=0;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        FLIP_finish<=0;
    end
    else if(nxt_state==FLIP)begin
        FLIP_finish<=1;
    end
    else begin
        FLIP_finish<=0;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        NEG_finish<=0;
    end
    else if(nxt_state==NEG)begin
        NEG_finish<=1;
    end
    else begin
        NEG_finish<=0;
    end
end
always@(*)begin
    nxt_state=cur_state;
    case(cur_state)
        IDLE:begin
            if(in_valid)
                nxt_state=IN1;
            else if(in_valid2)
                nxt_state=IN2;
            else 
                nxt_state=cur_state;
        end
        IN1:begin
            if(in_valid)  
                nxt_state=IN1; 
            else 
                nxt_state=WAIT_IN2;
        end
        WAIT_IN2:begin
            if(in_valid2)
                nxt_state=IN2;
            else 
                nxt_state=cur_state;
        end
        IN2:begin
            if(in_valid2)
                nxt_state=IN2;
            else begin
                nxt_state=GRAY;
            end
        end
        GRAY:begin
            if(GRAY_finish==0)
                nxt_state=GRAY;
            else begin
                case(action_ff[0])
                    3: nxt_state=POOL;
                    4: nxt_state=NEG;
                    5: nxt_state=FLIP;
                    6: nxt_state=MEDIAN; 
                    7: begin
                            nxt_state=CONV;
                    end
                    default: nxt_state=CONV;
                endcase
            end
        end
        FLIP:begin
                if(FLIP_finish==0)begin
                    nxt_state=FLIP;
                end
                else begin                
                    case(action_ff[0])
                        3: nxt_state=POOL;
                        4: nxt_state=NEG;
                        5: nxt_state=FLIP;
                        6: nxt_state=MEDIAN; 
                        7: begin
                            nxt_state=CONV;
                        end
                        default: nxt_state=CONV;
                    endcase
                end
        end
        NEG:begin
                if(NEG_finish==0)begin
                    nxt_state=FLIP;
                end
                case(action_ff[0])
                    3: nxt_state=POOL;
                    4: nxt_state=NEG;
                    5: nxt_state=FLIP;
                    6: nxt_state=MEDIAN; 
                    7: begin
                            nxt_state=CONV;
                    end
                    default: nxt_state=CONV;
                endcase
            
        end
        MEDIAN:begin
            if(MEDIAN_finish==0)
                nxt_state=MEDIAN;
            else begin
                case(action_ff[0])
                    3: nxt_state=POOL;
                    4: nxt_state=NEG;
                    5: nxt_state=FLIP;
                    6: nxt_state=MEDIAN; 
                    7: begin
                            nxt_state=CONV;
                    end
                    default: nxt_state=CONV;
                endcase
            end
        end
        POOL:begin
            if(POOL_finish==0)
                nxt_state=POOL;
            else begin
                case(action_ff[0])
                    3: nxt_state=POOL;
                    4: nxt_state=NEG;
                    5: nxt_state=FLIP;
                    6: nxt_state=MEDIAN; 
                    7: begin
                            nxt_state=CONV;
                    end
                    default: nxt_state=CONV;
                endcase
            end
        end
        CONV:begin
            if(OUT_finish==1)begin
                nxt_state=IDLE;
            end
            else
                nxt_state=cur_state;
        end

    endcase
end
//==================================================================
//                              counter
//==================================================================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        counter_st<=0;
    
    else if(nxt_state==cur_state)
        if((FLIP_finish||GRAY_finish||NEG_finish||MEDIAN_finish||POOL_finish))begin
            counter_st<=0;
        end
        else begin
            counter_st<=counter_st+1;
        end
    else 
        counter_st<=0;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        counter_sup<=0;
        counter_acc<=0;
    end 
    else if(nxt_state!=cur_state&&cur_state!=IN1)begin
        counter_sup<=0;
        counter_acc<=0;
    end
    else begin
        case(cur_state)
            IDLE:begin
                counter_sup<=0;
                counter_acc<=0;
            end
            IN1,WAIT_IN2:begin
                counter_sup<=(counter_sup==23)?0:counter_sup+1;
                counter_acc<=(counter_sup==22)?counter_acc+1:counter_acc;
            end 
            POOL:begin
                if(POOL_finish)begin
                    counter_sup<=0;
                    counter_acc<=0;
                end
                else begin
                    counter_sup<=(counter_sup==7)?0:counter_sup+1;
                    counter_acc<=(counter_sup==7)?counter_acc+1:counter_acc;
                end
                
            end
            MEDIAN:begin
                if(MEDIAN_finish)begin
                    counter_sup<=0;
                    counter_acc<=0;
                end
                else begin
                    case(size_ff)
                        0:begin
                            counter_sup<=(counter_sup==3)?0:counter_sup+1;
                            counter_acc<=(counter_sup==3)?counter_acc+1:counter_acc;
                        end
                        1:begin
                            counter_sup<=(counter_sup==7)?0:counter_sup+1;
                            counter_acc<=(counter_sup==7)?counter_acc+1:counter_acc;
                        end
                        2:begin
                            counter_sup<=(counter_sup==15)?0:counter_sup+1;
                            counter_acc<=(counter_sup==15)?counter_acc+1:counter_acc;
                        end
                    endcase
                end
                
                
            end
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
            MEDIAN:begin
                if((nxt_state!=MEDIAN)||MEDIAN_finish)begin
                    counter_row<=0;
                    counter_column<=0;
                end
                else begin
                    case(size_ff)
                        0:begin
                            if(counter_st==4)begin
                                counter_row<=0;
                                counter_column<=0;
                            end
                            else if(counter_st>=5)begin
                                counter_column<=(counter_column==3)?0:counter_column+1;
                                counter_row<=(counter_column==3)?counter_row+1:counter_row;
                            end
                        end
                        1:begin
                            if(counter_st==8)begin
                                counter_row<=0;
                                counter_column<=0;
                            end
                            else if(counter_st>=9)begin
                                counter_column<=(counter_column==7)?0:counter_column+1;
                                counter_row<=(counter_column==7)?counter_row+1:counter_row;
                            end
                        end
                        2:begin
                            if(counter_st==16)begin
                                counter_row<=0;
                                counter_column<=0;
                            end
                            else if(counter_st>=17)begin
                                counter_column<=(counter_column==15)?0:counter_column+1;
                                counter_row<=(counter_column==15)?counter_row+1:counter_row;
                            end
                        end
                    endcase
                end
                
            end
            CONV:begin
                if(counter_20!=19)begin
                    counter_column<=counter_column;
                    counter_row<=counter_row;
                end
                else begin
                    case(size_ff)
                    0:begin
                        counter_column<=(counter_column==3)?0:counter_column+1;
                        counter_row<=(counter_column==3)?counter_row+1:counter_row;
                    end
                    1:begin
                        counter_column<=(counter_column==7)?0:counter_column+1;
                        counter_row<=(counter_column==7)?counter_row+1:counter_row;
                    end
                    2:begin
                        counter_column<=(counter_column==15)?0:counter_column+1;
                        counter_row<=(counter_column==15)?counter_row+1:counter_row;
                    end
                endcase
            end
                
            end
            default:begin
                counter_row<=0;
                counter_column<=0;
            end
        endcase
    end
    
end
        


//==================================================================//
//                              READ                                //
//==================================================================//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        template_ff[0][0]<=0;
        template_ff[0][1]<=0;
        template_ff[0][2]<=0;
        template_ff[1][0]<=0;
        template_ff[1][1]<=0;
        template_ff[1][2]<=0;
        template_ff[2][0]<=0;
        template_ff[2][1]<=0;
        template_ff[2][2]<=0;
    end
    else begin
        if(cur_state==IDLE&&in_valid)begin
            template_ff[0][0]<=template;
        end
        if(cur_state==IN1)begin
            case(counter_st)
                0:template_ff[0][1]<=template;
                1:template_ff[0][2]<=template;
                2:template_ff[1][0]<=template;
                3:template_ff[1][1]<=template;
                4:template_ff[1][2]<=template;
                5:template_ff[2][0]<=template;
                6:template_ff[2][1]<=template;
                7:template_ff[2][2]<=template;
            endcase
        end
        
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        size_ff_origin<=0;
    end
    else begin
        if(cur_state==IDLE&&in_valid)
            size_ff_origin<=image_size;
    end
end
always@(posedge clk or negedge rst_n)begin //======read action=========//
    if(!rst_n)begin
        action_gray<=0;
    end
    else begin
        if(in_valid2&&(cur_state==WAIT_IN2||cur_state==IDLE))
            action_gray<=action;
        else begin
            action_gray<=action_gray;
        end
    end
    
end
always@(posedge clk or negedge rst_n)begin //======read action=========//
    if(!rst_n)begin
        for(i=0;i<=6;i=i+1)begin
            action_ff[i]<=0;
        end
    end
    else begin
        if(nxt_state==IDLE)begin
            for(i=0;i<=6;i=i+1)begin
                action_ff[i]<=0;
            end
        end
        else if(in_valid2&&cur_state==IN2)begin
            action_ff[counter_st]<=action;
        end
        else if((nxt_state!=cur_state&&cur_state!=IN2)||FLIP_finish||GRAY_finish||MEDIAN_finish||POOL_finish||NEG_finish)begin
            action_ff[6]<=0;
            for(i=5;i>=0;i=i-1)begin
                action_ff[i]<=action_ff[i+1];
            end
        end
    end
    
end


//==================================================================//
//                          control signal                          //
//==================================================================//


always@(posedge clk or negedge rst_n)begin //size_ff
    if(!rst_n)begin
        size_ff<=0;
    end
    else if(in_valid&&cur_state==IDLE) begin
        size_ff<=image_size;
    end
    else if(cur_state==IN2)begin
        size_ff<=size_ff_origin;
    end
    else if(POOL_finish)begin
        case(size_ff)
            0: size_ff<=0;
            1: size_ff<=0;
            2: size_ff<=1;
        endcase
    end

end


//==================================================================//
//                          memory address                          //
//==================================================================//
always@*begin
    addr1=0;
    case(cur_state)
        IN1,WAIT_IN2:begin //READ RGB from pattern, put 3 type grayscale into memory_big(addr1)
            if(counter_sup==23&&counter_acc>=1)
                addr1=counter_acc-1;
            else if(counter_sup==0&&counter_acc>=1)
                addr1=counter_acc+31;
            else if(counter_sup==1&&counter_acc>=1)
                addr1=counter_acc+63;
            else 
                addr1=0;
        end
        GRAY:begin
            case(action_gray)
                0:begin
                    addr1=counter_st;
                end
                1:begin
                    addr1=counter_st+32;
                end
                2:begin
                    if(counter_st<32)
                        addr1=counter_st+64;
                end
            endcase
        end
        
    endcase
    
end



//==================================================================//
//                          calculate                               //
//==================================================================//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        img_ff<=0;
    else begin
        img_ff<=img_nxt;
    end
end
always @(*) begin
    if(in_valid)
        img_nxt=image;
    else 
        img_nxt=img_ff;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<=15;i=i+1)begin
            for(j=0;j<=15;j=j+1)begin
                cal_ff[i][j]<=0;
            end
            
        end
    end
    else begin
        for(i=0;i<=15;i=i+1)begin
            for(j=0;j<=15;j=j+1)begin
                cal_ff[i][j]<=cal_nxt[i][j];
            end
        end
    end
    
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        tmp_ff<=0;
    end
    else begin
        tmp_ff<=tmp_nxt;
    end
end
always@*begin
    for(i=0;i<=15;i=i+1)begin
        for(j=0;j<=15;j=j+1)begin
            cal_nxt[i][j]=cal_ff[i][j];
        end
    end
    tmp_nxt=0;
    case(cur_state)
        IDLE:begin
        end
        IN1,WAIT_IN2:begin
            case(counter_sup)
                0,3,6,9,12,15,18,21:begin
                    cal_nxt[0][0]=img_ff;
                    tmp_nxt=img_ff;
                    cal_nxt[0][2]=img_ff>>2;
                end           
                1,4,7,10,13,16,19,22:begin
                    if(img_ff>=cal_ff[0][0])begin
                        cal_nxt[0][0]=img_ff;
                    end
                    else begin
                        cal_nxt[0][0]=cal_ff[0][0];
                    end
                    tmp_nxt=tmp_ff+img_ff;
                    cal_nxt[0][2]=cal_ff[0][2]+(img_ff>>1);
                end
                2:begin
                    cal_nxt[0][0]=(img_ff>=cal_ff[0][0])?img_ff:cal_ff[0][0];
                    tmp_nxt=((tmp_ff+img_ff)>=511)?((tmp_ff+img_ff-1)*171)>>9:((tmp_ff+img_ff)*171)>>9;
                    cal_nxt[0][2]=cal_ff[0][2]+(img_ff>>2);

                    cal_nxt[1][0]=cal_nxt[0][0];
                    cal_nxt[1][1]=tmp_nxt;
                    cal_nxt[1][2]=cal_nxt[0][2];
                end
                5:begin
                    cal_nxt[0][0]=(img_ff>=cal_ff[0][0])?img_ff:cal_ff[0][0];
                    tmp_nxt=((tmp_ff+img_ff)>=511)?((tmp_ff+img_ff-1)*171)>>9:((tmp_ff+img_ff)*171)>>9;
                    cal_nxt[0][2]=cal_ff[0][2]+(img_ff>>2);

                    cal_nxt[2][0]=cal_nxt[0][0];
                    cal_nxt[2][1]=tmp_nxt;
                    cal_nxt[2][2]=cal_nxt[0][2];
                end
                8:begin
                    cal_nxt[0][0]=(img_ff>=cal_ff[0][0])?img_ff:cal_ff[0][0];
                    tmp_nxt=((tmp_ff+img_ff)>=511)?((tmp_ff+img_ff-1)*171)>>9:((tmp_ff+img_ff)*171)>>9;
                    cal_nxt[0][2]=cal_ff[0][2]+(img_ff>>2);

                    cal_nxt[3][0]=cal_nxt[0][0];
                    cal_nxt[3][1]=tmp_nxt;
                    cal_nxt[3][2]=cal_nxt[0][2];
                end
                11:begin
                    cal_nxt[0][0]=(img_ff>=cal_ff[0][0])?img_ff:cal_ff[0][0];
                    tmp_nxt=((tmp_ff+img_ff)>=511)?((tmp_ff+img_ff-1)*171)>>9:((tmp_ff+img_ff)*171)>>9;
                    cal_nxt[0][2]=cal_ff[0][2]+(img_ff>>2);

                    cal_nxt[4][0]=cal_nxt[0][0];
                    cal_nxt[4][1]=tmp_nxt;
                    cal_nxt[4][2]=cal_nxt[0][2];
                end
                14:begin
                    cal_nxt[0][0]=(img_ff>=cal_ff[0][0])?img_ff:cal_ff[0][0];
                    tmp_nxt=((tmp_ff+img_ff)>=511)?((tmp_ff+img_ff-1)*171)>>9:((tmp_ff+img_ff)*171)>>9;
                    cal_nxt[0][2]=cal_ff[0][2]+(img_ff>>2);

                    cal_nxt[5][0]=cal_nxt[0][0];
                    cal_nxt[5][1]=tmp_nxt;
                    cal_nxt[5][2]=cal_nxt[0][2];
                end
                17:begin
                    cal_nxt[0][0]=(img_ff>=cal_ff[0][0])?img_ff:cal_ff[0][0];
                    tmp_nxt=((tmp_ff+img_ff)>=511)?((tmp_ff+img_ff-1)*171)>>9:((tmp_ff+img_ff)*171)>>9;
                    cal_nxt[0][2]=cal_ff[0][2]+(img_ff>>2);

                    cal_nxt[6][0]=cal_nxt[0][0];
                    cal_nxt[6][1]=tmp_nxt;
                    cal_nxt[6][2]=cal_nxt[0][2];
                end
                20:begin
                    cal_nxt[0][0]=(img_ff>=cal_ff[0][0])?img_ff:cal_ff[0][0];
                    tmp_nxt=((tmp_ff+img_ff)>=511)?((tmp_ff+img_ff-1)*171)>>9:((tmp_ff+img_ff)*171)>>9;
                    cal_nxt[0][2]=cal_ff[0][2]+(img_ff>>2);

                    cal_nxt[7][0]=cal_nxt[0][0];
                    cal_nxt[7][1]=tmp_nxt;
                    cal_nxt[7][2]=cal_nxt[0][2];
                end
                23:begin
                    cal_nxt[0][0]=(img_ff>=cal_ff[0][0])?img_ff:cal_ff[0][0];
                    tmp_nxt=((tmp_ff+img_ff)>=511)?((tmp_ff+img_ff-1)*171)>>9:((tmp_ff+img_ff)*171)>>9;
                    cal_nxt[0][2]=cal_ff[0][2]+(img_ff>>2);

                    cal_nxt[8][0]=cal_nxt[0][0];
                    cal_nxt[8][1]=tmp_nxt;
                    cal_nxt[8][2]=cal_nxt[0][2];
                end
            endcase
        end
        GRAY:begin
            for(i=0;i<=15;i=i+1)begin
                for(j=0;j<=15;j=j+1)begin
                    cal_nxt[i][j]=cal_ff[i][j];
                end
            end
            case(size_ff)  
                0:begin
                    case(counter_st)
                        1:begin
                            cal_nxt[0][0]=data_out1[63:56];
                            cal_nxt[0][1]=data_out1[55:48];
                            cal_nxt[0][2]=data_out1[47:40];
                            cal_nxt[0][3]=data_out1[39:32];
                            cal_nxt[1][0]=data_out1[31:24];
                            cal_nxt[1][1]=data_out1[23:16];
                            cal_nxt[1][2]=data_out1[15:8];
                            cal_nxt[1][3]=data_out1[7:0];
                        end
                        2:begin
                            cal_nxt[2][0]=data_out1[63:56];
                            cal_nxt[2][1]=data_out1[55:48];
                            cal_nxt[2][2]=data_out1[47:40];
                            cal_nxt[2][3]=data_out1[39:32];
                            cal_nxt[3][0]=data_out1[31:24];
                            cal_nxt[3][1]=data_out1[23:16];
                            cal_nxt[3][2]=data_out1[15:8];
                            cal_nxt[3][3]=data_out1[7:0];
                        end
                    endcase
                    
                end
                1:begin
                    if(counter_st!=0)begin
                        cal_nxt[counter_st-1][0]=data_out1[63:56];
                        cal_nxt[counter_st-1][1]=data_out1[55:48];
                        cal_nxt[counter_st-1][2]=data_out1[47:40];
                        cal_nxt[counter_st-1][3]=data_out1[39:32];
                        cal_nxt[counter_st-1][4]=data_out1[31:24];
                        cal_nxt[counter_st-1][5]=data_out1[23:16];
                        cal_nxt[counter_st-1][6]=data_out1[15:8];
                        cal_nxt[counter_st-1][7]=data_out1[7:0];      
                    end
                              
                end
                2:begin
                    if(counter_st!=0&&counter_st!=96)begin
                        if(counter_st[0]==1)begin
                            cal_nxt[(counter_st-1)>>1][0]=data_out1[63:56];
                            cal_nxt[(counter_st-1)>>1][1]=data_out1[55:48];
                            cal_nxt[(counter_st-1)>>1][2]=data_out1[47:40];
                            cal_nxt[(counter_st-1)>>1][3]=data_out1[39:32];
                            cal_nxt[(counter_st-1)>>1][4]=data_out1[31:24];
                            cal_nxt[(counter_st-1)>>1][5]=data_out1[23:16];
                            cal_nxt[(counter_st-1)>>1][6]=data_out1[15:8];
                            cal_nxt[(counter_st-1)>>1][7]=data_out1[7:0];
                        end
                        else begin
                                cal_nxt[(counter_st-1)>>1][8 ]=data_out1[63:56];
                                cal_nxt[(counter_st-1)>>1][9 ]=data_out1[55:48];
                                cal_nxt[(counter_st-1)>>1][10]=data_out1[47:40];
                                cal_nxt[(counter_st-1)>>1][11]=data_out1[39:32];
                                cal_nxt[(counter_st-1)>>1][12]=data_out1[31:24];
                                cal_nxt[(counter_st-1)>>1][13]=data_out1[23:16];
                                cal_nxt[(counter_st-1)>>1][14]=data_out1[15:8];
                                cal_nxt[(counter_st-1)>>1][15]=data_out1[7:0];
                        end
                    end
                    
                    
                end
            endcase
            
        end
        FLIP:begin
            case(size_ff)
                0:begin
                    for(i=0;i<=3;i=i+1)begin
                        for(j=0;j<=1;j=j+1)begin
                            cal_nxt[i][j]=cal_ff[i][3-j];
                            cal_nxt[i][3-j]=cal_ff[i][j];
                        end
                        
                    end
                end
                1:begin
                    for(i=0;i<=7;i=i+1)begin
                        for(j=0;j<=3;j=j+1)begin
                            cal_nxt[i][7-j]=cal_ff[i][j];
                            cal_nxt[i][j]=cal_ff[i][7-j];
                        end
                    end
                end
                2:begin
                    for(i=0;i<=15;i=i+1)begin
                        for(j=0;j<=7;j=j+1)begin
                            cal_nxt[i][j]=cal_ff[i][15-j];
                            cal_nxt[i][15-j]=cal_ff[i][j];
                        end
                    end
                end
            endcase
        end
        NEG:begin
            for(i=0;i<=15;i=i+1)begin
                for(j=0;j<=15;j=j+1)begin
                    cal_nxt[i][j]=~cal_ff[i][j];
                end
            end
        end
        POOL:begin
            case(size_ff)
                0:begin //do not change cal_ff

                end
                1:begin
                    case(counter_st)
                        0:begin
                            cal_nxt[0][0]=max;  
                        end
                        1:begin  
                            cal_nxt[0][1]=max; 
                        end
                        2:begin
                            cal_nxt[0][2]=max;   
                        end
                        3:begin
                            cal_nxt[0][3]=max;   
                        end
                        4:begin
                            cal_nxt[1][0]=max;   
                        end
                        5:begin
                            cal_nxt[1][1]=max;   
                        end
                        6:begin
                            cal_nxt[1][2]=max;    
                        end
                        7:begin  
                            cal_nxt[1][3]=max; 
                        end
                        8:begin
                            cal_nxt[2][0]=max;   
                        end
                        9:begin  
                            cal_nxt[2][1]=max;   
                        end
                        10:begin
                            cal_nxt[2][2]=max;     
                        end
                        11:begin
                            cal_nxt[2][3]=max;    
                        end
                        12:begin 
                            cal_nxt[3][0]=max;    
                        end
                        13:begin  
                            cal_nxt[3][1]=max;
                        end
                        14:begin 
                            cal_nxt[3][2]=max; 
                        end
                        15:begin  
                            cal_nxt[3][3]=max;
                        end

                    endcase
                end
                2:begin
                    cal_nxt[counter_acc][counter_sup]=max;
                end
            endcase
        end
        MEDIAN:begin
            case(size_ff)
                0:begin
                    if(counter_st>=5)begin
                        cal_nxt[counter_row][counter_column]=queue[0];
                    end
                        
                end
                1:begin
                    if(counter_st>=9)begin
                        cal_nxt[counter_row][counter_column]=queue[0];
                    end
                        
                end
                2:begin
                    if(counter_st>=17)begin
                        cal_nxt[counter_row][counter_column]=queue[0];
                    end
                        
                end
            endcase
        end
        CONV:begin

        end
    endcase
end
always@*begin
    if(cmp[0]>=cmp[1])begin
        n1=cmp[0];
    end
    else begin
        n1=cmp[1];
    end
    if(cmp[2]>=cmp[3])
        n2=cmp[2];
    else 
        n2=cmp[3];
    if(n2>=n1)
        max=n2;
    else
        max=n1;
end
always@*begin
    cmp[0]=0;
    cmp[1]=0;
    cmp[2]=0;
    cmp[3]=0;
    if(cur_state==POOL)begin
        case(size_ff)
            0:begin
                cmp[0]=0;
                cmp[1]=0;
                cmp[2]=0;
                cmp[3]=0;
            end
            1:begin
                case(counter_st)
                    0:begin  
                        cmp[0]= cal_ff[0][0];cmp[1]=cal_ff[0][1] ;cmp[2]= cal_ff[1][0];cmp[3]= cal_ff[1][1];
                    end
                    1:begin  
                        cmp[0]= cal_ff[0][2];cmp[1]=cal_ff[0][3] ;cmp[2]= cal_ff[1][2];cmp[3]= cal_ff[1][3];
                    end
                    2:begin  
                        cmp[0]= cal_ff[0][4];cmp[1]=cal_ff[0][5] ;cmp[2]= cal_ff[1][4];cmp[3]= cal_ff[1][5];
                    end
                    3:begin  
                        cmp[0]= cal_ff[0][6];cmp[1]=cal_ff[0][7] ;cmp[2]= cal_ff[1][6];cmp[3]= cal_ff[1][7];
                    end
                    4:begin  
                        cmp[0]= cal_ff[2][0];cmp[1]=cal_ff[2][1] ;cmp[2]= cal_ff[3][0];cmp[3]= cal_ff[3][1];
                    end
                    5:begin  
                        cmp[0]= cal_ff[2][2];cmp[1]=cal_ff[2][3] ;cmp[2]= cal_ff[3][2];cmp[3]= cal_ff[3][3];
                    end
                    6:begin  
                        cmp[0]= cal_ff[2][4];cmp[1]=cal_ff[2][5] ;cmp[2]= cal_ff[3][4];cmp[3]= cal_ff[3][5];
                    end
                    7:begin  
                        cmp[0]= cal_ff[2][6];cmp[1]=cal_ff[2][7] ;cmp[2]= cal_ff[3][6];cmp[3]= cal_ff[3][7];
                    end
                    8:begin  
                        cmp[0]= cal_ff[4][0];cmp[1]=cal_ff[4][1] ;cmp[2]= cal_ff[5][0];cmp[3]= cal_ff[5][1];
                    end
                    9:begin  
                        cmp[0]= cal_ff[4][2];cmp[1]=cal_ff[4][3] ;cmp[2]= cal_ff[5][2];cmp[3]= cal_ff[5][3];
                    end
                    10:begin  
                        cmp[0]= cal_ff[4][4];cmp[1]=cal_ff[4][5] ;cmp[2]= cal_ff[5][4];cmp[3]= cal_ff[5][5];
                    end
                    11:begin  
                        cmp[0]= cal_ff[4][6];cmp[1]=cal_ff[4][7] ;cmp[2]= cal_ff[5][6];cmp[3]= cal_ff[5][7];
                    end
                    12:begin  
                        cmp[0]= cal_ff[6][0];cmp[1]=cal_ff[6][1] ;cmp[2]= cal_ff[7][0];cmp[3]= cal_ff[7][1];
                    end
                    13:begin  
                        cmp[0]= cal_ff[6][2];cmp[1]=cal_ff[6][3] ;cmp[2]= cal_ff[7][2];cmp[3]= cal_ff[7][3];
                    end
                    14:begin  
                        cmp[0]= cal_ff[6][4];cmp[1]=cal_ff[6][5] ;cmp[2]= cal_ff[7][4];cmp[3]= cal_ff[7][5];
                    end
                    15:begin  
                        cmp[0]= cal_ff[6][6];cmp[1]=cal_ff[6][7] ;cmp[2]= cal_ff[7][6];cmp[3]= cal_ff[7][7];
                    end
                endcase
            end
            2:begin
                cmp[0]=cal_ff[counter_acc<<1][counter_sup<<1];
                cmp[1]=cal_ff[counter_acc<<1][(counter_sup<<1)+1];
                cmp[2]=cal_ff[(counter_acc<<1)+1][(counter_sup<<1)];
                cmp[3]=cal_ff[(counter_acc<<1)+1][(counter_sup<<1)+1];
            end
            
        endcase
    end
end
//================sort=================//
always@(*)begin
    sort_nxt[0]=0;
    sort_nxt[1]=0;
    sort_nxt[2]=0;
    sort_nxt[3]=0;
    sort_nxt[4]=0;
    sort_nxt[5]=0;
    sort_nxt[6]=0;
    sort_nxt[7]=0;
    sort_nxt[8]=0;
    if(cur_state==MEDIAN)begin
        case(size_ff)
            0:begin
                case(counter_acc)
                    0:begin
                        case(counter_sup)
                            0:begin
                                sort_nxt[0]=cal_ff[0][0];
                                sort_nxt[1]=cal_ff[0][0];
                                sort_nxt[2]=cal_ff[0][1];
                                sort_nxt[3]=cal_ff[0][0];
                                sort_nxt[4]=cal_ff[0][0];
                                sort_nxt[5]=cal_ff[0][1];
                                sort_nxt[6]=cal_ff[1][0];
                                sort_nxt[7]=cal_ff[1][0];
                                sort_nxt[8]=cal_ff[1][1];
                            end
                            3:begin
                                sort_nxt[0]=cal_ff[0][2];
                                sort_nxt[1]=cal_ff[0][3];
                                sort_nxt[2]=cal_ff[0][3];
                                sort_nxt[3]=cal_ff[0][2];
                                sort_nxt[4]=cal_ff[0][3];
                                sort_nxt[5]=cal_ff[0][3];
                                sort_nxt[6]=cal_ff[1][2];
                                sort_nxt[7]=cal_ff[1][3];
                                sort_nxt[8]=cal_ff[1][3];
                            end
                            default:begin
                                sort_nxt[0]=cal_ff[0][counter_sup-1];
                                sort_nxt[1]=cal_ff[0][counter_sup];
                                sort_nxt[2]=cal_ff[0][counter_sup+1];
                                sort_nxt[3]=cal_ff[0][counter_sup-1];
                                sort_nxt[4]=cal_ff[0][counter_sup];
                                sort_nxt[5]=cal_ff[0][counter_sup+1];
                                sort_nxt[6]=cal_ff[1][counter_sup-1];
                                sort_nxt[7]=cal_ff[1][counter_sup];
                                sort_nxt[8]=cal_ff[1][counter_sup+1];
                            end
                        endcase
                    end
                    3:begin
                        case(counter_sup)
                            0:begin
                                sort_nxt[0]=cal_ff[2][0];
                                sort_nxt[1]=cal_ff[2][0];
                                sort_nxt[2]=cal_ff[2][1];
                                sort_nxt[3]=cal_ff[3][0];
                                sort_nxt[4]=cal_ff[3][0];
                                sort_nxt[5]=cal_ff[3][1];
                                sort_nxt[6]=cal_ff[3][0];
                                sort_nxt[7]=cal_ff[3][0];
                                sort_nxt[8]=cal_ff[3][1];
                            end
                            3:begin
                                sort_nxt[0]=cal_ff[2][2];
                                sort_nxt[1]=cal_ff[2][3];
                                sort_nxt[2]=cal_ff[2][3];
                                sort_nxt[3]=cal_ff[3][2];
                                sort_nxt[4]=cal_ff[3][3];
                                sort_nxt[5]=cal_ff[3][3];
                                sort_nxt[6]=cal_ff[3][2];
                                sort_nxt[7]=cal_ff[3][3];
                                sort_nxt[8]=cal_ff[3][3];
                            end
                            default:begin
                                sort_nxt[0]=cal_ff[2][counter_sup-1];
                                sort_nxt[1]=cal_ff[2][counter_sup];
                                sort_nxt[2]=cal_ff[2][counter_sup+1];
                                sort_nxt[3]=cal_ff[3][counter_sup-1];
                                sort_nxt[4]=cal_ff[3][counter_sup];
                                sort_nxt[5]=cal_ff[3][counter_sup+1];
                                sort_nxt[6]=cal_ff[3][counter_sup-1];
                                sort_nxt[7]=cal_ff[3][counter_sup];
                                sort_nxt[8]=cal_ff[3][counter_sup+1];
                            end
                        endcase
                    end
                    default:begin
                        case(counter_sup)
                            0:begin
                                sort_nxt[0]=cal_ff[counter_acc-1][0];
                                sort_nxt[1]=cal_ff[counter_acc-1][0];
                                sort_nxt[2]=cal_ff[counter_acc-1][1];
                                sort_nxt[3]=cal_ff[counter_acc][0];
                                sort_nxt[4]=cal_ff[counter_acc][0];
                                sort_nxt[5]=cal_ff[counter_acc][1];
                                sort_nxt[6]=cal_ff[counter_acc+1][0];
                                sort_nxt[7]=cal_ff[counter_acc+1][0];
                                sort_nxt[8]=cal_ff[counter_acc+1][1];
                            end
                            3:begin
                                sort_nxt[0]=cal_ff[counter_acc-1][2];
                                sort_nxt[1]=cal_ff[counter_acc-1][3];
                                sort_nxt[2]=cal_ff[counter_acc-1][3];
                                sort_nxt[3]=cal_ff[counter_acc][2];
                                sort_nxt[4]=cal_ff[counter_acc][3];
                                sort_nxt[5]=cal_ff[counter_acc][3];
                                sort_nxt[6]=cal_ff[counter_acc+1][2];
                                sort_nxt[7]=cal_ff[counter_acc+1][3];
                                sort_nxt[8]=cal_ff[counter_acc+1][3];
                            end
                            default:begin
                                sort_nxt[0]=cal_ff[counter_acc-1][counter_sup-1];
                                sort_nxt[1]=cal_ff[counter_acc-1][counter_sup];
                                sort_nxt[2]=cal_ff[counter_acc-1][counter_sup+1];
                                sort_nxt[3]=cal_ff[counter_acc][counter_sup-1];
                                sort_nxt[4]=cal_ff[counter_acc][counter_sup];
                                sort_nxt[5]=cal_ff[counter_acc][counter_sup+1];
                                sort_nxt[6]=cal_ff[counter_acc+1][counter_sup-1];
                                sort_nxt[7]=cal_ff[counter_acc+1][counter_sup];
                                sort_nxt[8]=cal_ff[counter_acc+1][counter_sup+1];
                            end
                        endcase
                    end
                endcase
            end
            1:begin
                case(counter_acc)
                    0:begin
                        case(counter_sup)
                            0:begin
                                sort_nxt[0]=cal_ff[0][0];
                                sort_nxt[1]=cal_ff[0][0];
                                sort_nxt[2]=cal_ff[0][1];
                                sort_nxt[3]=cal_ff[0][0];
                                sort_nxt[4]=cal_ff[0][0];
                                sort_nxt[5]=cal_ff[0][1];
                                sort_nxt[6]=cal_ff[1][0];
                                sort_nxt[7]=cal_ff[1][0];
                                sort_nxt[8]=cal_ff[1][1];
                            end
                            7:begin
                                sort_nxt[0]=cal_ff[0][6];
                                sort_nxt[1]=cal_ff[0][7];
                                sort_nxt[2]=cal_ff[0][7];
                                sort_nxt[3]=cal_ff[0][6];
                                sort_nxt[4]=cal_ff[0][7];
                                sort_nxt[5]=cal_ff[0][7];
                                sort_nxt[6]=cal_ff[1][6];
                                sort_nxt[7]=cal_ff[1][7];
                                sort_nxt[8]=cal_ff[1][7];
                            end
                            default:begin
                                sort_nxt[0]=cal_ff[0][counter_sup-1];
                                sort_nxt[1]=cal_ff[0][counter_sup];
                                sort_nxt[2]=cal_ff[0][counter_sup+1];
                                sort_nxt[3]=cal_ff[0][counter_sup-1];
                                sort_nxt[4]=cal_ff[0][counter_sup];
                                sort_nxt[5]=cal_ff[0][counter_sup+1];
                                sort_nxt[6]=cal_ff[1][counter_sup-1];
                                sort_nxt[7]=cal_ff[1][counter_sup];
                                sort_nxt[8]=cal_ff[1][counter_sup+1];
                            end
                        endcase
                    end
                    7:begin
                        case(counter_sup)
                            0:begin
                                sort_nxt[0]=cal_ff[6][0];
                                sort_nxt[1]=cal_ff[6][0];
                                sort_nxt[2]=cal_ff[6][1];
                                sort_nxt[3]=cal_ff[7][0];
                                sort_nxt[4]=cal_ff[7][0];
                                sort_nxt[5]=cal_ff[7][1];
                                sort_nxt[6]=cal_ff[7][0];
                                sort_nxt[7]=cal_ff[7][0];
                                sort_nxt[8]=cal_ff[7][1];
                            end
                            7:begin
                                sort_nxt[0]=cal_ff[6][6];
                                sort_nxt[1]=cal_ff[6][7];
                                sort_nxt[2]=cal_ff[6][7];
                                sort_nxt[3]=cal_ff[7][6];
                                sort_nxt[4]=cal_ff[7][7];
                                sort_nxt[5]=cal_ff[7][7];
                                sort_nxt[6]=cal_ff[7][6];
                                sort_nxt[7]=cal_ff[7][7];
                                sort_nxt[8]=cal_ff[7][7];
                            end
                            default:begin
                                sort_nxt[0]=cal_ff[6][counter_sup-1];
                                sort_nxt[1]=cal_ff[6][counter_sup];
                                sort_nxt[2]=cal_ff[6][counter_sup+1];
                                sort_nxt[3]=cal_ff[7][counter_sup-1];
                                sort_nxt[4]=cal_ff[7][counter_sup];
                                sort_nxt[5]=cal_ff[7][counter_sup+1];
                                sort_nxt[6]=cal_ff[7][counter_sup-1];
                                sort_nxt[7]=cal_ff[7][counter_sup];
                                sort_nxt[8]=cal_ff[7][counter_sup+1];
                            end
                        endcase
                    end
                    default:begin
                        case(counter_sup)
                            0:begin
                                sort_nxt[0]=cal_ff[counter_acc-1][0];
                                sort_nxt[1]=cal_ff[counter_acc-1][0];
                                sort_nxt[2]=cal_ff[counter_acc-1][1];
                                sort_nxt[3]=cal_ff[counter_acc][0];
                                sort_nxt[4]=cal_ff[counter_acc][0];
                                sort_nxt[5]=cal_ff[counter_acc][1];
                                sort_nxt[6]=cal_ff[counter_acc+1][0];
                                sort_nxt[7]=cal_ff[counter_acc+1][0];
                                sort_nxt[8]=cal_ff[counter_acc+1][1];
                            end
                            7:begin
                                sort_nxt[0]=cal_ff[counter_acc-1][6];
                                sort_nxt[1]=cal_ff[counter_acc-1][7];
                                sort_nxt[2]=cal_ff[counter_acc-1][7];
                                sort_nxt[3]=cal_ff[counter_acc][6];
                                sort_nxt[4]=cal_ff[counter_acc][7];
                                sort_nxt[5]=cal_ff[counter_acc][7];
                                sort_nxt[6]=cal_ff[counter_acc+1][6];
                                sort_nxt[7]=cal_ff[counter_acc+1][7];
                                sort_nxt[8]=cal_ff[counter_acc+1][7];
                            end
                            default:begin
                                sort_nxt[0]=cal_ff[counter_acc-1][counter_sup-1];
                                sort_nxt[1]=cal_ff[counter_acc-1][counter_sup];
                                sort_nxt[2]=cal_ff[counter_acc-1][counter_sup+1];
                                sort_nxt[3]=cal_ff[counter_acc][counter_sup-1];
                                sort_nxt[4]=cal_ff[counter_acc][counter_sup];
                                sort_nxt[5]=cal_ff[counter_acc][counter_sup+1];
                                sort_nxt[6]=cal_ff[counter_acc+1][counter_sup-1];
                                sort_nxt[7]=cal_ff[counter_acc+1][counter_sup];
                                sort_nxt[8]=cal_ff[counter_acc+1][counter_sup+1];
                            end
                        endcase
                    end
                endcase
            end
            2:begin
                case(counter_acc)
                    0:begin
                        case(counter_sup)
                            0:begin
                                sort_nxt[0]=cal_ff[0][0];
                                sort_nxt[1]=cal_ff[0][0];
                                sort_nxt[2]=cal_ff[0][1];
                                sort_nxt[3]=cal_ff[0][0];
                                sort_nxt[4]=cal_ff[0][0];
                                sort_nxt[5]=cal_ff[0][1];
                                sort_nxt[6]=cal_ff[1][0];
                                sort_nxt[7]=cal_ff[1][0];
                                sort_nxt[8]=cal_ff[1][1];
                            end
                            15:begin
                                sort_nxt[0]=cal_ff[0][14];
                                sort_nxt[1]=cal_ff[0][15];
                                sort_nxt[2]=cal_ff[0][15];
                                sort_nxt[3]=cal_ff[0][14];
                                sort_nxt[4]=cal_ff[0][15];
                                sort_nxt[5]=cal_ff[0][15];
                                sort_nxt[6]=cal_ff[1][14];
                                sort_nxt[7]=cal_ff[1][15];
                                sort_nxt[8]=cal_ff[1][15];
                            end
                            default:begin
                                sort_nxt[0]=cal_ff[0][counter_sup-1];
                                sort_nxt[1]=cal_ff[0][counter_sup];
                                sort_nxt[2]=cal_ff[0][counter_sup+1];
                                sort_nxt[3]=cal_ff[0][counter_sup-1];
                                sort_nxt[4]=cal_ff[0][counter_sup];
                                sort_nxt[5]=cal_ff[0][counter_sup+1];
                                sort_nxt[6]=cal_ff[1][counter_sup-1];
                                sort_nxt[7]=cal_ff[1][counter_sup];
                                sort_nxt[8]=cal_ff[1][counter_sup+1];
                            end
                        endcase
                    end
                    15:begin
                        case(counter_sup)
                            0:begin
                                sort_nxt[0]=cal_ff[14][0];
                                sort_nxt[1]=cal_ff[14][0];
                                sort_nxt[2]=cal_ff[14][1];
                                sort_nxt[3]=cal_ff[15][0];
                                sort_nxt[4]=cal_ff[15][0];
                                sort_nxt[5]=cal_ff[15][1];
                                sort_nxt[6]=cal_ff[15][0];
                                sort_nxt[7]=cal_ff[15][0];
                                sort_nxt[8]=cal_ff[15][1];
                            end
                            15:begin
                                sort_nxt[0]=cal_ff[14][14];
                                sort_nxt[1]=cal_ff[14][15];
                                sort_nxt[2]=cal_ff[14][15];
                                sort_nxt[3]=cal_ff[15][14];
                                sort_nxt[4]=cal_ff[15][15];
                                sort_nxt[5]=cal_ff[15][15];
                                sort_nxt[6]=cal_ff[15][14];
                                sort_nxt[7]=cal_ff[15][15];
                                sort_nxt[8]=cal_ff[15][15];
                            end
                            default:begin
                                sort_nxt[0]=cal_ff[14][counter_sup-1];
                                sort_nxt[1]=cal_ff[14][counter_sup];
                                sort_nxt[2]=cal_ff[14][counter_sup+1];
                                sort_nxt[3]=cal_ff[15][counter_sup-1];
                                sort_nxt[4]=cal_ff[15][counter_sup];
                                sort_nxt[5]=cal_ff[15][counter_sup+1];
                                sort_nxt[6]=cal_ff[15][counter_sup-1];
                                sort_nxt[7]=cal_ff[15][counter_sup];
                                sort_nxt[8]=cal_ff[15][counter_sup+1];
                            end
                        endcase
                    end
                    default:begin
                        case(counter_sup)
                            0:begin
                                sort_nxt[0]=cal_ff[counter_acc-1][0];
                                sort_nxt[1]=cal_ff[counter_acc-1][0];
                                sort_nxt[2]=cal_ff[counter_acc-1][1];
                                sort_nxt[3]=cal_ff[counter_acc][0];
                                sort_nxt[4]=cal_ff[counter_acc][0];
                                sort_nxt[5]=cal_ff[counter_acc][1];
                                sort_nxt[6]=cal_ff[counter_acc+1][0];
                                sort_nxt[7]=cal_ff[counter_acc+1][0];
                                sort_nxt[8]=cal_ff[counter_acc+1][1];
                            end
                            15:begin
                                sort_nxt[0]=cal_ff[counter_acc-1][14];
                                sort_nxt[1]=cal_ff[counter_acc-1][15];
                                sort_nxt[2]=cal_ff[counter_acc-1][15];
                                sort_nxt[3]=cal_ff[counter_acc][14];
                                sort_nxt[4]=cal_ff[counter_acc][15];
                                sort_nxt[5]=cal_ff[counter_acc][15];
                                sort_nxt[6]=cal_ff[counter_acc+1][14];
                                sort_nxt[7]=cal_ff[counter_acc+1][15];
                                sort_nxt[8]=cal_ff[counter_acc+1][15];
                            end
                            default:begin
                                sort_nxt[0]=cal_ff[counter_acc-1][counter_sup-1];
                                sort_nxt[1]=cal_ff[counter_acc-1][counter_sup];
                                sort_nxt[2]=cal_ff[counter_acc-1][counter_sup+1];
                                sort_nxt[3]=cal_ff[counter_acc][counter_sup-1];
                                sort_nxt[4]=cal_ff[counter_acc][counter_sup];
                                sort_nxt[5]=cal_ff[counter_acc][counter_sup+1];
                                sort_nxt[6]=cal_ff[counter_acc+1][counter_sup-1];
                                sort_nxt[7]=cal_ff[counter_acc+1][counter_sup];
                                sort_nxt[8]=cal_ff[counter_acc+1][counter_sup+1];
                            end
                        endcase
                    end
                endcase
            end
        endcase
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        sort[0]<=0;
        sort[1]<=0;
        sort[2]<=0;
        sort[3]<=0;
        sort[4]<=0;
        sort[5]<=0;
        sort[6]<=0;
        sort[7]<=0;
        sort[8]<=0;
    end
    else begin
        sort[0]<=sort_nxt[0];
        sort[1]<=sort_nxt[1];
        sort[2]<=sort_nxt[2];
        sort[3]<=sort_nxt[3];
        sort[4]<=sort_nxt[4];
        sort[5]<=sort_nxt[5];
        sort[6]<=sort_nxt[6];
        sort[7]<=sort_nxt[7];
        sort[8]<=sort_nxt[8];
    end
    
end
always@(*)begin
    if(sort[0]>=sort[1])begin
        n[0]=sort[0];
        n[1]=sort[1];
    end
    else begin
        n[0]=sort[1];
        n[1]=sort[0];
    end
    if(sort[3]>=sort[4])begin
        n[2]=sort[3];
        n[3]=sort[4];
    end
    else begin
        n[2]=sort[4];
        n[3]=sort[3];
    end
    if(sort[6]>=sort[7])begin
        n[5]=sort[6];
        n[6]=sort[7];
    end
    else begin
        n[5]=sort[7];
        n[6]=sort[6];
    end
    if(n[1]>=sort[2])begin
        n[8]=n[1];
        n[11]=sort[2];
    end
    else begin
        n[8]=sort[2];
        n[11]=n[1];
    end
    if(n[3]>=sort[5])begin
        n[4]=n[3];
        n[14]=sort[5];
    end
    else begin
        n[4]=sort[5];
        n[14]=n[3];
    end
    if(n[6]>=sort[8])begin
        n[7]=n[6];
        n[17]=sort[8];
    end
    else begin
        n[7]=sort[8];
        n[17]=n[6];
    end
    if(n[0]>=n[8])begin
        n[9]=n[0];
        n[10]=n[8];
    end
    else begin
        n[9]=n[8];
        n[10]=n[0];
    end
    if(n[2]>=n[4])begin
        n[12]=n[2];
        n[13]=n[4];
    end
    else begin
        n[12]=n[4];
        n[13]=n[2];
    end
    if(n[5]>=n[7])begin
        n[15]=n[5];
        n[16]=n[7];
    end
    else begin
        n[15]=n[7];
        n[16]=n[5];
    end
    if(n[9]>=n[12])begin
        n[19]=n[12];
    end
    else begin
        n[19]=n[9];
    end
    if(n[19]>=n[15])begin
        n[20]=n[15];
    end
    else begin
        n[20]=n[19];
    end
    if(n10_ff>=n13_ff)begin
        n[18]=n10_ff;
        n[23]=n13_ff;
    end
    else begin
        n[18]=n13_ff;
        n[23]=n10_ff;
    end
    if(n[23]>=n16_ff)begin
        n[25]=n[23];
    end
    else begin
        n[25]=n16_ff;
    end
    if(n[18]>=n[25])begin
        n[27]=n[25];
    end
    else begin
        n[27]=n[18];
    end
    if(n11_ff>=n14_ff)begin
        n[21]=n11_ff;
        n[26]=n14_ff;
    end
    else begin
        n[21]=n14_ff;
        n[26]=n11_ff;
    end
    if(n[26]>=n17_ff)begin
        n[28]=n[26];
    end
    else begin
        n[28]=n17_ff;
    end
    if(n[21]>=n[28])begin
        n[24]=n[21];
    end
    else begin
        n[24]=n[28];
    end
    if(n[24]>=n20_ff)begin
        n[22]=n[24];
        n[30]=n20_ff;
    end
    else begin
        n[22]=n20_ff;
        n[30]=n[24];
    end
    if(n[27]>=n[30])begin
        n[29]=n[27];
    end
    else begin
        n[29]=n[30];
    end
    if(n[22]>=n[29])begin
        mid=n[29];
    end
    else begin
        mid=n[22];
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        n10_ff<=0;
        n11_ff<=0;
        n13_ff<=0;
        n14_ff<=0;
        n20_ff<=0;
        n16_ff<=0;
        n17_ff<=0;
    end
    else begin
        n10_ff<=n[10];
        n11_ff<=n[11];
        n13_ff<=n[13];
        n14_ff<=n[14];
        n20_ff<=n[20];
        n16_ff<=n[16];
        n17_ff<=n[17];
    end
    
end


//=============================queue=====================================//
always@(posedge clk or negedge rst_n)begin //queue
    if(!rst_n)begin
        for(i=0;i<=14;i=i+1)begin
            queue[i]<=0;
        end
    end
    else begin
        for(i=0;i<=14;i=i+1)begin
            queue[i]<=queue_nxt[i];
        end
    end
end
always@(*)begin //queue
    for(i=0;i<=14;i=i+1)begin
        queue_nxt[i]=0;
    end
    case(cur_state)
        MEDIAN:begin
            for(i=0;i<=14;i=i+1)begin
                queue_nxt[i]=queue[i];
            end
            case(size_ff)
                0:begin
                    if(2<=counter_st&&counter_st<=4)begin
                        queue_nxt[counter_st-2]=mid;
                    end
                    else if(counter_st>=5&&counter_st<=20)begin
                        queue_nxt[2]=mid;
                        for(i=1;i>=0;i=i-1)begin
                            queue_nxt[i]=queue[i+1];
                        end
                    end
                end
                1:begin
                    if(2<=counter_st&&counter_st<=8)begin
                        queue_nxt[counter_st-2]=mid;
                    end
                    else if(counter_st>=9&&counter_st<=72)begin
                        queue_nxt[6]=mid;
                        for(i=5;i>=0;i=i-1)begin
                            queue_nxt[i]=queue[i+1];
                        end
                    end
                end
                2:begin
                    if(2<=counter_st&&counter_st<=16)begin
                        queue_nxt[counter_st-2]=mid;
                    end
                    else if(counter_st>=17&&counter_st<=272)begin
                        queue_nxt[14]=mid;
                        for(i=13;i>=0;i=i-1)begin
                            queue_nxt[i]=queue[i+1];
                        end
                    end
                end
                
            endcase
        end
    endcase
end

//==================================================================//
//                          convolution                             //
//==================================================================//
always@(*)begin
    m=0;
    case(size_ff)
        0:m=3;
        1:m=7;
        2:m=15;
    endcase
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        counter_20<=0;
    end
    else begin
        case(cur_state)
        CONV:begin
            counter_20<=(counter_20==19)?0:counter_20+1;
        end
        default:begin
            counter_20<=0;
        end
    endcase
    end
    
end
always@(*)begin
    pix_chosed_nxt=0;
    tem_chosed_nxt=0;
    case(cur_state)
        CONV:begin
            case(counter_20)
                0:begin
                    tem_chosed_nxt=template_ff[0][0];
                    if(counter_row==0||counter_column==0)begin
                        pix_chosed_nxt=0;
                    end
                    else begin
                        pix_chosed_nxt=cal_ff[counter_row-1][counter_column-1];
                    end
                end
                1:begin
                    tem_chosed_nxt=template_ff[0][1];
                    if(counter_row==0)begin
                        pix_chosed_nxt=0;
                    end
                    else begin
                        pix_chosed_nxt=cal_ff[counter_row-1][counter_column];
                    end
                end
                2:begin
                    tem_chosed_nxt=template_ff[0][2];
                    if(counter_row==0||counter_column==m)begin
                        pix_chosed_nxt=0;
                    end
                    else begin
                        pix_chosed_nxt=cal_ff[counter_row-1][counter_column+1];
                    end
                end
                3:begin
                    tem_chosed_nxt=template_ff[1][0];
                    if(counter_column==0)begin
                        pix_chosed_nxt=0;
                    end
                    else begin
                        pix_chosed_nxt=cal_ff[counter_row][counter_column-1];
                    end
                end
                4:begin
                    tem_chosed_nxt=template_ff[1][1];
                    pix_chosed_nxt=cal_ff[counter_row][counter_column];
                end
                5:begin
                    tem_chosed_nxt=template_ff[1][2];
                    if(counter_column==m)begin
                        pix_chosed_nxt=0;
                    end
                    else begin
                        pix_chosed_nxt=cal_ff[counter_row][counter_column+1];
                    end
                end
                6:begin
                    tem_chosed_nxt=template_ff[2][0];
                    if(counter_row==m||counter_column==0)begin
                        pix_chosed_nxt=0;
                    end
                    else begin
                        pix_chosed_nxt=cal_ff[counter_row+1][counter_column-1];
                    end
                end
                7:begin
                    tem_chosed_nxt=template_ff[2][1];
                    if(counter_row==m)begin
                        pix_chosed_nxt=0;
                    end
                    else begin
                        pix_chosed_nxt=cal_ff[counter_row+1][counter_column];
                    end
                end
                8: begin
                    tem_chosed_nxt=template_ff[2][2];
                    if(counter_row==m||counter_column==m)begin
                        pix_chosed_nxt=0;
                    end
                    else begin
                        pix_chosed_nxt=cal_ff[counter_row+1][counter_column+1];
                    end
                end
            endcase
        end
    endcase
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        tem_chosed_ff<=0;
        pix_chosed_ff<=0;
    end
    else begin
        tem_chosed_ff<=tem_chosed_nxt;
        pix_chosed_ff<=pix_chosed_nxt;
    end
end
always@(*)begin
    ans_nxt=0;
    case(cur_state)
        
        CONV:begin
            if(counter_20>=1&&counter_20<=9)begin
                ans_nxt=pix_chosed_ff*tem_chosed_ff+ans_ff;
            end
            else if(counter_20==19)begin
                ans_nxt=0;
            end
            else begin
                ans_nxt=ans_ff;
            end
        end
    endcase
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        ans_ff<=0;
    end
    else begin
        ans_ff<=ans_nxt;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        ans_store<=0;
    end
    else begin
        case(cur_state)
            CONV:begin
                if(counter_20==18)begin
                    ans_store<=ans_ff;
                end
                else begin
                    ans_store<=ans_store<<1;
                end
            end
        endcase
    end
    
end
always@(*)begin
    OUT_finish=0;
    if(cur_state==CONV&&counter_row>m&&counter_20==19)begin
        OUT_finish=1;
    end
    else begin
        OUT_finish=0;
    end
end
//==================================================================//
//                          memory write_data                       //
//==================================================================//
always@(*)begin
    data_in1=64'b0;
    data_in2=64'b0;
    case(cur_state)
        IN1,WAIT_IN2:begin
            case(counter_sup)
                23: data_in1={cal_ff[1][0],cal_ff[2][0],cal_ff[3][0],cal_ff[4][0],cal_ff[5][0],cal_ff[6][0],cal_ff[7][0],cal_nxt[8][0]};
                0:  data_in1={cal_ff[1][1],cal_ff[2][1],cal_ff[3][1],cal_ff[4][1],cal_ff[5][1],cal_ff[6][1],cal_ff[7][1],cal_nxt[8][1]};
                1:  data_in1={cal_ff[1][2],cal_ff[2][2],cal_ff[3][2],cal_ff[4][2],cal_ff[5][2],cal_ff[6][2],cal_ff[7][2],cal_nxt[8][2]};
            endcase
        end
    endcase
end
always@*begin
    web_gray=1;
    case(cur_state)
        IN1,WAIT_IN2:begin //READ RGB from pattern, put 3 type grayscale into memory_big(addr1)
            if((counter_sup==23||counter_sup==0||counter_sup==1)&&counter_acc>=1)begin
                web_gray=0;//write mode
            end
        end

    endcase
end
//==================================================================//
//                          output                                  //
//==================================================================//
always@*begin
    if(cur_state==CONV)begin
            if((counter_column==0&&counter_row==0&&counter_20!=19)||(counter_row>m&&counter_20==19))
                out_valid_comb=0;
            else 
                out_valid_comb=1; 
            
    end
    else begin
        out_valid_comb=0; 
    end
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid<=0;
    end
    else begin
        out_valid<=out_valid_comb;
    end
end
always@(*)begin
    if(cur_state==CONV)begin
            if((counter_column==0&&counter_row==0&&counter_20!=19)||(counter_row>m&&counter_20==19))
                out_value_comb=0;
            else 
                out_value_comb=ans_store[19]; 
            
    end
    else 
        out_value_comb=0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_value<=0;
    end
    else begin
        out_value<=out_value_comb;
    end
end
//==================================================================//
//                              MEM module                          //
//==================================================================//
MEM_64bit mem_64bit(.A0(addr1[0]), .A1(addr1[1]), .A2(addr1[2]), .A3(addr1[3]), .A4(addr1[4]), .A5(addr1[5]), .A6(addr1[6]), 
                    .DO0(data_out1[0]),  .DO1(data_out1[1]),  .DO2(data_out1[2]),  .DO3(data_out1[3]),  .DO4(data_out1[4]), 
                    .DO5(data_out1[5]),  .DO6(data_out1[6]),  .DO7(data_out1[7]),  .DO8(data_out1[8]),  .DO9(data_out1[9]),  
                    .DO10(data_out1[10]), .DO11(data_out1[11]), .DO12(data_out1[12]), .DO13(data_out1[13]), .DO14(data_out1[14]), 
                    .DO15(data_out1[15]), .DO16(data_out1[16]), .DO17(data_out1[17]), .DO18(data_out1[18]), .DO19(data_out1[19]), 
                    .DO20(data_out1[20]), .DO21(data_out1[21]), .DO22(data_out1[22]), .DO23(data_out1[23]), 
                    .DO24(data_out1[24]), .DO25(data_out1[25]), .DO26(data_out1[26]), .DO27(data_out1[27]), 
                    .DO28(data_out1[28]), .DO29(data_out1[29]), .DO30(data_out1[30]), .DO31(data_out1[31]), 
                    .DO32(data_out1[32]), .DO33(data_out1[33]), .DO34(data_out1[34]), .DO35(data_out1[35]), 
                    .DO36(data_out1[36]), .DO37(data_out1[37]), .DO38(data_out1[38]), .DO39(data_out1[39]), 
                    .DO40(data_out1[40]), .DO41(data_out1[41]), .DO42(data_out1[42]), .DO43(data_out1[43]), 
                    .DO44(data_out1[44]), .DO45(data_out1[45]), .DO46(data_out1[46]), .DO47(data_out1[47]), 
                    .DO48(data_out1[48]), .DO49(data_out1[49]), .DO50(data_out1[50]), .DO51(data_out1[51]), 
                    .DO52(data_out1[52]), .DO53(data_out1[53]), .DO54(data_out1[54]), .DO55(data_out1[55]), 
                    .DO56(data_out1[56]), .DO57(data_out1[57]), .DO58(data_out1[58]), .DO59(data_out1[59]), 
                    .DO60(data_out1[60]), .DO61(data_out1[61]), .DO62(data_out1[62]), .DO63(data_out1[63]),
                    .DI0(data_in1[0]),  .DI1(data_in1[1]),  .DI2(data_in1[2]),  .DI3(data_in1[3]),  .DI4(data_in1[4]),  
                    .DI5(data_in1[5]),  .DI6(data_in1[6]),  .DI7(data_in1[7]),  .DI8(data_in1[8]),  .DI9(data_in1[9]),  
                    .DI10(data_in1[10]), .DI11(data_in1[11]), .DI12(data_in1[12]), .DI13(data_in1[13]), .DI14(data_in1[14]), 
                    .DI15(data_in1[15]), .DI16(data_in1[16]), .DI17(data_in1[17]), .DI18(data_in1[18]), .DI19(data_in1[19]), 
                    .DI20(data_in1[20]), .DI21(data_in1[21]), .DI22(data_in1[22]), .DI23(data_in1[23]), 
                    .DI24(data_in1[24]), .DI25(data_in1[25]), .DI26(data_in1[26]), .DI27(data_in1[27]), 
                    .DI28(data_in1[28]), .DI29(data_in1[29]), .DI30(data_in1[30]), .DI31(data_in1[31]), 
                    .DI32(data_in1[32]), .DI33(data_in1[33]), .DI34(data_in1[34]), .DI35(data_in1[35]), 
                    .DI36(data_in1[36]), .DI37(data_in1[37]), .DI38(data_in1[38]), .DI39(data_in1[39]), 
                    .DI40(data_in1[40]), .DI41(data_in1[41]), .DI42(data_in1[42]), .DI43(data_in1[43]), 
                    .DI44(data_in1[44]), .DI45(data_in1[45]), .DI46(data_in1[46]), .DI47(data_in1[47]), 
                    .DI48(data_in1[48]), .DI49(data_in1[49]), .DI50(data_in1[50]), .DI51(data_in1[51]), 
                    .DI52(data_in1[52]), .DI53(data_in1[53]), .DI54(data_in1[54]), .DI55(data_in1[55]), 
                    .DI56(data_in1[56]), .DI57(data_in1[57]), .DI58(data_in1[58]), .DI59(data_in1[59]), 
                    .DI60(data_in1[60]), .DI61(data_in1[61]), .DI62(data_in1[62]), .DI63(data_in1[63]),
                    .CK(clk), .WEB(web_gray), .OE(1'b1), .CS(1'b1));

endmodule