`timescale 1ns / 1ps
`default_nettype none

module user_input_tb();
    logic clk_in;
    logic rst_in;
    logic [3:0] pos_con_in;
    logic col_con_in;
    logic sw_con_in;
    logic [9:0] cursor_loc_x;
    logic [8:0] cursor_loc_y;
    logic [3:0] cursor_color;
    logic [2:0] stroke_width;

    user_input test(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .pos_con_in(pos_con_in),
        .col_con_in(col_con_in),
        .sw_con_in(sw_con_in),
        .cursor_loc_x(cursor_loc_x),
        .cursor_loc_y(cursor_loc_y),
        .cursor_color(cursor_color),
        .stroke_width(stroke_width));

    always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
    end

    initial begin
        $dumpfile("user_input.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,user_input_tb);
        $display("Starting Sim"); //print nice message at start

        clk_in = 0;
        rst_in = 0;
        pos_con_in = 0;
        col_con_in = 0;
        sw_con_in = 0;

        #10;
        rst_in = 1;
        #10;
        rst_in = 0;


        for(int i = 0; i < 20; i++) begin
            #10;
            col_con_in = 1;
            sw_con_in = 1;
            #10;
            col_con_in = 0;
            sw_con_in = 0;
        end

        pos_con_in = 4'b0110;
        #1500;
        pos_con_in = 4'b1001;
        #1500;
        pos_con_in = 0;

        #500;

        $display("Simulation finished");
        $finish;
    end



endmodule
`default_nettype wire