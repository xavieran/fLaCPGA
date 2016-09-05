
module FIR_FilterBank (
    input iClock, 
    input iEnable, 
    input iReset,
    
    input iLoad,
    input [3:0] iM,
    input [11:0] iCoeff,
    
    input iValid, 
    input signed [15:0] iSample, 
    
    output signed [15:0] oResidual,
    output oValid
    );

FIR12 f12 (
    .iEnable(iEnable),
    .iClock(iClock),
    .iReset(iReset),
    .iLoad(iLoad), 
    .iQLP(iCoeff),
    .iValid(iValid),
    .iSample(iSample),
    .oResidual(oResidual),
    .oValid(oValid)
    );


endmodule