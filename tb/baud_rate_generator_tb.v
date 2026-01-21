`timescale 1ns / 1ps

module baud_rate_generator_tb;

    parameter BITS = 11;
    reg clk;
    reg reset_n;
    reg enable;
    reg [BITS-1:0] FINAL_VALUE;
    wire done;

    // Instantiate the DUT (Device Under Test)
    timer_input #(.BITS(BITS)) uut (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .FINAL_VALUE(FINAL_VALUE),
        .done(done)
    );

    // Clock generation: 50MHz => 20ns period
    always #10 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        reset_n = 0;
        enable = 0;
        FINAL_VALUE = 11'd1735;  // Counter should pulse done after 10 cycles

        // Apply reset
        #40;
        reset_n = 1;

        // Enable counting
        #20;
        enable = 1;

        // Wait enough time for the counter to wrap (1735 counts × 20ns)
        #35000;

        // Disable counter
        enable = 0;

        #100;
        $finish;
    end

endmodule
