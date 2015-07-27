module parallel_shift(clk, reset, in, out);

input clk, reset, in;
output reg [7:0] out;

always @(posedge clk or posedge reset)
	begin
		if (reset)
			out[7:0] <= 8'b00000000;
		else
			out <= {out[6:0],in};
	end

endmodule 