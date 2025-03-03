##################################################################################################
## 
##  Xilinx, Inc. 2010            www.xilinx.com 
##  Mon Mar  3 15:28:57 2025

##  Generated by MIG Version 4.2
##  
##################################################################################################
##  File name :       example_top.sd
##  Details :     Constraints file
##                    FPGA Family:       ARTIX7
##                    FPGA Part:         XC7A100TICSG324_PKG
##                    Speedgrade:        -1
##                    Design Entry:      VERILOG
##                    Frequency:         200 MHz
##                    Time Period:       5000 ps
##################################################################################################

##################################################################################################
## Controller 0
## Memory Device: DDR2_SDRAM->Components->MT47H64M16HR-25E
## Data Width: 16
## Time Period: 5000
## Data Mask: 1
##################################################################################################

set_property IO_BUFFER_TYPE NONE [get_ports {ddr2_ck_n[*]} ]
set_property IO_BUFFER_TYPE NONE [get_ports {ddr2_ck_p[*]} ]
          
#create_clock -period 5 [get_ports sys_clk_i]
          
############## NET - IOSTANDARD ##################



set_property INTERNAL_VREF  0.900 [get_iobanks 34]