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
  inout wire [1:0] pmoda,
  input wire [7:0] pmodb,
  output logic SD_CMD,
  output logic SD_CLK,
  input wire SD_CD_N,
  inout wire SD_DQ0,
  inout wire SD_DQ1,
  inout wire SD_DQ2,
  inout wire SD_DQ3
  );

  // Connect switches to LED bank for debugging
  assign led = sw;
  // Shh those rgb LEDs (active high)
  assign rgb1[1:0]= 0;
  assign rgb0[1:0] = 0;

  assign rgb1[2] = ~pmodb[4];
  assign rgb0[2] = ~pmodb[5];

  // System Reset
  logic sys_rst;
  assign sys_rst = btn[0];

  // signals for working with SD card
  logic draw, slide_show, sd_reset;
  assign draw = sw[2];
  assign slide_show = sw[3];

  // Clock Buffer
  logic buffered_clk_100mhz;
  BUFG system_clk_buffer (
    .O(buffered_clk_100mhz),
    .I(clk_100mhz)
  );

  // HDMI Clock
  logic clk_pixel, clk_5x; //clock lines
  logic locked; //locked signal (we'll leave unused but still hook it up)
  //clock manager...creates 74.25 MHz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (
      .reset(0),
      .locked(locked),
      .clk_ref(buffered_clk_100mhz),
      .clk_pixel(clk_pixel),
      .clk_tmds(clk_5x));

  // Signals related to driving the video pipeline
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


  //debounce rotary encoders

  logic rot_a1, rot_b1, rot_a2, rot_b2;

  debouncer #(.CLK_PERIOD_NS(10),
              .DEBOUNCE_TIME_MS(2)) 
              rot_a1_db(.clk_in(clk_pixel),
                  .rst_in(sys_rst),
                  .dirty_in(pmodb[3]),
                  .clean_out(rot_a1));

  debouncer #(.CLK_PERIOD_NS(10),
              .DEBOUNCE_TIME_MS(2))
              rot_b1_db(.clk_in(clk_pixel),
                  .rst_in(sys_rst),
                  .dirty_in(pmodb[2]),
                  .clean_out(rot_b1));

  debouncer #(.CLK_PERIOD_NS(10),
              .DEBOUNCE_TIME_MS(2)) 
              rot_a2_db(.clk_in(clk_pixel),
                  .rst_in(sys_rst),
                  .dirty_in(pmodb[7]),
                  .clean_out(rot_a2));

  debouncer #(.CLK_PERIOD_NS(10),
              .DEBOUNCE_TIME_MS(2))
              rot_b2_db(.clk_in(clk_pixel),
                  .rst_in(sys_rst),
                  .dirty_in(pmodb[6]),
                  .clean_out(rot_b2));


  
  user_input2 user_input (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .pos_con_in(pos_control),
    .col_con_in(col_control),
    .sw_con_in(sw_control),
    .rot_a1_in(rot_a1),
    .rot_b1_in(rot_b1),
    .rot_a2_in(rot_a2),
    .rot_b2_in(rot_b2),
    .rot_but1(pmodb[5]),
    .rot_but2(pmodb[4]),
    .nf_in(new_frame),
    .cursor_loc_x(cursor_loc_x),
    .cursor_loc_y(cursor_loc_y),
    .cursor_color(cursor_color),
    .stroke_width(stroke_width)
  );

  //gui_sprite output
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
    .x_in1(cursor_loc_x),
    .x_in2(comm_x_loc),
    .y_in1(cursor_loc_y),
    .y_in2(comm_y_loc),
    .hcount_in(hcount_scaled),
    .vcount_in(vcount_scaled),
    .color_in1(cursor_color),
    .color_in2(comm_color), 
    .sw_in1(stroke_width),
    .sw_in2(comm_sw),
    .nf_in(new_frame),
    .red_out(fb_red),
    .green_out(fb_green),
    .blue_out(fb_blue),
    .slide_show(slide_show),
    .draw(draw),
    .clk_100mhz(clk_100mhz),
    .sd_cd(SD_CD_N), 
    .sd_dat({SD_DQ3, SD_DQ2, SD_DQ1, SD_DQ0}),
    .sd_reset(sd_reset), 
    .sd_sck(SD_CLK), 
    .sd_cmd(SD_CMD) 
  );


  //combinational logic to combine all parts

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




  // TMDS Pipeline
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

  // COMMUNICATION MODULE
  logic diff_data_out, diff_data_in, diff_in_sync, new_code_out, io_sel;
  logic [25:0] code_out;
  // Have the line float high by default.
  PULLUP pullup_p (.O(pmoda[0]));
  PULLDOWN pulldown_n (.O(pmoda[1]));
  // Transmit the cursor location on every new frame.
  IOBUFDS diff_io_buf (
    .IO(pmoda[0]),
    .IOB(pmoda[1]),
    .O(diff_data_in),
    .I(diff_data_out),
    .T(!io_sel)
  );
  diff_io diff_io (
      .clk_in(buffered_clk_100mhz),
      .rst_in(sys_rst),
      .trigger_in(new_frame),
      .data_in({cursor_loc_x, cursor_loc_y, cursor_color, stroke_width}),
      .diff_data_in(diff_in_sync),
      .diff_data_out(diff_data_out),
      .io_sel(io_sel),
      .new_code_out(new_code_out),
      .code_out(code_out)
  );
  synchronizer s_rx (
      .clk_in(buffered_clk_100mhz),
      .rst_in(sys_rst),
      .us_in(diff_data_in),
      .s_out(diff_in_sync)
  );
  logic [9:0] comm_x_loc;
  logic [8:0] comm_y_loc;
  logic [3:0] comm_color;
  logic [2:0] comm_sw;
  always_ff @(posedge buffered_clk_100mhz) begin
    if (new_code_out) begin
      comm_x_loc <= code_out[25:16];
      comm_y_loc <= code_out[15:7];
      comm_color <= code_out[6:3];
      comm_sw <= code_out[2:0];
    end
  end

endmodule // top_level
`default_nettype wire
