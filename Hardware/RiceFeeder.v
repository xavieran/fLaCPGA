module RiceFeeder(input iClock,
						input iReset,
						input iEnable,
						input iData,
						input [3:0] iRiceParam, 
						output reg signed [15:0] oData,
						output oDone);

	/* Given a data stream, this module will decode the rice integers
	   and regularly signal that it has done decoding using the 
		"done" flag. This means that the data in oData is a valid decoding 
		of the residual */
						
	wire [15:0] MSBs, LSBs;
	wire signed [15:0] data;
	wire sr_done;
	reg done_hist[0:1];
	reg done;
	
	assign oDone = done;
	
	RiceDecoder rd (.oData (data),
						 .iRiceParam (iRiceParam),
						 .iClock (iClock),
						 .iLSB (LSBs),
						 .iMSB (MSBs));
						 
   RiceStreamReader sr (.iClock(iClock),
							   .iReset(iReset),
								.iEnable(iEnable),
								.iData(iData),
								.iRiceParam(iRiceParam),
								.oMSB(MSBs),
								.oLSB(LSBs),
								.oDone(sr_done));
						 
	always @(posedge iClock) begin
		done_hist[1] <= done_hist[0];
		done_hist[0] <= sr_done;
		if (iReset) begin
			done_hist[1] <= 0;
			done_hist[0] <= 0;
			oData <= 0;
			done <= 0;
		end else if (iEnable) begin
			// Detect a positive edge on the done signal from sr
			if (done_hist[0] == 1'b1 && done_hist[1] == 1'b0) begin
				done <= 1;
				oData <= data;
			end else 
				done <= 0;
		end
	end
	
endmodule
			
