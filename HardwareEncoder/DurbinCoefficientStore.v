

module DurbinCoefficientStore (
    input wire iClock,
    input wire iEnable, 
    input wire iReset, 
    input wire iLoad,
    input wire [3:0] iM, 
    input wire [11:0] iCoeff, 
        
    output wire iUnload,
    input wire [3:0] iBestM, 
    output wire [11:0] oCoeff
    );


reg [11:0] 