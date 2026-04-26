// =============================================================================
// encoder_seq_item.sv
// UVM sequence item — one clock cycle of stimulus + observed response
// =============================================================================

class encoder_seq_item extends uvm_sequence_item;
    `uvm_object_utils(encoder_seq_item)

    // ------------------------------------------------------------------
    // Stimulus fields (driven to DUT)
    // ------------------------------------------------------------------
    rand logic [7:0] Din;
    rand logic       TX_EN;

    // ------------------------------------------------------------------
    // Response field (captured from DUT output)
    // ------------------------------------------------------------------
    logic [9:0] Dout;

    // ------------------------------------------------------------------
    // Constraints
    // ------------------------------------------------------------------
    // Bias toward interesting patterns
    constraint c_din_dist {
        Din dist {
            8'h00        :/ 5,   // all zeros
            8'hFF        :/ 5,   // all ones
            8'h55        :/ 5,   // alternating
            8'hAA        :/ 5,   // alternating
            [8'h00:8'hFF]:/ 80   // fully random
        };
    }

    constraint c_tx_en_dist {
        TX_EN dist { 1'b0 :/ 30, 1'b1 :/ 70 };
    }

    // ------------------------------------------------------------------
    function new(string name = "encoder_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("Din=0x%02h TX_EN=%0b Dout=0x%03h",
                         Din, TX_EN, Dout);
    endfunction

    function void do_copy(uvm_object rhs);
        encoder_seq_item rhs_t;
        super.do_copy(rhs);
        if (!$cast(rhs_t, rhs))
            `uvm_fatal("SEQ_ITEM", "do_copy: type mismatch")
        this.Din   = rhs_t.Din;
        this.TX_EN = rhs_t.TX_EN;
        this.Dout  = rhs_t.Dout;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        encoder_seq_item rhs_t;
        if (!$cast(rhs_t, rhs)) return 0;
        return (this.Din   == rhs_t.Din &&
                this.TX_EN == rhs_t.TX_EN);
    endfunction

endclass : encoder_seq_item
