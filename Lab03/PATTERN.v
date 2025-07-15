/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: PATTERN
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define CYCLE_TIME 3.5
`endif
`ifdef GATE
    `define CYCLE_TIME 3.5
`endif

module PATTERN(
	//OUTPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//INPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg			rst_n, clk, in_valid;
output reg	[2:0]	tetrominoes;
output reg  [2:0]	position;
input 				tetris_valid, score_valid, fail;
input 		[3:0]	score;
input		[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------

/* Parameters and Integers */
integer tetris_correct;
integer patnum;
integer i_pat, a, finish_flag, round_num,pattern_num,out_num;
integer f_in,i;
integer latency;
integer total_latency;
integer score_gold;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg  tetris_test[0:15][0:5],tetris_gold[0:15][0:5];
reg  [2:0]	current_tetrominoes,tetrominoes_notcare;
reg  [2:0]	current_position,position_notcare;

reg fail_gold;
reg [4:0] offset[0:5];
//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------
always @(negedge clk) begin
        if ( (tetris_valid===0 && |tetris===1)||(score_valid===0&&|score===1)||(score_valid===0 && |tetris_valid===1)||(score_valid===0 && |fail===1)) begin
            $display("                    SPEC-5 FAIL                   ");
            $finish;            
        end    
    end
initial begin
    // Open input and output files
    f_in  = $fopen("../00_TESTBED/input.txt", "r");
    // f_in  = $fopen("../00_TESTBED/input_v2.txt", "r");
    if (f_in == 0) begin
        $display("Failed to open input.txt");
        $finish;
    end
    // Initialize signals
    reset_task;
	a = $fscanf(f_in, "%d", patnum);
    // Iterate through each pattern
    for (i_pat = 0; i_pat < patnum; i_pat = i_pat + 1) begin
		finish_flag = 0;
		round_num=0;
        for(i=0;i<=15;i=i+1)begin
            for(int j=0;j<=5;j=j+1)begin
                tetris_gold[i][j]=0;
            end
        end
		fail_gold=0;
		score_gold=0;
		a = $fscanf(f_in, "%d", pattern_num);
        @(negedge clk);
        @(negedge clk);
		while((fail_gold==0)&&(round_num!=16))begin
			input_task;
			wait_out_valid_task;
			check_ans_task;
			round_num+=1;
		end        
		for(i=0;i<16-round_num;i=i+1)begin
			a = $fscanf(f_in, "%d", tetrominoes_notcare);
			a = $fscanf(f_in, "%d", position_notcare);
		end
    end
    
    $display("                  Congratulations!               ");
    $display("              execution cycles = %7d", total_latency);
    $display("              clock period = %4fns", CYCLE);
    $finish;
    //YOU_PASS_task;
end


task reset_task; 
    rst_n = 1'b1;
    in_valid = 1'b0;
    tetrominoes = 2'bxx;
    position = 2'bxx;
    total_latency = 0;
    force clk = 0;
    // Apply reset
    #CYCLE; rst_n = 1'b0; 
    #CYCLE; rst_n = 1'b1;
	#(100-CYCLE);    
    // Check initial conditions
    if (tetris_valid !== 1'b0 || score_valid !== 1'b0 || fail !== 1'b0 || score !== 4'b0000 || tetris!== 72'b0) begin
        $display("                    SPEC-4 FAIL                   ");
        repeat (2) #CYCLE;
        $finish;
    end
    #CYCLE; 
	release clk;
endtask
// Task to handle input
task input_task; begin
    
   
    in_valid=1'b1;
    a = $fscanf(f_in, "%d", current_tetrominoes);
    a = $fscanf(f_in, "%d", current_position);
	tetrominoes = current_tetrominoes;
	position = current_position;
    latency = 1;
	@(negedge clk); 	
	cal_gold_task;
	in_valid=1'b0;
	tetrominoes = 3'bxxx;
	position = 3'bxxx;
end endtask
task wait_out_valid_task; begin
    while (score_valid !== 1'b1) begin
        latency = latency + 1;
        if (latency == 1000) begin
            $display("                    SPEC-6 FAIL                   ");
            repeat (2) @(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task cal_gold_task;begin
	for(int k=0;k<=5;k++)begin
        offset[k]=0;
    end
    for(int row=0;row<=11;row=row+1)begin
        for(int k=0;k<=5;k++)begin
            if(tetris_gold[row][k]==1)begin
                offset[k]=row+1;
            end
        end
    end
	if(current_tetrominoes==0)begin
        if(offset[current_position]>offset[current_position+1])begin
            tetris_gold[offset[current_position]][current_position]=1;
            tetris_gold[offset[current_position]][current_position+1]=1;
            tetris_gold[offset[current_position]+1][current_position]=1;
            tetris_gold[offset[current_position]+1][current_position+1]=1;
        end
        else begin
            tetris_gold[offset[current_position+1]][current_position+1]=1;
            tetris_gold[offset[current_position+1]][current_position]=1;
            tetris_gold[offset[current_position+1]+1][current_position]=1;
            tetris_gold[offset[current_position+1]+1][current_position+1]=1;
        end
        //clean line
        for(int row=11;row>=0;row=row-1)begin            
            if((tetris_gold[row][0]==tetris_gold[row][1])&&(tetris_gold[row][1]==tetris_gold[row][2])&&(tetris_gold[row][2]==tetris_gold[row][3])&&(tetris_gold[row][3]==tetris_gold[row][4])&&(tetris_gold[row][4]==tetris_gold[row][5])&&(tetris_gold[row][0]==1))begin
                score_gold=score_gold+1;
                for(int shift_row=row;shift_row<=13;shift_row=shift_row+1)begin
                    for(int shift_col=0;shift_col<=5;shift_col=shift_col+1)begin
                        tetris_gold[shift_row][shift_col]=tetris_gold[shift_row+1][shift_col];
                    end
                end
            end
        end
        //check fail or not
        for(int exceed_row=12;exceed_row<=15;exceed_row=exceed_row+1)begin
            if(tetris_gold[exceed_row][0]==1||tetris_gold[exceed_row][1]==1||tetris_gold[exceed_row][2]==1||tetris_gold[exceed_row][3]==1||tetris_gold[exceed_row][4]==1||tetris_gold[exceed_row][5]==1)begin
                fail_gold=1;
            end
        end
    end
	else if(current_tetrominoes==1)begin
        tetris_gold[offset[current_position]][current_position]=1;
        tetris_gold[offset[current_position]+1][current_position]=1;
        tetris_gold[offset[current_position]+2][current_position]=1;
        tetris_gold[offset[current_position]+3][current_position]=1;
        //clean line
        for(int row=11;row>=0;row=row-1)begin
            if((tetris_gold[row][0]==tetris_gold[row][1])&&(tetris_gold[row][1]==tetris_gold[row][2])&&(tetris_gold[row][2]==tetris_gold[row][3])&&(tetris_gold[row][3]==tetris_gold[row][4])&&(tetris_gold[row][4]==tetris_gold[row][5])&&(tetris_gold[row][0]==1))begin
                score_gold=score_gold+1;
                for(int shift_row=row;shift_row<=13;shift_row=shift_row+1)begin
                    for(int shift_col=0;shift_col<=5;shift_col=shift_col+1)begin
                        tetris_gold[shift_row][shift_col]=tetris_gold[shift_row+1][shift_col];
                    end
                end
            end
        end
        //check fail or not
        for(int exceed_row=12;exceed_row<=15;exceed_row=exceed_row+1)begin
            if(tetris_gold[exceed_row][0]==1||tetris_gold[exceed_row][1]==1||tetris_gold[exceed_row][2]==1||tetris_gold[exceed_row][3]==1||tetris_gold[exceed_row][4]==1||tetris_gold[exceed_row][5]==1)begin
                fail_gold=1;
            end
        end
    end
    else if(current_tetrominoes==2)begin
        if(offset[current_position]>=offset[current_position+1]&&offset[current_position]>=offset[current_position+2]&&offset[current_position]>=offset[current_position+3])begin
            tetris_gold[offset[current_position]][current_position]=1;
            tetris_gold[offset[current_position]][current_position+1]=1;
            tetris_gold[offset[current_position]][current_position+2]=1;
            tetris_gold[offset[current_position]][current_position+3]=1;
        end
        else if(offset[current_position+1]>=offset[current_position]&&offset[current_position+1]>=offset[current_position+2]&&offset[current_position+1]>=offset[current_position+3])begin
            tetris_gold[offset[current_position+1]][current_position]=1;
            tetris_gold[offset[current_position+1]][current_position+1]=1;
            tetris_gold[offset[current_position+1]][current_position+2]=1;
            tetris_gold[offset[current_position+1]][current_position+3]=1;
        end
        else if(offset[current_position+2]>=offset[current_position]&&offset[current_position+2]>=offset[current_position+1]&&offset[current_position+2]>=offset[current_position+3])begin
            tetris_gold[offset[current_position+2]][current_position]=1;
            tetris_gold[offset[current_position+2]][current_position+1]=1;
            tetris_gold[offset[current_position+2]][current_position+2]=1;
            tetris_gold[offset[current_position+2]][current_position+3]=1;
        end
        else begin
            tetris_gold[offset[current_position+3]][current_position]=1;
            tetris_gold[offset[current_position+3]][current_position+1]=1;
            tetris_gold[offset[current_position+3]][current_position+2]=1;
            tetris_gold[offset[current_position+3]][current_position+3]=1;
        end
        //clean line
        for(int row=11;row>=0;row=row-1)begin
            if((tetris_gold[row][0]==tetris_gold[row][1])&&(tetris_gold[row][1]==tetris_gold[row][2])&&(tetris_gold[row][2]==tetris_gold[row][3])&&(tetris_gold[row][3]==tetris_gold[row][4])&&(tetris_gold[row][4]==tetris_gold[row][5])&&(tetris_gold[row][0]==1))begin
                score_gold=score_gold+1;
                for(int shift_row=row;shift_row<=13;shift_row=shift_row+1)begin
                    for(int shift_col=0;shift_col<=5;shift_col=shift_col+1)begin
                        tetris_gold[shift_row][shift_col]=tetris_gold[shift_row+1][shift_col];
                    end
                end
            end
        end
        //check fail or not
        for(int exceed_row=12;exceed_row<=15;exceed_row=exceed_row+1)begin
            if(tetris_gold[exceed_row][0]==1||tetris_gold[exceed_row][1]==1||tetris_gold[exceed_row][2]==1||tetris_gold[exceed_row][3]==1||tetris_gold[exceed_row][4]==1||tetris_gold[exceed_row][5]==1)begin
                fail_gold=1;
            end
        end
    end
    else if(current_tetrominoes==3)begin
        if(offset[current_position]>=offset[current_position+1]+2)begin
            tetris_gold[offset[current_position]][current_position]=1;
            tetris_gold[offset[current_position]][current_position+1]=1;
            tetris_gold[offset[current_position]-1][current_position+1]=1;
            tetris_gold[offset[current_position]-2][current_position+1]=1;
        end
        else begin
            tetris_gold[offset[current_position+1]][current_position+1]=1;
            tetris_gold[offset[current_position+1]+1][current_position+1]=1;
            tetris_gold[offset[current_position+1]+2][current_position+1]=1;
            tetris_gold[offset[current_position+1]+2][current_position]=1;
        end
        //clean line
        for(int row=11;row>=0;row=row-1)begin
            if((tetris_gold[row][0]==tetris_gold[row][1])&&(tetris_gold[row][1]==tetris_gold[row][2])&&(tetris_gold[row][2]==tetris_gold[row][3])&&(tetris_gold[row][3]==tetris_gold[row][4])&&(tetris_gold[row][4]==tetris_gold[row][5])&&(tetris_gold[row][0]==1))begin
                score_gold=score_gold+1;
                for(int shift_row=row;shift_row<=13;shift_row=shift_row+1)begin
                    for(int shift_col=0;shift_col<=5;shift_col=shift_col+1)begin
                        tetris_gold[shift_row][shift_col]=tetris_gold[shift_row+1][shift_col];
                    end
                end
            end
        end
        //check fail or not
        for(int exceed_row=12;exceed_row<=15;exceed_row=exceed_row+1)begin
            if(tetris_gold[exceed_row][0]==1||tetris_gold[exceed_row][1]==1||tetris_gold[exceed_row][2]==1||tetris_gold[exceed_row][3]==1||tetris_gold[exceed_row][4]==1||tetris_gold[exceed_row][5]==1)begin
                fail_gold=1;
            end
        end
    end
    else if(current_tetrominoes==4)begin
        if(offset[current_position+1]>=offset[current_position]+1&&offset[current_position+1]>=offset[current_position+2])begin
            tetris_gold[offset[current_position+1]][current_position+1]=1;
            tetris_gold[offset[current_position+1]][current_position+2]=1;
            tetris_gold[offset[current_position+1]][current_position]=1;
            tetris_gold[offset[current_position+1]-1][current_position]=1;
        end
        else if(offset[current_position+2]>=offset[current_position]+1&&offset[current_position+2]>=offset[current_position+1])begin
            tetris_gold[offset[current_position+2]][current_position+1]=1;
            tetris_gold[offset[current_position+2]][current_position+2]=1;
            tetris_gold[offset[current_position+2]][current_position]=1;
            tetris_gold[offset[current_position+2]-1][current_position]=1;
        end
        else begin
            tetris_gold[offset[current_position]][current_position]=1;
            tetris_gold[offset[current_position]+1][current_position]=1;
            tetris_gold[offset[current_position]+1][current_position+1]=1;
            tetris_gold[offset[current_position]+1][current_position+2]=1;
        end
        //clean line
        for(int row=11;row>=0;row=row-1)begin
            if((tetris_gold[row][0]==tetris_gold[row][1])&&(tetris_gold[row][1]==tetris_gold[row][2])&&(tetris_gold[row][2]==tetris_gold[row][3])&&(tetris_gold[row][3]==tetris_gold[row][4])&&(tetris_gold[row][4]==tetris_gold[row][5])&&(tetris_gold[row][0]==1))begin
                score_gold=score_gold+1;
                for(int shift_row=row;shift_row<=13;shift_row=shift_row+1)begin
                    for(int shift_col=0;shift_col<=5;shift_col=shift_col+1)begin
                        tetris_gold[shift_row][shift_col]=tetris_gold[shift_row+1][shift_col];
                    end
                end
            end
        end
        //check fail or not
        for(int exceed_row=12;exceed_row<=15;exceed_row=exceed_row+1)begin
            if(tetris_gold[exceed_row][0]==1||tetris_gold[exceed_row][1]==1||tetris_gold[exceed_row][2]==1||tetris_gold[exceed_row][3]==1||tetris_gold[exceed_row][4]==1||tetris_gold[exceed_row][5]==1)begin
                fail_gold=1;
            end
        end
    end
    else if(current_tetrominoes==5)begin
        if(offset[current_position]>=offset[current_position+1])begin
            tetris_gold[offset[current_position]][current_position]=1;
            tetris_gold[offset[current_position]][current_position+1]=1;
            tetris_gold[offset[current_position]+1][current_position]=1;
            tetris_gold[offset[current_position]+2][current_position]=1;
        end
        else begin
            tetris_gold[offset[current_position+1]][current_position]=1;
            tetris_gold[offset[current_position+1]][current_position+1]=1;
            tetris_gold[offset[current_position+1]+1][current_position]=1;
            tetris_gold[offset[current_position+1]+2][current_position]=1;
        end
        //clean line
        for(int row=11;row>=0;row=row-1)begin
            
            if((tetris_gold[row][0]==tetris_gold[row][1])&&(tetris_gold[row][1]==tetris_gold[row][2])&&(tetris_gold[row][2]==tetris_gold[row][3])&&(tetris_gold[row][3]==tetris_gold[row][4])&&(tetris_gold[row][4]==tetris_gold[row][5])&&(tetris_gold[row][0]==1))begin
                score_gold=score_gold+1;
                for(int shift_row=row;shift_row<=13;shift_row=shift_row+1)begin
                    for(int shift_col=0;shift_col<=5;shift_col=shift_col+1)begin
                        tetris_gold[shift_row][shift_col]=tetris_gold[shift_row+1][shift_col];
                    end
                end
            end
        end
        //check fail or not
        for(int exceed_row=12;exceed_row<=15;exceed_row=exceed_row+1)begin
            if(tetris_gold[exceed_row][0]==1||tetris_gold[exceed_row][1]==1||tetris_gold[exceed_row][2]==1||tetris_gold[exceed_row][3]==1||tetris_gold[exceed_row][4]==1||tetris_gold[exceed_row][5]==1)begin
                fail_gold=1;
            end
        end
    end
    else if(current_tetrominoes==6)begin
        if(offset[current_position]>=offset[current_position+1]+1)begin
            tetris_gold[offset[current_position]][current_position]=1;
            tetris_gold[offset[current_position]+1][current_position]=1;
            tetris_gold[offset[current_position]][current_position+1]=1;
            tetris_gold[offset[current_position]-1][current_position+1]=1;
        end
        else begin
            tetris_gold[offset[current_position+1]][current_position+1]=1;
            tetris_gold[offset[current_position+1]+1][current_position+1]=1;
            tetris_gold[offset[current_position+1]+1][current_position]=1;
            tetris_gold[offset[current_position+1]+2][current_position]=1;
        end
        //clean line
        for(int row=11;row>=0;row=row-1)begin
            
            if((tetris_gold[row][0]==tetris_gold[row][1])&&(tetris_gold[row][1]==tetris_gold[row][2])&&(tetris_gold[row][2]==tetris_gold[row][3])&&(tetris_gold[row][3]==tetris_gold[row][4])&&(tetris_gold[row][4]==tetris_gold[row][5])&&(tetris_gold[row][0]==1))begin
                score_gold=score_gold+1;
                for(int shift_row=row;shift_row<=13;shift_row=shift_row+1)begin
                    for(int shift_col=0;shift_col<=5;shift_col=shift_col+1)begin
                        tetris_gold[shift_row][shift_col]=tetris_gold[shift_row+1][shift_col];
                    end
                end
            end
        end
        //check fail or not
        for(int exceed_row=12;exceed_row<=15;exceed_row=exceed_row+1)begin
            if(tetris_gold[exceed_row][0]==1||tetris_gold[exceed_row][1]==1||tetris_gold[exceed_row][2]==1||tetris_gold[exceed_row][3]==1||tetris_gold[exceed_row][4]==1||tetris_gold[exceed_row][5]==1)begin
                fail_gold=1;
            end
        end
    end
    else if(current_tetrominoes==7)begin
        if(offset[current_position+2]>=(offset[current_position+1]+1)&&offset[current_position+2]>=offset[current_position]+1)begin
            tetris_gold[offset[current_position+2]][current_position+2]=1;
            tetris_gold[offset[current_position+2]][current_position+1]=1;
            tetris_gold[offset[current_position+2]-1][current_position+1]=1;
            tetris_gold[offset[current_position+2]-1][current_position]=1;
        end
        else if(offset[current_position+1]>=offset[current_position])begin
            tetris_gold[offset[current_position+1]][current_position+1]=1;
            tetris_gold[offset[current_position+1]][current_position]=1;
            tetris_gold[offset[current_position+1]+1][current_position+1]=1;
            tetris_gold[offset[current_position+1]+1][current_position+2]=1;
        end
        else begin
            tetris_gold[offset[current_position]][current_position+1]=1;
            tetris_gold[offset[current_position]][current_position]=1;
            tetris_gold[offset[current_position]+1][current_position+1]=1;
            tetris_gold[offset[current_position]+1][current_position+2]=1;
        end
        //clean line
        for(int row=11;row>=0;row=row-1)begin
            
            if((tetris_gold[row][0]==tetris_gold[row][1])&&(tetris_gold[row][1]==tetris_gold[row][2])&&(tetris_gold[row][2]==tetris_gold[row][3])&&(tetris_gold[row][3]==tetris_gold[row][4])&&(tetris_gold[row][4]==tetris_gold[row][5])&&(tetris_gold[row][0]==1))begin
                score_gold=score_gold+1;
                for(int shift_row=row;shift_row<=13;shift_row=shift_row+1)begin
                    for(int shift_col=0;shift_col<=5;shift_col=shift_col+1)begin
                        tetris_gold[shift_row][shift_col]=tetris_gold[shift_row+1][shift_col];
                    end
                end
            end
        end
        //check fail or not
        for(int exceed_row=12;exceed_row<=15;exceed_row=exceed_row+1)begin
            if(tetris_gold[exceed_row][0]==1||tetris_gold[exceed_row][1]==1||tetris_gold[exceed_row][2]==1||tetris_gold[exceed_row][3]==1||tetris_gold[exceed_row][4]==1||tetris_gold[exceed_row][5]==1)begin
                fail_gold=1;
            end
        end
    end
end
endtask


task check_ans_task; begin
    // Initialize output count
    out_num = 1;
    
    // Only perform checks when out_valid is high
    while (score_valid === 1) begin
        // Compare expected and received values
        tetris_correct=1;
        if(out_num > 1) begin
            $display("                    SPEC-8 FAIL                   ");
            repeat(9) @(negedge clk);
            $finish;
        end
        if(fail_gold==1||round_num==15)begin
            for(int k=0;k<=11;k=k+1)begin
                for(int j=0;j<=5;j=j+1)begin
                    if(tetris_gold[k][j]!=tetris[k*6+j])begin
                        tetris_correct=0;
                        $display("                    SPEC-7 FAIL                   ");
                        repeat (9) @(negedge clk);
                        $finish;
                    end
                end
            end
            if(tetris_valid!==1||score!==score_gold||fail!==fail_gold)begin
                $display("                    SPEC-7 FAIL                   ");
                repeat (9) @(negedge clk);
                $finish;
            end
            else begin
                @(negedge clk);
                out_num = out_num + 1;
            end
        end
        else if(fail_gold!==1&&round_num!==15)begin
            if(tetris_valid!==0||score!==score_gold||fail!==fail_gold)begin
                $display("                    SPEC-7 FAIL                   ");
                repeat (9) @(negedge clk);
                $finish;
            end
            else begin
                @(negedge clk);
                out_num = out_num + 1;
            end
        end
        else begin
                @(negedge clk);
                out_num = out_num + 1;
            end
        // Check if the number of outputs matches the expected count
        
    end
    
end endtask


endmodule
// for spec check
// $display("                    SPEC-4 FAIL                   ");
// $display("                    SPEC-5 FAIL                   ");
// $display("                    SPEC-6 FAIL                   ");
// $display("                    SPEC-7 FAIL                   ");
// $display("                    SPEC-8 FAIL                   ");
// for successful design
// $display("                  Congratulations!               ");
// $display("              execution cycles = %7d", total_latency);
// $display("              clock period = %4fns", CYCLE);