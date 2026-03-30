`timescale 1ns/1ns
/* *******************************************************************
 * Generate RGB color for pixel at position (pixX,pixY).
 * RGB data must be ready and stable in 1 clock cycle (!)
*/
module gen_video(
  input wire I_clk_pixel,
  input wire I_reset_n,
  input wire Pal50,
  input wire [9:0] pixX,
  input wire [9:0] pixY,
  output wire [12:0] vram_addr,
  input wire [7:0] vram_data,
  output wire [23:0] rgb
);

// *********************************************************************
// Line buffer updated by VDG
// - Left border: 
//   for HDMI extented left 0 <= pixX < 40 (720 - 640 = 80, half of that is 40) 
//   and for VDG left border 40 <= pixX < 104 (40 + 64 = 104) <== (640 - 512 = 128, half of that is 64)
// - Right border:
//   for HDMI extented right 680 <= pixX < 720 (720 - 640 = 80, half of that is 40) 
//   and for VDG right border 616 <= pixX < 680 (616 + 64 = 680) <== (640 - 512 = 128, half of that is 64)
// - Line data: for HDMI 104 <= pixX < 616 but stored 1 cell for 2 HDMI pixels
//   Need buffer for 2 lines since VDG generates line in 64us but HDMI needs it in 32us. 
//   So we can generate line N in buffer A while sending line N-1 from buffer B.
// *********************************************************************
localparam [23:0] COLOR_BLACK = 24'h000000;
localparam [23:0] COLOR_GREEN = 24'h00e000;
localparam [23:0] COLOR_BUFF =  24'he0e0e0;

logic [23:0] line_buffer [255:0][0:1]; // 256 pixels per line, 2 lines 
logic [23:0] left_border_color[0:1] = { COLOR_GREEN, COLOR_GREEN }; // Dark Green (almost Black)
logic [23:0] right_border_color[0:1] = { COLOR_GREEN, COLOR_GREEN }; 

wire lborder = (pixX < 'd104);
wire rborder = (pixX >= 'd616);

// Vertical position management
wire top_border = (pixY < (Pal50 ? 'd96 : 'd48)); // 96 for 576p, 48 for 480p
wire bottom_border = (pixY > (Pal50 ? 'd480 : 'd432)); // 96 for 576p, 48 for 480p
// combinational logic to determine if we're in the active video area (not in border)
// index to line buffer is (pixX - 104) / 2 since line buffer is 1 cell for 2 HDMI pixels
wire [7:0] line_buffer_index = 9'(pixX - 'd104) >> 1;
// index to 1 of 2 line buffers, we can use pixY[1] since we are doubling lines too
wire line_buffer_selector = pixY[1];

reg [23:0] rgb_r = 24'd0;
// Video rendering by HDMI
always@(posedge I_clk_pixel, negedge I_reset_n) begin
  if (!I_reset_n)
    rgb_r <= 24'd0;
  else if (lborder || top_border || bottom_border) begin
    rgb_r <= left_border_color[line_buffer_selector];
  end else if (rborder) begin
	rgb_r <= right_border_color[line_buffer_selector];
  end else begin
    rgb_r <= line_buffer[line_buffer_index][line_buffer_selector];// Pal50 ? 24'h008000 : 24'h0000ff; 
  end
end

assign rgb = rgb_r;

// **********************************************************************
// VDG timings:
wire vdg_de = !(lborder || top_border || bottom_border || rborder);

reg [12:0] fetch_addr;
reg [7:0] fetch_data;

reg [6:0] clk_div = 0;
always_ff @( posedge I_clk_pixel or negedge I_reset_n ) begin
	if (!I_reset_n)
		clk_div <= 'd0;		
	else if (clk_div == 'd30) begin
		clk_div <= 'd0;
	end else if (vdg_de)
		clk_div <= clk_div + 1'b1;
end

wire fetch_pulse = clk_div == 'd1;
always_ff @( posedge I_clk_pixel or negedge I_reset_n ) begin
	if (!I_reset_n) begin
		fetch_addr <= 'd0;
		fetch_data <= 'd0;
	end else if (fetch_pulse) begin
		fetch_data <= vram_data;
		fetch_addr <= fetch_addr + 1'b1;
	end
end
assign vram_addr = fetch_addr;
/*
// 1] AG mode is read only once per VDG line (2 HDMI lines) and must be ready by the end of the line
//    pixX == 857 and pixY[0] == 1 (last pixel of line) ready for next line
// 2] CSS mode is read once when AG (for left border)
//    pixX == 857 and pixY[0] == 1 (last pixel of line) ready for next line
//   per every VRAM byte fetch ...
//   once before Right border starts (extra fetch)
//    pixX ==  
// VDG writes to line buffer, 4 pixels at once (short cycle) or 8 pixels (long cycle)
// **********************************************************************
wire VdgAG = 1'b1; // Alphanumeric/Graphics mode // TODO: support text mode
wire VdgCSS = 1'b0; // Palete Color Selector // TODO: support text mode
// VDG writes data of line to opposite buffer of the one being read by HDMI, 
// so we can use pixY[1] to select which line buffer to write to.
wire vdg_line_buffer_selector = ~pixY[1];

reg LineAG_R, VdgCSS_R; // Registered version of VdgAG and VdgCSS
// AG mode is read only once per line and must be ready by the end of the line
always_ff@(posedge I_clk_pixel or negedge I_reset_n) begin
	if (!I_reset_n) begin
		LineAG_R <= 1'b0;
		left_border_color[0] <= COLOR_BLACK;
		left_border_color[1] <= COLOR_BLACK;
	end else if (pixX == 'd857 && pixY[0] == 1'b1)begin // last pixel of even line
		LineAG_R <= VdgAG; 
		left_border_color[vdg_line_buffer_selector] <= (VdgAG == 1'b0 ? COLOR_BLACK : (VdgCSS == 1'b0 ? COLOR_GREEN : COLOR_BUFF));
	end
end  

// LEft border color depends on CSS and AG mode:
// - 
// Left border is determined always before pixX = 0, so we can use time
// when pixX = last pixel of full line. Should be 863 for PAL50 and 857 for NTSC60
// but it doesnt really matter for timing
// always_ff @(posedge I_clk_pixel) begin
// 	if (pixX == 'd857) begin
// 		left_border_color[vdg_line_buffer_selector] <= (Pal50 ? 24'h008000 : 24'h0000ff); // Green for PAL50, Blue for NTSC60
// 	end
// end

// in order to have line 0 ready in buffer when pixY and pixX = 0, 
// VDG needs to write Left Borderit's line N to buffer when pixY is N-1. So we can use pixY as index to select which line buffer to write to.

*/
endmodule

