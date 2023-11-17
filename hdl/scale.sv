`timescale 1ns / 1ps
`default_nettype none

module scale(
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  output logic [9:0] scaled_hcount_out,
  output logic [8:0] scaled_vcount_out,
  output logic valid_addr_out
);

  assign valid_addr_out = hcount_in < 1280 && vcount_in <720;
  assign scaled_hcount_out = hcount_in>>1;
  assign scaled_vcount_out = vcount_in>>1;


endmodule


`default_nettype wire

