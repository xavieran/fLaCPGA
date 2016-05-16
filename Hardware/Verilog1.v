module Adder16Test(input iClock, 
                   input signed [15:0] A,
                   input signed [15:0] B, 
                   output signed [15:0]C);

reg signed [15:0] a, b, c;

assign C = c;

always @(posedge iClock) begin
    a <= A;
    b <= B;
    c <= a + b;
end
