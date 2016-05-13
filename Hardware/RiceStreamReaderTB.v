`timescale 1ns / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
		  
module RiceStreamReaderTB;
 
  reg iClock, rst, en, data;
  reg [3:0] rice_param;
  wire done;
  wire  [15:0] MSB, LSB;
  
	RiceStreamReader DUT (.iClock(iClock), 
								 .iReset(rst), 
								 .iEnable(en), 
								 .iData(data), 
								 .iRiceParam(rice_param), 
								 .oMSB(MSB), 
								 .oLSB(LSB),
								 .oDone(done));

always
  begin
    #10 iClock = !iClock;
  end

  initial
  begin
  #0 iClock = 0; rst = 1; en = 0; data = 0; rice_param = 3;
  #20 en = 1; rst = 0;
	  data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 1; // 5 msbs
  #20 data = 1;
  #20 data = 0;
  #20 data = 1; // 5 lsbs == -23
  
  #20 data = 0;
  #20 data = 0;
  #20 data = 1; // 2 msbs
  #20 data = 1;
  #20 data = 1;
  #20 data = 0; // 6 lsbs == 
  
  #20 data = 1; // 0 msbs
  #20 data = 0; 
  #20 data = 1;
  #20 data = 0; // 2 lsbs == 
  
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 1; // 5 msbs
  #20 data = 1;
  #20 data = 1;
  #20 data = 1; // 7 lsbs
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 0;
  #20 data = 1; // 11 msbs
  #20 data = 0;
  #20 data = 0;
  #20 data = 1; // 1 lsbs
  #20 $stop;
  end
  
endmodule
