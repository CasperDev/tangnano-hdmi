//`define RES_480P
`define RES_576P
`define GW_IDE

package configPackage;  

  `ifdef RES_480P
    localparam SCREENWIDTH = 720;
    localparam SCREENHEIGHT = 480;
    localparam TOTALWIDTH = 858;
    localparam TOTALHEIGHT = 525;

  `endif

  `ifdef RES_576P
    localparam SCREENWIDTH = 720;
    localparam SCREENHEIGHT = 576;
    localparam TOTALWIDTH = 864;
    localparam TOTALHEIGHT = 625;

  `endif

endpackage