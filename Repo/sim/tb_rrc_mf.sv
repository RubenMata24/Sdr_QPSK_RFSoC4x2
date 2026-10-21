`timescale 1ns/1ps
module tb_rrc_mf;
  logic aclk=0, aresetn=0, en=0;
  logic [63:0] x=0, y;
 
  rrc_mf dut(.aclk(aclk), .aresetn(aresetn), .en(en), .x_tdata(x), .y_tdata(y));
 
  always #2 aclk = ~aclk;   // 250 MHz (periodo 4 ns)
 
  wire signed [15:0] y0=y[15:0], y1=y[31:16], y2=y[47:32], y3=y[63:48];
  integer cyc;
 
  initial begin
    aresetn=0; en=0; x=0;
    repeat(4) @(posedge aclk);
    aresetn=1; en=1;
 
    x = {16'sd0, 16'sd0, 16'sd0, 16'sd16384};
    @(posedge aclk);
    x = 0;
 
    for (cyc=0; cyc<24; cyc=cyc+1) begin
      @(posedge aclk);
      $display("cyc %0d  y0=%0d y1=%0d y2=%0d y3=%0d", cyc, y0, y1, y2, y3);
    end
    $finish;
  end
endmodule