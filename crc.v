// crc.v

module crc (
    input clk,  // 10kHz
    input reset_n,  // asynchronous reset active low
    input tx_data, 
    input tx_data_valid, 
    output reg tx_out,  // serial output
    output reg tx_out_valid     // high active when outputing FCS code serially
);

reg [15:0] fcs_n;
reg [6:0] shr_count;
reg [3:0] fcs_count;

always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        fcs_n <= 16'hffff;
        shr_count <= 0;
        fcs_count <= 0;
    end else begin
        if (tx_data_valid) begin
            if (shr_count == 80) begin
                fcs_n <= {fcs_n[0]^tx_data, fcs_n[15:12], 
                          fcs_n[11]^fcs_n[0]^tx_data, fcs_n[10:5], 
                          fcs_n[4]^fcs_n[0]^tx_data, fcs_n[3:1]};
            end else shr_count <= shr_count + 1;
        end else if (shr_count == 80) begin
            tx_out_valid <= 1;
            tx_out <= ~fcs_n[0];
            fcs_n <= fcs_n >> 1;
            if (fcs_count == 15) shr_count <= 0;    // ready to receive next data;
            fcs_count <= fcs_count + 1;
        end else begin
            tx_out_valid <= 0;
            shr_count <= 0;
        end
    end
end

endmodule
