module ResidualDecoder(input iClock, 
         input iReset, 
         input iEnable,
         input [15:0] iBlockSize,
         input [3:0] iPredictorOrder,
         input [3:0] iPartitionOrder,
         
         input [4:0] iStartBit,
         input [15:0] iStartAddr,
         
         output signed [15:0] oResidual,
         output oDone,
         
         /* RAM I/O */
         input [15:0] iData,
         output [15:0] oReadAddr
         );

reg [15:0] data_buffer;
reg [15:0] rd_addr;
reg [4:0] curr_bit;
reg need_data;

reg rf_idata, rf_enable, rf_rst;
wire rf_done;
wire signed [15:0] rf_odata;

reg signed [15:0] residual;
reg done;

reg [1:0] delay;

assign oResidual = residual;
assign oDone = done;
assign oReadAddr = rd_addr;

RiceFeeder rf (.iClock(iClock),
               .iReset(rf_rst),
               .iEnable(rf_enable),
               .iData(rf_idata),
               .iBlockSize(iBlockSize), 
               .iPartitionOrder(iPartitionOrder),
               .iPredictorOrder(iPredictorOrder),
               .oData(rf_odata),
               .oDone(rf_done));

always @(posedge iClock) begin
    if (iReset) begin
        curr_bit <= iStartBit;
        rd_addr <= iStartAddr;
        data_buffer <= iData;
        need_data <= 1'b1;
        
        residual <= 1'b0;
        rf_idata <= 1'b0;
        rf_enable <= 1'b0;
        rf_rst <= 1'b1;
        
        done <= 1'b0;
        
    end else if (iEnable) begin
        if (need_data) begin
            rd_addr <= rd_addr + 1'b1;
            need_data <= 1'b0;
        end
        
        rf_rst <= 1'b0;
        rf_enable <= 1'b0;
        rf_idata <= data_buffer[4'd15];
        data_buffer <= data_buffer << 1'b1;
        curr_bit <= curr_bit - 1'b1;
        
        if (curr_bit == 0) begin
            curr_bit <= 5'd15;
            data_buffer[15:0] <= iData;
            need_data <= 1'b1;
        end
        
        if (rf_done) begin
            residual <= rf_odata;
            done <= 1'b1;
        end
    end
end
    
endmodule