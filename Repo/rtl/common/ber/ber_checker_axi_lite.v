`timescale 1ns / 1ps

module ber_checker_axi_lite #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4
)(
    input wire aclk,
    input wire aresetn,

    // AXI Lite
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0] awaddr,
    input  wire awvalid,
    output wire awready,
    input  wire [C_S_AXI_DATA_WIDTH-1 : 0] wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] wstrb,
    input  wire wvalid,
    output wire wready,
    output wire [1 : 0] bresp,
    output wire bvalid,
    input  wire bready,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0] araddr,
    input  wire arvalid,
    output wire arready,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] rdata,
    output wire [1 : 0] rresp,
    output wire rvalid,
    input  wire rready,

    // Señales del RX
    input  wire [1:0] rx_bits,
    input  wire       rx_valid,

    // Salidas a GPIO (64 bits partidos)
    output wire [31:0] bit_count_lo,
    output wire [31:0] bit_count_hi,
    output wire [31:0] error_count_lo,
    output wire [31:0] error_count_hi
);
    // ---- detector con auto-rotacion ----
    wire [63:0] chk_bits, chk_errs;
    wire        chk_in_sync;
    wire [1:0]  chk_rot;
    prbs_ber_check_auto #(.L(15), .LOCKN(64)) u_chk (
        .clk(aclk), .rstn(aresetn), .clr(ber_clr),
        .rx_bits(rx_bits), .rx_valid(rx_valid),
        .in_sync(chk_in_sync), .locked_rot(chk_rot),
        .bit_count(chk_bits), .error_count(chk_errs));

    // ---- captura ----
    reg [63:0] bits_reg, errs_reg;
    reg        in_sync_reg;
    reg [1:0]  rot_reg;
    always @(posedge aclk) begin
        if (!aresetn) begin bits_reg<=64'd0; errs_reg<=64'd0; in_sync_reg<=1'b0; rot_reg<=2'd0; end
        else begin bits_reg<=chk_bits; errs_reg<=chk_errs; in_sync_reg<=chk_in_sync; rot_reg<=chk_rot; end
    end

    // ===== AXI write =====
    reg aw_en;
    reg bvalid_r;
    always @(posedge aclk) begin
        if (!aresetn)                        aw_en <= 1'b1;
        else if (awvalid && wvalid && aw_en) aw_en <= 1'b0;
        else if (bvalid && bready)           aw_en <= 1'b1;
    end
    assign awready = aw_en && awvalid && wvalid;
    assign wready  = aw_en && awvalid && wvalid;
    always @(posedge aclk) begin
        if (!aresetn) ber_clr <= 1'b0;
        else if (awready) begin
            case (awaddr[3:0])
                4'h0C: ber_clr <= wdata[1];
            endcase
        end
    end
    always @(posedge aclk) begin
        if (!aresetn)     bvalid_r <= 1'b0;
        else if (awready) bvalid_r <= 1'b1;
        else if (bready)  bvalid_r <= 1'b0;
    end
    assign bvalid = bvalid_r;
    assign bresp  = 2'b00;

    // ===== AXI read =====
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg axi_rvalid;
    always @(posedge aclk) begin
        if (!aresetn)                axi_rvalid <= 1'b0;
        else if (arvalid && arready) axi_rvalid <= 1'b1;
        else if (rvalid && rready)   axi_rvalid <= 1'b0;
    end
    assign arready = !axi_rvalid && arvalid;
    always @(posedge aclk) begin
        if (arvalid && arready) begin
            case (araddr[3:0])
                4'h00: axi_rdata <= bits_reg[31:0];
                4'h04: axi_rdata <= bits_reg[63:32];
                4'h08: axi_rdata <= errs_reg[31:0];
                4'h0C: axi_rdata <= {25'b0, rot_reg, in_sync_reg, 2'b0, ber_clr, 1'b0};
                default: axi_rdata <= 32'h0;
            endcase
        end
    end
    assign rdata  = axi_rdata;
    assign rvalid = axi_rvalid;
    assign rresp  = 2'b00;

    // ===== salidas a GPIO =====
    assign bit_count_lo   = bits_reg[31:0];
    assign bit_count_hi   = bits_reg[63:32];
    assign error_count_lo = errs_reg[31:0];
    assign error_count_hi = errs_reg[63:32];

endmodule
