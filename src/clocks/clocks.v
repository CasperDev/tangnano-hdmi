import configPackage::*;

module clocks #(
  parameter DEVICE = "GW1NR-9C"
) (
  input wire I_clk27,         // board clock 27MHz
  input wire I_reset_n,       // manual reset button (active low)
  output wire O_clk_pixel,    // HDMI or VGA pixel clock           27MHz for 480p, 74.25MHz for 720p
  output wire O_clk_hdmiser,  // HDMI serial clock (5 x clk_pixel) 135MHz for 480p, 371.25MHz for 720p
  output wire O_clk_audio,    // HDMI audio clock 48kHz
  output wire O_reset_n       // keeps reset until clocks are ready or reset button is pressed
);

// --------------------------------------------------------------------------------
// HDMI clocks
// --------------------------------------------------------------------------------

wire hdmi_pll_lock;
wire pixel_lock;
wire clocks_ready = hdmi_pll_lock & pixel_lock;
assign O_reset_n = clocks_ready & I_reset_n;


wire clkoutd_o;
wire clkoutd3_o;

wire gw_gnd;
assign gw_gnd = 1'b0;

rPLL hdmi_pll (
    .CLKOUT(O_clk_hdmiser),
    .LOCK(hdmi_pll_lock),
    .CLKOUTP(),
    .CLKOUTD(clkoutd_o),
    .CLKOUTD3(clkoutd3_o),
    .RESET(gw_gnd),
    .RESET_P(gw_gnd),
    .CLKIN(I_clk27),
    .CLKFB(gw_gnd),
    .FBDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .IDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PSDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTYDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDLY({gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam hdmi_pll.FCLKIN = "27";
defparam hdmi_pll.DYN_IDIV_SEL = "false";
defparam hdmi_pll.IDIV_SEL = IDIV_SEL_X5;
defparam hdmi_pll.DYN_FBDIV_SEL = "false";
defparam hdmi_pll.FBDIV_SEL = FBDIV_SEL_X5;
defparam hdmi_pll.DYN_ODIV_SEL = "false";
defparam hdmi_pll.ODIV_SEL = ODIV_SEL_X5;
defparam hdmi_pll.PSDA_SEL = "0000";
defparam hdmi_pll.DYN_DA_EN = "true";
defparam hdmi_pll.DUTYDA_SEL = DUTYDA_SEL_X5;
defparam hdmi_pll.CLKOUT_FT_DIR = 1'b1;
defparam hdmi_pll.CLKOUTP_FT_DIR = 1'b1;
defparam hdmi_pll.CLKOUT_DLY_STEP = 0;
defparam hdmi_pll.CLKOUTP_DLY_STEP = 0;
defparam hdmi_pll.CLKFB_SEL = "internal";
defparam hdmi_pll.CLKOUT_BYPASS = "false";
defparam hdmi_pll.CLKOUTP_BYPASS = "false";
defparam hdmi_pll.CLKOUTD_BYPASS = "false";
defparam hdmi_pll.DYN_SDIV_SEL = DYN_SDIV_SEL_X5;
defparam hdmi_pll.CLKOUTD_SRC = "CLKOUT";
defparam hdmi_pll.CLKOUTD3_SRC = "CLKOUT";
defparam hdmi_pll.DEVICE = DEVICE;

`ifdef RES_480P

  assign O_clk_pixel = I_clk27;
  assign pixel_lock = 1'b1;

`endif
`ifdef RES_720P

  CLKDIV hdmiclkdiv (
    .CLKOUT(O_clk_pixel),
    .HCLKIN(O_clk_hdmiser),
    .RESETN(hdmi_pll_lock),
    .CALIB(gw_gnd)
  );
  assign pixel_lock = 1'b1;

defparam hdmiclkdiv.DIV_MODE = "5";
defparam hdmiclkdiv.GSREN = "false";

`else 
`ifndef RES_480P // not RES_480P and not RES_720P so what?
  
  $error("Define RES_480p or RES_720p in config.sv file");

`endif  // not RES_480P 
`endif // RES_480P or RES_720P

  localparam AUDIO_CLK_DELAY = CLKFRQ * 1000 / AUDIO_RATE / 2;
  reg [$clog2(AUDIO_CLK_DELAY)-1:0] audio_divider;
  reg clk_audio = 0;

  always@(posedge O_clk_pixel) 
  begin
      if (audio_divider != AUDIO_CLK_DELAY - 1) 
          audio_divider++;
      else begin 
          clk_audio <= ~clk_audio; 
          audio_divider <= 0; 
      end
  end

  assign O_clk_audio = clk_audio;

  
endmodule
