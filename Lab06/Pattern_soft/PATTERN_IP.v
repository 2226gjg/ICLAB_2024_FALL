`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 20.0
`endif

module PATTERN #(parameter IP_BIT = 5)(
    //Output Port
    IN_code,
    //Input Port
	OUT_code
);
// ========================================
// Input & Output
// ========================================

output reg [(IP_BIT+4-1):0] IN_code;
input [(IP_BIT-1):0] OUT_code;
//================================================================
// parameters & integer
//================================================================
integer PATNUM = 100;
integer patcount;
integer input_file, output_file;
integer k,i,j;
//================================================================
// clock
//================================================================
reg clk;
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

reg [(IP_BIT-1):0]ans_code;
//================================================================
// initial
//================================================================
initial begin
    $display("*                            IP_BIT: %d 	                      ", IP_BIT);
	input_file=$fopen("../00_TESTBED/input_11.txt","r");
    output_file=$fopen("../00_TESTBED/output_11.txt","r");

    IN_code='bx;
    repeat(5) @(negedge clk);

    //k = $fscanf(input_file, "%d", PATNUM);

	for( patcount = 0; patcount < PATNUM; patcount++) begin		
        input_task;
        repeat(1) @(negedge clk);
		check_ans;
		repeat($urandom_range(3, 5)) @(negedge clk);
	end
	display_pass;
    repeat(3) @(negedge clk);
    $finish;
end
//================================================================
// task
//================================================================

task input_task; begin
    //for ( i = IP_BIT+3; i >=0; i--) begin
        k = $fscanf(input_file, "%b", IN_code);
        
    //end
end endtask
task check_ans; begin
    //for ( i = IP_BIT-1; i >=0; i--) begin
        k = $fscanf(output_file, "%b", ans_code);
    //end
    if(OUT_code !== ans_code) begin
        display_fail;
        $display ("-------------------------------------------------------------------");
		$display("*                            PATTERN NO.%4d 	                      ", patcount);
        $display ("                ans should be : %b , your answer is : %b           ", ans_code, OUT_code);
        $display ("-------------------------------------------------------------------");
        #(100);
        $finish ;
    end
    else $display ("             \033[0;32mPass Pattern NO. %d\033[m         ", patcount);
end endtask


task display_fail; begin
    $display("\n");
    $display("\n");
    $display("\033[0;37m....................................................................................................\033[0m");
    $display("\033[0;37m.......................................................................,:+++:.......................\033[0m");
    $display("\033[0;37m....................................................,:+*\033[0m\033[0;32m******\033[0m\033[0;37m+;,....:*\033[0m\033[0;30m%%%%?%%S\033[0m\033[0;37m.\033[0m\033[0;30mS\033[0m\033[0;37m*:....................\033[0m");
    $display("\033[0;37m................................................,:*\033[0m\033[0;30m?%%%%%%%%\033[0m\033[0;32m????\033[0m\033[0;30m?%%%%%%%%\033[0m\033[0;32m*\033[0m\033[0;37m:.;.\033[0m\033[0;30m%%\033[0m\033[0;32m?\033[0m\033[0;30m%%SS%%%%SSS%%\033[0m\033[0;37m:..................\033[0m");
    $display("\033[0;37m..............................................:+\033[0m\033[0;30m?%%%%\033[0m\033[0;32m?????\033[0m\033[0;30m%%SSSSSSSSSSS\033[0m\033[0;37m.\033[0m\033[0;30m%%%%SSSSSS%%%%%%S\033[0m\033[0;37m.*,................\033[0m");
    $display("\033[0;37m...........................................:+\033[0m\033[0;30m?%%%%\033[0m\033[0;32m??????\033[0m\033[0;30mSS%%%%%%%%SSSSS#\033[0m\033[0;37m..\033[0m\033[0;30mSSSSS%%\033[0m\033[0;32m???????\033[0m\033[0;30m%%SS\033[0m\033[0;37m;...............\033[0m");
    $display("\033[0;37m........................................:+\033[0m\033[0;30m?%%%%\033[0m\033[0;32m???????\033[0m\033[0;30m%%S%%?%%SS%%%%???%%%%%%\033[0m\033[0;37m..\033[0m\033[0;30mSS%%\033[0m\033[0;32m??\033[0m\033[0;30m%%%%%%%%?\033[0m\033[0;32m*\033[0m\033[0;37m***\033[0m\033[0;30m?S\033[0m\033[0;37m*..............\033[0m");
    $display("\033[0;37m....................................,:+\033[0m\033[0;30m?%%%%\033[0m\033[0;32m????????\033[0m\033[0;30m%%SS?%%S%%\033[0m\033[0;32m???????????\033[0m\033[0;30m%%\033[0m\033[0;37m.\033[0m\033[0;30m%%?%%?\033[0m\033[0;37m+:,.,;+;,.,+\033[0m\033[0;30m?\033[0m\033[0;37m,............\033[0m");
    $display("\033[0;37m.................................,;*\033[0m\033[0;30m?%%?\033[0m\033[0;32m???????????\033[0m\033[0;30m%%\033[0m\033[0;32m?\033[0m\033[0;30m%%S%%\033[0m\033[0;32m????????\033[0m\033[0;30m?%%%%%%%%%%S\033[0m\033[0;37m.+:....+.....+..*\033[0m\033[0;30m*\033[0m\033[0;37m............\033[0m");
    $display("\033[0;37m..............................,;\033[0m\033[0;32m*\033[0m\033[0;30m%%%%?\033[0m\033[0;32m???????????????\033[0m\033[0;30mSS\033[0m\033[0;32m???????\033[0m\033[0;30m%%%%?\033[0m\033[0;32m*\033[0m\033[0;37m*+++++\033[0m\033[0;30mS\033[0m\033[0;37m,....:.......:..\033[0m\033[0;30mS\033[0m\033[0;37m:...........\033[0m");
    $display("\033[0;37m...........................:+\033[0m\033[0;30m?%%%%\033[0m\033[0;32m??????????????????\033[0m\033[0;30m%%S\033[0m\033[0;32m????\033[0m\033[0;30m%%%%%%?\033[0m\033[0;37m+;::,.....\033[0m\033[0;30mS\033[0m\033[0;37m;....*....;\033[0m\033[0;30m?\033[0m\033[0;37m.\033[0m\033[0;30m?\033[0m\033[0;37m,+.+...........\033[0m");
    $display("\033[0;37m.......................,:+\033[0m\033[0;30m?%%%%\033[0m\033[0;32m?????????????????????\033[0m\033[0;30mSS%%%%%%%%\033[0m\033[0;32m*\033[0m\033[0;37m;,,\033[0m\033[0;30m?\033[0m\033[0;37m....*.....\033[0m\033[0;30mS\033[0m\033[0;37m:,..\033[0m\033[0;30m?\033[0m\033[0;37m....;\033[0m\033[0;30m?\033[0m\033[0;37m..\033[0m\033[0;30m%%%%%%\033[0m\033[0;37m;...........\033[0m");
    $display("\033[0;37m....................,:+\033[0m\033[0;30m?%%%%\033[0m\033[0;32m???????????????????????\033[0m\033[0;30m%%%%S\033[0m\033[0;37m;:,,..:.......+..;.\033[0m\033[0;30m#SS%%?S\033[0m\033[0;37m.....\033[0m\033[0;30mS%%SS\033[0m\033[0;37m.*............\033[0m");
    $display("\033[0;37m..................,+\033[0m\033[0;30m?%%?\033[0m\033[0;32m??????????????????????????\033[0m\033[0;30m%%S?%%\033[0m\033[0;37m;...,....+\033[0m\033[0;30m%%\033[0m\033[0;37m..\033[0m\033[0;30m%%\033[0m\033[0;37m.+..\033[0m\033[0;30m%%\033[0m\033[0;32m*?\033[0m\033[0;30mSSSSSS%%SS\033[0m\033[0;37m....\033[0m\033[0;30m?\033[0m\033[0;37m,...........\033[0m");
    $display("\033[0;37m................:*\033[0m\033[0;30m??\033[0m\033[0;32m????????????????????????\033[0m\033[0;30m#?\033[0m\033[0;32m????\033[0m\033[0;30m#%%\033[0m\033[0;32m?\033[0m\033[0;30mS%%\033[0m\033[0;37m*:\033[0m\033[0;30m?\033[0m\033[0;37m...\033[0m\033[0;35m*\033[0m\033[0;37m,\033[0m\033[0;30m?\033[0m\033[0;37m...\033[0m\033[0;30mSS?%%\033[0m\033[0;37m..\033[0m\033[0;30m%%?\033[0m\033[0;32m?????\033[0m\033[0;30m%%SS#S%%\033[0m\033[0;32m?\033[0m\033[0;30m%%\033[0m\033[0;33m*\033[0m\033[0;37m...........\033[0m");
    $display("\033[0;37m..............,*\033[0m\033[0;30m%%\033[0m\033[0;32m???????????????????????????\033[0m\033[0;37m..\033[0m\033[0;30m%%\033[0m\033[0;32m????\033[0m\033[0;30m#S\033[0m\033[0;32m??\033[0m\033[0;30m%%S#\033[0m\033[0;37m...\033[0m\033[0;30mSS\033[0m\033[0;37m.\033[0m\033[0;30m#SS%%\033[0m\033[0;32m????\033[0m\033[0;30m%%\033[0m\033[0;37m...\033[0m\033[0;30mSSSSS%%?\033[0m\033[0;32m?????\033[0m\033[0;30m%%\033[0m\033[0;37m,..........\033[0m");
    $display("\033[0;37m.............+\033[0m\033[0;30m%%?\033[0m\033[0;32m?????????????????????????????\033[0m\033[0;30mS\033[0m\033[0;37m.\033[0m\033[0;30m#%%%%\033[0m\033[0;32m??\033[0m\033[0;30m%%SSSSSS%%SSS%%%%\033[0m\033[0;32m?????????\033[0m\033[0;30m%%\033[0m\033[0;37m..\033[0m\033[0;30mS%%\033[0m\033[0;32m?????????\033[0m\033[0;30m%%\033[0m\033[0;37m,..........\033[0m");
    $display("\033[0;37m............*\033[0m\033[0;30mS\033[0m\033[0;32m??????\033[0m\033[0;30m%%%%%%\033[0m\033[0;32m????\033[0m\033[0;30m%%%%%%%%%%%%%%%%%%%%%%%%?\033[0m\033[0;32m???????\033[0m\033[0;30m?%%SSSSSSS##S%%%%?\033[0m\033[0;32m??????????????\033[0m\033[0;30mS%%\033[0m\033[0;32m???????\033[0m\033[0;30m?%%%%\033[0m\033[0;37m+...........\033[0m");
    $display("\033[0;37m...........:\033[0m\033[0;30mS\033[0m\033[0;32m??????\033[0m\033[0;30m%%%%\033[0m\033[0;32m???\033[0m\033[0;30m%%%%%%%%\033[0m\033[0;31m%%%%%%%%%%%%\033[0m\033[0;30m%%%%%%%%SSSS%%%%%%?\033[0m\033[0;32m????????????????????????????????????\033[0m\033[0;30m?%%%%SS\033[0m\033[0;37m+............\033[0m");
    $display("\033[0;37m...........*\033[0m\033[0;30m%%\033[0m\033[0;32m?????\033[0m\033[0;30m%%?\033[0m\033[0;32m??\033[0m\033[0;30m%%S%%\033[0m\033[0;31m?????????????????%%\033[0m\033[0;30m%%%%SSSSSSSS%%%%%%?\033[0m\033[0;32m???????????????????\033[0m\033[0;30m?%%%%%%%%%%\033[0m\033[0;31m%%%%??%%\033[0m\033[0;30m?\033[0m\033[0;37m............\033[0m");
    $display("\033[0;37m...........\033[0m\033[0;32m?\033[0m\033[0;30m%%\033[0m\033[0;32m????\033[0m\033[0;30m?%%\033[0m\033[0;32m??\033[0m\033[0;30m%%S\033[0m\033[0;31m??????\033[0m\033[0;30mSSSSS%%\033[0m\033[0;31m%%%%?????????????%%\033[0m\033[0;30m%%SSSSSSSSSSSSSSSSSSSSSSSS%%%%\033[0m\033[0;31m%%??????%%\033[0m\033[0;30m%%\033[0m\033[0;37m;............\033[0m");
    $display("\033[0;37m...........;\033[0m\033[0;30m%%\033[0m\033[0;32m????\033[0m\033[0;30m%%%%\033[0m\033[0;32m??\033[0m\033[0;37m.\033[0m\033[0;31m???????????%%%%\033[0m\033[0;30m%%%%SSSSSSS%%%%\033[0m\033[0;31m%%%%?????????????????%%%%%%%%%%?????????????%%\033[0m\033[0;30m%%\033[0m\033[0;37m*,.............\033[0m");
    $display("\033[0;37m............\033[0m\033[0;32m*\033[0m\033[0;30m%%\033[0m\033[0;32m???\033[0m\033[0;30m%%%%\033[0m\033[0;32m??\033[0m\033[0;37m.\033[0m\033[0;30m%%\033[0m\033[0;31m?????????????????????%%%%%%\033[0m\033[0;30m%%SSSSSSSSSS%%%%\033[0m\033[0;31m%%%%???????????????%%%%\033[0m\033[0;30m%%SS#\033[0m\033[0;37m+,...............\033[0m");
    $display("\033[0;37m............,\033[0m\033[0;30m%%?\033[0m\033[0;32m??\033[0m\033[0;30m?\033[0m\033[0;32m???\033[0m\033[0;30m?S%%\033[0m\033[0;31m%%%%%%%%%%%%%%%%%%%%%%%%%%????????????????%%%%\033[0m\033[0;30m%%%%%%SSSSSSSSSSSSSSSSSSSSSS%%\033[0m\033[0;31m%%%%\033[0m\033[0;33m*\033[0m\033[0;37m................\033[0m");
    $display("\033[0;37m............,\033[0m\033[0;30mSS?\033[0m\033[0;32m???????\033[0m\033[0;30m%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\033[0m\033[0;31m%%%%%%????????????????????????????????????%%?\033[0m\033[0;37m,...............\033[0m");
    $display("\033[0;37m............\033[0m\033[0;30m?S\033[0m\033[0;32m?\033[0m\033[0;30m%%%%\033[0m\033[0;32m?????????????????????????\033[0m\033[0;30m?%%%%SSSSSSS%%%%%%%%%%%%\033[0m\033[0;31m%%%%%%%%?????????????????%%%%?\033[0m\033[0;37m;,................\033[0m");
    $display("\033[0;37m...........*\033[0m\033[0;30m#%%\033[0m\033[0;32m??\033[0m\033[0;30m%%%%?\033[0m\033[0;32m???????????????????????????????\033[0m\033[0;30m?%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%SS%%\033[0m\033[0;31m???*\033[0m\033[0;33m*\033[0m\033[0;37m+;,...................\033[0m");
    $display("\033[0;37m...........\033[0m\033[0;34m?%%%%\033[0m\033[0;30m%%%%\033[0m\033[0;32m??\033[0m\033[0;30m%%%%?\033[0m\033[0;32m?????????????????????????????????????????????\033[0m\033[0;30m?%%%%?\033[0m\033[0;37m*;,,,,........................\033[0m");
    $display("\033[0;37m...........\033[0m\033[0;34m?%%%%%%%%%%\033[0m\033[0;30m%%%%%%%%%%%%\033[0m\033[0;32m???????????????????????????????????????\033[0m\033[0;30m%%%%%%?\033[0m\033[0;32m*\033[0m\033[0;37m+:...............................\033[0m");
    $display("\033[0;37m...........\033[0m\033[0;34m?%%%%%%%%%%%%%%%%\033[0m\033[0;30m%%%%SS%%%%\033[0m\033[0;32m??????????????????????????????\033[0m\033[0;30m?%%%%%%S%%\033[0m\033[0;36m*\033[0m\033[0;37m;,...................................\033[0m");
    $display("\033[0;37m...........\033[0m\033[0;34m?%%%%%%%%%%%%%%%%%%%%%%%%%%\033[0m\033[0;30mSSSSS%%%%%%%%%%%%???????????\033[0m\033[0;32m???\033[0m\033[0;30m???\033[0m\033[0;32m?????\033[0m\033[0;30m??%%%%\033[0m\033[0;34m%%?\033[0m\033[0;37m+:..................................\033[0m");
    $display("\033[0;37m...........\033[0m\033[0;34m?%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%SS\033[0m\033[0;30mSSSSSSSSS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\033[0m\033[0;34m%%%%%%%%%%%%%%?\033[0m\033[0;37m+,...............................\033[0m");
    $display("\033[0;37m...........\033[0m\033[0;34m?%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\033[0m\033[0;36m*\033[0m\033[0;37m:.............................\033[0m");
    $display("\033[0;37m...........\033[0m\033[0;34m?%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\033[0m\033[0;37m;............................\033[0m");
    $display("\033[0;37m...........\033[0m\033[0;34m?%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\033[0m\033[0;30mS\033[0m\033[0;37m+...........................\033[0m");
    $display("\033[0;37m...........::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::...........................\033[0m");
    $display("\033[0;37m....................................................................................................\033[0m");
    $display("\033[0;37m....................................................................................................\033[0m");
    $display("\033[31m \033[5m     //   / /     //   ) )     //   ) )     //   ) )     //   ) )\033[0m");
    $display("\033[31m \033[5m    //____       //___/ /     //___/ /     //   / /     //___/ /\033[0m");
    $display("\033[31m \033[5m   / ____       / ___ (      / ___ (      //   / /     / ___ (\033[0m");
    $display("\033[31m \033[5m  //           //   | |     //   | |     //   / /     //   | |\033[0m");
    $display("\033[31m \033[5m //____/ /    //    | |    //    | |    ((___/ /     //    | |\033[0m");

    /*$display("        ----------------------------               ");
    $display("        --                        --       |\__||  ");
    $display("        --  OOPS!!                --      / X,X  | ");
    $display("        --                        --    /_____   | ");
    $display("        --  \033[0;31mSimulation FAIL!!\033[m   --   /^ ^ ^ \\  |");
    $display("        --                        --  |^ ^ ^ ^ |w| ");
    $display("        ----------------------------   \\m___m__|_|");
    $display("\n");*/
end endtask
task display_pass; begin
    $display("\033[0;37m......................................................,\033[0m\033[0;30m?%%%%%%\033[0m\033[0;37m+,.......................................\033[0m");
    $display("\033[0;37m.................................................,,::+\033[0m\033[0;30mS\033[0m\033[0;33m*::;?\033[0m\033[0;30m?\033[0m\033[0;33m*\033[0m\033[0;37m*+:...................................\033[0m");
    $display("\033[0;37m.........................................,+:...;\033[0m\033[0;30m?\033[0m\033[0;31m?\033[0m\033[0;33m*\033[0m\033[0;31m?\033[0m\033[0;30mSS\033[0m\033[0;33m+,,,::;+*\033[0m\033[0;31m?\033[0m\033[0;30mS\033[0m\033[0;37m*..................................\033[0m");
    $display("\033[0;37m........................................+\033[0m\033[0;30m%%\033[0m\033[0;37m.;.,*\033[0m\033[0;30m%%\033[0m\033[0;33m;,,,,,,,,,:;;:::;\033[0m\033[0;30m?\033[0m\033[0;37m*,................................\033[0m");
    $display("\033[0;37m.......................................;\033[0m\033[0;30mS\033[0m\033[0;33m:*\033[0m\033[0;30m%%??\033[0m\033[0;33m+,,:,,,,,;*+::;;;;;:*\033[0m\033[0;30m%%\033[0m\033[0;37m*,..............................\033[0m");
    $display("\033[0;37m.......................................+\033[0m\033[0;30m?\033[0m\033[0;33m,,,:,,;\033[0m\033[0;31m?*\033[0m\033[0;30m?\033[0m\033[0;33m*+*\033[0m\033[0;30m%%SS\033[0m\033[0;37m.\033[0m\033[0;30mS\033[0m\033[0;33m+::::;;:;\033[0m\033[0;30m%%S\033[0m\033[0;37m:.............................\033[0m");
    $display("\033[0;37m.......................................:\033[0m\033[0;30mS\033[0m\033[0;33m:,,,:*\033[0m\033[0;30m?\033[0m\033[0;37m:,,;+;:,,:\033[0m\033[0;33m*\033[0m\033[0;30mS\033[0m\033[0;33m?+*\033[0m\033[0;30m?%%S%%\033[0m\033[0;33m;:\033[0m\033[0;31m?\033[0m\033[0;37m.:............................\033[0m");
    $display("\033[0;37m.......................................+.\033[0m\033[0;31m?\033[0m\033[0;33m;;+\033[0m\033[0;30m?\033[0m\033[0;37m*,,,,,,,,,,,,:\033[0m\033[0;33m+\033[0m\033[0;37m;;::;\033[0m\033[0;30mS\033[0m\033[0;37m.\033[0m\033[0;33m;:\033[0m\033[0;30m%%S\033[0m\033[0;37m,...........................\033[0m");
    $display("\033[0;37m.......................................\033[0m\033[0;30mS\033[0m\033[0;33m+:\033[0m\033[0;30mS?\033[0m\033[0;37m*\033[0m\033[0;33m*\033[0m\033[0;37m:,,,,,,,,,;\033[0m\033[0;30m%%\033[0m\033[0;37m;,,,,,,,\033[0m\033[0;30m%%\033[0m\033[0;37m.\033[0m\033[0;33m;:+\033[0m\033[0;37m.;...........................\033[0m");
    $display("\033[0;37m.......................................+\033[0m\033[0;30m%%%%?\033[0m\033[0;37m,:,,,,,,,,,,,,;\033[0m\033[0;30m%%\033[0m\033[0;33m+\033[0m\033[0;37m,,,,;\033[0m\033[0;30mS%%\033[0m\033[0;33m;:;;\033[0m\033[0;37m.+...........................\033[0m");
    $display("\033[0;37m........................................\033[0m\033[0;30mSS\033[0m\033[0;37m,,,,,,,,,,,,,,,.,:,,,,+\033[0m\033[0;30m%%?\033[0m\033[0;33m+::+\033[0m\033[0;37m.;...........................\033[0m");
    $display("\033[0;37m.......................................:.:,:.\033[0m\033[0;30mS\033[0m\033[0;37m,,,,\033[0m\033[0;31m*\033[0m\033[0;37m,,,;\033[0m\033[0;30m?%%?\033[0m\033[0;37m:,,,,,;\033[0m\033[0;31m?\033[0m\033[0;30m??\033[0m\033[0;33m*:\033[0m\033[0;31m?\033[0m\033[0;37m.,...........................\033[0m");
    $display("\033[0;37m.......................................\033[0m\033[0;30m%%?\033[0m\033[0;37m,,:.\033[0m\033[0;30m%%\033[0m\033[0;37m,,,\033[0m\033[0;30m%%\033[0m\033[0;37m+,,,:;\033[0m\033[0;33m*\033[0m\033[0;37m.\033[0m\033[0;30mS\033[0m\033[0;37m,,,,,;\033[0m\033[0;31m?\033[0m\033[0;30m?\033[0m\033[0;31m?\033[0m\033[0;30m?\033[0m\033[0;33m*\033[0m\033[0;37m.\033[0m\033[0;30m?\033[0m\033[0;37m............................\033[0m");
    $display("\033[0;37m.........,+\033[0m\033[0;33m*\033[0m\033[0;30m??%%\033[0m\033[0;37m:......................,.;,,,:,,:\033[0m\033[0;30mS\033[0m\033[0;37m*,,,,,,,,:,,,,,;\033[0m\033[0;33m**\033[0m\033[0;30m%%?\033[0m\033[0;37m..:............................\033[0m");
    $display("\033[0;37m........,\033[0m\033[0;30m?\033[0m\033[0;37m+:,,\033[0m\033[0;30m?%%\033[0m\033[0;37m......................:.:,,,,,:.\033[0m\033[0;30m%%\033[0m\033[0;37m.,,,,,,,,,,,,,,\033[0m\033[0;33m+*+\033[0m\033[0;37m+\033[0m\033[0;30mS\033[0m\033[0;37m.+.............................\033[0m");
    $display("\033[0;37m........\033[0m\033[0;33m*\033[0m\033[0;37m;,,,,\033[0m\033[0;30m?\033[0m\033[0;37m*......................:.:,,,,,,\033[0m\033[0;31m*\033[0m\033[0;37m.;,,,,,,,,,,,,,,:\033[0m\033[0;33m*\033[0m\033[0;37m,:.\033[0m\033[0;30mS\033[0m\033[0;37m..............................\033[0m");
    $display("\033[0;37m.......,\033[0m\033[0;30m?\033[0m\033[0;37m,,,,,\033[0m\033[0;30mS\033[0m\033[0;37m,......................:.;,,:,,,,::,,,,;\033[0m\033[0;30mS\033[0m\033[0;37m+,,,,,,,,,,,\033[0m\033[0;33m+\033[0m\033[0;37m.;.............................\033[0m");
    $display("\033[0;37m.......,\033[0m\033[0;30m%%\033[0m\033[0;37m,,,,;\033[0m\033[0;30m?\033[0m\033[0;37m.......................,.\033[0m\033[0;33m*\033[0m\033[0;37m,\033[0m\033[0;30mSS\033[0m\033[0;37m+;;::;;++*+\033[0m\033[0;34m*\033[0m\033[0;37m.\033[0m\033[0;30mS\033[0m\033[0;37m:,,,,,,,,,\033[0m\033[0;33m+\033[0m\033[0;37m.;.............................\033[0m");
    $display("\033[0;37m........\033[0m\033[0;30m?\033[0m\033[0;37m;,,,:\033[0m\033[0;30m%%\033[0m\033[0;37m,.......................\033[0m\033[0;30m?\033[0m\033[0;37m.,\033[0m\033[0;30m?%%\033[0m\033[0;37m++;::::::;+*\033[0m\033[0;30m?S\033[0m\033[0;37m:,,,,,,:;\033[0m\033[0;33m*\033[0m\033[0;37m.*..............................\033[0m");
    $display("\033[0;37m......,,;.;,,,;\033[0m\033[0;30m?\033[0m\033[0;37m;,.....................:.\033[0m\033[0;30m?\033[0m\033[0;37m,::+\033[0m\033[0;30m???????\033[0m\033[0;37m*;,,;,,,,,:\033[0m\033[0;30m%%#?\033[0m\033[0;34m*\033[0m\033[0;37m:...............................\033[0m");
    $display("\033[0;37m...;\033[0m\033[0;30m?????S%%?\033[0m\033[0;33m*\033[0m\033[0;37m;,,\033[0m\033[0;33m+\033[0m\033[0;30m%%\033[0m\033[0;37m*,....................+.*.,,,+\033[0m\033[0;30m%%S\033[0m\033[0;37m+,,,,,,,,,,,;\033[0m\033[0;30mSS\033[0m\033[0;37m:..................................\033[0m");
    $display("\033[0;37m..;.;,,,,,,:;\033[0m\033[0;30m?%%\033[0m\033[0;33m+\033[0m\033[0;37m,:\033[0m\033[0;30mS%%\033[0m\033[0;37m,....................*.\033[0m\033[0;31m?\033[0m\033[0;37m,,,:;+:,,,,,,,,,:\033[0m\033[0;30m?\033[0m\033[0;37m.\033[0m\033[0;30mS\033[0m\033[0;37m;,..................................\033[0m");
    $display("\033[0;37m..*\033[0m\033[0;30mS\033[0m\033[0;37m.,,,,,,,,,:.;,:\033[0m\033[0;30mS\033[0m\033[0;37m.\033[0m\033[0;30mS?\033[0m\033[0;37m+;:,............,,,+.\033[0m\033[0;30mS\033[0m\033[0;37m;,,,,,,,,,,,,:\033[0m\033[0;33m*\033[0m\033[0;30mS\033[0m\033[0;37m.\033[0m\033[0;33m*\033[0m\033[0;37m;\033[0m\033[0;33m+\033[0m\033[0;31m?\033[0m\033[0;30m%%\033[0m\033[0;37m+:,..............................\033[0m");
    $display("\033[0;37m..,\033[0m\033[0;30m?\033[0m\033[0;31m?\033[0m\033[0;37m+\033[0m\033[0;33m*\033[0m\033[0;31m?\033[0m\033[0;30m???\033[0m\033[0;33m*\033[0m\033[0;37m;::.\033[0m\033[0;33m*\033[0m\033[0;37m,,\033[0m\033[0;33m+\033[0m\033[0;37m.\033[0m\033[0;30m#\033[0m\033[0;34m?\033[0m\033[0;30m%%SS%%%%??\033[0m\033[0;34m*\033[0m\033[0;37m***\033[0m\033[0;34m*???\033[0m\033[0;30m???%%\033[0m\033[0;34m?\033[0m\033[0;30m%%S\033[0m\033[0;37m.\033[0m\033[0;30m%%\033[0m\033[0;37m+:,,,,,,,,,:;\033[0m\033[0;30m??\033[0m\033[0;37m,,,;.\033[0m\033[0;30m%%S%%\033[0m\033[0;37m*;,...........................\033[0m");
    $display("\033[0;37m...\033[0m\033[0;30m?%%\033[0m\033[0;37m;::::;+\033[0m\033[0;33m*\033[0m\033[0;30m%%\033[0m\033[0;37m.\033[0m\033[0;30m%%\033[0m\033[0;37m,,,\033[0m\033[0;33m*\033[0m\033[0;30mS%%\033[0m\033[0;36m+\033[0m\033[0;37m++++\033[0m\033[0;36m+********+++\033[0m\033[0;37m+++++\033[0m\033[0;30m%%\033[0m\033[0;31m?\033[0m\033[0;37m:+\033[0m\033[0;30m%%S?\033[0m\033[0;33m*+\033[0m\033[0;37m;:,,:\033[0m\033[0;33m+\033[0m\033[0;30m%%\033[0m\033[0;31m?\033[0m\033[0;37m,,,,\033[0m\033[0;30m%%#\033[0m\033[0;36m?\033[0m\033[0;34m??%%\033[0m\033[0;30mS%%\033[0m\033[0;37m*:.........................\033[0m");
    $display("\033[0;37m..,.;.,,,,...,:\033[0m\033[0;30m%%\033[0m\033[0;33m*\033[0m\033[0;37m,:\033[0m\033[0;30mS\033[0m\033[0;37m;\033[0m\033[0;33m*\033[0m\033[0;34m?\033[0m\033[0;37m+++++++++++++++++++++\033[0m\033[0;30m%%\033[0m\033[0;31m?\033[0m\033[0;37m,,:\033[0m\033[0;31m?\033[0m\033[0;37m...\033[0m\033[0;30mS%%%%%%%%\033[0m\033[0;31m?\033[0m\033[0;37m;,,,,\033[0m\033[0;30m%%\033[0m\033[0;37m.\033[0m\033[0;34m???????%%\033[0m\033[0;30mS%%\033[0m\033[0;37m;.......................\033[0m");
    $display("\033[0;37m...*\033[0m\033[0;30m%%\033[0m\033[0;37m++*\033[0m\033[0;33m**\033[0m\033[0;37m++;:,*\033[0m\033[0;30mS\033[0m\033[0;37m,\033[0m\033[0;33m*\033[0m\033[0;37m.,\033[0m\033[0;33m+\033[0m\033[0;34m%%\033[0m\033[0;36m?*+\033[0m\033[0;37m++++++++++++++++++\033[0m\033[0;36m*\033[0m\033[0;37m.;,,,:;\033[0m\033[0;33m+++\033[0m\033[0;37m;:,,,,,;\033[0m\033[0;30mS#\033[0m\033[0;34m??????????%%\033[0m\033[0;30mS%%\033[0m\033[0;37m;.....................\033[0m");
    $display("\033[0;37m....\033[0m\033[0;30m?S\033[0m\033[0;37m;;;;+\033[0m\033[0;33m*\033[0m\033[0;30m?%%S\033[0m\033[0;37m.;,\033[0m\033[0;33m+\033[0m\033[0;30m%%\033[0m\033[0;37m,\033[0m\033[0;33m*\033[0m\033[0;34m%%???\033[0m\033[0;36m**+\033[0m\033[0;37m++++++++++++++++\033[0m\033[0;36m*\033[0m\033[0;30m#\033[0m\033[0;33m+\033[0m\033[0;37m,,,,,,,,,,,:\033[0m\033[0;33m+\033[0m\033[0;30m%%#\033[0m\033[0;34m%%?????????????%%\033[0m\033[0;30m#%%\033[0m\033[0;37m:...................\033[0m");
    $display("\033[0;37m....\033[0m\033[0;30mS\033[0m\033[0;33m*\033[0m\033[0;37m.......,+.\033[0m\033[0;33m+\033[0m\033[0;37m,\033[0m\033[0;30m%%\033[0m\033[0;37m;:\033[0m\033[0;30mS\033[0m\033[0;34m???????\033[0m\033[0;36m***++++\033[0m\033[0;37m+\033[0m\033[0;34m?\033[0m\033[0;36m*\033[0m\033[0;37m+++++++\033[0m\033[0;30mS\033[0m\033[0;33m*\033[0m\033[0;37m,,,,,,,;\033[0m\033[0;33m*\033[0m\033[0;31m*\033[0m\033[0;30m%%SS\033[0m\033[0;34m%%?????????????????%%\033[0m\033[0;30mS\033[0m\033[0;37m*,.................\033[0m");
    $display("\033[0;37m....:\033[0m\033[0;30m#S\033[0m\033[0;31m*\033[0m\033[0;37m+;;;+*\033[0m\033[0;30m%%%%\033[0m\033[0;37m;\033[0m\033[0;30m?\033[0m\033[0;37m;;\033[0m\033[0;30m%%\033[0m\033[0;34m???????????????%%\033[0m\033[0;37m.\033[0m\033[0;34m?\033[0m\033[0;37m++++++\033[0m\033[0;36m+\033[0m\033[0;37m.;,,,,,,\033[0m\033[0;33m*\033[0m\033[0;30m#\033[0m\033[0;34m%%%%???????????????????????\033[0m\033[0;30mS%%\033[0m\033[0;37m:................\033[0m");
    $display("\033[0;37m.....,*\033[0m\033[0;30mS#%%%%??????\033[0m\033[0;33m+*\033[0m\033[0;30m%%\033[0m\033[0;34m????????%%%%%%\033[0m\033[0;30m%%%%%%\033[0m\033[0;34m?\033[0m\033[0;37m*+.\033[0m\033[0;34m?\033[0m\033[0;37m++++++\033[0m\033[0;34m?\033[0m\033[0;30mS\033[0m\033[0;37m,,,,,,,\033[0m\033[0;30mS\033[0m\033[0;34m%%\033[0m\033[0;36m?\033[0m\033[0;34m????????????????????????\033[0m\033[0;36m?\033[0m\033[0;34m%%\033[0m\033[0;30mS\033[0m\033[0;37m+...............\033[0m");
    $display("\033[0;37m........,:;++*\033[0m\033[0;30m??\033[0m\033[0;33m*\033[0m\033[0;30m%%S%%%%%%%%%%%%%%%%?\033[0m\033[0;36m*\033[0m\033[0;37m+;:,,..,.\033[0m\033[0;36m*\033[0m\033[0;37m++++++\033[0m\033[0;30m%%?\033[0m\033[0;37m,,,,,,:.\033[0m\033[0;34m?????????????????????????????\033[0m\033[0;30mS*\033[0m\033[0;37m..............\033[0m");
    $display("\033[0;37m...................,,,,,............,.\033[0m\033[0;34m?\033[0m\033[0;37m++++++\033[0m\033[0;30m#\033[0m\033[0;33m+\033[0m\033[0;37m,,,,,,;.\033[0m\033[0;34m??????????%%\033[0m\033[0;30mS\033[0m\033[0;34m%%?????????????????\033[0m\033[0;30mS%%\033[0m\033[0;37m,............\033[0m");
    $display("\033[0;37m....................................,.\033[0m\033[0;34m?\033[0m\033[0;37m++++++.;,,,,,,\033[0m\033[0;33m*\033[0m\033[0;30m#\033[0m\033[0;34m???????????\033[0m\033[0;30mSS#S%%\033[0m\033[0;34m???????????????\033[0m\033[0;30mS%%\033[0m\033[0;37m,...........\033[0m");
    $display("\033[0;32m \033[5m    //   ) )     // | |     //   ) )     //   ) )\033[m");
    $display("\033[0;32m \033[5m   //___/ /     //__| |    ((           ((\033[m");
    $display("\033[0;32m \033[5m  / ____ /     / ___  |      \\           \\\033[m");
    $display("\033[0;32m \033[5m //           //    | |        ) )          ) )\033[m");
    $display("\033[0;32m \033[5m//           //     | | ((___ / /    ((___ / /\033[m");
    $display("        ----------------------------               ");
    $display("        --                        --               ");
    $display("        --  Congratulations !!    --               ");
    $display("        --                        --               ");
    $display("        --  \033[0;32mSimulation PASS!!\033[m          ");
    $display("        --                        --               ");
    $display("        ----------------------------               ");
end endtask
endmodule