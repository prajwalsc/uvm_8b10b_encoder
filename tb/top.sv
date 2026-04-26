// =============================================================================
// top.sv
// Top-level testbench module.
// Instantiates the DUT, the interface, generates the clock, and launches
// the UVM test selected by +UVM_TESTNAME.
// =============================================================================

`timescale 1ns/1ps

// UVM and project packages
import uvm_pkg::*;
`include "uvm_macros.svh"

import encoder_types_pkg::*;
import encoder_uvm_pkg::*;

module top;

    // -------------------------------------------------------------------------
    // Clock generation — 160 MHz → period = 6.25 ns
    // -------------------------------------------------------------------------
    localparam real CLK_PERIOD_NS = 6.25;

    logic Clk;
    initial Clk = 0;
    always #(CLK_PERIOD_NS / 2.0) Clk = ~Clk;

    // -------------------------------------------------------------------------
    // Interface instantiation
    // -------------------------------------------------------------------------
    encoder_if enc_if (.Clk(Clk));

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    encoder_8b10b dut (
        .Clk   (enc_if.Clk),
        .Din   (enc_if.Din),
        .TX_EN (enc_if.TX_EN),
        .Dout  (enc_if.Dout)
    );

    // -------------------------------------------------------------------------
    // Push virtual interfaces into uvm_config_db
    // -------------------------------------------------------------------------
    initial begin
        uvm_config_db #(virtual encoder_if.drv_mp)::set(
            null, "uvm_test_top", "drv_vif", enc_if.drv_mp);
        uvm_config_db #(virtual encoder_if.mon_mp)::set(
            null, "uvm_test_top", "mon_vif", enc_if.mon_mp);
    end

    // -------------------------------------------------------------------------
    // Run the UVM test
    // -------------------------------------------------------------------------
    initial begin
        run_test();
    end

    // -------------------------------------------------------------------------
    // Waveform dump (optional — controlled by +WAVES plusarg)
    // -------------------------------------------------------------------------
    initial begin
        if ($test$plusargs("WAVES")) begin
            $dumpfile("waves.vcd");
            $dumpvars(0, top);
        end
    end

    // -------------------------------------------------------------------------
    // Simulation timeout guard (500 µs)
    // -------------------------------------------------------------------------
    initial begin
        #500_000;
        `uvm_fatal("TOP", "Simulation timeout!")
    end

endmodule : top
