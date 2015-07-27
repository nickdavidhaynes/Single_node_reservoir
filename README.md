# Single_node_reservoir

Included are the verilog files used to collect the data for
http://arxiv.org/abs/1411.1398 . This publication describes an
experiment using asynchronous digital logic on a field-programmable gate
array (FPGA) to construct a physical reservoir computer to solve simple
classification problems.

The Verilog code was compiled using Altera's Quartus II software. The
FPGA used in the experiment was an Altera Cyclone IV EP4CE115F29C7N on a
Terasic De2-115 development board. Data was transferred to the computer
using a FTDI FT232H USB chip that was attached to the FPGA's GPIO pins
(see the USB_comm repo for more info).

---------------------------------------------------------------------------
File list
---------------------------------------------------------------------------
boolean_rc.v
  Top module for the Quartus project. Instantiates master_fsm, 
  acquire_controller, usb_comm_controller, and reservoir_controller.
  
master_fsm.v
  Finite state machine that monitors USB communications and creates global
  commands to begin acquiring dynamics, send data, or reset FPGA based on 
  data received from PC.

acquire_controller.v
  Finite state machine that manages the reading and writing of data from
  RAM. Instantiates ram_to_save_wf1, a single port, dual clock RAM module
  of 8 bits wide x 1k bits deep. Also instantiates two parallel_shift mods
  for buffering reservoir dynamics before they're sent to RAM. Dynamics
  from reservoir are sampled into buffer at 400 MHz.
  
usb_comm_controller.v
  Finite state machine that manages the necessary protocol to read and write
  data between the FPGA and the PC using the FT232H USB chip in 245 FIFO mode.
  Modifying this file has a high probability of breaking the USB communication.
  
reservoir_controller.v
  Finite state machine that manages the reservoir. Upon receiving acquire_signal,
  it enables the reservoir dynamics and inputs the word that was received via 
  USB. It then waits a specified amount of time before shutting off the dynamics
  and forcing the reservoir back to it's fixed point state. Also instantiates
  delay_ABN_reservoir.
  
delay_ABN_reservoir.v
  The dynamical system itself. Instantiates two delay modules that delay input
  signal by a specific number of (pairs of) inverter gates. XOR's reservoir
  input and delay line outputs to create reservoir outputs.
  
delay.v
  The delay lines. By supplying parameter n_delay, a delay line of n_delay * 2
  inverter gates (wired in series) is constructed. Each delay element adds, on
  average, ~0.6 ns of delay (~0.3 ns per inverter gate).

parallel_shift.v
  Synchronous parallel shift register that turns a 8 bits of serial data into
  8 bits of parallel data.
  
All other .v files are auto-generated Quartus megafunctions. Refer to Quartus
documentation for more info.
  
