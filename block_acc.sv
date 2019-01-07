`timescale 1ns/1ns
module block_acc #(
	// the NODE_NUM here must the power of 2
	parameter integer NODE_NUM = 8,
	// the data's width, must be large enough so that it won't be overflow!!!
	parameter integer NODE_WIDTH = 4
) ( 
	input logic										clk,
	input logic										rst_n,
	
	// every pixel has a ena signal
	input logic										ena[NODE_NUM],
	
	// input datas
	input logic [NODE_WIDTH-1:0]	add_node[NODE_NUM],

	// output result with cout
	output logic [NODE_WIDTH:0]		add_res,

	// output complete flag
	output logic									done
);

localparam int CURRENT_NODE_NUM = NODE_NUM;
localparam int NEXT_NODE_NUM = NODE_NUM / 2;

// generate for adder tree
generate

	// if the NODE_NUM == 1, then input directly export
	if (NODE_NUM == 1) begin : E1 // end of iteration
		always_ff @(posedge clk, negedge rst_n) begin
			assert ( ena !== 'x ) 
			else $error("%m, find ena = x");
			if ( ~rst_n ) begin
				add_res <= '0;
				done <= 1'b0;
			end else begin
				if ( ~ena ) begin
					add_res <= add_res;
					done <= 1'b0;
				end else begin
					add_res <= add_node;
					done <= 1'b1;
				end
			end
		end
	end : E1

	// if NODE_NUM = 2, then create an adder for two number
	else if (NODE_NUM == 2) begin : E2 // end of iteration
		always_ff @(posedge clk, negedge rst_n) begin
			assert ( ena !== 'x ) 
			else $error("$m, find ena = x");
			if ( ~rst_n ) begin
				add_res <= '0;
				done <= 1'b0;
			end else begin
				if ( ~ena[0] || ~ena[1] ) begin
					add_res <= add_res;
					done <= 1'b0;
				end else begin
					add_res <= add_node[0] + add_node[1];
					done <= 1'b1;
				end
			end
		end
	end : E2

	// if NODE_NUM > 2, then recursedly instantial this module to generate adder
	else begin : INTERNEL
		// internal wires for interconnnect
		wire [NODE_WIDTH:0] l_add_res, r_add_res;
		wire l_done, r_done;
		wire in_ena = l_done & r_done;

		// internal two accumulator
		block_acc #(.NODE_NUM(NEXT_NODE_NUM),
								.NODE_WIDTH(NODE_WIDTH))
						ul (.clk, 
								.rst_n,
								.ena(ena[0:NEXT_NODE_NUM-1]),
								.add_node(add_node[0:NEXT_NODE_NUM-1]),
								.add_res(l_add_res),
								.done(l_done));

		block_acc #(.NODE_NUM(NEXT_NODE_NUM),
								.NODE_WIDTH(NODE_WIDTH))
						ur (.clk, 
								.rst_n,
								.ena(ena[NEXT_NODE_NUM:CURRENT_NODE_NUM-1]),
								.add_node(add_node[NEXT_NODE_NUM:CURRENT_NODE_NUM-1]),
								.add_res(r_add_res),
								.done(r_done));

		// root adder
		always_ff @(posedge clk, negedge rst_n) begin
			if ( ~rst_n ) begin
				add_res <= '0;
				done <= 1'b0;
			end else begin
				if ( in_ena ) begin
					add_res <= l_add_res + r_add_res;
					done <= 1'b1;
				end else begin
					add_res <= add_res;
					done <= 1'b0;
				end
			end
		end

	end : INTERNEL


endgenerate

endmodule
