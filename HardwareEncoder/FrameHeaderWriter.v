module FrameHeaderWriter (
    input wire iClock,
    input wire iReset, 
    input wire iEnable, 
    
    input wire iValid
    input wire [3:0] iM,
    input wire signed [14:0] iModel
    
    
    );


reg [15:0] buffer [0:31];

always @(posedge iClock) begin
    if (iReset) begin
        buffer[0] <= 16'b1111111111111100;
        buffer[1] <= 16'b1100100100001000;
        buffer[2] <= 16'b0000000010000000;// last 8 bits are crc
        buffer[3] <= 0;
    end else if (iEnable) begin
        // subframe header
        // 01xxxxx0 (xxxxx = iM - 1)
        // insert warmup samples
    end
    
end

endmodule
