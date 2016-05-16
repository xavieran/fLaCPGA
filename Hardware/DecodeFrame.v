module FixedDecoder(input iClock,
                          input iReset, 
                          input iEnable, 
                          input [7:0] iOrder, 
                          input signed [15:0] iSample, 
                          output signed [15:0] oData);
                          
reg signed [15:0] dataq [0:4];
reg [3:0] warmup_count;

assign oData = dataq[0];

always @(posedge iClock)
begin
    if (iReset) begin
        warmup_count <= 0;
        dataq[0] <= 0;
        dataq[1] <= 0;
        dataq[2] <= 0;
        dataq[3] <= 0;
        dataq[4] <= 0;
    end else if (iEnable) begin
        dataq[4] = dataq[3];
        dataq[3] = dataq[2];
        dataq[2] = dataq[1];
        dataq[1] = dataq[0];
        
        if (warmup_count < iOrder) begin
            dataq[0] <= iSample;
            warmup_count <= warmup_count + 1'b1;
        end else if (iOrder == 0) begin
            dataq[0] <= iSample;
        end else if (iOrder == 1) begin
            dataq[0] <= iSample + dataq[1]; 
        end else if (iOrder == 2) begin
            dataq[0] <= iSample + 2*dataq[1] - dataq[2];    
        end else if (iOrder == 3) begin
            dataq[0] <= iSample + 3*dataq[1] - 3*dataq[2] + dataq[3];   
        end else if (iOrder == 4) begin
            dataq[0] <= iSample + 4*dataq[1] - 6*dataq[2] + 4*dataq[3] - dataq[4];  
        end 
    end
end
    
/*    switch(_predictorOrder) {
        case 0:
            memcpy(data, residuals, sizeof(int32_t)*_blockSize);
            break;
        case 1:
            for(i = 1; i < _blockSize; i++)
                data[i] = residuals[i - 1] + data[i-1];
            break;
        case 2:
            for(i = 2; i < _blockSize; i++)
                data[i] = residuals[i - 2] + 2*data[i-1] - data[i-2];
            break;
        case 3:
            for(i = 3; i < _blockSize; i++)
                data[i] = residuals[i - 3] + 3*data[i-1] - 3*data[i-2] + data[i-3];
            break;
        case 4:
            for(i = 4; i < _blockSize; i++)
                data[i] = residuals[i - 4] + 4*data[i-1] - 6*data[i-2] + 4*data[i-3] - data[i-4];
            break;
        default:
            break;
    }*/
     
 endmodule
 