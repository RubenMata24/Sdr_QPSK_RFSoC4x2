`timescale 1ns/1ps
module rrc_mf_top (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire        en,
    input  wire [63:0] x_tdata,
    output wire [63:0] y_tdata
);
    rrc_mf u_mf (
        .aclk(aclk),
        .aresetn(aresetn),
        .en(en),
        .x_tdata(x_tdata),
        .y_tdata(y_tdata)
    );
endmodule
