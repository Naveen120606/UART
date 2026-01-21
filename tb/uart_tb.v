`timescale 1ns / 1ps

module uart_tb;

    parameter DBITS = 8;
    parameter SB_TICK = 16;
    parameter BITS = 11;  // For baud rate timer precision
    reg clk;
    reg reset_n;
    reg tx_start;
    reg [DBITS-1:0] tx_din;
    wire tx_done_tick;
    wire tx;
    wire s_tick;
    wire [DBITS-1:0] rx_dout;
    wire rx_done_tick;

    reg [BITS-1:0] FINAL_VALUE = 11'd1735;  // ~9600 baud @ 50MHz clock
    reg enable;

    // Clock generation: 50 MHz
    always #10 clk = ~clk;

    // Baud tick generator
    timer_input #(.BITS(BITS)) baud_gen (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .FINAL_VALUE(FINAL_VALUE),
        .done(s_tick)
    );

    // UART Transmitter
    UART_tx #(.DBITS(DBITS), .SB_TICK(SB_TICK)) uart_tx_inst (
        .clk(clk),
        .reset_n(reset_n),
        .s_tick(s_tick),
        .tx_din(tx_din),
        .tx_start(tx_start),
        .tx_done_tick(tx_done_tick),
        .tx(tx)
    );

    // UART Receiver (rx input connected to tx)
    uart_rx #(.DBITS(DBITS), .STOP_TICK(SB_TICK)) uart_rx_inst (
        .clk(clk),
        .reset_n(reset_n),
        .rx(tx),  // Loopback connection
        .s_tick(s_tick),
        .rx_dout(rx_dout),
        .rx_done_tick(rx_done_tick)
    );

    // Test logic
    initial begin
        $display("UART Loopback Testbench Started");
        clk = 0;
        reset_n = 0;
        tx_start = 0;
        tx_din = 8'h00;
        enable = 0;

        // Reset
        #100;
        reset_n = 1;
        enable = 1;

        // Send data
        #200;
        tx_din = 8'h5A;  // 0b01011010
        tx_start = 1;
        #20;
        tx_start = 0;

        // Wait long enough for RX to finish
        #7000000;

        if (rx_done_tick) begin
            $display("RX DONE! Data received: %h", rx_dout);
            if (rx_dout == 8'h5A)
                $display("PASS: UART loopback received correct byte.");
            else
                $display("FAIL: UART received incorrect data.");
        end else begin
            $display("FAIL: UART RX did not complete in time.");
        end

        $finish;
    end

endmodule
