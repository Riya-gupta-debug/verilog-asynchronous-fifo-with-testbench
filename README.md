# verilog-asynchronous-fifo-with-testbench
This repository implements an asynchronous FIFO (First-In-First-Out) buffer in Verilog, designed to handle data transfer across two different clock domains using Gray code pointers and 2-flop synchronizers for safe Clock Domain Crossing (CDC).

## Key Concepts

- Dual Clock Domains: Separate `wclk` (write) and `rclk` (read)
- CDC Handling: 2-stage flip-flop synchronization of pointers
- Gray Code Pointers: Only one bit changes at a time to avoid metastability
- Full/Empty Detection: Based on synchronized pointers and MSB comparison
- Parameterizable: Easily adjustable data width and depth
