// =============================================================================
// encoder_agent.sv
// Active UVM agent: contains sequencer, driver, and monitor.
// =============================================================================

class encoder_agent extends uvm_agent;
    `uvm_component_utils(encoder_agent)

    encoder_sequencer sqr;
    encoder_driver    drv;
    encoder_monitor   mon;

    // Expose the monitor's analysis port at agent level
    uvm_analysis_port #(encoder_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap  = new("ap", this);
        sqr = encoder_sequencer::type_id::create("sqr", this);
        drv = encoder_driver   ::type_id::create("drv", this);
        mon = encoder_monitor  ::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
        mon.ap.connect(ap);
    endfunction

endclass : encoder_agent
