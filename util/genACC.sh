#!/bin/bash
if [ $# -ne 2 ]
then
        echo "Usage: ./genACC <tgt_name> <tmp_root> "
        exit
fi

# ---- get arguments ----#
tgt_name=$1
tmp_root=$2

# ---- process -----#
RaptorX_HOME=~/RaptorX_Property_Fast
ACCPred=$RaptorX_HOME/util/ACC_Predict/acc_pred
$ACCPred $tmp_root/$tgt_name.hhm $tmp_root/$tgt_name.ss2 $tmp_root/$tgt_name.ss8 $RaptorX_HOME/util/ACC_Predict/model.accpred $tmp_root/$tgt_name.acc

