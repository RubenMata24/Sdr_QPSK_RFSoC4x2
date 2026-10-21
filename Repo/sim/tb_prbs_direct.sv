`timescale 1ns / 1ps
module tb_prbs_direct;

    logic clk  = 1'b0;
    logic rstn = 1'b0;
    always #2 clk = ~clk;

    wire [1:0] dibit;
    PRBS_core u_gen (
        .aclk(clk), .aresetn(rstn), .dibit(dibit)
    );

    // Sincronizador
    wire        in_sync;
    wire [1:0]  locked_rot;
    wire [63:0] bit_count, error_count;
    prbs_ber_check_auto #(.L(15), .LOCKN(64)) u_chk (
        .clk(clk), .rstn(rstn), .clr(1'b0),
        .rx_bits(dibit), .rx_valid(1'b1),
        .in_sync(in_sync), .locked_rot(locked_rot),
        .bit_count(bit_count), .error_count(error_count)
    );

    initial begin
        repeat (10) @(posedge clk);
        rstn = 1'b1;
        repeat (5000) @(posedge clk);
        if (in_sync && (error_count == 64'd0) && (bit_count > 64'd0))
            $display("PASS: in_sync=%0d rot=%0d bits=%0d errores=%0d",
                     in_sync, locked_rot, bit_count, error_count);
        else
            $display("FAIL: in_sync=%0d rot=%0d bits=%0d errores=%0d",
                     in_sync, locked_rot, bit_count, error_count);
        $finish;
    end

endmodule
