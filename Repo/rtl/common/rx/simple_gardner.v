`timescale 1ns/1ps
module simple_gardner #(parameter integer PHASE = 0)(
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [63:0] s_i_tdata,
    input  wire [63:0] s_q_tdata,
    input  wire        s_valid,
    input  wire [0:0]  loop_inv,

    output wire [15:0] m_axis_i_tdata,
    output wire        m_axis_i_tvalid,
    input  wire        m_axis_i_tready,
    output wire [15:0] m_axis_q_tdata,
    output wire        m_axis_q_tvalid,
    input  wire        m_axis_q_tready,
    output wire [17:0] ted_err
);
    wire [15:0] mi, mq;
    wire        mv;
    gardner_ted #(.PHASE(PHASE)) u_core (
        .aclk(aclk), .aresetn(aresetn),
        .s_i_tdata(s_i_tdata), .s_q_tdata(s_q_tdata), .s_valid(s_valid),
        .loop_inv(loop_inv[0]),
        .m_i_tdata(mi), .m_q_tdata(mq), .m_valid(mv),
        .ted_err(ted_err)
    );
    assign m_axis_i_tdata  = mi;
    assign m_axis_q_tdata  = mq;
    assign m_axis_i_tvalid = mv;
    assign m_axis_q_tvalid = mv;
endmodule