// Acquire controller manages the writing of reservoir data to memory, and the retrieval of data from memory that
// the USB controller requests.

module acquire_controller(CLOCK_50, send_clk, node_dyn, acquire_signal, reset, ram_rd_address, send_byte);


// Parameters
parameter log_nr_lines;
parameter nr_samples;
parameter IDLE = 1'b0, ACQUIRE = 1'b1;


// Internal elements
input CLOCK_50;
input send_clk;
input node_dyn;
input acquire_signal;
input reset;
input [log_nr_lines-1:0] ram_rd_address;

output reg [7:0] send_byte;

reg state;
reg clr;
reg ram_wren;
reg pingpong;

wire [7:0] shift_out0, shift_out1;
wire [7:0] ram_in;
wire fast_clk;
wire [log_nr_lines-1:0] ram_wr_address;
wire ram_wr_clk;
wire [7:0] ram_out;
wire [log_nr_lines-1:0] ram_address;
wire ram_read_clk;
wire ram_clk;
wire [2:0] mem_pos;


// Instantiate RAM module (1 port, 2 clocks, 8x1k)
ram_to_save_wf1 ram1(
	.address(ram_address),
	.inclock(ram_wr_clk),
	.outclock(ram_read_clk),
	.data(ram_in[7:0]),
	.wren(ram_wren),
	.q(ram_out));
	

// Read and write clocks
// Create a fast clock for storing data. RAM should not be operated faster than 200 MHz, so fast_clk should not be faster than 8 x 200 MHz = 1.6 GHz
wf_acqu_clk pll1(CLOCK_50,fast_clk);					// 400 MHz
mod8counter counter0(reset, fast_clk, mem_pos);		// fast_clk / 8 = 50 MHz
assign ram_read_clk = send_clk;
assign ram_wr_clk = ~mem_pos[2];


//Create a counter that manages the RAM write address (increases by one during each RAM write cycle)
acq_counter counter1(clr, ram_wr_clk, ram_wren, ram_wr_address);


// Single port RAM, so switch between write address and read address, depending on current operation
assign ram_address = (ram_wren ? ram_wr_address : ram_rd_address);


// Parallel shift registers to turn serial data into 8-bit parallel data 
parallel_shift shift0(fast_clk & ~pingpong, reset, node_dyn, shift_out0);
parallel_shift shift1(fast_clk & pingpong, reset, node_dyn, shift_out1);

// Ping-pong between the two shift registers so that ram_in isn't updated by new data before old data is written to RAM
always @ (posedge ram_wr_clk)
	begin
		pingpong <= ~ pingpong;
	end

assign ram_in[7:0] = pingpong ? shift_out0[7:0] : shift_out1[7:0];


// Data read from RAM is output to USB comm controller to be transmitted to PC
always @(posedge send_clk)
	send_byte[7:0] = ram_out[7:0];


// Finite state machine for acquiring data
always @(state)
	begin
		case (state)
			IDLE:
				begin
					ram_wren <= 1'b0;
					clr <= 1'b1;
				end
			ACQUIRE:
				begin
					ram_wren <= 1'b1;
					clr <= 1'b0;
				end
			default:
				begin
					ram_wren <= 1'b0;
					clr <= 1'b1;
				end
		endcase
	end

always @(posedge fast_clk or posedge reset)
	begin
		if (reset)
			state <= IDLE;
		else
			begin
				case (state)
					IDLE:
						begin
							if (acquire_signal)
								state <= ACQUIRE;
							else
								state <= IDLE;
						end
					ACQUIRE:
						begin
							if (ram_wr_address < nr_samples / 8)
								state <= ACQUIRE;
							else
								state <= IDLE;
						end
					default:
						state <= IDLE;
				endcase
			end
	end


endmodule 
