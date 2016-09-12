

module DelayRegister (
    input wire iClock, 
    input wire iEnable, 
    input wire [15:0] iData,
    output wire [15:0] oData
    );


parameter LENGTH = 32;

integer i;
reg [15:0] delay [0:LENGTH - 1];

assign oData = delay[LENGTH - 1];

always @(posedge iClock) begin
    if (iEnable) begin
        for (i = LENGTH - 1; i > 0; i = i - 1) begin
            delay[i] <= delay[i - 1];
        end
        delay[0] <= iData;
    end
end
endmodule

