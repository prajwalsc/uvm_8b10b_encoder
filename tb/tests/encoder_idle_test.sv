// =============================================================================
// encoder_idle_test.sv
// Verify that the encoder continuously outputs correct /I1/ and /I2/
// ordered sets when TX_EN is deasserted for an extended period.
// =============================================================================

class encoder_idle_test extends encoder_base_test;
    `uvm_component_utils(encoder_idle_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        encoder_idle_seq seq;
        phase.raise_objection(this);

        seq = encoder_idle_seq::type_id::create("seq");
        seq.num_cycles = 100;   // 50 complete /I/ ordered sets
        seq.start(env.agent.sqr);

        phase.drop_objection(this);
    endtask

endclass : encoder_idle_test
