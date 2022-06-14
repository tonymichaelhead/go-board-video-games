`include "VGA_Sync_Pulses.v"
`include "Debounce_Switch.v"
`include "VGA_Sync_Porch.v"

module Car_Bitmap
  (input [3:0] i_Yofs,
   output reg [7:0] o_Bits);

  always @ (*)
    case (i_Yofs)
        0: o_Bits = 8'b0;
        1: o_Bits = 8'b1100;
        2: o_Bits = 8'b11001100;
        3: o_Bits = 8'b11111100;
        4: o_Bits = 8'b11101100;
        5: o_Bits = 8'b11100000;
        6: o_Bits = 8'b1100000;
        7: o_Bits = 8'b1110000;
        8: o_Bits = 8'b110000;
        9: o_Bits = 8'b110000;
        10: o_Bits = 8'b110000;
        11: o_Bits = 8'b1101110;
        12: o_Bits = 8'b11101110;
        13: o_Bits = 8'b11111110;
        14: o_Bits = 8'b11101110;
        15: o_Bits = 8'b101110;
    endcase

endmodule

module Sprite_Bitmap_Top
  (input i_Clk, // Main Clock
   input i_Switch_1, // for reset switch

   // VGA
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

  // For debouncing input reset switch
  Debounce_Switch Switch_1
  (.i_Clk(i_Clk),
   .i_Switch(i_Switch_1),
   .o_Switch(w_Reset));

  // VGA Constants to set Frame Size
  parameter c_VIDEO_WIDTH = 3;
  parameter c_TOTAL_COLS  = 800;
  parameter c_TOTAL_ROWS  = 525;
  parameter c_ACTIVE_COLS = 640;
  parameter c_ACTIVE_ROWS = 480;

  // Common VGA Signals
  wire [c_VIDEO_WIDTH-1:0] w_Red_Video_Pong, w_Red_Video_Porch;
  wire [c_VIDEO_WIDTH-1:0] w_Grn_Video_Pong, w_Grn_Video_Porch;
  wire [c_VIDEO_WIDTH-1:0] w_Blu_Video_Pong, w_Blu_Video_Porch;

  wire [9:0] w_Hpos;
  wire [9:0] w_Vpos;

  reg w_Sprite_Active;
  reg [3:0] r_Car_Sprite_Xofs;
  reg [3:0] r_Car_Sprite_Yofs;
  wire [7:0] w_Car_Sprite_Bits;

  reg [9:0] r_Player_X = 128;
  reg [9:0] r_Player_Y = 128;

  // Generates Sync Pulses to run VGA
  VGA_Sync_Pulses #(.TOTAL_COLS(c_TOTAL_COLS),
                    .TOTAL_ROWS(c_TOTAL_ROWS),
                    .ACTIVE_COLS(c_ACTIVE_COLS),
                    .ACTIVE_ROWS(c_ACTIVE_ROWS)) VGA_Sync_Pulses_Inst
  (.i_Clk(i_Clk),
  .o_HSync(w_HSync_VGA),
  .o_VSync(w_VSync_VGA),
  .o_Col_Count(w_Hpos),
  .o_Row_Count(w_Vpos)
  );

  ////////////////////////////////////////////////////////
  // BEGIN GAME HERE
  ////////////////////////////////////////////////////////

  wire [3:0] digit = w_Hpos[7:4];
  wire [2:0] xofs = w_Hpos[3:1];
  wire [2:0] yofs = w_Vpos[3:1];
  wire [4:0] bits;

  Car_Bitmap Car
    (.i_Yofs(r_Car_Sprite_Yofs),
     .i_Reset(w_Reset),
     .o_Bits(w_Car_Sprite_Bits));

   // start Y counter when we hit the top border (player_y)
   always @(posedge w_HSync_VGA)
     if (w_Vpos == r_Player_Y)
       r_Car_Sprite_Yofs <= 15;
     else if (r_Car_Sprite_Yofs != 0)
       r_Car_Sprite_Yofs <= r_Car_Sprite_Yofs - 1;

  // restart X counter when we hit the left board (player_x)
  always @(posedge i_Clk)
    if (w_Hpos == r_Player_X)
      r_Car_Sprite_Xofs <= 15;
    else if (r_Car_Sprite_Xofs != 0)
      r_Car_Sprite_Xofs <= r_Car_Sprite_Xofs - 1;

  // Mirror sprite in the X direction
  wire [3:0] w_Car_Bit = r_Car_Sprite_Xofs >= 8 ?
                                     15 - r_Car_Sprite_Xofs :
                                     r_Car_Sprite_Xofs;

  wire w_Car_Gfx = w_Car_Sprite_Bits[w_Car_Bit[2:0]];

  // Sync_To_Count #(.TOTAL_COLS(c_TOTAL_COLS),
  //                 .TOTAL_ROWS(c_TOTAL_ROWS))
  // UUT (.i_Clk      (i_Clk),
  //      .i_HSync    (w_HSync_VGA),
  //      .i_VSync    (w_VSync_VGA),
  //      .o_VSync    (w_VSync_Sync),
  //      .o_HSync    (w_HSync_Sync),
  //      .o_Col_Count(w_Col_Count),
  //      .o_Row_Count(w_Row_Count)
  //      );

  //  Register syncs to align with output data.
  // always @(posedge i_Clk)
  // begin
  //   r_VSync <= w_VSync_Sync;
  //   r_HSync <= w_HSync_Sync;
  // end

  wire r = (w_Hpos < c_ACTIVE_COLS && w_Vpos < c_ACTIVE_ROWS) && w_Car_Gfx;
  wire g = (w_Hpos < c_ACTIVE_COLS && w_Vpos < c_ACTIVE_ROWS) && w_Car_Gfx;
  wire b = (w_Hpos < c_ACTIVE_COLS && w_Vpos < c_ACTIVE_ROWS) && w_Car_Gfx;
  // wire g = (hpos < c_ACTIVE_COLS && w_Vpos < c_ACTIVE_ROWS) && bits[xofs ^ 3'b111];


  ////////////////////////////////////////////////////////
  // FOR VGA DISPLAY
  ////////////////////////////////////////////////////////

  VGA_Sync_Porch  #(.VIDEO_WIDTH(c_VIDEO_WIDTH),
                    .TOTAL_COLS(c_TOTAL_COLS),
                    .TOTAL_ROWS(c_TOTAL_ROWS),
                    .ACTIVE_COLS(c_ACTIVE_COLS),
                    .ACTIVE_ROWS(c_ACTIVE_ROWS))
  VGA_Sync_Porch_Inst
   (.i_Clk(i_Clk),
    .i_HSync(w_HSync_VGA),
    .i_VSync(w_VSync_VGA),
    .i_Red_Video({r,r,r}),
    .i_Grn_Video({g,g,g}),
    .i_Blu_Video({b,b,b}),
    .o_HSync(o_VGA_HSync),
    .o_VSync(o_VGA_VSync),
    .o_Red_Video(w_Red_Video_Porch),
    .o_Grn_Video(w_Grn_Video_Porch),
    .o_Blu_Video(w_Blu_Video_Porch));

  assign o_VGA_Red_0 = w_Red_Video_Porch[0];
  assign o_VGA_Red_1 = w_Red_Video_Porch[1];
  assign o_VGA_Red_2 = w_Red_Video_Porch[2];

  assign o_VGA_Grn_0 = w_Grn_Video_Porch[0];
  assign o_VGA_Grn_1 = w_Grn_Video_Porch[1];
  assign o_VGA_Grn_2 = w_Grn_Video_Porch[2];

  assign o_VGA_Blu_0 = w_Blu_Video_Porch[0];
  assign o_VGA_Blu_1 = w_Blu_Video_Porch[1];
  assign o_VGA_Blu_2 = w_Blu_Video_Porch[2];

endmodule
