`ifndef DUAL_WRITE_RAM_H
`define DUAL_WRITE_RAM_H

module dual_write_ram(
    input wire iClock,
    
    input wire [15:0] iData1,
    input wire [15:0] iData2, 
    
    input wire [15:0] iWriteAddress1,
    input wire [15:0] iWriteAddress2,
           
    input wire [15:0] iReadAddress1, 
    input wire [15:0] iReadAddress2,
    
    input wire iWE1,
    input wire iWE2,

    output reg [15:0] oData1, 
    output reg [15:0] oData2
    );

reg [15:0] memory [0:8191];

always @(posedge iClock) begin
    if (iWE1)
        memory[iWriteAddress1] <= iData1;

    oData1 <= memory[iReadAddress1];
end

always @(posedge iClock) begin
    if (iWE2)
        memory[iWriteAddress2] <= iData2;
        
    oData2 <= memory[iReadAddress2];
end

endmodule
`endif