`timescale 1ns / 1ps
module tb_prbs_ber;

    localparam int L = 15;

    logic clk = 0, rstn = 0;
    always #1 clk = ~clk;

    // ---- control del test ----
    logic [1:0] ch_rot   = 2'd0;
    logic [1:0] dut_rot  = 2'd0;
    logic       clr      = 0;
    logic       inject   = 0;

    // ---- generador PRBS-15 (mismo que el TX): s[n]=s[n-1]^s[n-15] ----
    logic [14:0] pr = 15'h7FFF;
    logic [1:0]  tx_dibit;
    always_ff @(posedge clk) begin
        logic ba, bb; logic [14:0] p1;
        if (!rstn) begin pr <= 15'h7FFF; tx_dibit <= 2'b00; end
        else begin
            ba = pr[0] ^ pr[14];  p1 = {pr[13:0], ba};
            bb = p1[0] ^ p1[14];  pr <= {p1[13:0], bb};
            tx_dibit <= {bb, ba};         // {Q,I}, igual que el TX (dibit[0]=I, dibit[1]=Q)
        end
    end

    function automatic logic [1:0] rot4(input logic [1:0] qi, input logic [1:0] r);
        logic I, Q, Ip, Qp;
        I = qi[0]; Q = qi[1];
        case (r)
            2'd0: begin Ip = I;  Qp = Q;  end   // 0 deg
            2'd1: begin Ip = ~Q; Qp = I;  end   // 90 deg
            2'd2: begin Ip = ~I; Qp = ~Q; end   // 180 deg
            2'd3: begin Ip = Q;  Qp = ~I; end   // 270 deg
        endcase
        rot4 = {Qp, Ip};
    endfunction

    wire [1:0] rx_dibit = rot4(tx_dibit, ch_rot) ^ (inject ? 2'b01 : 2'b00);

    logic        in_sync;
    logic [31:0] bit_count, error_count;
    prbs_ber_check #(.L(L), .LOCKN(64)) dut (
        .clk(clk), .rstn(rstn), .clr(clr), .rot(dut_rot),
        .rx_bits(rx_dibit), .rx_valid(1'b1),
        .in_sync(in_sync), .bit_count(bit_count), .error_count(error_count));

    task automatic pulse_clr();
        begin @(posedge clk); clr <= 1; @(posedge clk); clr <= 0; end
    endtask
    task automatic run(input int n);
        begin repeat (n) @(posedge clk); end
    endtask

    integer pass = 0, fail = 0;
    task automatic check(input string name, input bit cond);
        begin
            if (cond) begin pass++; $display("  [PASS] %s", name); end
            else      begin fail++; $display("  [FAIL] %s", name); end
        end
    endtask

    initial begin
        rstn = 0; repeat (20) @(posedge clk); rstn = 1;

        // ---- A) canal limpio, rot=0 ----
        $display("== A) Canal limpio (ch_rot=0, dut_rot=0) ==");
        ch_rot = 0; dut_rot = 0; pulse_clr(); run(400);
        check("A.in_sync=1",        in_sync === 1'b1);
        check("A.error_count=0",    error_count == 0);
        check("A.bit_count>0",      bit_count > 0);

        // ---- B) inyeccion de errores ----
        $display("== B) Inyeccion de errores ==");
        pulse_clr(); run(300);                 // re-engancha
        inject = 1; run(10); inject = 0;       // mete errores
        run(100);
        check("B.error_count>0",    error_count > 0);

        // ---- C) canal rotado 180 deg: barrido de dut_rot ----
        $display("== C) Canal rotado 180 (ch_rot=2): barrido de rot ==");
        ch_rot = 2;
        for (int r = 0; r < 4; r++) begin
            dut_rot = r[1:0]; pulse_clr(); run(400);
            $display("   rot=%0d -> in_sync=%0b  errores=%0d  bits=%0d",
                     dut_rot, in_sync, error_count, bit_count);
            if (r == 2) begin
                check("C.rot=2 engancha", in_sync === 1'b1);
                check("C.rot=2 sin errores", error_count == 0);
            end
            if (r == 0)
                check("C.rot=0 NO valido (sin sync o con errores)",
                      (in_sync !== 1'b1) || (error_count > 0));
        end

        $display("-----------------------------------------------");
        $display("RESULTADO: %0d PASS, %0d FAIL", pass, fail);
        if (fail == 0) $display(">>> TODO OK: el detector PRBS funciona <<<");
        else           $display(">>> HAY FALLOS, revisar <<<");
        $finish;
    end

    initial begin #2_000_000; $display("TIMEOUT"); $finish; end
endmodule
