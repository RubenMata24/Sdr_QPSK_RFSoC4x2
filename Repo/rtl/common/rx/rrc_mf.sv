`timescale 1ns/1ps

module rrc_mf (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire        en,
    input  wire [63:0] x_tdata,
    output wire [63:0] y_tdata
);
    localparam int NTAPS = 65;
    localparam int CF    = 14;
 
    localparam logic signed [15:0] H [0:NTAPS-1] = '{
        42, 32, 19, 3, -16, -37, -59, -80, -100, -117, -131, -138, -140, -134,
        -119, -95, -63, -21, 30, 88, 153, 224, 298, 374, 450, 524, 593, 655,
        709, 753, 785, 805, 812, 805, 785, 753, 709, 655, 593, 524, 450, 374,
        298, 224, 153, 88, 30, -21, -63, -95, -119, -134, -140, -138, -131,
        -117, -100, -80, -59, -37, -16, 3, 19, 32, 42 };
 
    logic signed [15:0] z [0:NTAPS+2];
    wire signed [15:0] s0 = $signed(x_tdata[15:0]);
    wire signed [15:0] s1 = $signed(x_tdata[31:16]);
    wire signed [15:0] s2 = $signed(x_tdata[47:32]);
    wire signed [15:0] s3 = $signed(x_tdata[63:48]);
 
    integer i, o, k, j;
 
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            for (i=0;i<NTAPS+3;i=i+1) z[i] <= '0;
        end else if (en) begin
            for (i=NTAPS+2;i>=4;i=i-1) z[i] <= z[i-4];
            z[3] <= s0; z[2] <= s1; z[1] <= s2; z[0] <= s3;
        end
    end
 
    logic signed [39:0] L0 [0:3][0:64];
    logic signed [39:0] L1 [0:3][0:32];
    logic signed [39:0] L2 [0:3][0:16];
    logic signed [39:0] L3 [0:3][0:8];
    logic signed [39:0] L4 [0:3][0:4];
    logic signed [39:0] L5 [0:3][0:2];
    logic signed [39:0] L6 [0:3][0:1];
    logic signed [39:0] L7 [0:3];
 
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            for (o=0;o<4;o=o+1) begin
                for (k=0;k<65;k=k+1) L0[o][k] <= '0;
                for (k=0;k<33;k=k+1) L1[o][k] <= '0;
                for (k=0;k<17;k=k+1) L2[o][k] <= '0;
                for (k=0;k<9; k=k+1) L3[o][k] <= '0;
                for (k=0;k<5; k=k+1) L4[o][k] <= '0;
                for (k=0;k<3; k=k+1) L5[o][k] <= '0;
                for (k=0;k<2; k=k+1) L6[o][k] <= '0;
                L7[o] <= '0;
            end
        end else if (en) begin
            for (o=0;o<4;o=o+1) begin
                for (k=0;k<65;k=k+1) L0[o][k] <= H[k] * z[3-o+k];
                for (j=0;j<32;j=j+1) L1[o][j] <= L0[o][2*j] + L0[o][2*j+1];
                L1[o][32] <= L0[o][64];
                for (j=0;j<16;j=j+1) L2[o][j] <= L1[o][2*j] + L1[o][2*j+1];
                L2[o][16] <= L1[o][32];
                for (j=0;j<8;j=j+1)  L3[o][j] <= L2[o][2*j] + L2[o][2*j+1];
                L3[o][8] <= L2[o][16];
                for (j=0;j<4;j=j+1)  L4[o][j] <= L3[o][2*j] + L3[o][2*j+1];
                L4[o][4] <= L3[o][8];
                for (j=0;j<2;j=j+1)  L5[o][j] <= L4[o][2*j] + L4[o][2*j+1];
                L5[o][2] <= L4[o][4];
                L6[o][0] <= L5[o][0] + L5[o][1];
                L6[o][1] <= L5[o][2];
                L7[o]    <= L6[o][0] + L6[o][1];
            end
        end
    end
 
    function automatic logic signed [15:0] sat16 (input logic signed [39:0] v);
        logic signed [39:0] sh;
        sh = v >>> CF;
        if      (sh >  40'sd32767)  sat16 = 16'sd32767;
        else if (sh < -40'sd32768)  sat16 = -16'sd32768;
        else                        sat16 = sh[15:0];
    endfunction
 
    assign y_tdata[15:0]  = sat16(L7[0]);
    assign y_tdata[31:16] = sat16(L7[1]);
    assign y_tdata[47:32] = sat16(L7[2]);
    assign y_tdata[63:48] = sat16(L7[3]);
endmodule