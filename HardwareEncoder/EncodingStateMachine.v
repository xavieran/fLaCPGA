`default_nettype none

module EncodingStateMachine(
    input wire iClock, 
    input wire iEnable,
    input wire iReset,
    input wire signed [15:0] iRamReadData,
    output wire [11:0] oRamReadAddr,
    output wire signed [15:0] oRamWriteData,
    output wire [11:0] oRamWriteAddr,
    output wire oRamWriteEnable);

/*
 * #1. Run through the data in memory and find the fixed encoder with the
 *     smallest absolute error sum 
 * 2. Select the best encoder and run through the data calculating the residual and 
 *    storing it in internal RAM
 * 3. Run the rice encoder over the internal RAM and find the optimum set of rice parameters
 *    for each partition size. FOR SIMPLICITIES SAKE: select partition order 0. (1 partition)
 * 4. Run the residuals through the best rice encoder for each partition, storing MSBs and LSBs 
 *    in an internal RAM
 * 5. Walk through the internal RAM with the residuals stored and write the results into external
 *    RAM
 */
 
parameter S_MIN_ERR = 0, S_CALC_RES = 1, S_WRITE_RES = 2, S_ENC_RICE = 3;
parameter BLOCK_SIZE = 4096;

wire [2:0] best_fixed_encoder;
wire [3:0] best_rice_param;
wire signed [15:0] iSample = iRamReadData;

reg [11:0] ram_read_addr;
assign oRamReadAddr = ram_read_addr;

reg encoder_enable, choose_enable, encoder_reset, choose_reset, 
    rice_enc_reset, cbr_enable, cbr_reset;
 
reg signed [15:0] best_sample;
reg [15:0] best_msb, best_lsb;

reg [3:0] state;
reg [12:0] sample_count;

wire signed [15:0] FE0_residual;
wire signed [15:0] FE1_residual;
wire signed [15:0] FE2_residual;
wire signed [15:0] FE3_residual;
wire signed [15:0] FE4_residual;

wire [15:0] MSB_re_0, LSB_re_0;
wire [16:0] BU_re_0;
wire [15:0] MSB_re_1, LSB_re_1;
wire [16:0] BU_re_1;
wire [15:0] MSB_re_2, LSB_re_2;
wire [16:0] BU_re_2;
wire [15:0] MSB_re_3, LSB_re_3;
wire [16:0] BU_re_3;
wire [15:0] MSB_re_4, LSB_re_4;
wire [16:0] BU_re_4;
wire [15:0] MSB_re_5, LSB_re_5;
wire [16:0] BU_re_5;
wire [15:0] MSB_re_6, LSB_re_6;
wire [16:0] BU_re_6;
wire [15:0] MSB_re_7, LSB_re_7;
wire [16:0] BU_re_7;
wire [15:0] MSB_re_8, LSB_re_8;
wire [16:0] BU_re_8;
wire [15:0] MSB_re_9, LSB_re_9;
wire [16:0] BU_re_9;
wire [15:0] MSB_re_10, LSB_re_10;
wire [16:0] BU_re_10;
wire [15:0] MSB_re_11, LSB_re_11;
wire [16:0] BU_re_11;
wire [15:0] MSB_re_12, LSB_re_12;
wire [16:0] BU_re_12;
wire [15:0] MSB_re_13, LSB_re_13;
wire [16:0] BU_re_13;
wire [15:0] MSB_re_14, LSB_re_14;
wire [16:0] BU_re_14;

always @(posedge iClock) begin
    if (iReset) begin
        state <= S_MIN_ERR;
        sample_count <= 0;
        encoder_enable <= 1'b0;
        choose_enable <= 1'b0;
        cbr_enable <= 1'b0;
        encoder_reset <= 1'b1;
        choose_reset <= 1'b1;
        cbr_reset <= 1'b1;
        rice_enc_reset <= 1'b1;
        
        best_sample <= 0;
        best_msb <= 0;
        best_lsb <= 0;
    end else if (iEnable) begin
        case (state) 
            S_MIN_ERR:
            begin
                if (sample_count == 0) begin
                    sample_count <= sample_count + 1'b1;
                    ram_read_addr <= sample_count;
                end else if (sample_count < BLOCK_SIZE) begin
                    sample_count <= sample_count + 1'b1;
                    ram_read_addr <= sample_count;
                    encoder_enable <= 1'b1;
                    encoder_reset <= 1'b0;
                    choose_enable <= 1'b1;
                    choose_reset <= 1'b0;
                end else begin
                    state <= S_CALC_RES;
                    // Reset the encoders 
                    encoder_enable <= 1'b0;
                    encoder_reset <= 1'b1;
                    
                    // Disable the chooser but keep the best option for now
                    choose_enable <= 1'b0;
                    ram_read_addr <= 0;
                    sample_count <= 0;
                end
            end
                
            S_CALC_RES:
            begin
                if (sample_count == 0) begin
                    sample_count <= sample_count + 1'b1;
                    ram_read_addr <= sample_count;
                end else if (sample_count < BLOCK_SIZE) begin
                    sample_count <= sample_count + 1'b1;
                    ram_read_addr <= sample_count;
                    cbr_enable <= 1'b1;
                    cbr_reset <= 1'b0;
                    encoder_enable <= 1'b1;
                    encoder_reset <= 1'b0;
                    rice_enc_reset <= 1'b0;
                    
                    case (best_fixed_encoder) 
                        3'b000: best_sample <= FE0_residual;
                        3'b001: best_sample <= FE1_residual;
                        3'b010: best_sample <= FE2_residual;
                        3'b011: best_sample <= FE3_residual;
                        3'b100: best_sample <= FE4_residual;
                    endcase
                
                end else begin
                    state <= S_WRITE_RES;
                    encoder_enable <= 1'b0;
                    encoder_reset <= 1'b1;
                    
                    cbr_enable <= 1'b0;
                    rice_enc_reset <= 1'b1;
                    
                    ram_read_addr <= 1'b0;
                    sample_count <= 1'b0;
                end
            end
            
            S_WRITE_RES:
            begin
                // First we must write the prelude...
                // residual type <2> partition order <4> rice_param <4> ...
                if (sample_count == 0) begin
                    sample_count <= sample_count + 1'b1;
                    ram_read_addr <= sample_count;
                end else if (sample_count < BLOCK_SIZE) begin
                    sample_count <= sample_count + 1'b1;
                    ram_read_addr <= sample_count;
                    
                    encoder_enable <= 1'b1;
                    encoder_reset <= 1'b0;
                    rice_enc_reset <= 1'b0;
                    
                    case (best_fixed_encoder)
                        3'b000: best_sample <= FE0_residual;
                        3'b001: best_sample <= FE1_residual;
                        3'b010: best_sample <= FE2_residual;
                        3'b011: best_sample <= FE3_residual;
                        3'b100: best_sample <= FE4_residual;
                    endcase
                    
                    case (best_rice_param) 
                        4'b0000: begin best_msb <= MSB_re_0; best_lsb <= LSB_re_0; end
                        4'b0001: begin best_msb <= MSB_re_1; best_lsb <= LSB_re_1; end
                        4'b0010: begin best_msb <= MSB_re_2; best_lsb <= LSB_re_2; end
                        4'b0011: begin best_msb <= MSB_re_3; best_lsb <= LSB_re_3; end
                        4'b0100: begin best_msb <= MSB_re_4; best_lsb <= LSB_re_4; end
                        4'b0101: begin best_msb <= MSB_re_5; best_lsb <= LSB_re_5; end
                        4'b0110: begin best_msb <= MSB_re_6; best_lsb <= LSB_re_6; end
                        4'b0111: begin best_msb <= MSB_re_7; best_lsb <= LSB_re_7; end
                        4'b1000: begin best_msb <= MSB_re_8; best_lsb <= LSB_re_8; end
                        4'b1001: begin best_msb <= MSB_re_9; best_lsb <= LSB_re_9; end
                        4'b1010: begin best_msb <= MSB_re_10; best_lsb <= LSB_re_10; end
                        4'b1011: begin best_msb <= MSB_re_11; best_lsb <= LSB_re_11; end
                        4'b1100: begin best_msb <= MSB_re_12; best_lsb <= LSB_re_12; end
                        4'b1101: begin best_msb <= MSB_re_13; best_lsb <= LSB_re_13; end
                        4'b1110: begin best_msb <= MSB_re_14; best_lsb <= LSB_re_14; end
                    endcase
                
                end else begin
                    state <= S_WRITE_RES;
                    encoder_enable <= 1'b0;
                    encoder_reset <= 1'b1;
                    
                    cbr_enable <= 1'b0;
                    rice_enc_reset <= 1'b1;
                    
                    ram_read_addr <= 1'b0;
                    sample_count <= 1'b0;
                end
            end
            
            
            default:
            begin
            end
        endcase
    end
end


/* Module instantiations */ 
ChooseBestFixed cbf (
    .iClock(iClock),
    .iEnable(choose_enable), 
    .iReset(choose_reset),
    .FE0_residual(FE0_residual),
    .FE1_residual(FE1_residual),
    .FE2_residual(FE2_residual),
    .FE3_residual(FE3_residual),
    .FE4_residual(FE4_residual),
    .oBest(best_fixed_encoder)
    );

FixedEncoderOrder0 FEO0 (
    .iEnable(encoder_enable),
    .iReset(encoder_reset),
    .iClock(iClock),
    .iSample(iSample),
    .oResidual(FE0_residual)); 

FixedEncoderOrder1 FEO1 ( 
      .iEnable(encoder_enable),
      .iReset(encoder_reset),
      .iClock(iClock),
      .iSample(iSample),
      .oResidual(FE1_residual)); 

FixedEncoderOrder2 FEO2  ( 
      .iEnable(encoder_enable),
      .iReset(encoder_reset),
      .iClock(iClock),
      .iSample(iSample),
      .oResidual(FE2_residual)); 

FixedEncoderOrder3 FEO3  ( 
      .iEnable(encoder_enable),
      .iReset(encoder_reset),
      .iClock(iClock),
      .iSample(iSample),
      .oResidual(FE3_residual)); 

FixedEncoderOrder4 FEO4 ( 
      .iEnable(encoder_enable),
      .iReset(encoder_reset),
      .iClock(iClock),
      .iSample(iSample),
      .oResidual(FE4_residual)); 
 
ChooseBestRice CBR (
    .iClock(iClock), 
    .iEnable(cbr_enable), 
    .iReset(cbr_reset), 
    .iRE_BU_0(BU_re_0),
    .iRE_BU_1(BU_re_1),
    .iRE_BU_2(BU_re_2),
    .iRE_BU_3(BU_re_3),
    .iRE_BU_4(BU_re_4),
    .iRE_BU_5(BU_re_5),
    .iRE_BU_6(BU_re_6),
    .iRE_BU_7(BU_re_7),
    .iRE_BU_8(BU_re_8),
    .iRE_BU_9(BU_re_9),
    .iRE_BU_10(BU_re_10),
    .iRE_BU_11(BU_re_11),
    .iRE_BU_12(BU_re_12),
    .iRE_BU_13(BU_re_13),
    .iRE_BU_14(BU_re_14),
    .oBest(best_rice_param)
    );



RiceEncoder #(.rice_param(0))
    RE0 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_0),
    .oLSB(LSB_re_0),
    .oBitsUsed(BU_re_0));


RiceEncoder #(.rice_param(1))
    RE1 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_1),
    .oLSB(LSB_re_1),
    .oBitsUsed(BU_re_1));


RiceEncoder #(.rice_param(2))
    RE2 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_2),
    .oLSB(LSB_re_2),
    .oBitsUsed(BU_re_2));


RiceEncoder #(.rice_param(3))
    RE3 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_3),
    .oLSB(LSB_re_3),
    .oBitsUsed(BU_re_3));


RiceEncoder #(.rice_param(4))
    RE4 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_4),
    .oLSB(LSB_re_4),
    .oBitsUsed(BU_re_4));


RiceEncoder #(.rice_param(5))
    RE5 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_5),
    .oLSB(LSB_re_5),
    .oBitsUsed(BU_re_5));


RiceEncoder #(.rice_param(6))
    RE6 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_6),
    .oLSB(LSB_re_6),
    .oBitsUsed(BU_re_6));


RiceEncoder #(.rice_param(7))
    RE7 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_7),
    .oLSB(LSB_re_7),
    .oBitsUsed(BU_re_7));


RiceEncoder #(.rice_param(8))
    RE8 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_8),
    .oLSB(LSB_re_8),
    .oBitsUsed(BU_re_8));


RiceEncoder #(.rice_param(9))
    RE9 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_9),
    .oLSB(LSB_re_9),
    .oBitsUsed(BU_re_9));


RiceEncoder #(.rice_param(10))
    RE10 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_10),
    .oLSB(LSB_re_10),
    .oBitsUsed(BU_re_10));


RiceEncoder #(.rice_param(11))
    RE11 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_11),
    .oLSB(LSB_re_11),
    .oBitsUsed(BU_re_11));


RiceEncoder #(.rice_param(12))
    RE12 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_12),
    .oLSB(LSB_re_12),
    .oBitsUsed(BU_re_12));


RiceEncoder #(.rice_param(13))
    RE13 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_13),
    .oLSB(LSB_re_13),
    .oBitsUsed(BU_re_13));


RiceEncoder #(.rice_param(14))
    RE14 (
    .iClk(iClock),
    .iReset(rice_enc_reset),
    .iSample(best_sample),
    .oMSB(MSB_re_14),
    .oLSB(LSB_re_14),
    .oBitsUsed(BU_re_14));


endmodule