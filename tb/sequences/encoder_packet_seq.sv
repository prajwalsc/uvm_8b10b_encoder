// =============================================================================
// encoder_packet_seq.sv
// Drive a complete Ethernet-style packet:
//   - idle_pre  idle cycles before the packet
//   - /S/ is inserted automatically by the DUT on first TX_EN assertion
//   - payload_bytes data bytes (TX_EN=1)
//   - TX_EN deasserted; DUT must output /T/ /R/ then resume /I/
//   - idle_post idle cycles after the packet
//
// Supports back-to-back packets (burst) via the burst_count parameter.
// =============================================================================

class encoder_packet_seq extends encoder_base_seq;
    `uvm_object_utils(encoder_packet_seq)

    // ---- configurable knobs ----
    rand int unsigned idle_pre      = 10;
    rand int unsigned idle_post     = 10;
    rand int unsigned payload_len   = 64;    // bytes in the payload
    rand int unsigned burst_count   = 1;     // number of back-to-back packets
    rand logic [7:0] payload [];             // actual payload bytes

    constraint c_idle_pre    { idle_pre    inside {[4:20]}; }
    constraint c_idle_post   { idle_post   inside {[4:20]}; }
    constraint c_payload_len { payload_len inside {[1:256]}; }
    constraint c_burst       { burst_count inside {[1:4]}; }
    constraint c_payload_sz  { payload.size() == payload_len; }

    function new(string name = "encoder_packet_seq");
        super.new(name);
    endfunction

    function void pre_randomize();
        payload = new[payload_len];
    endfunction

    task body();
        `uvm_info(get_type_name(),
                  $sformatf("Sending %0d packet(s) of %0d bytes, pre=%0d post=%0d",
                             burst_count, payload_len, idle_pre, idle_post),
                  UVM_MEDIUM)

        // Pre-packet IDLE
        repeat (idle_pre) send_cycle(8'h00, 1'b0);

        repeat (burst_count) begin
            // Packet payload  (DUT inserts /S/ on first TX_EN assertion)
            foreach (payload[i]) send_cycle(payload[i], 1'b1);

            // Deassert TX_EN — DUT must insert /T/ /R/ [/R/] then resume /I/
            send_cycle(8'h00, 1'b0);
        end

        // Post-packet IDLE
        repeat (idle_post) send_cycle(8'h00, 1'b0);
    endtask

endclass : encoder_packet_seq
