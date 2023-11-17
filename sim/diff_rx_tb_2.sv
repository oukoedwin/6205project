`timescale 1ns / 1ps
`default_nettype none

module diff_tx_tb_2();
    logic clk_in_t, clk_in_r, rst_in, trigger_in;
    logic [25:0] data_in, code_out;
    logic data_out, new_code_out;

    diff_tx #(.DATA_PERIOD(20)) dtx (
        .clk_in(clk_in_t),
        .rst_in(rst_in),
        .trigger_in(trigger_in),
        .data_in(data_in),
        .data_out(data_out)
    );

    diff_rx #(.DATA_PERIOD(20), .MARGIN(2)) drx (
        .clk_in(clk_in_r),
        .rst_in(rst_in),
        .data_in(data_out),
        .code_out(code_out),
        .new_code_out(new_code_out)
    );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in_t = !clk_in_t;
        clk_in_r = !clk_in_r;
    end
    initial begin
        $dumpfile("diff_rx_tb_2.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, diff_tx_tb_2);
        $display("Starting Sim");
        clk_in_t = 0;
        clk_in_r = 1;
        rst_in = 0;
        trigger_in = 0;

        // TEST CASE #1 - 00101111100011001000011001
        data_in = 26'b00101111100011001000011001;
        #10;
        rst_in = 1;
        #10;
        rst_in = 0;
        #50;
        trigger_in = 1;
        #10;
        trigger_in = 0;
        $display("data_in = %26b", data_in);
        #6000;

        // TEST CASE #2 - 10101011011011111011101111
        data_in = 26'b10101011011011111011101111;
        #10;
        rst_in = 1;
        #10;
        rst_in = 0;
        #50;
        trigger_in = 1;
        #10;
        trigger_in = 0;
        $display("data_in = %26b", data_in);
        #6000;

        // TEST CASE #3 - 00000000000000000000000000
        data_in = 26'b00000000000000000000000000;
        #10;
        rst_in = 1;
        #10;
        rst_in = 0;
        #50;
        trigger_in = 1;
        #10;
        trigger_in = 0;
        $display("data_in = %26b", data_in);
        #6000;

        // TEST CASE #4 - 11111111111111111111111111
        data_in = 26'b11111111111111111111111111;
        #10;
        rst_in = 1;
        #10;
        rst_in = 0;
        #50;
        trigger_in = 1;
        #10;
        trigger_in = 0;
        $display("data_in = %26b", data_in);
        #6000;

        // TEST CASE #5 - 10101010101010101010101010
        data_in = 26'b10101010101010101010101010;
        #10;
        rst_in = 1;
        #10;
        rst_in = 0;
        #50;
        trigger_in = 1;
        #10;
        trigger_in = 0;
        $display("data_in = %26b", data_in);
        // psst. test that a random trigger in the middle doesn't break things
        #2000;
        trigger_in = 1;
        #10;
        trigger_in = 0;
        #4000;

        $display("Finishing Sim");
        $finish;
    end
endmodule
`default_nettype wire