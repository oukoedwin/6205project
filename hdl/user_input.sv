module user_input(
    input wire clk_in,
    input wire rst_in,
    input wire [3:0] pos_con_in,
    input wire col_con_in,
    input wire sw_con_in,
    output logic [9:0] cursor_loc_x,
    output logic [8:0] cursor_loc_y,
    output logic [3:0] cursor_color,
    output logic [2:0] stroke_width
);

    localparam MOVE_AMT = 5;

    logic prev_col_in;
    logic prev_sw_in;



    always_ff @(posedge clk_in)begin 
        if (rst_in) begin 
            cursor_loc_x <= 0;
            cursor_loc_y <= 0;
            cursor_color <= 0;
            stroke_width <= 0;
        end else begin 
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
                if (cursor_loc_x+MOVE_AMT > 639) begin
                    cursor_loc_x <= 639;
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
                if(stroke_width == 4'b111) begin 
                    stroke_width <= 0;
                end
                stroke_width <= stroke_width + 1;
            end
            prev_sw_in <= sw_con_in;

        end
    end

endmodule //user_input