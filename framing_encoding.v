// framing_encoding.v

module framing_encoding (
    input clk,  // 10kHz
    input reset_n,  // asynchronous reset active low
    input [7:0] phr_psdu_in, 
    input phr_psdu_in_valid, 
    output framing_encoding_out, 
    output framing_encoding_out_valid 
);

fifo FIFO(
    .clk(clk), 
    .reset_n(reset_n), 
    .fifo_input(phr_psdu_in), 
    .fifo_input_valid(phr_psdu_in_valid), 

    .fifo_output(fifo_output), 
    .fifo_output_valid(fifo_output_valid)
);

crc CRC(
    .clk(clk), 
    .reset_n(reset_n), 
    .tx_data(fifo_output), 
    .tx_data_valid(fifo_output_valid), 

    .tx_out(crc_output), 
    .tx_out_valid(crc_output_valid)
);

select_whiting_input SELECT(
    .clk(clk), 
    .reset_n(reset_n), 
    .fifo_output(fifo_output), 
    .fifo_output_valid(fifo_output_valid), 
    .crc_output(crc_output), 
    .crc_output_valid(crc_output_valid), 

    .whiting_input(whiting_input), 
    .whiting_input_valid(whiting_input_valid)
);

whiting WHITING(
    .clk(clk), 
    .reset_n(reset_n), 
    .tx_data(whiting_input),  
    .tx_data_valid(whiting_input_valid), 

    .tx_out(framing_encoding_out), 
    .tx_out_valid(framing_encoding_out_valid)
);

endmodule

module select_whiting_input (
    input clk, 
    input reset_n, 
    input fifo_output, 
    input fifo_output_valid, 
    input crc_output, 
    input crc_output_valid, 
    output reg whiting_input, 
    output reg whiting_input_valid
);

reg pre_input;
reg [1:0] state;
// state == 0: waiting for input data
// state == 1: stored one bit data in pre_input
// state == 2: pre_input is empty, turns into a buffer

always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        whiting_input_valid <= 0;
        state <= 0;
    end else begin
        if (state == 0) begin
            if (fifo_output_valid) begin
                pre_input <= fifo_output;
                whiting_input_valid <= 0;
                state <= 1;
            end else state <= 0;
        end else if (state == 1) begin
            whiting_input <= pre_input;
            whiting_input_valid <= 1;
            if (fifo_output_valid) begin
                pre_input <= fifo_output;
                state <= 1;
            end else if (crc_output_valid) begin
                pre_input <= crc_output;
                state <= 1;
            end else begin
                state <= 2;
            end
        end else begin
            if (fifo_output_valid) begin
                whiting_input <= fifo_output;
                whiting_input_valid <= 1;
                state <= 2;
            end else if (crc_output_valid) begin
                whiting_input <= crc_output;
                whiting_input_valid <= 1;
                state <= 2;
            end else begin
                whiting_input_valid <= 0;
                state <= 0;
            end
        end
    end
end

endmodule
