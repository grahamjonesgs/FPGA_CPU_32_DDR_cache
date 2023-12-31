`timescale 1ns / 1ps
module Seven_seg_LED_Display_Controller (
    input i_sysclk,  // 100 Mhz clock source on Basys 3 FPGA
    input i_reset,
    input [31:0] i_displayed_number1,  // Number to display
    input [31:0] i_displayed_number2,  // Number to display
    output reg [7:0] o_Anode_Activate,
    output reg [7:0] o_LED_cathode
);

   reg  [ 7:0] r_LED_Bytes;
   reg  [19:0] r_refresh_counter;
   wire [ 2:0] r_LED_activating_counter;  // Which LED block to use

   always @(posedge i_sysclk) begin
      if (i_reset == 1) r_refresh_counter <= 0;
      else r_refresh_counter <= r_refresh_counter + 1;
   end
   assign r_LED_activating_counter = r_refresh_counter[17:15];

   always @(posedge i_sysclk) begin
      case (r_LED_activating_counter)
         3'b000: begin
            o_Anode_Activate = 8'b11110111;
            r_LED_Bytes = i_displayed_number2[31:24];
         end
         3'b001: begin
            o_Anode_Activate = 8'b11111011;
            r_LED_Bytes = i_displayed_number2[23:16];
         end
         3'b010: begin
            o_Anode_Activate = 8'b11111101;
            r_LED_Bytes = i_displayed_number2[15:8];
         end
         3'b011: begin
            o_Anode_Activate = 8'b11111110;
            r_LED_Bytes = i_displayed_number2[7:0];
         end
         3'b100: begin
            o_Anode_Activate = 8'b01111111;
            r_LED_Bytes = i_displayed_number1[31:24];
         end
         3'b101: begin
            o_Anode_Activate = 8'b10111111;
            r_LED_Bytes = i_displayed_number1[23:16];
         end
         3'b110: begin
            o_Anode_Activate = 8'b11011111;
            r_LED_Bytes = i_displayed_number1[15:8];
         end
         3'b111: begin
            o_Anode_Activate = 8'b11101111;
            r_LED_Bytes = i_displayed_number1[7:0];
         end
         default:  // To dim the LED's to 75% ignore 25% duty cycle
        begin
            o_Anode_Activate = 8'b11111111;
            r_LED_Bytes = 8'b0;
         end
      endcase
   end
   always @(posedge i_sysclk) begin  // Segments as per manual dot then ABCDEFG . High is off.
      case (r_LED_Bytes)
         8'h00:   o_LED_cathode = 8'b10000001;  // "0"
         8'h01:   o_LED_cathode = 8'b11001111;  // "1"
         8'h02:   o_LED_cathode = 8'b10010010;  // "2"
         8'h03:   o_LED_cathode = 8'b10000110;  // "3"
         8'h04:   o_LED_cathode = 8'b11001100;  // "4"
         8'h05:   o_LED_cathode = 8'b10100100;  // "5"
         8'h06:   o_LED_cathode = 8'b10100000;  // "6"
         8'h07:   o_LED_cathode = 8'b10001111;  // "7"
         8'h08:   o_LED_cathode = 8'b10000000;  // "8"
         8'h09:   o_LED_cathode = 8'b10000100;  // "9"
         8'h0A:   o_LED_cathode = 8'b10001000;  // "A"
         8'h0B:   o_LED_cathode = 8'b00000000;  // "B"
         8'h0C:   o_LED_cathode = 8'b10110001;  // "C"
         8'h0D:   o_LED_cathode = 8'b00000001;  // "D"
         8'h0E:   o_LED_cathode = 8'b10110000;  // "E"
         8'h0F:   o_LED_cathode = 8'b10111000;  // "F"
         8'h10:   o_LED_cathode = 8'b00000001;  // "0."
         8'h11:   o_LED_cathode = 8'b01001111;  // "1."
         8'h12:   o_LED_cathode = 8'b00010010;  // "2."
         8'h13:   o_LED_cathode = 8'b00000110;  // "3."
         8'h14:   o_LED_cathode = 8'b01001100;  // "4."
         8'h15:   o_LED_cathode = 8'b00100100;  // "5."
         8'h16:   o_LED_cathode = 8'b00100000;  // "6."
         8'h17:   o_LED_cathode = 8'b00001111;  // "7."
         8'h18:   o_LED_cathode = 8'b00000000;  // "8."
         8'h19:   o_LED_cathode = 8'b00000100;  // "9."
         8'h20:   o_LED_cathode = 8'b11000001;  // "V"
         8'h21:   o_LED_cathode = 8'b11111110;  // "-"
         8'h22:   o_LED_cathode = 8'b11111111;  // " "
         8'h23:   o_LED_cathode = 8'b11001000;  // "H"
         8'h24:   o_LED_cathode = 8'b11110001;  // "L"
         8'h25:   o_LED_cathode = 8'b10011000;  // "P"
         default: o_LED_cathode = 8'b11111110;  // "-"
      endcase
   end
endmodule
