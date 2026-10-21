`timescale 1ns/1ps
import qpsk_coef_pkg::*;
 
module rrc_fir (
    input  wire                     aclk,
    input  wire                     aresetn,
    input  wire                     en,
    input  wire signed [DATA_W-1:0] x,
    output wire signed [DATA_W-1:0] y
);
    localparam int ACC_W = DATA_W + COEF_W + 6;
    logic signed [ACC_W-1:0] acc [NTAPS];
 
    integer k;
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            for (k=0;k<NTAPS;k=k+1) acc[k] <= '0;
        end else if (en) begin
            acc[NTAPS-1] <= RRC_TAPS[NTAPS-1] * x;
            for (k=0;k<NTAPS-1;k=k+1)
                acc[k] <= RRC_TAPS[k]*x + acc[k+1];
        end
    end
 
    wire signed [ACC_W-1:0] y_full = acc[0] >>> COEF_FRAC;
    assign y = y_full[DATA_W-1:0];
endmodule