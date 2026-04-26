// =============================================================================
// encoder_base_test.sv
// Base test — builds the environment and sets up the virtual interface.
// All other tests extend this class.
// =============================================================================

class encoder_base_test extends uvm_test;
    `uvm_component_utils(encoder_base_test)

    encoder_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        virtual encoder_if.drv_mp drv_vif;
        virtual encoder_if.mon_mp mon_vif;

        super.build_phase(phase);
        env = encoder_env::type_id::create("env", this);

        // Pull virtual interfaces out of config_db and push down to agent
        if (!uvm_config_db #(virtual encoder_if.drv_mp)::get(
                this, "", "drv_vif", drv_vif))
            `uvm_fatal("TEST", "drv_vif not found in config_db")

        if (!uvm_config_db #(virtual encoder_if.mon_mp)::get(
                this, "", "mon_vif", mon_vif))
            `uvm_fatal("TEST", "mon_vif not found in config_db")

        uvm_config_db #(virtual encoder_if.drv_mp)::set(
            this, "env.agent.drv", "vif", drv_vif);
        uvm_config_db #(virtual encoder_if.mon_mp)::set(
            this, "env.agent.mon", "vif", mon_vif);
    endfunction

    // Override in subclasses
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Base test run (no stimulus)", UVM_NONE)
        #100;
        phase.drop_objection(this);
    endtask

endclass : encoder_base_test
