#!/bin/bash
if [ $# -ne 2 ]
then
	echo "Usage: ./genSS8.sh <tgt_file> <tmp_root>"
	exit
fi

# ---- get arguments ----#
tgt_file=$1
tmp_root=$2

# ---- process -----#
RaptorX_HOME=~/RaptorX_Property_Fast
fulnam=`basename $tgt_file`
relnam=${fulnam%.*}
SS8Pred=$RaptorX_HOME/bin/DeepCNF_SS_Con
$SS8Pred -t $tgt_file > $tmp_root/$relnam.ss8

