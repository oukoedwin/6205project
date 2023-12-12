`timescale 1ns / 1ps
`default_nettype none

module frame_buffer(
    input wire pixel_clk_in,
    input wire clk_100mhz, 
    input wire sd_cd,
    input wire rst_in,
    input wire slide_show, 
    input wire draw, 
    inout wire [3:0] sd_dat, 
    output logic sd_reset,
    output logic sd_sck,
    output logic sd_cmd, 
    input wire [9:0] x_in1, x_in2, hcount_in,
    input wire [8:0] y_in1, y_in2, vcount_in,
    input wire [3:0] color_in1, color_in2,
    input wire [2:0] sw_in1, sw_in2,
    input wire nf_in,
    output logic [7:0] red_out,
    output logic [7:0] green_out,
    output logic [7:0] blue_out
);
    logic [3:0] doutb;

    logic [$clog2(360*640)-1:0] input_addra;
    logic [3:0] input_dina, output_douta; 
    logic input_wea; 
    logic input_web;

    logic [$clog2(360*640)-1:0] addr;

    assign addr = hcount_in + 640*vcount_in;

    logic [$clog2(360*640)-1:0] sd_buffer_index; // current index in the buffer that is being read from or written to from the SD card
    logic [31:0] index_to_write_next_sector; // index in SD card where the next byte should be written to
    localparam SECTOR_SIZE = 512; // sector size in bytes
    // each image takes (640*360)/512 = 450 sectors
    localparam IMAGE_SIZE = 640 * 360;
    logic prev_draw;
    logic [31:0] cycle_count;
    logic mem_to_buffer_wr; // whether to enable buffer port to be written with data from SD memory
    logic [7:0] memout_bin; // data from SD memory to be written to buffer
    logic [7:0] bout_memin; // data from buffer to be written to SD memory
    typedef enum {IDLE=1, SLIDE_SHOW_SECTOR=2, SLIDE_SHOW_NEW_SECTOR=3, SLIDE_SHOW_NEXT_IMAGE=4, DRAWING=5, SAVING_SECTOR=6, FINISHED_SAVING_SECTOR=7} states;
    states state;
    // sd_controller inputs
    logic rd;                   // read enable
    logic wr;                   // write enable
    logic [7:0] din;            // data to sd card
    logic [31:0] sd_addr;          // starting address for read/write operation
    // sd_controller outputs
    logic ready;                // high when ready for new read/write operation
    logic [7:0] dout;           // data from sd card
    logic byte_available;       // high when byte available for read
    logic ready_for_next_byte;  // high when ready for new byte to be written
    logic prev_byte_available, prev_ready_for_next_byte;
    logic clk_25mhz;
    logic write_inc;

    assign sd_dat[2:1] = 2'b11;
    sd_clock_25mhz sd_clk(.sys_rst(rst_in), .clk(clk_100mhz), .clk_25mhz(clk_25mhz));

    sd_controller sd(.reset(rst_in), .clk(clk_25mhz), .cs(sd_dat[3]), .mosi(sd_cmd), 
                     .miso(sd_dat[0]), .sclk(sd_sck), .ready(ready), .address(sd_addr),
                     .rd(rd), .dout(dout), .byte_available(byte_available),
                     .wr(wr), .din(din), .ready_for_next_byte(ready_for_next_byte)); 

    
    //Logic to check if current hcount vcount is within the brush
    logic signed [9:0] radius1;
    assign radius1 = {1'b0,(sw_in1+1)*2-1};

    logic signed [23:0] h_min_x1; 
    assign h_min_x1 = ($signed({2'b0,hcount_in}) - $signed({2'b0,x_in1}))*($signed({2'b0,hcount_in}) - $signed({2'b0,x_in1}));
    logic signed [23:0] v_min_y1; 
    assign v_min_y1 = ($signed({2'b0,vcount_in}) - $signed({2'b0,y_in1}))*($signed({2'b0,vcount_in}) - $signed({2'b0,y_in1}));

    logic signed [9:0] radius2;
    assign radius2 = {1'b0,(sw_in2+1)*2-1};

    logic signed [23:0] h_min_x2; 
    assign h_min_x2 = ($signed({2'b0,hcount_in}) - $signed({2'b0,x_in2}))*($signed({2'b0,hcount_in}) - $signed({2'b0,x_in2}));
    logic signed [23:0] v_min_y2; 
    assign v_min_y2 = ($signed({2'b0,vcount_in}) - $signed({2'b0,y_in2}))*($signed({2'b0,vcount_in}) - $signed({2'b0,y_in2}));

    logic in_brush1;
    assign in_brush1 = ((radius1*radius1) >= 
                        (h_min_x1 + v_min_y1));
    
    logic in_brush2;
    assign in_brush2 = ((radius2*radius2) >= 
                        (h_min_x2 + v_min_y2));


    //  Xilinx True Dual Port RAM, Read First, Dual Clock
    xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(4),                       // Specify RAM data width
    .RAM_DEPTH(360*640),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) frame_buff (
    .addra(input_addra),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(addr),   // Port B address bus, width determined from RAM_DEPTH
    .dina(input_dina),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(color_in2),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),     // Port A clock
    .clkb(pixel_clk_in),     // Port B clock
    .wea(input_wea),       // Port A write enable
    .web(input_web),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(output_douta),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(doutb)    // Port B RAM output data, width determined from RAM_WIDTH
    );

    
    always_comb begin
        if (state == DRAWING) begin
            input_addra = addr;
            input_dina = color_in1;
            input_wea = in_brush1;
            input_web = in_brush2;
        end else begin // in any other state disregard inputs from any other modules
            input_addra = sd_buffer_index;
            input_dina = memout_bin[3:0];
            input_wea = mem_to_buffer_wr;
            bout_memin = {4'b0, output_douta};
            input_web = 0;
        end
        case (doutb)
            4'b0000: begin //black
                red_out = 8'h00;
                green_out = 8'h00;
                blue_out = 8'h00;
            end
            4'b0001: begin //white
                red_out = 8'hFF;
                green_out = 8'hFF;
                blue_out = 8'hFF;
            end
            4'b0010: begin //red
                red_out = 8'hFF;
                green_out = 8'h00;
                blue_out = 8'h00;
            end
            4'b0011: begin //green
                red_out = 8'h00;
                green_out = 8'hFF;
                blue_out = 8'h00;
            end
            4'b0100: begin //blue
                red_out = 8'h00;
                green_out = 8'h00;
                blue_out = 8'hFF;
            end
            4'b0101: begin //cyan
                red_out = 8'h00;
                green_out = 8'hFF;
                blue_out = 8'hFF;
            end
            4'b0110: begin //magenta
                red_out = 8'hFF;
                green_out = 8'h00;
                blue_out = 8'hFF;
            end
            4'b0111: begin //yellow
                red_out = 8'hFF;
                green_out = 8'hFF;
                blue_out = 8'h00;
            end
            4'b1000: begin //gray
                red_out = 8'h80;
                green_out = 8'h80;
                blue_out = 8'h80;
            end
            4'b1001: begin //eminence
                red_out = 8'h6C;
                green_out = 8'h30;
                blue_out = 8'h82;
            end
            4'b1010: begin //pink
                red_out = 8'hFF;
                green_out = 8'h00;
                blue_out = 8'h80;
            end
            4'b1011: begin //orange
                red_out = 8'hFF;
                green_out = 8'h80;
                blue_out = 8'h00;
            end
            4'b1100: begin //purple
                red_out = 8'h80;
                green_out = 8'h00;
                blue_out = 8'hFF;
            end
            4'b1101: begin //cool blue
                red_out = 8'h00;
                green_out = 8'h80;
                blue_out = 8'hFF;
            end
            4'b1110: begin //mint green
                red_out = 8'h00;
                green_out = 8'hFF;
                blue_out = 8'h80;
            end
            4'b1111: begin //lime green
                red_out = 8'h80;
                green_out = 8'hFF;
                blue_out = 8'h00;
            end
            default: begin //default (white)
                red_out = 8'hFF;
                green_out = 8'hFF;
                blue_out = 8'hFF;
            end
        endcase
    end
    
    /*
    always_comb begin 
        if (doutb == 4'b0001) begin 
            red_out = 8'hFF;
            green_out = 8'hFF;
            blue_out = 8'hFF;
        end else begin 
            red_out = 8'h00;
            green_out = 8'h00;
            blue_out = 8'h00;
        end
    end */

    always_ff @(posedge clk_25mhz) begin
        if (rst_in) begin //overwrites everything in permanent memory as well
            state <= IDLE;
            mem_to_buffer_wr <= 0;
            sd_buffer_index <= 0;
            index_to_write_next_sector <= 0;
            prev_byte_available <= 0;
            prev_ready_for_next_byte <= 0;
            write_inc <= 0;
            cycle_count <= 0;
        end else begin
            prev_byte_available <= byte_available;
            prev_ready_for_next_byte <= ready_for_next_byte;
            case (state)
                IDLE: begin
                    sd_buffer_index <= 0; 
                    if (slide_show) begin
                        state <= SLIDE_SHOW_NEW_SECTOR;
                        sd_addr <= 0; // start writing to the buffer from the beginning
                    end else if (draw) begin // draw only writes to the buffer, no action on this side
                        state <= DRAWING;
                        mem_to_buffer_wr <= 0;
                    end
                end
                SLIDE_SHOW_SECTOR: begin // read only a single image initially, eventually allow actual slide show
                    if (byte_available && (!prev_byte_available) && (write_inc == 0)) begin
                        // setting memout_bin and incrementing sd_buffer_index in different cycles to write to the old index (before the incrementing)
                        memout_bin <= dout;
                        write_inc <= 1;
                    end else begin
                        if (write_inc == 1) begin
                            sd_buffer_index <= sd_buffer_index + 1;
                            write_inc <= 0;
                            if ((sd_buffer_index + 1) % SECTOR_SIZE == 0) begin 
                                // the end of this sector
                                sd_addr <= sd_addr + SECTOR_SIZE;
                                state <= SLIDE_SHOW_NEW_SECTOR;
                                mem_to_buffer_wr <= 0;
                                rd <= 0;
                            end 
                        end
                    end
                end
                SLIDE_SHOW_NEW_SECTOR: begin
                    if (sd_buffer_index == IMAGE_SIZE) begin // read next image 
                        state <= SLIDE_SHOW_NEXT_IMAGE;
                        sd_buffer_index <= 0;
                    end else begin
                        if (ready) begin // rising edge of ready
                            rd <= 1;
                            mem_to_buffer_wr <= 1; // enable SD card module to write to buffer
                            write_inc <= 0;
                            state <= SLIDE_SHOW_SECTOR;
                        end
                    end
                end
                SLIDE_SHOW_NEXT_IMAGE: begin
                    // Eventually should pause after every image (for a few seconds), should resume from the last read index in memory
                    if (draw) begin
                        state <= DRAWING;
                        sd_buffer_index <= 0;
                    end else if (!slide_show) begin
                        state <= IDLE;
                        sd_buffer_index <= 0;
                    end else begin // read from the SD card to the buffer
                        if (cycle_count >= 1 << 26) begin //play around with this number
                            cycle_count <= 0;
                            if ((sd_buffer_index == index_to_write_next_sector)) begin
                                state <= IDLE;
                                sd_buffer_index <= 0;
                            end else begin
                                if (ready) begin
                                    rd <= 1;
                                    write_inc <= 0;
                                    mem_to_buffer_wr <= 1; // enable SD card module to write to buffer
                                    state <= SLIDE_SHOW_SECTOR;
                                end
                            end
                        end else begin
                            cycle_count <= cycle_count + 1;
                        end
                    end
                end
                DRAWING: begin
                    if (!draw) begin // finished drawing, save image  card
                        state <= FINISHED_SAVING_SECTOR;
                        sd_buffer_index <= 0; // saving, start reading the buffer from 0
                        sd_addr <= index_to_write_next_sector; // set index to be after the previous write index
                    end 
                end
                
                SAVING_SECTOR: begin
                    // write all contents of the buffer as a new image in the SD card
                    wr <= 0;
                    if (ready_for_next_byte && (!prev_ready_for_next_byte) && (write_inc == 0)) begin // rising edge of ready_for_next_byte
                        din <= bout_memin;
                        write_inc <= 1;
                    end else begin
                        if (write_inc == 1) begin
                            sd_buffer_index <= sd_buffer_index + 1;
                            // could modify later to empty the buffer as well in the process
                            if ((sd_buffer_index + 1) % SECTOR_SIZE == 0) begin //end of this sector
                                sd_addr <= sd_addr + SECTOR_SIZE;
                                state <= FINISHED_SAVING_SECTOR;
                            end 
                            write_inc <= 0;
                        end
                    end
                end
                FINISHED_SAVING_SECTOR: begin
                    if (sd_buffer_index == IMAGE_SIZE) begin
                        state <= IDLE;
                        index_to_write_next_sector <= sd_addr; // save this index for future writes
                        sd_buffer_index = 0;
                        wr <= 0;
                    end else begin
                        if (ready) begin // rising edge of ready
                            wr <= 1;
                            state <= SAVING_SECTOR;
                        end
                    end
                end
            endcase
        end
    end
endmodule

`default_nettype wire