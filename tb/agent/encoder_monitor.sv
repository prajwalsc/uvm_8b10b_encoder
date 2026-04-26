// =============================================================================
// encoder_monitor.sv
// Observes Din, TX_EN, and Dout each cycle and broadcasts a seq_item
// on the analysis port so the scoreboard and coverage can receive it.
// =============================================================================

class encoder_monitor extends uvm_monitor;
    `uvm_component_utils(encoder_monitor)

    virtual encoder_if.mon_mp vif;

    // Analysis port — broadcasts to scoreboard and coverage collector
    uvm_analysis_port #(encoder_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual encoder_if.mon_mp)::get(
                this, "", "vif", vif))
            `uvm_fatal("MON", "No virtual interface found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        encoder_seq_item item;
        forever begin
            @(vif.monitor_cb);
            item        = encoder_seq_item::type_id::create("mon_item");
            item.Din    = vif.monitor_cb.Din;
            item.TX_EN  = vif.monitor_cb.TX_EN;
            item.Dout   = vif.monitor_cb.Dout;
            ap.write(item);
            `uvm_info("MON",
                      $sformatf("Observe Din=0x%02h TX_EN=%0b Dout=0x%03h",
                                item.Din, item.TX_EN, item.Dout),
                      UVM_HIGH)
        end
    endtask

endclass : encoder_monitor
