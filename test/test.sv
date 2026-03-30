`timescale 1ns/1ns

module test_tb;

initial begin
	$dumpfile("test.vcd");
	$dumpvars(0);
end
bit clk_27 = 1'b0;
bit clk_7 = 1'b0;
bit rst_n = 1'b1;

wire [23:0] RGB;

// Clock 27 MHz
always begin
	#19 clk_27 = 1'b1;
	#18 clk_27 = 1'b0;
end

// Clock 7,159 MHz
always begin
	#70 clk_7 = 1'b1;
	#69 clk_7 = 1'b0;
end

// HDMI timings
bit [9:0] pixX,pixY;

always_ff @(  posedge clk_27 or negedge rst_n ) begin : HDMI_counters
	if (!rst_n) begin
		pixX <= 'd0;
		pixY <= 'd0;
	end else begin
		if (pixX == 'd857) begin
			pixX <= 'd0;
			pixY <= (pixY == 524) ? 'd0 : pixY + 1'b1;
		end else begin
			pixX <= pixX + 1'b1;
		end
	end
end
// *******************************************************
// I/O Pins
bit INT = 0;	// INT_n as output
bit AG = 1'b0, AS = 1'b0, CSS = 1'b0, INV = 1'b0, INTEXT = 1'b0;
bit [2:0] GM = 3'b000;

reg [7:0] VRAM[0:6*1024-1];
initial begin
	$readmemh("vramRG6.hex", VRAM);
end
wire [12:0] vram_addr;
wire [7:0] vram_data;
assign vram_data = VRAM[vram_addr];

gen_video renderer(
  .I_clk_pixel(clk_27), .I_reset_n(rst_n),
  .Pal50(1'b0),
  .pixX(pixX), .pixY(pixY),
  .vram_addr(vram_addr), .vram_data(vram_data),
  .rgb(RGB)
);

/*
// *******************************************************
// Double Line buffer
// *******************************************************

bit [7:0] LB[0:1] = {8'h55,8'h66};
bit [7:0] RB[0:1] = {8'h55,8'h66};
bit [7:0] DATA[0:255][0:1];
initial begin
	integer i;
	for (i = 0; i < 256; i = i + 1) begin
		DATA[i][0] = 8'haa; 
		DATA[i][1] = 8'h88; 
	end
end

// HDMI Rendering (pool)
bit [9:0] hdmi_x = 'd852, hdmi_y = 'd524;

// [0] HDMI renders from buffer 0 while generating data and writes to buffer 1
//     While renders lines 0 and 1 generates data for lines 2 and 3 
//     so for lines 0 and 1 we should start generate data when hdmi_y == 522 but...
//     Lines 0..47 for NTSC60 and 0..95 for PAL50 are Top Border so we only need
//     to read AG and CSS and update LB register.
//     The same applies to lines 432...479 for NTSC60 and 480..575 for PAL50
//     Conclusion: First rendered with data line (end of top border) is line 48 (NTSC60) or 96 (PAL50)
//     Lines (y):
//     0..45 (NTSC), 0..93 (PAL): 
//        Renderer reads LB and draws whole line (fills with left border color)
//        Generator reads AG,CSS and set LB for y+2 only if y is odd
//     46,47 (NTSC), 94,95 (PAL):
//        Renderer reads LB and draws whole line (fills with left border color)
//        Generator fetches data and generates 1 line duplicated later as 48 and 49
//     48..429 (NTSC), 96..477 (PAL):
//        Renderer reads DATA and draw whole line (twice the same)
//        Generator fetches data and generates 1 line duplicated later as 48 and 49
//     430,431 (NTSC), 478,479 (PAL):
//        Renderer reads DATA and draw whole line (twice the same)
//        Generator reads AG,CSS and set LB for y+2 only if y is odd
//     430..477 (NTSC), 480..573 (PAL): 
//        Renderer reads LB and draws whole line (fills with left border color)
//        Generator reads AG,CSS and set LB for y+2 only if y is odd
//     478,479 (NTSC), 573,574 (PAL): 
//        Renderer reads LB and draws whole line (fills with left border color)
//        Generator does nothing
//     480..522 (NTSC), 575..622 (PAL): 
//        Renderer does nothing
//        Generator does nothing
//     523,524 (NTSC), 623,624 (PAL): 
//        Renderer does nothing
//        Generator reads AG,CSS and set LB for y+2 only if y is odd
// [1] When (x,y) == (0,0) LB[0] must be alredy determined so
//     we have to read AG and CSS 1 clock before:
//     - NTSC60 - x == 857, y == 524
//     - PAL50  - x == 863, y == 624
wire f_frame_last_tick = (hdmi_x == 'd852 && hdmi_y == 'd524) ? 1'b1 : 1'b0;
// [2] When x == 0 and even line (0,2,4,6,...) LB[0] must be already determined so
//     we have to read AG and CSS 1 clock before (in previous/odd line)
//     - NTSC60 - x == 857, y[0] == 1
//     - PAL50  - x == 863, y[0] == 1
wire f_prev_line_last_tick = (hdmi_x == 'd852 && hdmi_y[0] == 1'b1) ? 1'b1 : 1'b0;

// Fetch AG & CSS & GM for left border area and update LBREG[0]
wire hdmi_fetch_AG_0 = hdmi_x == 'd857 && (hdmi_y == 'd524 || hdmi_y[1:0] == 2'b11);
wire hdmi_fetch_AG_1 = hdmi_x == 'd857 && hdmi_y[1:0] == 2'b01;
// HDMI draws left Extra Pan border (208 px) and vdg left border () from LBREG[0] or LBREG[1]
wire hdmi_draw_LB_0 = (hdmi_x < 'd104 && hdmi_y[1] == 1'b0) ? 1'b1 : 1'b0;
wire hdmi_draw_LB_1 = (hdmi_x < 'd104 && hdmi_y[1] == 1'b1) ? 1'b1 : 1'b0;
// HDMI draws pixels only when 104 <= x < 104 + 512 (616)
wire hdmi_draw_buf_0 = (hdmi_x >= 'd104 && hdmi_x < 'd616 & hdmi_y[1] == 1'b0) ? 1'b1 : 1'b0;
wire hdmi_draw_buf_1 = (hdmi_x >= 'd104 && hdmi_x < 'd616 & hdmi_y[1] == 1'b1) ? 1'b1 : 1'b0;
bit [8:0] fetch_addr = 0;
always_ff @( posedge clk_27 ) begin
	if (hdmi_x < 'd104 || hdmi_x > 'd616)
		fetch_addr <= 'd0;
	else 
		fetch_addr <= fetch_addr + 1'b1;
end
wire [7:0] hdmi_fetch_buf_0 = (hdmi_x >= 'd104 && hdmi_x < 'd616 && hdmi_y[1] == 1'b0)  ? fetch_addr[8:1] : 'd0;
wire [7:0] hdmi_fetch_buf_1 = (hdmi_x >= 'd104 && hdmi_x < 'd616 && hdmi_y[1] == 1'b1)  ? fetch_addr[8:1] : 'd0;
// 
wire hdmi_fetch_RB_0 = (hdmi_fetch_buf_0 == 'd255 && hdmi_x[0] == 1'b1) ? 1'b1 : 1'b0;
wire hdmi_fetch_RB_1 = (hdmi_fetch_buf_1 == 'd255 && hdmi_x[0] == 1'b1) ? 1'b1 : 1'b0;
// HDMI draws left Extra Pan border (208 px) and vdg left border () from LBREG[0] or LBREG[1]
wire hdmi_draw_RB_0 = (hdmi_x >= 'd616 && hdmi_x < 'd720 && hdmi_y[1] == 1'b0) ? 1'b1 : 1'b0;
wire hdmi_draw_RB_1 = (hdmi_x >= 'd616 && hdmi_x < 'd720 && hdmi_y[1] == 1'b1) ? 1'b1 : 1'b0;

always_ff@(posedge clk_27 or negedge rst_n) begin
	if (!rst_n) begin
		hdmi_x <= 0;
		hdmi_y <= 0;
	end else begin
		if (hdmi_x == 'd857) begin
			hdmi_x <= 'd0;
			hdmi_y <= (hdmi_y == 524) ? 'd0 : hdmi_y + 1'b1;
		end else begin
			hdmi_x <= hdmi_x + 1'b1;
		end
	end
end

// VDG Generating (push)
bit [9:0] vdg_x, vdg_y;
bit [8:0] fetch_counter;

// Reset VDG generator when HDMI end of frame (min 4 hdmi clocks before to be ready for top-left pixel (0,0))
wire restart_vdg = (hdmi_y == 'd524 && hdmi_x > 'd853) ? 1'b1 : 1'b0;
// Start of line: 
// HS 4,9us = 17,5 x 1/f = 35 dot clock
wire HS = vdg_x < 'd35 ? 1'b1 : 1'b0;
// Left Border = 29 x 1/f = 58 doc clock 
wire LBORDER = vdg_x >= 'd35 && vdg_x < ('d35 + 'd58) ? 1'b1 : 1'b0;
wire vdg_DE = vdg_x >= ('d35 + 'd58) && vdg_x < ('d35 + 'd58 + 'd256) ? 1'b1 : 1'b0;

wire fetch_pulse_short = (vdg_DE == 1'b1 && fetch_counter[2:0] == 3'b001) ? 1'b1 : 1'b0;
wire fetch_pulse_long = (vdg_DE == 1'b1 && fetch_counter[3:0] == 4'b0001) ? 1'b1 : 1'b0;
wire [4:0] fetch_addr_lo_short = fetch_counter[7:3];
wire [3:0] fetch_addr_lo_long = fetch_counter[7:4];

always_ff@(posedge clk_7 or negedge rst_n) begin
	if (!rst_n || restart_vdg) begin
		vdg_x <= 0;
		vdg_y <= 0;
		fetch_counter <= 0;
	end else begin
		if (vdg_x == 'd455) begin
			vdg_x <= 'd0;
			vdg_y <= (vdg_y == 524) ? 'd0 : vdg_y + 1'b1;
		end else begin
			vdg_x <= vdg_x + 1'b1;
		end
		if (vdg_DE) fetch_counter <= fetch_counter + 1'b1;
		else fetch_counter <= 'd0;
	end
end
bit [7:0] ColorOut;
always_ff @( posedge clk_27 ) begin : bartrender
	if (hdmi_draw_LB_0) begin
		ColorOut <= LB[0];
	end else if (hdmi_draw_LB_1) begin
		ColorOut <= LB[1];
	end else if (hdmi_draw_buf_0) begin
		ColorOut <= DATA[hdmi_fetch_buf_0][0];
	end else if (hdmi_draw_buf_1) begin
		ColorOut <= DATA[hdmi_fetch_buf_1][1];
	end else if (hdmi_draw_RB_0) begin
		ColorOut <= RB[0];
	end else if (hdmi_draw_RB_1) begin
		ColorOut <= RB[1];
	end else begin
		ColorOut <= 'd0;
	end
end
*/

initial begin
	clk_27 = 0;
	clk_7 = 0;
	rst_n = 0;
	#100 rst_n = 1'b1;

	#20_000_000;
	$finish;
end

endmodule
