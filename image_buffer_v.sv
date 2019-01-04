`timescale 1ns/1ns

module image_buffer_v;

// parameter
parameter integer CAMERA_HSIZE = 100;
parameter integer CAMERA_VSIZE = 100;
parameter integer BUF_ADDR_WIDTH = log2(CAMERA_HSIZE*CAMERA_VSIZE);
parameter integer PIXEL_SIZE = 12; 

function integer log2(integer x);
	for (log2 = 0; x > 0; log2++) 
		x >>= 1;
endfunction

reg clk, rst_n;
reg [BUF_ADDR_WIDTH-1:0] buf_raddr, buf_waddr;
reg buf_wvalid, buf_rvalid;
reg [PIXEL_SIZE-1:0] buf_wdata;

wire buf_rready, buf_wready;
wire [PIXEL_SIZE-1:0] buf_rdata;

image_buffer #(
	.CAMERA_HSIZE(CAMERA_HSIZE),
	.CAMERA_VSIZE(CAMERA_VSIZE),
	.BUF_ADDR_WIDTH(BUF_ADDR_WIDTH),
	.PIXEL_SIZE(PIXEL_SIZE)
) u1 (
	.clk(clk),
	.rst_n(rst_n),
	.buf_raddr(buf_raddr),
	.buf_rvalid(buf_rvalid),
	.buf_rready(buf_rready),
	.buf_rdata(buf_rdata),
	.buf_waddr(buf_waddr),
	.buf_wvalid(buf_wvalid),
	.buf_wready(buf_wready),
	.buf_wdata(buf_wdata)
);

initial begin
	clk = 0;
	rst_n = 0;
	buf_raddr = 0;
	buf_waddr = 0;
	buf_wvalid = 0;
	buf_rvalid = 0;
	#1
	rst_n = 1;
end

always #50 clk <= ~clk;

bit [BUF_ADDR_WIDTH-1:0] addr;
bit [PIXEL_SIZE-1:0] data;
event gen_addr_data, end_write;

always @(gen_addr_data) begin
	addr = $random%(CAMERA_HSIZE*CAMERA_VSIZE);
	data = $random%12'hfff;
end

always @(posedge clk) begin
	#10
	->gen_addr_data;
	#1
	buf_waddr = addr;
	buf_wdata = data;
	buf_wvalid = 1;
	#100
	->end_write;
	buf_wvalid = 0;
end

bit right;
always @(end_write) begin
	buf_rvalid = 1;
	buf_raddr = addr;
	right = (buf_rdata == data) ? 1 : 0;
end



endmodule
