module RiceStreamReader(input iClock,
						input iReset,
						input iEnable,
						input iData,
						input [3:0] iRiceParam, 
						output reg [15:0] oMSB,
						output reg [15:0] oLSB,
						output oDone);
/* This module analyses the data stream and outputs the current LSBs and MSBs 
   for the stream. Whenever the done flag is raised, you can sample the correct LSBs and MSBs

*/

	reg [15:0] procMSBs, procLSBs;
	
	parameter IDLE = 2'b00, UNARY = 2'b01, REMAINDER = 2'b10;
	
	reg [1:0] state;
	reg done;
	
	assign oDone = done;
						 
	reg [3:0] rem_bits;
	
	always @(posedge iClock) begin
		if (iReset) begin
			state <= UNARY;
			done <= 0;
			procLSBs <= 0;
			procMSBs <= 0;
			oMSB <= 0;
			oLSB <= 0;
		end else if (iEnable) begin
			case (state)
				UNARY:
					begin
						if (iData == 1) begin
							procMSBs <= procMSBs + 1;
						end else begin
							oMSB <= procMSBs;
							rem_bits <= iRiceParam - 1;
							procLSBs <= 0;
							state <= REMAINDER;
							done <= 0;
						end
					end
				REMAINDER:
					begin
						if (rem_bits != 0) begin
							procLSBs[rem_bits] = iData;
							rem_bits <= rem_bits - 1;
						end else begin
							oLSB <= procLSBs | iData;
							done <= 1;
							state <= UNARY;
							procMSBs <= 0;
						end
					end
			endcase
		end
	end
		
endmodule
