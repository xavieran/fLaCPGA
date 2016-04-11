module RiceFeeder(input iClock,
						input iReset,
						input iEnable,
						input iData,
						input [3:0] iRiceParam, 
						output signed [15:0] oData,
						output oDone);

	wire [15:0] MSBs, LSBs;
	wire signed [15:0] data;
	
	assign oData = data;

	RiceDecoder rd (.oData (data),
						 .iRiceParam (iRiceParam),
						 .iClock (iClock),
						 .iLSB (LSBs),
						 .iMSB (MSBs));
						 
   RiceStreamReader sr (.iClock(iClock),
							   .iReset(),
								.iEnable(),
								.iData(iData),
								.iRiceParam(),
								.oMSB(MSBs),
								.oLSB(LSBs),
								.oDone());
						 
		
endmodule
			
