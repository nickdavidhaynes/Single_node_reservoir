// Reservoir controller instantiates the reservoir and controls its operation. Because transients are long, we don't want to wait
// for the reservoir to find its fixed point with every run. Instead, reservoir controller allows the reservoir dynamics to evolve
// for a period of time, then disables and resets it for the next run.

module reservoir_controller(CLOCK_50, reset, acquire_signal, dynamics, collect_dynamics, LEDG, receive_byte);


// Parameters
parameter IDLE = 0, RES1 = 1;
parameter delay1, delay2;


// Internal elements
input CLOCK_50;
input reset;
input acquire_signal;
input [7:0] receive_byte;

output dynamics;
output reg collect_dynamics;
output [7:0] LEDG;

wire fast_clk;

reg [6:0] input_word;
reg res_enable;
reg in_state;
reg [11:0] cnt;
reg state;

assign LEDG[7:0] = receive_byte[7:0];


// Instantiate reservoir
delay_ABN_reservoir #(.delay1(delay1), .delay2(delay2)) reservoir0(in_state, dynamics, res_enable);


// Run reservoir for a while, then disable it
res_clk pll_inst(CLOCK_50,fast_clk);		// 400 MHz

always @(posedge fast_clk or posedge reset) begin
	if (reset) begin
		state <= IDLE;
		input_word[6:0] <= 7'b0;
	end
	else 
		begin
			case (state)
				IDLE:
					begin
						if (acquire_signal) begin
							state <= RES1;
							cnt <= 0;
							input_word[0] <= 1'b1;
							input_word[6:1] <= receive_byte[5:0];
						end
						else begin
							state <= IDLE;		
							in_state   <= 1'b0;
							res_enable <= 1'b0;
							collect_dynamics <= 1'b0;
							cnt <= 0;
						end
					end
				RES1:
					begin
						if(cnt <= 6)									// send input pattern
							begin
								state <= RES1;
								in_state <= input_word[cnt] & ~reset;
								res_enable <= 1'b1;
								collect_dynamics <= 1'b1;
								cnt <= cnt + 1;
							end
						else if(cnt <= 3000)							// Reservoir enabled, dynamics evolving
							begin
								state <= RES1;
								in_state   <= 1'b0;
								res_enable <= 1'b1;
								collect_dynamics <= 1'b0;
								cnt   <= cnt + 1;
							end
						else if(cnt <= 3100)							// Reservoir disabled, wait to settle into fixed point
							begin
								state <= RES1;
								in_state   <= 1'b0;
								res_enable <= 1'b0;		
								collect_dynamics <= 1'b0;
								cnt   <= cnt + 1;
							end
							
						else if(cnt <= 3200)							// Enable again, should be in fixed point
							begin
								state <= RES1;
								in_state   <= 1'b0;
								res_enable <= 1'b1;
								collect_dynamics <= 1'b0;
								cnt   <= cnt + 1;
							end
							
						else 												// Reset counter, wait for next run
							begin
								state <= IDLE;
								in_state   <= 1'b0;
								res_enable <= 1'b1;
								collect_dynamics <= 1'b0;
								cnt   <= 0;
							end
					end
				default:
					begin
						state <= IDLE;
						in_state   <= 1'b0;
						res_enable <= 1'b0;
						collect_dynamics <= 1'b0;
						cnt   <= 0;
					end
			endcase
		end
	end

endmodule 