module ResidualDecoder(input iClock, 
							  input iReset, 
							  input [15:0] iSamples,
							  input iData,
							  input [3:0] iPredOrder,
							  output signed [15:0] oResidual,
							  output iDone);

/* <2> 	Residual coding method:

    00 : partitioned Rice coding with 4-bit Rice parameter; RESIDUAL_CODING_METHOD_PARTITIONED_RICE follows
    01 : partitioned Rice coding with 5-bit Rice parameter; RESIDUAL_CODING_METHOD_PARTITIONED_RICE2 follows
    10-11 : reserved
RESIDUAL_CODING_METHOD_PARTITIONED_RICE
<4> 	Partition order.
RICE_PARTITION+ 	There will be 2^order partitions.

RICE_PARTITION
<4(+5)> 	Encoding parameter:

    0000-1110 : Rice parameter.
    1111 : Escape code, meaning the partition is in unencoded binary form using n bits per sample; n follows as a 5-bit number.

<?> 	Encoded residual. The number of samples (n) in the partition is determined as follows:

    if the partition order is zero, n = frame's blocksize - predictor order
    else if this is not the first partition of the subframe, n = (frame's blocksize / (2^partition order))
    else n = (frame's blocksize / (2^partition order)) - predictor order
*/


	reg [3:0] part_order;
	reg [3:0] rice_param;
	reg [7:0] current_partition;
	reg [15:0] curr_part_size;
	reg rf_enable;
	
	RiceFeeder rf (.iClock(iClock),
						.iReset(iReset),
						.iEnable(rf_enable),
						.iData(iData),
						.iRiceParam(rice_param),
						.oData(oData),
						.oDone(oDone));
	
	
	/* 1. Read in the partition order (4 bits)
	   2. Read in the rice parameter (4 bits)
		3. Store current partition being read 
		4. Calculate current partition size 
		5. Read and output curr_part_size number of rice samples 
		6. Repeat from step 3 */
		
		