// Stack tasks — stack lives in DDR2 RAM, top of 128 MiB, growing downward.
// Convention: r_SP points to the last pushed item (full descending).
//   PUSH: r_SP--; DDR2[r_SP] = value
//   POP:  value = DDR2[r_SP]; r_SP++
// All operations use the multi-cycle DDR2 interface (r_extra_clock pattern).
// R15 is the frame pointer by software convention.

// Push register onto stack
// 1-word instruction (PC+1)
task t_stack_push_reg;
   begin
      if (r_extra_clock == 0) begin
         r_SP             <= r_SP - 1;
         r_mem_addr       <= r_SP[24:0] - 25'd1;
         r_mem_write_data <= r_reg_port_b;
         r_mem_write_DV   <= 1'b1;
         r_extra_clock    <= 1'b1;
      end else begin
         if (w_mem_ready) begin
            r_mem_write_DV <= 1'b0;
            r_SM           <= OPCODE_REQUEST;
            r_PC           <= r_PC + 1;
         end
      end
   end
endtask

// Push 32-bit immediate value onto stack
// 2-word instruction (PC+2)
task t_stack_push_value;
   input [31:0] i_value;
   begin
      if (r_extra_clock == 0) begin
         r_SP             <= r_SP - 1;
         r_mem_addr       <= r_SP[24:0] - 25'd1;
         r_mem_write_data <= i_value;
         r_mem_write_DV   <= 1'b1;
         r_extra_clock    <= 1'b1;
      end else begin
         if (w_mem_ready) begin
            r_mem_write_DV <= 1'b0;
            r_SM           <= OPCODE_REQUEST;
            r_PC           <= r_PC + 2;
         end
      end
   end
endtask

// Pop stack into register
// 1-word instruction (PC+1)
task t_stack_pop_reg;
   begin
      if (r_extra_clock == 0) begin
         r_mem_addr    <= r_SP[24:0];
         r_mem_read_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end else begin
         if (w_mem_ready) begin
            r_writeback_value <= w_mem_read_data;
            r_writeback_reg   <= r_reg_2;
            r_SP              <= r_SP + 1;
            r_mem_read_DV     <= 1'b0;
            r_SM              <= WRITEBACK;
            r_PC              <= r_PC + 1;
         end
      end
   end
endtask

// GETSP — copy stack pointer value into register
// 1-word instruction (PC+1)
task t_get_sp;
   begin
      r_writeback_value <= {6'b0, r_SP};
      r_writeback_reg   <= r_reg_2;
      r_SM              <= WRITEBACK;
      r_PC              <= r_PC + 1;
   end
endtask

// SETSP — set stack pointer from register
// 1-word instruction (PC+1)
task t_set_sp;
   begin
      r_SP <= {2'b0, r_reg_port_b[24:0]};
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// ADDSP — add signed 32-bit immediate to stack pointer (allocate/free locals)
// 2-word instruction (PC+2)
task t_add_sp;
   input [31:0] i_value;
   begin
      r_SP <= r_SP + $signed(i_value[25:0]);
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;
   end
endtask

// CALLR — call to address held in register (for function pointers)
// Pushes PC+1 as return address, jumps to register value.
// 1-word instruction (PC+1)
task t_call_reg;
   begin
      if (r_extra_clock == 0) begin
         r_SP             <= r_SP - 1;
         r_mem_addr       <= r_SP[24:0] - 25'd1;
         r_mem_write_data <= {7'b0, r_PC + 25'd1};
         r_mem_write_DV   <= 1'b1;
         r_extra_clock    <= 1'b1;
      end else begin
         if (w_mem_ready) begin
            r_mem_write_DV <= 1'b0;
            r_SM           <= OPCODE_REQUEST;
            r_PC           <= r_reg_port_b[24:0];
         end
      end
   end
endtask
