`include "hvsync_generator.v"

/*
A simple test pattern using the hvsync_generator module.
*/

module test_hvsync_top
(
  input i_Clk,
  // input reset,

  output o_VGA_HSync,
  output o_VGA_VSync,
  output o_VGA_Red_0,
  output o_VGA_Red_1,
  output o_VGA_Red_2,
  output o_VGA_Grn_0,
  output o_VGA_Grn_1,
  output o_VGA_Grn_2,
  output o_VGA_Blu_0,
  output o_VGA_Blu_1,
  output o_VGA_Blu_2
);

  // input clk, reset;
  // output hsync, vsync;
  // output [2:0] rgb;
  wire display_on;
  wire [8:0] hpos;
  wire [8:0] vpos;

  hvsync_generator hvsync_gen(
    .clk(i_Clk),
    // .reset(0),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(display_on),
    .hpos(hpos),
    .vpos(vpos)
  );

  wire r = display_on && (((hpos&7)==0) || ((vpos&7)==0));
  wire g = display_on && vpos[4];
  wire b = display_on && hpos[4];
  // assign rgb = {b,g,r};

  assign o_VGA_HSync = hsync;
  assign o_VGA_VSync = vsync;

  assign o_VGA_Red_0 = r;
  assign o_VGA_Red_1 = r;
  assign o_VGA_Red_2 = r;

  assign o_VGA_Grn_0 = g;
  assign o_VGA_Grn_1 = g;
  assign o_VGA_Grn_2 = g;

  assign o_VGA_Blu_0 = b;
  assign o_VGA_Blu_1 = b;
  assign o_VGA_Blu_2 = b;

endmodule
