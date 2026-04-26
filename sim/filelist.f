// =============================================================================
// filelist.f  — compile-order file list for Questa / VCS / Xcelium
// Pass to simulator with -f sim/filelist.f
// =============================================================================

// ---- Types package (no UVM dependency) ----
+incdir+../tb/pkg
+incdir+../tb
../tb/pkg/encoder_types_pkg.sv

// ---- Interface ----
../tb/encoder_if.sv

// ---- RTL ----
../rtl/encoder_8b10b.sv

// ---- UVM package (includes everything via `include) ----
../tb/pkg/encoder_uvm_pkg.sv

// ---- Top ----
../tb/top.sv
