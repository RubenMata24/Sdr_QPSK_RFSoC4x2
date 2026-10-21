 `timescale 1ns/1ps
import qpsk_coef_pkg::*;
 
module qpsk_tx_core (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [1:0]  dibit,
    output wire [15:0] m_axis_i_tdata,
    output wire        m_axis_i_tvalid,
    input  wire        m_axis_i_tready,
    output wire [15:0] m_axis_q_tdata,
    output wire        m_axis_q_tvalid,
    input  wire        m_axis_q_tready,
    output wire [1:0]  tx_dibit,
    output wire        tx_sym_load
);
    wire en = m_axis_i_tready & m_axis_q_tready;
 
    logic [1:0] osr_cnt;
    logic [1:0] sym_dbg;
    logic signed [DATA_W-1:0] i_imp, q_imp;
 
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            osr_cnt <= 2'd0; i_imp <= '0; q_imp <= '0; sym_dbg <= 2'd0;
        end else if (en) begin
            if (osr_cnt == 2'd0) begin
                i_imp   <= dibit[0] ? -A_SYM : A_SYM;
                q_imp   <= dibit[1] ? -A_SYM : A_SYM;
                sym_dbg <= dibit;
            end else begin
                i_imp <= '0;
                q_imp <= '0;
            end
            osr_cnt <= (osr_cnt == OSR-1) ? 2'd0 : osr_cnt + 2'd1;
        end
    end
 
    (* mark_debug="true" *) wire signed [DATA_W-1:0] i_tx, q_tx;
    rrc_fir u_fir_i (.aclk(aclk),.aresetn(aresetn),.en(en),.x(i_imp),.y(i_tx));
    rrc_fir u_fir_q (.aclk(aclk),.aresetn(aresetn),.en(en),.x(q_imp),.y(q_tx));
 
    assign m_axis_i_tdata  = i_tx;
    assign m_axis_q_tdata  = q_tx;
    assign m_axis_i_tvalid = 1'b1;
    assign m_axis_q_tvalid = 1'b1;
    assign tx_dibit    = sym_dbg;
    assign tx_sym_load = (osr_cnt == 2'd0) & en;
endmodule