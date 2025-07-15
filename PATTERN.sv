
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE=1000;
parameter CYCLE = `CYCLE_TIME;
parameter PAT_NUM = 6300;
parameter SEED = 5487;
integer i_pat,i,j,latency,total_latency,out_num;
//================================================================
// wire & registers 
//================================================================
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[9*8:1]  reset_color       = "\033[1;0m";
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];
Action input_action;
Mode input_mode;
Formula_Type input_formula;
Date input_date;
Index input_index_A,input_index_B,input_index_C,input_index_D;
Data_No input_data_no;
Warn_Msg golden_warn;
logic golden_complete;
logic [11:0]golden_R,golden_threshold;
logic [11:0]golden_G_A,golden_G_B,golden_G_C,golden_G_D;
logic [31:0]sorted_I_A,sorted_I_B,sorted_I_C,sorted_I_D;
logic [31:0]sorted_G_A,sorted_G_B,sorted_G_C,sorted_G_D;
logic [31:0]temp[0:3];
//DRAM's data
Index D_index_A,D_index_B,D_index_C,D_index_D,D_index_A_update,D_index_B_update,D_index_C_update,D_index_D_update;
Date D_date,D_date_update;
//================================================================
// random data
//================================================================
class random_action;
    rand Action action_rand;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        action_rand inside{Index_Check,Update,Check_Valid_Date};
    }
endclass
class random_formula;
    randc Formula_Type formula_rand;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        formula_rand inside{Formula_A,Formula_B,Formula_C,Formula_D,Formula_E,Formula_F,Formula_G,Formula_H};
    }
endclass
class random_mode;
    randc Mode mode_rand;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        mode_rand inside{Insensitive,Normal,Sensitive};
    }
endclass
class random_date;
    randc Date date_rand;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        date_rand.M inside{[1:12]};
        (date_rand.M==1||date_rand.M==3||date_rand.M==5||date_rand.M==7||date_rand.M==8||date_rand.M==10||date_rand.M==12)->date_rand.D inside{[1:31]};
        (date_rand.M==4||date_rand.M==6||date_rand.M==9||date_rand.M==11)->date_rand.D inside{[1:30]};
        (date_rand.M==2)->date_rand.D inside{[1:28]};          
    }
endclass
class random_data_no;
    randc Data_No data_no_rand;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        data_no_rand inside{[0:255]};
    }
endclass
class random_index;
    randc Index index_rand;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        index_rand inside{[0:4095]};
    }
endclass

random_action action_rnd;
random_formula formula_rnd;
random_mode mode_rnd;
random_date date_rnd;
random_data_no data_no_rnd;
random_index index_rnd;
//================================================================
// MAIN
//================================================================
initial begin
    $readmemh(DRAM_p_r,golden_DRAM);
    action_rnd=new(SEED);
    formula_rnd=new(SEED);
    mode_rnd=new(SEED);
    date_rnd=new(SEED);
    data_no_rnd=new(SEED);
    index_rnd=new(SEED);
    reset_task;
    @(negedge clk);
    for(i_pat=0;i_pat<PAT_NUM;i_pat++)begin
        input_task;
        load_DRAM_data;
        cal_ans_task;
        
        wait_out_valid_task;
        check_ans_task;
        //$display("%0sPASS PATTERN NO.%4d %0sCycles: %3d%0s",txt_blue_prefix, i_pat, txt_green_prefix, latency, reset_color);
    end
    YOU_PASS_task;

end
task reset_task; 
    inf.rst_n = 1'b1;
    inf.sel_action_valid = 1'b0;
    inf.formula_valid=1'b0;
    inf.formula_valid=1'b0;
    inf.mode_valid=1'b0;
    inf.date_valid=1'b0;
    inf.data_no_valid=1'b0;
    inf.index_valid=1'b0;
    inf.D= 'bx;
    total_latency = 0;
    //force clk = 0;
    // Apply reset
    #CYCLE; inf.rst_n = 1'b0; 
    #CYCLE; inf.rst_n = 1'b1;   
    // Check initial conditions
    if (|inf.out_valid === 1 || |inf.warn_msg===1 || |inf.complete===1|| inf.AR_VALID===1|| |inf.AR_ADDR===1 || inf.R_READY===1 ||inf.AW_VALID===1|| |inf.AW_ADDR===1||inf.W_VALID===1|| |inf.W_DATA===1 ||inf.B_READY===1) begin
        //$display("                    reset fail!!!!!!!!!!!!!!!!!!               ");
        //repeat (1) #CYCLE;
        //$finish;
    end
    #CYCLE; 
	//release clk;
endtask
task input_task; begin
    
    
    
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.sel_action_valid=1'b1;
    if(i_pat<=3250)
        input_action=Index_Check;
    else begin
        i=action_rnd.randomize();
        input_action=action_rnd.action_rand;
    end
    inf.D=input_action;
    @(negedge clk)
    inf.sel_action_valid=1'b0;
    inf.D='bx;

    if(input_action==Index_Check)begin
        send_formula_task;
        send_mode_task;
        send_date_task;
        send_data_no_task;
        send_index_A_task;
        send_index_B_task;
        send_index_C_task;
        send_index_D_task;
    end
    else if(input_action==Update)begin
        send_date_task;
        send_data_no_task;
        send_index_A_task;
        send_index_B_task;
        send_index_C_task;
        send_index_D_task;
    end
    else if(input_action==Check_Valid_Date)begin
        send_date_task;
        send_data_no_task;
    end
end endtask
task send_formula_task;
    i=formula_rnd.randomize();
    input_formula=formula_rnd.formula_rand;
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.formula_valid=1'b1;
    inf.D=input_formula;
    @(negedge clk)
    inf.formula_valid=1'b0;
    inf.D='bx;
endtask
task send_mode_task;
    i=mode_rnd.randomize();
    input_mode=mode_rnd.mode_rand;
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.mode_valid=1'b1;
    inf.D=input_mode;
    @(negedge clk)
    inf.mode_valid=1'b0;
    inf.D='bx;
endtask
task send_date_task;
    i=date_rnd.randomize();
    input_date=date_rnd.date_rand;
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.date_valid=1'b1;
    inf.D=input_date;
    @(negedge clk)
    inf.date_valid=1'b0;
    inf.D='bx;
endtask
task send_data_no_task;
    i=data_no_rnd.randomize();
    input_data_no=data_no_rnd.data_no_rand;
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.data_no_valid=1'b1;
    inf.D=input_data_no;
    @(negedge clk)
    inf.data_no_valid=1'b0;
    inf.D='bx;
endtask
task send_index_A_task;
    i=index_rnd.randomize();
    input_index_A=index_rnd.index_rand;
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.index_valid=1'b1;
    inf.D=input_index_A;
    @(negedge clk)
    inf.index_valid=1'b0;
    inf.D='bx;
endtask
task send_index_B_task;
    i=index_rnd.randomize();
    input_index_B=index_rnd.index_rand;
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.index_valid=1'b1;
    inf.D=input_index_B;
    @(negedge clk)
    inf.index_valid=1'b0;
    inf.D='bx;
endtask
task send_index_C_task;
    i=index_rnd.randomize();
    input_index_C=index_rnd.index_rand;
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.index_valid=1'b1;
    inf.D=input_index_C;
    @(negedge clk)
    inf.index_valid=1'b0;
    inf.D='bx;
endtask
task send_index_D_task;
    i=index_rnd.randomize();
    input_index_D=index_rnd.index_rand;
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.index_valid=1'b1;
    inf.D=input_index_D;
    @(negedge clk)
    inf.index_valid=1'b0;
    inf.D='bx;
endtask
task load_DRAM_data;
    D_index_A  = {golden_DRAM[65536+8*input_data_no+7]     , golden_DRAM[65536+8*input_data_no+6][7:4]};
    D_index_B  = {golden_DRAM[65536+8*input_data_no+6][3:0], golden_DRAM[65536+8*input_data_no+5]};
    D_index_C  = {golden_DRAM[65536+8*input_data_no+3]     , golden_DRAM[65536+8*input_data_no+2][7:4]};
    D_index_D  = {golden_DRAM[65536+8*input_data_no+2][3:0], golden_DRAM[65536+8*input_data_no+1]};
    D_date.D   = {golden_DRAM[65536+8*input_data_no][4:0]};
    D_date.M   = {golden_DRAM[65536+8*input_data_no+4][3:0]};
endtask
task cal_ans_task;
    case(input_action)
        Index_Check:begin
            golden_G_A=(input_index_A>D_index_A)?(input_index_A-D_index_A):(D_index_A-input_index_A);
            golden_G_B=(input_index_B>D_index_B)?(input_index_B-D_index_B):(D_index_B-input_index_B);
            golden_G_C=(input_index_C>D_index_C)?(input_index_C-D_index_C):(D_index_C-input_index_C);
            golden_G_D=(input_index_D>D_index_D)?(input_index_D-D_index_D):(D_index_D-input_index_D);
            case(input_formula)
                Formula_A:begin
                    golden_R=(D_index_A+D_index_B+D_index_C+D_index_D)/4;
                end
                Formula_B:begin
                    temp[0] = D_index_A;
                    temp[1] = D_index_B;
                    temp[2] = D_index_C;
                    temp[3] = D_index_D;
                    temp.sort();
                    golden_R=temp[3]-temp[0];
                end
                Formula_C:begin
                    temp[0] = D_index_A;
                    temp[1] = D_index_B;
                    temp[2] = D_index_C;
                    temp[3] = D_index_D;
                    temp.sort();
                    golden_R=temp[0];
                end
                Formula_D:begin
                    golden_R=(D_index_A>=2047)+(D_index_B>=2047)+(D_index_C>=2047)+(D_index_D>=2047);
                end
                Formula_E:begin
                    golden_R=(D_index_A>=input_index_A)+(D_index_B>=input_index_B)+(D_index_C>=input_index_C)+(D_index_D>=input_index_D);
                end
                Formula_F:begin
                    temp[0] = golden_G_A;
                    temp[1] = golden_G_B;
                    temp[2] = golden_G_C;
                    temp[3] = golden_G_D;
                    temp.sort();
                    golden_R=(temp[0]+temp[1]+temp[2])/3;
                    
                end
                Formula_G:begin
                    temp[0] = golden_G_A;
                    temp[1] = golden_G_B;
                    temp[2] = golden_G_C;
                    temp[3] = golden_G_D;
                    temp.sort();
                    golden_R=(temp[0]/2)+(temp[1]/4)+(temp[2]/4);
                end
                Formula_H:begin
                    golden_R=(golden_G_A+golden_G_B+golden_G_C+golden_G_D)/4;
                end
            endcase
            case({input_formula,input_mode})
                {Formula_A,Insensitive},{Formula_C,Insensitive}:golden_threshold=2047;
                {Formula_A,Normal},{Formula_C,Normal}:golden_threshold=1023;
                {Formula_A,Sensitive},{Formula_C,Sensitive}:golden_threshold=511;
                {Formula_B,Insensitive},{Formula_F,Insensitive},{Formula_G,Insensitive},{Formula_H,Insensitive}:golden_threshold=800;
                {Formula_B,Normal},{Formula_F,Normal},{Formula_G,Normal},{Formula_H,Normal}:golden_threshold=400;
                {Formula_B,Sensitive},{Formula_F,Sensitive},{Formula_G,Sensitive},{Formula_H,Sensitive}:golden_threshold=200;
                {Formula_D,Insensitive},{Formula_E,Insensitive}:golden_threshold=3;
                {Formula_D,Normal},{Formula_E,Normal}:golden_threshold=2;
                {Formula_D,Sensitive},{Formula_E,Sensitive}:golden_threshold=1;
            endcase
            if(input_date.M<D_date.M||((input_date.M==D_date.M)&&(input_date.D<D_date.D)))begin
                golden_complete=0;
                golden_warn=Date_Warn;
            end
            else if(golden_R>=golden_threshold)begin
                golden_complete=0;
                golden_warn=Risk_Warn;
            end
            else begin
                golden_complete=1;
                golden_warn=No_Warn;
            end
        end
        Update:begin
            golden_complete=1;
            golden_warn=No_Warn;
            if(0>($signed({1'b0,D_index_A})+$signed(input_index_A)))begin
                D_index_A_update=0;
                golden_complete=0;
                golden_warn=Data_Warn;
            end
            else if(($signed({1'b0,D_index_A})+$signed(input_index_A))>4095)begin
                D_index_A_update=4095;
                golden_complete=0;
                golden_warn=Data_Warn;
            end
            else begin
                D_index_A_update=($signed({1'b0,D_index_A})+$signed(input_index_A));
            end
            if(0>($signed({1'b0,D_index_B})+$signed(input_index_B)))begin
                D_index_B_update=0;
                golden_complete=0;
                golden_warn=Data_Warn;
            end
            else if(($signed({1'b0,D_index_B})+$signed(input_index_B))>4095)begin
                D_index_B_update=4095;
                golden_complete=0;
                golden_warn=Data_Warn;
            end
            else begin
                D_index_B_update=($signed({1'b0,D_index_B})+$signed(input_index_B));
            end

            if(0>($signed({1'b0,D_index_C})+$signed(input_index_C)))begin
                D_index_C_update=0;
                golden_complete=0;
                golden_warn=Data_Warn;
            end
            else if(($signed({1'b0,D_index_C})+$signed(input_index_C))>4095)begin
                D_index_C_update=4095;
                golden_complete=0;
                golden_warn=Data_Warn;
            end
            else begin
                D_index_C_update=($signed({1'b0,D_index_C})+$signed(input_index_C));
            end

            if(0>($signed({1'b0,D_index_D})+$signed(input_index_D)))begin
                D_index_D_update=0;
                golden_complete=0;
                golden_warn=Data_Warn;
            end
            else if(($signed({1'b0,D_index_D})+$signed(input_index_D))>4095)begin
                D_index_D_update=4095;
                golden_complete=0;
                golden_warn=Data_Warn;
            end
            else begin
                D_index_D_update=($signed({1'b0,D_index_D})+$signed(input_index_D));
            end
            D_date_update=input_date;
            //update golden_DRAM
            golden_DRAM[65536+8*input_data_no]={3'b0,D_date_update.D};
            golden_DRAM[65536+8*input_data_no+1]={D_index_D_update[7:0]};
            golden_DRAM[65536+8*input_data_no+2]={D_index_C_update[3:0],D_index_D_update[11:8]};
            golden_DRAM[65536+8*input_data_no+3]={D_index_C_update[11:4]};
            golden_DRAM[65536+8*input_data_no+4]={4'b0,D_date_update.M};
            golden_DRAM[65536+8*input_data_no+5]={D_index_B_update[7:0]};
            golden_DRAM[65536+8*input_data_no+6]={D_index_A_update[3:0],D_index_B_update[11:8]};
            golden_DRAM[65536+8*input_data_no+7]={D_index_A_update[11:4]};
        end
        Check_Valid_Date:begin
            if(input_date.M<D_date.M||((input_date.M==D_date.M)&&(input_date.D<D_date.D)))begin
                golden_complete=0;
                golden_warn=Date_Warn;
            end
            else begin
                golden_complete=1;
                golden_warn=No_Warn;
            end
        end
    endcase
endtask
task wait_out_valid_task; begin
    latency =0;
    while (inf.out_valid === 0) begin
        latency = latency + 1;
        if (latency == (1000*CYCLE)) begin
            //$display("                   OUT_VALID should be 1 after 1000cycle!!!!!!                 ");
            //repeat (2) @(negedge clk);
            //$finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask
task check_ans_task; begin
    // Initialize output count
    //out_num = 1;
    
    // Only perform checks when out_valid is high
    while (inf.out_valid === 1) begin
        if(golden_complete!=inf.complete||golden_warn!=inf.warn_msg)begin
            //$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            //$display ("                                                                       FAIL!                                                                ");
            //$display ("                                                                    pattern %d                                                              ",i_pat);
            //$display ("                                           Your complete and warn is   : %d,%d                                                              ",inf.complete,inf.warn_msg);
            //$display ("                                           ans should be : %d,%d                                                                            ",golden_complete,golden_warn);
            //$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("Wrong Answer");
            @(negedge clk);
            $finish;
        end
        //if(out_num > 1) begin
            //$display("                    out should be high for 1cycle                   ");
            //repeat(1) @(negedge clk);
            //$finish;
        //end
        else begin
            @(negedge clk);
            //out_num = out_num + 1;
        end
        
    end   
end endtask
task YOU_PASS_task; begin
    $display("Congratulations");
    $finish;
end endtask
//=======================================================
// SPEC
//=======================================================

endprogram
