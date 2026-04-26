// =============================================================================
// encoder_coverage.sv
// Functional coverage for the 8B/10B encoder
// =============================================================================

class encoder_coverage extends uvm_subscriber #(encoder_seq_item);
    `uvm_component_utils(encoder_coverage)

    encoder_seq_item item;

    // Track previous TX_EN for edge detection
    logic prev_tx_en = 0;

    // ------------------------------------------------------------------
    // Covergroups
    // ------------------------------------------------------------------

    // All 256 input data values during active packet transmission
    covergroup cg_data_bytes;
        cp_din: coverpoint item.Din {
            bins zero     = {8'h00};
            bins ones     = {8'hFF};
            bins alt55    = {8'h55};
            bins altAA    = {8'hAA};
            bins data_lo  = {[8'h01:8'h7F]};
            bins data_hi  = {[8'h80:8'hFE]};
        }
    endgroup

    // TX_EN transitions (rising = packet start, falling = packet end)
    covergroup cg_tx_en_transitions;
        cp_tx: coverpoint item.TX_EN;
        cp_edge: coverpoint {prev_tx_en, item.TX_EN} {
            bins rise     = {2'b01};   // IDLE → packet
            bins fall     = {2'b10};   // packet → EPD
            bins high     = {2'b11};   // sustained packet
            bins low      = {2'b00};   // sustained IDLE
        }
    endgroup

    // 10-bit Dout patterns — hit key special code-groups
    covergroup cg_output_codes;
        cp_dout_special: coverpoint item.Dout {
            // K28.5 (COMMA)
            bins k28_5_neg    = {10'b10_1011_1100};
            bins k28_5_pos    = {10'b01_0100_0011};
            // /S/ K27.7
            bins k27_7_neg    = {10'b00_0101_1011};
            bins k27_7_pos    = {10'b11_1010_0100};
            // /T/ K29.7
            bins k29_7_neg    = {10'b00_0101_1101};
            bins k29_7_pos    = {10'b11_1010_0010};
            // /R/ K23.7
            bins k23_7_neg    = {10'b00_0101_0111};
            bins k23_7_pos    = {10'b11_1010_1000};
            // All other outputs
            bins data         = default;
        }
    endgroup

    // IDLE ordered set halves — verify both /I1/ and /I2/ appear
    covergroup cg_idle_sets;
        cp_idle_half: coverpoint item.Dout {
            // D5.6 — second code-group of /I1/
            bins d5_6    = {10'b01_1010_0101};
            // D16.2 RD- — second code-group of /I2/ after RD-
            bins d16_2_n = {10'b10_1011_0110};
            // D16.2 RD+ — second code-group of /I2/ after RD+
            bins d16_2_p = {10'b10_1000_0101};
            bins other   = default;
        }
    endgroup

    // ------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_data_bytes      = new();
        cg_tx_en_transitions = new();
        cg_output_codes    = new();
        cg_idle_sets       = new();
    endfunction

    function void write(encoder_seq_item t);
        item = t;
        if (t.TX_EN) cg_data_bytes.sample();
        cg_tx_en_transitions.sample();
        cg_output_codes.sample();
        cg_idle_sets.sample();
        prev_tx_en = t.TX_EN;
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV",
                  $sformatf("Data byte coverage  : %.1f%%",
                            cg_data_bytes.get_inst_coverage()),
                  UVM_NONE)
        `uvm_info("COV",
                  $sformatf("TX_EN transition cov: %.1f%%",
                            cg_tx_en_transitions.get_inst_coverage()),
                  UVM_NONE)
        `uvm_info("COV",
                  $sformatf("Output code coverage: %.1f%%",
                            cg_output_codes.get_inst_coverage()),
                  UVM_NONE)
        `uvm_info("COV",
                  $sformatf("IDLE orderset cov   : %.1f%%",
                            cg_idle_sets.get_inst_coverage()),
                  UVM_NONE)
    endfunction

endclass : encoder_coverage
