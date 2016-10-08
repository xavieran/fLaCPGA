`default_nettype none


module RiceWriter (
    input wire iClock,
    input wire iReset, 
    input wire iEnable, 
    
    input wire iChangeParam,
    input wire iFlush,
    input wire [15:0] iTotal,
    input wire [15:0] iUpper,
    input wire [15:0] iLower, 
    input wire [3:0] iRiceParam,
    
    output wire oRamEnable1,
    output wire [15:0] oRamAddress1, 
    output wire [15:0] oRamData1,
    
    output wire oRamEnable2,
    output wire [15:0] oRamAddress2, 
    output wire [15:0] oRamData2
    );

/* iTotal: The sum of the upper and lower bits
 * iUpper: The number of upper bits to write
 * iLower: a 1 concatenated with the lower bits
 * iRiceParam: The rice parameter size
 */

// I assume that we can access a RAM with two write ports.
// Quartus will compile it, so it must exist.

/*
 * There are three possible cases when we receive a code
 * 1. There is enough space to fit the entire code word
 * 2. We overlap onto the next buffer
 * 3. We finish the current data buffer, and the next one, and overlap onto
 *    the third buffer
 */

reg [3:0] bit_pointer;

wire [15:0] uppern = (iUpper - (16 - bit_pointer)) & 4'hf;
wire [15:0] totaln = uppern + iRiceParam + 1;
wire [15:0] skip = (iUpper - (16 - bit_pointer)) >> 4;

reg [15:0] buffer;

reg need_header;
reg first_write_done;

reg [15:0] ram_adr_prev;

reg [15:0] ram_adr1;
reg [15:0] ram_dat1;
reg ram_we1;

reg [15:0] ram_adr2;
reg [15:0] ram_dat2;
reg ram_we2;

assign oRamData1 = ram_dat1;
assign oRamAddress1 = ram_adr1;
assign oRamEnable1 = ram_we1;

assign oRamData2 = ram_dat2;
assign oRamAddress2 = ram_adr2;
assign oRamEnable2 = ram_we2;


always @(posedge iClock) begin
    if (iReset) begin
        bit_pointer <= 0;
        buffer <= 0;
        
        ram_adr_prev <= 0;
        ram_adr1 <= 0;
        ram_dat1 <= 0;
        ram_we1 <= 0;        
        ram_adr2 <= 0;
        ram_dat2 <= 0;
        ram_we2 <= 0;
        
        first_write_done <= 0;
        
    end else if (iEnable) begin
        ram_we1 <= 0;
        ram_we2 <= 0;
        
        if (iFlush) begin
            ram_we1 <= 1;
            ram_dat1 <= buffer;
            ram_adr1 <= ram_adr_prev + first_write_done;
            ram_adr_prev <= 0;
            first_write_done <= 0;
            bit_pointer <= 0;
            buffer <= 0;
        end else if (iChangeParam) begin
            buffer <= iRiceParam << 12;
            bit_pointer <= bit_pointer + 4;
        end else begin
            // We can place the data straight into this buffer wihtout sending
            if (bit_pointer + iTotal <= 15) begin
                buffer <= buffer | (iLower << (16 - iTotal - bit_pointer));
                bit_pointer <= bit_pointer + iTotal;
                
            // The data fits perfectly into one buffer, so we send it
            end else if (bit_pointer + iTotal == 16) begin
                first_write_done <= 1;
                ram_dat1 <= buffer | iLower;
                ram_adr1 <= ram_adr_prev + first_write_done;
                ram_adr_prev <= ram_adr_prev + first_write_done;
                ram_we1 <= 1;
                
                buffer <= 0;
                bit_pointer <= 0;
            
            // The data overflows one buffer
            end else if (bit_pointer + iTotal > 16 && bit_pointer + iTotal <= 32) begin 
                // In this case we need to write some of the lower bits to the buffer before
                // we send it off. Then we need to write the rest of the lower bits to the 
                // next buffer
                first_write_done <= 1;
                ram_we1 <= 1;
                ram_adr1 <= ram_adr_prev + first_write_done;
    
                ram_adr_prev <= ram_adr_prev + first_write_done;
                
                
                ram_dat1 <= buffer | iLower >> (bit_pointer + iTotal - 16);
                
                buffer <= iLower << 32 - bit_pointer - iTotal;
                
                bit_pointer <= bit_pointer + iTotal - 16;
                
            // The data overflows multiple buffers
            end else if (iTotal + bit_pointer > 32) begin
                first_write_done <= 1;
                ram_dat1 <= buffer;
                ram_adr1 <= ram_adr_prev + first_write_done;
                ram_we1 <= 1;
                
                // once we have sent the first buffer it is the same as if 
                // bp = 0 and upper = upper - (16 - bp_prev)
                if (totaln <= 15) begin
                    buffer <= iLower << (16 - totaln);
                    ram_adr_prev <= ram_adr_prev + first_write_done + skip;
                    bit_pointer <= totaln;
                end else if (totaln == 16) begin
                    buffer <= 0;
                    bit_pointer <= 0;
                    ram_dat2 <= iLower;
                    ram_we2 <= 1;
                    ram_adr2 <= ram_adr_prev + first_write_done + skip + 1;
                    ram_adr_prev <= ram_adr_prev + first_write_done + skip + 1;
                end else if (totaln > 16) begin
                    ram_dat2 <= iLower >> (totaln - 16);
                    ram_we2 <= 1;
                    ram_adr2 <= ram_adr_prev + first_write_done + skip + 1;
                    ram_adr_prev <= ram_adr_prev + first_write_done + skip + 1;
                    buffer <= iLower << (32 - totaln);
                    bit_pointer <= totaln - 16;
                end
            end
        end
    end
end
endmodule