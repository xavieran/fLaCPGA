module SubframeDecoder(input iClock,
                       input iReset,
                       input iEnable, 
                       input [19:0] iNSamples,
                       output oSampleValid,
                       output reg oFrameDone,
                       output signed [15:0] oSample,
                       /* RAM I/O */
                       input [15:0] iData, 
                       output [15:0] oReadAddr
                       );
   
reg [15:0] data_buffer;
reg [2:0] state;
reg [3:0] order;

reg rd_enable, rd_reset, fd_reset, done;
reg [15:0] sample_count, read_address;

wire rd_done;
wire signed [15:0] rd_residual;
wire [15:0] rd_address;

assign oSampleValid = done;

//if (rd_enable == 1) assign oReadAddr = rd_address;
//else assign oReadAddr = read_address;

assign oReadAddr = rd_enable ? rd_address : read_address;

parameter S_READ_HEADER = 0, S_READ_FIXED = 1;

always @(posedge iClock) begin
    if (iReset) begin
        data_buffer <= iData;
        state <= S_READ_HEADER;
        order <= 0;
        read_address <= 0;
        
        rd_enable <= 0;
        rd_reset <= 1;
        fd_reset <= 1;
        
        sample_count <= 0;
        oFrameDone <= 0;
        done <= 0;
    end else if (iEnable) begin
        case (state)
        default:
        begin /* RESET STATE */
            data_buffer <= iData;
            state <= S_READ_HEADER;
            order <= 0;
            read_address <= 0;
            
            rd_enable <= 0;
            rd_reset <= 1;
            fd_reset <= 1;
            
            oFrameDone <= 0;
            sample_count <= 0;
            done <= 0;
        end
        S_READ_HEADER:
        begin
            // 000000 : SUBFRAME_CONSTANT
            if (data_buffer[14:9] === 6'b000000) begin
            
            // 000001 : SUBFRAME_VERBATIM
            end else if (data_buffer[14:10] === 6'b00001) begin
            
            // 001xxx : if(xxx <= 4) SUBFRAME_FIXED, xxx=order ; else reserved-
            //end else if (data_buffer[14:9] === 6'b001xxx) begin 
            end else if (data_buffer[14:12] === 3'b001) begin 
                order <= data_buffer[11:9];
                state <= S_READ_FIXED;
            // 01xxxx : reserved : SUBFRAME_LPC, xxxxx=order-1
            end else if (data_buffer[14] === 1'b1) begin
            
            end else begin
                // Raise error?
            end
        end
        
        S_READ_FIXED:
        begin   
            rd_enable <= 1;
            
            rd_reset <= 0;
            fd_reset <= 0;
            
            done <= rd_done; // Delay rd_done by 1 cycle
            
            if (rd_done) begin
                sample_count <= sample_count + 1;
                if (sample_count == iNSamples) begin
                    state <= S_READ_HEADER;
                    oFrameDone <= 1;
                end
            end
        end
        endcase
    end
end


FixedDecoder fd (.iClock(iClock),
                 .iReset(fd_reset),
                 .iEnable(rd_done),
                 .iOrder(order),
                 .iSample(rd_residual),
                 .oData(oSample)
                 );
                                    
ResidualDecoder rd (.iClock(iClock),
                    .iReset(rd_reset),
                    .iEnable(rd_enable),
                    .iNSamples(iNSamples),
                    .iPredOrder(order),
                    .iStartBit(5'b00111),
                    .iStartAddr(read_address),
                    .oResidual(rd_residual),
                    .oDone(rd_done),
                    /* RAM I/O */
                    .iData(iData),
                    .oReadAddr(rd_address)
                    );
endmodule
