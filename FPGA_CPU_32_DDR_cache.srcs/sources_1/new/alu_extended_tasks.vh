//=============================================================================
// Extended ALU Tasks - Using Dedicated Read Ports
// Include this file in your main module
// 
// REQUIRES: r_reg_port_a and r_reg_port_b to be declared and updated each cycle:
//   reg [31:0] r_reg_port_a;
//   reg [31:0] r_reg_port_b;
//   always @(posedge i_Clk) begin
//       r_reg_port_a <= r_register[r_reg_1];
//       r_reg_port_b <= r_register[r_reg_2];
//   end
//=============================================================================

//=============================================================================
// ROTATE OPERATIONS
//=============================================================================

// ROLR - Rotate left by 1
task t_rotate_left;
   begin
      r_writeback_value <= {r_reg_port_b[30:0], r_reg_port_b[31]};
      r_writeback_reg <= r_reg_2;
      r_carry_flag <= r_reg_port_b[31];
      r_zero_flag <= (r_reg_port_b == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// RORR - Rotate right by 1
task t_rotate_right;
   begin
      r_writeback_value <= {r_reg_port_b[0], r_reg_port_b[31:1]};
      r_writeback_reg <= r_reg_2;
      r_carry_flag <= r_reg_port_b[0];
      r_zero_flag <= (r_reg_port_b == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// ROLCR - Rotate left through carry (33-bit rotate)
task t_rotate_left_carry;
   reg [32:0] temp;
   begin
      temp = {r_reg_port_b, r_carry_flag};
      r_writeback_value <= {temp[31:0]};
      r_writeback_reg <= r_reg_2;
      r_carry_flag <= temp[32];
      r_zero_flag <= (temp[31:0] == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// RORCR - Rotate right through carry (33-bit rotate)
task t_rotate_right_carry;
   reg [32:0] temp;
   begin
      temp = {r_carry_flag, r_reg_port_b};
      r_writeback_value <= temp[32:1];
      r_writeback_reg <= r_reg_2;
      r_carry_flag <= temp[0];
      r_zero_flag <= (temp[32:1] == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// ROLV - Rotate left by N bits
task t_rotate_left_n;
   input [31:0] i_count;
   reg [4:0] count;
   reg [31:0] result;
   begin
      count = i_count[4:0];  // Only use lower 5 bits (0-31)
      result = (r_reg_port_b << count) | (r_reg_port_b >> (32 - count));
      r_writeback_value <= result;
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (result == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// RORV - Rotate right by N bits
task t_rotate_right_n;
   input [31:0] i_count;
   reg [4:0] count;
   reg [31:0] result;
   begin
      count = i_count[4:0];
      result = (r_reg_port_b >> count) | (r_reg_port_b << (32 - count));
      r_writeback_value <= result;
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (result == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// ROLRR - Rotate left by amount in second register
task t_rotate_left_reg;
   reg [4:0] count;
   reg [31:0] result;
   begin
      count = r_reg_port_b[4:0];
      result = (r_reg_port_a << count) | (r_reg_port_a >> (32 - count));
      r_writeback_value <= result;
      r_writeback_reg <= r_reg_1;
      r_zero_flag <= (result == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// RORRR - Rotate right by amount in second register
task t_rotate_right_reg;
   reg [4:0] count;
   reg [31:0] result;
   begin
      count = r_reg_port_b[4:0];
      result = (r_reg_port_a >> count) | (r_reg_port_a << (32 - count));
      r_writeback_value <= result;
      r_writeback_reg <= r_reg_1;
      r_zero_flag <= (result == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask


//=============================================================================
// BIT MANIPULATION OPERATIONS
//=============================================================================

// BSET - Set bit N in register
task t_bit_set_value;
   input [31:0] i_bit;
   begin
      r_writeback_value <= r_reg_port_b | (32'b1 << i_bit[4:0]);
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// BCLR - Clear bit N in register
task t_bit_clear_value;
   input [31:0] i_bit;
   begin
      r_writeback_value <= r_reg_port_b & ~(32'b1 << i_bit[4:0]);
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// BTGL - Toggle bit N in register
task t_bit_toggle_value;
   input [31:0] i_bit;
   begin
      r_writeback_value <= r_reg_port_b ^ (32'b1 << i_bit[4:0]);
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// BTST - Test bit N, result in zero flag (zero if bit is 0)
task t_bit_test_value;
   input [31:0] i_bit;
   begin
      r_zero_flag <= ~r_reg_port_b[i_bit[4:0]];
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 2;
   end
endtask

// BSETRR - Set bit (bit number in second register)
task t_bit_set_reg;
   begin
      r_writeback_value <= r_reg_port_a | (32'b1 << r_reg_port_b[4:0]);
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// BCLRRR - Clear bit (bit number in second register)
task t_bit_clear_reg;
   begin
      r_writeback_value <= r_reg_port_a & ~(32'b1 << r_reg_port_b[4:0]);
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// BTGLRR - Toggle bit (bit number in second register)
task t_bit_toggle_reg;
   begin
      r_writeback_value <= r_reg_port_a ^ (32'b1 << r_reg_port_b[4:0]);
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// BTSTRR - Test bit (bit number in second register)
task t_bit_test_reg;
   reg [4:0] bit_pos;
   begin
      bit_pos = r_reg_port_b[4:0];
      r_zero_flag <= ~r_reg_port_a[bit_pos];
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// POPCNT - Population count (count 1 bits)
task t_popcnt;
   begin
      r_writeback_value <= {26'b0, popcount(r_reg_port_b)};
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (r_reg_port_b == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// CLZ - Count leading zeros
task t_clz;
   begin
      r_writeback_value <= {26'b0, count_leading_zeros(r_reg_port_b)};
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// CTZ - Count trailing zeros
task t_ctz;
   begin
      r_writeback_value <= {26'b0, count_trailing_zeros(r_reg_port_b)};
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// BITREV - Reverse all bits
task t_bit_reverse;
   begin
      r_writeback_value <= bit_reverse(r_reg_port_b);
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// BEXTR - Extract bit field
// Value format: bits [7:0] = start position, bits [15:8] = length
task t_extract_bits;
   input [31:0] i_params;
   reg [4:0] start_pos;
   reg [4:0] length;
   reg [31:0] mask;
   reg [31:0] result;
   begin
      start_pos = i_params[4:0];
      length = i_params[12:8];
      mask = (32'hFFFFFFFF >> (32 - length));
      result = (r_reg_port_b >> start_pos) & mask;
      r_writeback_value <= result;
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (result == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// BDEP - Deposit bit field (insert bits at position)
// Uses r_reg_1 as source, r_reg_2 as destination
// Value format: bits [7:0] = start position, bits [15:8] = length
task t_deposit_bits;
   input [31:0] i_params;
   reg [4:0] start_pos;
   reg [4:0] length;
   reg [31:0] mask;
   reg [31:0] insert_val;
   begin
      start_pos = i_params[4:0];
      length = i_params[12:8];
      mask = (32'hFFFFFFFF >> (32 - length)) << start_pos;
      insert_val = (r_reg_port_a << start_pos) & mask;
      r_writeback_value <= (r_reg_port_b & ~mask) | insert_val;
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask


//=============================================================================
// COMPARISON OPERATIONS (Signed and Unsigned)
// These benefit most from dedicated read ports - removes mux from compare path
//=============================================================================

// CMPLTRR - Signed less-than
task t_cmp_lt_regs;
   reg signed [31:0] s_reg1;
   reg signed [31:0] s_reg2;
   begin
      s_reg1 = r_reg_port_a;
      s_reg2 = r_reg_port_b;
      r_less_flag <= (s_reg1 < s_reg2) ? 1'b1 : 1'b0;
      r_equal_flag <= (s_reg1 == s_reg2) ? 1'b1 : 1'b0;
      r_zero_flag <= (s_reg1 == s_reg2) ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// CMPLERR - Signed less-or-equal
task t_cmp_le_regs;
   reg signed [31:0] s_reg1;
   reg signed [31:0] s_reg2;
   begin
      s_reg1 = r_reg_port_a;
      s_reg2 = r_reg_port_b;
      r_less_flag <= (s_reg1 <= s_reg2) ? 1'b1 : 1'b0;
      r_equal_flag <= (s_reg1 == s_reg2) ? 1'b1 : 1'b0;
      r_zero_flag <= (s_reg1 == s_reg2) ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// CMPGTRR - Signed greater-than
task t_cmp_gt_regs;
   reg signed [31:0] s_reg1;
   reg signed [31:0] s_reg2;
   begin
      s_reg1 = r_reg_port_a;
      s_reg2 = r_reg_port_b;
      r_less_flag <= (s_reg1 > s_reg2) ? 1'b1 : 1'b0;  // Reusing less_flag as "condition true"
      r_equal_flag <= (s_reg1 == s_reg2) ? 1'b1 : 1'b0;
      r_zero_flag <= (s_reg1 == s_reg2) ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// CMPGERR - Signed greater-or-equal
task t_cmp_ge_regs;
   reg signed [31:0] s_reg1;
   reg signed [31:0] s_reg2;
   begin
      s_reg1 = r_reg_port_a;
      s_reg2 = r_reg_port_b;
      r_less_flag <= (s_reg1 >= s_reg2) ? 1'b1 : 1'b0;
      r_equal_flag <= (s_reg1 == s_reg2) ? 1'b1 : 1'b0;
      r_zero_flag <= (s_reg1 == s_reg2) ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// CMPULTRR - Unsigned less-than
task t_cmp_ult_regs;
   begin
      r_carry_flag <= (r_reg_port_a < r_reg_port_b) ? 1'b1 : 1'b0;
      r_equal_flag <= (r_reg_port_a == r_reg_port_b) ? 1'b1 : 1'b0;
      r_zero_flag <= (r_reg_port_a == r_reg_port_b) ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// CMPULERR - Unsigned less-or-equal
task t_cmp_ule_regs;
   begin
      r_carry_flag <= (r_reg_port_a <= r_reg_port_b) ? 1'b1 : 1'b0;
      r_equal_flag <= (r_reg_port_a == r_reg_port_b) ? 1'b1 : 1'b0;
      r_zero_flag <= (r_reg_port_a == r_reg_port_b) ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// CMPUGTRR - Unsigned greater-than
task t_cmp_ugt_regs;
   begin
      r_carry_flag <= (r_reg_port_a > r_reg_port_b) ? 1'b1 : 1'b0;
      r_equal_flag <= (r_reg_port_a == r_reg_port_b) ? 1'b1 : 1'b0;
      r_zero_flag <= (r_reg_port_a == r_reg_port_b) ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask

// CMPUGERR - Unsigned greater-or-equal
task t_cmp_uge_regs;
   begin
      r_carry_flag <= (r_reg_port_a >= r_reg_port_b) ? 1'b1 : 1'b0;
      r_equal_flag <= (r_reg_port_a == r_reg_port_b) ? 1'b1 : 1'b0;
      r_zero_flag <= (r_reg_port_a == r_reg_port_b) ? 1'b1 : 1'b0;
      r_SM <= OPCODE_REQUEST;
      r_PC <= r_PC + 1;
   end
endtask


//=============================================================================
// HARDWARE MULTIPLY - PIPELINED (2 cycles)
// ALL multiply operations must go through the pipeline to avoid timing violations
//=============================================================================

// MULRR - Signed multiply, lower 32 bits
task t_mul_regs_hw;
begin
    r_mul_operand_a   <= r_reg_port_a;
    r_mul_operand_b   <= r_reg_port_b;
    r_mul_dest_reg    <= r_reg_1;
    r_mul_is_high     <= 1'b0;
    r_mul_is_unsigned <= 1'b0;
    r_mul_is_immediate <= 1'b0;
    r_SM              <= MULTIPLY_CALC;
end
endtask

// MULURR - Unsigned multiply, lower 32 bits
task t_mulu_regs_hw;
begin
    r_mul_operand_a   <= r_reg_port_a;
    r_mul_operand_b   <= r_reg_port_b;
    r_mul_dest_reg    <= r_reg_1;
    r_mul_is_high     <= 1'b0;
    r_mul_is_unsigned <= 1'b1;
    r_mul_is_immediate <= 1'b0;
    r_SM              <= MULTIPLY_CALC;
end
endtask

// MULHRR - Signed multiply, upper 32 bits
task t_mulh_regs_hw;
begin
    r_mul_operand_a   <= r_reg_port_a;
    r_mul_operand_b   <= r_reg_port_b;
    r_mul_dest_reg    <= r_reg_1;
    r_mul_is_high     <= 1'b1;
    r_mul_is_unsigned <= 1'b0;
    r_mul_is_immediate <= 1'b0;
    r_SM              <= MULTIPLY_CALC;
end
endtask

// MULHURR - Unsigned multiply, upper 32 bits
task t_mulhu_regs_hw;
begin
    r_mul_operand_a   <= r_reg_port_a;
    r_mul_operand_b   <= r_reg_port_b;
    r_mul_dest_reg    <= r_reg_1;
    r_mul_is_high     <= 1'b1;
    r_mul_is_unsigned <= 1'b1;
    r_mul_is_immediate <= 1'b0;
    r_SM              <= MULTIPLY_CALC;
end
endtask

// MULV - Multiply register by immediate value (signed) - NOW PIPELINED
task t_mul_value_hw;
   input [31:0] i_value;
begin
    r_mul_operand_a   <= r_reg_port_b;      // Register value
    r_mul_operand_b   <= i_value;           // Immediate value
    r_mul_dest_reg    <= r_reg_2;           // Result goes back to same register
    r_mul_is_high     <= 1'b0;
    r_mul_is_unsigned <= 1'b0;
    r_mul_is_immediate <= 1'b1;             // Flag for PC increment
    r_SM              <= MULTIPLY_CALC;
end
endtask

//=============================================================================
// DIVISION (Multi-cycle, but optimized)
// These use the division state machine defined in the main module
//=============================================================================

// DIVRR - Signed divide (initialization only, iteration in DIVIDE_STEP)
task t_div_regs_hw;
   reg [31:0] abs_dividend;
   reg [31:0] abs_divisor;
   begin
      if (r_reg_port_b == 32'b0) begin
         // Divide by zero
         r_writeback_value <= 32'hFFFFFFFF;
         r_writeback_reg <= r_reg_1;
         r_overflow_flag <= 1'b1;
         r_SM <= WRITEBACK;
         r_PC <= r_PC + 1;
      end
      else begin
         abs_dividend = r_reg_port_a[31] ? (~r_reg_port_a + 1) : r_reg_port_a;
         abs_divisor = r_reg_port_b[31] ? (~r_reg_port_b + 1) : r_reg_port_b;
         r_div_dividend <= abs_dividend;
         r_div_divisor <= abs_divisor;
         r_div_quotient <= 32'b0;
         r_div_remainder <= 32'b0;
         r_div_counter <= 6'd0;
         r_div_sign_q <= r_reg_port_a[31] ^ r_reg_port_b[31];
         r_div_sign_r <= r_reg_port_a[31];
         r_div_is_signed <= 1'b1;
         r_div_op <= DIV_OP_DIV;
         r_div_dest_reg <= r_reg_1;
         r_div_pc_inc <= 1'b0;  // PC += 1
         r_SM <= DIVIDE_STEP;
      end
   end
endtask

// DIVURR - Unsigned divide (initialization only, iteration in DIVIDE_STEP)
task t_divu_regs_hw;
   begin
      if (r_reg_port_b == 32'b0) begin
         r_writeback_value <= 32'hFFFFFFFF;
         r_writeback_reg <= r_reg_1;
         r_overflow_flag <= 1'b1;
         r_SM <= WRITEBACK;
         r_PC <= r_PC + 1;
      end
      else begin
         r_div_dividend <= r_reg_port_a;
         r_div_divisor <= r_reg_port_b;
         r_div_quotient <= 32'b0;
         r_div_remainder <= 32'b0;
         r_div_counter <= 6'd0;
         r_div_is_signed <= 1'b0;
         r_div_op <= DIV_OP_DIV;
         r_div_dest_reg <= r_reg_1;
         r_div_pc_inc <= 1'b0;  // PC += 1
         r_SM <= DIVIDE_STEP;
      end
   end
endtask

// MODRR - Signed modulo (initialization only, iteration in DIVIDE_STEP)
task t_mod_regs_hw;
   reg [31:0] abs_dividend;
   reg [31:0] abs_divisor;
   begin
      if (r_reg_port_b == 32'b0) begin
         r_writeback_value <= r_reg_port_a;  // Return dividend
         r_writeback_reg <= r_reg_1;
         r_overflow_flag <= 1'b1;
         r_SM <= WRITEBACK;
         r_PC <= r_PC + 1;
      end
      else begin
         abs_dividend = r_reg_port_a[31] ? (~r_reg_port_a + 1) : r_reg_port_a;
         abs_divisor = r_reg_port_b[31] ? (~r_reg_port_b + 1) : r_reg_port_b;
         r_div_dividend <= abs_dividend;
         r_div_divisor <= abs_divisor;
         r_div_quotient <= 32'b0;
         r_div_remainder <= 32'b0;
         r_div_counter <= 6'd0;
         r_div_sign_r <= r_reg_port_a[31];  // Remainder sign follows dividend
         r_div_is_signed <= 1'b1;
         r_div_op <= DIV_OP_MOD;
         r_div_dest_reg <= r_reg_1;
         r_div_pc_inc <= 1'b0;  // PC += 1
         r_SM <= DIVIDE_STEP;
      end
   end
endtask

// MODURR - Unsigned modulo (initialization only, iteration in DIVIDE_STEP)
task t_modu_regs_hw;
   begin
      if (r_reg_port_b == 32'b0) begin
         r_writeback_value <= r_reg_port_a;
         r_writeback_reg <= r_reg_1;
         r_overflow_flag <= 1'b1;
         r_SM <= WRITEBACK;
         r_PC <= r_PC + 1;
      end
      else begin
         r_div_dividend <= r_reg_port_a;
         r_div_divisor <= r_reg_port_b;
         r_div_quotient <= 32'b0;
         r_div_remainder <= 32'b0;
         r_div_counter <= 6'd0;
         r_div_is_signed <= 1'b0;
         r_div_op <= DIV_OP_MOD;
         r_div_dest_reg <= r_reg_1;
         r_div_pc_inc <= 1'b0;  // PC += 1
         r_SM <= DIVIDE_STEP;
      end
   end
endtask

// DIVV - Divide by immediate value (signed, initialization only)
task t_div_value_hw;
   input [31:0] i_value;
   reg [31:0] abs_dividend;
   reg [31:0] abs_divisor;
   begin
      if (i_value == 32'b0) begin
         r_writeback_value <= 32'hFFFFFFFF;
         r_writeback_reg <= r_reg_2;
         r_overflow_flag <= 1'b1;
         r_SM <= WRITEBACK;
         r_PC <= r_PC + 2;
      end
      else begin
         abs_dividend = r_reg_port_b[31] ? (~r_reg_port_b + 1) : r_reg_port_b;
         abs_divisor = i_value[31] ? (~i_value + 1) : i_value;
         r_div_dividend <= abs_dividend;
         r_div_divisor <= abs_divisor;
         r_div_quotient <= 32'b0;
         r_div_remainder <= 32'b0;
         r_div_counter <= 6'd0;
         r_div_sign_q <= r_reg_port_b[31] ^ i_value[31];
         r_div_is_signed <= 1'b1;
         r_div_op <= DIV_OP_DIV;
         r_div_dest_reg <= r_reg_2;
         r_div_pc_inc <= 1'b1;  // PC += 2
         r_SM <= DIVIDE_STEP;
      end
   end
endtask

// MODV - Modulo by immediate value (signed, initialization only)
task t_mod_value_hw;
   input [31:0] i_value;
   reg [31:0] abs_dividend;
   reg [31:0] abs_divisor;
   begin
      if (i_value == 32'b0) begin
         // Return dividend on mod by zero
         r_overflow_flag <= 1'b1;
         r_SM <= OPCODE_REQUEST;
         r_PC <= r_PC + 2;
      end
      else begin
         abs_dividend = r_reg_port_b[31] ? (~r_reg_port_b + 1) : r_reg_port_b;
         abs_divisor = i_value[31] ? (~i_value + 1) : i_value;
         r_div_dividend <= abs_dividend;
         r_div_divisor <= abs_divisor;
         r_div_quotient <= 32'b0;
         r_div_remainder <= 32'b0;
         r_div_counter <= 6'd0;
         r_div_sign_r <= r_reg_port_b[31];
         r_div_is_signed <= 1'b1;
         r_div_op <= DIV_OP_MOD;
         r_div_dest_reg <= r_reg_2;
         r_div_pc_inc <= 1'b1;  // PC += 2
         r_SM <= DIVIDE_STEP;
      end
   end
endtask


//=============================================================================
// ADDITIONAL REGISTER OPERATIONS
//=============================================================================

// ABSR - Absolute value
task t_abs_reg;
   begin
      if (r_reg_port_b[31]) begin
         r_writeback_value <= ~r_reg_port_b + 1;
         // Check for overflow (abs of -2^31)
         r_overflow_flag <= (r_reg_port_b == 32'h80000000) ? 1'b1 : 1'b0;
      end else begin
         r_writeback_value <= r_reg_port_b;
      end
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (r_reg_port_b == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// SEXTB - Sign extend byte to 32 bits
task t_sign_extend_byte;
   begin
      r_writeback_value <= {{24{r_reg_port_b[7]}}, r_reg_port_b[7:0]};
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (r_reg_port_b[7:0] == 0) ? 1'b1 : 1'b0;
      r_sign_flag <= r_reg_port_b[7];
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// SEXTH - Sign extend halfword to 32 bits
task t_sign_extend_half;
   begin
      r_writeback_value <= {{16{r_reg_port_b[15]}}, r_reg_port_b[15:0]};
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (r_reg_port_b[15:0] == 0) ? 1'b1 : 1'b0;
      r_sign_flag <= r_reg_port_b[15];
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// ZEXTB - Zero extend byte to 32 bits
task t_zero_extend_byte;
   begin
      r_writeback_value <= {24'b0, r_reg_port_b[7:0]};
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (r_reg_port_b[7:0] == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// ZEXTH - Zero extend halfword to 32 bits
task t_zero_extend_half;
   begin
      r_writeback_value <= {16'b0, r_reg_port_b[15:0]};
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (r_reg_port_b[15:0] == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// BSWAP - Byte swap (endian conversion)
task t_byte_swap;
   begin
      r_writeback_value <= {
         r_reg_port_b[7:0],
         r_reg_port_b[15:8],
         r_reg_port_b[23:16],
         r_reg_port_b[31:24]
      };
      r_writeback_reg <= r_reg_2;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// SHLV - Shift left by N bits
task t_left_shift_n;
   input [31:0] i_count;
   reg [31:0] result;
   begin
      result = r_reg_port_b << i_count[4:0];
      r_writeback_value <= result;
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (result == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// SHRV - Shift right by N bits (logical)
task t_right_shift_n;
   input [31:0] i_count;
   reg [31:0] result;
   begin
      result = r_reg_port_b >> i_count[4:0];
      r_writeback_value <= result;
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (result == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// SHRAV - Shift right arithmetical by N bits
task t_right_shift_a_n;
   input [31:0] i_count;
   reg signed [31:0] signed_val;
   reg [31:0] result;
   begin
      signed_val = r_reg_port_b;
      result = signed_val >>> i_count[4:0];
      r_writeback_value <= result;
      r_writeback_reg <= r_reg_2;
      r_zero_flag <= (result == 0) ? 1'b1 : 1'b0;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 2;
   end
endtask

// MINRR - Minimum of two signed registers
task t_min_regs;
   reg signed [31:0] s_reg1;
   reg signed [31:0] s_reg2;
   begin
      s_reg1 = r_reg_port_a;
      s_reg2 = r_reg_port_b;
      r_writeback_value <= (s_reg1 < s_reg2) ? r_reg_port_a : r_reg_port_b;
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// MAXRR - Maximum of two signed registers
task t_max_regs;
   reg signed [31:0] s_reg1;
   reg signed [31:0] s_reg2;
   begin
      s_reg1 = r_reg_port_a;
      s_reg2 = r_reg_port_b;
      r_writeback_value <= (s_reg1 > s_reg2) ? r_reg_port_a : r_reg_port_b;
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// MINURR - Minimum of two unsigned registers
task t_minu_regs;
   begin
      r_writeback_value <= (r_reg_port_a < r_reg_port_b) ?
                              r_reg_port_a : r_reg_port_b;
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// MAXURR - Maximum of two unsigned registers
task t_maxu_regs;
   begin
      r_writeback_value <= (r_reg_port_a > r_reg_port_b) ?
                              r_reg_port_a : r_reg_port_b;
      r_writeback_reg <= r_reg_1;
      r_SM <= WRITEBACK;
      r_PC <= r_PC + 1;
   end
endtask

// JMPR - Jump to address in register
task t_jump_reg;
   begin
      r_PC <= r_reg_port_b[23:0];
      r_SM <= OPCODE_REQUEST;
   end
endtask


//=============================================================================
// INDEXED MEMORY ACCESS
//=============================================================================

// LDIDX - Load indexed: reg1 = mem[reg2 + immediate]
task t_load_indexed;
   input [31:0] i_offset;
   reg [23:0] effective_addr;
   begin
      if (r_extra_clock == 0) begin
         effective_addr = r_reg_port_b[23:0] + i_offset[23:0];
         r_mem_addr <= effective_addr;
         r_mem_read_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end
      else begin
         if (w_mem_ready) begin
            r_writeback_value <= w_mem_read_data;
            r_writeback_reg <= r_reg_1;
            r_SM <= WRITEBACK;
            r_mem_read_DV <= 1'b0;
            r_PC <= r_PC + 2;
         end
      end
   end
endtask

// STIDX - Store indexed: mem[reg2 + immediate] = reg1
task t_store_indexed;
   input [31:0] i_offset;
   reg [23:0] effective_addr;
   begin
      if (r_extra_clock == 0) begin
         effective_addr = r_reg_port_b[23:0] + i_offset[23:0];
         r_mem_addr <= effective_addr;
         r_mem_write_data <= r_reg_port_a;
         r_mem_write_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end
      else begin
         if (w_mem_ready) begin
            r_SM <= OPCODE_REQUEST;
            r_mem_write_DV <= 1'b0;
            r_PC <= r_PC + 2;
         end
      end
   end
endtask

// LDIDXR - Load indexed with register offset: reg1 = mem[reg2 + reg3]
// Opcode format: 0EXY where X=dest, Y=base (third reg from var1 low nibble)
// NOTE: This needs a third register read - see note below
task t_load_indexed_reg;
   reg [23:0] effective_addr;
   reg [3:0] offset_reg;
   begin
      if (r_extra_clock == 0) begin
         offset_reg = w_var1[3:0];
         // NOTE: r_register[offset_reg] is NOT through read ports
         // This could be a timing issue if offset_reg varies
         // Consider adding a third read port or using a pipeline stage
         effective_addr = r_reg_port_b[23:0] + r_register[offset_reg][23:0];
         r_mem_addr <= effective_addr;
         r_mem_read_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end
      else begin
         if (w_mem_ready) begin
            r_writeback_value <= w_mem_read_data;
            r_writeback_reg <= r_reg_1;
            r_SM <= WRITEBACK;
            r_mem_read_DV <= 1'b0;
            r_PC <= r_PC + 2;
         end
      end
   end
endtask

// STIDXR - Store indexed with register offset: mem[reg2 + reg3] = reg1
// NOTE: Same issue as LDIDXR - needs third register read
task t_store_indexed_reg;
   reg [23:0] effective_addr;
   reg [3:0] offset_reg;
   begin
      if (r_extra_clock == 0) begin
         offset_reg = w_var1[3:0];
         // NOTE: r_register[offset_reg] is NOT through read ports
         effective_addr = r_reg_port_b[23:0] + r_register[offset_reg][23:0];
         r_mem_addr <= effective_addr;
         r_mem_write_data <= r_reg_port_a;
         r_mem_write_DV <= 1'b1;
         r_extra_clock <= 1'b1;
      end
      else begin
         if (w_mem_ready) begin
            r_SM <= OPCODE_REQUEST;
            r_mem_write_DV <= 1'b0;
            r_PC <= r_PC + 2;
         end
      end
   end
endtask