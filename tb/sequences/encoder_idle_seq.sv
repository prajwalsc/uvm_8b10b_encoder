// =============================================================================
// encoder_idle_seq.sv
// Drive N idle cycles (TX_EN=0, Din=0).
// Verifies that the encoder continuously outputs /I/ ordered sets.
// =============================================================================

class encoder_idle_seq extends encoder_base_seq;
    `uvm_object_utils(encoder_idle_seq)

    int unsigned num_cycles = 20;

    function new(string name = "encoder_idle_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(),
                  $sformatf("Sending %0d IDLE cycles", num_cycles),
                  UVM_MEDIUM)
        repeat (num_cycles)
            send_cycle(8'h00, 1'b0);
    endtask

endclass : encoder_idle_seq
