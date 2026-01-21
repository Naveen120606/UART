`timescale 1ns / 1ps

module uart_rx_tb;

    parameter DBITS = 8;
    parameter SB_TICK = 16;
    parameter BITS = 11;
    reg clk, reset_n;
    reg rx;
    wire s_tick;
    wire [DBITS-1:0] rx_dout;
    wire rx_done_tick;

    // Baud rate generator parameters
    reg [BITS-1:0] FINAL_VALUE = 11'd1735;  // Adjust for ~9600 baud at 50MHz
    reg enable;

    // Generate 50MHz clock
    always #10 clk = ~clk;

    // Instantiate baud rate generator
    timer_input #(.BITS(BITS)) baud_gen (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .FINAL_VALUE(FINAL_VALUE),
        .done(s_tick)
    );

    // Instantiate UART RX
    uart_rx #(.DBITS(DBITS), .STOP_TICK(SB_TICK)) uart_receiver (
        .clk(clk),
        .reset_n(reset_n),
        .rx(rx),
        .s_tick(s_tick),
        .rx_dout(rx_dout),
        .rx_done_tick(rx_done_tick)
    );

    // UART transmission task: sends 1 start, 8 data, and 1 stop bit
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // Start bit
            rx <= 0;
            #(FINAL_VALUE * SB_TICK * 20);  // Wait 1 bit duration

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx <= data[i];
                #(FINAL_VALUE * SB_TICK * 20);
            end

            // Stop bit
            rx <= 1;
            #(FINAL_VALUE * SB_TICK * 20);
        end
    endtask

    initial begin
        $display("Starting UART RX Testbench...");
        clk = 0;
        reset_n = 0;
        rx = 1;          // Idle state
        enable = 0;

        // Apply reset
        #100;
        reset_n = 1;
        enable = 1;

        // Send a byte
        #200;
        uart_send_byte(8'hA5);  // 8'b10100101

        // Wait and observe
        #1000000;
        if (rx_done_tick)
            $display("Data received: %h", rx_dout);
        else
            $display("Data reception failed or timed out.");

        #200;
        $finish;
    end

endmodule
