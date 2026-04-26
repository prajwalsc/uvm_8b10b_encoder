// =============================================================================
// encoder_packet_test.sv
// Directed test: send several fixed-pattern packets and verify correct
// /S/, data, /T/, /R/ sequence and disparity tracking.
// =============================================================================

class encoder_packet_test extends encoder_base_test;
    `uvm_component_utils(encoder_packet_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        encoder_idle_seq   idle_seq;
        encoder_packet_seq pkt_seq;
        phase.raise_objection(this);

        // -- 10 idle cycles to let disparity settle after reset
        idle_seq = encoder_idle_seq::type_id::create("idle_seq");
        idle_seq.num_cycles = 10;
        idle_seq.start(env.agent.sqr);

        // -- Packet 1: all-zeros payload (stress disparity accumulation)
        pkt_seq             = encoder_packet_seq::type_id::create("pkt1");
        pkt_seq.idle_pre    = 4;
        pkt_seq.idle_post   = 8;
        pkt_seq.payload_len = 10;
        pkt_seq.burst_count = 1;
        pkt_seq.payload     = new[10];
        foreach (pkt_seq.payload[i]) pkt_seq.payload[i] = 8'h00;
        pkt_seq.start(env.agent.sqr);

        // -- Packet 2: all-ones payload
        pkt_seq             = encoder_packet_seq::type_id::create("pkt2");
        pkt_seq.idle_pre    = 4;
        pkt_seq.idle_post   = 8;
        pkt_seq.payload_len = 10;
        pkt_seq.burst_count = 1;
        pkt_seq.payload     = new[10];
        foreach (pkt_seq.payload[i]) pkt_seq.payload[i] = 8'hFF;
        pkt_seq.start(env.agent.sqr);

        // -- Packet 3: alternating 0x55 / 0xAA
        pkt_seq             = encoder_packet_seq::type_id::create("pkt3");
        pkt_seq.idle_pre    = 4;
        pkt_seq.idle_post   = 8;
        pkt_seq.payload_len = 16;
        pkt_seq.burst_count = 1;
        pkt_seq.payload     = new[16];
        foreach (pkt_seq.payload[i])
            pkt_seq.payload[i] = (i % 2 == 0) ? 8'h55 : 8'hAA;
        pkt_seq.start(env.agent.sqr);

        // -- Packet 4: incrementing counter (covers all 256 values)
        pkt_seq             = encoder_packet_seq::type_id::create("pkt4");
        pkt_seq.idle_pre    = 4;
        pkt_seq.idle_post   = 8;
        pkt_seq.payload_len = 256;
        pkt_seq.burst_count = 1;
        pkt_seq.payload     = new[256];
        foreach (pkt_seq.payload[i]) pkt_seq.payload[i] = i[7:0];
        pkt_seq.start(env.agent.sqr);

        // -- Burst of 3 back-to-back packets
        pkt_seq             = encoder_packet_seq::type_id::create("burst");
        pkt_seq.idle_pre    = 6;
        pkt_seq.idle_post   = 6;
        pkt_seq.payload_len = 8;
        pkt_seq.burst_count = 3;
        pkt_seq.payload     = new[8];
        foreach (pkt_seq.payload[i]) pkt_seq.payload[i] = 8'hA5;
        pkt_seq.start(env.agent.sqr);

        // Drain IDLE
        idle_seq.num_cycles = 20;
        idle_seq.start(env.agent.sqr);

        phase.drop_objection(this);
    endtask

endclass : encoder_packet_test
