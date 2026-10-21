`timescale 1ns / 1ps

module iq_pack (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axis_i:s_axis_q:m_axis, ASSOCIATED_RESET aresetn" *)
    input  wire        aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire        aresetn,
 
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_i TDATA" *)
    input  wire [15:0] s_axis_i_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_i TVALID" *)
    input  wire        s_axis_i_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_i TREADY" *)
    output wire        s_axis_i_tready,
 
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_q TDATA" *)
    input  wire [15:0] s_axis_q_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_q TVALID" *)
    input  wire        s_axis_q_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_q TREADY" *)
    output wire        s_axis_q_tready,
 
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TDATA" *)
    output wire [31:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TVALID" *)
    output wire        m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TREADY" *)
    input  wire        m_axis_tready
);
    assign m_axis_tdata    = {s_axis_q_tdata, s_axis_i_tdata};   
    assign m_axis_tvalid   = s_axis_i_tvalid & s_axis_q_tvalid;
    assign s_axis_i_tready = m_axis_tready;                       
    assign s_axis_q_tready = m_axis_tready;
endmodule