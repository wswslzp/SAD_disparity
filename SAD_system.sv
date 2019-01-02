`timescale 1ns/1ns 

module SAD_system #(
	parameter integer CAMERA_HSIZE = 300,
	parameter integer CAMERA_VSIZE = 300,
	parameter integer PIXEL_SIZE	 = 12,
	parameter integer VGA_ADDR_WIDTH = 19
(
	//physical pin
	input wire clk,
	input wire rst_n,

	// outside device pin
	// input device 
	input wire cam1_frame_valid,
	input wire cam1_line_valid,
	input wire cam1_pixel_clk,
	input wire [PIXEL_SIZE-1:0] cam1_pixel_rgb,
	input wire cam2_frame_valid,
	input wire cam2_line_valid,
	input wire cam2_pixel_clk,
	input wire [PIXEL_SIZE-1:0] cam2_pixel_rgb,

	// output device

);
/* ------------------ local parameter-----------------*/
localparam integer PIXEL_CHANNEL_SIZE = PIXEL_SIZE/3;
localparam integer MEAN_SIZE = PIXEL_CHANNEL_SIZE;
localparam integer BUF_ADDR_WIDTH = (CAMERA_HSIZE*CAMERA_VSIZE*PIXEL_SIZE)/ MEAN_SIZE;

/*------------------- sub-module intantiation ---------*/

// Instantiation of RGB mean value module for two camera
wire [BUF_ADDR_WIDTH-1:0] buf1_waddr, buf2_waddr;
wire buf1_wready, buf2_wready;
wire buf1_wvalid, buf2_wvalid;
wire sad_done;
wire [PIXEL_CHANNEL_SIZE-1:0] pixel_mean1, pixel_mean2;

rgb_mean #(
	.CAMERA_HSIZE(CAMERA_HSIZE),
	.CAMERA_VSIZE(CAMERA_VSIZE),
	.PIXEL_SIZE(PIXEL_SIZE),
	.MEAN_SIZE(MEAN_SIZE),
	.BUF_ADDR_WIDTH(BUF_ADDR_WIDTH)
) rgb_mean_u1 (
	.clk(clk), // system clock
	.rst_n(rst_n), // system reset
	.cam_frame_valid(cam1_frame_valid), // camera1 frame valid
	.cam_line_valid(cam1_line_valid), // camera1 line valid
	.cam_pixel_clk(cam1_pixel_clk), // camera1 pixel clock, fall side valid
	.cam_pixel_rgb(cam1_pixel_data), // input pixel RGB channel
	.pixel_mean(pixel_mean1), // output pixel RGB mean value
	.buf_waddr(buf1_waddr), // buffer write address
	.buf_wvalid(buf1_wvalid), // buffer write valid signal
	.buf_wready(buf1_wready), // buffer write ready signal
	.sad_done(sad_done) // the signal indicates that sad module consume out of the buffer data
);

rgb_mean #(
	.CAMERA_HSIZE(CAMERA_HSIZE),
	.CAMERA_VSIZE(CAMERA_VSIZE),
	.PIXEL_SIZE(PIXEL_SIZE)
) rgb_mean_u2 (
	.clk(clk), // system clock
	.rst_n(rst_n), // system reset
	.cam_frame_valid(cam2_frame_valid), // camera2 frame valid
	.cam_line_valid(cam2_line_valid), // camera2 line valid
	.cam_pixel_clk(cam2_pixel_clk), // camera1 pixel clock, fall side valid
	.cam_pixel_rgb(cam2_pixel_data), // input pixel RGB channel
	.pixel_mean(pixel_mean2), // output pixel RGB mean value
	.buf_waddr(buf2_waddr), // buffer write address
	.buf_wvalid(buf2_wvalid), // write valid signal
	.buf_wready(buf2_wready), // write ready signal
	.sad_done(sad_done) // sad module consume out of the buffer data
);

// Instantiation of buffer1,buffer2
wire buf1_rready, buf2_rready;
wire buf1_rvalid, buf2_rvalid;
wire [BUF_ADDR_WIDTH-1:0] buf1_raddr, buf2_raddr;
wire [MEAN_SIZE-1:0] img_pix_1, img_pix_2;

image_buffer #(						// input buffer 1	
	.CAMERA_HSIZE(CAMERA_HSIZE),
	.CAMERA_VSIZE(CAMERA_VSIZE),
	.PIXEL_SIZE(PIXEL_SIZE),
	.BUF_ADDR_WIDTH(BUF_ADDR_WIDTH)
) image_buffer_u1 (
	.clk(clk),
	.rst_n(rst_n),
	.buf_waddr(buf1_waddr),
	.buf_wready(buf1_wready),
	.buf_wvalid(buf1_wvalid),
	.buf_wdata(pixel_mean1),
	.buf_raddr(buf1_raddr),
	.buf_rvalid(buf1_rvalid),
	.buf_rready(buf1_rready),
	.buf_rdata(img_pix_1),
);

image_buffer #(						// input buffer 2
	.CAMERA_HSIZE(CAMERA_HSIZE),
	.CAMERA_VSIZE(CAMERA_VSIZE),
	.PIXEL_SIZE(PIXEL_SIZE),
	.BUF_ADDR_WIDTH(BUF_ADDR_WIDTH)
) image_buffer_u2 (
	.clk(clk),
	.rst_n(rst_n),
	.buf_waddr(buf2_waddr),
	.buf_wready(buf2_wready),
	.buf_wvalid(buf2_wvalid),
	.buf_wdata(pixel_mean2),
	.buf_raddr(buf2_raddr),
	.buf_rvalid(buf2_rvalid),
	.buf_rready(buf2_rready),
	.buf_rdata(img_pix_2),
);

// Instantiation of SAD module
wire [MEAN_SIZE-1:0] sad_result;

SAD #(
	.CAMERA_HSIZE(CAMERA_HSIZE),
	.CAMERA_VSIZE(CAMERA_VSIZE),
	.PIXEL_SIZE(PIXEL_SIZE),
	.MEAN_SIZE(MEAN_SIZE),
	.BUF_ADDR_WIDTH(BUF_ADDR_WIDTH),
	.BLOCK_SIZE(BLOCK_SIZE)
) sad_u (
	.clk(clk),
	.rst_n(rst_n),
	.buf1_raddr(buf1_raddr),
	.buf1_rvalid(buf1_rvalid),
	.buf1_rready(buf1_rready),
	.buf1_rdata(img_pix_1),
	.buf2_raddr(buf2_raddr),
	.buf2_rvalid(buf2_rvalid),
	.buf2_rready(buf2_rready),
	.buf2_rdata(img_pix_2),
	.sad_result(sad_result),
	.sad_done(sad_done)
);

// Instantiation of VGA display buffer
wire vga_en;
wire [PIXEL_SIZE-1:0] vga_wdata;
wire [VGA_ADDR_WIDTH-1:0] vga_waddr;

VGA_buffer #(
	.DISPLAY_WIDTH(CAMERA_HSIZE),
	.DISPLAY_HEIGHT(CAMERA_VSIZE),
) vga_u (
	.clk(clk),
	.rst_n(rst_n),
	.vga_en(vga_en),
	.vga_waddr(vga_waddr),
	.vga_raddr(),
	.vga_wdata(vga_wdata),
	.vga_rdata()
);

endmodule
