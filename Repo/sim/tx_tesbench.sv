`timescale 1ns / 1ps
module tb_tx_core;
    logic clk = 0, rstn = 0;
    always #2 clk = ~clk;
 
    // PRBS
    logic [1:0] dibit;
    logic [14:0] pr = 15'h7FFF;
    always @(posedge clk) begin
        logic ba, bb; logic [14:0] p1;
        if (!rstn) begin pr <= 15'h7FFF; dibit <= 2'b00; end
        else begin
            ba = pr[0] ^ pr[14]; p1 = {pr[13:0], ba};
            bb = p1[0] ^ p1[14]; pr <= {p1[13:0], bb};
            dibit <= {bb, ba};
        end
    end
 
    logic [15:0] i_data, q_data;
    logic i_valid, q_valid;
    logic i_ready = 1'b1, q_ready = 1'b1;
    logic [1:0] tx_dibit; logic tx_sym_load;
    qpsk_tx_core u_tx (
        .aclk(clk), .aresetn(rstn), .dibit(dibit),
        .m_axis_i_tdata(i_data), .m_axis_i_tvalid(i_valid), .m_axis_i_tready(i_ready),
        .m_axis_q_tdata(q_data), .m_axis_q_tvalid(q_valid), .m_axis_q_tready(q_ready),
        .tx_dibit(tx_dibit), .tx_sym_load(tx_sym_load));
 
    initial begin
        rstn = 0; repeat (10) @(posedge clk); rstn = 1;
        repeat (40) begin
            @(posedge clk);
            $display("t=%0t  dibit=%b  i_data=%0d  q_data=%0d  ivalid=%b iready=%b",
                     $time, dibit, $signed(i_data), $signed(q_data), i_valid, i_ready);
        end
        $finish;
    end
endmodule