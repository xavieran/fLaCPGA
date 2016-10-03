

module DurbinCoefficientStore (
    input wire iClock,
    input wire iEnable, 
    input wire iReset, 
    
    input wire iLoad,
    input wire [3:0] iM, 
    input wire signed [11:0] iCoeff, 
        
    input wire iUnload,
    input wire [3:0] iBestM, 
    
    output wire signed [11:0] oCoeff,
    output wire oValid,
    output wire oDone
    );

integer i;

reg signed [11:0] m1;
reg signed [11:0] m2 [0:1];
reg signed [11:0] m3 [0:2];
reg signed [11:0] m4 [0:3];
reg signed [11:0] m5 [0:4];
reg signed [11:0] m6 [0:5];
reg signed [11:0] m7 [0:6];
reg signed [11:0] m8 [0:7];
reg signed [11:0] m9 [0:8];
reg signed [11:0] m10 [0:9];
reg signed [11:0] m11 [0:10];
reg signed [11:0] m12 [0:11];

reg signed [11:0] coeff;
reg valid;
reg [3:0] best_count;
reg done;

assign oCoeff = coeff;
assign oValid = valid;
assign oDone = done;

always @(posedge iClock) begin
    if (iReset) begin
        m1 <= 0;
        m2[0] <= 0;
        m3[0] <= 0;
        m4[0] <= 0;
        m5[0] <= 0;
        m6[0] <= 0;
        m7[0] <= 0;
        m8[0] <= 0;
        m9[0] <= 0;
        m10[0] <= 0;
        m11[0] <= 0;
        m12[0] <= 0;
        
        coeff <= 0;
        valid <= 0;
        best_count <= 0;
        done <= 0;
    end else if (iEnable) begin
        valid <= 0;
        
        if (iLoad) begin
            if (iM == 1) begin
                m1 <= iCoeff;
            end else if (iM == 2) begin
                m2[1] <= m2[0];
                m2[0] <= iCoeff;
            end else if (iM == 3) begin
                m3[2] <= m3[1];
                m3[1] <= m3[0];
                m3[0] <= iCoeff;
            end else if (iM == 4) begin
                for (i = 3; i > 0; i = i - 1)
                    m4[i] <= m4[i - 1];
                m4[0] <= iCoeff;
            end else if (iM == 5) begin
                for (i = 4; i > 0; i = i - 1)
                    m5[i] <= m5[i - 1];
                m5[0] <= iCoeff;
            end else if (iM == 6) begin
                for (i = 5; i > 0; i = i - 1)
                    m6[i] <= m6[i - 1];
                m6[0] <= iCoeff;
            end else if (iM == 7) begin
                for (i = 6; i > 0; i = i - 1)
                    m7[i] <= m7[i - 1];
                m7[0] <= iCoeff;
            end else if (iM == 8) begin
                for (i = 7; i > 0; i = i - 1)
                    m8[i] <= m8[i - 1];
                m8[0] <= iCoeff;
            end else if (iM == 9) begin
                for (i = 8; i > 0; i = i - 1)
                    m9[i] <= m9[i - 1];
                m9[0] <= iCoeff;
            end else if (iM == 10) begin
                for (i = 9; i > 0; i = i - 1)
                    m10[i] <= m10[i - 1];
                m10[0] <= iCoeff;
            end else if (iM == 11) begin
                for (i = 10; i > 0; i = i - 1)
                    m11[i] <= m11[i - 1];
                m11[0] <= iCoeff;
            end else if (iM == 12) begin
                for (i = 11; i > 0; i = i - 1)
                    m12[i] <= m12[i - 1];
                m12[0] <= iCoeff;
            end
        end else if (iUnload) begin
            best_count <= best_count + !done;
            if (best_count == (iBestM - 1)) begin
                done <= 1;
            end
            
            if (iBestM == 1) begin
                coeff <= m1;
                valid <= 1;
            end else if (iBestM == 2) begin
                coeff <= m2[1];
                m2[1] <= m2[0];
                valid <= 1;
            end else if (iBestM == 3) begin
                coeff <= m3[2];
                m3[2] <= m3[1];
                m3[1] <= m3[0];
                valid <= 1;
            end else if (iBestM == 4) begin
                coeff <= m4[3];
                for (i = 3; i > 0; i = i - 1) begin
                    m4[i] <= m4[i - 1];
                end
                valid <= 1;
            end else if (iBestM == 5) begin
                coeff <= m5[4];
                for (i = 4; i > 0; i = i - 1) begin
                    m5[i] <= m5[i - 1];
                end
                valid <= 1;
            end else if (iBestM == 6) begin
                coeff <= m6[5];
                for (i = 5; i > 0; i = i - 1) begin
                    m6[i] <= m6[i - 1];
                end
                valid <= 1;
            end else if (iBestM == 7) begin
                coeff <= m7[6];
                for (i = 6; i > 0; i = i - 1) begin
                    m7[i] <= m7[i - 1];
                end
                valid <= 1;
            end else if (iBestM == 8) begin
                coeff <= m8[7];
                for (i = 7; i > 0; i = i - 1) begin
                    m8[i] <= m8[i - 1];
                end
                valid <= 1;
            end else if (iBestM == 9) begin
                coeff <= m9[8];
                for (i = 8; i > 0; i = i - 1) begin
                    m9[i] <= m9[i - 1];
                end
                valid <= 1;
            end else if (iBestM == 10) begin
                coeff <= m10[9];
                for (i = 9; i > 0; i = i - 1) begin
                    m10[i] <= m10[i - 1];
                end
                valid <= 1;
            end else if (iBestM == 11) begin
                coeff <= m11[10];
                for (i = 10; i > 0; i = i - 1) begin
                    m11[i] <= m11[i - 1];
                end
                valid <= 1;
            end else if (iBestM == 12) begin
                coeff <= m12[11];
                for (i = 11; i > 0; i = i - 1) begin
                    m12[i] <= m12[i - 1];
                end
                valid <= 1;
            end
            
            if (done) valid <= 0;
        end
    end
end

endmodule