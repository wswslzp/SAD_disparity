`timescale 1ns/1ns

// only for verification not RTL sythesis
module image_buffer #(
	parameter CAMERA_HSIZE = 1,
	parameter CAMERA_VSIZE = 1,
	parameter PIXEL_SIZE = 1,
	parameter BUF_ADDR_WIDTH = 1)
	(
		// system signal, clock, reset
		input wire clk, 
		input wire rst_n,
		// read transaction
		input wire [BUF_ADDR_WIDTH-1:0] buf_raddr,
		input wire buf_rvalid,
		output reg buf_rready,
		output reg [PIXEL_SIZE-1:0] buf_rdata,
		// write transaction
		input wire [BUF_ADDR_WIDTH-1:0] buf_waddr,
		input wire [PIXEL_SIZE-1:0] buf_wdata,
		input wire buf_wvalid,
		output reg buf_wready
	);

	/*--------------local parameter----------------*/
	localparam BUFFER_DEPTH = 2**BUF_ADDR_WIDTH;

	/*--------------wire declare-------------------*/

	/*--------------reg declare--------------------*/
	reg [BUFFER_DEPTH-1:0][PIXEL_SIZE-1:0] buffer = 0;// ideal model not real
	//logic [BUF_ADDR_WIDTH-1:0] buffer_address = 0;
	
	// write transaction
	always @(posedge clk, negedge rst_n) begin
		if ( ~rst_n ) begin
			buffer <= 0;
			buf_wready <= 1;
		end else begin
			if ( buf_wvalid == 1'b1 ) begin
				// behavioral model
				buffer[buf_waddr] <= buf_wdata;
				buf_wready <= 0;
			end else 
				buf_wready <= 1;
		end
	end 

	// read transaction
	always @(posedge clk, negedge rst_n) begin
		if ( ~rst_n ) begin
			buf_rready <= 1;
			buf_rdata <= 0;
		end else begin
			if ( buf_rvalid == 1'b1 ) begin
				// behavioral model
				buf_rdata <= buffer[buf_raddr];
				buf_rready <= 0;
			end 
			else 
				buf_rready <= 1;
		end 
	end 



	endmodule
