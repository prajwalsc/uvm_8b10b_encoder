// =============================================================================
// encoder_rand_test.sv
// Fully randomised regression test for coverage closure.
// Seeds via +UVM_TESTNAME and +ntx=<N>.
// =============================================================================

class encoder_rand_test extends encoder_base_test;
    `uvm_component_utils(encoder_rand_test)

    int unsigned num_tx = 30;   // overridable via plusarg +ntx=<N>

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        int tmp;
        if ($value$plusargs("ntx=%0d", tmp)) num_tx = tmp;
        `uvm_info(get_type_name(),
                  $sformatf("Will run %0d random transactions", num_tx),
                  UVM_NONE)
    endfunction

    task run_phase(uvm_phase phase);
        encoder_rand_seq seq;
        phase.raise_objection(this);

        seq = encoder_rand_seq::type_id::create("seq");
        seq.num_transactions = num_tx;
        if (!seq.randomize())
            `uvm_fatal("RAND_TEST", "sequence randomize() failed")
        seq.start(env.agent.sqr);

        phase.drop_objection(this);
    endtask

endclass : encoder_rand_test
