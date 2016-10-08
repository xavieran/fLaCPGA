

module Test_fLaC_Encoder;

reg clk;
reg signed [15:0] sample;

reg read_file;

integer infile, i, fout, fout2;
integer cycles;

always begin
    #0 clk = 0;
    #10 clk = 1;cycles = cycles + 1 ;
    #10;
end

reg valid;
reg s1_ena, s1_rst;

wire re1, re2;
wire [15:0] ra1, ra2, rd1, rd2;

fLaC_Encoder fe(
    .iClock(clk),
    .iEnable(s1_ena), 
    .iReset(s1_rst),
    
    .iSample(sample),
    .iValid(valid),
     
    .oRamEnable1(re1),
    .oRamAddress1(ra1), 
    .oRamData1(rd1),
    
    .oRamEnable2(re2),
    .oRamAddress2(ra2), 
    .oRamData2(rd2),
    .oFrameDone(frame_done)
    );

reg [15:0] output_count, frame_count;
always @(posedge clk) begin
    if (read_file) begin
        $fscanf(infile, "%d\n", sample);
        valid <= 1;
    end 
    
    if (frame_done) begin
        frame_count <= frame_count + 1;
    end
    
   
end


initial begin
    //infile = $fopen("Pavane16Blocks.txt", "r");
    //infile = $fopen("Pavane_PCM_All.txt", "r");
    //fout = $fopen("pavane_test_residuals.txt", "w");
    infile = $fopen("wakeup_pcm.txt", "r");
    //fout = $fopen("test_stages_res_out.txt", "w");
    //fout = $fopen("wakeup_test_residuals.txt", "w");
    //fout2 = $fopen("ld_coefficients2.txt", "w");
    s1_ena = 0; s1_rst = 1; valid = 0; read_file = 0;
    cycles = 0;
    //Skip first 5 seconds of wake up
    for (i = 0; i < 4096*512; i = i + 1) $fscanf(infile, "%d\n", sample);
    #20;
    read_file = 1;
    s1_rst = 0; s1_ena = 1;
    for (i = 0; i < 4096*16; i = i + 1) #20;
    read_file = 0;
    valid = 0;
    
    for (i = 0; i < 4096*3; i = i + 1) #20;
    
    #60
    
    $stop;
end

endmodule
