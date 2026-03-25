
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 09/24/2020 01:15:33 PM
// Design Name:
// Module Name: SPI_top
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

`timescale 1ns / 1ps
module FPGA_CPU_32_bits_cache (
    input             CPU_RESETN,        // CPU reset button
    input             i_Clk,             // FPGA Clock
    input             i_uart_rx,
    input             i_load_H,          // Load button
    output            o_uart_tx,
    output reg [15:0] o_led,
    output            o_SPI_LCD_Clk,
    input             i_SPI_LCD_MISO,
    output            o_SPI_LCD_MOSI,
    output            o_SPI_LCD_CS_n,
    output reg        o_LCD_DC,
    output reg        o_LCD_reset_n,
    output     [ 7:0] o_Anode_Activate,  // anode signals of the 7-segment LED display
    output     [ 7:0] o_LED_cathode,     // cathode patterns of the 7-segment LED display
    input      [15:0] i_switch,
    output     [ 2:0] o_LED_RGB_1,
    output     [ 2:0] o_LED_RGB_2,

    // DDR2 Physical Interface Signals
    //Inouts
    inout [15:0] ddr2_dq,
    inout [1:0] ddr2_dqs_n,
    inout [1:0] ddr2_dqs_p,
    // Outputs
    output [12:0] ddr2_addr,
    output [2:0] ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    //output ddr2_reset_n,
    output [0:0] ddr2_ck_p,
    output [0:0] ddr2_ck_n,
    output [0:0] ddr2_cke,
    output [0:0] ddr2_cs_n,
    output [1:0] ddr2_dm,
    output [0:0] ddr2_odt
);

   localparam STACK_SIZE = 1024;

   // State Machine Code
   localparam OPCODE_REQUEST = 32'h1, OPCODE_FETCH = 32'h2, OPCODE_FETCH2 = 32'h4;
   localparam VAR1_FETCH = 32'h8, VAR1_FETCH2 = 32'h10, VAR1_FETCH3 = 32'h20;
   localparam START_WAIT = 32'h40, UART_DELAY = 32'h80, OPCODE_EXECUTE = 32'h100;
   localparam HCF_1 = 32'h200, HCF_2 = 32'h400, HCF_3 = 32'h800, HCF_4 = 32'h1_000;
   localparam NO_PROGRAM = 32'h2_000, LOAD_START = 32'h4_000, LOADING_BYTE = 32'h8_000;
   localparam LOAD_COMPLETE = 32'h10_000, LOAD_WAIT = 32'h20_000;
   localparam DEBUG_DATA = 32'h40_000, DEBUG_DATA2 = 32'h80_000, DEBUG_DATA3 = 32'h100_000;
   localparam DEBUG_WAIT = 32'h200_000;
localparam MULTIPLY_CALC      = 32'h0040_0000;  // DSP pipeline stage 1 (MREG)
localparam MULTIPLY_PIPE      = 32'h0100_0000;  // DSP pipeline stage 2 (PREG)
localparam MULTIPLY_WRITEBACK = 32'h0080_0000;  // Write result
localparam WRITEBACK          = 32'h0200_0000;  // Register file writeback stage
localparam HALTED             = 32'h0400_0000;  // CPU halted, waiting for reset
localparam DIVIDE_STEP        = 32'h0800_0000;  // Division iteration state

   // Error Codes
   localparam ERR_INV_OPCODE = 8'h1, ERR_INV_FSM_STATE = 8'h2, ERR_STACK = 8'h3;
   localparam ERR_DATA_LOAD = 8'h4, ERR_CHECKSUM_LOAD = 8'h5, ERR_OVERFLOW = 8'h6;
   localparam ERR_SEG_WRITE_TO_CODE = 'h7, ERR_SEG_EXEC_DATA = 'h8;

   // UART receive control
   wire [7:0] w_uart_rx_value;  // Received value
   wire w_uart_rx_DV;  // receive flag

   // LCD control
   reg [3:0] o_TX_LCD_Count;  // # bytes per CS low
   reg [7:0] o_TX_LCD_Byte;  // Byte to transmit on MOSI
   reg o_TX_LCD_DV;  // Data Valid Pulse with i_TX_Byte
   wire i_TX_LCD_Ready;  // Transmit Ready for next byte

   // RX (MISO) Signals
   wire [3:0] i_RX_LCD_Count;  // Index RX byte
   wire i_RX_LCD_DV;  // Data Valid pulse (1 clock cycle)
   wire [7:0] i_RX_LCD_Byte;  // Byte received on MISO

   reg [44:0] r_timeout_counter;  // Room for 32 bits plus the 13 left shift in the timing task
   reg [44:0] r_timeout_max;

   // Machine control
   reg [31:0] r_SM;
   reg [23:0] r_PC;
   reg [31:0] r_mem_read_addr;
   wire [15:0] w_opcode;
   wire [31:0] w_var1;
   wire [31:0] w_var2;
   wire [31:0] w_mem;
   reg [3:0] r_reg_1;
   reg [3:0] r_reg_2;
   reg [1:0] r_extra_clock;
   reg [23:0] r_idx_base_addr;  // Saved base address for indexed register ops
   reg r_hcf_message_sent;
   reg [31:0] r_stack_limit;
   reg [31:0] r_start_wait_counter;

   //load control
   //reg          o_ram_write_DV;
   reg [31:0] o_ram_write_value;
   reg [23:0] o_ram_write_addr;
   reg [23:0] r_ram_next_write_addr;
   reg [7:0] rx_count;
   reg [2:0] r_load_byte_counter;
   reg [15:0] r_checksum;
   reg [15:0] r_old_checksum;
   reg [15:0] r_calc_checksum;
   reg [15:0] r_rec_checksum;
   reg [23:0] r_PC_requested;

   // Register control
   reg [31:0] r_register[15:0];
   reg r_zero_flag;
   reg r_equal_flag;
   reg r_carry_flag;
   reg r_overflow_flag;
   reg [7:0] r_error_code;

   // Display value
   reg [31:0] r_seven_seg_value1;
   reg [31:0] r_seven_seg_value2;
   reg r_error_display_type;
   reg [11:0] r_RGB_LED_1;
   reg [11:0] r_RGB_LED_2;

   // Stack control
   wire [31:0] i_stack_top_value;
   wire i_stack_error;
   reg r_stack_read_flag;
   reg r_stack_write_flag;
   reg [31:0] r_stack_write_value;
   reg r_stack_reset;

   // UART send message
   reg [2047:0] r_msg;
   reg [7:0] r_msg_length;
   reg r_msg_send_DV;
   reg r_mem_was_ready;
   wire i_msg_sent_DV;
   wire w_sending_msg;

   // temp vars for timing
   reg r_timing_start;

   // Interrupt handler
   reg [23:0] r_interrupt_table[3:0];
   reg r_timer_interrupt;
   reg [31:0] r_timer_interrupt_counter;
   reg [63:0] r_timer_interrupt_counter_sec;

   // Memory
   reg r_mem_write_DV;
   reg r_mem_read_DV;
   reg [23:0] r_mem_addr;
   reg [31:0] r_mem_write_data;
   wire [31:0] w_mem_read_data;
   wire w_mem_ready;
   reg [15:0] r_opcode_mem;
   reg [31:0] r_var1_mem;
   reg [31:0] r_var2_mem;
   reg r_cache_reset;

   // Debug
   reg r_debug_flag;
   reg r_debug_step_flag;
   reg r_debug_step_run;

   wire w_reset_H;
   reg r_boot_flash;
   
   //=========================================================================
   // Additional flags for expanded comparisons
   //=========================================================================
   reg r_sign_flag;      // Sign of last result (bit 31)
   reg r_less_flag;      // Result of signed less-than comparison

   reg r_mul_is_immediate;  // If true, increment PC by 2 instead of 1
   
   //=============================================================================
  // PIPELINED MULTIPLY REGISTERS
  //=============================================================================

  // Pipeline stage registers (active during s_multiply state)
  reg [63:0] r_mul_pipe1;        // Stage 1: multiply result (maps to DSP48 MREG)
  reg [63:0] r_mul_pipe2;        // Stage 2: registered output (maps to DSP48 PREG)
  wire [31:0] r_mul_result_lo;
  wire [31:0] r_mul_result_hi;
  assign r_mul_result_lo = r_mul_pipe2[31:0];
  assign r_mul_result_hi = r_mul_pipe2[63:32];

  reg        r_mul_is_high;      // Are we capturing high word?
  reg        r_mul_is_unsigned;  // Unsigned operation?
  reg [3:0]  r_mul_dest_reg;     // Destination register
  // Dedicated multiply operand capture (breaks path from register file)
  reg [31:0] r_mul_operand_a;
  reg [31:0] r_mul_operand_b;

  // Free-running 2-stage multiply pipeline (lets Vivado use DSP48 MREG + PREG)
  always @(posedge i_Clk) begin
     // Stage 1: multiply
     if (r_mul_is_unsigned)
        r_mul_pipe1 <= r_mul_operand_a * r_mul_operand_b;
     else
        r_mul_pipe1 <= $signed(r_mul_operand_a) * $signed(r_mul_operand_b);
     // Stage 2: register
     r_mul_pipe2 <= r_mul_pipe1;
  end


   //=========================================================================
   // Hardware divide using iterative but optimized state machine
   // For true single-cycle, you'd need a pipelined divider IP
   //=========================================================================
   reg [31:0] r_div_dividend;
   reg [31:0] r_div_divisor;
   reg [31:0] r_div_quotient;
   reg [31:0] r_div_remainder;
   reg [5:0]  r_div_counter;
   reg        r_div_busy;
   reg        r_div_sign_q;      // Sign of quotient
   reg        r_div_sign_r;      // Sign of remainder
   reg        r_div_is_signed;
   reg [1:0]  r_div_op;          // 0=none, 1=div, 2=mod
   reg [3:0]  r_div_dest_reg;    // Destination register for division result
   reg        r_div_pc_inc;      // 0=PC+1, 1=PC+2
   
   localparam DIV_OP_NONE = 2'd0;
   localparam DIV_OP_DIV  = 2'd1;
   localparam DIV_OP_MOD  = 2'd2;
   
   // Dedicated read ports - registered every cycle
   reg [31:0] r_reg_port_a;
   reg [31:0] r_reg_port_b;

   // Writeback pipeline registers
   reg [31:0] r_writeback_value;
   reg [3:0]  r_writeback_reg;

    always @(posedge i_Clk) begin
       r_reg_port_a <= r_register[r_reg_1];
       r_reg_port_b <= r_register[r_reg_2];
   end

   assign w_reset_H = !CPU_RESETN;

   mem_read_write mem_read_write (
       .i_Clk(i_Clk),
       .ddr2_dq(ddr2_dq),
       .ddr2_dqs_n(ddr2_dqs_n),
       .ddr2_dqs_p(ddr2_dqs_p),
       // Outputs
       .ddr2_addr(ddr2_addr),
       .ddr2_ba(ddr2_ba),
       .ddr2_ras_n(ddr2_ras_n),
       .ddr2_cas_n(ddr2_cas_n),
       .ddr2_we_n(ddr2_we_n),
       .ddr2_ck_p(ddr2_ck_p),
       .ddr2_ck_n(ddr2_ck_n),
       .ddr2_cke(ddr2_cke),
       .ddr2_cs_n(ddr2_cs_n),
       .ddr2_dm(ddr2_dm),
       .ddr2_odt(ddr2_odt),

       .i_mem_write_DV(r_mem_write_DV),
       .i_mem_read_DV(r_mem_read_DV),
       .i_mem_addr(r_mem_addr),
       .i_mem_write_data(r_mem_write_data),
       .o_mem_read_data(w_mem_read_data),
       .o_mem_ready(w_mem_ready),
       .i_cache_enable(i_switch[0]),
       .i_cache_reset(r_cache_reset)
   );


   uart_send_msg uart_send_msg1 (
       .i_Clk(i_Clk),
       .i_msg_flat(r_msg),
       .i_msg_length(r_msg_length),
       .i_msg_send_DV(r_msg_send_DV),
       .o_Tx_Serial(o_uart_tx),
       .o_msg_sent_DV(i_msg_sent_DV),
       .o_sending_msg(w_sending_msg)
   );


   uart_rx uart_rx1 (
       .i_Clock(i_Clk),
       .i_Rx_Serial(i_uart_rx),
       .o_Rx_DV(w_uart_rx_DV),
       .o_Rx_Byte(w_uart_rx_value)
   );


   Seven_seg_LED_Display_Controller Seven_seg_LED_Display_Controller1 (
       .i_sysclk(i_Clk),
       .i_reset(w_reset_H),
       .i_displayed_number1(r_seven_seg_value1),  // Number to display
       .i_displayed_number2(r_seven_seg_value2),  // Number to display
       .o_Anode_Activate(o_Anode_Activate),
       .o_LED_cathode(o_LED_cathode)
   );

   SPI_Master_With_Single_CS SPI_Master_With_Single_CS_inst (
       .i_Rst_L   (~w_reset_H),
       .i_Clk     (i_Clk),
       // TX (MOSI) Signals
       .i_TX_Count(o_TX_LCD_Count),  // # bytes per CS low
       .i_TX_Byte (o_TX_LCD_Byte),   // Byte to transmit on MOSI
       .i_TX_DV   (o_TX_LCD_DV),     // Data Valid Pulse with i_TX_Byte
       .o_TX_Ready(i_TX_LCD_Ready),  // Transmit Ready for next byte
       // RX (MISO) Signals
       .o_RX_Count(i_RX_LCD_Count),  // Index RX byte
       .o_RX_DV   (i_RX_LCD_DV),     // Data Valid pulse (1 clock cycle)
       .o_RX_Byte (i_RX_LCD_Byte),   // Byte received on MISO
       // SPI Interface
       .o_SPI_Clk (o_SPI_LCD_Clk),
       .i_SPI_MISO(i_SPI_LCD_MISO),
       .o_SPI_MOSI(o_SPI_LCD_MOSI),
       .o_SPI_CS_n(o_SPI_LCD_CS_n)
   );
   /*
rams_sp_nc rams_sp_nc1 (
               .i_clk(i_Clk),
               .i_opcode_read_addr(r_PC),
               .i_mem_read_addr(r_mem_read_addr),
               .o_dout_opcode(w_opcode),
               .o_dout_mem(w_mem),
               .o_dout_var1(w_var1),
               .o_dout_var2(w_var2),
               .i_write_addr(o_ram_write_addr),
               .i_write_value(o_ram_write_value),
               .i_write_en(o_ram_write_DV)
                );
 */
   integer i;
   initial begin
      r_sign_flag <= 0;
      r_less_flag <= 0;
      r_div_busy <= 0;
      r_div_op <= DIV_OP_NONE;
      r_div_counter <= 0;
       for (i = 0; i < 16; i = i + 1)
       r_register[i] = 32'b0;
      r_mul_is_immediate = 0;
   end
   
   assign w_opcode = r_opcode_mem;
   assign w_var1   = r_var1_mem;
   assign w_var2   = r_var2_mem;
   

   stack main_stack (
       .clk(i_Clk),
       .i_reset(w_reset_H),
       .i_read_flag(r_stack_read_flag),
       .i_write_flag(r_stack_write_flag),
       .i_write_value(r_stack_write_value),
       .i_stack_reset(r_stack_reset),
       .o_stack_top_value(i_stack_top_value),
       .o_stack_error(i_stack_error)
   );

   RGB_LED RGB_LED (
       .i_sysclk(i_Clk),
       .LED1(r_RGB_LED_1),
       .LED2(r_RGB_LED_2),
       .o_LED_RGB_1(o_LED_RGB_1),
       .o_LED_RGB_2(o_LED_RGB_2)
   );


   /*ila_0  myila(.clk(i_Clk),
             .probe0(w_opcode),
             .probe1(0),
             .probe2(r_PC),
             .probe3(r_SM),
             .probe4(r_var1_mem),
             .probe5(0),
             .probe6(0),
             .probe7(0),
             .probe8(r_mem_read_DV),
             .probe9(r_mem_addr),
             .probe10(w_mem_ready),
             .probe11(w_var1),
             .probe12(w_mem_read_data),
             .probe13(w_temp_cache_hit),
             .probe14(w_temp_cache_value),
             .probe15(0)

            ); */

   `include "timing_tasks.vh"
   `include "LCD_tasks.vh"
   `include "led_tasks.vh"
   `include "register_tasks.vh"
   `include "control_tasks.vh"
   `include "stack_tasks.vh"
   `include "functions.vh"
   `include "seven_seg.vh"
   `include "opcode_select.vh"
   `include "uart_tasks.vh"
   `include "memory_tasks.vh"
   `include "alu_extended_tasks.vh"    

   initial begin
      o_TX_LCD_Count = 4'd1;
      o_TX_LCD_Byte = 8'b0;
      r_SM = NO_PROGRAM;
      r_timeout_counter = 0;
      o_LCD_reset_n = 1'b0;
      r_PC = 24'h0;
      r_zero_flag = 0;
      r_equal_flag = 0;
      r_carry_flag = 0;
      r_overflow_flag = 0;
      r_error_code = 8'h0;
      r_timeout_counter = 32'b0;
      r_seven_seg_value1 = 32'h20_10_00_07;
      r_seven_seg_value2 = 32'h21_21_21_21;
      o_led <= 16'h0;
      rx_count = 8'b0;
      o_ram_write_addr = 24'h0;
      r_ram_next_write_addr = 24'h0;
      r_stack_reset = 1'b0;
      r_msg_send_DV <= 1'b0;
      r_hcf_message_sent <= 1'b0;
      r_RGB_LED_1 = 12'h000;
      r_RGB_LED_2 = 12'h000;
      r_timing_start <= 0;
      r_timer_interrupt_counter <= 0;
      r_timer_interrupt_counter_sec <= 0;
      r_mem_write_DV <= 0;
      r_mem_read_DV <= 0;
      r_msg = 2048'b0;
      r_boot_flash = 0;
      r_cache_reset = 0;
      r_debug_flag = 0;
      r_debug_step_flag = 0;
      r_debug_step_run = 0;
   end

   always @(posedge i_Clk) begin
      if (w_reset_H) begin

         r_SM <= NO_PROGRAM;
         for (i = 0; i < 16; i = i + 1)
            r_register[i] <= 32'b0;

      end // if (w_reset_H)
    // else if(w_uart_rx_DV&w_uart_rx_value==8'h53&i_load_H) // Load start flag received and down button pressed
      else if(w_uart_rx_DV&w_uart_rx_value==8'h53) // Load start flag received ignore if button pressed
    begin
         r_SM <= LOADING_BYTE;
         r_load_byte_counter <= 0;
         o_ram_write_addr <= 24'h0;
         r_ram_next_write_addr <= 24'h0;
         r_checksum <= 16'h0;
         r_old_checksum <= 16'h0;
         r_RGB_LED_1 <= 12'h0;
         r_RGB_LED_2 <= 12'h0;
         o_led <= 16'h0;
         r_mem_write_DV <= 1'b0;
         r_mem_read_DV <= 1'b0;

      end
    else if(w_uart_rx_DV&w_uart_rx_value==8'h47) // Debug flag G sent
    begin
         r_debug_flag <= 1;
      end
    else if(w_uart_rx_DV&w_uart_rx_value==8'h67) // No debug flag g sent
    
    begin
         r_debug_flag <= 0;
      end
    else if(w_uart_rx_DV&w_uart_rx_value==8'h57) // Step flag W sent
    begin
         r_debug_step_flag <= 1;
      end
    else if(w_uart_rx_DV&w_uart_rx_value==8'h77) // No step flag w sent
    begin
         r_debug_step_flag <= 0;
      end 
        else if(w_uart_rx_DV&w_uart_rx_value==8'h6E) // Next command n sent
    begin
         r_debug_step_run <= 1;
      end else begin
         r_msg_send_DV <= 1'b0;

         if (r_timer_interrupt_counter > 32'hFFFFF) begin
            r_timer_interrupt_counter <= 0;
            r_timer_interrupt <= 1;
         end else begin
            r_timer_interrupt_counter <= r_timer_interrupt_counter + 1;
         end

         if (r_timer_interrupt_counter_sec > 100_000_000) begin
            r_timer_interrupt_counter_sec <= 0;
         end else begin
            r_timer_interrupt_counter_sec <= r_timer_interrupt_counter_sec + 1;
         end


         case (r_SM)
            NO_PROGRAM: begin
               r_seven_seg_value1 <= 32'h22222222;
               r_seven_seg_value2 <= 32'h22222222;

               if (r_timer_interrupt_counter_sec == 0) begin
                  case (r_boot_flash)
                     0: begin
                        r_RGB_LED_1  <= 12'h010;
                        r_RGB_LED_2  <= 12'h100;
                        //o_led[0]<=1;
                        r_boot_flash <= 1;
                     end
                     default: begin
                        r_RGB_LED_1  <= 12'h100;
                        r_RGB_LED_2  <= 12'h010;
                        //o_led[0]<=0;
                        r_boot_flash <= 0;
                     end
                  endcase
               end
            end

            LOADING_BYTE: begin

               if (w_mem_ready) begin
                  r_mem_write_DV <= 1'b0;
               end
               r_stack_reset <= 1'b1;

               r_seven_seg_value1 <= {
                  8'h24,
                  8'h22,
                  4'h0,
                  r_ram_next_write_addr[23:20],
                  4'h0,
                  r_ram_next_write_addr[19:16]
               };
               r_seven_seg_value2 <= {
                  4'h0,
                  r_ram_next_write_addr[15:12],
                  4'h0,
                  r_ram_next_write_addr[11:8],
                  4'h0,
                  r_ram_next_write_addr[7:4],
                  4'h0,
                  r_ram_next_write_addr[3:0]
               };

               if (w_uart_rx_DV) begin


                  case (w_uart_rx_value)
                     8'h58: // End char X
                        begin
                        if (r_load_byte_counter == 0) begin
                           r_SM <= LOAD_COMPLETE;
                           r_calc_checksum<=r_old_checksum+o_ram_write_addr[15:0]*2+o_ram_write_value[31:16]; //adding number byte to checksum for zeros
                           r_rec_checksum <= o_ram_write_value[15:0];
                           o_ram_write_value <= 32'h0;

                        end // (r_load_byte_counter==0)
                            else
                            begin
                           r_SM <= HCF_1;  // Halt and catch fire error
                           r_error_code <= ERR_DATA_LOAD;
                        end  // else (r_load_byte_counter==3)
                     end  // case 8'h58
                     8'h5A: // Start data flag Z
                        begin
                        r_PC_requested <= o_ram_write_value[23:0];
                     end
                     8'h0a: ;  // ignore LF
                     8'h0d: ;  // ignore CR
                     default: begin
                        case (r_load_byte_counter)
                           0: o_ram_write_value[31:28] = return_hex_from_ascii(w_uart_rx_value);
                           1: o_ram_write_value[27:24] = return_hex_from_ascii(w_uart_rx_value);
                           2: o_ram_write_value[23:20] = return_hex_from_ascii(w_uart_rx_value);
                           3: o_ram_write_value[19:16] = return_hex_from_ascii(w_uart_rx_value);
                           4: o_ram_write_value[15:12] = return_hex_from_ascii(w_uart_rx_value);
                           5: o_ram_write_value[11:8] = return_hex_from_ascii(w_uart_rx_value);
                           6: o_ram_write_value[7:4] = return_hex_from_ascii(w_uart_rx_value);
                           7: o_ram_write_value[3:0] = return_hex_from_ascii(w_uart_rx_value);
                           default: ;
                        endcase  //r_load_byte_counter
                        if (r_load_byte_counter == 7) begin
                           r_load_byte_counter <= 0;
                           case (r_RGB_LED_1)
                              12'h050: r_RGB_LED_1 <= 12'h005;
                              default: r_RGB_LED_1 <= 12'h050;
                           endcase
                           o_ram_write_addr <= r_ram_next_write_addr;
                           r_ram_next_write_addr <= r_ram_next_write_addr + 1;
                           if (r_ram_next_write_addr>24'h10_000) // Nexys has 128 MiB ram, but is addresses in 128 bit chunks and on 32 bits are used
                                begin
                              r_SM <= HCF_1;  // Halt and catch fire error
                              r_error_code <= ERR_OVERFLOW;
                           end
                           r_mem_addr <= r_ram_next_write_addr;
                           r_mem_write_data <= o_ram_write_value;
                           r_mem_write_DV <= 1'b1;

                           r_old_checksum <= r_checksum;
                           r_checksum <= r_checksum + o_ram_write_value[31:16] + o_ram_write_value[15:0];
                        end // if (r_load_byte_counter==3)
                            else
                            begin
                           r_load_byte_counter <= r_load_byte_counter + 1;
                        end  // else if (r_load_byte_counter==3)
                     end  // case default
                  endcase  // w_uart_rx_value
               end
            end

            LOAD_COMPLETE: begin
               r_seven_seg_value1 <= 32'h22222222;  // Blank 7 seg
               if (r_calc_checksum==r_rec_checksum) // Last value received should be checksum
                begin  // Reset all flags and jump to first instruction
                  o_LCD_reset_n <= 1'b0;
                  o_led <= 16'h0;
                  o_ram_write_addr <= 24'h0;
                  o_TX_LCD_Byte <= 8'b0;
                  o_TX_LCD_Count <= 4'd1;
                  r_carry_flag <= 1'b0;
                  r_debug_flag <= 1'b0;
                  r_debug_step_flag <= 1'b0;
                  r_debug_step_run <= 1'b0;
                  r_equal_flag <= 1'b0;
                  r_error_code <= 8'h0;
                  r_hcf_message_sent <= 1'b0;
                  r_interrupt_table[0] <= 0;  // blank timer interrupt
                  r_msg_send_DV <= 1'b0;
                  r_overflow_flag <= 1'b0;
                  r_PC <= r_PC_requested;
                  r_ram_next_write_addr <= 24'h0;
                  r_RGB_LED_1 <= 12'h000;
                  r_RGB_LED_2 <= 12'h000;
                  r_seven_seg_value1 <= 32'h22_22_22_22;
                  r_seven_seg_value2 <= 32'h22_22_22_22;
                  r_SM <= START_WAIT;
                  r_stack_reset <= 1'b0;
                  r_timeout_counter <= 0;
                  r_timer_interrupt <= 0;
                  r_timer_interrupt_counter <= 0;
                  r_timing_start <= 0;
                  r_zero_flag <= 0;
                  t_tx_message(8'd1);  // Load OK message
               end else begin
                  r_SM <= HCF_1;  // Halt and catch fire error
                  r_error_code <= ERR_CHECKSUM_LOAD;
                  t_tx_message(8'd2);  // Load error message
               end
            end

            // Delay to enable load message to be sent before starting
            START_WAIT: begin
               r_cache_reset <= 1'b1;
               r_msg_send_DV <= 1'b0;
               if (r_start_wait_counter == 0) begin
                  r_SM <= OPCODE_REQUEST;
                  r_seven_seg_value1 <= 32'h22_22_22_22;
                  r_seven_seg_value2 <= 32'h22_22_22_22;
               end else begin
                  r_start_wait_counter <= r_start_wait_counter - 1;
                  r_seven_seg_value1 <= 32'h21_21_21_21;
                  r_seven_seg_value2 <= 32'h21_21_21_21;
               end
            end

            // Delay to enable load message to be sent before starting
            UART_DELAY: begin
               r_msg_send_DV <= 1'b0;
               if (!w_sending_msg) begin
                  r_SM <= OPCODE_REQUEST;
               end

            end

            OPCODE_REQUEST: begin
               r_cache_reset <= 1'b0;
               o_led[0] <= i_switch[0];  // Temp showing cache enabled status.

               r_stack_write_flag <= 1'h0;
               r_stack_read_flag <= 1'h0;
               r_msg_send_DV <= 1'b0;
               r_extra_clock <= 2'b0;
               if (r_stack_write_flag) begin
                  r_stack_write_flag <= 0;
               end
               if (i_stack_error) begin
                  r_SM <= HCF_1;  // Halt and catch fire error 1
                  r_error_code <= ERR_STACK;
               end else begin
                  if (r_timer_interrupt && r_interrupt_table[0] != 24'h0) begin
                     r_stack_write_value <= {8'b0, r_PC};  // push PC on stack
                     r_stack_write_flag <= 1'b1;  // to move stack pointer
                     r_timer_interrupt <= 0;
                     r_PC <= r_interrupt_table[0];
                  end

                  r_mem_addr <= r_PC;
                  r_mem_read_DV <= 1'b1;
                  r_SM <= OPCODE_FETCH;
               end
            end

            OPCODE_FETCH: begin
               if (w_mem_ready) begin
                  r_opcode_mem<=w_mem_read_data[15:0]; // the memory location, allows read of code as well as data
                  r_mem_read_DV <= 1'b0;
                  r_SM <= OPCODE_FETCH2;
               end  // if ready asserted, else will loop until ready
            end

            OPCODE_FETCH2: begin
               r_reg_2 <= w_opcode[3:0];
               r_reg_1 <= w_opcode[7:4];
               r_SM <= VAR1_FETCH;
               r_mem_addr <= (r_PC + 1);
               r_mem_read_DV <= 1'b1;
            end


            VAR1_FETCH: begin
               if (w_mem_ready) begin
                  r_var1_mem<=w_mem_read_data; // the memory location, allows read of code as well as data
                  if (r_debug_flag&&w_opcode[15:12]!=4'hF) begin  // Ignore opcodes starting F as these are delay and
                     r_SM <= DEBUG_DATA;
                  end else begin
                     r_SM <= OPCODE_EXECUTE;
                  end
                  r_mem_read_DV <= 1'b0;

               end  // if ready asserted, else will loop until ready
            end


            DEBUG_DATA: begin
               t_debug_message;
               r_SM <= DEBUG_DATA2;
            end

            DEBUG_DATA2: begin
               r_msg_send_DV <= 1'b0;
               r_SM <= DEBUG_DATA3;
            end

            DEBUG_DATA3: begin
               if (!w_sending_msg) begin
                  r_SM <= OPCODE_EXECUTE;
                  if (r_debug_step_flag == 1'b1) begin
                     r_SM <= DEBUG_WAIT;
                  end else begin
                     r_SM <= OPCODE_EXECUTE;
                  end
               end
            end

            DEBUG_WAIT: begin
               if (r_debug_step_run == 1'b1) begin
                  r_debug_step_run <= 1'b0;
                  r_SM <= OPCODE_EXECUTE;
               end
            end

            OPCODE_EXECUTE: begin
               t_opcode_select;
            end  // case OPCODE_EXECUTE

            HCF_1: begin
               if (!r_hcf_message_sent) begin
                  r_hcf_message_sent <= 1'b1;
               end
               r_stack_write_flag <= 1'h0;
               r_stack_read_flag <= 1'h0;
               r_timeout_counter <= 0;
               r_SM <= HCF_2;
            end

            HCF_2: begin
               r_seven_seg_value1[31:8] <= 24'h230C0F;
               r_seven_seg_value1[7:0] <= r_error_code;
               r_seven_seg_value2 <= 32'h22_22_22_22;
               r_timeout_max <= 32'd100_000_000;
               if (r_timeout_counter >= r_timeout_max) begin
                  r_timeout_counter <= 0;
                  r_SM <= HCF_3;
               end  // if(r_timeout_counter>=DELAY_TIME)
                else
                begin
                  r_timeout_counter <= r_timeout_counter + 1;
               end  // else if(r_timeout_counter>=DELAY_TIME)
            end
            HCF_3: begin
               r_timeout_counter <= 0;
               r_SM <= HCF_4;
               r_error_display_type <= ~r_error_display_type;
            end
            HCF_4: begin
               if (r_error_display_type) begin
                  // ERR_INV_OPCODE=8'h1, ERR_INV_FSM_STATE=8'h2, ERR_STACK=8'h3, ERR_DATA_LOAD=8'h4, ERR_CHECKSUM_LOAD=8'h5;

                  case (r_error_code)
                     ERR_CHECKSUM_LOAD:
                     // incoming checksum
                     r_seven_seg_value1 <= {
                        4'h0,
                        r_rec_checksum[15:12],
                        4'h0,
                        r_rec_checksum[11:8],
                        4'h0,
                        r_rec_checksum[7:4],
                        4'h0,
                        r_rec_checksum[3:0]
                     };
                     ERR_DATA_LOAD:  // Load counter
              begin
                        r_seven_seg_value1 <= {
                           8'h24,
                           8'h24,
                           4'h0,
                           r_ram_next_write_addr[23:20],
                           4'h0,
                           r_ram_next_write_addr[19:16]
                        };
                        r_seven_seg_value2 <= {
                           4'h0,
                           r_ram_next_write_addr[15:12],
                           4'h0,
                           r_ram_next_write_addr[11:8],
                           4'h0,
                           r_ram_next_write_addr[7:4],
                           4'h0,
                           r_ram_next_write_addr[3:0]
                        };
                     end
                     default: // Also for opcode 1
                            // Blank then Program counter
                     begin
                        r_seven_seg_value1 <= {8'h22, 8'h22, 4'h0, r_PC[23:20], 4'h0, r_PC[19:16]};
                        r_seven_seg_value2 <= {
                           4'h0, r_PC[15:12], 4'h0, r_PC[11:8], 4'h0, r_PC[7:4], 4'h0, r_PC[3:0]
                        };
                     end


                  endcase
               end   // if (r_error_display_type)
                else
                begin

                  case (r_error_code)
                     ERR_CHECKSUM_LOAD:
                     // Calculated checksum
                     r_seven_seg_value1 <= {
                        4'h0,
                        r_calc_checksum[15:12],
                        4'h0,
                        r_calc_checksum[11:8],
                        4'h0,
                        r_calc_checksum[7:4],
                        4'h0,
                        r_calc_checksum[3:0]
                     };

                     ERR_DATA_LOAD: begin
                        // Three blanks then loading byte counter
                        r_seven_seg_value1 <= 32'h22_22_22_22;
                        r_seven_seg_value2 <= {8'h22, 8'h22, 8'h22, 6'h0, r_load_byte_counter[1:0]};
                     end
                     default // Also for opcode 1
                        // Opcode selected print OP on 7seg1, and code on 7seg2
                     begin
                        r_seven_seg_value1 <= 32'h00_25_0C_0D;
                        r_seven_seg_value2 <= {
                           4'h0,
                           w_opcode[15:12],
                           4'h0,
                           w_opcode[11:8],
                           4'h0,
                           w_opcode[7:4],
                           4'h0,
                           w_opcode[3:0]
                        };
                     end

                  endcase

               end  // else if (r_error_display_type)

               r_timeout_max <= 32'd100_000_000;
               if (r_timeout_counter >= r_timeout_max) begin
                  r_timeout_counter <= 0;
                  r_SM <= HCF_1;
               end  // if(r_timeout_counter>=DELAY_TIME)
                else
                begin
                  r_timeout_counter <= r_timeout_counter + 1;
               end  // else if(r_timeout_counter>=DELAY_TIME)

            end
            
             MULTIPLY_CALC: begin
    // Wait for pipeline stage 1 (MREG) - multiply is computed
    // by the free-running pipeline from r_mul_operand_a/b
    r_SM <= MULTIPLY_PIPE;
end

MULTIPLY_PIPE: begin
    // Wait for pipeline stage 2 (PREG) - result now in r_mul_result_hi/lo
    r_SM <= MULTIPLY_WRITEBACK;
end

MULTIPLY_WRITEBACK: begin
    // Stage result into writeback pipeline
    if (r_mul_is_high)
        r_writeback_value <= r_mul_result_hi;
    else
        r_writeback_value <= r_mul_result_lo;
    r_writeback_reg <= r_mul_dest_reg;

    // Flags from registered values
    if (r_mul_is_high) begin
        r_zero_flag     <= (r_mul_result_hi == 32'b0);
        r_sign_flag     <= r_mul_result_hi[31];
        r_overflow_flag <= 1'b0;
    end else begin
        r_zero_flag     <= (r_mul_result_lo == 32'b0);
        r_sign_flag     <= r_mul_result_lo[31];
        if (r_mul_is_unsigned)
            r_overflow_flag <= (r_mul_result_hi != 32'b0);
        else
            r_overflow_flag <= (r_mul_result_hi != {32{r_mul_result_lo[31]}});
    end

    // PC increment depends on instruction type
    if (r_mul_is_immediate)
        r_PC <= r_PC + 2;
    else
        r_PC <= r_PC + 1;

    r_SM <= WRITEBACK;
end

            HALTED: begin
               // CPU halted - do nothing until reset
            end

            DIVIDE_STEP: begin
               // Shared division iteration - avoids re-evaluating opcode casez each cycle
               if (r_div_counter < 6'd32) begin
                  // Restoring division step
                  if ({r_div_remainder[30:0], r_div_dividend[31]} >= r_div_divisor) begin
                     r_div_remainder <= {r_div_remainder[30:0], r_div_dividend[31]} - r_div_divisor;
                     r_div_quotient <= {r_div_quotient[30:0], 1'b1};
                  end
                  else begin
                     r_div_remainder <= {r_div_remainder[30:0], r_div_dividend[31]};
                     r_div_quotient <= {r_div_quotient[30:0], 1'b0};
                  end
                  r_div_dividend <= {r_div_dividend[30:0], 1'b0};
                  r_div_counter <= r_div_counter + 1;
               end
               else begin
                  // Division complete - write result based on op type
                  if (r_div_op == DIV_OP_DIV) begin
                     if (r_div_is_signed && r_div_sign_q)
                        r_writeback_value <= ~r_div_quotient + 1;
                     else
                        r_writeback_value <= r_div_quotient;
                     r_zero_flag <= (r_div_quotient == 0) ? 1'b1 : 1'b0;
                  end
                  else begin  // DIV_OP_MOD
                     if (r_div_is_signed && r_div_sign_r)
                        r_writeback_value <= ~r_div_remainder + 1;
                     else
                        r_writeback_value <= r_div_remainder;
                     r_zero_flag <= (r_div_remainder == 0) ? 1'b1 : 1'b0;
                  end
                  r_writeback_reg <= r_div_dest_reg;
                  r_overflow_flag <= 1'b0;
                  r_div_op <= DIV_OP_NONE;
                  r_PC <= r_PC + (r_div_pc_inc ? 2 : 1);
                  r_SM <= WRITEBACK;
               end
            end

            WRITEBACK: begin
               r_register[r_writeback_reg] <= r_writeback_value;
               r_stack_read_flag <= 1'h0;
               r_SM <= OPCODE_REQUEST;
            end

            default: r_SM <= HCF_1;  // loop in error
         endcase  // case(r_SM)
      end  // else if (w_reset_H)
   end  // always @(posedge i_Clk)
   
   //=========================================================================
   // Bit manipulation helper functions (active during single cycles)
   //=========================================================================
   // Population count - count number of 1 bits
   function [5:0] popcount;
      input [31:0] val;
      integer i;
      begin
         popcount = 0;
         for (i = 0; i < 32; i = i + 1) begin
            popcount = popcount + val[i];
         end
      end
   endfunction
   
   // Count leading zeros
   function [5:0] count_leading_zeros;
      input [31:0] val;
      integer i;
      begin
         count_leading_zeros = 32;
         for (i = 31; i >= 0; i = i - 1) begin
            if (val[i] && count_leading_zeros == 32 - i - 1 + 32) begin
               // This is tricky in a function; use casez instead
            end
         end
         // Simpler implementation:
         casez (val)
            32'b1???????????????????????????????: count_leading_zeros = 0;
            32'b01??????????????????????????????: count_leading_zeros = 1;
            32'b001?????????????????????????????: count_leading_zeros = 2;
            32'b0001????????????????????????????: count_leading_zeros = 3;
            32'b00001???????????????????????????: count_leading_zeros = 4;
            32'b000001??????????????????????????: count_leading_zeros = 5;
            32'b0000001?????????????????????????: count_leading_zeros = 6;
            32'b00000001????????????????????????: count_leading_zeros = 7;
            32'b000000001???????????????????????: count_leading_zeros = 8;
            32'b0000000001??????????????????????: count_leading_zeros = 9;
            32'b00000000001?????????????????????: count_leading_zeros = 10;
            32'b000000000001????????????????????: count_leading_zeros = 11;
            32'b0000000000001???????????????????: count_leading_zeros = 12;
            32'b00000000000001??????????????????: count_leading_zeros = 13;
            32'b000000000000001?????????????????: count_leading_zeros = 14;
            32'b0000000000000001????????????????: count_leading_zeros = 15;
            32'b00000000000000001???????????????: count_leading_zeros = 16;
            32'b000000000000000001??????????????: count_leading_zeros = 17;
            32'b0000000000000000001?????????????: count_leading_zeros = 18;
            32'b00000000000000000001????????????: count_leading_zeros = 19;
            32'b000000000000000000001???????????: count_leading_zeros = 20;
            32'b0000000000000000000001??????????: count_leading_zeros = 21;
            32'b00000000000000000000001?????????: count_leading_zeros = 22;
            32'b000000000000000000000001????????: count_leading_zeros = 23;
            32'b0000000000000000000000001???????: count_leading_zeros = 24;
            32'b00000000000000000000000001??????: count_leading_zeros = 25;
            32'b000000000000000000000000001?????: count_leading_zeros = 26;
            32'b0000000000000000000000000001????: count_leading_zeros = 27;
            32'b00000000000000000000000000001???: count_leading_zeros = 28;
            32'b000000000000000000000000000001??: count_leading_zeros = 29;
            32'b0000000000000000000000000000001?: count_leading_zeros = 30;
            32'b00000000000000000000000000000001: count_leading_zeros = 31;
            32'b00000000000000000000000000000000: count_leading_zeros = 32;
         endcase
      end
   endfunction
   
   // Count trailing zeros
   function [5:0] count_trailing_zeros;
      input [31:0] val;
      begin
         casez (val)
            32'b???????????????????????????????1: count_trailing_zeros = 0;
            32'b??????????????????????????????10: count_trailing_zeros = 1;
            32'b?????????????????????????????100: count_trailing_zeros = 2;
            32'b????????????????????????????1000: count_trailing_zeros = 3;
            32'b???????????????????????????10000: count_trailing_zeros = 4;
            32'b??????????????????????????100000: count_trailing_zeros = 5;
            32'b?????????????????????????1000000: count_trailing_zeros = 6;
            32'b????????????????????????10000000: count_trailing_zeros = 7;
            32'b???????????????????????100000000: count_trailing_zeros = 8;
            32'b??????????????????????1000000000: count_trailing_zeros = 9;
            32'b?????????????????????10000000000: count_trailing_zeros = 10;
            32'b????????????????????100000000000: count_trailing_zeros = 11;
            32'b???????????????????1000000000000: count_trailing_zeros = 12;
            32'b??????????????????10000000000000: count_trailing_zeros = 13;
            32'b?????????????????100000000000000: count_trailing_zeros = 14;
            32'b????????????????1000000000000000: count_trailing_zeros = 15;
            32'b???????????????10000000000000000: count_trailing_zeros = 16;
            32'b??????????????100000000000000000: count_trailing_zeros = 17;
            32'b?????????????1000000000000000000: count_trailing_zeros = 18;
            32'b????????????10000000000000000000: count_trailing_zeros = 19;
            32'b???????????100000000000000000000: count_trailing_zeros = 20;
            32'b??????????1000000000000000000000: count_trailing_zeros = 21;
            32'b?????????10000000000000000000000: count_trailing_zeros = 22;
            32'b????????100000000000000000000000: count_trailing_zeros = 23;
            32'b???????1000000000000000000000000: count_trailing_zeros = 24;
            32'b??????10000000000000000000000000: count_trailing_zeros = 25;
            32'b?????100000000000000000000000000: count_trailing_zeros = 26;
            32'b????1000000000000000000000000000: count_trailing_zeros = 27;
            32'b???10000000000000000000000000000: count_trailing_zeros = 28;
            32'b??100000000000000000000000000000: count_trailing_zeros = 29;
            32'b?1000000000000000000000000000000: count_trailing_zeros = 30;
            32'b10000000000000000000000000000000: count_trailing_zeros = 31;
            32'b00000000000000000000000000000000: count_trailing_zeros = 32;
         endcase
      end
   endfunction
   
   // Bit reverse
   function [31:0] bit_reverse;
      input [31:0] val;
      integer i;
      begin
         for (i = 0; i < 32; i = i + 1) begin
            bit_reverse[31-i] = val[i];
         end
      end
   endfunction

endmodule
