// Implementation of HDMI audio sample packet
// By Sameer Puri https://github.com/sameer

// Unless otherwise specified, all "See X" references will refer to the HDMI v1.4a specification.

// See Section 5.3.4
// 2-channel L-PCM or IEC 61937 audio in IEC 60958 frames with consumer grade IEC 60958-3.
module audio_sample_packet 
(
    input logic [7:0] frame_counter,
    // See IEC 60958-1 4.4 and Annex A. 0 indicates the signal is suitable for decoding to an analog audio signal.
    input logic [1:0] valid_bit [3:0],
    // See IEC 60958-3 Section 6. 0 indicates that no user data is being sent
    input logic [1:0] user_data_bit [3:0],
    input logic [23:0] audio_sample_word [3:0] [1:0],
    input logic [3:0] audio_sample_word_present,
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

// See IEC 60958-1 5.1, Table 2
logic [191:0] channel_status_left;
assign channel_status_left = {152'd0, 8'h02, 8'h02, 8'h10, 8'h00, 8'h04};

logic [191:0] channel_status_right;
assign channel_status_right = {152'd0, 8'h02, 8'h02, 8'h20, 8'h00, 8'h04};


// See HDMI 1.4a Table 5-12: Audio Sample Packet Header.
assign header[19:12] = 8'h00;
assign header[7:0] = 8'd2;

logic [1:0] parity_bit [3:0];
logic [7:0] aligned_frame_counter [3:0];
genvar i;
generate
    for (i = 0; i < 4; i++)
    begin: sample_based_assign
        always_comb
        begin
            if (8'(frame_counter + i) >= 8'd192)
                aligned_frame_counter[i] = 8'(frame_counter + i - 8'd192);
            else
                aligned_frame_counter[i] = 8'(frame_counter + i);
        end
        assign header[23 - (3-i)] = aligned_frame_counter[i] == 8'd0 && audio_sample_word_present[i];
        assign header[11 - (3-i)] = audio_sample_word_present[i];
        assign parity_bit[i][0] = ^{channel_status_left[aligned_frame_counter[i]], user_data_bit[i][0], valid_bit[i][0], audio_sample_word[i][0]};
        assign parity_bit[i][1] = ^{channel_status_right[aligned_frame_counter[i]], user_data_bit[i][1], valid_bit[i][1], audio_sample_word[i][1]};
        // See HDMI 1.4a Table 5-13: Audio Sample Subpacket.
        always_comb
        begin
            if (audio_sample_word_present[i])
                sub[i] = {{parity_bit[i][1], channel_status_right[aligned_frame_counter[i]], user_data_bit[i][1], valid_bit[i][1], parity_bit[i][0], channel_status_left[aligned_frame_counter[i]], user_data_bit[i][0], valid_bit[i][0]}, audio_sample_word[i][1], audio_sample_word[i][0]};
            else
                sub[i] = 56'd0;
        end
    end
endgenerate

endmodule
