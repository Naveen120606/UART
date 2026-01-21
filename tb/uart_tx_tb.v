`timescale 1ns / 1ps

module uart_tx_tb;

    parameter DBITS = 8;
    parameter SB_TICK = 16;
    parameter BITS = 11;  // For timer resolution

    reg clk;
    reg reset_n;
    reg tx_start;
    reg [DBITS-1:0] tx_din;
    wire tx_done_tick;
    wire tx;
    wire s_tick;

    reg [BITS-1:0] FINAL_VALUE = 11'd1735;  // For 9600 baud with 50MHz clk
    reg enable;

    // Clock generation: 50 MHz
    always #10 clk = ~clk;

    // Instantiate Baud Tick Generator
    timer_input #(.BITS(BITS)) baud_gen (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .FINAL_VALUE(FINAL_VALUE),
        .done(s_tick)
    );

    // Instantiate UART Transmitter
    UART_tx #(.DBITS(DBITS), .SB_TICK(SB_TICK)) uart_tx_inst (
        .clk(clk),
        .reset_n(reset_n),
        .s_tick(s_tick),
        .tx_din(tx_din),
        .tx_start(tx_start),
        .tx_done_tick(tx_done_tick),
        .tx(tx)
    );

    // Test procedure
    initial begin
        $display("UART TX Testbench Started");

        // Initialize
        clk = 0;
        reset_n = 0;
        tx_start = 0;
        tx_din = 8'h00;
        enable = 0;

        // Reset pulse
        #100;
        reset_n = 1;
        enable = 1;

        // Wait a bit before starting transmission
        #1000;

        // Send byte 0xA5 (10100101)
        tx_din = 8'hA5;
        tx_start = 1;
        #20;
        tx_start = 0;

        // Wait for transmission to finish (1 start + 8 data + 1 stop = 10 bits)
        // Each bit takes approx 555.2 us → Wait ~6 ms
        #6000000;

        if (tx_done_tick)
            $display("Transmission complete: tx_done_tick = %b", tx_done_tick);
        else
            $display("Error: Transmission did not complete in expected time.");

        $finish;
    end

endmodule
