namespace eval ::optrace {
  variable script "/home/graham/Documents/src/fpga/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.runs/impl_1/FPGA_CPU_32_bits_cache.tcl"
  variable category "vivado_impl"
}

# Try to connect to running dispatch if we haven't done so already.
# This code assumes that the Tcl interpreter is not using threads,
# since the ::dispatch::connected variable isn't mutex protected.
if {![info exists ::dispatch::connected]} {
  namespace eval ::dispatch {
    variable connected false
    if {[llength [array get env XILINX_CD_CONNECT_ID]] > 0} {
      set result "true"
      if {[catch {
        if {[lsearch -exact [package names] DispatchTcl] < 0} {
          set result [load librdi_cd_clienttcl[info sharedlibextension]] 
        }
        if {$result eq "false"} {
          puts "WARNING: Could not load dispatch client library"
        }
        set connect_id [ ::dispatch::init_client -mode EXISTING_SERVER ]
        if { $connect_id eq "" } {
          puts "WARNING: Could not initialize dispatch client"
        } else {
          puts "INFO: Dispatch client connection id - $connect_id"
          set connected true
        }
      } catch_res]} {
        puts "WARNING: failed to connect to dispatch server - $catch_res"
      }
    }
  }
}
if {$::dispatch::connected} {
  # Remove the dummy proc if it exists.
  if { [expr {[llength [info procs ::OPTRACE]] > 0}] } {
    rename ::OPTRACE ""
  }
  proc ::OPTRACE { task action {tags {} } } {
    ::vitis_log::op_trace "$task" $action -tags $tags -script $::optrace::script -category $::optrace::category
  }
  # dispatch is generic. We specifically want to attach logging.
  ::vitis_log::connect_client
} else {
  # Add dummy proc if it doesn't exist.
  if { [expr {[llength [info procs ::OPTRACE]] == 0}] } {
    proc ::OPTRACE {{arg1 \"\" } {arg2 \"\"} {arg3 \"\" } {arg4 \"\"} {arg5 \"\" } {arg6 \"\"}} {
        # Do nothing
    }
  }
}

proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    } elseif { [info exist ::env(HOST)] } {
      set host $::env(HOST)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
OPTRACE "impl_1" END { }
}

set_msg_config  -string {{HW Target shutdown}}  -suppress 
set_msg_config  -id {Synth 8-7023}  -string {{WARNING: [Synth 8-7023] instance 'bank_mach0' of module 'mig_7series_v4_2_bank_mach' has 74 connections declared, but only 73 given [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_mc.v:670]}}  -suppress 
set_msg_config  -id {Synth 8-7071}  -string {{WARNING: [Synth 8-7071] port 'afull' of module 'mig_7series_v4_2_ddr_of_pre_fifo' is unconnected for instance 'phy_ctl_pre_fifo_0' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v:1428]}}  -suppress 
set_msg_config  -id {Synth 8-689}  -string {{WARNING: [Synth 8-689] width (12) of port connection 'pi_dqs_found_lanes' does not match port width (4) of module 'mig_7series_v4_2_ddr_mc_phy' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v:1671]}}  -suppress 
set_msg_config  -id {Synth 8-5974}  -string {{WARNING: [Synth 8-5974] attribute "use_dsp48" has been deprecated, please use "use_dsp" instead}}  -suppress 
set_msg_config  -id {Synth 8-7186}  -string {{WARNING: [Synth 8-7186] Applying attribute ram_style = "distributed" is ignored, object 'rd_addr' is not inferred as ram due to incorrect usage [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_prbs_gen.v:203]}}  -suppress 
set_msg_config  -id {Synth 8-3848}  -string {{WARNING: [Synth 8-3848] Net ui_addn_clk_0 in module/entity mig_7series_v4_2_infrastructure does not have driver. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/clocking/mig_7series_v4_2_infrastructure.v:140]}}  -suppress 
set_msg_config  -id {Synth 8-3936}  -string {{WARNING: [Synth 8-3936] Found unconnected internal register 'dbl_req_reg' and it is trimmed from '6' to '5' bits. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_round_robin_arb.v:145]}}  -suppress 
set_msg_config  -id {Synth 8-6014}  -string {{WARNING: [Synth 8-6014] Unused sequential element periodic_rd_generation.read_this_rank_r1_reg was removed.  [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_rank_cntrl.v:487]}}  -suppress 
set_msg_config  -id {Synth 8-7129}  -string {{WARNING: [Synth 8-7129] Port rd_data_addr[4] in module mig_7series_v4_2_ui_rd_data is either unconnected or has no load}}  -suppress 
set_msg_config  -id {Designutils 20-1567}  -string {{WARNING: [Designutils 20-1567] Use of 'set_multicycle_path' with '-hold' is not supported by synthesis. The constraint will not be passed to synthesis. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc:334]}}  -suppress 
set_msg_config  -id {Board 49-26}  -suppress 
set_msg_config  -id {Synth 8-3332}  -string {{WARNING: [Synth 8-3332] Sequential element (FSM_onehot_cal1_state_r_reg[33]) is unused and will be removed from module mig_7series_v4_2_ddr_phy_rdlvl.}}  -suppress 
set_msg_config  -id {Synth 8-3321}  -string {{WARNING: [Synth 8-3321] set_false_path : Empty through list for constraint at line 347 of /home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc:347]}}  -suppress 
set_msg_config  -id {Synth 8-7023}  -string {{WARNING: [Synth 8-7023] instance 'phy_ctl_pre_fifo_0' of module 'mig_7series_v4_2_ddr_of_pre_fifo' has 8 connections declared, but only 7 given [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v:1428]}}  -suppress 
set_msg_config  -id {Synth 8-7071}  -string {{WARNING: [Synth 8-7071] port 'afull' of module 'mig_7series_v4_2_ddr_of_pre_fifo' is unconnected for instance 'phy_ctl_pre_fifo_1' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v:1445]}}  -suppress 
set_msg_config  -id {Synth 8-689}  -string {{WARNING: [Synth 8-689] width (12) of port connection 'pi_phase_locked_lanes' does not match port width (4) of module 'mig_7series_v4_2_ddr_mc_phy' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v:1679]}}  -suppress 
set_msg_config  -id {Synth 8-7186}  -string {{WARNING: [Synth 8-7186] Applying attribute ram_style = "distributed" is ignored, object 'mem_out' is not inferred as ram due to incorrect usage [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_prbs_gen.v:205]}}  -suppress 
set_msg_config  -id {Synth 8-3848}  -string {{WARNING: [Synth 8-3848] Net ui_addn_clk_1 in module/entity mig_7series_v4_2_infrastructure does not have driver. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/clocking/mig_7series_v4_2_infrastructure.v:141]}}  -suppress 
set_msg_config  -id {Synth 8-3936}  -string {{WARNING: [Synth 8-3936] Found unconnected internal register 'dbl_last_master_ns_reg' and it is trimmed from '6' to '4' bits. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_round_robin_arb.v:143]}}  -suppress 
set_msg_config  -id {Synth 8-6014}  -string {{WARNING: [Synth 8-6014] Unused sequential element last_master_r_reg was removed.  [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_round_robin_arb.v:181]}}  -suppress 
set_msg_config  -id {Synth 8-7129}  -string {{WARNING: [Synth 8-7129] Port rd_data_addr[3] in module mig_7series_v4_2_ui_rd_data is either unconnected or has no load}}  -suppress 
set_msg_config  -id {Synth 8-7080}  -suppress 
set_msg_config  -id {Designutils 20-1567}  -string {{WARNING: [Designutils 20-1567] Use of 'set_multicycle_path' with '-hold' is not supported by synthesis. The constraint will not be passed to synthesis. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/constraints/mig_7series_0.xdc:341]}}  -suppress 
set_msg_config  -id {Synth 8-7023}  -string {{WARNING: [Synth 8-7023] instance 'phy_ctl_pre_fifo_1' of module 'mig_7series_v4_2_ddr_of_pre_fifo' has 8 connections declared, but only 7 given [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v:1445]}}  -suppress 
set_msg_config  -id {Synth 8-7071}  -string {{WARNING: [Synth 8-7071] port 'afull' of module 'mig_7series_v4_2_ddr_of_pre_fifo' is unconnected for instance 'phy_ctl_pre_fifo_2' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v:1462]}}  -suppress 
set_msg_config  -id {Synth 8-689}  -string {{WARNING: [Synth 8-689] width (2) of port connection 'fine_adjust_lane_cnt' does not match port width (1) of module 'mig_7series_v4_2_ddr_phy_dqs_found_cal_hr' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_calib_top.v:1963]}}  -suppress 
set_msg_config  -id {Synth 8-3848}  -string {{WARNING: [Synth 8-3848] Net ui_addn_clk_2 in module/entity mig_7series_v4_2_infrastructure does not have driver. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/clocking/mig_7series_v4_2_infrastructure.v:142]}}  -suppress 
set_msg_config  -id {Synth 8-3936}  -string {{WARNING: [Synth 8-3936] Found unconnected internal register 'col_addr_template_reg' and it is trimmed from '16' to '13' bits. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_bank_compare.v:251]}}  -suppress 
set_msg_config  -id {Synth 8-6014}  -string {{WARNING: [Synth 8-6014] Unused sequential element sent_row_or_maint_r_reg was removed.  [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_arb_row_col.v:357]}}  -suppress 
set_msg_config  -id {Synth 8-7129}  -string {{WARNING: [Synth 8-7129] Port rd_data_addr[2] in module mig_7series_v4_2_ui_rd_data is either unconnected or has no load}}  -suppress 
set_msg_config  -id {Synth 8-7023}  -string {{WARNING: [Synth 8-7023] instance 'phy_ctl_pre_fifo_2' of module 'mig_7series_v4_2_ddr_of_pre_fifo' has 8 connections declared, but only 7 given [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v:1462]}}  -suppress 
set_msg_config  -id {Synth 8-7071}  -string {{WARNING: [Synth 8-7071] port 'of_data_a_full' of module 'mig_7series_v4_2_ddr_mc_phy' is unconnected for instance 'u_ddr_mc_phy' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v:1579]}}  -suppress 
set_msg_config  -id {Synth 8-7129}  -string {{WARNING: [Synth 8-7129] Port i_cache_reset in module mem_read_write is either unconnected or has no load}}  -suppress 
set_msg_config  -id {Synth 8-689}  -string {{WARNING: [Synth 8-689] width (12) of port connection 'pi_dqs_found_lanes' does not match port width (4) of module 'mig_7series_v4_2_ddr_calib_top' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_top.v:1340]}}  -suppress 
set_msg_config  -id {Synth 8-3848}  -string {{WARNING: [Synth 8-3848] Net ui_addn_clk_3 in module/entity mig_7series_v4_2_infrastructure does not have driver. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/clocking/mig_7series_v4_2_infrastructure.v:143]}}  -suppress 
set_msg_config  -id {Synth 8-3936}  -string {{WARNING: [Synth 8-3936] Found unconnected internal register 'dbl_req_reg' and it is trimmed from '8' to '7' bits. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_round_robin_arb.v:145]}}  -suppress 
set_msg_config  -id {Synth 8-6014}  -string {{WARNING: [Synth 8-6014] Unused sequential element mc_aux_out_r_1_reg was removed.  [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_arb_select.v:680]}}  -suppress 
set_msg_config  -id {Synth 8-7129}  -string {{WARNING: [Synth 8-7129] Port rd_data_addr[1] in module mig_7series_v4_2_ui_rd_data is either unconnected or has no load}}  -suppress 
set_msg_config  -id {Synth 8-7071}  -string {{WARNING: [Synth 8-7071] port 'complex_oclk_prech_req' of module 'mig_7series_v4_2_ddr_phy_init' is unconnected for instance 'u_ddr_phy_init' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_calib_top.v:1367]}}  -suppress 
set_msg_config  -id {Synth 8-7023}  -string {{WARNING: [Synth 8-7023] instance 'u_ddr_mc_phy' of module 'mig_7series_v4_2_ddr_mc_phy' has 89 connections declared, but only 88 given [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v:1579]}}  -suppress 
set_msg_config  -id {Synth 8-689}  -string {{WARNING: [Synth 8-689] width (1) of port connection 'dbg_poc' does not match port width (1024) of module 'mig_7series_v4_2_memc_ui_top_std' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/mig_7series_0_mig.v:1080]}}  -suppress 
set_msg_config  -id {Synth 8-3848}  -string {{WARNING: [Synth 8-3848] Net ui_addn_clk_4 in module/entity mig_7series_v4_2_infrastructure does not have driver. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/clocking/mig_7series_v4_2_infrastructure.v:144]}}  -suppress 
set_msg_config  -id {Synth 8-3936}  -string {{WARNING: [Synth 8-3936] Found unconnected internal register 'dbl_last_master_ns_reg' and it is trimmed from '8' to '6' bits. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_round_robin_arb.v:143]}}  -suppress 
set_msg_config  -id {Synth 8-7129}  -string {{WARNING: [Synth 8-7129] Port i_load_H in module FPGA_CPU_32_bits_cache is either unconnected or has no load}}  -suppress 
set_msg_config  -id {Synth 8-6014}  -string {{WARNING: [Synth 8-6014] Unused sequential element mc_aux_out_r_2_reg was removed.  [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_arb_select.v:681]}}  -suppress 
set_msg_config  -id {Synth 8-7129}  -string {{WARNING: [Synth 8-7129] Port rd_data_addr[0] in module mig_7series_v4_2_ui_rd_data is either unconnected or has no load}}  -suppress 
set_msg_config  -id {Synth 8-7023}  -string {{WARNING: [Synth 8-7023] instance 'u_ddr_phy_init' of module 'mig_7series_v4_2_ddr_phy_init' has 131 connections declared, but only 130 given [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_calib_top.v:1367]}}  -suppress 
set_msg_config  -id {Synth 8-3848}  -string {{WARNING: [Synth 8-3848] Net channel[0].inh_group in module/entity mig_7series_v4_2_round_robin_arb__parameterized0 does not have driver. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_round_robin_arb.v:153]}}  -suppress 
set_msg_config  -id {Synth 8-6014}  -string {{WARNING: [Synth 8-6014] Unused sequential element fine_delay_r_reg was removed.  [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/phy/mig_7series_v4_2_ddr_byte_group_io.v:185]}}  -suppress 
set_msg_config  -id {Synth 8-3936}  -string {{WARNING: [Synth 8-3936] Found unconnected internal register 'read_fifo.fifo_out_data_r_reg' and it is trimmed from '12' to '8' bits. [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_col_mach.v:396]}}  -suppress 
set_msg_config  -id {Synth 8-7129}  -string {{WARNING: [Synth 8-7129] Port rd_data_offset in module mig_7series_v4_2_ui_rd_data is either unconnected or has no load}}  -suppress 
set_msg_config  -id {Synth 8-3848}  -suppress 
set_msg_config  -id {Synth 8-6014}  -suppress 
set_msg_config  -id {Synth 8-3936}  -suppress 
set_msg_config  -id {DRC REQP-1709}  -string {{WARNING: [DRC REQP-1709] Clock output buffering: PLLE2_ADV connectivity violation. The signal mem_read_write/ddr2_control/mig_7series_0/u_mig_7series_0_mig/u_ddr2_infrastructure/pll_clk3_out on the mem_read_write/ddr2_control/mig_7series_0/u_mig_7series_0_mig/u_ddr2_infrastructure/plle2_i/CLKOUT3 pin of mem_read_write/ddr2_control/mig_7series_0/u_mig_7series_0_mig/u_ddr2_infrastructure/plle2_i does not drive the same kind of BUFFER load as the other CLKOUT pins. Routing from the different buffer types will not be phase aligned.}}  -suppress 
set_msg_config  -id {Synth 8-7129}  -suppress 
set_msg_config  -id {Synth 8-10515}  -suppress 
set_msg_config  -id {Synth 8-567}  -string {{WARNING: [Synth 8-567] referenced signal 'periodic_rd_generation.periodic_rd_timer_one' should be on the sensitivity list [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_rank_cntrl.v:509]}}  -suppress 
set_msg_config  -id {Synth 8-7071}  -string {{WARNING: [Synth 8-7071] port 'idle' of module 'mig_7series_v4_2_bank_mach' is unconnected for instance 'bank_mach0' [/home/graham/Documents/src/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.srcs/sources_1/ip/mig_7series_0/mig_7series_0/user_design/rtl/controller/mig_7series_v4_2_mc.v:670]}}  -suppress 

OPTRACE "impl_1" START { ROLLUP_1 }
OPTRACE "Phase: Write Bitstream" START { ROLLUP_AUTO }
OPTRACE "write_bitstream setup" START { }
start_step write_bitstream
set ACTIVE_STEP write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  set_param chipscope.maxJobs 1
  set_param general.usePosixSpawnForFork 1
  set_param runs.launchOptions { -jobs 4  }
  open_checkpoint FPGA_CPU_32_bits_cache_postroute_physopt.dcp
  set_property webtalk.parent_dir /home/graham/Documents/src/fpga/FPGA_CPU_32_DDR_cache/FPGA_CPU_32_DDR_cache.cache/wt [current_project]
set_property TOP FPGA_CPU_32_bits_cache [current_fileset]
OPTRACE "read constraints: write_bitstream" START { }
OPTRACE "read constraints: write_bitstream" END { }
  set_property XPM_LIBRARIES XPM_CDC [current_project]
  catch { write_mem_info -force -no_partial_mmi FPGA_CPU_32_bits_cache.mmi }
OPTRACE "write_bitstream setup" END { }
OPTRACE "write_bitstream" START { }
  write_bitstream -force FPGA_CPU_32_bits_cache.bit 
OPTRACE "write_bitstream" END { }
OPTRACE "write_bitstream misc" START { }
OPTRACE "read constraints: write_bitstream_post" START { }
OPTRACE "read constraints: write_bitstream_post" END { }
  catch {write_debug_probes -quiet -force FPGA_CPU_32_bits_cache}
  catch {file copy -force FPGA_CPU_32_bits_cache.ltx debug_nets.ltx}
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
  unset ACTIVE_STEP 
}

OPTRACE "write_bitstream misc" END { }
OPTRACE "Phase: Write Bitstream" END { }
OPTRACE "impl_1" END { }
