/*
 * FMax: 202 MHz (when registered)
 */

module RiceDecoder(input iClock, 
						 input [15:0] iMSB, 
						 input [15:0] iLSB, 
						 input [3:0] iRiceParam, 
						 output signed [15:0] oData);

reg signed [15:0] data;
assign oData = data;

always @(posedge iClock)
begin
    if (iLSB[0] || (iRiceParam == 0 && iMSB[0]))
		data <= -(((iMSB << iRiceParam) | iLSB) >> 1'b1) - 1'b1;
	else
		data <= ((iMSB << iRiceParam) | iLSB) >> 1'b1;
end
endmodule 

/*
reg [15:0] l, m;
reg [3:0] rp;
reg signed [15:0] data;
assign oData = data;

always @(posedge iClock)
begin
    l <= iLSB;
    m <= iMSB;
    rp <= iRiceParam;
    
    if (l[0] || (rp == 0 && m[0]))
        data <= -(((m << rp) | l) >> 1'b1) - 1'b1;
    else
        data <= ((m << rp) | l) >> 1'b1;
end
endmodule */