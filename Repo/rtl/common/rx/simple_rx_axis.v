`timescale 1ns / 1ps

module simple_rx_axis (
    input  wire        aclk,
    input  wire        aresetn,
    // I <- ADC A (tile 226, m20_axis)
    input  wire [15:0] s_axis_i_tdata,
    input  wire        s_axis_i_tvalid,
    output wire        s_axis_i_tready,
    // Q <- ADC B (tile 226, m22_axis)
    input  wire [15:0] s_axis_q_tdata,
    input  wire        s_axis_q_tvalid,
    
    output wire        s_axis_q_tready,
    output wire [1:0]  last_symbol_0,
    output wire [1:0]  last_symbol_1,
    output wire [1:0]  last_symbol_2,
    output wire [1:0]  last_symbol_3,
    output wire [31:0] symbol_counter,
    output wire        rx_valid
);

    qpsk_rx_core u_core (
        .aclk(aclk), .aresetn(aresetn),
        .s_axis_i_tdata(s_axis_i_tdata), .s_axis_i_tvalid(s_axis_i_tvalid), .s_axis_i_tready(s_axis_i_tready),
        .s_axis_q_tdata(s_axis_q_tdata), .s_axis_q_tvalid(s_axis_q_tvalid), .s_axis_q_tready(s_axis_q_tready),
        .last_symbol_0(last_symbol_0), .last_symbol_1(last_symbol_1),
        .last_symbol_2(last_symbol_2), .last_symbol_3(last_symbol_3),
        .symbol_counter(symbol_counter), .rx_valid(rx_valid)

    );

endmodule
 