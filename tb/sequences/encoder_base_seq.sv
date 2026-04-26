// =============================================================================
// encoder_base_seq.sv
// Base sequence — thin wrapper that all other sequences extend
// =============================================================================

class encoder_base_seq extends uvm_sequence #(encoder_seq_item);
    `uvm_object_utils(encoder_base_seq)

    function new(string name = "encoder_base_seq");
        super.new(name);
    endfunction

    // Helper: send one cycle with given Din/TX_EN values
    task send_cycle(logic [7:0] din, logic tx_en);
        encoder_seq_item item;
        item        = encoder_seq_item::type_id::create("item");
        item.Din    = din;
        item.TX_EN  = tx_en;
        start_item(item);
        finish_item(item);
    endtask

endclass : encoder_base_seq
