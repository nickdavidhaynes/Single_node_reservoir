 
module delay_ABN_reservoir(in,out,res_enable);

parameter delay1, delay2;

input in;
input res_enable;
output out; 

wire [2:0] out_delayed;

delay #(delay1) d_inst0(out,out_delayed[0]);
delay #(delay2) d_inst1(out,out_delayed[1]);

// output layer
assign out = (in ^ out_delayed[0] ^ out_delayed[1]) & res_enable;


endmodule

