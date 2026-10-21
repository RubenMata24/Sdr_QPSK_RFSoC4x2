`timescale 1ns / 1ps
module dibit_mux (
    input  wire [0:0] sel,
    input  wire [1:0] dibit_prbs,
    input  wire [1:0] dibit_seq,
    output wire [1:0] dibit_out
);
    assign dibit_out = sel[0] ? dibit_seq : dibit_prbs;
endmodule