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
// On completion
// Increment PC
// Increment r_SM_msg
task t_copy_regs;
   begin
      r_register[r_reg_1] <= r_register[r_reg_2];
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// Set reg with value
// On completion
// Increment PC 2
// Increment r_SM_msg
task t_set_reg;
   input [31:0] i_value;
   begin
      r_register[r_reg_2] <= i_value;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;
   end
endtask

// Set reg with value
// On completion
// Increment PC
// Increment r_SM_msg
task t_set_reg_flags;
   begin
      r_register[r_reg_2] <= {r_zero_flag, r_equal_flag, r_carry_flag, r_overflow_flag, 28'b0};
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// Bitwise operations

// AND first reg with second, result in first
// On completion
// Increment PC
// Increment r_SM_msg
task t_and_regs;
   begin
      r_register[r_reg_1] <= r_register[r_reg_1] & r_register[r_reg_2];
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// OR first reg with second, result in first
// On completion
// Increment PC
// Increment r_SM_msg
task t_or_regs;
   begin
      r_register[r_reg_1] <= r_register[r_reg_1] | r_register[r_reg_2];
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// XOR first reg with second, result in first
// On completion
// Increment PC
// Increment r_SM_msg
task t_xor_regs;
   begin
      r_register[r_reg_1] <= r_register[r_reg_1] ^ r_register[r_reg_2];
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// AND first reg with value, result in first
// On completion
// Increment PC by 2
// Increment r_SM_msg
task t_and_reg_value;
   input [31:0] i_value;
   begin
      r_register[r_reg_2] <= r_register[r_reg_2] & i_value;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;
   end
endtask

// OR first reg with value, result in first
// On completion
// Increment PC by 2
// Increment r_SM_msg
task t_or_reg_value;
   input [31:0] i_value;
   begin
      r_register[r_reg_2] <= r_register[r_reg_2] | i_value;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;
   end
endtask

// XOR first reg with value, result in first
// On completion
// Increment PC by 2
// Increment r_SM_msg
task t_xor_reg_value;
   input [31:0] i_value;
   begin
      r_register[r_reg_2] <= r_register[r_reg_2] ^ i_value;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;
   end
endtask

// Arithmetic operations

// Inc reg by value
// On completion
// Increment PC 2
// Increment r_SM_msg
// Update zero, carry
task t_add_value;
   input [31:0] i_value;
   reg [31:0] hold;
   begin
      {r_carry_flag, hold} = {1'b0, r_register[r_reg_2]} + {1'b0, i_value};
      r_zero_flag <= hold == 0 ? 1'b1 : 1'b0;
      r_overflow_flag = (r_register[r_reg_2][31]&&i_value[31]&&!hold[31])||(!r_register[r_reg_2][31]&&!i_value[31]&&hold[31]) ? 1'b1 : 1'b0;
      r_register[r_reg_2] <= hold;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;

   end
endtask

// Dec reg by value
// On completion
// Increment PC 2
// Increment r_SM_msg
task t_minus_value;
   input [31:0] i_value;
   reg [31:0] hold;
   begin
      {r_carry_flag, hold} = {1'b0, r_register[r_reg_2]} - {1'b0, i_value};
      r_zero_flag <= hold == 0 ? 1'b1 : 1'b0;
      r_overflow_flag = (r_register[r_reg_2][31]&&!i_value[31]&&!hold[31])||(!r_register[r_reg_2][31]&&i_value[31]&&hold[31]) ? 1'b1 : 1'b0;
      r_register[r_reg_2] <= hold;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;
   end
endtask

// Dec reg
// On completion
// Increment PC
// Increment r_SM_msg
task t_dec_reg;
   reg [31:0] hold;
   begin
      {r_carry_flag, hold} = {1'b0, r_register[r_reg_2]} - {33'b1};
      r_zero_flag <= hold == 0 ? 1'b1 : 1'b0;
      r_overflow_flag = (r_register[r_reg_2][31] && !hold[31]) ? 1'b1 : 1'b0;
      r_register[r_reg_2] <= hold;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// Inc reg
// On completion
// Increment PC
// Increment r_SM_msg
task t_inc_reg;
   reg [31:0] hold;
   begin
      {r_carry_flag, hold} = {1'b0, r_register[r_reg_2]} + 33'b1;
      r_zero_flag <= hold == 0 ? 1'b1 : 1'b0;
      r_overflow_flag = (!r_register[r_reg_2][31] && hold[31]) ? 1'b1 : 1'b0;
      r_register[r_reg_2] <= hold;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// Compare register to value
// On completion
// Increment PC 2
// Increment r_SM_msg
task t_compare_reg_value;
   input [31:0] i_value;
   begin
      r_equal_flag <= r_register[r_reg_2] == i_value ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;
   end
endtask

// Add second reg to first, result in first
// On completion
// Increment PC
// Increment r_SM_msg
task t_add_regs;
   reg [31:0] hold;
   begin

      {r_carry_flag, hold} = {1'b0, r_register[r_reg_1]} + {1'b0, r_register[r_reg_2]};
      r_zero_flag <= hold == 0 ? 1'b1 : 1'b0;
      r_overflow_flag = (r_register[r_reg_1][31]&&r_register[r_reg_2][31]&&!hold[31])||(!r_register[r_reg_1][31]&&!r_register[r_reg_2][31]&&hold[31]) ? 1'b1 : 1'b0;
      r_register[r_reg_1] <= hold;

      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;

   end
endtask

// Minus second reg from first, result in first
// On completion
// Increment PC
// Increment r_SM_msg
task t_minus_regs;
   reg [31:0] hold;
   begin
      {r_carry_flag, hold} = {1'b0, r_register[r_reg_1]} - {1'b0, r_register[r_reg_2]};
      r_zero_flag <= hold == 0 ? 1'b1 : 1'b0;
      r_overflow_flag = (r_register[r_reg_1][31]&&!r_register[r_reg_2][31]&&!hold[31])||(!r_register[r_reg_1][31]&&r_register[r_reg_2][31]&&hold[31]) ? 1'b1 : 1'b0;
      r_register[r_reg_1] <= hold;

      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// Negate reg
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_negate_reg;
   begin
      r_register[r_reg_2] <= ~r_register[r_reg_2] + 1;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// Left shift reg
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_left_shift_reg;
   begin
      r_register[r_reg_2] <= r_register[r_reg_2] << 1;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// Right shift reg
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_right_shift_reg;
   begin
      r_register[r_reg_2] <= r_register[r_reg_2] >> 1;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// Left shift arithmetical reg
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_left_shift_a_reg;
   begin
      r_register[r_reg_2] <= r_register[r_reg_2] <<< 1;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// Right shift arithmetical reg
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_right_shift_a_reg;
   begin
      r_register[r_reg_2] <= r_register[r_reg_2] >>> 1;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask


// Compare registers
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_compare_regs;
   begin
      r_equal_flag <= r_register[r_reg_1] == r_register[r_reg_2] ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask


