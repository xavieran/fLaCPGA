/* The optimal rice parameter can be estimated from the expectation of 
 * the sequence of numbers as log(|E|, 2) according to  Weinberger (1996)
 * This can be calculated as the smallest k that satisfies 2^k*N >= A
 * where N is the number of samples seen and A is their sum
 */



module RiceOptimizer (
    input iClock,
    input iEnable, 
    input iReset,
    
    input signed [15:0] iResidual,
    
    output signed [3:0] oBest
    );

parameter PARTITION_SIZE = 1024;

reg signed [15:0] residual;
reg [15:0] icount;
reg [31:0] sum;
reg [3:0] best;

always @(posedge iClock) begin
    if (iReset) begin
        sum <= 0;
        best <= 0;
        icount <= 0;
        sample <= 0;
        unsigned_sample <= 0;
    end else begin
        residual <= iResidual;
        
        if (sample[15]) begin
            unsigned_sample <= sample ^ 16'hffff;
        end else begin
            unsigned_sample <= sample;
        end
        
        if (icount < PARTITION_SIZE + 2) begin
            icount <= icount + 1'b1;
            sum <= sum + unsigned_sample;
        end
        
        
        
    end
end


endmodule