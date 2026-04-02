`timescale 1ns/1ns
/* *******************************************************************
 * Generate RGB color for pixel at position (pixX,pixY).
 * RGB data must be ready and stable in 1 clock cycle (!)
*/
module gen_video(
  input wire I_clk_pixel,
  input wire I_reset_n,
  input wire Pal50,
  // VDG modes
  input wire AG, CSS,
  // Pixel Coordinates requested by HDMI pulling
  input wire [9:0] pixX,
  input wire [9:0] pixY,
  // Interface to fetching system VRAM
  output wire [12:0] vram_addr,
  input wire [7:0] vram_data,
  // RGB24 output to HDMI 
  output wire [23:0] rgb
);

// *********************************************************************
// Line buffer updated by VDG
// - Left border: 
//   for HDMI extented left 0 <= pixX < 40 (720 - 640 = 80, half of that is 40) 
//   for VDG left border 40 <= pixX < 104 (40 + 64 = 104) <== (640 - 512 = 128, half of that is 64)
// - Right border:
//   for HDMI extented right 680 <= pixX < 720 (720 - 640 = 80, half of that is 40) 
//   for VDG right border 616 <= pixX < 680 (616 + 64 = 680) <== (640 - 512 = 128, half of that is 64)
// - Line data: for HDMI 104 <= pixX < 616 but stored 1 cell for 2 HDMI pixels
//   Need buffer for 2 lines since VDG generates line in 64us but HDMI needs it in 32us. 
//   So VDG generates line N in buffer A while HDMI renders line N-2 and line N-1 from buffer B.
// *********************************************************************
localparam [23:0] COLOR_BLACK 	= 24'h000000;
localparam [23:0] COLOR_DKGREEN =  {8'd9, 8'd61,8'd1};
localparam [23:0] COLOR_DKORANGE = {8'd79,8'd41,8'd12};

localparam [23:0] COLOR_GREEN 	=  {8'd27, 8'd184,8'd4};
localparam [23:0] COLOR_YELLOW 	=  {8'd147,8'd169,8'd35};
localparam [23:0] COLOR_BLUE 	=  {8'd89, 8'd67, 8'd202};
localparam [23:0] COLOR_RED 	=  {8'd178,8'd43, 8'd89};
localparam [23:0] COLOR_BUFF 	=  {8'd147,8'd147,8'd147};
localparam [23:0] COLOR_CYAN 	=  {8'd27, 8'd162,8'd117};
localparam [23:0] COLOR_MAGENTA	=  {8'd206,8'd49, 8'd230};
localparam [23:0] COLOR_ORANGE	=  {8'd237,8'd124,8'd35};

// Reading from PALETTE must take 1 clock (since is is setable by CPU later)
reg [23:0] PALETTE[0:15];
initial begin
	// 8 Standard Gfx colors: 
	// Gfx: {luma=1,CSS,pxbits[1:0]}
	// Txt: {luma=1,CSS,CSS,CSS}
	// Semi4: {luma=1,pxbits[6:4]}
	// Semi6: {luma=1,CSS,pxbits[7:6]}
	PALETTE[8] = COLOR_GREEN;		// CSS=0, Color=00, TXT: Foreground
	PALETTE[9] = COLOR_YELLOW;		// CSS=0, Color=01
	PALETTE[10] = COLOR_BLUE;		// CSS=0, Color=10
	PALETTE[11] = COLOR_RED;		// CSS=0, Color=11
	PALETTE[12] = COLOR_BUFF;		// CSS=1, Color=00
	PALETTE[13] = COLOR_CYAN;		// CSS=1, Color=01
	PALETTE[14] = COLOR_MAGENTA;	// CSS=1, Color=10
	PALETTE[15] = COLOR_ORANGE;		// CSS=1, Color=11, TXT: Foreground
	// Extra colors for BackGrounds, Borders
	PALETTE[0] = COLOR_DKGREEN;		// CSS=0, SEMI=0 TXT: Background {luma=0, CSS=0, AG=0, SEMI=0}
	PALETTE[1] = COLOR_BLACK;		// CSS=0, SEMI=1 SEMI: Background {luma=0, CSS=0, AG=0, SEMI=1}
	PALETTE[2] = COLOR_BLACK;		// CSS=0, PixOn=0 Gfx: Background {luma=0, CSS=0, AG=1, PixOn=0}
	PALETTE[3] = COLOR_GREEN;		// CSS=0, PixOn=1 Gfx: Foreground {luma=0, CSS=0, AG=1, PixOn=1}
	PALETTE[4] = COLOR_DKORANGE;	// CSS=1, SEMI=0 TXT: Background {luma=0, CSS=1, AG=0, SEMI=0}
	PALETTE[5] = COLOR_BLACK;		// CSS=1, SEMI=1 SEMI: Background {luma=0, CSS=1, AG=0, SEMI=1}
	PALETTE[6] = COLOR_BLACK;		// CSS=1, PixOn=0 Gfx: Background {luma=0, CSS=1, AG=1, PixOn=0}
	PALETTE[7] = COLOR_BUFF;		// CSS=1, PixOn=1 Gfx: Foreground {luma=0, CSS=1, AG=1, PixOn=1}
end

// **********************************************************************
// Liner buffer
// **********************************************************************
reg [23:0] LINEBUF [511:0]; // 256 pixels per line, 2 lines 

wire lbuf_wr_sel = !pixY[1];  // alias
wire lbuf_rd_sel = pixY[1];   // alias

// read index to line buffer is (pixX - 104) / 2 since line buffer has 1 cell for 2 HDMI pixels
wire [7:0] lbuf_rd_addr = {pixY[1], 9'(pixX - 'd104) >> 1};

// write index to line buffer
reg [7:0] lbuf_wr_idx;
always@(posedge I_clk_pixel, negedge I_reset_n) begin
  if (!I_reset_n)
    lbuf_wr_idx <= 'd0;
  else if (pixX[1:0] == 2'b00) begin
	lbuf_wr_idx <= lbuf_wr_idx + 1'b1;
  end
end


// **********************************************************************
// VDG timings:
// **********************************************************************


localparam HS_START = 612, HS_LEN = 124;
localparam AG_FETCH = 4; // HS_START+HS_LEN+222 % 864
localparam FIRST_FETCH = AG_FETCH+4;
localparam LAST_FETCH = 600;
reg HS;
always@(posedge I_clk_pixel, negedge I_reset_n) begin
  if (!I_reset_n)
    HS <= 1'd0;
  else if (pixY[0] == 1'b1 && pixX == HS_START) 
	HS <= 1'b1;
  else if (pixY[0] == 1'b1 && pixX == HS_START+HS_LEN) 
	HS <= 1'b0;
end

// --------- FETCH BORDER (AG+CSS) ------------
// Border color is updated when VDG starts creating line and fetches 32th display block (just after disp area)
// AG mode is fetched only once when VDG line starts
// CSS (for border) is fetched once when VDG line starts and when VDG fetches last display block (or after)
reg [1:0] LINEAG;
reg [3:0] BORDERIDX[0:1];
always@(posedge I_clk_pixel or negedge I_reset_n) begin
	if (!I_reset_n) begin
		LINEAG <= {AG,AG};
		BORDERIDX[0] <= {1'b0, CSS, AG, 1'b1};
		BORDERIDX[1] <= {1'b0, CSS, AG, 1'b1};
	end else begin
		if (pixY[0] == 1'b0 && pixX == AG_FETCH) begin
			LINEAG[lbuf_wr_sel] <= AG;
			BORDERIDX[lbuf_wr_sel] <= {1'b0, CSS, AG, 1'b1};
		end else if (pixY[0] == 1'b1 && pixX == LAST_FETCH) begin
			BORDERIDX[lbuf_wr_sel] <= {1'b0, CSS, LINEAG[lbuf_wr_sel], 1'b1};
		end
	end
end
wire [23:0] BORDERRGB = PALETTE[BORDERIDX[lbuf_rd_sel]];

reg renderBorder; 
always@(*) begin
	if (Pal50) begin
		renderBorder = pixY < 'd96 || pixY > 'd479 || pixX < 'd104 || pixX > 'd615;
	end else begin
		renderBorder = pixY < 'd48 || pixY > 'd431 || pixX < 'd104 || pixX > 'd615;
	end
end

reg fetchLines;
always@(*) begin
	if (Pal50) begin
		fetchLines = pixY >= 'd94 && pixY < 'd478;
	end else begin
		fetchLines = pixY >= 'd46 && pixY < 'd430;
	end
end

reg [4:0] vdg_clk_div = 0;
reg [4:0] vram_addr_lo = 0;
always@( posedge I_clk_pixel or negedge I_reset_n ) begin
	if (!I_reset_n) begin
		vdg_clk_div <= 'd0;
		vram_addr_lo <= 'd0;
	end else if (!fetchLines) begin
		vdg_clk_div <= 'd0;
		vram_addr_lo <= 'd0;
	end else if (pixY[0] == 1'b0 && pixX == FIRST_FETCH) begin
		vdg_clk_div <= 'd0;		
		vram_addr_lo <= 'd0;
	end else if (vdg_clk_div == 'd29) begin
		vdg_clk_div <= 'd0;
		vram_addr_lo <= vram_addr_lo + 1'b1;
	end else begin
		vdg_clk_div <= vdg_clk_div + 1'b1;
	end
end



// index to 1 of 2 line buffers, we can use pixY[1] since we are doubling lines too

reg [23:0] RGBOUT = 24'd0;

// -----------------------------------------------------------------------
// Video rendering by HDMI - RGB must be ready before next rising edge (!)
// -----------------------------------------------------------------------

always@(posedge I_clk_pixel, negedge I_reset_n) begin
  if (!I_reset_n)
    RGBOUT <= 24'd0;
  else if (renderBorder) begin
    RGBOUT <= BORDERRGB;
  end else begin
    RGBOUT <= LINEBUF[lbuf_rd_addr];// Pal50 ? 24'h008000 : 24'h0000ff; 
  end
end

assign rgb = RGBOUT;



reg [12:0] fetch_addr;
reg [7:0] fetch_data;

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

