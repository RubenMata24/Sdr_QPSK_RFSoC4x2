`timescale 1ns / 1ps

module PRBS_core(
    input  wire       aclk,
    input  wire       aresetn,
    input  wire       en,
    output reg [1:0]  dibit
);
    reg [14:0] pr;
    reg ba, bb;
    reg [14:0] p1;
 
    always @(posedge aclk) begin
        if (!aresetn) begin
            pr    <= 15'h7FFF;
            dibit <= 2'b00;
        end else if (en) begin
            ba = pr[0] ^ pr[14];
            p1 = {pr[13:0], ba};
            bb = p1[0] ^ p1[14];
            pr    <= {p1[13:0], bb};
            dibit <= {bb, ba};
        end
    end
endmodule