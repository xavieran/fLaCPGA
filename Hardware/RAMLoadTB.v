
`timescale 1ns / 100ps

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
    
module RAMLoadTB;

reg [15:0] iData;
reg [12:0] rdaddr, wraddr;
wire [15:0] oData;

reg clk, wren;

reg[15:0] memory [0:4096];
integer i;

 RAM 
 DUT (.clock(clk),
      .data(iData),
      .rdaddress(rdaddr),
      .wraddress(wraddr),
      .wren(wren),
      .q(oData));


    always begin
        #10 clk = !clk;
    end

    initial begin
        clk = 0; wren = 0;
        $readmemh("residual.rmh", memory);
        
        for (i = 0; i < 4096; i = i + 1) begin
            wraddr = i;
            iData = memory[i];
            wren = 1;
            #20;
        end
        
        wren = 0;
        #20;
        #10
        for (i = 0; i < 4096; i = i + 1) begin
            #20;
            rdaddr = i;
        end
        
        $stop;
    end
    

endmodule
