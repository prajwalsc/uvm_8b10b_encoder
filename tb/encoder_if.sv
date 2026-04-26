// =============================================================================
// encoder_if.sv
// SystemVerilog interface for the 8B/10B encoder DUT
// =============================================================================

interface encoder_if (input logic Clk);

    logic [7:0] Din;
    logic       TX_EN;
    logic [9:0] Dout;

    // ------------------------------------------------------------------
    // Clocking block for the driver (stimulus side)
    // Drives on negedge so signals settle before the DUT's posedge sample
    // ------------------------------------------------------------------
    clocking driver_cb @(posedge Clk);
        default input #1 output #1;
        output Din;
        output TX_EN;
    endclocking

    // ------------------------------------------------------------------
    // Clocking block for the monitor (observation side)
    // ------------------------------------------------------------------
    clocking monitor_cb @(posedge Clk);
        default input #1;
        input Din;
        input TX_EN;
        input Dout;
    endclocking

    // ------------------------------------------------------------------
    // Modports
    // ------------------------------------------------------------------
    modport drv_mp  (clocking driver_cb,  input Clk);
    modport mon_mp  (clocking monitor_cb, input Clk);
    modport dut_mp  (input Clk, input Din, input TX_EN, output Dout);

endinterface : encoder_if
