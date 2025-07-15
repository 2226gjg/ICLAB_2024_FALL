`ifdef RTL
    `define CYCLE_TIME 6.0
`endif
`ifdef GATE
    `define CYCLE_TIME 6.0
`endif

module PATTERN(
    // Output signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Input signals
    out_valid, 
	out_data
);

// ========================================
// Input & Output
// ========================================
output reg clk, rst_n, in_valid;
output reg [8:0] in_mode;
output reg [14:0] in_data;

input out_valid;
input [206:0] out_data;
//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------

/* Parameters and Integers */
integer patnum;
integer i_pat, a,pattern_num;
integer f_input_data,f_img_data,f_input_size,f_size_data,i,j;
integer latency;
integer total_latency;
integer out_num;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg signed[206:0]gold_out;
reg signed [10:0]img[0:3][0:3];
reg signed[22:0]out2[0:8];
reg signed[50:0]out3[0:3];
reg signed[206:0]out4;
reg [4:0]mode;
//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

always @(negedge clk) begin
    if ( (in_valid===1 && |out_data===1)||(in_valid===1&& out_valid===1)) begin
        $display("                    in out overlap  FAIL                   ");
        $finish;            
    end    
end
always @(negedge clk) begin
    if ( (out_valid===0 && |out_data===1)) begin
        $display("                    out_valid=0 but out_data!=0  FAIL                   ");
        $finish;            
    end    
end
initial begin
    $display("                    START!!!!!!!!!!!!!!                   ");
    // Open input and output files
    f_input_data  = $fopen("../00_TESTBED/input_data.txt", "r");
    f_img_data  = $fopen("../00_TESTBED/img_data.txt", "r");
    f_input_size  = $fopen("../00_TESTBED/input_size.txt", "r");
    f_size_data = $fopen("../00_TESTBED/size_data.txt", "r");
    
    // Initialize signals
    reset_task;
	a = $fscanf(f_input_data, "%d", patnum);
    // Iterate through each pattern
    for (i_pat = 0; i_pat < patnum; i_pat = i_pat + 1) begin
		a = $fscanf(f_input_data, "%d", pattern_num);
        a = $fscanf(f_img_data, "%d", pattern_num);
        a = $fscanf(f_input_size, "%d", pattern_num);
        a = $fscanf(f_size_data, "%d", pattern_num);
        @(negedge clk);
        @(negedge clk);
        input_task;
        cal_ans_task;
        wait_out_valid_task;
        check_ans_task;
        $display ("Pass pattern%d",i_pat);
    end
    YOU_PASS_task;
end
task reset_task; 
    rst_n = 1'b1;
    in_valid = 1'b0;
    in_mode= 'bx;
    in_data= 'bx;
    total_latency = 0;
    force clk = 0;
    // Apply reset
    #CYCLE; rst_n = 1'b0; 
    #CYCLE; #CYCLE; #CYCLE; rst_n = 1'b1;   
    // Check initial conditions
    if (|out_valid === 1 || |out_data===1) begin
        $display("                    reset fail!!!!!!!!!!!!!!!!!!               ");
        repeat (2) #CYCLE;
        $finish;
    end
    #CYCLE; 
	release clk;
endtask
task input_task; begin
    @(negedge clk);
    in_valid=1'b1;
    for(i=0;i<=15;i=i+1)begin
        a = $fscanf(f_input_data, "%b", in_data);
        if(i==0)
            a = $fscanf(f_input_size, "%b", in_mode);
        else 
            in_mode=0;
        @(negedge clk);
    end
    in_valid=1'b0;
    in_mode='bx;
    in_data='bx;
end endtask
// Function to calculate determinant of 3x3 matrix
function signed [50:0] det3x3(
    input signed [10:0] a11, a12, a13,
    input signed [10:0] a21, a22, a23,
    input signed [10:0] a31, a32, a33
);
    begin
        det3x3 = a11 * (a22 * a33 - a23 * a32) - 
                 a12 * (a21 * a33 - a23 * a31) + 
                 a13 * (a21 * a32 - a22 * a31);
    end
endfunction
// Function to calculate determinant of 4x4 matrix
function signed [206:0] det4x4(
    input signed [10:0] img [0:3][0:3]
);
    begin
        det4x4 = img[0][0] * det3x3(img[1][1], img[1][2], img[1][3], 
                                    img[2][1], img[2][2], img[2][3], 
                                    img[3][1], img[3][2], img[3][3])
               - img[0][1] * det3x3(img[1][0], img[1][2], img[1][3], 
                                    img[2][0], img[2][2], img[2][3], 
                                    img[3][0], img[3][2], img[3][3])
               + img[0][2] * det3x3(img[1][0], img[1][1], img[1][3], 
                                    img[2][0], img[2][1], img[2][3], 
                                    img[3][0], img[3][1], img[3][3])
               - img[0][3] * det3x3(img[1][0], img[1][1], img[1][2], 
                                    img[2][0], img[2][1], img[2][2], 
                                    img[3][0], img[3][1], img[3][2]);
    end
endfunction
task cal_ans_task;begin
    for(i=0;i<=3;i=i+1)begin
        for(j=0;j<=3;j=j+1)begin
            a= $fscanf(f_img_data, "%b", img[i][j]);
        end
    end
    a= $fscanf(f_size_data, "%b", mode);
    out2[0]=img[0][0]*img[1][1]-img[1][0]*img[0][1];
    out2[1]=img[0][1]*img[1][2]-img[0][2]*img[1][1];
    out2[2]=img[0][2]*img[1][3]-img[0][3]*img[1][2];
    out2[3]=img[1][0]*img[2][1]-img[1][1]*img[2][0];
    out2[4]=img[1][1]*img[2][2]-img[1][2]*img[2][1];
    out2[5]=img[1][2]*img[2][3]-img[1][3]*img[2][2];
    out2[6]=img[2][0]*img[3][1]-img[2][1]*img[3][0];
    out2[7]=img[2][1]*img[3][2]-img[2][2]*img[3][1];
    out2[8]=img[2][2]*img[3][3]-img[2][3]*img[3][2];

    out3[0]=(img[0][0]*img[1][1]*img[2][2])+(img[0][1]*img[1][2]*img[2][0])+(img[0][2]*img[2][1]*img[1][0])-(img[0][2]*img[1][1]*img[2][0])-(img[0][0]*img[2][1]*img[1][2])-(img[0][1]*img[1][0]*img[2][2]);
    out3[1]=(img[0][1]*img[1][2]*img[2][3])+(img[0][2]*img[1][3]*img[2][1])+(img[0][3]*img[2][2]*img[1][1])-(img[0][3]*img[1][2]*img[2][1])-(img[0][1]*img[2][2]*img[1][3])-(img[0][2]*img[1][1]*img[2][3]);
    out3[2]=(img[1][0]*img[2][1]*img[3][2])+(img[1][1]*img[2][2]*img[3][0])+(img[1][2]*img[3][1]*img[2][0])-(img[1][2]*img[2][1]*img[3][0])-(img[1][0]*img[3][1]*img[2][2])-(img[1][1]*img[2][0]*img[3][2]);
    out3[3]=(img[1][1]*img[2][2]*img[3][3])+(img[1][2]*img[2][3]*img[3][1])+(img[1][3]*img[3][2]*img[2][1])-(img[1][3]*img[2][2]*img[3][1])-(img[1][1]*img[3][2]*img[2][3])-(img[1][2]*img[2][1]*img[3][3]);

    out4=det4x4(img);

    if(mode==5'b00100)begin
        gold_out={out2[0],out2[1],out2[2],out2[3],out2[4],out2[5],out2[6],out2[7],out2[8]};
    end
    else if(mode==5'b00110)begin
        gold_out={3'b000,out3[0],out3[1],out3[2],out3[3]};
    end
    else if(mode==5'b10110)begin
        gold_out=out4;
    end
end endtask
task wait_out_valid_task; begin
    latency =0;
    while (out_valid === 0) begin
        latency = latency + 1;
        if (latency == (1000*CYCLE)) begin
            $display("                   OUT_VALID should be 1 after 1000cycle!!!!!!                 ");
            repeat (2) @(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask
task check_ans_task; begin
    // Initialize output count
    out_num = 1;
    
    // Only perform checks when out_valid is high
    while (out_valid === 1) begin
        $display("check");
        if(gold_out!=out_data)begin
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                       FAIL!                                                                ");
            $display ("                                                                    pattern %d                                                              ",i_pat);
            $display ("                                           Your out is   : %b                                                                               ",out_data);
            $display ("                                           ans should be : %b                                                                               ",gold_out);
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            @(negedge clk);
            $finish;
        end
        if(out_num > 1) begin
            $display("                    out should be high for 1cycle                   ");
            repeat(9) @(negedge clk);
            $finish;
        end
        else begin
            @(negedge clk);
            out_num = out_num + 1;
        end
        
    end
    
end endtask


task YOU_PASS_task;
    begin
        $display("\033[1;33m                         `oo+oy+`                                                                                                     ");
        $display("\033[1;33m                        /h/----+y        `+++++:                                                                                      ");
        $display("\033[1;33m                      .y------:m/+ydoo+:y:---:+o                                                                                      ");
        $display("\033[1;33m                       o+------/y--::::::+oso+:/y                                                                                     ");
        $display("\033[1;33m                       s/-----:/:----------:+ooy+-                                                                                    ");
        $display("\033[1;33m                      /o----------------/yhyo/::/o+/:-.`                                                                              ");
        $display("\033[1;33m                     `ys----------------:::--------:::+yyo+                                                                           ");
        $display("\033[1;33m                     .d/:-------------------:--------/--/hos/                                                                         ");
        $display("\033[1;33m                     y/-------------------::ds------:s:/-:sy-                                                                         ");
        $display("\033[1;33m                    +y--------------------::os:-----:ssm/o+`                                                                          ");
        $display("\033[1;33m                   `d:-----------------------:-----/+o++yNNmms                                                                        ");
        $display("\033[1;33m                    /y-----------------------------------hMMMMN.                                                                      ");
        $display("\033[1;33m                    o+---------------------://:----------:odmdy/+.                                                                    ");
        $display("\033[1;33m                    o+---------------------::y:------------::+o-/h                                                                    ");
        $display("\033[1;33m                    :y-----------------------+s:------------/h:-:d                                                                    ");
        $display("\033[1;33m                    `m/-----------------------+y/---------:oy:--/y                                                                    ");
        $display("\033[1;33m                     /h------------------------:os++/:::/+o/:--:h-                                                                    ");
        $display("\033[1;33m                  `:+ym--------------------------://++++o/:---:h/                                                                     ");
        $display("\033[1;31m                 `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
        $display("\033[1;31m                  shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
        $display("\033[1;31m                  .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
        $display("\033[1;31m                 `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
        $display("\033[1;31m                 -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
        $display("\033[1;31m                  hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
        $display("\033[1;31m                  `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
        $display("\033[1;31m                   dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
        $display("\033[1;31m                  :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
        $display("\033[1;31m                 /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
        $display("\033[1;31m               +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
        $display("\033[1;31m               -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
        $display("\033[1;31m                `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
        $display("\033[1;31m                  os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
        $display("\033[1;33m                  h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
        $display("\033[1;33m                  m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
        $display("\033[1;33m                 `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
        $display("\033[1;33m                 .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
        $display("\033[1;33m                 +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
        $display("\033[1;33m                 h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
        $display("\033[1;33m                `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
        $display("\033[1;33m             `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
        $display("\033[1;33m            -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
        $display("\033[1;33m            s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
        $display("\033[1;33m            o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
        $display("\033[1;33m             :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
        $display("\033[1;33m                .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
        $display("\033[1;33m                                                   `:+omy/---------------------+h:----:y+//so                                         ");
        $display("\033[1;33m                                                       `-ys:-------------------+s-----+s///om                                         ");
        $display("\033[1;33m                                                          -os+::---------------/y-----ho///om                                         ");
        $display("\033[1;33m                                                             -+oo//:-----------:h-----h+///+d                                         ");
        $display("\033[1;33m                                                                `-oyy+:---------s:----s/////y                                         ");
        $display("\033[1;33m                                                                    `-/o+::-----:+----oo///+s                                         ");
        $display("\033[1;33m                                                                        ./+o+::-------:y///s:                                         ");
        $display("\033[1;33m                                                                            ./+oo/-----oo/+h                                          ");
        $display("\033[1;33m                                                                                `://++++syo`                                          ");
        $display("\033[1;0m");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                               Congratulations!                						                       ");
        $display("*                                                        Your execution cycles = %d cycles                                                  ", total_latency);
        $display("*                                                        Your clock period = %.1f ns                                                         ", CYCLE);
        $display("*                                                        Total Latency = %.1f ns                                                             ", total_latency*CYCLE);
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $finish;
    end
endtask

endmodule