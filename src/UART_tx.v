`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.05.2025 21:05:07
// Design Name: 
// Module Name: UART_tx
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


module UART_tx#(parameter DBITS=8, SB_TICK=16)(
    input clk,reset_n,s_tick,
    input [DBITS-1:0]tx_din,
    input tx_start,
    output reg tx_done_tick,
    output tx
);
    
    reg [1:0] state_reg,state_next;
    reg [$clog2(SB_TICK)-1:0] s_reg,s_next;
    reg [DBITS-1:0] b_reg,b_next;
    reg [DBITS-1:0] n_reg,n_next;
    reg tx_reg,tx_next;
    
    localparam idle=0,start=1,data=2,stop=3;
    
    always @(posedge clk,negedge reset_n)
    begin
        if(~reset_n)
        begin
            state_reg<=0;
            s_reg<=0;
            b_reg<=0;
            n_reg<=0;
            tx_reg<=1'b1;
        end
        else
        begin
            state_reg<=state_next;
            s_reg<=s_next;
            b_reg<=b_next;
            n_reg<=n_next;
            tx_reg<=tx_next;
        end
    end
    
    always @(*)
    begin
        state_next = state_reg;
        s_next = s_reg;
        b_next = b_reg;
        n_next = n_reg;
        tx_done_tick = 1'b0;
        case(state_reg)
            idle : begin
            tx_next = 1'b1;
            if(tx_start)
                   begin
                       s_next = 0;
                       b_next = tx_din;
                       state_next = start;
                   end
            end
            start : 
            begin
            tx_next = 0;
            if(s_tick==1)
                        begin
                            if(s_reg == 15)
                            begin
                                s_next = 0;
                                n_next = 0;
                                state_next = data;
                            end
                            else
                                s_next = s_reg+1;
                        end
            end
            data : 
            begin
            tx_next = b_reg[0];
            if (s_tick==1)
                if(s_reg == 15)
                begin
                    s_next = 0;
                    b_next = b_reg>>1;
                    begin
                        if(n_reg == DBITS-1)
                        begin
                            state_next = stop;
                        end
                        else
                            n_next=n_reg+1;
                    end
                end
                else
                    s_next = s_reg+1;           
            end
            stop : 
            begin
            tx_next = 1'b1;
                if (s_tick ==1)
                begin
                    if(s_reg==SB_TICK-1)
                    begin
                        tx_done_tick = 1;
                        state_next = idle;
                    end
                    else
                        s_next = s_reg+1;
                end
            end
            default : state_next = idle;
        endcase
    end
    
    assign tx = tx_reg;
endmodule
