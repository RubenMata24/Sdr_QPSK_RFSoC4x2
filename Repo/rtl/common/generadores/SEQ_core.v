`timescale 1ns / 1ps
module SEQ_core(
    input  wire       aclk,
    input  wire       aresetn,
    input  wire       en,
    output reg  [1:0] dibit
);
    localparam integer SEQ_LEN = 32;
    reg [4:0] idx;
    reg [1:0] sym;
    always @(*) begin
        case (idx)
            5'd0:sym=2'd2;  5'd1:sym=2'd3;  5'd2:sym=2'd1;  5'd3:sym=2'd0;
            5'd4:sym=2'd3;  5'd5:sym=2'd0;  5'd6:sym=2'd2;  5'd7:sym=2'd1;
            5'd8:sym=2'd0;  5'd9:sym=2'd2;  5'd10:sym=2'd3; 5'd11:sym=2'd1;
            5'd12:sym=2'd1; 5'd13:sym=2'd3; 5'd14:sym=2'd0; 5'd15:sym=2'd2;
            5'd16:sym=2'd3; 5'd17:sym=2'd1; 5'd18:sym=2'd2; 5'd19:sym=2'd0;
            5'd20:sym=2'd0; 5'd21:sym=2'd1; 5'd22:sym=2'd3; 5'd23:sym=2'd2;
            5'd24:sym=2'd1; 5'd25:sym=2'd0; 5'd26:sym=2'd2; 5'd27:sym=2'd3;
            5'd28:sym=2'd2; 5'd29:sym=2'd1; 5'd30:sym=2'd3; 5'd31:sym=2'd0;
            default: sym=2'd0;
        endcase
    end
    always @(posedge aclk) begin
        if (!aresetn) begin
            idx   <= 5'd0;
            dibit <= 2'd2;
        end else if (en) begin
            dibit <= sym;
            idx   <= (idx==SEQ_LEN-1) ? 5'd0 : idx + 5'd1;
        end
    end
endmodule