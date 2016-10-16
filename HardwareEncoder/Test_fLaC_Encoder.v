

module Test_fLaC_Encoder;

reg clk;
reg signed [15:0] sample;


integer infile, i, fout, model_out, warmup_out;
integer res_out;
integer cycles;
integer frame_count;
always begin
    #0 clk = 0;
    #10 clk = 1;cycles = cycles + 1 ;
    #10;
end

reg valid;
reg s1_ena, s1_rst;

wire [31:0] fe_data;
wire fe_valid, fe_load, fe_wvalid, fe_rvalid;
wire [3:0] fe_m;
wire signed [14:0] fe_model;
wire signed [15:0] fe_warmup;
wire signed [15:0] fe_residual;
fLaC_Encoder fe(
    .iClock(clk),
    .iEnable(s1_ena), 
    .iReset(s1_rst),
    
    .iSample(sample),
    .iValid(valid),
     
    .oLoad(fe_load), 
    .oM(fe_m), 
    .oModel(fe_model),
    
    .oWValid(fe_wvalid), 
    .oWarmup(fe_warmup),
    
    .oFrameDone(fe_fd),
    .oResidual(fe_residual),
    .oRValid(fe_rvalid),
    
    .oData(fe_data), 
    .oValid(fe_valid)
    );

always @(posedge clk) begin

    if (fe_valid) begin
        $fwrite(fout, "%u", fe_data);
    end
    
    if (fe_load) begin
        $fwrite(model_out, "%d ", fe_m);
        $fwrite(model_out, "%d\n", fe_model);
        $fflush(model_out);
        $fflush(res_out);
        $fflush(fout);
        //$display("%d %d", fe_m, fe_model);
    end
   
    if (fe_wvalid) begin
        $fwrite(warmup_out, "%d\n", fe_warmup);
        $fflush(warmup_out);
    end
    
    if (fe_rvalid) begin
        $fwrite(res_out, "%d\n", fe_residual);
    end
    
    if (fe_fd) begin
        frame_count = frame_count + 1;
        $display("Frames: %d", frame_count);
    end
   
end


initial begin
    //infile = $fopen("Pavane16Blocks.txt", "r");
    //infile = $fopen("Pavane_PCM_All.txt", "r");
    //fout = $fopen("pavane_test_residuals.txt", "w");
    //fout = $fopen("test_stages_res_out.txt", "w");
    //fout = $fopen("wakeup_test_residuals.txt", "w");
    //fout2 = $fopen("ld_coefficients2.txt", "w");
    
    
    infile = $fopen("Verification/wakeup_pcm.txt", "r");
    //infile = $fopen("Verification/PavaneAll256.pcm", "r");
    fout = $fopen("Verification/fe_residuals.txt", "w");
    model_out = $fopen("Verification/models.txt", "w");
    warmup_out = $fopen("Verification/warmup.txt", "w");
    res_out = $fopen("Verification/residuals.txt", "w");
    frame_count = 0;
    s1_ena = 0; s1_rst = 1; valid = 0;
    cycles = 0;
    //Skip first 5 seconds of wake up
    //for (i = 0; i < 4096*512; i = i + 1) $fscanf(infile, "%d\n", sample);
    
    #20;
    s1_rst = 0; s1_ena = 1; valid = 1;
    for (i = 0; i < 4096*2048; i = i + 1) begin
        $fscanf(infile, "%d\n", sample);
        #20;
    end
    
    #60
    $fclose(infile);
    $fclose(fout);
    $fclose(model_out);
    $fclose(res_out);
    $stop;
end

endmodule
