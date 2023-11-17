`timescale 1ns / 1ps
`default_nettype none

module frame_buffer(
    input wire pixel_clk_in,
    input wire rst_in,
    input wire [9:0] x_in, hcount_in,
    input wire [8:0]  y_in, vcount_in,
    input wire [3:0] color_in,
    input wire [2:0] sw_in,
    input wire nf_in,
    output logic [7:0] red_out,
    output logic [7:0] green_out,
    output logic [7:0] blue_out
);
    logic [3:0] doutb;

    logic [$clog2(360*640)-1:0] write_addr;
    logic [$clog2(360*640)-1:0] read_addr;



    assign write_addr = hcount_in + 640*vcount_in;
    assign read_addr = hcount_in + 640*vcount_in;

    /*
    logic in_brush;
    assign in_brush = (hcount_in == x_in) && (vcount_in == y_in);
    */

    
    logic signed [9:0] radius;
    assign radius = {1'b0,(sw_in+1)*2-1};

    logic signed [23:0] h_min_x; 
    assign h_min_x = ($signed({2'b0,hcount_in}) - $signed({2'b0,x_in}))*($signed({2'b0,hcount_in}) - $signed({2'b0,x_in}));
    logic signed [23:0] v_min_y; 
    assign v_min_y = ($signed({2'b0,vcount_in}) - $signed({2'b0,y_in}))*($signed({2'b0,vcount_in}) - $signed({2'b0,y_in}));

    logic in_brush;
    assign in_brush = ((radius*radius) >= 
                        (h_min_x + v_min_y));



    /*
    logic in_brush;
    assign in_brush = ((radius*radius) >= 
                        ((hcount_in - x_in)*(hcount_in - x_in) + 
                         (vcount_in-y_in)*(vcount_in-y_in)));
    */
    


    /*
    always_comb begin 

    end

    always_ff @(posedge clk_in)begin 
        if (rst_in) begin

        end else begin 
            
        end
    end
    */



    //  Xilinx True Dual Port RAM, Read First, Dual Clock
    xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(4),                       // Specify RAM data width
    .RAM_DEPTH(360*640),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) frame_buff (
    .addra(write_addr),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(read_addr),   // Port B address bus, width determined from RAM_DEPTH
    .dina(color_in),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(4'b0),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),     // Port A clock
    .clkb(pixel_clk_in),     // Port B clock
    .wea(in_brush),       // Port A write enable
    .web(1'b0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(doutb)    // Port B RAM output data, width determined from RAM_WIDTH
    );

    
    always_comb begin
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






endmodule

`default_nettype none