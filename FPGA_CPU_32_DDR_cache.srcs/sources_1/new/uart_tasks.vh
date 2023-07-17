// Send debug message
// On completion
// Increment PC 1
// Increment r_SM_msg

task t_debug_message;
    begin
        if (!w_sending_msg) begin
            r_msg[7:0] <= 8'h50;  // P
            r_msg[15:8] <= 8'h43;  // C
            r_msg[23:16] <= 8'h20;  //  
            r_msg[31:24] <= 8'h69;  // i
            r_msg[39:32] <= 8'h73;  // s
            r_msg[47:40] <= 8'h20;  //  

            r_msg[55:48] <= return_ascii_from_hex(r_PC[23:20]);
            r_msg[63:56] <= return_ascii_from_hex(r_PC[19:16]);
            r_msg[71:64] <= return_ascii_from_hex(r_PC[15:12]);
            r_msg[79:72] <= return_ascii_from_hex(r_PC[11:8]);
            r_msg[87:80] <= return_ascii_from_hex(r_PC[7:4]);
            r_msg[95:88] <= return_ascii_from_hex(r_PC[3:0]);

            r_msg[103:96] <= 8'h0D;  // CR

            r_msg_length <= 8'h0D;
            r_msg_send_DV <= 1'b1;
        end
    end

endtask  // Send test message
// On completion
// Increment PC 1
// Increment r_SM_msg

task t_test_message;
    begin
        if (!w_sending_msg) begin
            t_tx_message(8'd3);
            r_SM <= OPCODE_REQUEST;
            r_PC <= r_PC + 1;
        end
    end
endtask

// Print to serial values from register location
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_tx_char_from_reg_value;
    begin
        if (r_extra_clock == 0) begin
            r_mem_addr <= r_register[r_reg_2][23:0];
            r_mem_read_DV <= 1'b1;
            r_mem_was_ready <=1'b0;
            r_extra_clock <= 1'b1;
        end // if first loop
        else
        begin
            if (w_mem_ready) begin
                r_mem_read_DV <= 1'b0;
                r_mem_was_ready <= 1'b1;
                
            end       
            if ((w_mem_ready||r_mem_was_ready) && !w_sending_msg) begin
                r_msg[7:0] <= w_mem_read_data[7:0];
                r_msg_length <= 8'h1;
                r_msg_send_DV <= 1'b1;
                r_SM <= UART_DELAY;
                r_mem_read_DV <= 1'b0;
                r_PC <= r_PC + 1;
            end  // if ready asserted, else will loop until ready
        end  // if subsequent loop
    end
endtask

// Print to serial value from memory at register location
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_tx_value_of_mem_at_reg;
    begin
        if (r_extra_clock == 0) begin
            r_mem_addr <= r_register[r_reg_2][23:0];
            r_mem_read_DV <= 1'b1;
            r_mem_was_ready <=1'b0;
            r_extra_clock <= 1'b1;
        end // if first loop
        else
        begin
            if (w_mem_ready) begin
                r_mem_read_DV <= 1'b0;
                r_mem_was_ready <= 1'b1;
                
            end       
            if ((w_mem_ready||r_mem_was_ready) && !w_sending_msg) begin
                r_msg[7:0] <= return_ascii_from_hex(w_mem_read_data[31:28]);
                r_msg[15:8] <= return_ascii_from_hex(w_mem_read_data[27:24]);
                r_msg[23:16] <= return_ascii_from_hex(w_mem_read_data[23:20]);
                r_msg[31:24] <= return_ascii_from_hex(w_mem_read_data[19:16]);
                r_msg[39:32] <= return_ascii_from_hex(w_mem_read_data[15:12]);
                r_msg[47:40] <= return_ascii_from_hex(w_mem_read_data[11:8]);
                r_msg[55:48] <= return_ascii_from_hex(w_mem_read_data[7:4]);
                r_msg[63:56] <= return_ascii_from_hex(w_mem_read_data[3:0]);
                r_msg_length <= 8'h8;
                r_msg_send_DV <= 1'b1;
                r_SM <= UART_DELAY;
                r_mem_read_DV <= 1'b0;
                r_PC <= r_PC + 1;
            end  // if ready asserted, else will loop until ready
        end  // if subsequent loop
    end
endtask

// Print to serial character from memory location
// On completion
// Increment PC 2
// Increment r_SM_msg
task t_tx_value_of_mem;
    input [31:0] i_location;
    begin
        if (r_extra_clock == 0) begin
            r_mem_addr <= i_location[23:0];
            r_mem_read_DV <= 1'b1;
            r_mem_was_ready <=1'b0;
            r_extra_clock <= 1'b1;
        end // if first loop
        else
        begin
            if (w_mem_ready) begin
                r_mem_read_DV <= 1'b0;
                r_mem_was_ready <= 1'b1;
                
            end       
            if ((w_mem_ready||r_mem_was_ready) && !w_sending_msg) begin
                r_msg[7:0] <= return_ascii_from_hex(w_mem_read_data[31:28]);
                r_msg[15:8] <= return_ascii_from_hex(w_mem_read_data[27:24]);
                r_msg[23:16] <= return_ascii_from_hex(w_mem_read_data[23:20]);
                r_msg[31:24] <= return_ascii_from_hex(w_mem_read_data[19:16]);
                r_msg[39:32] <= return_ascii_from_hex(w_mem_read_data[15:12]);
                r_msg[47:40] <= return_ascii_from_hex(w_mem_read_data[11:8]);
                r_msg[55:48] <= return_ascii_from_hex(w_mem_read_data[7:4]);
                r_msg[63:56] <= return_ascii_from_hex(w_mem_read_data[3:0]);
                r_msg_length <= 8'h8;
                r_msg_send_DV <= 1'b1;
                r_SM <= UART_DELAY;
                r_mem_read_DV <= 1'b0;
                r_PC <= r_PC + 2;
            end  // if ready asserted, else will loop until ready
        end  // if subsequent loop
    end
endtask

// Print to serial character from memory location
// On completion
// Increment PC 2
// Increment r_SM_msg
task t_tx_string_at_mem;
    input [31:0] i_location;
    begin
        if (r_extra_clock == 0) begin
            r_mem_addr <= i_location[23:0];
            r_mem_read_DV <= 1'b1;
            r_mem_was_ready <=1'b0;
            r_extra_clock <= 1'b1;
        end // if first loop
        else
        begin
            if (w_mem_ready) begin
                r_mem_read_DV <= 1'b0;
                r_mem_was_ready <= 1'b1;
                
            end       
            if ((w_mem_ready||r_mem_was_ready) && !w_sending_msg) begin
                r_msg[15:0] <= {8'b0, w_mem_read_data[31:24]};
                r_msg[31:16] <= {8'b0, w_mem_read_data[23:16]};
                r_msg[47:32] <= {8'b0, w_mem_read_data[15:8]};
                r_msg[63:48] <= {8'b0, w_mem_read_data[7:0]};
                r_msg_length <= 8'h8;
                r_msg_send_DV <= 1'b1;
                r_SM <= UART_DELAY;
                r_mem_read_DV <= 1'b0;
                r_PC <= r_PC + 2;
            end  // if ready asserted, else will loop until ready
        end  // if subsequent loop
    end
endtask

// Print to serial character from memory location given by register
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_tx_string_at_reg;
    begin
        if (r_extra_clock == 0) begin
            r_mem_addr <= r_register[r_reg_2][23:0];
            r_mem_read_DV <= 1'b1;
            r_mem_was_ready <=1'b0;
            r_extra_clock <= 1'b1;
        end // if first loop
        else
        begin
            if (w_mem_ready) begin
                r_mem_read_DV <= 1'b0;
                r_mem_was_ready <= 1'b1;
                
            end       
            if ((w_mem_ready||r_mem_was_ready) && !w_sending_msg) begin
                r_msg[15:0] <= {8'b0, w_mem_read_data[31:24]};
                r_msg[31:16] <= {8'b0, w_mem_read_data[23:16]};
                r_msg[47:32] <= {8'b0, w_mem_read_data[15:8]};
                r_msg[63:48] <= {8'b0, w_mem_read_data[7:0]};
                r_msg_length <= 8'h8;
                r_msg_send_DV <= 1'b1;
                r_SM <= UART_DELAY;
                r_mem_read_DV <= 1'b0;
                r_PC <= r_PC + 1;
            end  // if ready asserted, else will loop until ready
        end  // if subsequent loop
    end
endtask


// Send message newline
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_tx_newline;
    begin
        if (!w_sending_msg) begin
            r_msg[7:0] <= 8'h0A;
            r_msg[15:8] <= 8'h0D;
            r_msg_length <= 8'hf2;
            r_msg_send_DV <= 1'b1;
            r_SM <= UART_DELAY;
            r_PC <= r_PC + 1;
        end
    end
endtask

// Send message of reg contents
// On completion
// Increment PC 1
// Increment r_SM_msg
task t_tx_reg;
    begin
        if (!w_sending_msg) begin
            r_msg[7:0] <= return_ascii_from_hex(r_register[r_reg_2][31:28]);
            r_msg[15:8] <= return_ascii_from_hex(r_register[r_reg_2][27:24]);
            r_msg[23:16] <= return_ascii_from_hex(r_register[r_reg_2][23:20]);
            r_msg[31:24] <= return_ascii_from_hex(r_register[r_reg_2][19:16]);
            r_msg[39:32] <= return_ascii_from_hex(r_register[r_reg_2][15:12]);
            r_msg[47:40] <= return_ascii_from_hex(r_register[r_reg_2][11:8]);
            r_msg[55:48] <= return_ascii_from_hex(r_register[r_reg_2][7:4]);
            r_msg[63:56] <= return_ascii_from_hex(r_register[r_reg_2][3:0]);
            r_msg_length <= 8'h8;
            r_msg_send_DV <= 1'b1;
            r_SM <= UART_DELAY;
            r_PC <= r_PC + 1;
        end
    end
endtask


task t_tx_message;
    input [7:0] i_message_number;
    begin
        case (i_message_number)
            1: // Load Complete OK
            begin
                r_msg[7:0] <= 8'h4C;
                r_msg[15:8] <= 8'h6F;
                r_msg[23:16] <= 8'h61;
                r_msg[31:24] <= 8'h64;
                r_msg[39:32] <= 8'h20;
                r_msg[47:40] <= 8'h43;
                r_msg[55:48] <= 8'h6F;
                r_msg[63:56] <= 8'h6D;
                r_msg[71:64] <= 8'h70;
                r_msg[79:72] <= 8'h6C;
                r_msg[87:80] <= 8'h65;
                r_msg[95:88] <= 8'h74;
                r_msg[103:96] <= 8'h65;
                r_msg[111:104] <= 8'h20;
                r_msg[119:112] <= 8'h4F;
                r_msg[127:120] <= 8'h4B;
                r_msg[135:128] <= 8'h0A;
                r_msg[143:136] <= 8'h0D;
                r_msg_length <= 18;
            end
            2: // Load Error, bad CRC
            begin
                r_msg[7:0] <= 8'h4C;
                r_msg[15:8] <= 8'h6F;
                r_msg[23:16] <= 8'h61;
                r_msg[31:24] <= 8'h64;
                r_msg[39:32] <= 8'h20;
                r_msg[47:40] <= 8'h45;
                r_msg[55:48] <= 8'h72;
                r_msg[63:56] <= 8'h72;
                r_msg[71:64] <= 8'h6F;
                r_msg[79:72] <= 8'h72;
                r_msg[87:80] <= 8'h2C;
                r_msg[95:88] <= 8'h20;
                r_msg[103:96] <= 8'h62;
                r_msg[111:104] <= 8'h61;
                r_msg[119:112] <= 8'h64;
                r_msg[127:120] <= 8'h20;
                r_msg[135:128] <= 8'h43;
                r_msg[143:136] <= 8'h52;
                r_msg[151:144] <= 8'h43;
                r_msg[159:152] <= 8'h0A;
                r_msg[167:160] <= 8'h0D;
                r_msg_length <= 20;
            end
            3: // Test message
            begin
                r_msg[7:0] <= 8'h54;
                r_msg[15:8] <= 8'h65;
                r_msg[23:16] <= 8'h73;
                r_msg[31:24] <= 8'h74;
                r_msg[39:32] <= 8'h20;
                r_msg[47:40] <= 8'h6D;
                r_msg[55:48] <= 8'h65;
                r_msg[63:56] <= 8'h73;
                r_msg[71:64] <= 8'h73;
                r_msg[79:72] <= 8'h61;
                r_msg[87:80] <= 8'h67;
                r_msg[95:88] <= 8'h65;
                r_msg[103:96] <= 8'h0A;
                r_msg[111:104] <= 8'h0D;
                r_msg_length <= 14;
            end
            3: // Segmentation error. Attempt to execute data.
            begin
                r_msg[7:0] <= 8'h54;
                r_msg[15:8] <= 8'h65;
                r_msg[23:16] <= 8'h73;
                r_msg[31:24] <= 8'h74;
                r_msg[39:32] <= 8'h20;
                r_msg[47:40] <= 8'h6D;
                r_msg[55:48] <= 8'h65;
                r_msg[63:56] <= 8'h73;
                r_msg[71:64] <= 8'h73;
                r_msg[79:72] <= 8'h61;
                r_msg[87:80] <= 8'h67;
                r_msg[95:88] <= 8'h65;
                r_msg[103:96] <= 8'h0A;
                r_msg[111:104] <= 8'h0D;
                r_msg_length <= 8'h0E;
            end
            default: begin
                r_msg[7:0]   <= 8'h00;
                r_msg_length <= 8'h0;
            end
        endcase
        r_msg_send_DV <= 1'b1;
    end
endtask
