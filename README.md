# tangnano9k-hdmi
Demo Implementation of HDMI with Audio for Gowin TangNano 9k FPGA board

# Using 

Simple example displaying pink screen with blue frame via HDMI 720p or 480p.
There is also 1kHz sine wave audio playing via HDMI, but you have to push button to hear it.


# Change resolution

In order to choose resolution you have to change define declaration in file src/config.sv
Pick one and comment out other.

```
`define RES_480P /* for 720x480 @ 59.94Hz resolution */
//`define RES_720P /* for 1280x720 @ 60Hz resolution */
```

No need to recreate Gowin PLL IP - just compile as usual and upload to board.

# Use for own project

You can use this code as template for your project. There are 2 files to modify for your needs:

* src/gen_audio.v
* src/gen_video.v

Theses modules generate video and audio data. Keep in mind that HDMI works as master. It sinks pixel data from these modules giving pixel (x,y) position and expects 24bit RGB data in the same clock.

* TODO

Optimize hdmi module. It's stupid to sacrifice over 1000 LUT just for HDMI output.


