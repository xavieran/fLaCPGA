module RiceDecoder(input iClock, 
						 input [31:0] iMSB, 
						 input [31:0] iLSB, 
						 input [4:0] iRiceParam, 
						 output signed [31:0] oData);
						 						 
reg signed [31:0] data;
assign oData = data;

always @(posedge iClock)
begin
	if (iLSB & 1)
		data <= -(((iMSB << iRiceParam) | iLSB) >> 1) - 1;
	else
		data <= ((iMSB << iRiceParam) | iLSB) >> 1;
end

/*
C code...
 read unary msbs
 read bits lsbs, rice_param bits...
 unsigned uval = (msbs << rice_param) | lsbs;
 if (uval & 1)
	  *x = -((int)(uval >> 1)) - 1;
 else
	  *x = (int)(uval >> 1);
 return true;
 */
endmodule 