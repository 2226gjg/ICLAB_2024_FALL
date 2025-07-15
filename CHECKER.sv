/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Formula_and_mode;
    Formula_Type f_type;
    Mode f_mode;
endclass

Formula_and_mode fm_info = new();
always_ff@(posedge clk)begin
    if(inf.formula_valid)
        fm_info.f_type=inf.D.d_formula[0];
    if(inf.mode_valid)
        fm_info.f_mode=inf.D.d_mode[0];
end
//========================================================//
//SPEC1                                                   //
//========================================================//
covergroup Formula_group@(posedge clk iff(inf.formula_valid));
    option.per_instance=1;
    option.at_least=150;
    formula_coverpoint: coverpoint inf.D.d_formula[0]{
        bins formula_bin[]={Formula_A,Formula_B,Formula_C,Formula_D,Formula_E,Formula_F,Formula_G,Formula_H};
    }
endgroup
Formula_group Formula_cov=new();

//========================================================//
//SPEC2                                                   //
//========================================================//
covergroup Mode_group@(posedge clk iff(inf.mode_valid));
    option.per_instance=1;
    option.at_least=150;
    mode_coverpoint: coverpoint inf.D.d_mode[0]{
        bins formula_bin[]={Insensitive,Normal,Sensitive};
    }
endgroup
Mode_group Mode_cov=new();
//========================================================//
//SPEC3                                                   //
//========================================================//
covergroup Cross_group@(posedge clk iff(inf.mode_valid));
    option.per_instance=1;
    option.at_least=150;
    cross fm_info.f_type,fm_info.f_mode;
endgroup
Cross_group cross_cov=new();
//========================================================//
//SPEC4                                                   //
//========================================================//
covergroup Warn_group@(negedge clk iff(inf.out_valid));
    option.per_instance=1;
    option.at_least=150;
    warn_coverpoint: coverpoint inf.warn_msg{
        bins out_bin[]={No_Warn,Data_Warn,Date_Warn,Risk_Warn};
    }
endgroup
Warn_group warn_cov=new();
//========================================================//
//SPEC5                                                   //
//========================================================//
covergroup Tran_group@(posedge clk iff(inf.sel_action_valid));
    option.per_instance=1;
    option.at_least=300;
    action_coverpoint: coverpoint inf.D.d_act[0]{
        bins action_trans_bin[]=([Index_Check:Check_Valid_Date]=>[Index_Check:Check_Valid_Date]);
    }
endgroup
Tran_group action_trans=new();
//========================================================//
//SPEC6                                                   //
//========================================================//
Action act_ff;
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)begin
        act_ff<=Index_Check;
    end
    else begin
        if(inf.sel_action_valid&&inf.D.d_act[0]==Update)begin
            act_ff<=Update;
        end
        else if(inf.sel_action_valid&&inf.D.d_act[0]==Index_Check)begin
            act_ff<=Index_Check;
        end
        else if(inf.sel_action_valid&&inf.D.d_act[0]==Check_Valid_Date)begin
            act_ff<=Check_Valid_Date;
        end
    end
end
covergroup Variation_group@(posedge clk iff(inf.index_valid&&act_ff==Update));
    option.per_instance=1;
    option.at_least=1;
    variation_coverpoint: coverpoint inf.D.d_index[0]{
        option.auto_bin_max = 32;
    }
endgroup
Variation_group variation_cov=new();

//=============================================================================================//
//Assertion1: All outputs signals (Program.sv) should be zero after reset                                             
//=============================================================================================//
always@(negedge inf.rst_n)begin
    #2;
    Reset_check: assert (inf.out_valid===0&&inf.warn_msg===0&& inf.complete===0&& inf.AR_VALID===0&&inf.AR_ADDR===0&& inf.R_READY===0&&inf.AW_VALID===0&&inf.AW_ADDR===0&&inf.W_VALID===0&&inf.W_DATA===0&&inf.B_READY===0)else $fatal(0,"Assertion 1 is violated");
end
//=============================================================================================//
//Assertion2: Latency should be less than 1000 cycles for each operation.                                         
//=============================================================================================//
logic [1:0]counter_index;
always_ff@(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n)begin
        counter_index<=0;
    end
    else begin
        if(inf.index_valid)begin
            counter_index<=counter_index+1;
        end
    end
end
property latency_property1;
	@(posedge clk) (((act_ff===Index_Check||act_ff===Update)&&inf.index_valid&&counter_index==3)|-> ##[1:1000] inf.out_valid);
endproperty
property latency_property2;
    @(posedge clk) ((act_ff==Check_Valid_Date&&inf.data_no_valid)|-> ##[1:1000] inf.out_valid);
endproperty
Latency_check1: assert property(latency_property1) else $fatal(0,"Assertion 2 is violated");
Latency_check2: assert property(latency_property2) else $fatal(0,"Assertion 2 is violated");
//=============================================================================================//
//Assertion3: If action is completed (complete=1), warn_msg should be 2’b0 (No_Warn).                                         
//=============================================================================================//
property assertion3_property;
	@(negedge clk) (inf.complete===1|->inf.warn_msg===No_Warn);
endproperty
Assertion3_check: assert property(assertion3_property)else $fatal(0,"Assertion 3 is violated");
//=============================================================================================//
//Assertion4: Next input valid will be valid 1-4 cycles after previous input valid fall.                                         
//=============================================================================================//
property IN_Index_Check_property;
    @(posedge clk) ((inf.sel_action_valid===1&&inf.D.d_act[0]===Index_Check)|->##[1:4]inf.formula_valid ##[1:4]inf.mode_valid##[1:4]inf.date_valid##[1:4]inf.data_no_valid##[1:4]inf.index_valid##[1:4]inf.index_valid##[1:4]inf.index_valid##[1:4]inf.index_valid);
endproperty
property IN_Update_property;
    @(posedge clk) ((inf.sel_action_valid===1&&inf.D.d_act[0]===Update)|->##[1:4]inf.date_valid##[1:4]inf.data_no_valid##[1:4]inf.index_valid##[1:4]inf.index_valid##[1:4]inf.index_valid##[1:4]inf.index_valid);
endproperty
property IN_Check_Valid_Date_property;
    @(posedge clk) ((inf.sel_action_valid===1&&inf.D.d_act[0]===Check_Valid_Date)|->##[1:4]inf.date_valid##[1:4]inf.data_no_valid);
endproperty
invalid_check1: assert property(IN_Index_Check_property)else $fatal(0,"Assertion 4 is violated");
invalid_check2: assert property(IN_Update_property)else $fatal(0,"Assertion 4 is violated");
invalid_check3: assert property(IN_Check_Valid_Date_property)else $fatal(0,"Assertion 4 is violated");

//=============================================================================================//
//Assertion5: All input valid signals won’t overlap with each other                                         
//=============================================================================================//
logic[3:0] sum_in_valid;
always_comb begin
    sum_in_valid=inf.sel_action_valid+inf.formula_valid+inf.mode_valid+inf.date_valid+inf.data_no_valid+inf.index_valid;
end

property overlap_property;
    @(posedge clk) (sum_in_valid===1||sum_in_valid===0);
endproperty
overlap_check: assert property(overlap_property)else $fatal(0,"Assertion 5 is violated");

//=============================================================================================//
//Assertion6: Out_valid can only be high for exactly one cycle                                       
//=============================================================================================//
property out_valid_high_property;
    @(negedge clk) (inf.out_valid===1|=>inf.out_valid===0);
endproperty
out_valid_high_check: assert property(out_valid_high_property)else $fatal(0,"Assertion 6 is violated");

//=============================================================================================//
//Assertion7: Next operation will be valid 1-4 cycles after out_valid fall.                                       
//=============================================================================================//
property out_valid_to_in_valid_property;
    @(posedge clk) (inf.out_valid===1|->##[1:4]inf.sel_action_valid===1);
endproperty
out_valid_to_in_valid_check:assert property(out_valid_to_in_valid_property)else $fatal(0,"Assertion 7 is violated");
//=============================================================================================//
//Assertion8: The input date from pattern should adhere to the real calendar                                       
//=============================================================================================//
property date_property;
    @(negedge clk) ( inf.date_valid===1|->((inf.D.d_date[0].M === 1 || inf.D.d_date[0].M === 3 || inf.D.d_date[0].M === 5 || inf.D.d_date[0].M === 7 || inf.D.d_date[0].M === 8 || inf.D.d_date[0].M === 10 || inf.D.d_date[0].M === 12)&&(1 <= inf.D.d_date[0].D && inf.D.d_date[0].D <= 31))||
                     ((inf.D.d_date[0].M === 4 || inf.D.d_date[0].M === 6 || inf.D.d_date[0].M === 9 || inf.D.d_date[0].M === 11 )&&(1 <= inf.D.d_date[0].D && inf.D.d_date[0].D <= 30))||
                     ((inf.D.d_date[0].M === 2)&&(1 <= inf.D.d_date[0].D && inf.D.d_date[0].D <= 28))   
                    );
endproperty
date_check:assert property(date_property)else $fatal(0,"Assertion 8 is violated");

//=============================================================================================//
//Assertion9: The AR_VALID signal should not overlap with the AW_VALID signal.                                       
//=============================================================================================//
logic [1:0]A_valid_sum;
assign A_valid_sum=inf.AR_VALID+inf.AW_VALID;
property A_VALID_property;
    @(posedge clk)(A_valid_sum<=1);
endproperty
A_VALID_check:assert property(A_VALID_property)else $fatal(0,"Assertion 9 is violated");



endmodule