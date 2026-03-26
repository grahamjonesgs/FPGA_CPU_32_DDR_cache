/*// Set reg from memory location
// On completion
// Increment PC 3
// Increment r_SM_msg
task t_set_reg_from_memory;
input [31:0] i_location; // Not used here, but needed to show this is a two word opcode
    begin
        if(r_extra_clock==0)
        begin
           r_extra_clock<=1'b1;
        end
        else
        begin
            r_register[r_reg_2]<=w_mem; // the memory location, allows read of code as well as data
            r_SM<=OPCODE_REQUEST;
            r_PC<=r_PC+2;
        end
    end
endtask

// Set mem location from register
// On completion
// Increment PC 3
// Increment r_SM_msg
task t_set_memory_from_reg;
input [31:0] i_location; // Not used here, but needed to show this is a two word opcode
    begin
        if(r_extra_clock==0)
        begin
            r_extra_clock<=1'b1;
        end
        else
        begin

            //    if (w_dout_opcode_exec) // works as the memory read address is set to same as i_location already
            //    begin
            //         r_SM<=HCF_1; // Halt and catch fire error
            //        r_error_code<=ERR_SEG_WRITE_TO_CODE;
             //   end
             //   else
             //   begin
            o_ram_write_addr<=w_var1;
            o_ram_write_value<=r_register[r_reg_2];
            o_ram_write_DV<=1'b1;
            r_SM<=OPCODE_REQUEST;
            r_PC<=r_PC+2;
       // end
       end
    end
endtask
*/

// Copy from second reg to first
task t_copy_regs;
   begin
      r_writeback_value <= r_reg_port_b;
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// Set reg with value
task t_set_reg;
   input [31:0] i_value;
   begin
      r_writeback_value <= i_value;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// Set reg with flags
task t_set_reg_flags;
   begin
      r_writeback_value <= {r_zero_flag, r_equal_flag, r_carry_flag, r_overflow_flag, 28'b0};
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// Bitwise operations

// AND first reg with second, result in first
task t_and_regs;
   begin
      r_writeback_value <= r_reg_port_a & r_reg_port_b;
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// OR first reg with second, result in first
task t_or_regs;
   begin
      r_writeback_value <= r_reg_port_a | r_reg_port_b;
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// XOR first reg with second, result in first
task t_xor_regs;
   begin
      r_writeback_value <= r_reg_port_a ^ r_reg_port_b;
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// AND reg with value
task t_and_reg_value;
   input [31:0] i_value;
   begin
      r_writeback_value <= r_reg_port_b & i_value;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// OR reg with value
task t_or_reg_value;
   input [31:0] i_value;
   begin
      r_writeback_value <= r_reg_port_b | i_value;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// XOR reg with value
task t_xor_reg_value;
   input [31:0] i_value;
   begin
      r_writeback_value <= r_reg_port_b ^ i_value;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// Arithmetic operations

// Add value to reg
task t_add_value;
   input [31:0] i_value;
   reg [31:0] hold;
   begin
      {r_carry_flag, hold} = {1'b0, r_reg_port_b} + {1'b0, i_value};
      r_writeback_set_zero_flag <= 1'b1;
      r_sign_flag <= hold[31];
      r_overflow_flag <= (r_reg_port_b[31]&&i_value[31]&&!hold[31])||(!r_reg_port_b[31]&&!i_value[31]&&hold[31]) ? 1'b1 : 1'b0;
      r_writeback_value <= hold;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// Subtract value from reg
task t_minus_value;
   input [31:0] i_value;
   reg [31:0] hold;
   begin
      {r_carry_flag, hold} = {1'b0, r_reg_port_b} - {1'b0, i_value};
      r_writeback_set_zero_flag <= 1'b1;
      r_sign_flag <= hold[31];
      r_overflow_flag <= (r_reg_port_b[31]&&!i_value[31]&&!hold[31])||(!r_reg_port_b[31]&&i_value[31]&&hold[31]) ? 1'b1 : 1'b0;
      r_writeback_value <= hold;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// Decrement reg
task t_dec_reg;
   reg [31:0] hold;
   begin
      {r_carry_flag, hold} = {1'b0, r_reg_port_b} - {33'b1};
      r_writeback_set_zero_flag <= 1'b1;
      r_sign_flag <= hold[31];
      r_overflow_flag <= (r_reg_port_b[31] && !hold[31]) ? 1'b1 : 1'b0;
      r_writeback_value <= hold;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// Increment reg
task t_inc_reg;
   reg [31:0] hold;
   begin
      {r_carry_flag, hold} = {1'b0, r_reg_port_b} + 33'b1;
      r_writeback_set_zero_flag <= 1'b1;
      r_sign_flag <= hold[31];
      r_overflow_flag <= (!r_reg_port_b[31] && hold[31]) ? 1'b1 : 1'b0;
      r_writeback_value <= hold;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// Compare register to value (no register write)
task t_compare_reg_value;
   input [31:0] i_value;
   reg signed [31:0] s_reg;
   reg signed [31:0] s_val;
   begin
      s_reg = r_reg_port_b;
      s_val = i_value;
      r_equal_flag <= (r_reg_port_b == i_value) ? 1'b1 : 1'b0;
      r_less_flag <= (s_reg < s_val) ? 1'b1 : 1'b0;
      r_sign_flag <= (s_reg - s_val) < 0 ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;
   end
endtask

// Subtract regs
task t_minus_regs;
   reg [31:0] hold;
   begin
      {r_carry_flag, hold} = {1'b0, r_reg_port_a} - {1'b0, r_reg_port_b};
      r_writeback_set_zero_flag <= 1'b1;
      r_sign_flag <= hold[31];
      r_overflow_flag <= (r_reg_port_a[31]&&!r_reg_port_b[31]&&!hold[31])||(!r_reg_port_a[31]&&r_reg_port_b[31]&&hold[31]) ? 1'b1 : 1'b0;
      r_writeback_value <= hold;
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// Negate reg
task t_negate_reg;
   begin
      r_writeback_value <= ~r_reg_port_b + 1;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// Left shift reg
task t_left_shift_reg;
   begin
      r_writeback_value <= r_reg_port_b << 1;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// Right shift reg
task t_right_shift_reg;
   begin
      r_writeback_value <= r_reg_port_b >> 1;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// Left shift arithmetical reg
task t_left_shift_a_reg;
   begin
      r_writeback_value <= r_reg_port_b <<< 1;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// Right shift arithmetical reg
task t_right_shift_a_reg;
   reg signed [31:0] signed_val;
   begin
      signed_val = r_reg_port_b;
      r_writeback_value <= signed_val >>> 1;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// Compare registers (no register write)
task t_compare_regs;
   reg signed [31:0] s_a;
   reg signed [31:0] s_b;
   begin
      s_a = r_reg_port_a;
      s_b = r_reg_port_b;
      r_equal_flag <= (r_reg_port_a == r_reg_port_b) ? 1'b1 : 1'b0;
      r_less_flag <= (s_a < s_b) ? 1'b1 : 1'b0;
      r_sign_flag <= (s_a - s_b) < 0 ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

//=============================================================================
// ADDRR - Add registers
//=============================================================================
task t_add_regs;
   reg [32:0] hold;
   begin
      hold = {1'b0, r_reg_port_a} + {1'b0, r_reg_port_b};
      r_carry_flag <= hold[32];
      r_writeback_set_zero_flag <= 1'b1;
      r_sign_flag <= hold[31];
      r_overflow_flag <= (r_reg_port_a[31] == r_reg_port_b[31]) &&
                         (hold[31] != r_reg_port_a[31]) ? 1'b1 : 1'b0;
      r_writeback_value <= hold[31:0];
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

//=============================================================================
// CMPLTRR - Compare less-than registers (no register write)
//=============================================================================
task t_compare_less_than_regs;
   reg signed [31:0] signed_reg1;
   reg signed [31:0] signed_reg2;
   begin
      signed_reg1 = r_reg_port_a;
      signed_reg2 = r_reg_port_b;

      r_equal_flag <= (signed_reg1 < signed_reg2) ? 1'b1 : 1'b0;
      r_carry_flag <= (r_reg_port_a < r_reg_port_b) ? 1'b1 : 1'b0;
      r_zero_flag <= (r_reg_port_a == r_reg_port_b) ? 1'b1 : 1'b0;

      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask
