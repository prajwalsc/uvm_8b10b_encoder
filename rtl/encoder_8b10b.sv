// =============================================================================
// encoder_8b10b.sv
// 802.3 1000BASE-X 8B/10B PCS Transmit Encoder
//
// Implements IEEE 802.3-2012 Section 36 encoding:
//   - IDLE (/I1/ or /I2/) when TX_EN is deasserted
//   - /S/ (K27.7) Start-of-Packet delimiter on TX_EN rising edge
//   - /D/ 8B/10B encoded data bytes during packet
//   - /T/ (K29.7) + /R/ (K23.7) End-of-Packet delimiter on TX_EN falling edge
//   - Running disparity (RD) tracked across all transmitted code-groups
//
// Interface
//   Clk   : 160 MHz rising-edge clock
//   Din   : 8-bit GMII TXD input (valid when TX_EN is high)
//   TX_EN : Transmit Enable — packet present when HIGH
//   Dout  : 10-bit code-group output (one per clock)
//
// NOTE: This file is the DUT under verification. Replace the stub logic
//       below with your full implementation.
// =============================================================================

module encoder_8b10b (
    input  logic       Clk,
    input  logic [7:0] Din,
    input  logic       TX_EN,
    output logic [9:0] Dout
);

    // -------------------------------------------------------------------------
    // Student implementation goes here.
    // The UVM testbench drives Clk, Din, TX_EN and checks Dout against the
    // 8B/10B reference model in the scoreboard.
    // -------------------------------------------------------------------------

    // Placeholder: tie outputs to zero so the TB compiles and runs
    assign Dout = 10'h000;

endmodule : encoder_8b10b
