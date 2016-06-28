 
`timescale 1ns / 100ps

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end

module FixedEncoderOrder2TB;
  reg    iEnable;
  reg    iReset;
  reg    iClock;
  reg signed  [15:0] iSample;
  wire  signed [15:0] oResidual;
  
  FixedEncoderOrder2
   DUT  ( 
       .iEnable (iEnable ) ,
      .iReset (iReset ) ,
      .oResidual (oResidual ) ,
      .iClock (iClock ) ,
      .iSample (iSample)); 
  
  always
  begin
    #10 iClock = !iClock;
  end

  initial
  begin
        #0 iClock = 0; iEnable = 0; iReset = 1; iSample = 0;
        #10
        #20 iReset = 1; 
        #20 iReset = 0; iEnable = 1; 
            iSample = 20;
        #20 iSample = 10;
        #20 iSample = -7;
        #20 iSample = -4;
        #20 iSample = 8;
        #20 iSample = 0;
        #20 iSample = 2;
        #20 iSample = -3;
        #20 iSample = 1;
        #20 iSample = 0;
        #20;
        #20;
        #20;
        #20;
        #20;
        #20;
        #20;
        #20;
        #20 $stop;
  end
  /* -38, -18, 59, -47, 33, -30, 20, -7, 1 */
  
endmodule
