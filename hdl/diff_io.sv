`timescale 1ns / 1ps
`default_nettype none
module diff_io (
    input wire clk_in,
    input wire rst_in,
    input wire trigger_in,
    input wire [25:0] data_in,
    input wire diff_data_in,
    output logic diff_data_out,
    output logic io_sel, // High when transmitting, low when receiving
    output logic new_code_out,
    output logic [25:0] code_out
);
    
    // Module variables
    logic message_waiting, tx_trigger;
    logic [25:0] current_data;
    logic [1:0] tx_state;
    logic [2:0] rx_state; // state of the receiving module
    typedef enum {IDLE = 0, RECV = 1, TRANS = 2} io_state;
    io_state state;

    // Transmission module
    diff_tx dtx (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .trigger_in(tx_trigger),
        .data_in(data_in),
        .data_out(diff_data_out),
        .state_out(tx_state)
    );

    // Receiving module
    diff_rx drx (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .data_in(io_sel ? 1'b1 : diff_data_in),
        .code_out(code_out),
        .new_code_out(new_code_out),
        .state_out(rx_state)
    );

    // IO Logic
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            io_sel <= 1'b0;
            message_waiting <= 1'b0;
            tx_trigger <= 1'b0;
        end else begin
            case (state)
                // RECV - A message is being received! Wait until that's done.
                RECV : begin
                    // When the receiver goes back to IDLE, the message is done.
                    if (rx_state == 0) begin
                        // If there's a message waiting, go ahead and send it.
                        if (message_waiting) begin
                            state <= TRANS;
                            io_sel <= 1'b1;
                            tx_trigger <= 1'b1;
                        // Otherwise, head back to IDLE.
                        end else begin
                            state <= IDLE;
                        end
                    // Otherwise, just keep waiting I guess.
                    end else begin
                        io_sel <= 1'b0;
                        // If a message comes in while we're reading this one, save it for later.
                        if (trigger_in) begin
                            current_data <= data_in;
                            message_waiting = 1'b1;
                            tx_trigger <= 1'b0;
                        end
                    end
                end
                // TRANS - We're sending a message!
                TRANS : begin
                    tx_trigger <= 1'b0;
                    message_waiting <= 1'b0;
                    // Once the transmitter goes back to IDLE, the message is done.
                    // Head on back to IDLE.
                    if (!message_waiting && tx_state == 0) begin
                        state <= IDLE;
                        io_sel <= 1'b0;
                    end else begin
                        io_sel <= 1'b1;
                    end
                end
                // IDLE - Chill in a receiving state
                default : begin
                    // If a transmission is triggered, save the input data.
                    if (trigger_in) begin
                        current_data <= data_in;
                        // If the receiver isn't busy, go ahead and start transmitting said message.
                        if (rx_state == 0) begin
                            state <= TRANS;
                            message_waiting <= 1'b1;
                            io_sel <= 1'b1;
                            tx_trigger <= 1'b1;
                        // Otherwise, we'll wait to send it.
                        end else begin
                            message_waiting = 1'b1;
                            io_sel <= 1'b0;
                            tx_trigger <= 1'b0;
                        end
                    end
                    // If the receiver leaves the IDLE state, there's a message in progress.
                    // Head on over to the RECV state.
                    if (rx_state != 0) begin
                        state <= RECV;
                        io_sel <= 1'b0;
                        tx_trigger <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule
`default_nettype none