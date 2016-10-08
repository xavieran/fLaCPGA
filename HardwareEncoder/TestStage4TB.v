
`include "Stage2_FindModel.v"
`include "Quantizer.v"
`include "ACFDivider.v"
`include "fp_divider.v"
`include "Durbinator.v"
`include "register_file.v"
`include "ModelSelector.v"
`include "AlphaCalculator2.v"
`include "CalculateKAndError.v"
`include "GenerateAutocorrelationSums.v"

`include "fp_convert.v"
`include "fp_add_sub.v"
`include "fp_mult.v"
`include "FIR_FilterBank.v"
`include "fir_filters.v"
`include "Compare12.v"
`include "mf_fifo.v"
`include "mf_fifo1024.v"
`include "mf_fifo128.v"
`include "DelayRegister.v"
`include "TappedDelayRegister.v"

`include "Stage3_Encode.v"
`include "DurbinCoefficientStore.v"
`include "RiceWriter.v"
`include "RiceEncoder.v"
`include "dual_write_ram.v"

module TestStage4TB;

reg clk, ena, rst;
reg signed [15:0] sample;

reg read_file;
integer infile, i, fout, fout2;
integer cycles;

always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

reg [15:0] last_ram_address;
reg frame_done;
reg [3:0] m;
reg valid;
wire re1, re2;
wire [15:0] ra1, rd1, ra2, rd2;
wire s4_fd;


Stage4_Compress s4 (
    .iClock(clk),
    .iEnable(ena),
    .iReset(rst),
    
    .iFrameDone(frame_done),
    .iM(m),
    .iValid(valid),
    .iResidual(sample),
    
    .oRamEnable1(re1),
    .oRamAddress1(ra1), 
    .oRamData1(rd1),
    
    .oRamEnable2(re2),
    .oRamAddress2(ra2), 
    .oRamData2(rd2),
    .oFrameDone(s4_fd)
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


always @(posedge clk) begin
    if (read_file) begin
        $fscanf(infile, "%d\n", sample);
        valid <= 1;
    end 
    
    if (s4_fd) begin
        last_ram_address <= ra1;
        ram_select <= !ram_select;
    end
end

initial begin
    infile = $fopen("test_stages_res_out.txt", "r");
    fout = $fopen("ts4_ram_dump.txt", "w");
    //fout2 = $fopen("ld_coefficients2.txt", "w");
    
    cycles = 0; rst = 1; ena = 0; valid = 0;frame_done = 0; m = 0;
    ram_select = 0;
    // Skip first 5 seconds of wake up
    //for (i = 0; i < 4096*50; i = i + 1) $fscanf(infile, "%d\n", sample);
    
    // Zero the RAM
    
    for (i = 0; i < (4096/2); i = i + 1) begin
        ore1 = 1; ore2 = 1;
        ora1 = i; ora2 = i + (4096/2);
        ord1 = 0; ord2 = 0;
        #20;
    end
    ord1 = 0; ore1 = 0; ore2 = 0; ora2 = 0; ord2 = 0;
    #20;
    ena = 1; rst = 0; frame_done = 1; m = 8;
    ram_select = 1;
    #20; 
    frame_done = 0;
    read_file = 1; 
    #20
    for (i = 0; i < (4096 - m)*1; i = i + 1) #20;
    #20;
    read_file = 0; valid = 0;
    #80;
    m = 12; frame_done = 1; 
    #20 
    read_file = 1;
    frame_done = 0;
    for (i = 0; i < (4096 - m)*1; i = i + 1) #20;
    read_file = 0; valid = 0;
    #400
    
    ena = 0;
    for (i = 0; i < last_ram_address; i = i + 2) begin
        read_1 = i;
        read_2 = i + 1;
        #20;
        $fwrite(fout, "%u", encoded_out);
    end
    
    #20;
    //for (i = 0; i < );
    $stop;
end


endmodule
