module FrameDecoder(input iClock,
                       input iReset,
                       input iEnable, 
                       input [15:0] iBlockSize,
                       output oSampleValid,
                       output reg oFrameDone,
                       output signed [15:0] oSample,
                       
                       /* RAM I/O */
                       input [15:0] iData, 
                       output [15:0] oReadAddr
                       );

reg [15:0] data_buffer;
reg [15:0] read_address;

reg [2:0] state;

// (sync code - 14) (0-1) (0-1)
// (block size - 4) (sample rate - 4) (channels - 4) (bps - 3) (0 - 1)
// UTF-8
// CRC-8 (8 bits)


wire [15:0] sd_read_address;
wire signed [15:0] sd_sample;
wire sd_done;
reg sd_enable;

assign oSampleValid = sd_done;
assign oSample = sd_sample;

assign oReadAddr = sd_enable ? sd_read_address : read_address;

parameter S_READ_HEADER = 0, S_READ_FIXED = 1;

always @(posedge iClock) begin
    if (iReset) begin
        data_buffer <= iData;
        state <= S_READ_HEADER;
    end else if (iEnable) begin
        case (state)
        default:
        begin // RESET STATE 
            data_buffer <= iData;
            state <= S_READ_HEADER;
        end
        S_READ_HEADER:
        begin
        end

        S_READ_FIXED:
        begin
        end
        endcase
    end
end

SubframeDecoder sd (.iClock(iClock),
                    .iReset(iReset),
                    .iEnable(sd_enable),
                    .oSampleValid(sd_done),
                    .oSample(sd_sample),
                    // RAM I/O
                    .iData(iData), 
                    .oReadAddr(sd_read_address)
                    );


endmodule
