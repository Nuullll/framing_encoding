// fifo_test.v
`timescale 1us/100ns

module fifo_test;

     wire             fifo_output;
     wire             fifo_output_valid;
     reg     [7:0]    phr_psdu_in;
     reg              phr_psdu_in_valid;
     reg              clk;
     reg              reset_n;
 
 
 
fifo fifo0 (
    .clk(clk), 
    .reset_n(reset_n), 
    .fifo_input(phr_psdu_in), 
    .fifo_input_valid(phr_psdu_in_valid), 
    .fifo_output(fifo_output), 
    .fifo_output_valid(fifo_output_valid)
);


// stop simulation after 20000us
  initial 
    begin
    #20000 $stop;
    end


    
// generate data input signal
  initial 
    begin
             phr_psdu_in=8'h00;
        #500 phr_psdu_in=8'h07;
        #100 phr_psdu_in=8'h03;
        #100 phr_psdu_in=8'h01;
        #100 phr_psdu_in=8'h05;
        #100 phr_psdu_in=8'h21;
        #100 phr_psdu_in=8'h43;
        #100 phr_psdu_in=8'h65;
        #100 phr_psdu_in=8'h87;
    end

// generate phr_psdu_in_valid signal
  initial 
    begin
             phr_psdu_in_valid =1'b0;
        #500 phr_psdu_in_valid =1'b1;
        #800 phr_psdu_in_valid =1'b0;
    end
    
// generate clk signal
  initial 
    begin
        clk=1'b0;
    end
always #50 clk=~clk;

// generate resrt_n signal
  initial 
    begin
               reset_n=1'b1;
        #  520 reset_n=1'b0;
        #  20  reset_n=1'b1;
    end

endmodule