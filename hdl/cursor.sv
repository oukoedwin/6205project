`timescale 1ns / 1ps
`default_nettype none

module cursor(
    input wire clk_in,
    input wire rst_in,
    input wire [3:0] cursor_color,
    input wire [2:0] stroke_width,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire [9:0] x_in,
    input wire [8:0] y_in,
    input wire cursor_type,
    output logic [7:0] red_out,
    output logic [7:0] green_out,
    output logic [7:0] blue_out,
    output logic in_sprite
);
    logic cursor1, cursor2;
    assign cursor1 = (hcount_in == x_in*2 || vcount_in == y_in*2) && 
                (x_in*2 + (stroke_width+1)*2 >= hcount_in && x_in*2 - (stroke_width+1)*2 <= hcount_in) &&
                (y_in*2 + (stroke_width+1)*2 >= vcount_in && y_in*2 - (stroke_width+1)*2 <= vcount_in);

    assign cursor2 = (hcount_in >= x_in*2-5 && hcount_in <= x_in*2+5 && vcount_in >= y_in*2-5 & vcount_in <= y_in*2+5);
        

    always_ff @(posedge clk_in)begin 
        if (rst_in) begin
            in_sprite <= 0;
            red_out <= 0;
            green_out <= 0;
            blue_out <= 0;
        end else begin 
            if (cursor_type) begin 
                if (cursor1) begin 
                    in_sprite <= 1;
                    red_out <= 8'h80;
                    green_out <= 8'h80;
                    blue_out <= 8'h80;
                end else begin 
                    in_sprite <= 0;
                end
            end else begin 
                if (cursor2) begin 
                    in_sprite <= 1;
                    red_out <= 8'h80;
                    green_out <= 8'h80;
                    blue_out <= 8'h80;
                end else begin
                    in_sprite <= 0;
                end
            end 
        end
    end

endmodule
`default_nettype wire
