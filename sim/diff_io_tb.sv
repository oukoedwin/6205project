`timescale 1ns / 1ps
`default_nettype none

module diff_io_tb();
    logic clk_in, rst_in, trigger_in;
    logic [25:0] data_in, code_out, tx_data_in, tx_code_out;
    logic new_code_out;
    logic diff_data_in, diff_data_out, io_sel;
    logic tx_trigger, tx_io_sel, tx_new_code_out;

    diff_io diff_io_2 (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .trigger_in(tx_trigger),
        .data_in(tx_data_in),
        .diff_data_in(diff_data_out),
        .diff_data_out(diff_data_in),
        .io_sel(tx_io_sel),
        .new_code_out(tx_new_code_out),
        .code_out(tx_code_out)
    );
    
    diff_io diff_io_1 (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .trigger_in(trigger_in),
        .data_in(data_in),
        .diff_data_in(diff_data_in),
        .diff_data_out(diff_data_out),
        .io_sel(io_sel),
        .new_code_out(new_code_out),
        .code_out(code_out)
    );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    initial begin
        $dumpfile("diff_io_tb.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, diff_io_tb);
        $display("Starting Sim");
        clk_in = 0;
        rst_in = 0;
        trigger_in = 0;

        #10;
        rst_in = 1;
        #10;
        rst_in = 0;

        // TEST CASE #1 - Attempted transmit while busy
        tx_data_in = 26'b00101111100011001000011001;
        tx_trigger = 1;
        #10;
        tx_trigger = 0;
        #3000;
        data_in = 26'b10101011011011111011101111;
        trigger_in = 1;
        #10;
        trigger_in = 0;
        #9000;

        $display("Finishing Sim");
        $finish;
    end
endmodule
`default_nettype wire