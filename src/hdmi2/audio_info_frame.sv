// Implementation of HDMI audio info frame
// By Sameer Puri https://github.com/sameer

// See Section 8.2.2
module audio_info_frame
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

assign header = {8'h0a, 8'h01, 8'h84};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] packet_bytes [27:0];

assign packet_bytes[0] = 8'h70;
assign packet_bytes[1] = 8'h01;

assign packet_bytes[2] = 8'h00;
assign packet_bytes[3] = 8'h00;
assign packet_bytes[4] = 8'h00;
assign packet_bytes[5] = 8'h00;
assign packet_bytes[6] = 8'h00;
assign packet_bytes[7] = 8'h00;
assign packet_bytes[8] = 8'h00;
assign packet_bytes[9] = 8'h00;
assign packet_bytes[10] = 8'h00;
assign packet_bytes[11] = 8'h00;
assign packet_bytes[12] = 8'h00;
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

assign sub[0] = 56'h00000000000170;

assign sub[1] = 56'h00000000000000;
assign sub[2] = 56'h00000000000000;
assign sub[3] = 56'h00000000000000;

endmodule
