// =============================================================================
// encoder_rand_seq.sv
// Fully randomised sequence — mixes idle runs and random-length packets.
// Good for coverage closure and disparity stress testing.
// =============================================================================

class encoder_rand_seq extends encoder_base_seq;
    `uvm_object_utils(encoder_rand_seq)

    rand int unsigned num_transactions = 20;

    constraint c_num { num_transactions inside {[10:50]}; }

    function new(string name = "encoder_rand_seq");
        super.new(name);
    endfunction

    task body();
        encoder_packet_seq pkt_seq;
        encoder_idle_seq   idle_seq;

        `uvm_info(get_type_name(),
                  $sformatf("Running %0d random transactions", num_transactions),
                  UVM_MEDIUM)

        repeat (num_transactions) begin
            // Randomly choose idle burst or packet
            if ($urandom_range(0, 1)) begin
                idle_seq = encoder_idle_seq::type_id::create("idle_seq");
                idle_seq.num_cycles = $urandom_range(4, 30);
                idle_seq.start(m_sequencer);
            end else begin
                pkt_seq = encoder_packet_seq::type_id::create("pkt_seq");
                if (!pkt_seq.randomize())
                    `uvm_fatal("RAND_SEQ", "Packet sequence randomization failed")
                pkt_seq.start(m_sequencer);
            end
        end
    endtask

endclass : encoder_rand_seq
