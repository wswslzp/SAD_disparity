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
	input wire cam_pixel_clk, // assumption that camera's clock much more slower than system clock
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
wire pixel_clk_e;

/* ---------------reg declaration-----------*/
reg [15:0] pixel_counter;
reg [15:0] line_counter;
reg lt1, lt2;
reg [BUF_ADDR_WIDTH-1:0] addr_mid_reg;
reg [PIXEL_SIZE-1:0] raw_pixel;
reg [MEAN_SIZE-1:0] b_reg;
reg [MEAN_SIZE:0] rg_reg;
reg [2:0] state;
reg pt1, pt2;
reg state_start;

// detect the fall down edge of camera's pixel clock
always @(negedge clk, negedge rst_n) begin
	if ( ~rst_n ) 
		{pt1, pt2} <= 2'b0;
	else begin
		pt1 <= cam_pixel_clk;
		pt2 <= pt1;
	end
end

assign pixel_clk_e = (~pt1) & pt2;

// output buffer valid
always @(posedge clk, negedge rst_n) begin
	if ( ~rst_n ) begin 
		state <= 0;
		state_start <= 0;
		buf_wvalid <= 0;	
	end
	else begin
		if (pixel_clk_e) begin
			state <= 3'b001;
			state_start <= 1;
			buf_wvalid <= 0;
		end else if (state_start) begin
			state <= state + 1;
			if (state == 3'b010) begin
				buf_wvalid <= 1;
				state_start <= 0;
			end 
		end
		else if (state == 3'b011) 
			buf_wvalid <= 0;
	end 
end

// pixel counter, plus one for each input pixel valided
always @(negedge cam_pixel_clk, negedge rst_n) begin
	if ( ~rst_n ) 
		pixel_counter <= 1'b0;
	else if ( cam_line_valid == 1'b0 || buf_wready == 1'b0) 
		pixel_counter <= 1'b0;
	else 
		pixel_counter <= pixel_counter + 1'b1;
end

// detect the rise edge of cam_line_valid
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

// buffer address generator
always @(posedge clk, negedge rst_n) begin
	if ( ~rst_n ) 
		addr_mid_reg <= 0;
	else // TODO: this critical path needs to be modified in order to balance pipeline
		addr_mid_reg <= pixel_counter-1 + CAMERA_HSIZE * (line_counter-1);//constant multiply module; width consideration
end

always @(posedge clk) buf_waddr <= addr_mid_reg;

// read the pixel from camera
always @(posedge pixel_clk_e, negedge rst_n) begin
	if ( ~rst_n ) 
		raw_pixel <= 0;
	else if ( cam_frame_valid == 1'b1 && cam_line_valid == 1'b1 && buf_wready == 1'b1 ) 
		raw_pixel <= cam_pixel_rgb;
	else ;
end

// mean value: (R+G+B)/3
always @(posedge clk, negedge rst_n) begin
	if ( ~rst_n ) begin
		rg_reg <= 5'b0;
		b_reg  <= 4'b0;
	end else begin
		rg_reg <= raw_pixel[11:8] + raw_pixel[7:4];
		b_reg  <= raw_pixel[3:0];
	end
end

// TODO: the critical path needs modification: constant divide
always @(posedge clk, negedge rst_n) begin
	if ( ~rst_n ) 
		pixel_mean <= 0;
	else 
		pixel_mean <= (rg_reg + b_reg)/3;
end

endmodule
