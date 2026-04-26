// =============================================================================
// encoder_env.sv
// Top-level UVM environment: wires agent → scoreboard and coverage
// =============================================================================

class encoder_env extends uvm_env;
    `uvm_component_utils(encoder_env)

    encoder_agent      agent;
    encoder_scoreboard sb;
    encoder_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = encoder_agent     ::type_id::create("agent", this);
        sb    = encoder_scoreboard::type_id::create("sb",    this);
        cov   = encoder_coverage  ::type_id::create("cov",   this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.ap.connect(sb.analysis_export);
        agent.ap.connect(cov.analysis_export);
    endfunction

endclass : encoder_env
