`timescale 1ns/1ns
module SAD #(
	parameter integer CAMERA_HSIZE = 1,
	parameter integer CAMERA_VSIZE = 1,
	parameter integer PIXEL_SIZE = 1,
	parameter integer MEAN_SIZE = 1,
	parameter integer BUF_ADDR_WIDTH = 1,
	parameter integer BLOCK_SIZE = 1)
(
	input wire												clk,
	input wire												rst_n,

	// bus for buffer1
	output reg [BUF_ADDR_WIDTH-1:0]		buf1_raddr,
	input wire												buf1_rvalid,
	output reg												buf1_rready,
	input wire [MEAN_SIZE-1:0]				buf1_rdata,

	// bus for buffer2
	output reg [BUF_ADDR_WIDTH-1:0]		buf2_raddr,
	input wire												buf2_rvalid,
	output reg												buf2_rready,
	input wire [MEAN_SIZE-1:0]				buf2_rdata,

	// result 
	output reg [MEAN_SIZE-1:0]				sad_result,
	
	// indicator signal
	output reg												sad_done
);

// function for pixel subtraction: abs( X-Y )
function automatic logic signed [MEAN_SIZE-1:0] pixel_sub(
	input logic signed [MEAN_SIZE-1:0] a, b);
	
	return (a > b) ? (a - b) : (b - a);

endfunction


// function for block subtraction
function automatic void block_sub(
	input logic [MEAN_SIZE-1:0] block_a[BLOCK_SIZE][BLOCK_SIZE],
	input logic [MEAN_SIZE-1:0] block_b[BLOCK_SIZE][BLOCK_SIZE],
	output logic [MEAN_SIZE-1:0] block_res[BLOCK_SIZE][BLOCK_SIZE]);

	for(int i = 0; i < BLOCK_SIZE; i++) begin
		for(int j = 0; j < BLOCK_SIZE; j++) begin
			block_res[i][j] = pixel_sub(block_a[i][j], block_b[i][j]);
		end
	end

endfunction 


/* acquire value from buffer */


/* make computation */

endmodule
