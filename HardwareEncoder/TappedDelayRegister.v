

module TappedDelayRegister (
    input wire iClock, 
    input wire iEnable, 
    input wire [3:0] iM,
    input wire [15:0] iData,
    output wire [15:0] oData
    );


parameter LENGTH = 32;

integer i;
reg [15:0] delay [0:LENGTH - 1];
reg [15:0] delay_tap;

assign oData = delay_tap;

always @(posedge iClock) begin
    if (iEnable) begin
        if (iM == 15)
            delay_tap <= iData;
        else 
            delay_tap <= delay[iM];
        
        for (i = LENGTH - 1; i > 0; i = i - 1) begin
            delay[i] <= delay[i - 1];
        end
        delay[0] <= iData;
    end
end
endmodule

