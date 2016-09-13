
module WriteRice (
    input wire iClock,
    input wire iReset, 
    input wire iEnable, 
    
    input wire [15:0] iUpper,
    input wire [15:0] iLower, 
    input wire [3:0] iRiceParam
    
    output wire oRamEnable,
    output wire [15:0] oRamAddress, 
    output wire [15:0] oRamData
    );


reg [3:0] bit_pointer;
reg [15:0] data_buffer;
reg [15:0] ram_adr;
reg [15:0] ram_dat;

always @(posedge iClock) begin
    if (iReset) begin
        bit_pointer <= 0;
        data_buffer <= 0;
        ram_adr <= 0;
        ram_dat <= 0;
    end else if (iEnable) begin
        
        /* Step 1. Write the upper bits */
        ram_dat[iUpper + 1] <= 1;
        ram_dat[iUpper + 2] <= iLower << bit_pointer;
        
        /* Step 2. Write the lower bits */
        
        
    end
end
endmodule