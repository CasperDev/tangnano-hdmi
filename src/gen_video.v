import configPackage::*;
/* *******************************************************************
 * Generate RGB color for pixel at position (pixX,pixY).
 * RGB data must be ready and stable in 1 clock cycle (!)
*/
module gen_video(
  input wire I_clk_pixel,
  input wire I_reset_n,
  input [VIDEO_X_BITWIDTH-1:0] pixX,
  input [VIDEO_Y_BITWIDTH-1:0] pixY,
  input [VIDEO_X_BITWIDTH-1:0] screenWidth,
  input [VIDEO_Y_BITWIDTH-1:0] screenHeight,
  output wire [23:0] rgb
);

wire border = (pixX == 'd0) || (pixX == screenWidth-1'b1) || (pixY == 'd0) || (pixY == screenHeight-1'b1)  ? 1'b1 : 1'b0; 
reg [23:0] rgb_r = 24'd0;

// Video generation
always@(posedge I_clk_pixel, negedge I_reset_n) begin
  if (!I_reset_n)
    rgb_r <= 24'd0;
  else if (border) begin
    rgb_r <= 24'h0000ff;
  end else begin
    rgb_r <= 24'hffc0cb; // Pink of course :)
  end
end

assign rgb = rgb_r;

endmodule

