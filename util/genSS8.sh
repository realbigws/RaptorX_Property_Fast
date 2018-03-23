#!/bin/bash
if [ $# -ne 2 ]
then
        echo "Usage: ./genSS8 <tgt_name> <tmp_root>"
        exit
fi

# ---- get arguments ----#
tgt_name=$1
tmp_root=$2

# ---- process -----#
RaptorX_HOME=~/RaptorX_Property_Fast
SS8_Pred=$RaptorX_HOME/util/SS8_Predict/bin/run_raptorx-ss8.pl
$SS8_Pred $tmp_root/$tgt_name.seq -pssm $tmp_root/$tgt_name.psp -outdir $tmp_root/

