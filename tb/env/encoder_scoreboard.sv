// =============================================================================
// encoder_scoreboard.sv
// Reference model for the 802.3 1000BASE-X 8B/10B PCS Transmit encoder.
//
// State machine (per IEEE 802.3-2012 Fig 36-5):
//   IDLE_STATE    → outputs /I/ (alternating /I1/ and /I2/)
//   START_STATE   → outputs /S/ (K27.7), then transitions to DATA_STATE
//                   (takes 2 cycles — /S/ uses 2 code-groups inserted by DUT)
//   DATA_STATE    → encodes each Din byte with ENCODE()
//   END_STATE_T   → outputs /T/ (K29.7)
//   END_STATE_R   → outputs /R/ (K23.7), possibly twice for alignment
//
// Running disparity is tracked across every output code-group.
// =============================================================================

class encoder_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(encoder_scoreboard)

    import encoder_types_pkg::*;

    // Analysis port — receives monitor observations
    uvm_analysis_imp #(encoder_seq_item, encoder_scoreboard) analysis_export;

    // -----------------------------------------------------------------------
    // Reference model state
    // -----------------------------------------------------------------------
    typedef enum {
        REF_RESET,
        REF_IDLE,          // outputting /I/ ordered sets
        REF_START,         // about to output /S/ (K27.7)
        REF_DATA,          // outputting encoded data bytes
        REF_EPD_T,         // outputting /T/ (K29.7)
        REF_EPD_R,         // outputting first /R/ (K23.7)
        REF_EPD_R2         // outputting optional second /R/
    } ref_state_t;

    ref_state_t ref_state;
    rd_t        running_rd;        // current running disparity
    int         tx_even;           // even/odd code-group position counter
    bit         first_idle;        // first /I/ after packet → use /I1/
    bit         idle_phase;        // 0=/I1/ K28.5 half, 1=data half

    // For /I/ generation: which sub-orderset are we on?
    // Each /I/ orderset = 2 code-groups: K28.5 then data
    bit         idle_cg_half;      // 0 = K28.5 half, 1 = data half
    bit         use_i1;            // 1 → /I1/ (D5.6), 0 → /I2/ (D16.2)

    // FIFO for expected output code-groups (pre-computed one clock ahead)
    logic [9:0] exp_q[$];

    // Statistics
    int         checks_passed;
    int         checks_failed;

    // -----------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        // Power-on state: RD starts negative, first /I/ after reset is /I1/
        ref_state    = REF_IDLE;
        running_rd   = RD_NEG;
        tx_even      = 0;
        first_idle   = 1;
        idle_cg_half = 0;
        use_i1       = 1;
        checks_passed = 0;
        checks_failed = 0;
    endfunction

    // -----------------------------------------------------------------------
    // Called each cycle by the monitor
    // -----------------------------------------------------------------------
    function void write(encoder_seq_item item);
        logic [9:0] expected;
        string      info_str;

        expected = compute_expected(item.TX_EN, item.Din);

        if (expected === 10'hx) begin
            // Don't-care cycle (pipeline flush, reset, etc.)
            return;
        end

        info_str = $sformatf(
            "TX_EN=%0b Din=0x%02h | expected=0x%03h got=0x%03h",
            item.TX_EN, item.Din, expected, item.Dout);

        if (item.Dout === expected) begin
            checks_passed++;
            `uvm_info("SB", {" PASS  ", info_str}, UVM_HIGH)
        end else begin
            checks_failed++;
            `uvm_error("SB", {" FAIL  ", info_str})
        end
    endfunction

    // -----------------------------------------------------------------------
    // Reference model: compute expected Dout for one cycle
    // Advances the internal state machine.
    // -----------------------------------------------------------------------
    function logic [9:0] compute_expected(logic tx_en, logic [7:0] din);
        logic [9:0] cg;
        rd_t        new_rd;

        case (ref_state)

            // -----------------------------------------------------------------
            // IDLE: output alternating /I1/ and /I2/ ordered sets.
            // Each ordered set = 2 code-groups:  K28.5  then  D5.6 or D16.2
            // -----------------------------------------------------------------
            REF_IDLE: begin
                if (tx_en) begin
                    // TX_EN asserted — transition to /S/ output next cycle
                    // (DUT must have absorbed this in a FIFO and will now
                    //  emit /S/ as the first code-group)
                    ref_state    = REF_START;
                    idle_cg_half = 0;
                    // Still emit the current /I/ code-group this cycle
                    // (the DUT outputs /S/ one cycle after TX_EN assertion
                    //  because the FIFO buffers the incoming byte)
                    // For simplicity model: current cycle still outputs idle
                    cg = idle_codegrp();
                end else begin
                    cg = idle_codegrp();
                end
                return update_rd_and_return(cg);
            end

            // -----------------------------------------------------------------
            // START: output /S/ (K27.7).  The DUT takes one clock to insert /S/
            // while the incoming byte is held in the FIFO.
            // After /S/ is sent, move to DATA_STATE.
            // -----------------------------------------------------------------
            REF_START: begin
                cg        = (running_rd == RD_NEG) ? K27_7_RD_NEG : K27_7_RD_POS;
                ref_state = REF_DATA;
                first_idle = 0;
                return update_rd_and_return(cg);
            end

            // -----------------------------------------------------------------
            // DATA: 8B/10B encode the current Din byte.
            // When TX_EN deasserts, next cycle will be /T/.
            // -----------------------------------------------------------------
            REF_DATA: begin
                cg = encode_data(din, running_rd, new_rd);
                if (!tx_en) begin
                    // TX_EN just went low — next output is /T/
                    ref_state = REF_EPD_T;
                end
                running_rd = new_rd;
                tx_even++;
                return cg;
            end

            // -----------------------------------------------------------------
            // EPD /T/ — End-of-Packet part 1
            // -----------------------------------------------------------------
            REF_EPD_T: begin
                cg        = (running_rd == RD_NEG) ? K29_7_RD_NEG : K29_7_RD_POS;
                ref_state = REF_EPD_R;
                return update_rd_and_return(cg);
            end

            // -----------------------------------------------------------------
            // EPD /R/ — End-of-Packet part 2 (first /R/)
            // Per spec 36.2.4.15: if this /R/ lands on an even code-group
            // position, a second /R/ must be added to realign /I/ to even.
            // -----------------------------------------------------------------
            REF_EPD_R: begin
                cg = (running_rd == RD_NEG) ? K23_7_RD_NEG : K23_7_RD_POS;
                update_rd(cg);
                tx_even++;
                // Determine whether a second /R/ is needed for even alignment
                if ((tx_even % 2) == 0) begin
                    // /T/ was on odd → this /R/ is even → need one more /R/
                    ref_state = REF_EPD_R2;
                end else begin
                    // Aligned — resume IDLE
                    ref_state  = REF_IDLE;
                    use_i1     = 1;          // first /I/ after packet uses /I1/
                    first_idle = 1;
                    idle_cg_half = 0;
                end
                return cg;
            end

            // -----------------------------------------------------------------
            // EPD /R/ part 3 — optional second /R/ for alignment
            // -----------------------------------------------------------------
            REF_EPD_R2: begin
                cg = (running_rd == RD_NEG) ? K23_7_RD_NEG : K23_7_RD_POS;
                update_rd(cg);
                ref_state    = REF_IDLE;
                use_i1       = 1;
                first_idle   = 1;
                idle_cg_half = 0;
                return cg;
            end

            default: begin
                `uvm_error("SB", "Reference model reached unknown state")
                return 10'hx;
            end
        endcase
    endfunction

    // -----------------------------------------------------------------------
    // Generate the next IDLE code-group (half of an /I1/ or /I2/ ordered set)
    // -----------------------------------------------------------------------
    function logic [9:0] idle_codegrp();
        logic [9:0] cg;
        if (idle_cg_half == 0) begin
            // First half: always K28.5
            cg = (running_rd == RD_NEG) ? K28_5_RD_NEG : K28_5_RD_POS;
            idle_cg_half = 1;
        end else begin
            // Second half: D5.6 (/I1/) or D16.2 (/I2/)
            if (use_i1) begin
                // D5.6 is disparity-neutral — same code-group regardless of RD
                cg = D5_6_NEUTRAL;
                // After /I1/, next idle uses /I2/ (unless after a packet)
                use_i1 = 0;
            end else begin
                cg = (running_rd == RD_NEG) ? D16_2_RD_NEG : D16_2_RD_POS;
            end
            idle_cg_half = 0;
        end
        return cg;
    endfunction

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------
    function logic [9:0] update_rd_and_return(logic [9:0] cg);
        update_rd(cg);
        return cg;
    endfunction

    function void update_rd(logic [9:0] cg);
        // cg = { j[9], h[8], g[7], f[6], i[5], e[4], d[3], c[2], b[1], a[0] }
        // 6-bit sub-block = abcdei = { cg[0],cg[1],cg[2],cg[3],cg[4],cg[5] }
        // 4-bit sub-block = fghj   = { cg[6],cg[7],cg[8],cg[9] }
        rd_t rd_mid;
        rd_mid     = rd_after_6b({cg[5],cg[4],cg[3],cg[2],cg[1],cg[0]}, running_rd);
        running_rd = rd_after_4b({cg[6],cg[7],cg[8],cg[9]}, rd_mid);
    endfunction

    // -----------------------------------------------------------------------
    // Report phase
    // -----------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        `uvm_info("SB",
                  $sformatf("Scoreboard results: %0d passed, %0d failed",
                            checks_passed, checks_failed),
                  UVM_NONE)
        if (checks_failed > 0)
            `uvm_error("SB", "*** SIMULATION FAILED — encoding errors detected ***")
        else
            `uvm_info("SB", "*** SIMULATION PASSED ***", UVM_NONE)
    endfunction

endclass : encoder_scoreboard
