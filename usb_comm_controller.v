// USB comm controller manages the protocol necessary to read and write data between the FPGA and the PC using the FTDI UM232H-B
// breakout board in asynch 245 FIFO mode (make sure chip is programmed for 245 FIFO using FT_Prog utility). Refer to FT232H
// manual for details about protocol.

module usb_comm_controller(CLOCK_50, write_data, reset, write_sig, GPIO, read_data, received, ram_rd_address, send_clk, LEDR);


// Parameters
parameter IDLE = 0, READ_I = 1, READ_II = 2, READ_III = 3, CHECK_TXE = 4, WRITE_I = 5, WRITE_II = 6, WRITE_III = 7;
parameter nr_samples;//nr_words to send
parameter log_nr_lines;


// Internal elements
input CLOCK_50;
input [7:0] write_data;
input reset;
input write_sig; // write request signal

inout [35:0] GPIO;

output reg [7:0] read_data;
output reg received;
output [log_nr_lines-1:0] ram_rd_address;
output send_clk;

reg def_flag;
output [4:0] LEDR;
assign LEDR[2:0] = state[2:0];
assign LEDR[3] = TXE_i;
assign LEDR[4] = def_flag;

wire RXF_i;		// c0, input, when low, data is available to read
wire TXE_i;    // c1, input, when high, do not read: buffer full
wire RXLED_i, TXLED_i;
reg RD_i;     // c2, read clock: data to lines when it goes low, read when it goes high
reg WR_i;		// c3, write clock: write to chip when WR_i goes low
wire SIWU_i;  // c4, wakeup signal, should be tied to 1
wire PWRSAV_i; // c7, powersaver, should be tied to 1

reg oe; // output enable for data wires
reg addr_inc, addr_reset;
wire reset;
reg read_flag;
reg [2:0] state;

assign RXF_i = GPIO[11];
assign TXE_i = GPIO[13];
assign GPIO[15] = RD_i;
assign GPIO[17] = WR_i;
assign GPIO[19] = SIWU_i;
assign GPIO[25] = PWRSAV_i;
assign SIWU_i = 1'b1;										// Keep SIWU tied to 1
assign PWRSAV_i = 1'b1;										// Keep PWRSAV tied to 1
assign send_clk = oe;										//output enable provides a send clock, as it ticks high, when new data has to be provided
assign GPIO[10] = oe ? write_data[0] : 8'bZ;
assign GPIO[12] = oe ? write_data[1] : 8'bZ;
assign GPIO[14] = oe ? write_data[2] : 8'bZ;
assign GPIO[16] = oe ? write_data[3] : 8'bZ;
assign GPIO[18] = oe ? write_data[4] : 8'bZ;
assign GPIO[20] = oe ? write_data[5] : 8'bZ;
assign GPIO[22] = oe ? write_data[6] : 8'bZ;
assign GPIO[24] = oe ? write_data[7] : 8'bZ;


// Counter for ram read address values (increases once per read cycle)
rd_addr_counter counter0(.aclr(addr_reset),.clock(addr_inc),.q(ram_rd_address));


always @(posedge read_flag)
	begin
		read_data[0] = GPIO[10];
		read_data[1] = GPIO[12];
		read_data[2] = GPIO[14];
		read_data[3] = GPIO[16];
		read_data[4] = GPIO[18];
		read_data[5] = GPIO[20];
		read_data[6] = GPIO[22];
		read_data[7] = GPIO[24];
	end


// finite state machine for USB reading and writing
always @(*)
	begin
		case (state)
			IDLE:
				begin
					WR_i <= 1'b1;
					oe <= 1'b0;
					RD_i <= 1'b1;
					read_flag <= 1'b0;
					received <= 1'b0;
					addr_reset <= 1'b1;
					addr_inc   <= 1'b0;
					def_flag <= 1'b0;
				end
			READ_I:
				begin
					WR_i <= 1'b1;
					oe <= 1'b0;		
					RD_i <= 1'b0;						//send signal to chip to send data to the FPGA (for at least 2 clock cycles > 30 ns)
					read_flag <= 1'b0;
					received <= 1'b0;
					addr_reset <= 1'b1;
					addr_inc   <= 1'b0;
					def_flag <= 1'b0;
				end
			READ_II:
				begin
					WR_i <= 1'b1;
					oe <= 1'b0;
					RD_i <= 1'b0;
					read_flag <= 1'b1;				//strobe read_flag
					received <= 1'b0;
					addr_reset <= 1'b1;
					addr_inc   <= 1'b0;
					def_flag <= 1'b0;
				end
			READ_III:
				begin
					WR_i <= 1'b1;
					oe <= 1'b0;
					RD_i <= 1'b1;						//turn off the read signal
					read_flag <= 1'b0;
					received <= 1'b1;					//signal that a byte was read
					addr_reset <= 1'b1;
					addr_inc   <= 1'b0;
					def_flag <= 1'b0;
				end
			CHECK_TXE:
				begin
					WR_i <= 1'b1;
					oe <= 1'b0;
					RD_i <= 1'b1;
					read_flag <= 1'b0;
					received <= 1'b0;
					addr_reset <= 1'b0;					//do not reset n anymore
					addr_inc   <= 1'b0;
					def_flag <= 1'b0;
				end
			WRITE_I:
				begin
					WR_i <= 1'b1;
					oe <= 1'b1;							//enable the output from tristate
					RD_i <= 1'b1;
					read_flag <= 1'b0;
					received <= 1'b0;
					addr_reset <= 1'b0;
					addr_inc   <= 1'b1;					//increase  by one
					def_flag <= 1'b0;
				end
			WRITE_II:
				begin
					WR_i <= 1'b0;						//here, the data: write_data must be stable already
					oe <= 1'b1;
					RD_i <= 1'b1;
					read_flag <= 1'b0;
					received <= 1'b0;
					addr_reset <= 1'b0;
					addr_inc   <= 1'b0;
					def_flag <= 1'b0;
				end
			WRITE_III:
				begin
					WR_i <= 1'b0;
					oe <= 1'b0;							//data can be disabled within 5ns from WR_i negedge
					RD_i <= 1'b1;
					read_flag <= 1'b0;
					received <= 1'b0;
					addr_reset <= 1'b0;
					addr_inc   <= 1'b0;
					def_flag <= 1'b0;
				end
			default:
				begin
					WR_i <= 1'b1;
					oe <= 1'b0;
					RD_i <= 1'b1;
					read_flag <= 1'b0;
					received <= 1'b0;
					addr_reset <= 1'b1;
					addr_inc   <= 1'b0;
					def_flag <= 1'b1;
				end
		endcase
	end
	

always @(posedge CLOCK_50 or posedge reset)
	begin
		if (reset)
			state <= IDLE;
		else
			case (state)
				IDLE:
					begin
						if(write_sig == 1'b1)					//write requested
							state <= CHECK_TXE;
						else if (RXF_i == 1'b0)					//data available to read
							state <= READ_I;
						else
							state <= IDLE;
					end			
				READ_I:
					state <= READ_II;
				READ_II:
					state <= READ_III;
				READ_III:
					state <= IDLE;
				CHECK_TXE:
					begin
						if(TXE_i == 1'b0)
							state <= WRITE_I;
						else
							state <= CHECK_TXE;
					end
				WRITE_I:
					state <= WRITE_II;
				WRITE_II:
					state <= WRITE_III;
				WRITE_III:
					begin
						if (ram_rd_address < nr_samples / 8)
							state <= CHECK_TXE;
						else
							state <= IDLE;
					end
				default:
					state <= IDLE;
			endcase
	end


endmodule 