`timescale 1ns / 1ps
`default_nettype none
module diff_tx
    #( parameter DATA_PERIOD = 20, parameter HALF_DATA_PERIOD = 10, parameter QUARTER_DATA_PERIOD = 5, parameter THREE_QUARTER_DATA_PERIOD = 15 )
    ( input wire clk_in,
      input wire rst_in,
      input wire trigger_in,
      input wire [25:0] data_in,
      output logic data_out );

    // Module variables
    logic [$clog2(DATA_PERIOD)-1:0] counter;
    logic [25:0] current_data;
    logic [4:0] data_index;
    typedef enum {IDLE = 0, SYNC = 1, ZERO = 2, ONE = 3} tx_state;
    tx_state state;
    
    always_ff @(posedge clk_in) begin
        // Transition back to IDLE on system reset
        if (rst_in) begin
            state <= IDLE;
            counter <= 0;
            data_index <= 5'd25;
            data_out <= 1'b1;
        end else begin
            case (state)
                // Sync Period - Duty cycle of 50%
                SYNC : begin
                    // Hold low on first half
                    if (counter < HALF_DATA_PERIOD) begin
                        data_out <= 1'b0;
                        counter <= counter + 1;
                    // Once the end is reached, determine whether we're at the start or end of the message
                    end else if (counter >= DATA_PERIOD) begin
                        // If we're at the end, raise the line and head back to IDLE.
                        if (data_index == 5'd31) begin
                            state <= IDLE;
                            data_out <= 1'b1;
                            counter <= 0;
                            data_index <= 5'd25;
                        // If we're at the start, lower the line and send the first bit (MSB).
                        end else begin
                            data_out <= 1'b0;
                            counter <= 1;
                            state <= current_data[25] ? ONE : ZERO;
                            data_index <= 5'd24;
                        end
                    // Hold high on the second half
                    end else begin
                        data_out <= 1'b1;
                        counter <= counter + 1;
                    end
                end
                // Zero Bit - Duty cycle of 75%
                ZERO : begin
                    // Hold low on first quarter
                    if (counter < QUARTER_DATA_PERIOD) begin
                        data_out <= 1'b0;
                        counter <= counter + 1;
                    // At the end of sending a zero, send the next bit or end the message
                    end else if (counter >= DATA_PERIOD) begin
                        // If we're at the end, drop the line and SYNC again
                        if (data_index == 5'd31) begin
                            state <= SYNC;
                        // Otherwise, drop the line and send the next bit
                        end else begin
                            state <= current_data[data_index] ? ONE : ZERO;
                            data_index <= data_index - 1;
                        end
                        data_out <= 1'b0;
                        counter <= 1;
                    // Hold high on last three quarters
                    end else begin
                        data_out <= 1'b1;
                        counter <= counter + 1;
                    end
                end
                // One Bit - Duty cycle of 25%
                ONE : begin
                    // Hold low on first three quarters
                    if (counter < THREE_QUARTER_DATA_PERIOD) begin
                        data_out <= 1'b0;
                        counter <= counter + 1;
                    // At the end of sending a one, send the next bit or end the message
                    end else if (counter >= DATA_PERIOD) begin
                        // If we're at the end, drop the line and SYNC again
                        if (data_index == 5'd31) begin
                            state <= SYNC;
                        // Otherwise, drop the line and send the next bit
                        end else begin
                            state <= current_data[data_index] ? ONE : ZERO;
                            data_index <= data_index - 1;
                        end
                        data_out <= 1'b0;
                        counter <= 1;
                    // Hold high on last quarter
                    end else begin
                        data_out <= 1'b1;
                        counter <= counter + 1;
                    end
                end
                // IDLE - Hold output high until there's new data to send
                default: begin
                    data_out <= 1'b1;
                    // Drop output low when there's new data to send and start the
                    // sync period.
                    if (trigger_in) begin
                        state <= SYNC;
                        counter <= 1;
                        current_data <= data_in;
                        data_index <= 5'd25;
                        data_out <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule
`default_nettype none