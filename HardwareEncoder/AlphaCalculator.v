//`default_nettype none

`ifndef ALPHA_CALC_H
`define ALPHA_CALC_H

`define DFP(X) $bitstoshortreal(X)

module AlphaCalculator (
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
parameter ORDER = 12;
parameter MULT_LATENCY = 5;
parameter ADD_LATENCY = 7;
parameter TOTAL_LATENCY = MULT_LATENCY + ADD_LATENCY;

//Valid;
reg done;

reg rValid;
reg [31:0] dValid;
reg [3:0] input_count;


reg [31:0] alpha;

reg [31:0] rACF1, rACF2, rModel1, rModel2;



reg [31:0] partial_sums_stage1a [0:3];
reg [31:0] partial_sums_stage1b [0:3];

reg [31:0] partial_sums_stage2a [0:1];
reg [31:0] partial_sums_stage2b [0:1];

reg [31:0] partial_sums_stage3a;
reg [31:0] partial_sums_stage3b;

reg [3:0] stage;

reg [2:0] stage2_in_sel;
reg [1:0] stage3_in_sel;

reg [31:0] stage2_add_count;
reg [31:0] stage3_add_count;
reg [31:0] stage4_add_count;

reg flip;


reg [31:0] a2_i1, a2_i2, a2_i1_s2, a2_i1_s3, a2_i2_s2, a2_i2_s3;

assign oAlpha = alpha;
assign oDone = done;

wire [31:0] m1_out, m2_out, a1_out, a2_out;

wire s2Valid = stage2_in_sel < ((input_count + 1'b1) >> 1);
wire s3Valid = stage3_in_sel < 1; // ???

wire mult_en = iEnable;
wire a1_en = iEnable;
wire a2_en = iEnable;

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
    .dataa(m1_out),
    .datab(m2_out),
    .result(a1_out));

fp_add_sub a2 (
    .add_sub(1'b1),
    .clk_en(a2_en),
    .clock(iClock),
    .dataa(a2_i1),
    .datab(a2_i2),
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
        dValid <= 0;
        input_count <= 0;
        
        for (i = 3; i >= 0; i = i - 1) begin
            partial_sums_stage1a[i] <= 0;
            partial_sums_stage1b[i] <= 0;
        end
        
        for (i = 1; i >= 0; i = i - 1) begin
            partial_sums_stage2a[i] <= 0;
            partial_sums_stage2b[i] <= 0;
        end
        
        
        partial_sums_stage3a <= 0;
        partial_sums_stage3b <= 0;
        
        flip <= 0;
        
        
        stage <= 0;
        stage2_in_sel <= 0;
        stage3_in_sel <= 0;
        stage2_add_count <= 1;
        stage3_add_count <= 1;
        stage4_add_count <= 1;
        
       
    end else if (iEnable) begin
        rACF1 <= iACF1;
        rACF2 <= iACF2;
        rModel1 <= iModel1;
        rModel2 <= iModel2;
        rValid <= iValid;
        
        if (rValid) begin
            input_count <= input_count + 1'b1;
            $display("ALPHA::%d :: %f*%f +%f*%f",iM, `DFP(rModel1), `DFP(rACF2), `DFP(rModel2), `DFP(rACF1));
        end else begin
            input_count <= input_count;
        end
        
        dValid = (dValid << 1) | rValid;
        
        // If the data out of the first adder is valid, then shift it down
        if (dValid[TOTAL_LATENCY]) begin
        
            if (flip) begin
                flip <= 0;
                for (i = 3; i > 0; i = i - 1) begin
                    partial_sums_stage1a[i] <= partial_sums_stage1a[i - 1];
                end
                partial_sums_stage1a[0] <= a1_out;
            end else begin
                flip <= 1;
                for (i = 3; i > 0; i = i - 1) begin
                    partial_sums_stage1b[i] <= partial_sums_stage1b[i - 1];
                end
                partial_sums_stage1b[0] <= a1_out;
            end
            
            // On falling edge o
            if (dValid[TOTAL_LATENCY:TOTAL_LATENCY-1] == 2'b10) begin
                stage <= 1;
            end 
            
        end else if (stage == 1) begin
            /* Start counting in the next to be added */
            if (s2Valid) begin
                stage2_in_sel <= stage2_in_sel + 1'b1;
            end
            
            stage2_add_count <= (stage2_add_count << 1) | s2Valid;
            
            /* Start saving them into the next stage*/
            if (stage2_add_count[ADD_LATENCY - 1]) begin
                if (flip) begin
                    flip <= 0;
                    partial_sums_stage2a[1] <= partial_sums_stage2a[0];
                    partial_sums_stage2a[0] <= a2_out;
                end else begin
                    flip <= 1;
                    partial_sums_stage2b[1] <= partial_sums_stage2b[0];
                    partial_sums_stage2b[0] <= a2_out;
                end
            end
            
            // On falling edge of valid signal, we move to next stage
            if (stage2_add_count[ADD_LATENCY-1:ADD_LATENCY - 2] == 2'b10) begin
                stage <= 2;
            end
            
        end else if (stage == 2) begin
            /* Start counting in the next to be added */
            if (s3Valid) begin
                stage3_in_sel <= stage3_in_sel + 1'b1;
            end
            
            stage3_add_count <= (stage3_add_count << 1) | s3Valid;
            
            /* Start saving them into the next stage*/
            if (stage3_add_count[ADD_LATENCY]) begin
                if (flip) begin
                    flip <= 0;
                    partial_sums_stage3a <= a2_out;
                end else begin
                    flip <= 1;
                    partial_sums_stage3b <= a2_out;
                end
            end
            
            // On falling edge of valid signal, we move to next stage
            if (stage3_add_count[ADD_LATENCY:ADD_LATENCY - 1] == 2'b10) begin
                stage <= 3;
            end
            
        end else if (stage == 3) begin
            stage4_add_count <= (stage4_add_count << 1);
            /* Start saving them into the next stage*/
            if (stage4_add_count[ADD_LATENCY]) begin
                alpha <= a2_out;
                done <= 1'b1;
                stage <= 4;
            end 
        end
    end 
end




always @(stage or a2_i1_s2 or a2_i1_s3 or partial_sums_stage3a) begin
    if (stage == 1) begin
        a2_i1 <= a2_i1_s2;
    end else if (stage == 2) begin
        a2_i1 <= a2_i1_s3;
    end else if (stage == 3) begin
        a2_i1 <= partial_sums_stage3a;
    end else begin
        a2_i1 <= 0;
    end
end

always @(stage or a2_i2_s2 or a2_i2_s3 or partial_sums_stage3b) begin
    if (stage == 1) begin
        a2_i2 <= a2_i2_s2;
    end else if (stage == 2) begin
        a2_i2 <= a2_i2_s3;
    end else if (stage == 3) begin
        a2_i2 <= partial_sums_stage3b;
    end else begin
        a2_i2 <= 0;
    end
end

/* Muxes for second stage adder input */
always @(stage2_in_sel or partial_sums_stage1a) begin
    if (stage2_in_sel < 4) begin
        a2_i1_s2 <= partial_sums_stage1a[stage2_in_sel];
    end else begin
        a2_i1_s2 <= 0;
    end
end

always @(stage2_in_sel or partial_sums_stage1b) begin
    if (stage2_in_sel < 4) begin
        a2_i2_s2 <= partial_sums_stage1b[stage2_in_sel];
    end else begin
        a2_i2_s2 <= 0;
    end
end

/* Muxes for third stage adder input */
always @(stage3_in_sel or partial_sums_stage2a) begin
    if (stage3_in_sel == 0) begin
        a2_i1_s3 <= partial_sums_stage2a[0];
    end else if (stage3_in_sel == 1) begin
        a2_i1_s3 <= partial_sums_stage2a[1];
    end else begin
        a2_i1_s3 <= 0;
    end 
end

always @(stage3_in_sel or partial_sums_stage2b) begin
    if (stage3_in_sel == 0) begin
        a2_i2_s3 <= partial_sums_stage2b[0];
    end else if (stage3_in_sel == 1) begin
        a2_i2_s3 <= partial_sums_stage2b[1];
    end else begin
        a2_i2_s3 <= 0;
    end
end


endmodule
        
        
`endif