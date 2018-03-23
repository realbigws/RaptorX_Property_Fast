#!/bin/bash
if [ $# -ne 2 ]
then
        echo "Usage: ./genMAIN.sh <input_a3m> <temp_dir> "
        exit
fi

#----- input files ------#
INPUTA3M=$1
TEMPDIR=$2
fulnam=`basename $1`
bname=${fulnam%.*}
rootname=R$bname


#------ directory ------#
RaptorX_HOME=~/RaptorX_Property_Fast
A3M_To_PSI=$RaptorX_HOME/util/A3M_To_PSI
MSA_To_PSSM=$RaptorX_HOME/util/MSA_To_PSSM
HHMAKE=$RaptorX_HOME/util/hhmake

#----- generate PSP and MTX -----#
$A3M_To_PSI $INPUTA3M $TEMPDIR/$rootname.psi_tmp
grep -v "ss_pred\|ss_conf\|ss_dssp" $TEMPDIR/$rootname.psi_tmp > $TEMPDIR/$rootname.psi
$MSA_To_PSSM -i $TEMPDIR/$rootname.psi -o $TEMPDIR/$rootname.psp -m $TEMPDIR/$rootname.mtx -c 20
$HHMAKE -i $INPUTA3M -o $TEMPDIR/$rootname.hhm
rm -f $TEMPDIR/$rootname.psi_tmp

#----- move generated files to output ---#
mv $TEMPDIR/$rootname.psi $TEMPDIR/$bname.psi
mv $TEMPDIR/$rootname.psp $TEMPDIR/$bname.psp
mv $TEMPDIR/$rootname.mtx $TEMPDIR/$bname.mtx
mv $TEMPDIR/$rootname.hhm $TEMPDIR/$bname.hhm

