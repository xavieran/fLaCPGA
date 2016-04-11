module RiceDecoder(input iClock, 
						 input [15:0] iMSB, 
						 input [15:0] iLSB, 
						 input [3:0] iRiceParam, 
						 output signed [15:0] oData);
						 						 
reg signed [15:0] data;
assign oData = data;

always @(posedge iClock)
begin
	if (iLSB[0])
		data <= -(((iMSB << iRiceParam) | iLSB) >> 1) - 1;
	else
		data <= ((iMSB << iRiceParam) | iLSB) >> 1;
end
endmodule 