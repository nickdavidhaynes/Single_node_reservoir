// Master FSM evaluates the word sent from the computer as an instruction to either:
// 1) Go idle
// 2) Receive instructions from computer
// 3) Acquire the reservoir dynamics to memory 
// 4) Send the memory content to the computer

module master_fsm(CLOCK_50, KEY, received, receive_byte, acquire_signal, send_signal, reset);


// Parameters
parameter idle = 5'b00001, RCVD = 5'b00010, acquire = 5'b00100, send = 5'b01000, rst = 5'b10000;


// Internal elements
input CLOCK_50;
input [0:0] KEY;
input received;
input [7:0] receive_byte;

output acquire_signal;
output send_signal;
output reset;

reg [4:0] state;
reg [5:0] count1;
reg [5:0] count2;

wire hardware_reset;

assign acquire_signal = state[2];
assign send_signal = state[3];
assign hardware_reset = ~KEY[0];
assign reset = state[4] | hardware_reset;


// The finite state machine
always @(posedge CLOCK_50 or posedge hardware_reset)
begin
   if (hardware_reset)
		begin
         state <= idle;
			count1 <= 0;
		end
   else
		begin
			case (state)
				idle:
					begin
						count1 <= 0;
						count2 <= 0;
						if (received)
							begin
								state <= RCVD;
							end
						else
							begin
								state <= idle;
							end
					end
				RCVD:
					begin
						count1 <= 0;
						count2 <= 0;
						case (receive_byte[7:6])
							2'b01: state <= acquire;
							2'b10: state <= send;
							2'b11: state <= rst;
						default: 
								state <= idle;
						endcase
					end
				acquire:
					begin
						if (count1 < 10)
							begin
								state <= acquire;
								count1 <= count1 + 1;
								count2 <= 0;
							end
						else 
							begin
								state <= idle;
								count1 <= 0;
								count2 <= 0;
							end
					end
				send:
					begin
						if (count2 < 10)
							begin
								state <= send;
								count1 <= 0;
								count2 <= count2 + 1;
							end
						else
							begin
								state <= idle;
								count1 <= 0;
								count2 <= 0;
							end
					end
				rst:
					begin
						state <= idle;
						count1 <= 0;
						count2 <= 0;
					end
				default:
					begin
						state <= idle;
						count1 <= 0;
						count2 <= 0;
					end
			endcase
		end
end

endmodule 
