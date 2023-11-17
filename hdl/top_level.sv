`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic [2:0] hdmi_tx_p, //hdmi output signals (blue, green, red)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives)
  output logic hdmi_clk_p, hdmi_clk_n, //differential hdmi clock
  output logic [6:0] ss0_c,
  output logic [6:0] ss1_c,
  output logic [3:0] ss0_an,
  output logic [3:0] ss1_an,
  input wire [7:0] pmoda,
  input wire [2:0] pmodb,
  output logic pmodbclk,
  output logic pmodblock
  );
  assign led = sw; //for debugging
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;

  //have btnd control system reset
  logic sys_rst;
  assign sys_rst = btn[0];

  logic clk_pixel, clk_5x; //clock lines
  logic locked; //locked signal (we'll leave unused but still hook it up)
 
  //clock manager...creates 74.25 MHz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (
      .reset(0),
      .locked(locked),
      .clk_ref(clk_100mhz),
      .clk_pixel(clk_pixel),
      .clk_tmds(clk_5x));

  //Signals related to driving the video pipeline
  logic [10:0] hcount; //horizontal count
  logic [9:0] vcount; //vertical count
  logic vert_sync; //vertical sync signal
  logic hor_sync; //horizontal sync signal
  logic active_draw; //active draw signal
  logic new_frame; //new frame (use this to trigger center of mass calculations)
  logic [5:0] frame_count; //current frame

  logic [9:0] hcount_scaled;
  logic [8:0] vcount_scaled;
  logic valid_addr_scaled;

  video_sig_gen mvg(
      .clk_pixel_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_out(hcount),
      .vcount_out(vcount),
      .vs_out(vert_sync),
      .hs_out(hor_sync),
      .ad_out(active_draw),
      .nf_out(new_frame),
      .fc_out(frame_count));

    scale(
    .hcount_in(hcount),
    .vcount_in(vcount),
    .scaled_hcount_out(hcount_scaled),
    .scaled_vcount_out(vcount_scaled),
    .valid_addr_out(valid_addr_scaled)
  );

  

  logic [3:0] pos_control;
  logic col_control;
  logic sw_control;
  assign pos_control = {sw[15:14],sw[1:0]};
  assign col_control = btn[1];
  assign sw_control = btn[2];

  logic [9:0] cursor_loc_x;
  logic [8:0] cursor_loc_y;
  logic [3:0] cursor_color;
  logic [2:0] stroke_width;



  user_input user_input (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .pos_con_in(pos_control),
    .col_con_in(col_control),
    .sw_con_in(sw_control),
    .nf_in(new_frame),
    .cursor_loc_x(cursor_loc_x),
    .cursor_loc_y(cursor_loc_y),
    .cursor_color(cursor_color),
    .stroke_width(stroke_width)
  );

  //gui_sprite output:
  logic [7:0] gui_red, gui_green, gui_blue;
  logic in_sprite;

  gui_sprite gui_sprite (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .cursor_color(cursor_color),
    .stroke_width(stroke_width),
    .hcount_in(hcount),
    .vcount_in(vcount),
    .red_out(gui_red),
    .green_out(gui_green),
    .blue_out(gui_blue),
    .in_sprite(in_sprite)
  );


  logic [7:0] fb_red, fb_green, fb_blue;


  frame_buffer canvas (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .x_in(cursor_loc_x),
    .y_in(cursor_loc_y),
    .hcount_in(hcount_scaled),
    .vcount_in(vcount_scaled),
    .color_in(cursor_color),
    .sw_in(stroke_width),
    .nf_in(new_frame),
    .red_out(fb_red),
    .green_out(fb_green),
    .blue_out(fb_blue)
  );

  logic [7:0] final_red, final_green, final_blue;

  always_comb begin
    if (in_sprite) begin 
        final_red = gui_red;
        final_blue = gui_blue;
        final_green = gui_green;
    end else if (hcount_scaled == cursor_loc_x || vcount_scaled == cursor_loc_y) begin 
        final_red = 8'h00;
        final_blue = 8'hFF;
        final_green = 8'h80;
    end else begin 
        final_red = fb_red;
        final_blue = fb_blue;
        final_green = fb_green;
        
    end
  end




  logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
  logic tmds_signal [2:0]; //output of each TMDS serializer!
 
  //three tmds_encoders (blue, green, red)
 
  tmds_encoder tmds_red(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(final_red),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[2]));

  tmds_encoder tmds_green(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(final_green),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[1]));

  tmds_encoder tmds_blue(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(final_blue),
      .control_in({vert_sync,hor_sync}),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[0]));
 
  //three tmds_serializers (blue, green, red):
  //MISSING: two more serializers for the green and blue tmds signals.
  tmds_serializer red_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[2]),
      .tmds_out(tmds_signal[2]));
  
  tmds_serializer green_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[1]),
      .tmds_out(tmds_signal[1]));

  tmds_serializer blue_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[0]),
      .tmds_out(tmds_signal[0]));
 
  //output buffers generating differential signals:
  //three for the r,g,b signals and one that is at the pixel clock rate
  //the HDMI receivers use recover logic coupled with the control signals asserted
  //during blanking and sync periods to synchronize their faster bit clocks off
  //of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
  //the slower 74.25 MHz clock)
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));


endmodule // top_level
`default_nettype wire
