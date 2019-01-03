`timescale 1ns/1ns

module rgb_mean_vrf;

parameter CAMERA_HSIZE = 100;
parameter CAMERA_VSIZE = 100;
parameter BUF_ADDR_WIDTH = 32;

reg clk, rst_n, cam_frame_valid, cam_line_valid, cam_pixel_clk;
reg buf_wready, sad_done;
reg [11:0] cam_pixel_rgb;
wire [3:0] pixel_mean;
wire [BUF_ADDR_WIDTH-1:0] buf_waddr;
int frame_clk_counter = 0, line_clk_counter = 0, pixel_clk_counter = 0;
int red, green, blue, true_mean;

initial begin
	clk = 0;
	rst_n = 0;
	cam_frame_valid = 0;
	cam_line_valid = 0;
	cam_pixel_clk = 0;
	buf_wready = 0;
	sad_done  = 0;
	cam_pixel_rgb = 0;
	#1 
	rst_n = 1;
	cam_pixel_clk = 1;
	cam_line_valid = 1;
	cam_frame_valid = 1;
	buf_wready = 1;
end

// counter for clk generation
always #50 begin
	clk <= ~clk;
	if ( pixel_clk_counter < 10 ) 
		pixel_clk_counter++;
	else 
		pixel_clk_counter = 0;
	if (line_clk_counter < 10*CAMERA_HSIZE ) 
		line_clk_counter++;
	else 
		line_clk_counter = 0;
	if ( frame_clk_counter < 10*CAMERA_HSIZE*CAMERA_VSIZE) 
		frame_clk_counter++;
	else 
		frame_clk_counter = 0;
end

// generate camera clk
always @ (posedge clk) begin

	if ( cam_line_valid && cam_frame_valid ) begin
		if ( pixel_clk_counter == 1 ) 
			cam_pixel_clk <= ~cam_pixel_clk;
		else ;
	end else 
		cam_pixel_clk <= 0;

	if ( line_clk_counter == 1 && line_clk_counter == 50 ) 
		cam_line_valid <= ~cam_line_valid;
	else;
	if ( frame_clk_counter == 1 && frame_clk_counter == 100) 
		cam_frame_valid <= ~cam_frame_valid;
	else;
end

// generate pixel per pixel_clk
always @(posedge cam_pixel_clk) begin
	cam_pixel_rgb = $random%12'hfff;
	red = cam_pixel_rgb[11:8];
	green = cam_pixel_rgb[7:4];
	blue = cam_pixel_rgb[3:0];
	true_mean = (red + green + blue) / 3;
end

rgb_mean #(
	.CAMERA_HSIZE(CAMERA_HSIZE),
	.CAMERA_VSIZE(CAMERA_VSIZE),
	.PIXEL_SIZE(12),
	.BUF_ADDR_WIDTH(32)
) rgb_mean_u1 (
	.clk(clk),
	.rst_n(rst_n),
	.cam_frame_valid(cam_frame_valid),
	.cam_line_valid(cam_line_valid),
	.cam_pixel_clk(cam_pixel_clk),
	.cam_pixel_rgb(cam_pixel_rgb),
	.pixel_mean(pixel_mean),
	.buf_waddr(buf_waddr),
	.buf_wvalid(buf_wvalid),
	.buf_wready(buf_wready),
	.sad_done(sad_done)
);

endmodule
