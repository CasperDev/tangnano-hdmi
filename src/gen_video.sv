import configPackage::*;
/* *******************************************************************
 * Generate RGB color for pixel at position (pixX,pixY).
 * RGB data must be ready and stable in 1 clock cycle (!)
*/
module gen_video(
  input wire I_clk_pixel,
  input wire I_reset_n,
  input wire Pal50,
  input [9:0] pixX,
  input [9:0] pixY,
  input [9:0] screenWidth,
  input [9:0] screenHeight,
  output wire [23:0] rgb
);

wire border = (pixX == 'd0) || (pixX == screenWidth-1'b1) || (pixY == 'd0) || (pixY == screenHeight-1'b1)  ? 1'b1 : 1'b0; 
reg [23:0] rgb_r = 24'd0;

// Video generation
always@(posedge I_clk_pixel, negedge I_reset_n) begin
  if (!I_reset_n)
    rgb_r <= 24'd0;
  else if (border) begin
    rgb_r <= 24'hffffff;
  end else begin
    rgb_r <= Pal50 ? 24'h008000 : 24'hff0000; // Pink of course :)
  end
end

assign rgb = rgb_r;

endmodule

