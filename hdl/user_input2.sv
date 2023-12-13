`timescale 1ns / 1ps
`default_nettype none

module user_input2(
    input wire clk_in,
    input wire rst_in,
    input wire [3:0] pos_con_in,
    input wire col_con_in,
    input wire sw_con_in,
    input wire nf_in,
    input wire rot_a1_in, rot_b1_in, rot_a2_in, rot_b2_in,
    input wire rot_but1, rot_but2,
    output logic [9:0] cursor_loc_x,
    output logic [8:0] cursor_loc_y,
    output logic [3:0] cursor_color,
    output logic [2:0] stroke_width
);

    //switch logic move amount
    localparam MOVE_AMT = 1;

    logic prev_col_in;
    logic prev_sw_in;

    logic rot_a1_old, rot_b1_old, rot_a2_old, rot_b2_old;



    always_ff @(posedge clk_in)begin 
        if (rst_in) begin 
            cursor_loc_x <= 320;
            cursor_loc_y <= 180;
            cursor_color <= 0;
            stroke_width <= 0;
        end else begin 

            // ROTARY ENCODER LOGIC
            rot_a1_old <= rot_a1_in;
            rot_b1_old <= rot_b1_in;
            rot_a2_old <= rot_a2_in;
            rot_b2_old <= rot_b2_in;


            if (rot_but1) begin //drawing with rotary encoder 1
                if (rot_a1_in != rot_a1_old) begin //knob rotating
                    if (rot_b1_in != rot_a1_in) begin // a changed first - CW
                        if (cursor_loc_x > 638) begin 
                            cursor_loc_x <= 638;
                        end else begin 
                            cursor_loc_x <= cursor_loc_x +1;
                        end
                    end else begin //b changed first - CCW
                        if (cursor_loc_x < 1) begin 
                            cursor_loc_x <= 1;
                        end else begin 
                            cursor_loc_x <= cursor_loc_x -1;
                        end
                    end
                end
            end else begin //changing sw with rotary encoder 1
                if (rot_a1_in != rot_a1_old) begin //knob rotating
                    if (rot_b1_in != rot_a1_in) begin // a changed first - CW
                        if(stroke_width == 3'b111) begin 
                            stroke_width <= 3'b111;
                        end else begin
                            stroke_width <= stroke_width + 1;
                        end
                    end else begin //b changed first - CCW
                        if(stroke_width == 3'b000) begin 
                            stroke_width <= 3'b000;
                        end else begin 
                            stroke_width <= stroke_width - 1;
                        end
                    end
                end
            end

            if (rot_but2) begin //drawing with rotary encoder 2
                if (rot_a2_in != rot_a2_old) begin //knob rotating
                    if (rot_b2_in != rot_a2_in) begin // a changed first - CW
                        if (cursor_loc_y > 359) begin 
                            cursor_loc_y <= 359;
                        end else begin 
                            cursor_loc_y <= cursor_loc_y +1;
                        end
                    end else begin //b changed first - CCW
                        if (cursor_loc_y < 1) begin 
                            cursor_loc_y <= 1;
                        end else begin 
                            cursor_loc_y <= cursor_loc_y -1;
                        end
                    end
                end
            end else begin //changing color with rotary encoder 2
                if (rot_a2_in != rot_a2_old) begin //knob rotating
                    if (rot_b2_in != rot_a2_in) begin // a changed first - CW
                        if(cursor_color == 4'b1111) begin 
                            cursor_color <= 4'b1111;
                        end else begin
                            cursor_color <= cursor_color + 1;
                        end
                    end else begin //b changed first - CCW
                        if(cursor_color == 4'b0000) begin 
                            cursor_color <= 4'b0000;
                        end else begin 
                            cursor_color <= cursor_color - 1;
                        end
                    end
                end
            end
            

            //SWITCH LOGIC
            if (nf_in) begin
                //cursor up
                if (pos_con_in[0]) begin 
                    if ((cursor_loc_y) <= MOVE_AMT) begin
                        cursor_loc_y <= 0;
                    end else begin 
                        cursor_loc_y <= cursor_loc_y - MOVE_AMT;
                    end
                end
                //cursor down
                if (pos_con_in[1]) begin 
                    if (cursor_loc_y+MOVE_AMT > 359) begin
                        cursor_loc_y <= 359;
                    end else begin 
                        cursor_loc_y <= cursor_loc_y + MOVE_AMT;
                    end
                end
                //cursor right
                if (pos_con_in[2]) begin 
                    if (cursor_loc_x+MOVE_AMT > 638) begin
                        cursor_loc_x <= 638;
                    end else begin 
                        cursor_loc_x <= cursor_loc_x + MOVE_AMT;
                    end
                end
                //cursor left
                if (pos_con_in[3]) begin 
                    if (cursor_loc_x <= MOVE_AMT) begin 
                        cursor_loc_x <= 0;
                    end else begin 
                        cursor_loc_x <= cursor_loc_x - MOVE_AMT;
                    end
                end
            end
            //color button logic
                if (!prev_col_in && col_con_in) begin
                    if(cursor_color == 4'b1111) begin 
                        cursor_color <= 0;
                    end
                    cursor_color <= cursor_color + 1;
                end
                prev_col_in <= col_con_in;

                //stroke width button logic
                if (!prev_sw_in && sw_con_in) begin
                    if(stroke_width == 3'b111) begin 
                        stroke_width <= 0;
                    end
                    stroke_width <= stroke_width + 1;
                end
                prev_sw_in <= sw_con_in;

        end
    end

endmodule //user_input2
`default_nettype wire
