module BB(
    //Input Ports
    input clk,
    input rst_n,
    input in_valid,
    input [1:0] inning,   // Current inning number
    input half,           // 0: top of the inning, 1: bottom of the inning
    input [2:0] action,   // Action code

    //Output Ports
    output reg out_valid,  // Result output valid
    output reg [7:0] score_A,  // Score of team A (guest team)
    output reg [7:0] score_B,  // Score of team B (home team)
    output reg [1:0] result    // 0: Team A wins, 1: Team B wins, 2: Darw
);

//==============================================//
//             Action Memo for Students         //
// Action code interpretation:
// 3’d0: Walk (BB)
// 3’d1: 1H (single hit)
// 3’d2: 2H (double hit)
// 3’d3: 3H (triple hit)
// 3’d4: HR (home run)
// 3’d5: Bunt (short hit)
// 3’d6: Ground ball
// 3’d7: Fly ball
//==============================================//

//==============================================//
//             Parameter and Integer            //
//==============================================//
// State declaration for FSM
// Example: parameter IDLE = 3'b000;
typedef enum reg[1:0]{IDLE=2'b00,TOP = 2'b01,BOTTOM = 2'b10,BOTTOM_NOMATTER = 2'b11}state;
state cur_state,nxt_state;
//parameter IDLE = 3'b000;
//parameter TOP = 3'b001;
//parameter BOTTOM = 3'b010;
//parameter BOTTOM_NOMATTER = 3'b011;
//parameter OUT = 3'b100;


//==============================================//
//                 reg declaration              //
//==============================================//
reg Base1_ff,Base2_ff,Base3_ff,Base1_nxt,Base2_nxt,Base3_nxt;
reg [7:0] score_A_nxt,score_B_nxt,score_A_ff,score_B_ff,score_A_comb,score_B_comb;
reg [2:0] grade;
//reg [2:0] cur_state,nxt_state;
reg [1:0] out_num_ff,out_num_nxt;
reg [2:0] action_ff;
reg out_valid_comb;
reg [1:0]result_comb;
//==============================================//
//             Current State Block              //
//==============================================//
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        cur_state<=IDLE;
        Base1_ff<=0;
        Base2_ff<=0;
        Base3_ff<=0;
        out_num_ff<=0;
        action_ff<=0;
        score_A_ff<=0;
        score_B_ff<=0;
        out_valid<=0;
        result<=0;
        score_A<=0;
        score_B<=0;
    end
    else begin
        cur_state<=nxt_state;
        Base1_ff<=Base1_nxt;
        Base2_ff<=Base2_nxt;
        Base3_ff<=Base3_nxt;
        out_num_ff<=out_num_nxt;
        action_ff<=action;
        score_A_ff<=score_A_nxt;
        score_B_ff<=score_B_nxt;
        out_valid<=out_valid_comb;
        result<=result_comb;
        score_A<=score_A_nxt;
        score_B<=score_B_nxt;
    end
end

//==============================================//
//              Next State Block                //
//==============================================//
always@*begin   //FSM
    case(cur_state)
        IDLE: begin
            if(in_valid)begin
                nxt_state=TOP;
            end
            else begin
                nxt_state=cur_state;
            end
        end
        TOP: begin
            if(half==1&&inning==3&&score_A_nxt<score_B_nxt)begin
                nxt_state=BOTTOM_NOMATTER;
            end
            else if(half==1)begin
                nxt_state=BOTTOM;
            end
            else begin
                nxt_state=cur_state;
            end
        end
        BOTTOM: begin
            if(!in_valid)begin
                nxt_state=IDLE;
            end
            else if(half==0)begin
                nxt_state=TOP;
            end
            else begin
                nxt_state=cur_state;
            end
        end
        BOTTOM_NOMATTER: begin
            if(in_valid)begin
                nxt_state=cur_state;
            end
            else begin
                nxt_state=IDLE;
            end
        end
        default: begin
            nxt_state=cur_state;
        end
    endcase
end
//==============================================//
//             Base and Score Logic             //
//==============================================//
// Handle base runner movements and score calculation.
// Update bases and score depending on the action:
// Example: Walk, Hits (1H, 2H, 3H), Home Runs, etc.
always@*begin
    if(cur_state==IDLE)begin
        Base1_nxt = 0;
        Base2_nxt = 0;
        Base3_nxt = 0;
        out_num_nxt = 0;
        grade=0;
    end
    else begin
        Base1_nxt = Base1_ff;
        Base2_nxt = Base2_ff;
        Base3_nxt = Base3_ff;
        grade=0;
        out_num_nxt = out_num_ff;
        if(action_ff==3'd0)begin //Walk
            Base1_nxt=1; //Walk
            if(Base1_ff==1)begin 
                if(Base2_ff==0)begin 
                    Base2_nxt = 1;
                    Base3_nxt = Base3_ff;
                end
                else begin 
                    if(Base3_ff==0)begin 
                        Base2_nxt = 1;
                        Base3_nxt = 1;
                    end
                    else begin 
                        grade=1;
                        Base2_nxt = 1;
                        Base3_nxt = 1;
                    end
                end
            end 
            else begin 
                Base2_nxt = Base2_ff;
                Base3_nxt = Base3_ff;
            end
        end
        else if(action_ff==3'd1)begin //Single
            Base1_nxt=1;
            if(out_num_ff==2)begin //2out
                Base2_nxt=0;
                Base3_nxt=Base1_ff;
                grade=Base3_ff+Base2_ff;
            end
            else begin //0、1out
                Base2_nxt=Base1_ff;
                Base3_nxt=Base2_ff;
                grade=Base3_ff;
                
            end
            
        end
        else if(action_ff==3'd2)begin //Double
            Base1_nxt=0;
            Base2_nxt=1;
            if(out_num_ff==2)begin
                Base3_nxt=0;
                grade=Base1_ff+Base2_ff+Base3_ff;
            end
            else begin
                Base3_nxt=Base1_ff;
                grade=Base2_ff+Base3_ff;
            end
        end
        else if(action_ff==3'd3)begin //Triple
            Base1_nxt=0;
            Base2_nxt=0;
            Base3_nxt=1;
            grade=Base1_ff+Base2_ff+Base3_ff;
        end
        else if(action_ff==3'd4)begin //Home Run
            Base1_nxt=0;
            Base2_nxt=0;
            Base3_nxt=0;
            grade=Base1_ff+Base2_ff+Base3_ff+1;
        end
        else if(action_ff==3'd5)begin //Bunt
            Base1_nxt=0;
            Base2_nxt=Base1_ff;
            Base3_nxt=Base2_ff;
            out_num_nxt=out_num_ff+1;
            grade=Base3_ff;
        end
        else if(action_ff==3'd6)begin //Gnd Ball
            if(out_num_ff==0)begin
                Base1_nxt=0;
                Base2_nxt=0;
                Base3_nxt=Base2_ff;
                grade=Base3_ff;
                out_num_nxt=1+Base1_ff;
            end
            else if(out_num_ff==1)begin
                if(Base1_ff==0)begin
                    out_num_nxt=2;
                    Base1_nxt=0;
                    Base2_nxt=0;
                    Base3_nxt=Base2_ff;
                    grade=Base3_ff;
                end
                else begin
                    out_num_nxt=0;
                    Base1_nxt=0;
                    Base2_nxt=0;
                    Base3_nxt=0;
                    grade=0;
                end
            end
            else begin
                out_num_nxt=0;
                Base1_nxt=0;
                Base2_nxt=0;
                Base3_nxt=0;
                grade=0;
            end
        end
        else if(action_ff==3'd7)begin //Fly Ball
            Base1_nxt=Base1_ff;
            Base2_nxt=Base2_ff;
            Base3_nxt=0;
            if(out_num_ff==0||out_num_ff==1)begin 
                grade=Base3_ff;
                out_num_nxt=out_num_ff+1;
            end
            else begin
                Base1_nxt=0;
                Base2_nxt=0;
                Base3_nxt=0;
                grade=0;
                out_num_nxt=0;
            end
        end
    end
end
always@*begin
    case(cur_state)
        TOP:begin
            score_A_nxt=score_A_ff+grade;
            score_B_nxt=score_B_ff;
        end
        BOTTOM_NOMATTER:begin
            score_B_nxt=score_B_ff;
            score_A_nxt=score_A_ff;
        end
        BOTTOM:begin
            score_B_nxt=score_B_ff+grade;
            score_A_nxt=score_A_ff;
        end
        default:begin
            score_A_nxt=0;
            score_B_nxt=0;
        end
    endcase
end
/*
always@*begin
    if(nxt_state==OUT)begin
        out_valid_comb=1;
        if(score_A_nxt<score_B_nxt)begin
            result_comb = 1;
        end
        else if(score_A_nxt==score_B_nxt)begin
            result_comb=2;
        end
        else begin
            result_comb=0;
        end
    end
    else begin
        out_valid_comb=0;
        result_comb=0;
    end
end
*/
always@*begin
    if((cur_state==BOTTOM||cur_state==BOTTOM_NOMATTER)&&!in_valid)begin
        out_valid_comb=1;
        if(score_A_nxt<score_B_nxt)begin
            result_comb = 1;
        end
        else if(score_A_nxt==score_B_nxt)begin
            result_comb=2;
        end
        else begin
            result_comb=0;
        end
    end
    else begin
        out_valid_comb=0;
        result_comb=0;
    end
end
//==============================================//
//                Output Block                  //
//==============================================//
// Decide when to set out_valid high, and output score_A, score_B, and result.



endmodule
