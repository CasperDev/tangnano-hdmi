// Implementation of HDMI packet choice logic.
// By Sameer Puri https://github.com/sameer

module packet_picker
(
    input logic clk_pixel,
    input logic clk_audio,
    input logic reset,
	input logic Pal50, // PAL50 switch SW[0], set to 1 for 576p resolution, 0 for 480p resolution
    input logic video_field_end,
    input logic packet_enable,
    input logic [4:0] packet_pixel_counter,
    input logic [15:0] audio_sample_word [1:0],
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

// Connect the current packet type's data to the output.
logic [7:0] packet_type = 8'd0;
logic [23:0] headers [253:0];
logic [55:0] subs [255:0] [3:0];

assign header = headers[packet_type];
assign sub[0] = subs[packet_type][0];
assign sub[1] = subs[packet_type][1];
assign sub[2] = subs[packet_type][2];
assign sub[3] = subs[packet_type][3];

 
// NULL packet
// "An HDMI Sink shall ignore bytes HB1 and HB2 of the Null Packet Header and all bytes of the Null Packet Body."
`ifdef MODEL_TECH
assign headers[0] = {8'd0, 8'd0, 8'd0}; assign subs[0] = '{56'd0, 56'd0, 56'd0, 56'd0};
`else
assign headers[0] = {8'dX, 8'dX, 8'd0};
assign subs[0][0] = 56'dX;
assign subs[0][1] = 56'dX;
assign subs[0][2] = 56'dX;
assign subs[0][3] = 56'dX;
`endif

// Audio Clock Regeneration Packet
logic clk_audio_counter_wrap;
audio_clock_regeneration_packet audio (
	.clk_pixel(clk_pixel), 
	.clk_audio(clk_audio), 
	.clk_audio_counter_wrap(clk_audio_counter_wrap), 
	.header(headers[1]), 
	.sub(subs[1])
);


logic [15:0] audio_sample_word_transfer [1:0];
logic audio_sample_word_transfer_control = 1'd0;
always_ff @(posedge clk_audio)
begin
    audio_sample_word_transfer <= audio_sample_word;
    audio_sample_word_transfer_control <= !audio_sample_word_transfer_control;
end

logic [1:0] audio_sample_word_transfer_control_synchronizer_chain = 2'd0;
always_ff @(posedge clk_pixel)
    audio_sample_word_transfer_control_synchronizer_chain <= {audio_sample_word_transfer_control, audio_sample_word_transfer_control_synchronizer_chain[1]};

logic sample_buffer_current = 1'b0;
logic [1:0] samples_remaining = 2'd0;
logic [23:0] audio_sample_word_buffer [1:0] [3:0] [1:0];
logic [15:0] audio_sample_word_transfer_mux [1:0];
always_comb
begin
    if (audio_sample_word_transfer_control_synchronizer_chain[0] ^ audio_sample_word_transfer_control_synchronizer_chain[1])
        audio_sample_word_transfer_mux = audio_sample_word_transfer;
    else
        audio_sample_word_transfer_mux = '{audio_sample_word_buffer[sample_buffer_current][samples_remaining][1][23:8], audio_sample_word_buffer[sample_buffer_current][samples_remaining][0][23:8]};
end

logic sample_buffer_used = 1'b0;
logic sample_buffer_ready = 1'b0;

always_ff @(posedge clk_pixel)
begin
    if (sample_buffer_used)
        sample_buffer_ready <= 1'b0;

    if (audio_sample_word_transfer_control_synchronizer_chain[0] ^ audio_sample_word_transfer_control_synchronizer_chain[1])
    begin
        audio_sample_word_buffer[sample_buffer_current][samples_remaining][0] <=  24'(audio_sample_word_transfer_mux[0])<<8;
        audio_sample_word_buffer[sample_buffer_current][samples_remaining][1] <=  24'(audio_sample_word_transfer_mux[1])<<8;
        if (samples_remaining == 2'd3)
        begin
            samples_remaining <= 2'd0;
            sample_buffer_ready <= 1'b1;
            sample_buffer_current <= !sample_buffer_current;
        end
        else
            samples_remaining <= samples_remaining + 1'd1;
    end
end

logic [23:0] audio_sample_word_packet [3:0] [1:0];
logic [3:0] audio_sample_word_present_packet;

logic [7:0] frame_counter = 8'd0;
int k;
always_ff @(posedge clk_pixel)
begin
    if (reset)
    begin
        frame_counter <= 8'd0;
    end
    else if (packet_pixel_counter == 5'd31 && packet_type == 8'h02) // Keep track of current IEC 60958 frame
    begin
        frame_counter = frame_counter + 8'd4;
        if (frame_counter >= 8'd192)
            frame_counter = frame_counter - 8'd192;
    end
end

audio_sample_packet audio_sample_packet (
	.frame_counter(frame_counter), 
	.valid_bit('{2'b00, 2'b00, 2'b00, 2'b00}), 
	.user_data_bit('{2'b00, 2'b00, 2'b00, 2'b00}), 
	.audio_sample_word(audio_sample_word_packet), 
	.audio_sample_word_present(audio_sample_word_present_packet), 
	.header(headers[2]), 
	.sub(subs[2])
);


auxiliary_video_information_info_frame auxiliary_video_information_info_frame(
	.Pal50(Pal50), // PAL50 switch SW[0], set to 1 for 576p resolution, 0 for 480p resolution
	.header(headers[130]), 
	.sub(subs[130])
);


source_product_description_info_frame source_product_description_info_frame(
	.header(headers[131]), 
	.sub(subs[131])
);


audio_info_frame audio_info_frame(
	.header(headers[132]), 
	.sub(subs[132])
);


// "A Source shall always transmit... [an InfoFrame] at least once per two Video Fields"
logic audio_info_frame_sent = 1'b0;
logic auxiliary_video_information_info_frame_sent = 1'b0;
logic source_product_description_info_frame_sent = 1'b0;
logic last_clk_audio_counter_wrap = 1'b0;
always_ff @(posedge clk_pixel)
begin
    if (sample_buffer_used)
        sample_buffer_used <= 1'b0;

    if (reset || video_field_end)
    begin
        audio_info_frame_sent <= 1'b0;
        auxiliary_video_information_info_frame_sent <= 1'b0;
        source_product_description_info_frame_sent <= 1'b0;
        packet_type <= 8'dx;
    end
    else if (packet_enable)
    begin
        if (last_clk_audio_counter_wrap ^ clk_audio_counter_wrap)
        begin
            packet_type <= 8'd1;
            last_clk_audio_counter_wrap <= clk_audio_counter_wrap;
        end
        else if (sample_buffer_ready)
        begin
            packet_type <= 8'd2;
            audio_sample_word_packet <= audio_sample_word_buffer[!sample_buffer_current];
            audio_sample_word_present_packet <= 4'b1111;
            sample_buffer_used <= 1'b1;
        end
        else if (!audio_info_frame_sent)
        begin
            packet_type <= 8'h84;
            audio_info_frame_sent <= 1'b1;
        end
        else if (!auxiliary_video_information_info_frame_sent)
        begin
            packet_type <= 8'h82;
            auxiliary_video_information_info_frame_sent <= 1'b1;
        end
        else if (!source_product_description_info_frame_sent)
        begin
            packet_type <= 8'h83;
            source_product_description_info_frame_sent <= 1'b1;
        end
        else
            packet_type <= 8'd0;
    end
end

endmodule
