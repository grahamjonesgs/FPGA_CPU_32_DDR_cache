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
         r_PC <= i_value[24:0];  // jump
      end // if(i_condition)
        else
        begin
         r_SM <= OPCODE_REQUEST;
         r_PC <= r_PC + 2;
      end  // else if(i_condition)
   end
endtask

// Call if condition met — push return address (PC+2) onto DDR2 stack, jump to target.
// 2-word instruction; uses multi-cycle DDR2 write (r_extra_clock pattern).
// w_var1 (the jump target) stays valid across cycles as the instruction stays latched.
task t_cond_call;
   input [31:0] i_value;
   input i_condition;
   begin
      if (i_condition) begin
         if (r_extra_clock == 0) begin
            r_SP             <= r_SP - 1;
            r_mem_addr       <= r_SP[24:0] - 25'd1;
            r_mem_write_data <= {7'b0, r_PC + 25'd2};
            r_mem_write_DV   <= 1'b1;
            r_extra_clock    <= 1'b1;
         end else begin
            if (w_mem_ready) begin
               r_mem_write_DV <= 1'b0;
               r_SM           <= OPCODE_REQUEST;
               r_PC           <= i_value[24:0];
            end
         end
      end else begin
         r_SM <= OPCODE_REQUEST;
         r_PC <= r_PC + 2;
      end
   end
endtask

// Return from call — pop return address from DDR2 stack, jump to it.
// 1-word instruction; uses multi-cycle DDR2 read (r_extra_clock pattern).
task t_ret;
   begin
      if (r_extra_clock == 0) begin
         r_mem_addr    <= r_SP[24:0];
         r_mem_read_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end else begin
         if (w_mem_ready) begin
            r_PC          <= w_mem_read_data[24:0];
            r_SP          <= r_SP + 1;
            r_mem_read_DV <= 1'b0;
            r_SM          <= OPCODE_REQUEST;
         end
      end
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

// Stop and hang - enters low-power halted state until reset
// On completion
// Do not change PC
task t_halt;
   begin
      r_SM <= HALTED_BREAK;
   end
endtask

// Reset PC
// On completion
// Do not change PC
// Increment r_SM
task t_reset;
   begin
      r_SM <= OPCODE_REQUEST;
      r_PC <= 25'h1;
   end  // Case FFFF
endtask

// Set interrupt from regs first is interrupt in lowest byte, then address of handlers
// On completion
// Increment PC
// Increment r_SM
task t_set_interrupt_regs;
   reg [1:0] r_interrupt_number;
   begin
      r_interrupt_number = r_reg_port_a[1:0];
      r_interrupt_table[r_interrupt_number] <= r_reg_port_b[24:0];
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask



