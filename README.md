# Systolic-Array-Accelerator-for-RISCV

A fully parameterizable N×N systolic array accelerator for matrix multiplication, implemented in SystemVerilog using a pipelined MAC mesh. The design supports streaming wavefront dataflow and is suitable for RISC-V accelerator integration.

##  Overview
This accelerator computes C = A × B using a systolic array architecture.  
Matrix A streams horizontally across the array, while matrix B streams vertically. Each processing element performs a multiply–accumulate (MAC) operation every cycle, enabling fully pipelined, high-throughput computation.

## Module Description

### accel_pcpi_wrapper.sv
Front-end control and data streaming module:
- Streams matrix A into systolic rows
- Streams matrix B into systolic columns
- Controls computation start and valid timing
- Waits for completion and outputs flattened results

### accel_top.sv
Core systolic array compute engine:
- N×N MAC processing elements
- Horizontal propagation of A and vertical propagation of B
- Fully pipelined accumulation of partial sums
- Outputs flattened result matrix

### tb_accel.sv
SystemVerilog testbench:
- Generates clock and reset
- Initializes A as an ascending matrix
- Initializes B as an identity matrix
- Triggers accelerator and waits for completion
- Verifies correctness (output equals A)

## Running Simulation

### Compile
```bash
ncvlog accel_pcpi_wrapper.sv accel_top.sv tb_accel.sv
