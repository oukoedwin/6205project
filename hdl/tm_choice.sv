`timescale 1ns / 1ps
`default_nettype none
module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );
  

  //your code here, friend
  
  logic [3:0] num_ones;
  
  always_comb begin
    num_ones = 0;
    for (integer i = 0; i < 8; i=i+1) begin 
      if (data_in[i] == 1) num_ones = num_ones+1;
    end
    
    if((num_ones > 4) || (num_ones == 4 && data_in[0] == 0)) begin 
      qm_out[0] = data_in[0];
      qm_out[1] = qm_out[0] ^~ data_in[1];
      qm_out[2] = qm_out[1] ^~ data_in[2];
      qm_out[3] = qm_out[2] ^~ data_in[3];
      qm_out[4] = qm_out[3] ^~ data_in[4];
      qm_out[5] = qm_out[4] ^~ data_in[5];
      qm_out[6] = qm_out[5] ^~ data_in[6];
      qm_out[7] = qm_out[6] ^~ data_in[7];
      qm_out[8] = 0;
    end else begin
      qm_out[0] = data_in[0];
      qm_out[1] = qm_out[0] ^ data_in[1];
      qm_out[2] = qm_out[1] ^ data_in[2];
      qm_out[3] = qm_out[2] ^ data_in[3];
      qm_out[4] = qm_out[3] ^ data_in[4];
      qm_out[5] = qm_out[4] ^ data_in[5];
      qm_out[6] = qm_out[5] ^ data_in[6];
      qm_out[7] = qm_out[6] ^ data_in[7];
      qm_out[8] = 1;
    end
    
  end



endmodule //end tm_choice
`default_nettype wire
