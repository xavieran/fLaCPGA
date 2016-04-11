
module UnaryDecoder(input iClock, 
						  input iReset, 
						  input iEnable, 
						  input iBits, 
						  output oDone, 
						  output [15:0] oData);
						  
reg done;
reg [15:0] data;

assign oDone = done;
assign oData = data;

always @(posedge iClock) begin
	if (iReset) begin
		data <= 0;
		done <= 0;
	end
	
	if (iEnable) begin
		if (iBits == 0 && ~oDone)
			data <= oData + 1;
		else
			done <= 1;
	end
end
endmodule
