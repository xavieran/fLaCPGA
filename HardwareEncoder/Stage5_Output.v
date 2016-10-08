//Stage5_Output.v


`default_nettype none


module Stage5_Output (
    input wire iEnable,
    input wire iReset,
    input wire iClear,
    
    input wire iRamEnable1,
    input wire [15:0] iRamAddress1, 
    input wire [15:0] iRamData1,
    
    input wire iRamEnable2,
    input wire [15:0] iRamAddress2, 
    input wire [15:0] iRamData2,
    
    input wire iFrameDone,
    
    output wire [31:0] oData,
    output wire oValid
    );


reg ram_select;
reg ore1, ore2;
reg [15:0] ora1, ora2, ord1, ord2;
reg [15:0] read_1, read_2;
wire [15:0] dwr1_q1, dwr1_q2;
wire [15:0] q1, q2;

// We write to RAM 1 when select is high
dual_write_ram dwr1 (
    .iClock(clk),
    
    .iData1(ram_select ? rd1 : 0) ,
    .iData2(ram_select ? rd2 : 0), 
    
    .iWriteAddress1(ram_select ? ra1 : ora1),
    .iWriteAddress2(ram_select ? ra2: ora2),
    
    .iReadAddress1(read_1), 
    .iReadAddress2(read_2),
    
    .iWE1(ram_select ? re1 : ore1),
    .iWE2(ram_select ? re2 : ore2),

    .oData1(dwr1_q1), 
    .oData2(dwr1_q2)
    );

wire [15:0] dwr2_q1, dwr2_q2;
// We write to RAM 2 when select is low
dual_write_ram dwr2 (
    .iClock(clk),
    
    .iData1(!ram_select ? rd1 : 0) ,
    .iData2(!ram_select ? rd2 : 0), 
    
    .iWriteAddress1(!ram_select ? ra1 : ora1),
    .iWriteAddress2(!ram_select ? ra2: ora2),
    
    .iReadAddress1(read_1), 
    .iReadAddress2(read_2),
    
    .iWE1(!ram_select ? re1 : ore1),
    .iWE2(!ram_select ? re2 : ore2),

    .oData1(dwr2_q1), 
    .oData2(dwr2_q2)
    );

assign q1 = ram_select ? dwr2_q1 : dwr1_q1;
assign q2 = ram_select ? dwr2_q2 : dwr1_q2;

wire [7:0] ram_dat1a, ram_dat1b, ram_dat2a, ram_dat2b;
assign ram_dat1a = q1[15:8];
assign ram_dat1b = q1[7:0];
assign ram_dat2a = q2[15:8];
assign ram_dat2b = q2[7:0];
wire [31:0] encoded_out;
//assign encoded_out = {ram_dat1b, ram_dat1a, ram_dat2b, ram_dat2a};
assign encoded_out = {ram_dat2b, ram_dat2a, ram_dat1b, ram_dat1a};

assign oData = encoded_out;
assign oValid = valid;

reg start_reading;
reg last_address;
always @(posedge iClock) begin
    if (iReset) begin
        ram_select <= 0;
        ore1 <= 0;
        ore2 <= 0;
        ora1 <= 0;
        ora2 <= 0;
        ord1 <= 0;
        ord2 <= 0;
        read_1 <= 0;
        read_2 <= 0;
        
        last_address <= 0;
        start_reading <= 0;
    end else if (iClear) begin
        
    end else if (iEnable) begin
    
        if (iFrameDone) begin
            ram_select <= !ram_select;
            start_reading <= 1;
            read_1 <= 0;
            read_2 <= 1;
        end
        
        if (start_reading) begin
            valid <= 1;
            ora1 <= read_1;
            ora2 <= read_2;
            ore1 <= 1;
            ore2 <= 1;
            read_1 <= read_1 + 2;
            read_2 <= read_2 + 2;
            
            if (read_2 >= last_address || read_1 >= last_address) begin
                start_reading <= 0;
                ore1 <= 0;
                ore2 <= 0;
                valid <= 0;
            end
        end
    end
end

endmodule