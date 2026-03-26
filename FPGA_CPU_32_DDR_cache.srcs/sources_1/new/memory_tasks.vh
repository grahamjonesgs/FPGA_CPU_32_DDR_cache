// Set mem location given in value to contents of register
// On completion
// Increment PC 2
// Increment r_SM_msg
task t_set_mem_from_value_reg;
   input [31:0] i_location;
   begin
      if (r_extra_clock == 0) begin
         r_mem_addr <= i_location[24:0];
         r_mem_write_data <= r_reg_port_b;
         r_mem_write_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end // if first loop
        else
        begin
         if (w_mem_ready) begin
            r_SM <= OPCODE_REQUEST;
            r_PC <= r_PC + 2;
            r_mem_write_DV <= 1'b0;
         end  // if ready asserted, else will loop until ready
      end  // if subsequent loop
   end
endtask

// Set mem location given in register to contents of register (first in order is value, second is location)
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_set_mem_from_reg_reg;
   begin
      if (r_extra_clock == 0) begin
         r_mem_addr <= r_reg_port_b[24:0];
         r_mem_write_data <= r_reg_port_a;
         r_mem_write_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end // if first loop
        else
        begin
         if (w_mem_ready) begin
            r_SM <= OPCODE_REQUEST;
            r_PC <= r_PC + 1;
            r_mem_write_DV <= 1'b0;
         end  // if ready asserted, else will loop until ready
      end  // if subsequent loop
   end
endtask

// Set contents of register to location given in value
// On completion
// Increment PC 2
// Increment r_SM_msg
task t_set_reg_from_mem_value;
   input [31:0] i_location;
   begin
      if (r_extra_clock == 0) begin
         r_mem_addr <= i_location[24:0];
         r_mem_read_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end // if first loop
        else
        begin
         if (w_mem_ready) begin
            r_writeback_value <= w_mem_read_data;
            r_writeback_reg <= r_reg_2;
            r_SM <= WRITEBACK;
            r_mem_read_DV <= 1'b0;
            r_PC <= r_PC + 2;
         end  // if ready asserted, else will loop until ready
      end  // if subsequent loop
   end
endtask

// Set contents of register to location given in register (first in order is reg to be set, second is location)
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_set_reg_from_mem_reg;
   begin
      if (r_extra_clock == 0) begin
         r_mem_addr <= r_reg_port_b[24:0];
         r_mem_read_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end // if first loop
        else
        begin
         if (w_mem_ready) begin
            r_writeback_value <= w_mem_read_data;
            r_writeback_reg <= r_reg_1;
            r_SM <= WRITEBACK;
            r_mem_read_DV <= 1'b0;
            if (r_mem_read_DV) begin
               r_PC <= r_PC + 1;
            end
         end  // if ready asserted, else will loop until ready
      end  // if subsequent loop
   end
endtask

