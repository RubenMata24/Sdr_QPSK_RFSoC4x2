`timescale 1ns / 1ps
module prbs_ber_check_auto #(
    parameter int L     = 15,
    parameter int LOCKN = 64
)(
    input  wire        clk,
    input  wire        rstn,
    input  wire        clr,
    input  wire [7:0]  rx_bits,
    input  wire        rx_valid,
    output wire        in_sync,
    output wire [1:0]  locked_rot,
    output wire [63:0] bit_count,
    output wire [63:0] error_count
);
    wire [3:0]  sy_i;
    wire [63:0] bc_i [0:3];
    wire [63:0] ec_i [0:3];

    genvar gi;
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_rot
            prbs_ber_check #(.L(L), .LOCKN(LOCKN)) u (
                .clk(clk), .rstn(rstn), .clr(clr), .rot(gi[1:0]),
                .rx_bits(rx_bits), .rx_valid(rx_valid),
                .in_sync(sy_i[gi]), .bit_count(bc_i[gi]), .error_count(ec_i[gi]));
        end
    endgenerate

    logic [1:0] sel;
    always_comb begin
        if      (sy_i[0]) sel = 2'd0;
        else if (sy_i[1]) sel = 2'd1;
        else if (sy_i[2]) sel = 2'd2;
        else if (sy_i[3]) sel = 2'd3;
        else              sel = 2'd0;
    end

    assign in_sync     = |sy_i;
    assign locked_rot  = sel;
    assign bit_count   = bc_i[sel];
    assign error_count = ec_i[sel];
endmodule
