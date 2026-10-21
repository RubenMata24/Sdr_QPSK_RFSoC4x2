`timescale 1ns / 1ps
package qpsk_coef_pkg;
  localparam int NTAPS     = 33;
  localparam int COEF_W    = 16;
  localparam int COEF_FRAC = 14;
  localparam int OSR       = 4;
  localparam int DATA_W    = 16;
  localparam int A_SYM     = 10000;
  localparam logic signed [COEF_W-1:0] RRC_TAPS [NTAPS] = '{ 17, 109, 78, -78, -209, -121, 210, 535, 468, -181, -1107, -1546, -694, 1695, 4980, 7842, 8977, 7842, 4980, 1695, -694, -1546, -1107, -181, 468, 535, 210, -121, -209, -78, 78, 109, 17 };
endpackage
