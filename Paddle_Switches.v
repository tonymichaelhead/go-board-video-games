module Paddle_Switches
  (input            i_Clk,
   input            i_Switch_1,
   input            i_Switch_2,
   input            i_Switch_3,
   input            i_Switch_4,
   output reg       o_Switch_1 = 1'b0,
   output reg       o_Switch_2 = 1'b0,
   output reg       o_Switch_3 = 1'b0,
   output reg       o_Switch_4 = 1'b0
 );


  // Set the Speed the switch needs to be pressed down to switch on
  // In this case, the paddle will move on board game unit
  // every 50 ms that the button is held down.
  parameter c_SWITCH_SPEED = 1250000;

  reg [31:0] r_Paddle_Count = 0;

  // wire w_Paddle_Count_En;

  // Only allow paddles to move if only one button is pushed
  // ^ is an XOR bitwise operation.
  // assign w_Paddle_Count_En = i_Paddle_Up ^ i_Paddle_Dn;

  always @(posedge i_Clk)
  begin
    if (i_Switch_1 == 1'b1)
    begin
      if (r_Paddle_Count == c_SWITCH_SPEED) begin
        r_Paddle_Count <= 0;
        o_Switch_1 <= 1'b1;
      end
      else begin
        r_Paddle_Count <= r_Paddle_Count + 1;
        o_Switch_1 <= 1'b0;
      end
    end

    if (i_Switch_2 == 1'b1)
    begin
      if (r_Paddle_Count == c_SWITCH_SPEED) begin
        r_Paddle_Count <= 0;
        o_Switch_2 <= 1'b1;
      end
      else begin
        r_Paddle_Count <= r_Paddle_Count + 1;
        o_Switch_2 <= 1'b0;
      end
    end

    if (i_Switch_3 == 1'b1)
    begin
      if (r_Paddle_Count == c_SWITCH_SPEED) begin
        r_Paddle_Count <= 0;
        o_Switch_3 <= 1'b1;
      end
      else begin
        r_Paddle_Count <= r_Paddle_Count + 1;
        o_Switch_3 <= 1'b0;
      end
    end

    if (i_Switch_4 == 1'b1)
    begin
      if (r_Paddle_Count == c_SWITCH_SPEED) begin
        r_Paddle_Count <= 0;
        o_Switch_4 <= 1'b1;
      end
      else begin
        r_Paddle_Count <= r_Paddle_Count + 1;
        o_Switch_4 <= 1'b0;
      end
    end
  end

endmodule // Paddle_Switches
