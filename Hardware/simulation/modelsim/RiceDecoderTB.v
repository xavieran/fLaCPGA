
`timescale 1ns / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
		  
module RiceDecoderTB; 
 
  wire  [15:0]  oData   ; 
  reg  [3:0]  iRiceParam;
  reg   iClock; 
  reg  [15:0] iLSB; 
  reg  [15:0] iMSB;
  
  RiceDecoder  
   DUT  ( 
       .oData (oData ) ,
      .iRiceParam (iRiceParam ) ,
      .iClock (iClock ) ,
      .iLSB (iLSB ) ,
      .iMSB (iMSB ) ); 



always
  begin
    #10 iClock = !iClock;
  end

  initial
  begin
		#0 iClock = 0;
		#20 iRiceParam = 0; iMSB = 2; iLSB = 0; // 1
		#20 iRiceParam = 0; iMSB = 6; iLSB = 0; // 3
		#20 iRiceParam = 0; iMSB = 3; iLSB = 0; // -2
		#20 iRiceParam = 0; iMSB = 8; iLSB = 0; // 4
		#20 iRiceParam = 0; iMSB = 14; iLSB = 0; // 7
		#20 iRiceParam = 0; iMSB = 100; iLSB = 0; // 50
		#20 iRiceParam = 0; iMSB = 203; iLSB = 0; // -102
		#20 iRiceParam = 0; iMSB = 0; iLSB = 0; /* BLANK */
		#40 iRiceParam = 3; iMSB = 0; iLSB = 2; // 1
		#20 iRiceParam = 3; iMSB = 0; iLSB = 6; // 3
		#20 iRiceParam = 3; iMSB = 0; iLSB = 3; // -2
		#20 iRiceParam = 3; iMSB = 1; iLSB = 0; // 4
		#20 iRiceParam = 3; iMSB = 1; iLSB = 6; // 7
		#20 iRiceParam = 3; iMSB = 12; iLSB = 4; // 50
		#20 iRiceParam = 3; iMSB = 25; iLSB = 3; // -102
  end
  
  	initial
	#1000 $stop;
  
endmodule
