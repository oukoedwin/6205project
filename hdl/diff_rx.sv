`timescale 1ns / 1ps
`default_nettype none
module diff_rx
    #( parameter DATA_PERIOD = 20, parameter HALF_DATA_PERIOD = 10, parameter QUARTER_DATA_PERIOD = 5, parameter THREE_QUARTER_DATA_PERIOD = 15, parameter MARGIN = 2 )
    ( input wire clk_in,
      input wire rst_in,
      input wire data_in,
      output logic [25:0] code_out,
      output logic new_code_out );

    // Module variables
    logic [$clog2(DATA_PERIOD + MARGIN)-1:0] counter;
    logic [25:0] data_buffer;
    logic [4:0] data_buffer_index;
    typedef enum {IDLE = 0, SL = 1, SH = 2, DL = 3, DH0 = 4, DH1 = 5, DONE = 6} rx_state;
    rx_state state;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            new_code_out <= 0;
            code_out <= 0;
            counter <= 0;
            data_buffer <= 0;
            data_buffer_index <= 5'd25;
        end else begin
            case (state)
                // SL - Receive the first half of the sync period.
                SL : begin
                    // If the line raises, ensure that it was the right length. If it is,
                    // head over to SH.
                    if (data_in) begin
                        if (counter >= (HALF_DATA_PERIOD - MARGIN) && counter <= (HALF_DATA_PERIOD + MARGIN)) begin
                            state <= SH;
                            counter <= 1;
                        end else begin
                            state <= IDLE;
                        end
                    // If the line is low too long, something is wrong.
                    end else if (counter > HALF_DATA_PERIOD + MARGIN) begin
                        state <= IDLE;
                    // Otherwise, just keep waiting.
                    end else begin
                        counter <= counter + 1;
                    end                    
                end
                // SH - Receive the second half of the sync period.
                SH : begin
                    // If the line drops, ensure that it was the right length. If it is,
                    // head over to DL.
                    if (!data_in) begin
                        if (counter >= (HALF_DATA_PERIOD - MARGIN) && counter <= (HALF_DATA_PERIOD + MARGIN)) begin
                            state <= DL;
                            counter <= 1;
                        end else begin
                            state <= IDLE;
                        end
                    // If the line is high too long, something is wrong.
                    end else if (counter > HALF_DATA_PERIOD + MARGIN) begin
                        state <= IDLE;
                    // Otherwise, just keep waiting.
                    end else begin
                        counter <= counter + 1;
                    end
                end
                // DL - Receive the low part of the next bit.
                DL : begin
                    // If the line raises, check the length. Head to DH0 or DH1 (or IDLE? if things
                    // end up being wrong?) as appropriate.
                    if (data_in) begin
                        if (counter >= (QUARTER_DATA_PERIOD - MARGIN) && counter <= (QUARTER_DATA_PERIOD + MARGIN)) begin
                            state <= DH0;
                            counter <= 1;
                        end else if (counter >= (THREE_QUARTER_DATA_PERIOD - MARGIN) && counter <= (THREE_QUARTER_DATA_PERIOD + MARGIN)) begin
                            state <= DH1;
                            counter <= 1;
                        end else begin
                            state <= IDLE;
                        end
                    // If the line has been low too long, something is wrong.
                    end else if (counter > THREE_QUARTER_DATA_PERIOD + MARGIN) begin
                        state <= IDLE;
                    // Otherwise, just keep waiting.
                    end else begin
                        counter <= counter + 1;
                    end
                end
                // DH0 - Receive the high part of the 0 bit.
                DH0 : begin
                    // If the line goes low, check the length. If this is the last bit in the message,
                    // output it. Otherwise, head back to DL and wait for the next bit.
                    if (!data_in) begin
                        if (counter >= (THREE_QUARTER_DATA_PERIOD - MARGIN) && counter <= (THREE_QUARTER_DATA_PERIOD + MARGIN)) begin
                            data_buffer[data_buffer_index] <= 1'b0;
                            if (data_buffer_index == 0) begin
                                state <= DONE;
                            end else begin
                                data_buffer_index <= data_buffer_index - 1;
                                state <= DL;
                            end
                            counter <= 1;
                        end else begin
                            state <= IDLE;
                        end
                    // If the line has been high too long, something is wrong.
                    end else if (counter > THREE_QUARTER_DATA_PERIOD + MARGIN) begin
                        state <= IDLE;
                    // Otherwise, just keep waiting.
                    end else begin
                        counter <= counter + 1;
                    end
                end
                // DH1 - Receive the high part of the 1 bit.
                DH1 : begin
                    // If the line goes low, check the length. If this is the last bit in the message,
                    // output it. Otherwise, head back to DL and wait for the next bit.
                    if (!data_in) begin
                        if (counter >= (QUARTER_DATA_PERIOD - MARGIN) && counter <= (QUARTER_DATA_PERIOD + MARGIN)) begin
                            data_buffer[data_buffer_index] <= 1'b1;
                            if (data_buffer_index == 0) begin
                                state <= DONE;
                            end else begin
                                data_buffer_index <= data_buffer_index - 1;
                                state <= DL;
                            end
                            counter <= 1;
                        end else begin
                            state <= IDLE;
                        end
                    // If the line has been high too long, something is wrong.
                    end else if (counter > QUARTER_DATA_PERIOD + MARGIN) begin
                        state <= IDLE;
                    // Otherwise, just keep waiting.
                    end else begin
                        counter <= counter + 1;
                    end
                end
                // DONE - Receive the last part of the end sync period. (i.e. just wait for the line
                // to raise again)
                DONE : begin
                    if (data_in) begin
                        state <= IDLE;
                        new_code_out <= 1'b1;
                        code_out <= data_buffer;
                    end
                end
                // IDLE - Wait until the line drops low to start receiving the message.
                default : begin
                    // Start processing the sync period.
                    if (!data_in) begin
                        data_buffer_index <= 5'd25;
                        counter <= 1;
                        state <= SL;
                    end
                    // Otherwise, just wait around I guess.
                    new_code_out <= 0;
                end
            endcase
        end
    end

endmodule
`default_nettype none