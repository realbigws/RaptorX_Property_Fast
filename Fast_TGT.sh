#!/bin/bash

# ----- usage ------ #
usage()
{
	echo "Version 1.03 [2016-07-07] "
	echo "USAGE: ./Fast_TGT.sh <-i input_fasta> [-n iteration] [-C coverage] "
	echo "       [-o out_root] [-j job_id] [-c CPU_num] [-k kill_tmp] [-d uniprot20]"
	echo "[note1]: default HHblits iteration number is 3, CPU_num is 4, "
	echo "         and kill_tmp is 1 to remove temporary files in /tmp/\${input_name}_\${job_id}/. "
	echo "[note2]: Default value of job_id is tmp, out_root is current directory. "
	echo "[note3]: Default coverage is -2, i.e., NOT use -cov in HHblits. "
	echo "         if set to -1, then automatically determine coverate value. "
	echo "         if set to any other positive value, then use this -cov in HHblits. "
	echo "[note4]: Default uniprot20 version is set to 'uniprot20_2016_02' "
	exit 1
}

if [ $# -lt 1 ];
then
        usage
fi
curdir="$(pwd)"



# ----- get arguments ----- #
#-> optional arguments
out_root="./"   #-> output to current directory
job_id="tmp"    #-> we allow job id here
coverage=-2     #-> automatic determine the coverage on basis of input sequence length 
cpu_num=4       #-> use 4 CPUs 
kill_tmp=1      #-> default: kill temporary root
#-> required arguments
input_fasta=""
iteration=3
uniprot20=uniprot20_2016_02

#-> parse arguments
while getopts ":i:n:C:o:j:c:k:d:" opt;
do
	case $opt in
	#-> required arguments
	i)
		input_fasta=$OPTARG
		;;
	#-> optional arguments
	n)
		iteration=$OPTARG
		;;
	C)
		coverage=$OPTARG
		;;
	o)
		out_root=$OPTARG
		;;
	j)
		job_id=$OPTARG
		;;
	c)
		cpu_num=$OPTARG
		;;
	k)
		kill_tmp=$OPTARG
		;;
	d)
		uniprot20=$OPTARG
		;;
	#-> others
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


# ------ check required arguments ------ #
if [ ! -f "$input_fasta" ]
then
	echo "input_fasta $input_fasta not found !!" >&2
	exit 1
fi


# ------ related path ------ #
#-> get job id:
fulnam=`basename $input_fasta`
relnam=${fulnam%.*}

# --- create temporary folder --#
tmp_root=/tmp/$relnam"_"$job_id/
mkdir -p $out_root
mkdir -p $tmp_root


# ---- verify FASTA file -------- #
seq_file=$relnam.seq
util/Verify_FASTA $input_fasta $tmp_root/$seq_file
OUT=$?
if [ $OUT -ne 0 ]
then
	echo "failed in util/Verify_FASTA $input_fasta $tmp_root/$seq_file"
	exit 1
fi


# ----- determine coverage ---- #
if [ $coverage -eq -1 ]
then
	a=60
	b=`tail -n1 $tmp_root/$seq_file | wc | awk '{print int(7000/($3-1))}'`
	if [ $a -gt $b ]
	then
		coverage=$b
	else
		coverage=$a
	fi
fi


# ---- generate A3M file -------- #
a3m_file=$relnam.a3m
if [ ! -f "$tmp_root/$a3m_file" ]
then
	echo "hhblits start with database $uniprot20"
	HHSUITE=hhsuite
	HHLIB=$HHSUITE/lib/hh
	if [ $coverage -eq -2 ]
	then
		echo "run HHblits with default parameter without -cov "
		$HHSUITE/bin/hhblits -i $tmp_root/$seq_file -cpu $cpu_num -d databases/$uniprot20/$uniprot20 -o $tmp_root/$relnam.hhr -oa3m $tmp_root/$relnam.a3m -n $iteration
	else
		echo "run HHblits with -maxfilt 500000 -diff inf -id 99 -cov $coverage"
		$HHSUITE/bin/hhblits -i $tmp_root/$seq_file -cpu $cpu_num -d databases/$uniprot20/$uniprot20 -o $tmp_root/$relnam.hhr -oa3m $tmp_root/$relnam.a3m -n $iteration -maxfilt 500000 -diff inf -id 99 -cov $coverage
	fi
	OUT=$?
	if [ $OUT -ne 0 ]
	then
		echo "failed in $HHSUITE/bin/hhblits -i $tmp_root/$seq_file -cpu $cpu_num -d databases/$uniprot20/$uniprot20 -o $tmp_root/$relnam.hhr -oa3m $tmp_root/$relnam.a3m -n $iteration"
		exit 1
	fi
	echo "hhblits done"
fi

# ---- generate TGT file ------ #
tgt_file=$relnam.tgt
if [ ! -f "$tmp_root/$tgt_file" ]
then
	./A3M_To_TGT -i $tmp_root/$seq_file -I $tmp_root/$a3m_file -o $tmp_root/$tgt_file -t $tmp_root
	OUT=$?
	if [ $OUT -ne 0 ]
	then
		echo "failed in ./A3M_To_TGT -i $tmp_root/$seq_file -I $tmp_root/$a3m_file -o $tmp_root/$tgt_file -t $tmp_root"
		exit 1
	fi
fi

# ---- post process ----- #
cp $input_fasta $out_root/$relnam.fasta_raw
mv $tmp_root/$seq_file $tmp_root/$a3m_file $tmp_root/$tgt_file $out_root
if [ $kill_tmp -eq 1 ]
then
	rm -f $tmp_root/$relnam.*
	rmdir $tmp_root
fi

# ========= exit 0 =========== #
exit 0


