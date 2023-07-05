// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.1 (lin64) Build 3865809 Sun May  7 15:04:56 MDT 2023
// Date        : Wed Jul  5 20:46:07 2023
// Host        : archlinux running 64-bit unknown
// Command     : write_verilog -force -mode synth_stub
//               /home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.runs/clk_wiz_0_synth_1/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(clk_200, resetn, i_Clk)
/* synthesis syn_black_box black_box_pad_pin="resetn" */
/* synthesis syn_force_seq_prim="clk_200" */
/* synthesis syn_force_seq_prim="i_Clk" */;
  output clk_200 /* synthesis syn_isclock = 1 */;
  input resetn;
  input i_Clk /* synthesis syn_isclock = 1 */;
endmodule
