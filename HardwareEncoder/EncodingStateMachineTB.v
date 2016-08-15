`timescale 1ns/100ps
`include "dual_port_ram.v"

module EncodingStateMachineTB;

reg clk, ena, rst;
reg signed [15:0] sample;

integer infile, i;

wire signed [15:0] ram_sample_q;
wire [11:0] ram_sample_a;
reg sample_we;

EncodingStateMachine ESM (
    .iClock(clk),
    .iEnable(ena), 
    .iReset(rst),
    .iRamReadData(ram_sample_q),
    .oRamReadAddr(ram_sample_a),
    .oRamWriteData(),
    .oRamWriteAddr(),
    .oRamWriteEnable()
    );

// RAM where each sample block is placed
dual_port_ram 
    #(.DATA_WIDTH(16), .ADDR_WIDTH(12))
    input_sample_ram (
    .clk(clk), 
    .data(sample), 
    .write_addr(i),
    .we(sample_we),
    .q(ram_sample_q), 
    .read_addr(ram_sample_a));


always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 ;
end

initial begin
    ena = 0; rst = 1;
    #20;
    ena = 0; rst = 1;

    // Fill the internal sample RAM
    infile = $fopen("Pavane16Blocks.txt", "r");
    for (i = 0; i < 4096; i = i + 1) begin
        $fscanf(infile, "%d\n", sample);
        sample_we = 1;
        #20;
    end
    #10
    $fclose(infile);
    sample_we = 0;
    
    /* Step 1 - Choose the best fixed encoder */
    #20;
    ena = 1; rst = 0;
    for (i = 0; i < 4096; i = i + 1) begin
        #20 ;
    end
    
    /* Step 2 - Choose the best rice parameter */
    #20 ; 
    for (i = 0; i < 4096; i = i + 1) begin
        #20 ;
    end
    
    /* Step 3 - Encode the residuals */
    #20 ;
    for (i = 0; i < 4096; i = i + 1) begin
        #20 ;
    end
    #20 ;
    
    #200 $stop;
end

endmodule