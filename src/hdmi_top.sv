import configPackage::*;

module hdmi_top(
  //input I_clk27,      // board clock
	input I_reset_n,    // system reset (Active low)

// TODO:

    // vz video signals
//    input [5:0] color,
//    input [8:0] cycle,
//    input [8:0] scanline,
//    input aspect_8x7,       // 1: 8x7 pixel aspect ratio mode

	// HDMI clocks
	input I_clk_pixel,
	input I_clk_serial,
  	input I_clk_audio,
	input I_PAL50,			// PAL50 switch SW[0], set to 1 for 576p resolution, 0 for 480p resolution
	input [23:0] rgb,
	input [15:0] sample,

	output [9:0] pixX,
	output [9:0] pixY,
	output [9:0] frameWidth,
	output [9:0] frameHeight,
	output [9:0] screenWidth,
	output [9:0] screenHeight,

	// HDMI output signals
	output       tmds_clk_n,
	output       tmds_clk_p,
	output [2:0] tmds_d_n,
	output [2:0] tmds_d_p
);

// --------------------------------------------------------------
// Audio 
// --------------------------------------------------------------

    reg [15:0] audio_sample_word [1:0], audio_sample_word0 [1:0];
    always @(posedge I_clk_pixel) begin       // crossing clock domain
        audio_sample_word0[0] <= sample;
        audio_sample_word[0] <= audio_sample_word0[0];
        audio_sample_word0[1] <= sample;
        audio_sample_word[1] <= audio_sample_word0[1];
    end

    logic[2:0] tmds;
    logic tmdsClk;

    hdmi hdmi( 
		.clk_pixel_x5(I_clk_serial), 
		.clk_pixel(I_clk_pixel), 
		.clk_audio(I_clk_audio),
		.rgb(rgb), 
		.reset( ~I_reset_n ),
		.Pal50(I_PAL50),
		.audio_sample_word(audio_sample_word),
		.tmds(tmds), 
		.tmds_clock(tmdsClk), 
		.cx(pixX), 
		.cy(pixY),
		.frame_width( frameWidth ),
		.frame_height( frameHeight ), 
		.screen_width( screenWidth ),
		.screen_height( screenHeight ) 
    );

    // Gowin LVDS output buffer
    ELVDS_OBUF tmds_bufds [3:0] (
        .I({I_clk_pixel, tmds}),
        .O({tmds_clk_p, tmds_d_p}),
        .OB({tmds_clk_n, tmds_d_n})
    );

endmodule

