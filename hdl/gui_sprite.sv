`timescale 1ns / 1ps
`default_nettype none

module gui_sprite(
    input wire clk_in,
    input wire rst_in,
    input wire [3:0] cursor_color,
    input wire [2:0] stroke_width,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    output logic [7:0] red_out,
    output logic [7:0] green_out,
    output logic [7:0] blue_out,
    output logic in_sprite
);
    logic [7:0] red, green, blue;
    always_comb begin
        case (cursor_color)
            4'b0000: begin //black
                red = 8'h00;
                green = 8'h00;
                blue = 8'h00;
            end
            4'b0001: begin //white
                red = 8'hFF;
                green = 8'hFF;
                blue = 8'hFF;
            end
            4'b0010: begin //red
                red = 8'hFF;
                green = 8'h00;
                blue = 8'h00;
            end
            4'b0011: begin //green
                red = 8'h00;
                green = 8'hFF;
                blue = 8'h00;
            end
            4'b0100: begin //blue
                red = 8'h00;
                green = 8'h00;
                blue = 8'hFF;
            end
            4'b0101: begin //cyan
                red = 8'h00;
                green = 8'hFF;
                blue = 8'hFF;
            end
            4'b0110: begin //magenta
                red = 8'hFF;
                green = 8'h00;
                blue = 8'hFF;
            end
            4'b0111: begin //yellow
                red = 8'hFF;
                green = 8'hFF;
                blue = 8'h00;
            end
            4'b1000: begin //gray
                red = 8'h80;
                green = 8'h80;
                blue = 8'h80;
            end
            4'b1001: begin //eminence
                red = 8'h6C;
                green = 8'h30;
                blue = 8'h82;
            end
            4'b1010: begin //pink
                red = 8'hFF;
                green = 8'h00;
                blue = 8'h80;
            end
            4'b1011: begin //orange
                red = 8'hFF;
                green = 8'h80;
                blue = 8'h00;
            end
            4'b1100: begin //purple
                red = 8'h80;
                green = 8'h00;
                blue = 8'hFF;
            end
            4'b1101: begin //cool blue
                red = 8'h00;
                green = 8'h80;
                blue = 8'hFF;
            end
            4'b1110: begin //mint green
                red = 8'h00;
                green = 8'hFF;
                blue = 8'h80;
            end
            4'b1111: begin //lime green
                red = 8'h80;
                green = 8'hFF;
                blue = 8'h00;
            end
            default: begin //default (white)
                red = 8'hFF;
                green = 8'hFF;
                blue = 8'hFF;
            end
        endcase
    end


    always_ff @(posedge clk_in)begin 
        if (rst_in) begin
            in_sprite <= 0;
            red_out <= 0;
            green_out <= 0;
            blue_out <= 0;
        end else begin 
            if (hcount_in <= 100) begin 
                in_sprite <= 1;
                if (hcount_in >= 20 && hcount_in <= 80 && vcount_in >= 20 & vcount_in <= 80) begin //color square
                    red_out <= red;
                    green_out <= green;
                    blue_out <= blue;
                end else if (hcount_in >= 40 && hcount_in <= 60 && vcount_in <= 700 && vcount_in >= 680-(stroke_width*10)) begin //sw indicator
                    red_out <= 8'hB9;
                    green_out <= 8'hB9;
                    blue_out <= 8'hB9;
                end else begin 
                    red_out <= 8'h50;
                    green_out <= 8'h50;
                    blue_out <= 8'h50;
                end
            end else begin 
                in_sprite <= 0;
            end
        end
    end

endmodule

`default_nettype wire