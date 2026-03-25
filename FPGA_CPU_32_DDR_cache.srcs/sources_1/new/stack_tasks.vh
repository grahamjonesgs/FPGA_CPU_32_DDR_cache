// Push value onto stack
// On completion
// Increment PC by 2
// Increment r_SM_msg
task t_stack_push_value;
   input [31:0] i_value;
   begin
      r_stack_write_value <= i_value;
      r_stack_write_flag <= 1'h1;  // to move stack pointer 1
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;
   end
endtask

// Push register onto stack
// On completion
// increment PC
// increment r_SM_msg
task t_stack_push_reg;
   begin
      r_stack_write_flag <= 1'h1;  // to move stack pointer 1
      r_stack_write_value <= r_reg_port_b;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;

   end
endtask

// Pop register from stack
// On completion
// increment PC
// increment r_SM_msg
task t_stack_pop_reg;
   begin
      r_writeback_value <= i_stack_top_value;
      r_writeback_reg <= r_reg_2;
      r_stack_read_flag <= 1'h1;  // to move stack pointer
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask


