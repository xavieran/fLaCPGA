module register_file(
    input iClock,
    
    input [31:0] iData1,
    input [31:0] iData2, 
    
    input [3:0] iWriteAddress1,
    input [3:0] iWriteAddress2,
           
    input [3:0] iReadAddress1, 
    input [3:0] iReadAddress2,
    
    input iWE1,
    input iWE2,

    output reg [31:0] oData1, 
    output reg [31:0] oData2
    );

reg [31:0] memory [0:15];

always @(posedge iClock) begin
    if (iWE1)
        memory[iWriteAddress1] <= iData1;

    if (iWE1 && iWriteAddress1 == iReadAddress1)
        oData1 <= iData1;
    else
        oData1 <= memory[iReadAddress1];
end

always @(posedge iClock) begin
    if (iWE2)
        memory[iWriteAddress2] <= iData2;

    if (iWE2 && iWriteAddress2 == iReadAddress2)
        oData2 <= iData2;
    else
        oData2 <= memory[iReadAddress2];
end

endmodule