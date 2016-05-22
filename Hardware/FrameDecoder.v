module FrameDecoder(input iClock,
                       input iReset,
                       input iEnable, 
                       output oSampleValid,
                       output oFrameDone,
                       output signed [15:0] oSample,
                       output reg oBadFrame, 
                       
                       /* RAM I/O */
                       input iUpperBits, 
                       input [15:0] iStartAddress,
                       input [15:0] iData, 
                       output [15:0] oReadAddr
                       );

reg [15:0] read_address;
reg wait_for_ram;
reg upper, lower;
reg [3:0] state;
reg [16:0] sync_code;
reg [3:0] block_size;
reg [3:0] sample_rate;
reg [3:0] channels;
reg [3:0] bps;

reg [47:0] frame_number;
reg [7:0] frame_crc8;
reg [7:0] calc_crc8;


// 1111 1111 1111 1000
// (sync code - 14) (0-1) (0-1)
// 1100 1001 0000 1000
// (block size - 4) (sample rate - 4) (channels - 4) (bps - 3) (0 - 1)
// Will have to decode this :/
// UTF-8
// CRC-8 (8 bits)


wire [15:0] sd_read_address;
wire signed [15:0] sd_sample;
wire sd_done, sd_frame_done;
reg sd_upper;
reg sd_enable, sd_reset;

assign oSample = sd_sample;
assign oSampleValid = sd_done;
assign oFrameDone = sd_frame_done;

assign oReadAddr = sd_enable ? sd_read_address : read_address;

parameter S_READU_SYNC_CODE = 0, S_READL_SYNC_CODE = 1, S_READU_BLOCK_SIZE = 2,
          S_READL_BLOCK_SIZE = 3,  S_READU_UTF8 = 4, S_READU_CRC8 = 5, S_READL_CRC8 = 6,
          S_LVERIFY = 7, S_UVERIFY = 8, S_READ_SUBFRAME = 9;

always @(posedge iClock) begin
    if (iReset) begin
        read_address <= iStartAddress;
        wait_for_ram <= 1'b1;
        upper <= iUpperBits;
        lower <= !iUpperBits;
        
        sync_code <= 0;
        block_size <= 0;
        sample_rate <= 0;
        channels <= 0;
        bps <= 0;
        frame_number <= 48'b0;
        frame_crc8 <= 0;
        calc_crc8 <= 0;
        
        oBadFrame <= 1'b0;
        state <= S_READU_SYNC_CODE;
        
        sd_enable <= 1'b0;
        sd_reset <= 1'b1;
        sd_upper <= 1'b1;
        
        
    end else if (iEnable) begin
        case (state)
        S_READU_SYNC_CODE:
        begin
            if (!wait_for_ram) begin
                if (upper) begin
                    sync_code <= iData;
                    
                    read_address <= read_address + 1'b1;
                    wait_for_ram <= 1'b1;
                    state <= S_READU_BLOCK_SIZE;
                end else if (lower) begin
                    sync_code[15:8] <= iData[7:0];
                    
                    read_address <= read_address + 1'b1;
                    wait_for_ram <= 1'b1;
                    state <= S_READL_SYNC_CODE;
                end
            end else wait_for_ram <= 1'b0;
        end
        
        S_READU_BLOCK_SIZE:
        begin
            if (!wait_for_ram) begin
                block_size <= iData[15:12];
                sample_rate <= iData[11:8];
                channels <= iData[7:4];
                bps <= iData[3:0];
                
                read_address <= read_address + 1'b1;
                wait_for_ram <= 1'b1;
                state <= S_READU_UTF8;
            end else wait_for_ram <= 1'b0;
        end
        
        S_READU_UTF8:
        begin
            if (!wait_for_ram) begin
                if (!(iData[15:8] & 8'h80)) begin
                    frame_number[7:0] <= iData[15:8];
                    frame_crc8 <= iData[7:0];
                    
                    read_address <= read_address + 1'b1;
                    wait_for_ram <= 1'b1;
                    state <= S_UVERIFY;
                end
            end else wait_for_ram <= 1'b0;
        end
        
        S_UVERIFY:
        begin
            if (!wait_for_ram) begin
                if (sync_code != 16'hFFF8) oBadFrame <= 1'b1;
                if (block_size != 4'b1100) oBadFrame <= 1'b1;
                if (sample_rate != 4'b1001) oBadFrame <= 1'b1;
                if (channels != 4'b0000) oBadFrame <= 1'b1;
                if (bps != 4'b1000) oBadFrame <= 1'b1;
                sd_upper <= 1'b1;
                // Check crc8 ...
                state <= S_READ_SUBFRAME;
            end else wait_for_ram <= 1'b0;
        end
        
        S_READL_SYNC_CODE:
        begin
            if (!wait_for_ram) begin
                sync_code[7:0] <= iData[15:8];
                block_size <= iData[7:4];
                sample_rate <= iData[3:0];
                
                read_address <= read_address + 1'b1;
                wait_for_ram <= 1'b1;
                state <= S_READL_BLOCK_SIZE;
            end else wait_for_ram <= 1'b0;
        end
        
        S_READL_BLOCK_SIZE:
        begin
            if (!wait_for_ram) begin
                channels <= iData[15:12];
                bps <= iData[11:8];
                if (!(iData[7:0] & 8'h80)) begin
                    frame_number[7:0] <= iData[7:0];
                    
                    read_address <= read_address + 1'b1;
                    wait_for_ram <= 1'b1;
                    state <= S_READL_CRC8;
                end else begin
                    // Do reading of UTF8 here...
                end
            end else wait_for_ram <= 1'b0;
        end
        
        S_READL_CRC8: 
        begin
            if (!wait_for_ram) begin
                frame_crc8 <= iData[15:8];
                state <= S_LVERIFY;
            end else wait_for_ram <= 1'b0;
        end
        
        S_LVERIFY:
        begin
            if (!wait_for_ram) begin
                if (sync_code != 16'hFFF8) oBadFrame <= 1'b1;
                if (block_size != 4'b1100) oBadFrame <= 1'b1;
                if (sample_rate != 4'b1001) oBadFrame <= 1'b1;
                if (channels != 4'b0000) oBadFrame <= 1'b1;
                if (bps != 4'b1000) oBadFrame <= 1'b1;
                // Check crc8 ...
                state <= S_READ_SUBFRAME;
            end else wait_for_ram <= 1'b0;
        end
        
        S_READ_SUBFRAME:
        begin
            if (!wait_for_ram) begin
                if (oBadFrame) begin
                   // ABORT !!! ? 
                end
                sd_reset <= 1'b0;
                sd_enable <= 1'b1;
                sd_upper = upper;
            end else wait_for_ram <= 1'b0;        
        end
        endcase
    end
end

SubframeDecoder sd (.iClock(iClock),
                .iReset(sd_reset),
                .iEnable(sd_enable), 
                .iBlockSize(16'd4096),
                .oSampleValid(sd_done),
                .oFrameDone(sd_frame_done),
                .oSample(sd_sample),
                
                /* RAM I/O */
                .iUpperBits(sd_upper),
                .iStartAddress(read_address),
                
                .iData(iData), 
                .oReadAddr(sd_read_address)
                );

endmodule
