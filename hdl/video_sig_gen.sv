module video_sig_gen
#(
  parameter ACTIVE_H_PIXELS = 1280,
  parameter H_FRONT_PORCH = 110,
  parameter H_SYNC_WIDTH = 40,
  parameter H_BACK_PORCH = 220,
  parameter ACTIVE_LINES = 720,
  parameter V_FRONT_PORCH = 5,
  parameter V_SYNC_WIDTH = 5,
  parameter V_BACK_PORCH = 20)
(
  input wire clk_pixel_in,
  input wire rst_in,
  output logic [$clog2(TOTAL_PIXELS)-1:0] hcount_out,
  output logic [$clog2(TOTAL_LINES)-1:0] vcount_out,
  output logic vs_out,
  output logic hs_out,
  output logic ad_out,
  output logic nf_out,
  output logic [5:0] fc_out);
 
  localparam TOTAL_PIXELS = ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH;
  localparam TOTAL_LINES = ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH; 

  logic [$clog2(TOTAL_PIXELS)-1:0] pointer;
 
  //your code here
  always_ff @(posedge clk_pixel_in)begin 
    if (rst_in) begin 
        hcount_out <= 0;
        pointer <= 0;
        vcount_out <= 0;
        vs_out <= 0;
        hs_out <= 0;
        nf_out <= 0;
        fc_out <= 0;
        ad_out <= 0;
    end else begin

        //drawing region
        if (pointer < ACTIVE_H_PIXELS && vcount_out < ACTIVE_LINES) begin 
            ad_out <= 1;
        end else begin 
            ad_out <= 0;
        end

        //new frame
        if (pointer == ACTIVE_H_PIXELS && vcount_out == ACTIVE_LINES) begin 
            nf_out <= 1;
            if (fc_out >= 59) begin 
                fc_out <= 0;
            end else begin 
                fc_out <= fc_out + 1;
            end
        end else begin 
            nf_out <= 0;
        end

        //horizontal sync
        if (pointer >= ACTIVE_H_PIXELS + H_FRONT_PORCH && pointer < ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH) begin 
            hs_out <= 1;
        end else begin 
            hs_out <= 0;
        end

        //vertical sync
        if (vcount_out >= ACTIVE_LINES + V_FRONT_PORCH && vcount_out < ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH) begin 
            vs_out <= 1;
        end else begin 
            vs_out <= 0;
        end

        //next pixel 
        if (pointer >= TOTAL_PIXELS-1) begin 
            pointer <= 0;
            if (vcount_out >= TOTAL_LINES-1) begin 
                vcount_out <= 0;
            end else begin 
                vcount_out <= vcount_out +1;
            end
        end else begin 
            pointer <= pointer +1;
        end
        hcount_out <= pointer;
    end
  end
 
endmodule