// Jump if condition met
// On completion
// Increment PC 2 or jump
// Increment r_SM
task t_cond_jump;
   input [31:0] i_value;
   input i_condition;
   begin
      if (i_condition) begin
         r_SM <= OPCODE_REQUEST;
         r_PC <= i_value[23:0];  // jump
      end // if(i_condition)
        else
        begin
         r_SM <= OPCODE_REQUEST;
         r_PC <= r_PC + 2;
      end  // else if(i_condition)
   end
endtask

// Call if condition met - push PC on stack
// On completion
// PC  set to value, or increment by 2
// Increment r_SM
task t_cond_call;
   input [31:0] i_value;
   input i_condition;
   begin
      if (i_condition) begin
         r_stack_write_value = {8'b0, r_PC + 24'd2};  // push PC on stack
         r_stack_write_flag <= 1'b1;  // to move stack pointer
         r_SM <= OPCODE_REQUEST;
         r_PC <= i_value[23:0];
      end // if(i_condition)
        else
        begin
         r_SM <= OPCODE_REQUEST;
         r_PC <= r_PC + 2;
      end  // else if(i_condition)
   end
endtask

// Return from call, pop new pc from stack
// On completion
// PC  set to top of stack
// Increment r_SM
task t_ret;
   begin
      r_stack_read_flag <= 1'b1;  // to move stack pointer
      r_SM <= OPCODE_REQUEST;
      r_PC <= i_stack_top_value[23:0];  // Pop PC from stack plus 2 to jump over call
   end
endtask

// Do nothing
// On completion
// Increment PC
// Increment r_SM
task t_nop;
   begin
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// Stop and hang
// On completion
// Do not change PC
// Increment r_SM
task t_halt;
   begin
      r_SM <= OPCODE_REQUEST;
   end
endtask

// Reset PC
// On completion
// Do not change PC
// Increment r_SM
task t_reset;
   begin
      r_SM <= OPCODE_REQUEST;
      r_PC <= 24'h1;
   end  // Case FFFF
endtask

// Set interrupt from regs first is interrupt in lowest byte, then address of handlers
// On completion
// Increment PC
// Increment r_SM
task t_set_interrupt_regs;
   reg [1:0] r_interrupt_number;
   begin
      r_interrupt_number = r_register[r_reg_1][1:0];
      r_interrupt_table[r_interrupt_number] <= r_register[r_reg_2][23:0];
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask



