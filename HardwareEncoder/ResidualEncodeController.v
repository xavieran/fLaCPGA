

module ResidualEncodeController (
    input wire iClock,
    input wire iEnable, 
    input wire iReset,
    
    input [15:0] iMSB,
    input [15:0] iLSB,
    input [3:0] iRiceParam,
    
    output [15:0] oRamWriteAddress, 
    output [15:0] oRamData,
    output [15:0] oRamWE
    );

