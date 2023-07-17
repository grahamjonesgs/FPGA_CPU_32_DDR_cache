`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/10/2021 10:53:39 AM
// Design Name:
// Module Name: mem_read_write
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
// Added pre_wait to write

module mem_read_write (
    input         i_Clk,
    inout  [15:0] ddr2_dq,
    inout  [ 1:0] ddr2_dqs_n,
    inout  [ 1:0] ddr2_dqs_p,
    // Outputs
    output [12:0] ddr2_addr,
    output [ 2:0] ddr2_ba,
    output        ddr2_ras_n,
    output        ddr2_cas_n,
    output        ddr2_we_n,
    //output ddr2_reset_n,
    output [ 0:0] ddr2_ck_p,
    output [ 0:0] ddr2_ck_n,
    output [ 0:0] ddr2_cke,
    output [ 0:0] ddr2_cs_n,
    output [ 1:0] ddr2_dm,
    output [ 0:0] ddr2_odt,

    input             i_mem_write_DV,
    input             i_mem_read_DV,
    input      [23:0] i_mem_addr,
    input      [31:0] i_mem_write_data,
    output reg [31:0] o_mem_read_data,
    output reg        o_mem_ready,
    input             i_cache_enable,
    input             i_cache_reset

);

   parameter CACHE_SIZE = 4_096;  // 5 bit index

   // DDR2
   wire         sys_clk_i;
   reg  [  9:0] por_counter = 32;
   wire         resetn = (por_counter == 0);
   // Power-on-reset generator circuit.
   // Asserts resetn for 1023 cycles, then de-asserts
   // `resetn` is Active low reset

   // regs to talk to DDR
   reg          o_ddr_mem_write_DV;
   reg          o_ddr_mem_read_DV;
   wire [ 26:0] o_ddr_mem_addr;
   wire [ 26:0] o_temp_ddr_mem_addr;
   wire [ 26:0] o_temp_ddr_mem_addr2;
   reg  [127:0] o_ddr_mem_write_data;
   wire [127:0] i_ddr_mem_read_data;
   wire         i_ddr_mem_ready;
   wire         w_cache_enable;
   reg  [ 15:0] r_app_wdf_mask;
   wire [ 15:0] w_app_wdf_mask;

   assign w_app_wdf_mask = r_app_wdf_mask;

   localparam PRE_WAIT = 9'd1;
   localparam WAIT = 10'd2;
   localparam WRITE = 10'd4;
   localparam WRITE_DONE = 10'd8;
   localparam READ_CACHE = 10'd16;
   localparam READ_CACHE1 = 10'd32;
   localparam READ_CACHE2 = 10'd64;
   localparam READ_CACHE3 = 10'd128;
   localparam READ_WAIT = 10'd256;

   reg [9:0] state = WAIT;

   reg [24-$clog2(CACHE_SIZE):0] cache_val_addr[CACHE_SIZE-1:0];
   // Cache data
   (* ram_style = "block" *)
   (* rw_addr_collision = "yes" *)
   reg [127:0] cache_val_data[CACHE_SIZE-1:0];
   reg [127:0] r_cache_val_data_hold;

   // Internal regs
   wire w_cache_hit;
   wire [$clog2(CACHE_SIZE)-1:0] w_cache_index;  //4:0
   integer counter;  // use for init
   wire [1:0] w_byte_offset;  // 1:0
   wire [23-$clog2(CACHE_SIZE):0] w_cache_tag;  // is 18 for 5 bit index (cache size 32) // 18:0

   // Memory model based on the 16 bit data address of the DDR, thus the <<1 to make it 32 bit. Then remove 
   // the two lowest bits as we will always grab the 4*32 bits 
   assign o_temp_ddr_mem_addr = {3'b0, i_mem_addr[23:0]};
   assign o_temp_ddr_mem_addr2 = o_temp_ddr_mem_addr << 1;
   assign o_ddr_mem_addr = {o_temp_ddr_mem_addr2[26:3], 3'b0};
   // 19 tag ,5 index,3 zero


   assign w_cache_enable = i_cache_enable;

   assign w_cache_index = o_ddr_mem_addr[$clog2(CACHE_SIZE)+2:3];  // 7:3 - 5 bit index
   assign w_cache_tag = o_ddr_mem_addr[26:3+$clog2(CACHE_SIZE)];  // 26:8 - 19 bit tag 

   // comprising 18:0 to 18:0.....
   assign w_cache_hit = cache_val_addr[w_cache_index][23-$clog2(
       CACHE_SIZE
   ):0] == w_cache_tag && cache_val_addr[w_cache_index][24-$clog2(
       CACHE_SIZE
   )] == 1'b1 && w_cache_enable;
   assign w_byte_offset = i_mem_addr[1:0];


 /*  ila_0 myila (
       .clk(i_Clk),
       .probe0(r_cache_value),
       .probe1(r_cache_hit),
       .probe2(r_next_cache),
       .probe3(o_mem_ready),
       .probe4(i_mem_read_DV),
       .probe5(state),
       .probe6(i_cache_enable),
       .probe7(w_mem_addr),
       .probe8(o_mem_read_data),
       .probe9(i_ddr_mem_read_data),
       .probe10(o_ddr_mem_addr),
       .probe11(o_ddr_mem_read_DV),
       .probe12(i_ddr_mem_ready),
       .probe13(r_cache_val_data_hold)

   ); */

   initial begin
      for (counter = 0; counter < CACHE_SIZE; counter = counter + 1) begin
         cache_val_addr[counter] = 0;
      end
   end
   always @(posedge i_Clk) begin
      if (por_counter > 0) begin
         por_counter <= por_counter - 1;
      end
   end

   always @(posedge i_Clk) begin
      if (i_cache_reset) begin
         for (counter = 0; counter < CACHE_SIZE; counter = counter + 1) begin
       //     cache_val_addr[counter] = 0;  // Leads to too many LUT usage. Marked dirty on write anyway
         end
      end  // If cache reset is high
      case (state)

         PRE_WAIT: begin
            state <= WAIT;
         end

         WAIT: begin
            o_mem_ready <= 0;
            if (i_mem_write_DV) begin
               state <= WRITE;
            end // if (i_mem_write_DV)
            else
            begin
               if (i_mem_read_DV) begin
                  if (w_cache_hit) begin
                     r_cache_val_data_hold<=cache_val_data[w_cache_index];
                     state <= READ_CACHE2;
                  end else begin
                     o_ddr_mem_read_DV <= 1;
                     state <= READ_WAIT;
                  end
               end  // if (i_mem_write_DV)
            end  // else if (i_mem_write_DV)
         end

         WRITE: begin
            o_ddr_mem_write_DV <= 1;
            state <= WRITE_DONE;
            cache_val_addr[w_cache_index]<=0; // Mark as dirty  
            if (i_mem_addr[1:0] == 0) begin
               r_app_wdf_mask = 16'b0000_1111_1111_1111;
               o_ddr_mem_write_data <= {i_mem_write_data, 96'b0};
            end else if (i_mem_addr[1:0] == 1) begin
               r_app_wdf_mask = 16'b1111_0000_1111_1111;
               o_ddr_mem_write_data <= {32'b0, i_mem_write_data, 64'b0};
            end else if (i_mem_addr[1:0] == 2) begin
               r_app_wdf_mask = 16'b1111_1111_0000_1111;
               o_ddr_mem_write_data <= {64'b0, i_mem_write_data, 32'b0};
            end else begin
               r_app_wdf_mask = 16'b1111_1111_1111_0000;
               o_ddr_mem_write_data <= {96'b0, i_mem_write_data};
            end
         end

         WRITE_DONE: begin
            if (i_ddr_mem_ready) begin
               o_mem_ready <= 1;
               o_ddr_mem_write_DV <= 0;
               state <= PRE_WAIT;
            end
         end

         READ_CACHE2: begin
            case (w_byte_offset)
               2'b00: begin
                  o_mem_read_data <= r_cache_val_data_hold[127:96];
               end
               2'b01: begin
                  o_mem_read_data <= r_cache_val_data_hold[95:64];
               end
               2'b10: begin
                  o_mem_read_data <= r_cache_val_data_hold[63:32];
               end
               2'b11: begin
                  o_mem_read_data <= r_cache_val_data_hold[31:0];
               end

            endcase
            o_mem_ready <= 1;
            state <= PRE_WAIT; // or too fast for CPU
         end

         READ_WAIT: begin
            if (i_ddr_mem_ready) begin
               o_mem_ready <= 1;
               o_ddr_mem_read_DV <= 0;
               state <= PRE_WAIT;
               // Test read from correct part of data
               if (i_mem_addr[1:0] == 0) begin
                  o_mem_read_data <= i_ddr_mem_read_data[127:96];
               end else if (i_mem_addr[1:0] == 1) begin
                  o_mem_read_data <= i_ddr_mem_read_data[95:64];
               end else if (i_mem_addr[1:0] == 2) begin
                  o_mem_read_data <= i_ddr_mem_read_data[63:32];
               end else begin
                  o_mem_read_data <= i_ddr_mem_read_data[31:0];
               end
               cache_val_addr[w_cache_index] <= {1'b1, w_cache_tag};  // Add address to cache
               cache_val_data[w_cache_index] <= i_ddr_mem_read_data;  // Add value to cache

            end
         end

         default: state <= WAIT;
      endcase
   end


   clk_wiz_0 clk_wiz_0 (
       .i_Clk  (i_Clk),
       .clk_200(sys_clk_i),
       .resetn (resetn)
   );

   ddr2_control ddr2_control (
       .ddr2_dq(ddr2_dq),
       .ddr2_dqs_n(ddr2_dqs_n),
       .ddr2_dqs_p(ddr2_dqs_p),
       // Outputs
       .ddr2_addr(ddr2_addr),
       .ddr2_ba(ddr2_ba),
       .ddr2_ras_n(ddr2_ras_n),
       .ddr2_cas_n(ddr2_cas_n),
       .ddr2_we_n(ddr2_we_n),
       //output ddr2_reset_n,
       .ddr2_ck_p(ddr2_ck_p),
       .ddr2_ck_n(ddr2_ck_n),
       .ddr2_cke(ddr2_cke),
       .ddr2_cs_n(ddr2_cs_n),
       .ddr2_dm(ddr2_dm),
       .ddr2_odt(ddr2_odt),

       .resetn(resetn),
       .sys_clk_i(sys_clk_i),

       .i_mem_write_DV(o_ddr_mem_write_DV),
       .i_mem_read_DV(o_ddr_mem_read_DV),
       .i_mem_addr(o_ddr_mem_addr),
       .i_mem_write_data(o_ddr_mem_write_data),
       .i_app_wdf_mask   (w_app_wdf_mask),
       .o_mem_read_data(i_ddr_mem_read_data),
       .o_mem_ready(i_ddr_mem_ready)
   );

endmodule