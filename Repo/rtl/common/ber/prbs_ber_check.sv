`timescale 1ns / 1ps
module prbs_ber_check #(
    parameter int L      = 15,
    parameter int LOCKN  = 64,
    parameter int UNLOCK = 512,
    parameter int ACC_UP = 16
)(
    input  wire        clk,
    input  wire        rstn,
    input  wire        clr,
    input  wire [1:0]  rot,
    input  wire [1:0]  rx_bits,
    input  wire        rx_valid,
    output reg         in_sync,
    output wire [63:0] bit_count,
    output wire [63:0] error_count
);
    reg [1:0] d;
    always_comb begin
        case (rot)
            2'd0: d = { rx_bits[1],  rx_bits[0]};
            2'd1: d = { rx_bits[0], ~rx_bits[1]};
            2'd2: d = {~rx_bits[1], ~rx_bits[0]};
            2'd3: d = {~rx_bits[0],  rx_bits[1]};
        endcase
    end
 
    reg [L-1:0] hist;
    reg [15:0]  good_run;
    reg [15:0]  err_acc;
 
    reg [31:0] bit_lo, bit_hi;
    reg [31:0] err_lo, err_hi;
    reg        bit_cy, err_cy;
 
    always_ff @(posedge clk) begin
        if (!rstn || clr) begin
            hist <= '0; good_run <= '0; in_sync <= 1'b0; err_acc <= 16'd0;
            bit_lo <= 32'd0; bit_hi <= 32'd0; bit_cy <= 1'b0;
            err_lo <= 32'd0; err_hi <= 32'd0; err_cy <= 1'b0;
        end else if (rx_valid) begin
            logic [L-1:0] h;
            logic [15:0]  gr;
            logic         sy;
            logic         cnt_en, pred, b, err;
            logic [1:0]   bc_inc, ec_inc;
            logic [1:0]   nerr;
            logic [16:0]  ea_up, ea_tmp;
            logic [32:0]  sum_b, sum_e;
 
            h = hist; gr = good_run; sy = in_sync;
            cnt_en = in_sync; bc_inc = 2'd0; ec_inc = 2'd0; nerr = 2'd0;
 
            if (in_sync && (err_acc > UNLOCK)) begin
                sy = 1'b0; gr = 16'd0;
            end
 
            for (int k = 0; k < 2; k++) begin
                b    = d[k];
                pred = h[0] ^ h[L-1];
                err  = (b != pred);
                if (cnt_en) begin
                    bc_inc = bc_inc + 2'd1;
                    if (err) ec_inc = ec_inc + 2'd1;
                end
                if (err) begin
                    gr   = 16'd0;
                    nerr = nerr + 2'd1;
                end else begin
                    if (gr < 16'hFFFF) gr = gr + 16'd1;
                    if (gr >= LOCKN)   sy = 1'b1;
                end
                h = {h[L-2:0], b};
            end
 
            ea_up   = err_acc + nerr * ACC_UP;
            ea_tmp  = (ea_up > (17'd2 - nerr)) ? (ea_up - (17'd2 - nerr)) : 17'd0;
            err_acc <= (ea_tmp > 17'd65535) ? 16'hFFFF : ea_tmp[15:0];
 
            hist <= h; good_run <= gr; in_sync <= sy;
 
            sum_b  = {1'b0, bit_lo} + bc_inc;
            sum_e  = {1'b0, err_lo} + ec_inc;
            bit_lo <= sum_b[31:0];  bit_hi <= bit_hi + bit_cy;  bit_cy <= sum_b[32];
            err_lo <= sum_e[31:0];  err_hi <= err_hi + err_cy;  err_cy <= sum_e[32];
        end
    end
 
    assign bit_count   = {bit_hi, bit_lo};
    assign error_count = {err_hi, err_lo};
endmodule