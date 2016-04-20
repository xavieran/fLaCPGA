module FixedSubFrameDecoder(input iClock,
									 input iReset, 
									 input iData,
									 input iOrder, 
									 input iSamples,
									 input 
	/* SUBFRAME_FIXED
<n> 	Unencoded warm-up samples (n = frame's bits-per-sample * predictor order).
RESIDUAL 	Encoded residual 
RESIDUAL
<2> 	Residual coding method:
<4(+5)> 	Encoding parameter:

    0000-1110 : Rice parameter.
    1111 : Escape code, meaning the partition is in unencoded binary form using n bits per sample; n follows as a 5-bit number.

<?> 	Encoded residual. The number of samples (n) in the partition is determined as follows:

    if the partition order is zero, n = frame's blocksize - predictor order
    else if this is not the first partition of the subframe, n = (frame's blocksize / (2^partition order))
    else n = (frame's blocksize / (2^partition order)) - predictor order*/
								 
	
	FixedDecoder decoder (input iClock,
						  input iReset, 
						  input iEnable, 
						  input [7:0] iOrder, 
						  input signed [15:0] iSample, 
						  output signed [15:0] oData);	 
									 
   RiceFeeder residuals (input iClock,
						input iReset,
						input iEnable,
						input iData,
						input [3:0] iRiceParam, 
						output reg signed [15:0] oData,
						output oDone);