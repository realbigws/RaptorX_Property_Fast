#!/bin/bash
if [ $# -ne 2 ]
then
	echo "Usage: ./genACC.sh <tgt_file> <tmp_root> "
	exit
fi

# ---- get arguments ----#
tgt_file=$1
tmp_root=$2

# ---- process -----#
RaptorX_HOME=~/GitBucket/RaptorX_Property_Fast
fulnam=`basename $tgt_file`
relnam=${fulnam%.*}
mkdir -p $RaptorX_HOME/$tmp_root
ACCPred=$RaptorX_HOME/bin/AcconPred
$ACCPred $tgt_file 1 > $RaptorX_HOME/$tmp_root/$relnam.acc

