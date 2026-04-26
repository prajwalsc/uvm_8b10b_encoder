# =============================================================================
# run.do — Questa/ModelSim macro
# Usage (from sim/ directory):
#   vsim -do run.do                          # packet test (default)
#   vsim -do run.do -gTEST=encoder_idle_test
#   vsim -do run.do -gTEST=encoder_rand_test
# =============================================================================

quietly set TEST encoder_packet_test
if {[info exists 1]} { set TEST $1 }

# ---- Compile ----
vlib work
vmap work work

vlog -sv -f filelist.f \
     +define+UVM_NO_DEPRECATED \
     +incdir+$env(UVM_HOME)/src \
     $env(UVM_HOME)/src/uvm_pkg.sv

# ---- Simulate ----
vsim -L work top \
     +UVM_TESTNAME=$TEST \
     +UVM_VERBOSITY=UVM_MEDIUM \
     -sv_seed random \
     -do "
         log -r /*;
         run -all;
         quit -f
     "
