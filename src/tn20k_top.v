

import configPackage::*;

module top(
  input wire I_clk27,   // board clock 27MHz
  input wire I_reset, // Reset button BTN[0]
  input wire I_play_audio, // 2nd button BTN[1] play audio only if pressed (1)
	// HDMI output signals
	output       tmds_clk_n,
	output       tmds_clk_p,
	output [2:0] tmds_d_n,
	output [2:0] tmds_d_p

);

wire I_reset_n = ~I_reset;
wire I_play_audio_n = ~I_play_audio;

// ------------ Clocks --------------------
wire clk_pixel;         // HDMI or VGA pixel clock           27MHz for 480p, 74.25MHz for 720p
wire clk_hdmi_serial;   // HDMI serial clock (5 x clk_pixel) 135MHz for 480p, 371.25MHz for 720p
wire clk_audio;         // HDMI audio clock 32kHz
wire sys_reset_n;       // 0 when clocks NOT ready or button pressed

clocks #(.DEVICE("GW2AR-18C") ) clocks_inst(I_clk27,I_reset_n, clk_pixel, clk_hdmi_serial,clk_audio,sys_reset_n);

wire [23:0] rgb;
wire [VIDEO_X_BITWIDTH-1:0] pixX, frameWidth, screenWidth;
wire [VIDEO_Y_BITWIDTH-1:0] pixY, frameHeight, screenHeight;

gen_video just_border(
  .I_clk_pixel(clk_pixel),
  .I_reset_n(sys_reset_n),
  .pixX(pixX),
  .pixY(pixY),
  .screenWidth(screenWidth),
  .screenHeight(screenHeight),
  .rgb(rgb)
);
wire [AUDIO_BIT_WIDTH-1:0] sample_gen;
wire [AUDIO_BIT_WIDTH-1:0] sample;

gen_audio sin_1kHz(
  .I_clk_audio(clk_audio),
  .I_reset_n(sys_reset_n),
  .sample(sample_gen)
);

assign sample = (I_play_audio_n == 1'b0) ? sample_gen : 16'd0;

hdmi_top video(
	.I_reset_n(sys_reset_n),    // system reset (Active low)

	// HDMI clocks
	.I_clk_pixel(clk_pixel),
	.I_clk_serial(clk_hdmi_serial),
  .I_clk_audio(clk_audio),

  .rgb(rgb),
  .sample(sample),

  .pixX(pixX), 
  .pixY(pixY),
  .frameWidth(frameWidth),
  .frameHeight(frameHeight),
  .screenWidth(screenWidth),
  .screenHeight(screenHeight),

	// HDMI output signals
	.tmds_clk_n(tmds_clk_n),
	.tmds_clk_p(tmds_clk_p),
	.tmds_d_n(tmds_d_n),
	.tmds_d_p(tmds_d_p)
);

endmodule