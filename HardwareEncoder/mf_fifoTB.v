`include "mf_fifo.v"

module mf_fifoTB;

reg clk;
integer i, infile, outfile;

reg signed [15:0] data_in;
reg read, write;
wire empty, full;
wire signed [15:0] data_out;
wire [15:0] num_words;

integer cycles;


always begin
    #0 clk = 0;
    #10 clk = 1;
    #10 cycles = cycles + 1;
end

mf_fifo fifo (
    .clock(clk),
    .data(data_in),
    .rdreq(read),
    .wrreq(write),
    .empty(empty),
    .full(full),
    .q(data_out),
    .usedw(num_words));


initial begin
    cycles = 0;
    data_in = 0; read = 0; write = 0;
    #30;
    #20;
    infile = $fopen("Pavane16Blocks.txt", "r");
    outfile = $fopen("delayed_data.txt", "w");
    
    write = 1;
    for (i = 0; i < 4096; i = i + 1) begin
        $fscanf(infile, "%d\n", data_in);
        #20;
    end
    write = 0;
    read = 1;
    #20;
    
    for (i = 0; i < 4096; i = i + 1) begin
        $fwrite(outfile, "%d\n", data_out);
        #20;
    end
    read = 0;
    #20;
    
    $fclose(infile);
    $fclose(outfile);
    $stop;
end

endmodule