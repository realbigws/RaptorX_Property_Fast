#!/bin/bash

if [ $# -lt 1 ]
then
	echo "./self_pwd.sh [OutType] "
	echo "[OutType]: 1 for linux out, and other for perl out"
	exit
fi

OutType=$1

# ---- start ----- #
tempDBDir=`mktemp -d tempDB.XXXXX`
pwd > $tempDBDir/ws1
a=`echo ~ | awk '{l=length($0); f=substr($0,l,1); g=substr($0,1,l-1); if(f=="/"){print g}else{print $0}}'`

# ---- bash or perl ---- #
if [ $OutType -eq 1 ]
then
	sed "s#$a#~#g" $tempDBDir/ws1 > $tempDBDir/ws2
	cat $tempDBDir/ws2
else
	sed "s#$a##g" $tempDBDir/ws1 > $tempDBDir/ws2
	cat $tempDBDir/ws2
fi
rm -r $tempDBDir

