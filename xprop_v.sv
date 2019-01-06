`timescale 1ns/1ns

module xprop_v;

logic sel;
logic [1:0] a, b;
logic [1:0] y;


xprop u1
(
	.*);


initial begin
	//#0
	sel = 1'b1;
	a = 2'b10;
	b = 2'b01;
	#50
	sel = 1'b0;
	#50 
	sel = 1'bx;
	#100
	$stop;
end


endmodule 
