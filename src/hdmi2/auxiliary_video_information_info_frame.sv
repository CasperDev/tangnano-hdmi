// Implementation of HDMI Auxiliary Video InfoFrame packet.
// By Sameer Puri https://github.com/sameer

// See Section 8.2.1
module auxiliary_video_information_info_frame
(
	input logic Pal50, // PAL50 switch SW[0], set to 1 for 576p resolution, 0 for 480p resolution
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

logic [7:0] video_id_code;
assign video_id_code = Pal50 ? 8'd17 : 8'd2;;

localparam bit [6:0] TYPE = 7'd2;

assign header = {8'h0d, 8'h02, 8'h82};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] packet_bytes [27:0];

assign packet_bytes[0] = Pal50 ? 8'hd6 : 8'he5;
assign packet_bytes[1] = 8'h00;
assign packet_bytes[2] = 8'h08;
assign packet_bytes[3] = 8'h80;
assign packet_bytes[4] = video_id_code;

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

assign sub[0] = {16'h0000, video_id_code, 24'h800800, packet_bytes[0]};
assign sub[1] = 56'h00000000000000;
assign sub[2] = 56'h00000000000000;
assign sub[3] = 56'h00000000000000;

endmodule
