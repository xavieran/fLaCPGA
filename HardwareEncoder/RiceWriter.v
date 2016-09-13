`default_nettype none


module RiceWriter (
    input wire iClock,
    input wire iReset, 
    input wire iEnable, 
    
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
 *
 */

/*
 * There are three possible cases when we receive a code
 * 1. There is enough space to fit the entire code word
 * 2. We overlap onto the next buffer
 * 3. We finish the current data buffer, and the next one, and overlap onto
 *    the third buffer
 */

reg [3:0] bit_pointer;

wire [15:0] overflow = bit_pointer + iTotal;
wire [15:0] overlap = (iUpper[3:0] + bit_pointer[3:0]) + iRiceParam + 1;
wire [3:0] upper_shift = 15 - bit_pointer - iUpper - iRiceParam;

// The amount to shift the lower bits by if we overflow the first buffer
wire [7:0] of_lshift = iUpper + bit_pointer;

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
        
        need_header <= 1;
    end else if (iEnable) begin
        if (need_header) begin
            buffer <= iRiceParam << 12;
            bit_pointer <= bit_pointer + 4;
            need_header <= 0;
        end else begin
            ram_we1 <= 0;
            ram_we2 <= 0;
            // We can place the data straight into this buffer wihtout sending
            if (overflow < 16) begin
                buffer <= buffer | (iLower << upper_shift);
                bit_pointer <= overflow;
                
            // We need to send the first buffer
            end else if (overflow == 16) begin
                first_write_done <= 1;
                ram_dat1 <= buffer | iLower;
                ram_adr1 <= ram_adr_prev + first_write_done;
                ram_adr_prev <= ram_adr_prev + first_write_done;
                ram_we1 <= 1;
                
                buffer <= 0;
                bit_pointer <= 0;
            end else if (overflow >= 17 && overflow < 32) begin 
                // In this case we need to write some of the lower bits to the buffer before
                // we send it off. Then we need to write the rest of the lower bits to the 
                // next buffer    
                first_write_done <= 1;
                ram_we1 <= 1;
                ram_adr1 <= ram_adr_prev + first_write_done;
                ram_adr_prev <= ram_adr_prev + first_write_done;
                
                if (of_lshift <= 15) begin
                    ram_dat1 <= buffer | (iLower >> (15 - of_lshift[3:0]));
                    buffer <= iLower << (of_lshift + 1 - iRiceParam);
                    bit_pointer <= iRiceParam - 1 - of_lshift;
                    
                /* If the upper bits pass beyond the current data buffer, 
                 * then we can send it without modifying it anymore */
                end else if (of_lshift > 15) begin
                    ram_dat1 <= buffer;
                    /* We can now write the rest of the stuff straight into the
                     * buffer */
                    buffer <= iLower << (15 - of_lshift[3:0] - iRiceParam);
                    bit_pointer <= of_lshift[3:0] + iRiceParam + 1;
                end
                
            // We need to send the first and second buffers and place data into buffer 3
            end else if (overflow >= 32) begin
                first_write_done <= 1;
                ram_dat1 <= buffer;
                ram_adr1 <= ram_adr_prev + first_write_done;
                ram_we1 <= 1;
                
                ram_adr2 <= ram_adr_prev + first_write_done + of_lshift[7:4];
                ram_adr_prev <= ram_adr_prev + first_write_done + of_lshift[7:4];
                ram_we2 <= 1;
                    
                bit_pointer <= overlap[3:0];
                
                if (overlap < 15) begin
                    ram_dat2 <= iLower << (15 - overlap + 1);
                    buffer <= 0;
                end else if (overlap >= 15) begin
                    ram_dat2 <= iLower >> (overlap - 15);
                    buffer <= iLower << (15 - overlap[3:0]);
                end
            end
        end
    end
end
endmodule