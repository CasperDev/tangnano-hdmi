# tangnano-hdmi
Demo Implementation of HDMI with Audio for Gowin TangNano FPGA boards:
* Tang Nano 9k
* Tang Nano 20k

## Features 

Simple example displaying pink screen with blue frame via HDMI 720p or 480p.
There is also 1kHz sine wave audio playing via HDMI, but you have to push button to hear it (cause it would be annoying to hear it all the time).

## Resource Utilization Summary

Amount of used resource depends on Gowin IDE version you use. Seems like new 1.9.9 Beta-3 version is improved and do much better job. Code is optimized to NOT use block-RAM - you may need it as buffers for your video/audio generators.

### Gowin IDE 1.9.9 Beta-3 build(67298) - Tangnano 9k

|Resource|Usage|Utilization|
|---|---|---|
|Logic|1194(974 LUT, 88 ALU, 132 ROM16) / 8640|14%|
|Register|668 / 6693|10%|
|  --Register as Latch|0 / 6693|0%|
|  --Register as FF|668 / 6693|10%|
|BSRAM|0 / 26|0%|

### Gowin IDE 1.9.9 Beta-3 build(67298) - Tangnano 20k

|Resource|Usage|Utilization|
|---|---|---|
|Logic|1207(988 LUTs, 87 ALUs, 132 ROM16) / 20736|6%|
|Register|668 / 15750|5%|
|  --Register as Latch|0 / 15750|0%|
|  --Register as FF|668 / 15750|5%|
|BSRAM|0 / 46|0%|

### Gowin IDE 1.9.8.06 build(57742) - Tangnano 9k

|Resource|Usage|Utilization|
|---|---|---|
|Logic|2009(1258 LUTs, 68 ALUs, 683 SSRAMs) / 8640|23%|
|Register|668 / 6693|10%|
|  --Register as Latch|0 / 6693|0%|
|  --Register as FF|668 / 6693|10%|
|BSRAM|0 / 26|0%|

### Gowin IDE 1.9.8.06 build(57742) - Tangnano 20k

|Resource|Usage|Utilization|
|---|---|---|
|Logic|2013(1262 LUTs, 68 ALUs, 683 SSRAMs) / 20736|10%|
|Register|668 / 15750|4%|
|  --Register as Latch|0 / 15750|0%|
|  --Register as FF|668 / 15750|4%|
|BSRAM|0 / 46|0%|


## Change resolution

In order to choose resolution you have to change define declaration in file src/config.sv
Pick one and comment out other.

```
`define RES_480P /* for 720x480 @ 59.94Hz resolution */
//`define RES_720P /* for 1280x720 @ 60Hz resolution */
```

No need to recreate Gowin PLL IP - just compile as usual and upload to board.

## Use for own project

You can use this code as template for your project. There are 2 files to modify for your needs:

* src/gen_audio.v
* src/gen_video.v

Theses modules generate video and audio data. Keep in mind that HDMI works as master. It sinks pixel data from these modules giving pixel (x,y) position and expects 24bit RGB data in the same clock.

## TODO

Optimize hdmi module. It's stupid to sacrifice over 1000 LUT just for HDMI output.


