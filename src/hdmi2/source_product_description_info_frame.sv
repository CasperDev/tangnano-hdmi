// Implementation of HDMI SPD InfoFrame packet.
// By Sameer Puri https://github.com/sameer

// See CEA-861-D Section 6.5 page 72 (84 in PDF)
module source_product_description_info_frame
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

localparam bit [4:0] LENGTH = 5'd25;

assign header = {8'd25, 8'd1, 8'h83};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] packet_bytes [27:0];

assign packet_bytes[0] = 8'd1 + ~(8'd25 + 8'd1 + 8'h83 + 8'h41 + 8'h47 + 8'h50 + 8'h46 + 8'h6e + 8'h77 + 8'h6f + 8'h6e + 8'h6b + 8'h6e + 8'h55);
assign packet_bytes[1] = 8'h55;
assign packet_bytes[2] = 8'h6e;
assign packet_bytes[3] = 8'h6b;
assign packet_bytes[4] = 8'h6e;
assign packet_bytes[5] = 8'h6f;
assign packet_bytes[6] = 8'h77;
assign packet_bytes[7] = 8'h6e;
assign packet_bytes[8] = 8'h00;

assign packet_bytes[9] = 8'h46;
assign packet_bytes[10] = 8'h50;
assign packet_bytes[11] = 8'h47;
assign packet_bytes[12] = 8'h41;
assign packet_bytes[13] = 8'h00;
assign packet_bytes[14] = 8'h00;
assign packet_bytes[15] = 8'h00;
assign packet_bytes[16] = 8'h00;
assign packet_bytes[17] = 8'h00;
assign packet_bytes[18] = 8'h00;
assign packet_bytes[19] = 8'h00;
assign packet_bytes[20] = 8'h00;
assign packet_bytes[21] = 8'h00;
assign packet_bytes[22] = 8'h00;
assign packet_bytes[23] = 8'h00;
assign packet_bytes[24] = 8'h00;

assign packet_bytes[25] = 8'h00;
assign packet_bytes[26] = 8'h00;
assign packet_bytes[27] = 8'h00;


genvar i;
generate
    for (i = 0; i < 4; i++)
    begin: pb_to_sub
        assign sub[i] = {packet_bytes[6 + i*7], packet_bytes[5 + i*7], packet_bytes[4 + i*7], packet_bytes[3 + i*7], packet_bytes[2 + i*7], packet_bytes[1 + i*7], packet_bytes[0 + i*7]};
    end
endgenerate

endmodule
