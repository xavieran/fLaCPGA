//`default_nettype none

`ifndef ALPHA_CALC2_H
`define ALPHA_CALC2_H

`define DFP(X) $bitstoshortreal(X)

module AlphaCalculator2 (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input wire iValid,
    
    input wire [3:0] iM,
    input wire [31:0] iACF1,
    input wire [31:0] iACF2,
    input wire [31:0] iModel1,
    input wire [31:0] iModel2,
    
    output wire [31:0] oAlpha,
    output wire oDone
    );

integer i;

parameter S_CALC_PART_SUMS = 0;
parameter S_ADD_PHASE1 = 1;
parameter S_ADD_PHASE2 = 2;
parameter S_ADD_PHASE3 = 3;
parameter S_DONE = 4;

parameter ORDER = 12;
parameter MULT_LATENCY = 5;
parameter ADD_LATENCY = 7;
parameter TOTAL_LATENCY = MULT_LATENCY + ADD_LATENCY;

//Valid;
reg done;

reg rValid;

reg [5:0] phase_count;

reg [31:0] alpha;
reg [31:0] rACF1, rACF2, rModel1, rModel2;
reg [31:0] partial_sums [0:5];

reg [3:0] state;

assign oAlpha = alpha;
assign oDone = done;

wire [31:0] m1_out, m2_out, a1_out, a2_out;

wire mult_en = iEnable;
wire a1_en = iEnable;
wire a2_en = iEnable;

reg [31:0] a1_in1, a1_in2, a2_in1, a2_in2;
reg add_partial_sums;


fp_mult m1 (
    .clk_en(mult_en),
    .clock(iClock),
    .dataa(rACF2),
    .datab(rModel1),
    .nan(),
    .result(m1_out));

fp_mult m2 (
    .clk_en(mult_en),
    .clock(iClock),
    .dataa(rACF1),
    .datab(rModel2),
    .nan(),
    .result(m2_out));

fp_add_sub a1 (
    .add_sub(1'b1),
    .clk_en(a1_en),
    .clock(iClock),
    .dataa(a1_in1),
    .datab(a1_in2),
    .result(a1_out));

fp_add_sub a2 (
    .add_sub(1'b1),
    .clk_en(a2_en),
    .clock(iClock),
    .dataa(a2_in1),
    .datab(a2_in2),
    .result(a2_out));

// 3f800000 1.0

always @(posedge iClock) begin
    if (iReset) begin
        done <= 0;
        alpha <= 0;
        rACF1 <= 0;
        rACF2 <= 0;
        rModel1 <= 0;
        rModel2 <= 0;
        rValid <= 0;
        partial_sums[0] <= 0;
        phase_count <= 0;
        state <= S_CALC_PART_SUMS;
       
    end else if (iEnable) begin
        rACF1 <= iValid ? iACF1 : 0;
        rACF2 <= iValid ? iACF2 : 0;
        rModel1 <= iValid ? iModel1 : 0;
        rModel2 <= iValid ? iModel2 : 0;
        rValid <= iValid;
        
        /*
        if (rValid) begin
           $display("ALPHA::%d :: %f*%f +%f*%f",iM, `DFP(rModel1), `DFP(rACF2), `DFP(rModel2), `DFP(rACF1));
        end
        */
        
        case (state) 
        S_CALC_PART_SUMS:
        begin
            a1_in1 <= m1_out;
            a1_in2 <= m2_out;
            
            phase_count <= phase_count + 1'b1;
            
            for (i = 5; i > 0; i = i - 1)
                partial_sums[i] <= partial_sums[i-1];
            partial_sums[0] <= a1_out;
            
            if (phase_count == TOTAL_LATENCY + 7) begin
                if (iM == 1) begin
                    alpha <= partial_sums[4];
                    state <= S_DONE;
                end else begin
                    state <= S_ADD_PHASE1;
                    phase_count <= 0;   
                end
            end
        end
        
        S_ADD_PHASE1:
        begin
            phase_count <= phase_count + 1'b1;
            
            a1_in1 <= partial_sums[5]; // a + 
            a1_in2 <= partial_sums[4]; // b
            a2_in1 <= partial_sums[3]; // c + 
            a2_in2 <= partial_sums[2]; // d
            
            
            if (phase_count == ADD_LATENCY + 1) begin
                if (iM == 2 || iM == 3) begin
                    alpha <= a1_out;
                    state <= S_DONE;
                end else begin
                    state <= S_ADD_PHASE2;
                    phase_count <= 0;
                    
                    partial_sums[5] <= a1_out; // x
                    partial_sums[4] <= a2_out; // y
                end
            end
        end
        
        S_ADD_PHASE2:
        begin    
        
            phase_count <= phase_count + 1'b1;
            a1_in1 <= partial_sums[5]; // x +
            a1_in2 <= partial_sums[4]; // y
            a2_in1 <= partial_sums[1]; // e + 
            a2_in2 <= partial_sums[0]; // f
            
            if (phase_count == ADD_LATENCY + 1) begin
                if (iM == 4 || iM == 5 || iM == 6 || iM == 7) begin
                    alpha <= a1_out;
                    state <= S_DONE;
                end else begin
                    state <= S_ADD_PHASE3;
                    phase_count <= 0;
                    partial_sums[5] <= a1_out; // k
                    partial_sums[4] <= a2_out; // z
                end
            end
        end
        
        S_ADD_PHASE3:
        begin            
            phase_count <= phase_count + 1'b1;
            a1_in1 <= partial_sums[5]; // k +
            a1_in2 <= partial_sums[4]; // z
            a2_in1 <= 0;
            a2_in2 <= 0;
            
            if (phase_count == ADD_LATENCY + 1) begin
                if (iM == 8 || iM == 9 || iM == 10 || iM == 11) begin
                    alpha <= a1_out;
                    state <= S_DONE;
                end
            end
        end
        
        S_DONE:
        begin
            done <= 1'b1;
        end
        
        default:
        begin
            done <= 1'b1;
        end
        
        endcase
        
    end 
end



endmodule
        
        
`endif