# UVM Verification — 802.3 1000BASE-X 8B/10B Encoder

EE 287 Project · Spring 2026  
IEEE Std 802.3™-2012, Section 36 — Physical Coding Sublayer (PCS)

---

## Overview

This repository contains a modular **UVM testbench** for verifying the
8B/10B PCS transmit encoder described in IEEE 802.3-2012 §36.2.4.

The encoder converts 8-bit GMII data (TXD + TX_EN) into a stream of
10-bit code-groups that implement the 8B/10B line code with correct:

- **Running disparity** (tracked across all transmitted code-groups)
- **IDLE** ordered sets `/I1/` and `/I2/` (K28.5 + D5.6 / K28.5 + D16.2)
- **Start-of-Packet** delimiter `/S/` (K27.7) on TX_EN assertion
- **Data** code-groups `/D/` (8B/10B encoded bytes during packet)
- **End-of-Packet** delimiters `/T/` (K29.7) + `/R/` (K23.7) on TX_EN deassertion

---

## Directory Structure

```
uvm_8b10b_encoder/
├── rtl/
│   └── encoder_8b10b.sv          ← DUT (fill in your implementation here)
│
├── tb/
│   ├── encoder_if.sv             ← SystemVerilog interface (drv + mon clocking blocks)
│   ├── top.sv                    ← Top-level testbench module
│   │
│   ├── pkg/
│   │   ├── encoder_types_pkg.sv  ← 8B/10B tables, K-code constants, encode functions
│   │   └── encoder_uvm_pkg.sv    ← Master UVM package (includes all classes)
│   │
│   ├── sequences/
│   │   ├── encoder_seq_item.sv   ← UVM sequence item (Din, TX_EN → Dout)
│   │   ├── encoder_base_seq.sv   ← Base sequence with helper task
│   │   ├── encoder_idle_seq.sv   ← Sustained IDLE stimulus
│   │   ├── encoder_packet_seq.sv ← Full packet with configurable payload
│   │   └── encoder_rand_seq.sv   ← Randomised mix of packets and idles
│   │
│   ├── agent/
│   │   ├── encoder_sequencer.sv
│   │   ├── encoder_driver.sv     ← Drives Din/TX_EN each clock cycle
│   │   ├── encoder_monitor.sv    ← Observes Din/TX_EN/Dout, broadcasts to AP
│   │   └── encoder_agent.sv      ← Active agent (sqr + drv + mon)
│   │
│   ├── env/
│   │   ├── encoder_scoreboard.sv ← Reference model + checker
│   │   ├── encoder_coverage.sv   ← Functional coverage collector
│   │   └── encoder_env.sv        ← Environment (agent + sb + cov)
│   │
│   └── tests/
│       ├── encoder_base_test.sv  ← Base test (interface wiring, config_db)
│       ├── encoder_idle_test.sv  ← 100-cycle IDLE verification
│       ├── encoder_packet_test.sv← Directed packet tests (all-0, all-1, counter…)
│       └── encoder_rand_test.sv  ← Randomised regression
│
├── sim/
│   ├── filelist.f                ← Tool-agnostic compile-order file list
│   └── run.do                    ← Questa/ModelSim macro
│
├── Makefile                      ← Questa / VCS / Xcelium targets
├── .gitignore
└── README.md
```

---

## DUT Interface

| Signal  | Width | Dir | Description                                   |
|---------|-------|-----|-----------------------------------------------|
| `Clk`   | 1     | In  | 160 MHz rising-edge clock                     |
| `Din`   | 8     | In  | GMII TXD — data byte to encode                |
| `TX_EN` | 1     | In  | High = packet present; Low = idle             |
| `Dout`  | 10    | Out | 8B/10B code-group output (one per clock cycle)|

Bit ordering of `Dout[9:0]` follows the spec's *abcdei fghj* notation:

```
Dout[0] = a  (first transmitted bit)
Dout[5] = i
Dout[6] = f
Dout[9] = j  (last transmitted bit)
```

---

## Output Code-Group Sequence

```
... /I/ /I/ /I/ | /S/ D D D ... D | /T/ /R/ [/R/] | /I/ /I/ ...
  (IDLE)        |   (packet)      |    (EPD)       |  (IDLE)
                ↑ TX_EN asserts   ↑ TX_EN deasserts
```

- `/I/` = alternating `/I1/` (K28.5 D5.6) and `/I2/` (K28.5 D16.2)
- `/S/` = K27.7 — the first `/I/` after reset is always `/I1/` to restore RD−
- Each `/D/` byte is 8B/10B encoded; running disparity is tracked
- `/T/R/` closes the packet; a second `/R/` is appended if necessary to
  keep `/I/` aligned on an even code-group boundary (§36.2.4.15)

---

## Running the Testbench

### Prerequisites

- Questa / ModelSim, Synopsys VCS, or Cadence Xcelium
- UVM 1.2 (set `UVM_HOME` environment variable)

### Compile & simulate (Questa)

```bash
cd uvm_8b10b_encoder
export UVM_HOME=/path/to/questa/uvm-1.2

# Default test (encoder_packet_test)
make sim TOOL=questa

# Idle test
make sim TOOL=questa TEST=encoder_idle_test

# Randomised regression (3 seeds)
make regression TOOL=questa

# GUI with waveforms
make gui TOOL=questa TEST=encoder_packet_test
```

### VCS

```bash
export VCS_UVM_HOME=/path/to/vcs/uvm-1.2
make sim TOOL=vcs TEST=encoder_rand_test SEED=42
```

### Xcelium

```bash
export XCELIUM_UVM_HOME=/path/to/xcelium/uvm-1.2
make sim TOOL=xcelium
```

### Plusarg reference

| Plusarg                  | Default               | Purpose                   |
|--------------------------|-----------------------|---------------------------|
| `+UVM_TESTNAME=<name>`   | `encoder_packet_test` | Select test               |
| `+UVM_VERBOSITY=<level>` | `UVM_MEDIUM`          | Log verbosity             |
| `+ntx=<N>`               | 30                    | Transactions in rand test |
| `+WAVES`                 | off                   | Enable VCD waveform dump  |

---

## Scoreboard / Reference Model

`encoder_scoreboard.sv` implements a cycle-accurate reference model of the
PCS Transmit state machine (IEEE 802.3-2012 Fig. 36-5).  It uses the
same `encode_data()` and `encode_kcode()` functions from
`encoder_types_pkg.sv` and tracks running disparity independently.

Each cycle the monitor broadcasts a transaction; the scoreboard predicts
the expected `Dout` and issues a `uvm_error` on any mismatch.

---

## Functional Coverage

`encoder_coverage.sv` measures:

| Covergroup              | What it checks                                        |
|-------------------------|-------------------------------------------------------|
| `cg_data_bytes`         | All 256 Din values exercised during TX                |
| `cg_tx_en_transitions`  | Rising / falling / sustained edges of TX_EN           |
| `cg_output_codes`       | K27.7, K29.7, K23.7, K28.5 all appear in Dout        |
| `cg_idle_sets`          | Both /I1/ (D5.6) and /I2/ (D16.2) second code-groups |

---

## Implementation Notes

1. **FIFO requirement** — The spec requires the DUT to buffer the first
   incoming data byte while inserting the two-code-group `/S/` ordered set.
   Your RTL needs at least a 1-deep FIFO on the input path.

2. **Even/odd alignment** — Track `tx_even` (toggled every code-group).
   The `/T/` must be on an odd position so the following `/I/` lands on
   even.  If alignment is wrong, an extra `/R/` must be inserted.

3. **Disparity initialization** — After power-on (or reset), the transmitter
   must start with RD = negative (§36.2.4.4).

4. **First IDLE after packet** — Must always be `/I1/` to restore RD to
   negative (§36.2.4.12).
