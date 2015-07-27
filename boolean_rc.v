// 8/13/2014, NDH

module boolean_rc(CLOCK_50, GPIO, KEY, LEDR, LEDG);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////// If you're not familiar with the operation of this project,      ////////////////////////////////////
///////////////// you should ONLY change these parameters. Changing other things  ////////////////////////////////////
///////////////// has a high probability of breaking the project.						 ////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
parameter nr_samples = 200;		// Number of time series samples taken - make sure to adjust the corresponding parameter in LabVIEW, too!
parameter delay1 = 18;				// Number of elements in the 1st delay line
parameter delay2 = 16;				// Number of elements in the 2nd delay line
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

parameter nr_lines = 8192;
parameter log_nr_lines = 10;

input CLOCK_50;
input [0:0] KEY;
inout [35:0] GPIO;

output [4:0] LEDR;
output [7:0] LEDG;

wire 			received;
wire [7:0] 	receive_byte;
wire 			acquire_signal;
wire 			send_signal;
wire [7:0] 	send_byte;
wire 			send_clk;
wire 			dynamics;
wire			collect_dynamics;
wire [log_nr_lines-1:0] n;
wire 			reset;
wire			res_enable;


// 1. Initialize master control FSM
master_fsm FSM0(
					CLOCK_50, 
					KEY[0], 
					received, 
					receive_byte, 
					acquire_signal, 
					send_signal, 
					reset);


// 3. Initialize acquisition controller
acquire_controller #(.nr_samples(nr_samples),.log_nr_lines(log_nr_lines)) acquire0(
					CLOCK_50, 
					send_clk, 
					dynamics, 
					collect_dynamics,
					reset, 
					n, 
					send_byte);


// 2. Initialize USB communications
usb_comm_controller #(.nr_samples(nr_samples), .log_nr_lines(log_nr_lines)) USB0(
					CLOCK_50, 
					send_byte, 
					reset, 
					send_signal, 
					GPIO, 
					receive_byte, 
					received, 
					n, 
					send_clk,
					LEDR[4:0]);


// 4. Build reservoir
reservoir_controller #(.delay1(delay1), .delay2(delay2)) res0(
					CLOCK_50,
					reset,
					acquire_signal,
					dynamics,
					collect_dynamics,
					LEDG[7:0],
					receive_byte);


					
endmodule 