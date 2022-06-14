`include "VGA_Sync_Pulses.v"
`include "Debounce_Switch.v"
`include "Paddle_Switches.v"
`include "VGA_Sync_Porch.v"
`include "Car_Bitmap.v"

/*
* Displays a 16x16 sprite (8 bits mirrored left/right).
*/
module Sprite_Renderer
  (input i_Clk,
   input i_VStart, // start drawing (top border)
   input i_Load, // ok to load sprite data?
   input i_HStart, // start drawing scanline (left border)
   output reg [3:0] o_Rom_Addr, // select ROM address
   input [7:0] i_Rom_Bits, // input bits from ROM
   output reg o_Gfx, // output pixel
   output o_In_Progress); // 0 if waiting for i_VStart

  reg [2:0] r_State; // current state #
  reg [3:0] r_YCount; // number of scan lines drawn so far
  reg [3:0] r_XCount; // number of horizontal pixels in this line

  reg [7:0] r_Outbits; // register to store bits from ROM

  // states for state machine
  localparam WAIT_FOR_VSTART = 0;
  localparam WAIT_FOR_LOAD   = 1;
  localparam LOAD1_SETUP     = 2;
  localparam LOAD1_FETCH     = 3;
  localparam WAIT_FOR_HSTART = 4;
  localparam DRAW            = 5;

  // assign in_progress output bit
  assign o_In_Progress = r_State != WAIT_FOR_VSTART;

  always @(posedge i_Clk)
    begin
      case(r_State)
        WAIT_FOR_VSTART: begin
          r_YCount <= 0; // Initialize vertical count
          o_Gfx <= 0; // Default pixel value (off)
          // wait for i_VStart, then next state
          if (i_VStart)
            r_State <= WAIT_FOR_LOAD;
        end

        WAIT_FOR_LOAD: begin
          r_XCount <= 0; // initialize horizontal count
          o_Gfx <= 0;
          // wait for load, then next state
          if (i_Load)
            r_State <= LOAD1_SETUP;
        end

        LOAD1_SETUP: begin
          o_Rom_Addr <= r_YCount; // load ROM address
          r_State <= LOAD1_FETCH;
        end

        LOAD1_FETCH: begin
          r_Outbits <= i_Rom_Bits;
          r_State <= WAIT_FOR_HSTART;
        end

        WAIT_FOR_HSTART: begin
          // wait for i_HStart, then start drawing
          if(i_HStart)
            r_State <= DRAW;
        end

        DRAW: begin
          // get pixel, mirroring graphics left/right
          o_Gfx <= r_Outbits[r_XCount<8 ? r_XCount[2:0] : ~r_XCount[2:0]];
          r_XCount <= r_XCount + 1;
          // finished drawing horizontal slice?
          if (r_XCount == 15) begin // pre-increment value
            r_YCount <= r_YCount + 1;
            if (r_YCount == 15) // pre-increment value
              r_State <= WAIT_FOR_VSTART;
            else
              r_State <= WAIT_FOR_LOAD;
          end
        end

        // unknown state -- reset
        default: begin
          r_State <= WAIT_FOR_VSTART;
        end
      endcase
    end

endmodule // Sprite_Renderer


module Sprite_Renderer_Test_Top
  (input i_Clk, // Main Clock

   // Paddle control
   input i_Switch_1,
   input i_Switch_2,
   input i_Switch_3,
   input i_Switch_4,

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
   .o_Switch(w_Debounced_Switch_1));

  Debounce_Switch Switch_2
  (.i_Clk(i_Clk),
   .i_Switch(i_Switch_2),
   .o_Switch(w_Debounced_Switch_2));

  Debounce_Switch Switch_3
  (.i_Clk(i_Clk),
   .i_Switch(i_Switch_3),
   .o_Switch(w_Debounced_Switch_3));

  Debounce_Switch Switch_4
  (.i_Clk(i_Clk),
   .i_Switch(i_Switch_4),
   .o_Switch(w_Debounced_Switch_4));

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

  // Generates Sync Pulses to run VGA
  VGA_Sync_Pulses #(.TOTAL_COLS(c_TOTAL_COLS),
                    .TOTAL_ROWS(c_TOTAL_ROWS),
                    .ACTIVE_COLS(c_ACTIVE_COLS),
                    .ACTIVE_ROWS(c_ACTIVE_ROWS)) VGA_Sync_Pulses_Inst
  (.i_Clk(i_Clk),
  .o_HSync(w_HSync_VGA),
  .o_VSync(w_VSync_VGA),
  .o_Display_On(w_Display_On),
  .o_Col_Count(w_Hpos),
  .o_Row_Count(w_Vpos)
  );

  ////////////////////////////////////////////////////////
  // BEGIN GAME HERE
  ////////////////////////////////////////////////////////

  wire [9:0] w_Hpos;
  wire [9:0] w_Vpos;

  // player position
  // TODO how many bits should this be? think it should be the same as
  reg [7:0] r_Player_X = 128;
  reg [7:0] r_Player_Y = 128;

  // paddle position
  reg [7:0] r_Paddle_X = 128;
  reg [7:0] r_Paddle_Y = 128;

  // car bitmap ROM and associated wires
  wire [3:0] w_Car_Sprite_Addr;
  wire [7:0] w_Car_Sprite_Bits;

  Car_Bitmap Car
    (.i_Yofs(w_Car_Sprite_Addr),
     .o_Bits(w_Car_Sprite_Bits));

  // convert player x/y to 10 bits and compare to screen hpos/vpos
  wire w_VStart = {2'b00, r_Player_Y} == w_Vpos;
  wire w_HStart = {2'b00, r_Player_X} == w_Hpos;

  wire w_Car_Gfx; // car sprite video signal
  wire w_In_Progress; // 1 = rendering taking place on scanline

  // sprite rendered module
  Sprite_Renderer Renderer(
    .i_Clk(i_Clk),
    .i_VStart(w_VStart),
    .i_Load(w_HSync_VGA),
    .i_HStart(w_HStart),
    .o_Rom_Addr(w_Car_Sprite_Addr),
    .i_Rom_Bits(w_Car_Sprite_Bits),
    .o_Gfx(w_Car_Gfx),
    .o_In_Progress(w_In_Progress));

  Paddle_Switches Paddle_Switches_Inst
    (.i_Clk(i_Clk),
    .i_Switch_1(w_Debounced_Switch_1),
    .i_Switch_2(w_Debounced_Switch_2),
    .i_Switch_3(w_Debounced_Switch_3),
    .i_Switch_4(w_Debounced_Switch_4),
    .o_Switch_1(w_Paddle_Up),
    .o_Switch_2(w_Paddle_Dn),
    .o_Switch_3(w_Paddle_Rt),
    .o_Switch_4(w_Paddle_Lt));

  // measure paddle position
  always @(posedge i_Clk)
    if (w_Paddle_Up == 1'b1)
      r_Paddle_Y <= r_Paddle_Y - 1;
    else if (w_Paddle_Dn == 1'b1)
      r_Paddle_Y <= r_Paddle_Y + 1;
    else if (w_Paddle_Rt == 1'b1)
      r_Paddle_X <= r_Paddle_X + 1;
    else if (w_Paddle_Lt == 1'b1)
      r_Paddle_X <= r_Paddle_X - 1;

  always @(posedge w_VSync_VGA)
    begin
      r_Player_X <= r_Paddle_X;
      r_Player_Y <= r_Paddle_Y;
    end

  // TODO: implement Display_On from VGA pulse signal to cleanup code
  wire r = w_Display_On && w_Car_Gfx;
  wire g = w_Display_On && w_Car_Gfx;
  wire b = w_Display_On && w_In_Progress;


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
