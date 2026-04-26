// =============================================================================
// encoder_driver.sv
// Drives Din and TX_EN onto the DUT interface, one item per clock cycle.
// =============================================================================

class encoder_driver extends uvm_driver #(encoder_seq_item);
    `uvm_component_utils(encoder_driver)

    virtual encoder_if.drv_mp vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual encoder_if.drv_mp)::get(
                this, "", "vif", vif))
            `uvm_fatal("DRV", "No virtual interface found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        encoder_seq_item item;

        // Initialise interface to idle
        vif.driver_cb.Din   <= 8'h00;
        vif.driver_cb.TX_EN <= 1'b0;

        forever begin
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(encoder_seq_item item);
        @(vif.driver_cb);
        vif.driver_cb.Din   <= item.Din;
        vif.driver_cb.TX_EN <= item.TX_EN;
        `uvm_info("DRV",
                  $sformatf("Drive  Din=0x%02h TX_EN=%0b", item.Din, item.TX_EN),
                  UVM_HIGH)
    endtask

endclass : encoder_driver
