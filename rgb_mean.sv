`timescale 1ns/1ns

module rgb_mean #(
	parameter CAMERA_HSIZE = 1, 
	parameter CAMERA_VSIZE = 1,
	parameter PIXEL_SIZE = 1,
	parameter MEAN_SIZE = PIXEL_SIZE/3,
	parameter BUF_ADDR_WIDTH = 1)
(
	input wire clk,
	input wire rst_n, 
	input wire cam_frame_valid,
	input wire cam_line_valid,
	input wire cam_pixel_clk,
	input wire [PIXEL_SIZE-1:0] cam_pixel_rgb,
	output reg [MEAN_SIZE-1:0] pixel_mean,
	output reg [BUF_ADDR_WIDTH-1:0] buf_waddr,
	output reg buf_wvalid, 
	input wire buf_wready,
	input wire sad_done
);
/* ---------------local parameter-----------*/

/* ---------------wire declaration----------*/
wire line_valid_tog;

/* ---------------reg declaration-----------*/
reg [15:0] pixel_counter;
reg [15:0] line_counter;
reg lt1, lt2;

// pixel counter, plus one for each input pixel valided
always @(negedge cam_pixel_clk, negedge rst_n) begin
	if ( ~rst_n ) 
		pixel_counter <= 1'b0;
	else if ( cam_line_valid == 1'b0 || buf_wready == 1'b0) 
		pixel_counter <= 1'b0;
	else 
		pixel_counter <= pixel_counter + 1'b1;
end

// detect the edge of cam_line_valid
always @(posedge clk, negedge rst_n) begin
	if ( ~rst_n ) begin 
		lt1 <= 0;
		lt2 <= 0;
	end else begin
		lt1 <= cam_line_valid;
		lt2 <= lt1;
	end
end

assign line_valid_tog = lt1 & (~lt2);

// line counter, plus one for each input line
always @(posedge clk, negedge rst_n) begin
	if ( ~rst_n ) 
		line_counter <= 1'b0;
	else if ( ~buf_wready ) 
		line_counter <= 1'b0;
	else if (line_valid_tog == 1'b1) 
		line_counter <= line_counter + 1;
	else ;
end

endmodule
