//Stage5_Output.v


//`default_nettype none

`ifndef STAGE_5_H
`define STAGE_5_H

module Stage5_Output (
    input wire iClock,
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

wire re1 = iRamEnable1;
wire re2 = iRamEnable2;
wire [15:0] ra1 = iRamAddress1;
wire [15:0] ra2 = iRamAddress2;
wire [15:0] rd1 = iRamData1;
wire [15:0] rd2 = iRamData2;

reg ram_select;
reg ore1, ore2;
reg [15:0] ora1, ora2, ord1, ord2;
reg [15:0] read_1, read_2;
wire [15:0] dwr1_q1, dwr1_q2;
wire [15:0] q1, q2;

// We write to RAM 1 when select is high
dual_write_ram dwr1 (
    .iClock(iClock),
    
    .iData1((ram_select & !iClear) ? rd1 : 0) ,
    .iData2((ram_select & !iClear) ? rd2 : 0), 
    
    .iWriteAddress1((ram_select & !iClear) ? ra1 : ora1),
    .iWriteAddress2((ram_select & !iClear) ? ra2: ora2),
    
    .iReadAddress1(read_1), 
    .iReadAddress2(read_2),
    
    .iWE1((ram_select & !iClear) ? re1 : ore1),
    .iWE2((ram_select & !iClear) ? re2 : ore2),

    .oData1(dwr1_q1), 
    .oData2(dwr1_q2)
    );

wire [15:0] dwr2_q1, dwr2_q2;
// We write to RAM 2 when select is low
dual_write_ram dwr2 (
    .iClock(iClock),
    
    .iData1((!ram_select & !iClear) ? rd1 : 0 ) ,
    .iData2((!ram_select & !iClear) ? rd2 : 0), 
    
    .iWriteAddress1((!ram_select & !iClear) ? ra1 : ora1),
    .iWriteAddress2((!ram_select & !iClear) ? ra2: ora2),
    
    .iReadAddress1(read_1), 
    .iReadAddress2(read_2),
    
    .iWE1((!ram_select & !iClear) ? re1 : ore1),
    .iWE2((!ram_select & !iClear) ? re2 : ore2),

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

reg [15:0] half_word1;
wire [15:0] half_word2 = q2;
reg half_word;
wire [7:0] hw_dat1a, hw_dat1b, hw_dat2a, hw_dat2b;
assign hw_dat1a = half_word1[15:8];
assign hw_dat1b = half_word1[7:0];
assign hw_dat2a = half_word2[15:8];
assign hw_dat2b = half_word2[7:0];

reg half_word_load;
wire [31:0] encoded_out;
//assign encoded_out = {ram_dat1b, ram_dat1a, ram_dat2b, ram_dat2a};
assign encoded_out = half_word_load ? {hw_dat2b, hw_dat2a, hw_dat1b, hw_dat1a} :
                                 {ram_dat2b, ram_dat2a, ram_dat1b, ram_dat1a};

reg valid;

assign oData = encoded_out;
assign oValid = valid;
reg start_reading;
reg [15:0] last_address;

always @(posedge iClock) begin
    if (iReset) begin
        ram_select <= 0;
        ore1 <= 1;
        ore2 <= 1;
        ora1 <= 0;
        ora2 <= 1;
        ord1 <= 0;
        ord2 <= 0;
        read_1 <= 0;
        read_2 <= 0;
        
        last_address <= 0;
        start_reading <= 0;
        valid <= 0;
        half_word = 0;
        half_word1 <= 0;
        half_word_load <= 0;
    end else if (iClear) begin
        ora1 <= ora1 + 2;
        ora2 <= ora2 + 2;
        ore1 <= 1;
        ore2 <= 1;
    end else if (iEnable) begin
        ore1 <= 0;
        ore2 <= 0;
        if (iFrameDone) begin
            ram_select <= !ram_select;
            start_reading <= 1;
            last_address <= (ra2 > ra1) ? ra2 : ra1;
            
            read_1 <= 0;
            read_2 <= 1;
        end
        
        if (start_reading) begin
            if (half_word) begin
                half_word <= 0;
                half_word_load <= 1;
                valid <= 1;
                read_1 <= 1;
                read_2 <= 2;
                ora1 <= read_1;
                ore1 <= 1;
            end else begin
                half_word_load <= 0;
                valid <= 1;
                ora1 <= read_1;
                ora2 <= read_2;
                ore1 <= 1;
                ore2 <= 1;
                read_1 <= read_1 + 2;
                read_2 <= read_2 + 2;
                
                if (read_1 == last_address) begin
                    half_word_load <= 1;
                    start_reading <= 0;
                    valid <= 0;
                end else if (read_2 == last_address) begin
                    start_reading <= 0;
                    ore1 <= 0;
                end
             end
        end
        
        if (!start_reading) begin
            valid <= 0;
            if (half_word_load) begin
                half_word1 <= q1;
                half_word_load <= 0;
                half_word <= 1;
            end
        end
    end
end

endmodule

`endif