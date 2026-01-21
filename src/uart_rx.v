`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.05.2025 00:34:33
// Design Name: 
// Module Name: uart_rx
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
module uart_rx#(parameter DBITS=8,STOP_TICK=16)(
    input clk,reset_n,
    input rx,s_tick,
    output [DBITS-1:0]rx_dout,
    output reg rx_done_tick
);
     localparam idle=0, start=1, data=2, stop=3;
    
    reg [1:0] state_reg,state_next;
    reg [3:0] s_reg,s_next;  //variable to keep track of baud rate (total: 16 ticks)
    reg [$clog2(DBITS)-1:0]n_reg,n_next;  //variable to keep track of number of bits received
    reg [DBITS-1:0] b_reg,b_next;  // stores received data bits
    
    //State functioning at clock or reset_n
    always@(posedge clk,negedge reset_n)
    begin
        if(~reset_n)
        begin
            state_reg<=idle;
            s_reg<=0;
            n_reg<=0;
            b_reg<=0;
        end
       else
        begin
            state_reg<=state_next;
            s_reg<=s_next;
            n_reg<=n_next;
            b_reg<=b_next;
        end
    end
    
    always @(*)
    begin
    state_next = state_reg;
    s_next = s_reg;
    n_next = n_reg;
    b_next = b_reg;
        case(state_reg)
            idle : if(~rx)
                        state_next = start;
            start :if(s_reg==7 & s_tick)
                        begin
                            s_next = 0;
                            n_next = 0;
                            state_next = data;
                        end
                    else if(s_reg!=7 & s_tick)
                        begin
                            s_next = s_reg+1;
                        end
             data : if(s_tick)
                        begin
                            if(s_reg==15)
                            begin
                                s_next = 0;
                                b_next = (rx<<DBITS-1)|(b_reg>>1);
                                if (n_reg == DBITS-1)
                                    state_next = stop;
                                else
                                        n_next = n_reg+1;
                            end
                            else
                                    s_next = s_reg+1;
                        end
            stop : if(s_tick)
                   begin
                       if(s_reg == STOP_TICK-1)
                       begin
                           rx_done_tick = 1'b1;
                           state_next = idle;
                       end
                       else
                       begin
                           s_next = s_reg+1;
                       end
                   end
            default : begin
                        state_next = idle;
                        n_next = n_reg;
                        b_next = b_reg;
                        rx_done_tick = 0;
             end
        endcase
    end
    
    assign rx_dout = b_reg;
endmodule
