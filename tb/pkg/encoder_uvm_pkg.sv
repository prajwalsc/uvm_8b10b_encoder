// =============================================================================
// encoder_uvm_pkg.sv
// Master package — includes all UVM classes in dependency order.
// Import this package in top.sv after importing uvm_pkg.
// =============================================================================

`ifndef ENCODER_UVM_PKG_SV
`define ENCODER_UVM_PKG_SV

package encoder_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import encoder_types_pkg::*;

    // ---- Sequence item ----
    `include "sequences/encoder_seq_item.sv"

    // ---- Sequences ----
    `include "sequences/encoder_base_seq.sv"
    `include "sequences/encoder_idle_seq.sv"
    `include "sequences/encoder_packet_seq.sv"
    `include "sequences/encoder_rand_seq.sv"

    // ---- Agent components ----
    `include "agent/encoder_sequencer.sv"
    `include "agent/encoder_driver.sv"
    `include "agent/encoder_monitor.sv"
    `include "agent/encoder_agent.sv"

    // ---- Env components ----
    `include "env/encoder_scoreboard.sv"
    `include "env/encoder_coverage.sv"
    `include "env/encoder_env.sv"

    // ---- Tests ----
    `include "tests/encoder_base_test.sv"
    `include "tests/encoder_idle_test.sv"
    `include "tests/encoder_packet_test.sv"
    `include "tests/encoder_rand_test.sv"

endpackage : encoder_uvm_pkg

`endif
