`timescale 1ns / 1ps
module simple_tx_axis (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [1:0]  dibit,
    // I -> DAC A (tile 230, s20_axis)
    output wire [15:0] m_axis_i_tdata,
    output wire        m_axis_i_tvalid,
    input  wire        m_axis_i_tready,
    // Q -> DAC B (tile 228, s00_axis)
    output wire [15:0] m_axis_q_tdata,
    output wire        m_axis_q_tvalid,
    input  wire        m_axis_q_tready,
    output wire [1:0]  tx_dibit,
    output wire        tx_sym_load
);
qpsk_tx_core u_core (
    .aclk(aclk), .aresetn(aresetn), .dibit(dibit),
    .m_axis_i_tdata(m_axis_i_tdata), .m_axis_i_tvalid(m_axis_i_tvalid), .m_axis_i_tready(m_axis_i_tready),
    .m_axis_q_tdata(m_axis_q_tdata), .m_axis_q_tvalid(m_axis_q_tvalid), .m_axis_q_tready(m_axis_q_tready),
    .tx_dibit(tx_dibit), .tx_sym_load(tx_sym_load)
);
endmodule