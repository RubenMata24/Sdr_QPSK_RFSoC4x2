  `timescale 1ns/1ps

module tb_gardner;
 
  logic aclk = 0, aresetn = 0;
  always #2 aclk = ~aclk;
 
  logic [63:0] s_i_tdata, s_q_tdata;
  logic        s_valid;
  logic signed [15:0] m_i_tdata, m_q_tdata;
  logic        m_valid;
  logic signed [17:0] ted_err;
 
  gardner_ted #(.PHASE(4)) dut (
    .aclk(aclk), .aresetn(aresetn),
    .s_i_tdata(s_i_tdata), .s_q_tdata(s_q_tdata), .s_valid(s_valid),
    .m_i_tdata(m_i_tdata), .m_q_tdata(m_q_tdata), .m_valid(m_valid),
    .ted_err(ted_err)
  );
 
  localparam int A    = 8000;
  localparam int SPS  = 16;
  localparam int NSYM = 4096;
  localparam int NS   = NSYM*SPS;
 
  real pulse [0:SPS-1];
  logic signed [15:0] streamI [0:NS-1];
  logic signed [15:0] streamQ [0:NS-1];
 
  initial begin
    int si, sq;
    for (int n=0;n<SPS;n++) pulse[n] = 0.5*(1.0 - $cos(2.0*3.14159265*n/SPS));
    for (int s=0;s<NSYM;s++) begin
      si = ($urandom & 1) ? 1 : -1;
      sq = ($urandom & 1) ? 1 : -1;
      for (int p=0;p<SPS;p++) begin
        streamI[s*SPS+p] = $rtoi(si*A*pulse[p]);
        streamQ[s*SPS+p] = $rtoi(sq*A*pulse[p]);
      end
    end
  end
 
  int scnt;
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      scnt <= 0; s_valid <= 1'b0; s_i_tdata <= '0; s_q_tdata <= '0;
    end else if (scnt < NS-4) begin
      s_valid   <= 1'b1;
      s_i_tdata <= {streamI[scnt+3], streamI[scnt+2], streamI[scnt+1], streamI[scnt+0]};
      s_q_tdata <= {streamQ[scnt+3], streamQ[scnt+2], streamQ[scnt+1], streamQ[scnt+0]};
      scnt      <= scnt + 4;
    end
  end
 
  int    sym_cnt = 0;
  real   abs_sum = 0.0; int abs_cnt = 0;
  logic [3:0] tau_prev = 4'd4;
 
  always @(posedge aclk) if (aresetn && m_valid) begin
      sym_cnt = sym_cnt + 1;
      // imprime cada vez que tau cambia, para ver la trayectoria hacia el centro
      if (dut.tau !== tau_prev) begin
        $display("t=%0t  simbolo %0d   tau %0d -> %0d   (ted_err=%0d)",
                 $time, sym_cnt, tau_prev, dut.tau, $signed(ted_err));
        tau_prev = dut.tau;
      end
      // a partir del simbolo 2000 (ya deberia estar enganchado) mide el |error|
      if (sym_cnt > 2000) begin
        abs_sum = abs_sum + ((ted_err<0) ? -$itor($signed(ted_err)) : $itor($signed(ted_err)));
        abs_cnt = abs_cnt + 1;
      end
  end
 
  initial begin
    $dumpfile("tb_gardner.vcd");
    $dumpvars(0, tb_gardner);
    aresetn = 0; #40; aresetn = 1;
    #60000;
    $display("\n===== Resultado del lazo de Gardner =====");
    $display("tau final = %0d   (esperado 8, el centro del simbolo)", dut.tau);
    $display("|ted_err| medio en el tramo final = %0.1f   (deberia ser pequeno frente a ~250 del pico)",
             (abs_cnt>0) ? abs_sum/abs_cnt : 0.0);
    if (dut.tau>=4'd7 && dut.tau<=4'd9)
      $display(">> ENGANCHADO: tau se ha clavado en el centro. El lazo funciona.");
    else
      $display(">> NO enganchado: sube o baja THRESH, o pon LOOP_INV a 1.");
    $finish;
  end
 
endmodule