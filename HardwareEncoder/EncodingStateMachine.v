module EncodingStateMachine(
    input iClock, 
    input iEnable,
    input iReset,
    input iRamReadData,
    output oRamReadAddr,
    output oRamWriteData,
    output oRamWriteAddr,
    output oRamWriteEnable);

/* 
 * 1. Run through the data in memory and find the fixed encoder with the
 *    smallest absolute error sum
 * 2. Select the best encoder and run through the data calculating the residual and 
 *    storing it in internal RAM
 * 3. Run the rice encoder over the internal RAM and find the optimum set of rice parameters
 *    for each partition size
 * 4. Run the residuals through the best rice encoder for each partition, storing MSBs and LSBs 
 *    in an internal RAM
 * 5. Walk through the internal RAM with the residuals stored and write the results into external
 *    RAM
 */
 
 
reg [3:0] state; 

always @(posedge iClock) begin
    if (iReset) begin
    
    end else if (iEnable) begin
        
    end
end


endmodule