#!/bin/bash

# ----- usage ------ #
usage()
{
	echo "PDBTM_Topology_Pred v1.04 [Nov-20-2017] "
	echo "    Predict 9-state PDBTM Topology labels given a protein sequence "
	echo ""
	echo "USAGE:  ./PDBTM_Topology_Pred.sh <-i input_fasta | input_tgt> "
	echo "          [-o output] [-c CPU_num] [-k keep_file] [-l real_label] "
	echo ""
	echo "Options:"
	echo ""
	echo "***** required arguments *****"
	echo "-i input_fasta :  input protein sequence file in FASTA format"
	echo "(or)"
	echo "-i input_tgt   :  input protein profile file in TGT format"
	echo ""
	echo "***** optional arguments *****"
	echo "-o output      :  default output would be XXXX.diso_MODE at the current directory,"
	echo "                  where XXXX is the input name, and MODE is profile or noprof"
	echo ""
	echo "-c CPU_num     :  the number of CPUs to be used [default 1]"
	echo ""
	echo "-k keep_file   :  keep the intermediate files if its value is 1 [default 0]"
	echo ""
	echo "-l real_label  :  real PDBTM Topology label file, in  three lines " 
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
if [ ! -f "$RaptorX_HOME/PDBTM_Topology_Pred.sh" ]
then
	echo "PDBTM_Topology_Pred program file $RaptorX_HOME/PDBTM_Topology_Pred.sh not exist."
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
label_file=""
#-> optional arguments
CPU_num=1
Keep_file=0

#-> parse arguments
while getopts ":i:o:c:k:l:" opt;
do
	case $opt in
	#-> required arguments
	i)
		input=$OPTARG
		;;
	#-> optional arguments
	o)
		output=$OPTARG
		;;
	c)
		CPU_num=$OPTARG
		;;
	k)
		Keep_file=$OPTARG
		;;
	l)
		label_file=$OPTARG
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
tmp=/tmp/TransMemb"_"$relnam"_"$RANDOM
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
		# ----- generate feature ----- #
		if [ "$label_file" == "" ]
		then
			$util/MemProt_Feat $tmp/$relnam.tgt $tmp/$relnam.ss8 null > $tmp/$relnam.feat_profile
		else
			$util/MemProt_Feat $tmp/$relnam.tgt $tmp/$relnam.ss8 $label_file > $tmp/$relnam.feat_profile
		fi
		OUT=$?
		if [ $OUT -ne 0 ]
		then
			echo "Failed in generating feature file (profile mode) for sequence $relnam"
			program_suc=0
			break
		fi

	# ------------ amionly mode ---------- #
	else
		# ----- generate predicted SSE and ACC ----- #
		cd util/psisolvpred
			./runxxxpred_single $tmp/$relnam.seq 1> $tmp/$relnam.ws1 2> $tmp/$relnam.ws2
			mv /tmp/$relnam.solv /tmp/$relnam.ss2 $tmp
			rm -f /tmp/$relnam.ss /tmp/$relnam.horiz $tmp/$relnam.ws1 $tmp/$relnam.ws2
		cd ../../
		# ----- generate feature ----- #
		if [ "$label_file" == "" ]
		then
			$util/MemProt_Feat_noprof $tmp/$relnam.seq $tmp/$relnam.ss2 $tmp/$relnam.solv null > $tmp/$relnam.feat_noprof
		else
			$util/MemProt_Feat_noprof $tmp/$relnam.seq $tmp/$relnam.ss2 $tmp/$relnam.solv $label_file > $tmp/$relnam.feat_noprof
		fi
		OUT=$?
		if [ $OUT -ne 0 ]
		then
			echo "Failed in generating feature file (no_profile mode) for sequence $relnam"
			program_suc=0
			break
		fi
	fi


	# ---------- predict trans-membrane regions ----------- #
	outnam=$relnam.topo
	outfeat=$relnam.feat
	if [ $amino_only -eq 0 ]
	then
		$util/DeepCNF_Pred -i $tmp/$relnam.feat_profile -w 5,5,5,5,5 -d 100,100,100,100,100 -s 9 -l 68 -m parameters/MemProt_profile_model > $tmp/$relnam.topo_profile 2> $tmp/$relnam.pred_log2
		OUT=$?
		if [ $OUT -ne 0 ]
		then
			echo "Failed in prediction of membrane topology (profile mode )for sequence $relnam"
			program_suc=0
			break
		fi
		outnam=$relnam.topo_profile
		outfeat=$relnam.feat_profile
	else
		$util/DeepCNF_Pred -i $tmp/$relnam.feat_noprof -w 5,5,5,5,5 -d 100,100,100,100,100 -s 9 -l 87 -m parameters/MemProt_noprof_model > $tmp/$relnam.topo_noprof 2> $tmp/$relnam.pred_log2
		OUT=$?
		if [ $OUT -ne 0 ]
		then
			echo "Failed in prediction of membrane topology (no_profile mode) for sequence $relnam"
			program_suc=0
			break
		fi
		outnam=$relnam.topo_noprof
		outfeat=$relnam.feat_noprof
	fi

	# ------ final copy ------ #
	if [ "$output" == "" ]
	then
		cp $tmp/$outnam $curdir/$outnam
	else
		cp $tmp/$outnam $output
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

