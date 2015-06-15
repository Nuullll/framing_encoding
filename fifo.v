// fifo.v

module fifo (
    input clk, 
    input reset_n, 
    input [7:0] fifo_input,   // 8 bit in
    input fifo_input_valid, 
    output reg fifo_output,     // 1 bit out
    output reg fifo_output_valid
    // output fifo_full
);

parameter MEMORY_SIZE = 8;
integer i;

reg [7:0] memory [MEMORY_SIZE - 1:0];
reg [2:0] col;  // mark which bit to output
reg [2:0] read_row;  // mark which row to output
reg [2:0] write_row; // mark which row to write data
reg [3:0] count;    // count the number of 1-Byte-data still in memory
reg [7:0] send_count;  // count the number of data sent out
reg [7:0] data_size;    // Bytes of phr + psdu is data_size
reg read_data_size;     // tag: high active to catch data_size
reg [6:0] shr_count;    // count: output SHR code
reg [79:0] shr;         // SHR code: {16'hF3_98, 64'hAA_AA_AA_AA_AA_AA_AA_AA}

always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        // initialize memory
        for (i = 0; i < MEMORY_SIZE; i = i + 1) begin
            memory[i] <= 8'h00;
        end
        // initialize row, col
        // ready to output memory[0][0], but memory is empty
        col <= 3'b000;
        read_row <= 3'b000;
        write_row <= 3'b000;
        fifo_output <= 0;
        fifo_output_valid <= 0;
        count <= 0;
        send_count <= 0;
        read_data_size <= 1;
        shr_count <= 0;
        shr <= {16'hF3_98, 64'hAA_AA_AA_AA_AA_AA_AA_AA};
    end else begin
        if (fifo_input_valid && count < MEMORY_SIZE) begin   // store input data
            if (read_data_size) begin
                data_size <= fifo_input;    // first Byte
                read_data_size <= 0;        // flag off
            end
            if (count == 0) begin
                memory[0] <= fifo_input;    // store into empty memory
                read_row <= 0;
                write_row <= 1;
            end else begin
                memory[write_row] <= fifo_input;
                write_row <= write_row + 1;
            end
            count <= count + 1;
        end
        if (count != 0) begin      // output data
            if (shr_count == 80) begin      // SHR end
                shr <= {16'hF3_98, 64'hAA_AA_AA_AA_AA_AA_AA_AA};
                fifo_output <= memory[read_row][col];
                fifo_output_valid <= 1;
                if (col == 7) begin     // one Byte data is sent out
                    read_row <= read_row + 1;
                    count <= count - 1;
                    if (send_count == data_size) begin  // data end
                        send_count <= 0;
                        read_data_size <= 1;    // catch next data_size
                        shr_count <= 0;
                    end else send_count <= send_count + 1;
                end
                col <= col + 1;
            end else begin      // outputing SHR code
                fifo_output <= shr[0];
                fifo_output_valid <= 1;
                shr <= shr >> 1;
                shr_count <= shr_count + 1;
            end
        end else fifo_output_valid <= 0;
    end
end

endmodule 
