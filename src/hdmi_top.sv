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

  input [23:0] rgb,
  input [AUDIO_BIT_WIDTH-1:0] sample,

  output [VIDEO_X_BITWIDTH-1:0] pixX,
  output [VIDEO_Y_BITWIDTH-1:0] pixY,
  output [VIDEO_X_BITWIDTH-1:0] frameWidth,
  output [VIDEO_Y_BITWIDTH-1:0] frameHeight,
  output [VIDEO_X_BITWIDTH-1:0] screenWidth,
  output [VIDEO_Y_BITWIDTH-1:0] screenHeight,

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

    hdmi #( .VIDEO_ID_CODE(VIDEOID), 
            .DVI_OUTPUT(0), 
            .VIDEO_REFRESH_RATE(VIDEO_REFRESH),
            .IT_CONTENT(1),
            .AUDIO_RATE(AUDIO_RATE), 
            .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
            .START_X(0),
            .START_Y(0) )

    hdmi( .clk_pixel_x5(I_clk_serial), 
          .clk_pixel(I_clk_pixel), 
          .clk_audio(I_clk_audio),
          .rgb(rgb), 
          .reset( ~I_reset_n ),
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

