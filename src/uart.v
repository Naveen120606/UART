`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.05.2025 23:38:18
// Design Name: 
// Module Name: uart
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart#(parameter DBITS=8,SB_TICK=16)(
    input clk,reset_n,
    
    //receiver port
    input rx,
    output [DBITS-1:0] r_data,
    input rd_uart,
    output rx_empty,
    
    //transmitter port
    output tx,
    input [DBITS-1:0] w_data,
    input wr_uart,
    output tx_full,
    
    //baud rate generator port
    input [10:0] FINAL_VALUE
    );
    
    //Baud rate generator    
    wire tick;
    
    timer_input#(.BITS(11)) baud_rate_generator(
        .clk(clk),
        .reset_n(reset_n),
        .enable(1'b1),
        .FINAL_VALUE(FINAL_VALUE),
        .done(tick)
    );
    
    //UART receiver
    wire rx_done_tick;
    wire [DBITS-1:0] rx_dout;
    
    uart_rx#(.DBITS(8),.STOP_TICK(16)) uart_receiver(
        .clk(clk),
        .reset_n(reset_n),
        .rx(rx),
        .s_tick(tick),
        .rx_dout(rx_dout),
        .rx_done_tick(rx_done_tick)
    );
     
     //FIFO for receiver
     wire rx_full;
     
     fifo_generator_0 fifo_rx (
         .clk(clk),      // input wire clk
         .srst(~reset_n),    // input wire srst
         .din(rx_dout),      // input wire [7 : 0] din
         .wr_en(rx_done_tick),  // input wire wr_en
         .rd_en(rd_uart),  // input wire rd_en
         .dout(r_data),    // output wire [7 : 0] dout
         .full(),    // output wire full
         .empty(rx_empty)  // output wire empty
      );

    //Transmitter
    wire tx_done_tick, tx_fifo_empty;
    wire [DBITS-1:0] tx_din;
    
    UART_tx#(.DBITS(8),.SB_TICKS(16)) uart_transmitter(
        .clk(clk),
        .reset_n(reset_n),
        .s_tick(tick),
        .tx_din(tx_din),
        .tx_start(~tx_fifo_empty),
        .tx_done_tick(tx_done_tick),
        .tx(tx)
    );
    
    //FIFO for transmitter
    fifo_generator_0 fifo_tx (
       .clk(clk),      // input wire clk
       .srst(~reset_n),    // input wire srst
       .din(w_data),      // input wire [7 : 0] din
       .wr_en(wr_uart),  // input wire wr_en
       .rd_en(tx_done_tick),  // input wire rd_en
       .dout(tx_din),    // output wire [7 : 0] dout
       .full(tx_full),    // output wire full
       .empty(tx_fifo_empty)  // output wire empty
    );
endmodule
