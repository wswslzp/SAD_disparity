module xprop(
	input logic sel,
	input logic [1:0] a,
	input logic [1:0] b,
	output logic [1:0] y);


always_comb begin
	assert (sel !== 1'bx)
	else $error("%m, sel = x");
	if (sel) 
		y = a;
	else //if (~sel) 
		y = b;
	//else 
	//	y = 'x;
end


endmodule
