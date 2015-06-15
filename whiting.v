// whiting.v

module whiting (
    input clk, 
    input reset_n, 
    input tx_data,  // serial input
    input tx_data_valid, 
    output reg tx_out,  // serial output
    output reg tx_out_valid 
);

reg [8:0] pseudo_rand;
reg [6:0] shr_count;
reg data_received;

always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        pseudo_rand <= 9'b111_111_111;
        tx_out_valid <= 0;
        shr_count <= 0;
        data_received <= 0;
    end else begin
        if (tx_data_valid) begin
            if (shr_count == 80) begin
                tx_out <= tx_data ^ pseudo_rand[0];
                tx_out_valid <= 1;
                pseudo_rand <= {pseudo_rand[5]^pseudo_rand[0], pseudo_rand[8:1]};
                data_received <= 1;
            end else begin
                shr_count <= shr_count + 1;
                tx_out <= tx_data;
                tx_out_valid <= 1;
                data_received <= 0;
            end
        end else if (data_received) begin   // ready to receive SHR of next data
            tx_out_valid <= 0;
            shr_count <= 0;
            data_received <= 1;
        end else begin
            tx_out_valid <= 0;  // waiting for PHR PSDU FCS
        end
    end
end

endmodule
