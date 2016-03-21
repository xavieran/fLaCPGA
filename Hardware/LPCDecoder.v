module LPCDecoder(input iClock,
						input iReset,
						input iEnable,
						input [3:0] iPrecision,
						input [4:0] iShift,
						input signed [31:0] iCoeff,
						input [5:0] lpcOrder,
						input signed [31:0] iSample,
						output signed [31:0] oData);

reg signed [31:0] coeffs [11:0]; // Max order is 12
reg signed[31:0] dataq [12:0]; // Shift register to hold past audio samples
reg [3:0] sample_count; // Counts the number of warmup samples before starting decoding
reg [2:0] state; 

assign oData = dataq[0];

parameter S_INIT = 2'b00, S_COEFF = 2'b01, S_WARMUP = 2'b10, S_DECODE = 2'b11;

always @(posedge iClock) begin
	if (iReset) begin
		// Reset things
		sample_count <= 0;
		state <= 0;
	end else if (iEnable) begin
		/* Shift the shift register ... */
		dataq[12] <= dataq[11];
		dataq[11] <= dataq[10];
		dataq[10] <= dataq[9];
		dataq[9] <= dataq[8];
		dataq[8] <= dataq[7];
		dataq[7] <= dataq[6];
		dataq[6] <= dataq[5];
		dataq[5] <= dataq[4];
		dataq[4] <= dataq[3];
		dataq[3] <= dataq[2];
		dataq[2] <= dataq[1];
		dataq[1] <= dataq[0];
	
		case (state)
		S_INIT: 
			begin
			state <= S_COEFF;
			sample_count <= 0;
			end
		S_COEFF:
			if (sample_count < lpcOrder) begin
				coeffs[sample_count] <= iSample;
				sample_count = sample_count + 1'b1;
			end else begin// Question, does this mean we need to wait a clock cycle between feeding in warmup and coeefs???
				state <= S_WARMUP;
				sample_count <= 1'b0;
			end
		S_WARMUP:
			if (sample_count < lpcOrder) begin
				dataq[0] <= iSample;
				sample_count <= sample_count + 1'b1;
			end else begin
				state <= S_DECODE;
			end
		S_DECODE:
			dataq[0] <= iSample + 
						 ((dataq[1]*coeffs[0] + dataq[2]*coeffs[1] + dataq[3]*coeffs[2] +
							dataq[4]*coeffs[3] + dataq[5]*coeffs[4] + dataq[6]*coeffs[5] +
						   dataq[7]*coeffs[6] + dataq[8]*coeffs[7] + dataq[9]*coeffs[8] +
							dataq[10]*coeffs[9] + dataq[11]*coeffs[10] + dataq[12]*coeffs[11]) >> iShift);
							/* This is potentially inefficient use of resources ? */
		default:
			state <= S_INIT;
		endcase
	end
end
endmodule		
/*pcOr

    for(i = 0; i < _lder; i++){
        fr->read_bits_signed(data + i, _bitsPerSample);
    }

    fr->read_bits(&_qlpPrecis, 4);
    _qlpPrecis++; 

    fr->read_bits_signed(&_qlpShift, 5)

    int32_t coeff;
    for (i = 0; i < _lpcOrder; i++){
        fr->read_bits_signed(_qlpCoeff + i, _qlpPrecis);
    }
    int s = _lpcOrder; // The sum of all samples read by this subframe...
    s += fr->read_residual(residuals, _blockSize, _lpcOrder);
    
    for(i = _lpcOrder; i < _blockSize; i++) {
        sum = 0;
        for(j = 0; j < _lpcOrder; j++)
            sum += _qlpCoeff[j] * data[i-j-1];
        data[i] = (sum >> _qlpShift) + residuals[i - _lpcOrder];
    }
    */