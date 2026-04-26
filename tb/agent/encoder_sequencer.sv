// =============================================================================
// encoder_sequencer.sv
// =============================================================================

class encoder_sequencer extends uvm_sequencer #(encoder_seq_item);
    `uvm_component_utils(encoder_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : encoder_sequencer
