module ChooseBestRice (
    input wire iClock,
    input wire iEnable, 
    input wire iReset, 

    input wire signed [16:0] iRE_BU_0,
    input wire signed [16:0] iRE_BU_1,
    input wire signed [16:0] iRE_BU_2,
    input wire signed [16:0] iRE_BU_3,
    input wire signed [16:0] iRE_BU_4,
    input wire signed [16:0] iRE_BU_5,
    input wire signed [16:0] iRE_BU_6,
    input wire signed [16:0] iRE_BU_7,
    input wire signed [16:0] iRE_BU_8,
    input wire signed [16:0] iRE_BU_9,
    input wire signed [16:0] iRE_BU_10,
    input wire signed [16:0] iRE_BU_11,
    input wire signed [16:0] iRE_BU_12,
    input wire signed [16:0] iRE_BU_13,
    input wire signed [16:0] iRE_BU_14,
    output wire [3:0] oBest
    );

reg [3:0] best;
assign oBest = best;
reg [27:0] Total_BU_0;
reg [27:0] Total_BU_1;
reg [27:0] Total_BU_2;
reg [27:0] Total_BU_3;
reg [27:0] Total_BU_4;
reg [27:0] Total_BU_5;
reg [27:0] Total_BU_6;
reg [27:0] Total_BU_7;
reg [27:0] Total_BU_8;
reg [27:0] Total_BU_9;
reg [27:0] Total_BU_10;
reg [27:0] Total_BU_11;
reg [27:0] Total_BU_12;
reg [27:0] Total_BU_13;
reg [27:0] Total_BU_14;


always @(posedge iClock) begin
    if (iReset) begin
        best <= 0;

        Total_BU_0 <= 0;
        Total_BU_1 <= 0;
        Total_BU_2 <= 0;
        Total_BU_3 <= 0;
        Total_BU_4 <= 0;
        Total_BU_5 <= 0;
        Total_BU_6 <= 0;
        Total_BU_7 <= 0;
        Total_BU_8 <= 0;
        Total_BU_9 <= 0;
        Total_BU_10 <= 0;
        Total_BU_11 <= 0;
        Total_BU_12 <= 0;
        Total_BU_13 <= 0;
        Total_BU_14 <= 0;
   end else if (iEnable) begin
        Total_BU_0 <= Total_BU_0 + iRE_BU_0;
        Total_BU_1 <= Total_BU_1 + iRE_BU_1;
        Total_BU_2 <= Total_BU_2 + iRE_BU_2;
        Total_BU_3 <= Total_BU_3 + iRE_BU_3;
        Total_BU_4 <= Total_BU_4 + iRE_BU_4;
        Total_BU_5 <= Total_BU_5 + iRE_BU_5;
        Total_BU_6 <= Total_BU_6 + iRE_BU_6;
        Total_BU_7 <= Total_BU_7 + iRE_BU_7;
        Total_BU_8 <= Total_BU_8 + iRE_BU_8;
        Total_BU_9 <= Total_BU_9 + iRE_BU_9;
        Total_BU_10 <= Total_BU_10 + iRE_BU_10;
        Total_BU_11 <= Total_BU_11 + iRE_BU_11;
        Total_BU_12 <= Total_BU_12 + iRE_BU_12;
        Total_BU_13 <= Total_BU_13 + iRE_BU_13;
        Total_BU_14 <= Total_BU_14 + iRE_BU_14;

        /* Maybe optimize below into one comparator */

        if (
         Total_BU_0  <  Total_BU_1  &&
         Total_BU_0  <  Total_BU_2  &&
         Total_BU_0  <  Total_BU_3  &&
         Total_BU_0  <  Total_BU_4  &&
         Total_BU_0  <  Total_BU_5  &&
         Total_BU_0  <  Total_BU_6  &&
         Total_BU_0  <  Total_BU_7  &&
         Total_BU_0  <  Total_BU_8  &&
         Total_BU_0  <  Total_BU_9  &&
         Total_BU_0  <  Total_BU_10  &&
         Total_BU_0  <  Total_BU_11  &&
         Total_BU_0  <  Total_BU_12  &&
         Total_BU_0  <  Total_BU_13  &&
         Total_BU_0  <  Total_BU_14 ) best <= 4'd0;

        if (
         Total_BU_1  <  Total_BU_0  &&
         Total_BU_1  <  Total_BU_2  &&
         Total_BU_1  <  Total_BU_3  &&
         Total_BU_1  <  Total_BU_4  &&
         Total_BU_1  <  Total_BU_5  &&
         Total_BU_1  <  Total_BU_6  &&
         Total_BU_1  <  Total_BU_7  &&
         Total_BU_1  <  Total_BU_8  &&
         Total_BU_1  <  Total_BU_9  &&
         Total_BU_1  <  Total_BU_10  &&
         Total_BU_1  <  Total_BU_11  &&
         Total_BU_1  <  Total_BU_12  &&
         Total_BU_1  <  Total_BU_13  &&
         Total_BU_1  <  Total_BU_14 ) best <= 4'd1;

        if (
         Total_BU_2  <  Total_BU_0  &&
         Total_BU_2  <  Total_BU_1  &&
         Total_BU_2  <  Total_BU_3  &&
         Total_BU_2  <  Total_BU_4  &&
         Total_BU_2  <  Total_BU_5  &&
         Total_BU_2  <  Total_BU_6  &&
         Total_BU_2  <  Total_BU_7  &&
         Total_BU_2  <  Total_BU_8  &&
         Total_BU_2  <  Total_BU_9  &&
         Total_BU_2  <  Total_BU_10  &&
         Total_BU_2  <  Total_BU_11  &&
         Total_BU_2  <  Total_BU_12  &&
         Total_BU_2  <  Total_BU_13  &&
         Total_BU_2  <  Total_BU_14 ) best <= 4'd2;

        if (
         Total_BU_3  <  Total_BU_0  &&
         Total_BU_3  <  Total_BU_1  &&
         Total_BU_3  <  Total_BU_2  &&
         Total_BU_3  <  Total_BU_4  &&
         Total_BU_3  <  Total_BU_5  &&
         Total_BU_3  <  Total_BU_6  &&
         Total_BU_3  <  Total_BU_7  &&
         Total_BU_3  <  Total_BU_8  &&
         Total_BU_3  <  Total_BU_9  &&
         Total_BU_3  <  Total_BU_10  &&
         Total_BU_3  <  Total_BU_11  &&
         Total_BU_3  <  Total_BU_12  &&
         Total_BU_3  <  Total_BU_13  &&
         Total_BU_3  <  Total_BU_14 ) best <= 4'd3;

        if (
         Total_BU_4  <  Total_BU_0  &&
         Total_BU_4  <  Total_BU_1  &&
         Total_BU_4  <  Total_BU_2  &&
         Total_BU_4  <  Total_BU_3  &&
         Total_BU_4  <  Total_BU_5  &&
         Total_BU_4  <  Total_BU_6  &&
         Total_BU_4  <  Total_BU_7  &&
         Total_BU_4  <  Total_BU_8  &&
         Total_BU_4  <  Total_BU_9  &&
         Total_BU_4  <  Total_BU_10  &&
         Total_BU_4  <  Total_BU_11  &&
         Total_BU_4  <  Total_BU_12  &&
         Total_BU_4  <  Total_BU_13  &&
         Total_BU_4  <  Total_BU_14 ) best <= 4'd4;

        if (
         Total_BU_5  <  Total_BU_0  &&
         Total_BU_5  <  Total_BU_1  &&
         Total_BU_5  <  Total_BU_2  &&
         Total_BU_5  <  Total_BU_3  &&
         Total_BU_5  <  Total_BU_4  &&
         Total_BU_5  <  Total_BU_6  &&
         Total_BU_5  <  Total_BU_7  &&
         Total_BU_5  <  Total_BU_8  &&
         Total_BU_5  <  Total_BU_9  &&
         Total_BU_5  <  Total_BU_10  &&
         Total_BU_5  <  Total_BU_11  &&
         Total_BU_5  <  Total_BU_12  &&
         Total_BU_5  <  Total_BU_13  &&
         Total_BU_5  <  Total_BU_14 ) best <= 4'd5;

        if (
         Total_BU_6  <  Total_BU_0  &&
         Total_BU_6  <  Total_BU_1  &&
         Total_BU_6  <  Total_BU_2  &&
         Total_BU_6  <  Total_BU_3  &&
         Total_BU_6  <  Total_BU_4  &&
         Total_BU_6  <  Total_BU_5  &&
         Total_BU_6  <  Total_BU_7  &&
         Total_BU_6  <  Total_BU_8  &&
         Total_BU_6  <  Total_BU_9  &&
         Total_BU_6  <  Total_BU_10  &&
         Total_BU_6  <  Total_BU_11  &&
         Total_BU_6  <  Total_BU_12  &&
         Total_BU_6  <  Total_BU_13  &&
         Total_BU_6  <  Total_BU_14 ) best <= 4'd6;

        if (
         Total_BU_7  <  Total_BU_0  &&
         Total_BU_7  <  Total_BU_1  &&
         Total_BU_7  <  Total_BU_2  &&
         Total_BU_7  <  Total_BU_3  &&
         Total_BU_7  <  Total_BU_4  &&
         Total_BU_7  <  Total_BU_5  &&
         Total_BU_7  <  Total_BU_6  &&
         Total_BU_7  <  Total_BU_8  &&
         Total_BU_7  <  Total_BU_9  &&
         Total_BU_7  <  Total_BU_10  &&
         Total_BU_7  <  Total_BU_11  &&
         Total_BU_7  <  Total_BU_12  &&
         Total_BU_7  <  Total_BU_13  &&
         Total_BU_7  <  Total_BU_14 ) best <= 4'd7;

        if (
         Total_BU_8  <  Total_BU_0  &&
         Total_BU_8  <  Total_BU_1  &&
         Total_BU_8  <  Total_BU_2  &&
         Total_BU_8  <  Total_BU_3  &&
         Total_BU_8  <  Total_BU_4  &&
         Total_BU_8  <  Total_BU_5  &&
         Total_BU_8  <  Total_BU_6  &&
         Total_BU_8  <  Total_BU_7  &&
         Total_BU_8  <  Total_BU_9  &&
         Total_BU_8  <  Total_BU_10  &&
         Total_BU_8  <  Total_BU_11  &&
         Total_BU_8  <  Total_BU_12  &&
         Total_BU_8  <  Total_BU_13  &&
         Total_BU_8  <  Total_BU_14 ) best <= 4'd8;

        if (
         Total_BU_9  <  Total_BU_0  &&
         Total_BU_9  <  Total_BU_1  &&
         Total_BU_9  <  Total_BU_2  &&
         Total_BU_9  <  Total_BU_3  &&
         Total_BU_9  <  Total_BU_4  &&
         Total_BU_9  <  Total_BU_5  &&
         Total_BU_9  <  Total_BU_6  &&
         Total_BU_9  <  Total_BU_7  &&
         Total_BU_9  <  Total_BU_8  &&
         Total_BU_9  <  Total_BU_10  &&
         Total_BU_9  <  Total_BU_11  &&
         Total_BU_9  <  Total_BU_12  &&
         Total_BU_9  <  Total_BU_13  &&
         Total_BU_9  <  Total_BU_14 ) best <= 4'd9;

        if (
         Total_BU_10  <  Total_BU_0  &&
         Total_BU_10  <  Total_BU_1  &&
         Total_BU_10  <  Total_BU_2  &&
         Total_BU_10  <  Total_BU_3  &&
         Total_BU_10  <  Total_BU_4  &&
         Total_BU_10  <  Total_BU_5  &&
         Total_BU_10  <  Total_BU_6  &&
         Total_BU_10  <  Total_BU_7  &&
         Total_BU_10  <  Total_BU_8  &&
         Total_BU_10  <  Total_BU_9  &&
         Total_BU_10  <  Total_BU_11  &&
         Total_BU_10  <  Total_BU_12  &&
         Total_BU_10  <  Total_BU_13  &&
         Total_BU_10  <  Total_BU_14 ) best <= 4'd10;

        if (
         Total_BU_11  <  Total_BU_0  &&
         Total_BU_11  <  Total_BU_1  &&
         Total_BU_11  <  Total_BU_2  &&
         Total_BU_11  <  Total_BU_3  &&
         Total_BU_11  <  Total_BU_4  &&
         Total_BU_11  <  Total_BU_5  &&
         Total_BU_11  <  Total_BU_6  &&
         Total_BU_11  <  Total_BU_7  &&
         Total_BU_11  <  Total_BU_8  &&
         Total_BU_11  <  Total_BU_9  &&
         Total_BU_11  <  Total_BU_10  &&
         Total_BU_11  <  Total_BU_12  &&
         Total_BU_11  <  Total_BU_13  &&
         Total_BU_11  <  Total_BU_14 ) best <= 4'd11;

        if (
         Total_BU_12  <  Total_BU_0  &&
         Total_BU_12  <  Total_BU_1  &&
         Total_BU_12  <  Total_BU_2  &&
         Total_BU_12  <  Total_BU_3  &&
         Total_BU_12  <  Total_BU_4  &&
         Total_BU_12  <  Total_BU_5  &&
         Total_BU_12  <  Total_BU_6  &&
         Total_BU_12  <  Total_BU_7  &&
         Total_BU_12  <  Total_BU_8  &&
         Total_BU_12  <  Total_BU_9  &&
         Total_BU_12  <  Total_BU_10  &&
         Total_BU_12  <  Total_BU_11  &&
         Total_BU_12  <  Total_BU_13  &&
         Total_BU_12  <  Total_BU_14 ) best <= 4'd12;

        if (
         Total_BU_13  <  Total_BU_0  &&
         Total_BU_13  <  Total_BU_1  &&
         Total_BU_13  <  Total_BU_2  &&
         Total_BU_13  <  Total_BU_3  &&
         Total_BU_13  <  Total_BU_4  &&
         Total_BU_13  <  Total_BU_5  &&
         Total_BU_13  <  Total_BU_6  &&
         Total_BU_13  <  Total_BU_7  &&
         Total_BU_13  <  Total_BU_8  &&
         Total_BU_13  <  Total_BU_9  &&
         Total_BU_13  <  Total_BU_10  &&
         Total_BU_13  <  Total_BU_11  &&
         Total_BU_13  <  Total_BU_12  &&
         Total_BU_13  <  Total_BU_14 ) best <= 4'd13;

        if (
         Total_BU_14  <  Total_BU_0  &&
         Total_BU_14  <  Total_BU_1  &&
         Total_BU_14  <  Total_BU_2  &&
         Total_BU_14  <  Total_BU_3  &&
         Total_BU_14  <  Total_BU_4  &&
         Total_BU_14  <  Total_BU_5  &&
         Total_BU_14  <  Total_BU_6  &&
         Total_BU_14  <  Total_BU_7  &&
         Total_BU_14  <  Total_BU_8  &&
         Total_BU_14  <  Total_BU_9  &&
         Total_BU_14  <  Total_BU_10  &&
         Total_BU_14  <  Total_BU_11  &&
         Total_BU_14  <  Total_BU_12  &&
         Total_BU_14  <  Total_BU_13 ) best <= 4'd14;

    end
end
endmodule
