`timescale 1ns / 1ps
import qpsk_coef_pkg::*;
import nco_lut_pkg::*;
 
module qpsk_rx_core (
    input  wire           aclk,
    input  wire           aresetn,
    input  wire [15:0]    s_axis_i_tdata,
    input  wire           s_axis_i_tvalid,
    output wire           s_axis_i_tready,
    input  wire [15:0]    s_axis_q_tdata,
    input  wire           s_axis_q_tvalid,
    output wire           s_axis_q_tready,
    (* mark_debug="true" *) output reg  [1:0]  last_symbol_0,
    (* mark_debug="true" *) output reg  [1:0]  last_symbol_1,
    (* mark_debug="true" *) output reg  [1:0]  last_symbol_2,
    (* mark_debug="true" *) output reg  [1:0]  last_symbol_3,
    (* mark_debug="true" *) output reg  [31:0] symbol_counter,
    (* mark_debug="true" *) output wire        rx_valid
);
    localparam int KP = 6800;
    localparam int KI = 170;
 
    assign s_axis_i_tready = 1'b1;
    assign s_axis_q_tready = 1'b1;
    wire en = s_axis_i_tvalid & s_axis_q_tvalid;
 
    function automatic logic signed [DATA_W-1:0] sat16(input logic signed [31:0] x);
        if (x >  32'sd32767)      sat16 = 16'sd32767;
        else if (x < -32'sd32768) sat16 = -16'sd32768;
        else                      sat16 = x[DATA_W-1:0];
    endfunction
 
    wire signed [15:0] i_in = s_axis_i_tdata;
    wire signed [15:0] q_in = s_axis_q_tdata;
 
    (* mark_debug="true" *) logic signed [31:0] phi, freq;
    logic signed [31:0] kp_term, ki_term;
    logic signed [15:0]        symI0, symQ0;
    logic [$clog2(LUT_N)-1:0]  idx0;
    logic signed [15:0]        symI1, symQ1, cos1, sin1;
    logic signed [31:0]        pic2, pqs2, pqc2, pis2;
    (* mark_debug="true" *) logic signed [DATA_W-1:0] Id, Qd;
 
    wire signed [16:0] si_Qd = Id[DATA_W-1] ? -Qd : Qd;
    wire signed [16:0] sq_Id = Qd[DATA_W-1] ? -Id : Id;
    (* mark_debug="true" *) wire signed [17:0] costas_err = si_Qd - sq_Id;
 
    reg rx_valid_r;
    assign rx_valid = rx_valid_r;
 
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            symI0<='0; symQ0<='0; idx0<='0;
            symI1<='0; symQ1<='0; cos1<='0; sin1<='0;
            pic2<='0; pqs2<='0; pqc2<='0; pis2<='0;
            Id<='0; Qd<='0; phi<='0; freq<='0; kp_term<='0; ki_term<='0;
            last_symbol_0<=2'b00; last_symbol_1<=2'b00;
            last_symbol_2<=2'b00; last_symbol_3<=2'b00;
            symbol_counter<=32'd0; rx_valid_r<=1'b0;
        end else if (en) begin
            symI0 <= i_in;  symQ0 <= q_in;
            idx0  <= phi[31:22];
            cos1  <= SIN_LUT[(idx0 + QUARTER) & (LUT_N-1)];
            sin1  <= SIN_LUT[idx0];
            symI1 <= symI0; symQ1 <= symQ0;
            pic2 <= symI1 * cos1;
            pqs2 <= symQ1 * sin1;
            pqc2 <= symQ1 * cos1;
            pis2 <= symI1 * sin1;
            Id <= sat16((pic2 + pqs2) >>> LUT_Q);
            Qd <= sat16((pqc2 - pis2) >>> LUT_Q);
            kp_term <= KP * costas_err;
            ki_term <= KI * costas_err;
            freq <= freq + ki_term;
            phi  <= phi + freq + kp_term;
            last_symbol_3 <= last_symbol_2;
            last_symbol_2 <= last_symbol_1;
            last_symbol_1 <= last_symbol_0;
            last_symbol_0 <= {Qd[DATA_W-1], Id[DATA_W-1]};
            symbol_counter <= symbol_counter + 1'b1;
            rx_valid_r <= 1'b1;
        end else begin
            rx_valid_r <= 1'b0;
        end
    end
endmodule