
module Compare12(
    input wire iClock,
    input wire iEnable,
    
    input wire [27:0]  iIn0,
    input wire [27:0]  iIn1,
    input wire [27:0]  iIn2,
    input wire [27:0]  iIn3,
    input wire [27:0]  iIn4,
    input wire [27:0]  iIn5,
    input wire [27:0]  iIn6,
    input wire [27:0]  iIn7,
    input wire [27:0]  iIn8,
    input wire [27:0]  iIn9,
    input wire [27:0]  iIn10,
    input wire [27:0]  iIn11,
    output wire [3:0] oMinimum);

reg [3:0] index0_0;
reg [3:0] index0_1;
reg [3:0] index0_2;
reg [3:0] index0_3;
reg [3:0] index0_4;
reg [3:0] index0_5;
reg [3:0] index1_0;
reg [3:0] index1_1;
reg [3:0] index1_2;
reg [3:0] index2_0;
reg [3:0] rindex2_1;
reg [3:0] index3_0;
reg [27:0] value0_0;
reg [27:0] value0_1;
reg [27:0] value0_2;
reg [27:0] value0_3;
reg [27:0] value0_4;
reg [27:0] value0_5;
reg [27:0] value1_0;
reg [27:0] value1_1;
reg [27:0] value1_2;
reg [27:0] value2_0;
reg [27:0] rvalue2_1;
reg [27:0] value3_0;

assign oMinimum =  index3_0 ;

always @(posedge iClock) begin
    if (iEnable) begin
    value0_0 <= (iIn0 < iIn1) ? iIn0 : iIn1;
    index0_0 <= (iIn0 < iIn1) ? 0 : 1;
    value0_1 <= (iIn2 < iIn3) ? iIn2 : iIn3;
    index0_1 <= (iIn2 < iIn3) ? 2 : 3;
    value0_2 <= (iIn4 < iIn5) ? iIn4 : iIn5;
    index0_2 <= (iIn4 < iIn5) ? 4 : 5;
    value0_3 <= (iIn6 < iIn7) ? iIn6 : iIn7;
    index0_3 <= (iIn6 < iIn7) ? 6 : 7;
    value0_4 <= (iIn8 < iIn9) ? iIn8 : iIn9;
    index0_4 <= (iIn8 < iIn9) ? 8 : 9;
    value0_5 <= (iIn10 < iIn11) ? iIn10 : iIn11;
    index0_5 <= (iIn10 < iIn11) ? 10 : 11;
    value1_0 <= (value0_0 < value0_1) ? value0_0 : value0_1;
    index1_0 <= (value0_0 < value0_1) ? index0_0 : index0_1;
    value1_1 <= (value0_2 < value0_3) ? value0_2 : value0_3;
    index1_1 <= (value0_2 < value0_3) ? index0_2 : index0_3;
    value1_2 <= (value0_4 < value0_5) ? value0_4 : value0_5;
    index1_2 <= (value0_4 < value0_5) ? index0_4 : index0_5;
    value2_0 <= (value1_0 < value1_1) ? value1_0 : value1_1;
    index2_0 <= (value1_0 < value1_1) ? index1_0 : index1_1;
    rvalue2_1 <= value1_2;
    rindex2_1 <= index1_2;
    value3_0 <= (value2_0 < rvalue2_1) ? value2_0 : rvalue2_1;
    index3_0 <= (value2_0 < rvalue2_1) ? index2_0 : rindex2_1;

    end
end

endmodule

