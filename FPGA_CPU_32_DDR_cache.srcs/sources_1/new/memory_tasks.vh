// Set mem location given in value to contents of register
// On completion
// Increment PC 2
// Increment r_SM_msg
task t_set_mem_from_value_reg;
   input [31:0] i_location;
   begin
      if (r_extra_clock == 0) begin
         r_mem_addr <= i_location[26:0];
         r_mem_write_data <= r_reg_port_b;
         r_mem_write_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end // if first loop
        else
        begin
         if (w_mem_ready) begin
            r_SM <= OPCODE_REQUEST;
            r_PC <= r_PC + 8;
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
         r_mem_addr <= r_reg_port_b[26:0];
         r_mem_write_data <= r_reg_port_a;
         r_mem_write_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end // if first loop
        else
        begin
         if (w_mem_ready) begin
            r_SM <= OPCODE_REQUEST;
            r_PC <= r_PC + 4;
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
         r_mem_addr <= i_location[26:0];
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
            r_PC <= r_PC + 8;
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
         r_mem_addr <= r_reg_port_b[26:0];
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
               r_PC <= r_PC + 4;
            end
         end  // if ready asserted, else will loop until ready
      end  // if subsequent loop
   end
endtask

// MEMSET8 - Write one byte to byte address in register
// Big-endian: byte_addr[1:0]=0 → bits[31:24], 1→bits[23:16], 2→bits[15:8], 3→bits[7:0]
// 1-word instruction (PC+4)
task t_memset8;
   reg [1:0] byte_lane;
   begin
      if (r_extra_clock == 0) begin
         byte_lane        = r_reg_port_b[1:0];
         r_mem_addr       <= r_reg_port_b[26:0];
         r_mem_write_data <= {4{r_reg_port_a[7:0]}};  // replicated; only enabled lane used
         // Big-endian byte enables: lane 0 = bit[3] (MSB), lane 3 = bit[0] (LSB)
         r_mem_byte_en    <= 4'b1000 >> byte_lane;
         r_mem_write_DV   <= 1'b1;
         r_extra_clock    <= 1'b1;
      end else begin
         if (w_mem_ready) begin
            r_mem_write_DV <= 1'b0;
            r_SM           <= OPCODE_REQUEST;
            r_PC           <= r_PC + 4;
         end
      end
   end
endtask

// MEMGET8 - Read one byte from byte address in register, zero-extended into dest register
// Big-endian: byte_addr[1:0]=0 → bits[31:24], 1→bits[23:16], 2→bits[15:8], 3→bits[7:0]
// 1-word instruction (PC+4)
task t_memget8;
   begin
      if (r_extra_clock == 0) begin
         r_mem_addr    <= r_reg_port_b[26:0];
         r_mem_read_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end else begin
         if (w_mem_ready) begin
            r_mem_read_DV <= 1'b0;
            case (r_reg_port_b[1:0])
               2'b00: r_writeback_value <= {24'b0, w_mem_read_data[31:24]};
               2'b01: r_writeback_value <= {24'b0, w_mem_read_data[23:16]};
               2'b10: r_writeback_value <= {24'b0, w_mem_read_data[15:8]};
               2'b11: r_writeback_value <= {24'b0, w_mem_read_data[7:0]};
            endcase
            r_writeback_reg <= r_reg_1;
            r_SM            <= WRITEBACK;
            r_PC            <= r_PC + 4;
         end
      end
   end
endtask

