`timescale 1ns / 1ns

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
        end
		  
module RiceFeederTB;
 
  reg iClock, rst, en, data;
  reg [3:0] rice_param;
  wire done;
  wire signed [15:0] residual;
  
	RiceFeeder DUT (.iClock(iClock), 
								 .iReset(rst), 
								 .iEnable(en), 
								 .iData(data), 
								 .iRiceParam(rice_param), 
								 .oData(residual),
								 .oDone(done));

always
  begin
    #10 iClock = !iClock;
  end

  initial
  begin
  #0 iClock = 0; rst = 1; en = 0; data = 0; rice_param = 3;
  #20 en = 1; rst = 0;
	   data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 0; // 5 msbs
  #20 data = 1;
  #20 data = 0;
  #20 data = 1; // 5 lsbs == -23
  
  #20 data = 1;
  #20 data = 1;
  #20 data = 0; // 2 msbs
  #20 data = 1;
  #20 data = 1;
  #20 data = 0; // 6 lsbs == 
  
  #20 data = 0; // 0 msbs
  #20 data = 0; 
  #20 data = 1;
  #20 data = 0; // 2 lsbs == 
  
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  #20 data = 0;
  #20 data = 1;
  #20 data = 1;
  #20 data = 1;
  end
  
  	initial
	#1000 $stop;
  
endmodule
