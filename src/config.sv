//`define RES_480P
`define RES_576P
`define GW_IDE

package configPackage;  

  `ifdef RES_480P
    localparam SCREENWIDTH = 720;
    localparam SCREENHEIGHT = 480;
    localparam TOTALWIDTH = 858;
    localparam TOTALHEIGHT = 525;
    localparam SCALE = 3;

    localparam CLKFRQ = 27000;
  `endif

  `ifdef RES_576P
    localparam SCREENWIDTH = 720;
    localparam SCREENHEIGHT = 576;
    localparam TOTALWIDTH = 864;
    localparam TOTALHEIGHT = 625;
    localparam SCALE = 3;

    localparam CLKFRQ = 27000;
  `endif

  localparam COLLEN = 80;
  localparam POWERUPNS = 100000000.0;
  localparam CLKPERNS = (1.0/CLKFRQ)*1000000.0;
  //localparam int POWERUPCYCLES = $ceil( POWERUPNS/CLKPERNS );

endpackage