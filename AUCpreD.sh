#!/bin/bash

# ----- usage ------ #
usage()
{
	echo "AUCpreD v1.03 [Oct-20-2015] "
	echo "    Predict order/disorder regions using sequence or profile information"
	echo ""
	echo "USAGE:  ./AUCpreD.sh [-i input_fasta | input_tgt] [-m mode]"
	echo "          [-o output] [-t threshold] [-c CPU_num] [-k keep_file]"
	echo ""
	echo "Options:"
	echo ""
	echo "***** required arguments *****"
	echo "-i input_fasta :  input protein sequence file in FASTA format"
	echo "(or)"
	echo "-i input_tgt   :  input protein profile file in TGT format"
	echo ""
	echo "***** optional arguments *****"
	echo "-m mode        :  prediction mode, 0 for using sequence profile, while 1 not"
	echo "                  if the mode is not explicitly set, when the input file has a suffix '.tgt', "
	echo "                     then mode is set to 0 by default;"
	echo "                  otherwise, mode is set to 1 by default"
	echo ""
	echo "-o output      :  default output would be XXXX.diso_MODE at the current directory,"
	echo "                  where XXXX is the input name, and MODE is profile or noprof"
	echo ""
	echo "-t threshold   :  threshold to determine disordered residue."
	echo "                  [default: 0.2 for sequence mode, and 0.25 for profile mode]"
	echo ""
	echo "-c CPU_num     :  the number of CPUs to be used [default 1]"
	echo ""
	echo "-k keep_file   :  keep the intermediate files if its value is 1 [default 0]"
	echo "                  these files are in /tmp/\${input_name}_diso/. "
	echo ""
	exit 1
}

if [ $# -lt 1 ];
then
        usage
fi
curdir="$(pwd)"

# ----- main directory ---#
util=bin
RaptorX_HOME=~/RaptorX_Property_Fast
#-> check directory
if [ ! -f "$RaptorX_HOME/AUCpreD.sh" ]
then
	echo "AUCpreD program file $RaptorX_HOME/AUCpreD.sh not exist."
	echo "please run './setup.pl' to configure the package."
	exit 1
fi


# ----- get arguments ----- #
#-> required arguments
input=""
input_fasta=""
input_tgt=""
amino_only=-1
output=""
#-> optional arguments
threshold=""
threshold_ami=0.5
threshold_pro=0.5
CPU_num=1
Keep_file=0

#-> parse arguments
while getopts ":i:m:o:t:c:k:" opt;
do
	case $opt in
	#-> required arguments
	i)
		input=$OPTARG
		;;
	#-> optional arguments
	m)
		amino_only=$OPTARG
		;;
	o)
		output=$OPTARG
		;;
	t)
		threshold=$OPTARG
		;;
	c)
		CPU_num=$OPTARG
		;;
	k)
		Keep_file=$OPTARG
		;;
	#-> default
	\?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
	:)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1
		;;
	esac
done

# ------ judge fasta or tgt -------- #
filename=`basename $input`
extension=${filename##*.}
filename=${filename%.*}
if [ "$extension" == "tgt" ]
then
	input_tgt=$input
	if [ $amino_only -eq -1 ]
	then
		amino_only=0
	fi
else
	input_fasta=$input
	if [ $amino_only -eq -1 ]
	then
		amino_only=1
	fi
fi

# ------ check required arguments ------ #
#-> check input_tgt
has_tgt=0
if [ ! -f "$curdir/$input_tgt" ]
then
	if [ ! -f "$input_tgt" ]
	then
		has_tgt=0
	else
		has_tgt=1
	fi
else
	input_tgt=$curdir/$input_tgt
	has_tgt=1
fi

#-> check input_fasta
has_fasta=0
if [ ! -f "$curdir/$input_fasta" ]
then
	if [ ! -f "$input_fasta" ]
	then
		has_fasta=0
	else
		has_fasta=1
	fi
else
	input_fasta=$curdir/$input_fasta
	has_fasta=1
fi

# ------ final check ------#
if [ $has_fasta -eq 0 ] && [ $has_tgt -eq 0 ]
then
	echo "input_fasta $input_fasta or input_tgt $input_tgt not found" >&2
	exit 1
fi

# ------ part 0 ------ # related path
if [ $has_fasta -eq 1 ]
then
	fulnam=`basename $input_fasta`
	relnam=${fulnam%.*}
fi
if [ $has_tgt -eq 1 ]
then
	fulnam=`basename $input_tgt`
	relnam=${fulnam%.*}
fi

# ----- pre process ------ #
cd $RaptorX_HOME
tmp=/tmp/${relnam}_diso/
mkdir -p $tmp/
rm -f $tmp/$relnam.seq
if [ $has_fasta -eq 1 ]
then
	cp $input_fasta $tmp/$relnam.seq
fi
if [ $has_tgt -eq 1 ]
then
	cp $input_tgt $tmp/$relnam.tgt
	echo ">$relnam" > $tmp/$relnam.seq
	head -n4 $tmp/$relnam.tgt | tail -n1 | awk '{print $3}' >> $tmp/$relnam.seq
fi

# ----- main procedure ------ #
program_suc=1
for ((i=0;i<1;i++))
do
	# ------------ profile mode ---------- #
	if [ $amino_only -eq 0 ]
	then
		# ----- buildFeature ------ #
		if [ ! -f "$tmp/$relnam.tgt" ]
		then
			echo "Running buildFeature to generate TGT file for sequence $relnam"
			./Fast_TGT.sh -i $tmp/$relnam.seq -o $tmp -c $CPU_num 1> $tmp/$relnam.tgt_log1 2> $tmp/$relnam.tgt_log2
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating TGT file for sequence $relnam"
				program_suc=0
				break
			fi
			cp $tmp/$relnam.tgt $curdir/$relnam.tgt
		fi
		# ----- DeepCNF_SS_Con ----- #
		$util/DeepCNF_SS_Con -t $tmp/$relnam.tgt > $tmp/$relnam.ss8
		OUT=$?
		if [ $OUT -ne 0 ]
		then
			echo "Failed in generating SS8 file for sequence $relnam"
			program_suc=0
			break
		fi
		# ----- AcconPred ----- #
		$util/AcconPred $tmp/$relnam.tgt 1 > $tmp/$relnam.acc
		OUT=$?
		if [ $OUT -ne 0 ]
		then
			echo "Failed in generating ACC file for sequence $relnam"
			program_suc=0
			break
		fi
		# ----- generate feature ----- #
		$util/Diso_Feature_Make $tmp/$relnam.tgt $tmp/$relnam.ss8 $tmp/$relnam.acc -1 > $tmp/$relnam.feat_profile
		OUT=$?
		if [ $OUT -ne 0 ]
		then
			echo "Failed in generating feature file (profile mode) for sequence $relnam"
			program_suc=0
			break
		fi
		# ----- determine threshold --- #
		if [ "$threshold" == "" ]
		then
			threshold=$threshold_pro
		fi

	# ------------ amionly mode ---------- #
	else
		# ----- generate predicted SSE and ACC ----- #
		cd util/psisolvpred
			./runxxxpred_single ../../$tmp/$relnam.seq 1> $relnam.ws1 2> $relnam.ws2
			mv $relnam.solv $relnam.ss2 ../../$tmp
			rm -f $relnam.ss $relnam.horiz $relnam.ws1 $relnam.ws2
		cd ../../
		# ----- generate feature ----- #
		$util/Diso_Feature_Make_noprof $tmp/$relnam.seq $tmp/$relnam.ss2 $tmp/$relnam.solv -1 > $tmp/$relnam.feat_noprof
		OUT=$?
		if [ $OUT -ne 0 ]
		then
			echo "Failed in generating feature file (no_profile mode) for sequence $relnam"
			program_suc=0
			break
		fi
		# ----- determine threshold --- #
		if [ "$threshold" == "" ]
		then
			threshold=$threshold_ami
		fi
	fi

	# ---------- predict order/disorder regions ----------- #
	outnam=$relnam.diso
	if [ $amino_only -eq 0 ]
	then
		$util/DeepCNF_Pred -i $tmp/$relnam.feat_profile -w 5,5 -d 50,50 -s 3 -l 148 -m parameters/AUCpreD_profile_model > $tmp/$relnam.diso_profile 2> $tmp/$relnam.pred_log2
		OUT=$?
		if [ $OUT -ne 0 ]
		then
			echo "Failed in prediction of order/disorder (profile mode )for sequence $relnam"
			program_suc=0
			break
		fi
		outnam=$relnam.diso_profile
	else
		$util/DeepCNF_Pred -i $tmp/$relnam.feat_noprof -w 5,5 -d 50,50 -s 3 -l 87 -m parameters/AUCpreD_noprof_model > $tmp/$relnam.diso_noprof 2> $tmp/$relnam.pred_log2
		OUT=$?
		if [ $OUT -ne 0 ]
		then
			echo "Failed in prediction of order/disorder (no_profile mode) for sequence $relnam"
			program_suc=0
			break
		fi
		outnam=$relnam.diso_noprof
	fi

	# ---------- transform the raw result into DisoPred format ------ #
	if [ "$output" == "" ]
	then
		$util/DisoPred_Trans $tmp/$relnam.seq $tmp/$outnam $threshold $amino_only > $curdir/$outnam
	else
		$util/DisoPred_Trans $tmp/$relnam.seq $tmp/$outnam $threshold $amino_only > $output
	fi

done

# ----- return back ----#
cd $RaptorX_HOME
if [ $Keep_file -eq 0 ]
then
	rm -rf $tmp/
fi
cd $curdir

# ---- exit ----- #
if [ $program_suc -ne 0 ]
then
	exit 0
else
	exit 1
fi

