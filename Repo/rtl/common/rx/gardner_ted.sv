`timescale 1ns/1ps
import qpsk_coef_pkg::*;

module gardner_ted #(
    parameter integer PHASE = 0
)(
    input  wire               aclk,
    input  wire               aresetn,
    input  wire        [63:0] s_i_tdata,
    input  wire        [63:0] s_q_tdata,
    input  wire               s_valid,
    input  wire               loop_inv,
    output wire signed [15:0] m_i_tdata,
    output wire signed [15:0] m_q_tdata,
    output wire               m_valid,
    output wire signed [17:0] ted_err
);
    localparam int THRESH = 256;
    localparam int SHIFT  = 12;
 
    wire en = s_valid;
 
    logic [1:0] c;
    always_ff @(posedge aclk)
        if (!aresetn) c <= 2'd0;
        else if (en)  c <= (c == 2'd3) ? 2'd0 : c + 2'd1;
 
    wire signed [15:0] li0=$signed(s_i_tdata[0+:16]), li1=$signed(s_i_tdata[16+:16]),
                       li2=$signed(s_i_tdata[32+:16]), li3=$signed(s_i_tdata[48+:16]);
    wire signed [15:0] lq0=$signed(s_q_tdata[0+:16]), lq1=$signed(s_q_tdata[16+:16]),
                       lq2=$signed(s_q_tdata[32+:16]), lq3=$signed(s_q_tdata[48+:16]);
 
    logic signed [15:0] buf_i[0:15], buf_q[0:15], prv_i[0:15], prv_q[0:15];
    (* mark_debug="true" *) logic [3:0]        tau;
    (* mark_debug="true" *) logic signed [31:0] acc;
 
    wire [3:0] mid_idx = tau ^ 4'd8;
    wire signed [15:0] strobe_i = buf_i[tau];
    wire signed [15:0] strobe_q = buf_q[tau];
    wire signed [15:0] prevst_i = prv_i[tau];
    wire signed [15:0] prevst_q = prv_q[tau];
    wire signed [15:0] mid_i = tau[3] ? buf_i[mid_idx] : prv_i[mid_idx];
    wire signed [15:0] mid_q = tau[3] ? buf_q[mid_idx] : prv_q[mid_idx];
 
    logic signed [15:0] sI,sQ,pI,pQ,mI,mQ;
    logic signed [16:0] dI,dQ;
    logic signed [33:0] eI,eQ;
    (* mark_debug="true" *) logic signed [34:0] err;
    logic v_str;
 
    wire signed [34:0] e_full = err >>> SHIFT;
    wire signed [17:0] e_s =
        (e_full >  35'sd131071) ?  18'sd131071 :
        (e_full < -35'sd131072) ? -18'sd131072 : e_full[17:0];
    wire signed [31:0] e_s32 = e_s;
    wire signed [31:0] e_ext = loop_inv ? -e_s32 : e_s32;
    wire signed [31:0] acc_n = acc + e_ext;
 
    integer k;
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            for (k=0;k<16;k=k+1) begin buf_i[k]<='0; buf_q[k]<='0; prv_i[k]<='0; prv_q[k]<='0; end
            tau<=PHASE[3:0]; acc<='0;
            sI<='0;sQ<='0;pI<='0;pQ<='0;mI<='0;mQ<='0; dI<='0;dQ<='0; eI<='0;eQ<='0; err<='0; v_str<=1'b0;
        end else if (en) begin
            buf_i[{c,2'b00}]<=li0; buf_i[{c,2'b01}]<=li1; buf_i[{c,2'b10}]<=li2; buf_i[{c,2'b11}]<=li3;
            buf_q[{c,2'b00}]<=lq0; buf_q[{c,2'b01}]<=lq1; buf_q[{c,2'b10}]<=lq2; buf_q[{c,2'b11}]<=lq3;
            v_str <= (c == 2'd0);
            case (c)
              2'd0: begin
                  for (k=0;k<16;k=k+1) begin prv_i[k]<=buf_i[k]; prv_q[k]<=buf_q[k]; end
                  sI<=strobe_i; sQ<=strobe_q;
                  pI<=prevst_i; pQ<=prevst_q;
                  mI<=mid_i;    mQ<=mid_q;
                  if (acc_n > THRESH)       begin tau<=tau-4'd1; acc<=acc_n - THRESH; end
                  else if (acc_n < -THRESH) begin tau<=tau+4'd1; acc<=acc_n + THRESH; end
                  else                       acc<=acc_n;
              end
              2'd1: begin dI<=sI - pI; dQ<=sQ - pQ; end
              2'd2: begin eI<=mI*dI;  eQ<=mQ*dQ;  end
              2'd3: begin err<=eI + eQ;            end
            endcase
        end
    end
 
    assign m_i_tdata = sI;
    assign m_q_tdata = sQ;
    assign m_valid   = v_str;
    assign ted_err   = e_s;
endmodule