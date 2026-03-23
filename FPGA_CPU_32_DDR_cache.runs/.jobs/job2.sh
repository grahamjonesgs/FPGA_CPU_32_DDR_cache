#!/bin/bash

# 
# Vivado(TM)
# launch.sh: a Vivado-generated ExploreAhead Script for UNIX
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
# 

HD_LDIR=`dirname "$0"`

# *** Create Queue Clues
HD_RUNDIR="$HD_LDIR/../synth_1"
if [ -d "$HD_RUNDIR" ]
then
/bin/touch "$HD_RUNDIR/.Vivado_Synthesis.queue.rst"
fi


# *** Launch Runs (one at a time)
HD_RUNSH="$HD_LDIR/../synth_1/runme.sh"
if [ -f "$HD_RUNSH" ]
then
"$HD_RUNSH"
fi


