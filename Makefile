# =============================================================================
# Makefile — 8B/10B Encoder UVM Testbench
# Supports Questa (vlog/vsim), VCS, and Xcelium targets.
# =============================================================================

TEST    ?= encoder_packet_test
SEED    ?= random
WAVES   ?= 0
VERBOSITY ?= UVM_MEDIUM

# --- Tool selection (set to questa / vcs / xcelium) ---
TOOL    ?= questa

# --- UVM home (override if needed) ---
UVM_HOME ?= /opt/questa/verilog_src/uvm-1.2

# =============================================================================
# Questa targets
# =============================================================================
ifeq ($(TOOL),questa)

compile:
	vlib work
	vmap work work
	vlog -sv \
	     +define+UVM_NO_DEPRECATED \
	     +incdir+$(UVM_HOME)/src \
	     +incdir+tb/pkg \
	     +incdir+tb \
	     $(UVM_HOME)/src/uvm_pkg.sv \
	     -f sim/filelist.f

sim: compile
	vsim -c top \
	     +UVM_TESTNAME=$(TEST) \
	     +UVM_VERBOSITY=$(VERBOSITY) \
	     -sv_seed $(SEED) \
	     $(if $(filter 1,$(WAVES)),+WAVES,) \
	     -do "run -all; quit -f"

gui: compile
	vsim top \
	     +UVM_TESTNAME=$(TEST) \
	     +UVM_VERBOSITY=$(VERBOSITY) \
	     -sv_seed $(SEED)

endif

# =============================================================================
# VCS target
# =============================================================================
ifeq ($(TOOL),vcs)

compile:
	vcs -full64 -sverilog \
	    +define+UVM_NO_DEPRECATED \
	    +incdir+$(VCS_UVM_HOME)/src \
	    +incdir+tb/pkg \
	    +incdir+tb \
	    $(VCS_UVM_HOME)/src/uvm_pkg.sv \
	    -f sim/filelist.f \
	    -o simv

sim: compile
	./simv \
	    +UVM_TESTNAME=$(TEST) \
	    +UVM_VERBOSITY=$(VERBOSITY) \
	    +ntb_random_seed=$(SEED)

endif

# =============================================================================
# Xcelium target
# =============================================================================
ifeq ($(TOOL),xcelium)

compile:
	xmvlog -sv \
	       +define+UVM_NO_DEPRECATED \
	       +incdir+$(XCELIUM_UVM_HOME)/src \
	       +incdir+tb/pkg \
	       +incdir+tb \
	       -f sim/filelist.f

sim: compile
	xmsim top \
	      +UVM_TESTNAME=$(TEST) \
	      +UVM_VERBOSITY=$(VERBOSITY) \
	      -seed $(SEED)

endif

# =============================================================================
# Regression — run all tests
# =============================================================================
regression:
	$(MAKE) sim TEST=encoder_idle_test   SEED=1
	$(MAKE) sim TEST=encoder_packet_test SEED=1
	$(MAKE) sim TEST=encoder_rand_test   SEED=1
	$(MAKE) sim TEST=encoder_rand_test   SEED=2
	$(MAKE) sim TEST=encoder_rand_test   SEED=3

clean:
	rm -rf work simv csrc ucli.key *.log *.vcd transcript vsim.wlf \
	       xcelium.d INCA_libs *.shm

.PHONY: compile sim gui regression clean
