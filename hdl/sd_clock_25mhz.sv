`timescale 1ns / 1ps
`default_nettype none
module sd_clock_25mhz(
    input wire sys_rst,
    input wire clk,
    output logic clk_25mhz
);
    // generate 25 mhz clock for sd_controller 
    logic [1:0] clk_count;
    always_ff @(posedge clk) begin
        if (sys_rst) begin
            clk_count <= 0;
            clk_25mhz <= 0;
        end else begin
            if (clk_count == 3) begin
                clk_25mhz <= 1;
                clk_count <= 0;
            end else begin
                clk_25mhz <= 0;
                clk_count <= clk_count + 1;
            end
        end
    end
endmodule
`default_nettype wire
