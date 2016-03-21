
`timescale 1ns / 1ns
module FixedDecoderTB   ; 
 
  reg    iEnable   ; 
  reg    iReset   ; 
  wire  signed [31:0]  oData   ; 
  reg  [7:0] iOrder   ; 
  reg    iClock   ; 
  reg signed  [31:0]  iSample   ; 
  FixedDecoder  
   DUT  ( 
       .iEnable (iEnable ) ,
      .iReset (iReset ) ,
      .oData (oData ) ,
      .iOrder (iOrder ) ,
      .iClock (iClock ) ,
      .iSample (iSample ) ); 
  
  always
  begin
    #10 iClock = !iClock;
  end

  initial
  begin
		#0 iClock = 0;
		#20 iReset = 1;
		#20 iReset = 0; iEnable = 1;
		#20 iOrder = 0; iSample = 10;
		#20 iSample = -7;
		#20 iSample = -4;
		#20 iSample = 8;
		#20 iEnable = 0;
		#20 iSample = 2;
		#20 iSample = -3;
		#20 iSample = 1;
		#20 iSample = 0;
		
		#20 iReset = 1;
		#20 iReset = 0; iEnable = 1;
		#20 iOrder = 1; iSample = 10;
		#20 iSample = -7;
		#20 iSample = -4;
		#20 iSample = 8;
		#20 iEnable = 0;
		#20 iSample = 2;
		#20 iSample = -3;
		#20 iSample = 1;
		#20 iSample = 0;
		
		#20 iReset = 1;
		#20 iReset = 0; iEnable = 1;
		#20 iOrder = 2; iSample = 10;
		#20 iSample = -7;
		#20 iSample = -4;
		#20 iSample = 8;
		#20 iEnable = 0;
		#20 iSample = 2;
		#20 iSample = -3;
		#20 iSample = 1;
		#20 iSample = 0;
		
		#20 iReset = 1;
		#20 iReset = 0; iEnable = 1;
		#20 iOrder = 3; iSample = 10;
		#20 iSample = -7;
		#20 iSample = -4;
		#20 iSample = 8;
		#20 iEnable = 0;
		#20 iSample = 2;
		#20 iSample = -3;
		#20 iSample = 1;
		#20 iSample = 0;
  end
  
	initial
	#1000 $stop;
	
endmodule
