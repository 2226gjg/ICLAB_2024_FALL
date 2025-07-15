module Program(input clk, INF.Program_inf inf);
import usertype::*;
//=======================================================================================================
//state def
//=======================================================================================================
typedef enum logic  [4:0] { IDLE=0,IN_FORMULA=1,IN_MODE=2,IN_DATE=3,IN_DATA_NO=4,IN_A=5,IN_B=6,IN_C=7,IN_D=8,WAIT=9,CAL_INDEX=10,CAL_UPDATE=11,CAL_DATE=12,OUT=13}  State ;
typedef enum logic  [2:0] { D_IDLE=0,READ_DRAM_SHAKE=1,READ_DRAM_DATA=2,WRITE_DRAM_SHAKE=3,WRITE_DRAM_DATA=4,WRITE_FINISH=5}  DRAM_state;
//=======================================================================================================
//logic declare
//=======================================================================================================
State cur_state,nxt_state;
DRAM_state cur_Dstate,nxt_Dstate;
Action act_ff;
Mode  mode_ff;
Formula_Type formula_ff;
Date date_ff;
logic [7:0]data_no_ff;
logic [11:0]index_A,index_B,index_C,index_D;
logic finish_read,finish_write;
logic finish_index,risk_flag,date_warn_flag,data_warn_flag;
Data_Dir DRAM_data;
Warn_Msg warn_comb;
logic complete_comb;
logic out_valid_comb;
logic [11:0] threshold;
logic [11:0]G_A,G_B,G_C,G_D;
logic [11:0]R,R_nxt;
logic [13:0] sum3;
logic [10:0] temp;
logic [2:0]counter;
//=======================================================================================================
//Design
//=======================================================================================================
//============================================//
//                     FSM                    //
//============================================//
always_ff @( posedge clk or negedge inf.rst_n ) begin :FSM
    if(!inf.rst_n)begin
        cur_state<=IDLE;
    end
    else begin
        cur_state<=nxt_state; 
    end
end
always_comb begin 
    nxt_state=cur_state;
    case(cur_state)
        IDLE:begin
            if(inf.sel_action_valid&&inf.D.d_act[0]==0)
                nxt_state=IN_FORMULA;
            else if(inf.sel_action_valid)
                nxt_state=IN_DATE;
        end
        IN_FORMULA:begin
            if(inf.formula_valid)
                nxt_state=IN_MODE;
        end
        IN_MODE:begin
            if(inf.mode_valid)
                nxt_state=IN_DATE;
        end
        IN_DATE:begin
            if(inf.date_valid)
                nxt_state=IN_DATA_NO;
        end
        IN_DATA_NO:begin
            if(act_ff==2&&inf.data_no_valid)
                nxt_state=WAIT;
            else if(inf.data_no_valid)
                nxt_state=IN_A;
        end
        IN_A:begin
            if(inf.index_valid)
                nxt_state=IN_B;
        end
        IN_B:begin
            if(inf.index_valid)
                nxt_state=IN_C;
        end
        IN_C:begin
            if(inf.index_valid)
                nxt_state=IN_D;
        end
        IN_D:begin
            if(inf.index_valid&&finish_read)begin
                case(act_ff)
                    Index_Check:
                        nxt_state=CAL_INDEX;
                    Update:
                        nxt_state=CAL_UPDATE;
                endcase
            end
            else if(inf.index_valid)
                nxt_state=WAIT;
                
        end
        WAIT:begin
            if(finish_read)begin
                case(act_ff)
                    Index_Check:
                        nxt_state=CAL_INDEX;
                    Update:
                        nxt_state=CAL_UPDATE;
                    Check_Valid_Date:
                        nxt_state=CAL_DATE;
                endcase
            end
        end
        CAL_INDEX:begin
            if((counter==3&&formula_ff!=Formula_F)||(counter==4&&formula_ff==Formula_F)||date_warn_flag==1)begin
                nxt_state=OUT;
            end
        end
        CAL_UPDATE:begin
            if(cur_Dstate==WRITE_FINISH&&inf.B_VALID)begin
                nxt_state=OUT;
            end
        end
        CAL_DATE:begin
            nxt_state=OUT;
        end
        OUT:begin
            nxt_state=IDLE;
        end
    endcase
end

always_ff @( posedge clk or negedge inf.rst_n ) begin :DRAM_FSM
    if(!inf.rst_n)begin
        cur_Dstate<=D_IDLE;
    end
    else begin
        cur_Dstate<=nxt_Dstate; 
    end
end
always_comb begin 
    nxt_Dstate=cur_Dstate;
    case(cur_Dstate)
        D_IDLE:begin
            if(inf.data_no_valid)begin
                nxt_Dstate=READ_DRAM_SHAKE;
            end
            if(cur_state==CAL_UPDATE&&counter==0)begin
                nxt_Dstate=WRITE_DRAM_SHAKE;
            end
        end
        READ_DRAM_SHAKE:begin
            if(inf.AR_READY)begin
                nxt_Dstate=READ_DRAM_DATA;
            end
        end
        READ_DRAM_DATA:begin
            if(inf.R_VALID)
                nxt_Dstate=D_IDLE;
        end
        WRITE_DRAM_SHAKE:begin
            if(inf.AW_READY)
                nxt_Dstate=WRITE_DRAM_DATA;
        end
        WRITE_DRAM_DATA:begin
            if(inf.W_READY)
                nxt_Dstate=WRITE_FINISH;
        end
        WRITE_FINISH:begin
            if(inf.B_VALID)
                nxt_Dstate=D_IDLE;
        end
    endcase
end
//============================================//
//           AXI output signal                //
//============================================//
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        inf.AR_VALID<=0;
    end
    else begin
        if(nxt_Dstate==READ_DRAM_SHAKE)
            inf.AR_VALID<=1;
        else 
            inf.AR_VALID<=0;
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n)begin
        inf.AR_ADDR<=0;
    end
    else begin
        if(nxt_Dstate==READ_DRAM_SHAKE)
            inf.AR_ADDR<=65536+(data_no_ff<<3);
        else 
            inf.AR_ADDR<=0;
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        inf.R_READY<=0;
    end
    else begin
        if(nxt_Dstate==READ_DRAM_DATA)
            inf.R_READY<=1;
        else 
            inf.R_READY<=0;
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        inf.AW_VALID<=0;
    end
    else begin
        if(nxt_Dstate==WRITE_DRAM_SHAKE)
            inf.AW_VALID<=1;
        else 
            inf.AW_VALID<=0;
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n)begin
        inf.AW_ADDR<=0;
    end
    else begin
        if(nxt_Dstate==WRITE_DRAM_SHAKE)
            inf.AW_ADDR<=65536+(data_no_ff<<3);
        else 
            inf.AW_ADDR<=0;
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        inf.W_VALID<=0;
    end
    else begin
        if(nxt_Dstate==WRITE_DRAM_DATA)
            inf.W_VALID<=1;
        else 
            inf.W_VALID<=0;
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        inf.W_DATA<=0;
    end
    else begin
        if(nxt_Dstate==WRITE_DRAM_DATA)
            inf.W_DATA<= {DRAM_data.Index_A,DRAM_data.Index_B,4'b0,DRAM_data.M,DRAM_data.Index_C,DRAM_data.Index_D,3'b0,DRAM_data.D};
        else 
            inf.W_DATA<=0;
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        inf.B_READY<=0;
    end
    else begin
        if(nxt_Dstate==WRITE_DRAM_DATA||nxt_Dstate==WRITE_FINISH)
            inf.B_READY<=1;
        else 
            inf.B_READY<=0;
    end
end
//============================================//
//              data input                    //
//============================================//
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n)begin
        act_ff<=Index_Check;
    end
    else begin
        if(inf.sel_action_valid)
            act_ff<=inf.D.d_act[0];
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n)begin
        formula_ff<=Formula_A;
    end
    else begin
        if(inf.formula_valid)
            formula_ff<=inf.D.d_formula[0];
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        mode_ff<=Insensitive;
    end
    else begin
        if(inf.mode_valid)
            mode_ff<=inf.D.d_mode[0];
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        date_ff<=0;
    end
    else begin
        if(inf.date_valid)
            date_ff<=inf.D.d_date[0];
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n)begin
        data_no_ff<=0;
    end
    else begin
        if(inf.data_no_valid)
            data_no_ff<=inf.D.d_data_no[0];
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        index_A<=0;
    end
    else begin
        if(inf.index_valid&&cur_state==IN_A)
            index_A<=inf.D.d_index[0];
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n)begin
        index_B<=0;
    end
    else begin
        if(inf.index_valid&&cur_state==IN_B)
            index_B<=inf.D.d_index[0];
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        index_C<=0;
    end
    else begin
        if(inf.index_valid&&cur_state==IN_C)
            index_C<=inf.D.d_index[0];
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        index_D<=0;
    end
    else begin
        if(inf.index_valid&&cur_state==IN_D)
            index_D<=inf.D.d_index[0];
    end
end

//============================================//
//              DRAM DATA                     //
//============================================//
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        DRAM_data.Index_A<=12'b0;
        DRAM_data.Index_B<=12'b0;
        DRAM_data.Index_C<=12'b0;
        DRAM_data.Index_D<=12'b0;
        DRAM_data.M<=8'b0;
        DRAM_data.D<=8'b0;
        data_warn_flag<=0;
    end
    else begin
        if(cur_Dstate==READ_DRAM_DATA&&inf.R_VALID)begin
            DRAM_data.Index_A<={inf.R_DATA[63:52]};
            DRAM_data.Index_B<={inf.R_DATA[51:40]};
            DRAM_data.Index_C<={inf.R_DATA[31:20]};
            DRAM_data.Index_D<={inf.R_DATA[19:8]};
            DRAM_data.M<=inf.R_DATA[35:32];
            DRAM_data.D<=inf.R_DATA[4:0];
            data_warn_flag<=0;
        end
        else if(cur_state==CAL_UPDATE&&counter==0)begin
            DRAM_data.D<=date_ff.D;
            DRAM_data.M<=date_ff.M;
            if((0>($signed({1'b0,DRAM_data.Index_A})+$signed(index_A))))begin
                DRAM_data.Index_A<=0;
                data_warn_flag<=1;
            end
            else if((($signed({1'b0,DRAM_data.Index_A})+$signed(index_A))>4095))begin
                DRAM_data.Index_A<=4095;
                data_warn_flag<=1;
            end
            else begin
                DRAM_data.Index_A<=($signed({1'b0,DRAM_data.Index_A})+$signed(index_A));
            end
            if((0 > ($signed({1'b0, DRAM_data.Index_B}) + $signed(index_B)))) begin
                DRAM_data.Index_B <= 0;
                data_warn_flag<=1;
            end
            else if((($signed({1'b0, DRAM_data.Index_B}) + $signed(index_B)) > 4095)) begin
                DRAM_data.Index_B <= 4095;
                data_warn_flag<=1;
            end
            else begin
                DRAM_data.Index_B <= ($signed({1'b0, DRAM_data.Index_B}) + $signed(index_B));
            end
            if((0 > ($signed({1'b0, DRAM_data.Index_C}) + $signed(index_C)))) begin
                DRAM_data.Index_C <= 0;
                data_warn_flag<=1;
            end
            else if((($signed({1'b0, DRAM_data.Index_C}) + $signed(index_C)) > 4095)) begin
                DRAM_data.Index_C <= 4095;
                data_warn_flag<=1;
            end
            else begin
                DRAM_data.Index_C <= ($signed({1'b0, DRAM_data.Index_C}) + $signed(index_C));
            end
            if((0 > ($signed({1'b0, DRAM_data.Index_D}) + $signed(index_D)))) begin
                DRAM_data.Index_D <= 0;
                data_warn_flag<=1;
            end
            else if((($signed({1'b0, DRAM_data.Index_D}) + $signed(index_D)) > 4095)) begin
                DRAM_data.Index_D <= 4095;
                data_warn_flag<=1;
            end
            else begin
                DRAM_data.Index_D <= ($signed({1'b0, DRAM_data.Index_D}) + $signed(index_D));
            end
        end
    end
end
//============================================//
//              FLAG                          //
//============================================//
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        finish_read<=0;
    end
    else begin
        if(cur_Dstate==READ_DRAM_DATA&&inf.R_VALID)
            finish_read<=1;
        else if(nxt_state==CAL_INDEX||nxt_state==CAL_DATE||nxt_state==CAL_UPDATE)
            finish_read<=0;
    end
end
always_comb begin
    if(cur_state==CAL_INDEX&&R>=threshold&&(counter==3||counter==4))begin
        risk_flag=1;
    end
    else 
        risk_flag=0;
end
always_comb begin
    if(((date_ff.M<DRAM_data.M)||(date_ff.M==DRAM_data.M&&date_ff.D<DRAM_data.D))&&(cur_state==CAL_INDEX||cur_state==CAL_DATE))begin
        date_warn_flag=1;
    end
    else begin
        date_warn_flag=0;
    end
end
//============================================//
//              counter                       //
//============================================//
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        counter<=0;
    end
    else begin
        if(nxt_state!=cur_state)
            if(nxt_state==CAL_INDEX)
                case(formula_ff)
                    Formula_A,Formula_D,Formula_E:counter<=2;
                    Formula_B,Formula_C:counter<=1;
                    default:begin
                        counter<=0;
                    end
                endcase
            else begin
                counter<=0;
            end
        else 
            counter<=(counter==7)?7:counter+1;
    end
end
//============================================//
//              sorting                       //
//============================================//
logic [11:0]r[0:3],n[0:5],D[0:3],D_ff[0:3];
always_ff@( posedge clk or negedge inf.rst_n )begin
    if(!inf.rst_n)begin
        D_ff[0]<=0;
        D_ff[1]<=0;
        D_ff[2]<=0;
        D_ff[3]<=0;
    end
    else begin
        D_ff[0]<=D[0];
        D_ff[1]<=D[1];
        D_ff[2]<=D[2];
        D_ff[3]<=D[3];
    end
end
always_comb begin:sort
    if(r[0]>=r[1])begin
        n[0]=r[0];
        n[1]=r[1];
    end
    else begin
        n[0]=r[1];
        n[1]=r[0];
    end
    if(r[2]>=r[3])begin
        n[2]=r[2];
        n[3]=r[3];
    end
    else begin
        n[2]=r[3];
        n[3]=r[2];
    end
    if(n[1]>=n[2])begin
        n[4]=n[1];
        n[5]=n[2];
    end
    else begin
        n[4]=n[2];
        n[5]=n[1];
    end
    if(n[0]>=n[4])begin
        D[0]=n[0];
        D[1]=n[4];
    end
    else begin
        D[0]=n[4];
        D[1]=n[0];
    end
    if(n[5]>=n[3])begin
        D[2]=n[5];
        D[3]=n[3];
    end
    else begin
        D[2]=n[3];
        D[3]=n[5];
    end
end
always_comb begin
    r[0]=0;
    r[1]=0;
    r[2]=0;
    r[3]=0;
    case(formula_ff)
        Formula_B:begin
            r[0]=DRAM_data.Index_A;
            r[1]=DRAM_data.Index_B;
            r[2]=DRAM_data.Index_C;
            r[3]=DRAM_data.Index_D;
        end
        Formula_C:begin
            r[0]=DRAM_data.Index_A;
            r[1]=DRAM_data.Index_B;
            r[2]=DRAM_data.Index_C;
            r[3]=DRAM_data.Index_D;
        end
        Formula_F:begin
            r[0]=G_A;
            r[1]=G_B;
            r[2]=G_C;
            r[3]=G_D;
        end
        Formula_G:begin
            r[0]=G_A;
            r[1]=G_B;
            r[2]=G_C;
            r[3]=G_D;
        end
    endcase
end
//============================================//
//              FORMULA                       //
//============================================//
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if(!inf.rst_n)begin
        G_A<=0;
        G_B<=0;
        G_C<=0;
        G_D<=0;
    end
    else begin
        if(cur_state==CAL_INDEX)begin
            G_A<=(DRAM_data.Index_A>=index_A)?(DRAM_data.Index_A-index_A):(index_A-DRAM_data.Index_A);
            G_B<=(DRAM_data.Index_B>=index_B)?(DRAM_data.Index_B-index_B):(index_B-DRAM_data.Index_B);
            G_C<=(DRAM_data.Index_C>=index_C)?(DRAM_data.Index_C-index_C):(index_C-DRAM_data.Index_C);
            G_D<=(DRAM_data.Index_D>=index_D)?(DRAM_data.Index_D-index_D):(index_D-DRAM_data.Index_D);
        end
    end
end
always_ff @( posedge clk or negedge inf.rst_n ) begin 
    if(!inf.rst_n)begin
        R<=0;
    end
    else begin
        R<=R_nxt;
    end
end
always_comb begin
    R_nxt=R;
    //if(cur_state==CAL_INDEX)begin
        case(formula_ff)
            Formula_A:begin
                R_nxt=({2'b0,DRAM_data.Index_A}+DRAM_data.Index_B+DRAM_data.Index_C+DRAM_data.Index_D)>>2;
            end
            Formula_B:begin
                R_nxt=D_ff[0]-D_ff[3];
            end
            Formula_C:begin
                R_nxt=D_ff[3];
            end
            Formula_D:begin
                R_nxt=(DRAM_data.Index_A>=2047)+(DRAM_data.Index_B>=2047)+(DRAM_data.Index_C>=2047)+(DRAM_data.Index_D>=2047);
            end
            Formula_E:begin
                R_nxt=(DRAM_data.Index_A>=index_A)+(DRAM_data.Index_B>=index_B)+(DRAM_data.Index_C>=index_C)+(DRAM_data.Index_D>=index_D);
            end
            Formula_F:begin
                R_nxt=temp;
            end
            Formula_G:begin
                R_nxt=(D_ff[3]>>1)+(D_ff[2]>>2)+(D_ff[1]>>2);
            end
            Formula_H:begin
                R_nxt=({3'b0,G_A}+G_B+G_C+G_D)>>2;
            end

        endcase
    //end
end
always_comb begin
    sum3={D_ff[3]}+D_ff[2]+D_ff[1];
end
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)begin
        temp<=0;
    end
    else begin
        case(threshold)
            200:begin
                if(sum3>=600)begin
                    temp<=200;
                end
                else begin
                    temp<=0;
                end
            end
            400:begin
                if(sum3>=1200)begin
                    temp<=400;
                end
                else begin
                    temp<=0;
                end
            end
            800:begin
                if(sum3>=2400)begin
                    temp<=800;
                end
                else begin
                    temp<=0;
                end
            end
        endcase
    end
end
//============================================//
//              threshold table               //
//============================================//
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        threshold<=0;
    end
    else begin
        case({formula_ff,mode_ff})
            {Formula_A,Insensitive},{Formula_C,Insensitive}:threshold<=2047;
            {Formula_A,Normal},{Formula_C,Normal}:threshold<=1023;
            {Formula_A,Sensitive},{Formula_C,Sensitive}:threshold<=511;
            {Formula_B,Insensitive},{Formula_F,Insensitive},{Formula_G,Insensitive},{Formula_H,Insensitive}:threshold<=800;
            {Formula_B,Normal},{Formula_F,Normal},{Formula_G,Normal},{Formula_H,Normal}:threshold<=400;
            {Formula_B,Sensitive},{Formula_F,Sensitive},{Formula_G,Sensitive},{Formula_H,Sensitive}:threshold<=200;
            {Formula_D,Insensitive},{Formula_E,Insensitive}:threshold<=3;
            {Formula_D,Normal},{Formula_E,Normal}:threshold<=2;
            {Formula_D,Sensitive},{Formula_E,Sensitive}:threshold<=1;
        endcase
    end
    //if(cur_state==CAL_INDEX)begin
        
    //end
    //else begin
        //threshold=0;
    //end
end


//============================================//
//              OUTPUT                        //
//============================================//
always_comb begin
    if(nxt_state==OUT)begin
        out_valid_comb=1;
    end
    else begin
        out_valid_comb=0;
    end
end
always_comb begin
    if(date_warn_flag)begin
        warn_comb=Date_Warn;
        complete_comb=0;
    end
    else if(data_warn_flag)begin
        warn_comb=Data_Warn;
        complete_comb=0;
    end
    else if(risk_flag)begin
        warn_comb=Risk_Warn;
        complete_comb=0;
    end
    else begin
        warn_comb=No_Warn;
        complete_comb=1;
    end
end
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)begin
        inf.out_valid<=0;
    end
    else begin
        inf.out_valid<=out_valid_comb;
    end
end
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)begin
        inf.complete<=0;
    end
    else begin
        if(nxt_state==OUT)begin
            inf.complete<=complete_comb;
        end
        else begin
            inf.complete<=0;
        end
    end
end
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)begin
        inf.warn_msg<=No_Warn;
    end
    else begin
        if(nxt_state==OUT)begin
            inf.warn_msg<=warn_comb;
        end
        else begin
            inf.warn_msg<=No_Warn;
        end
    end
end
endmodule
