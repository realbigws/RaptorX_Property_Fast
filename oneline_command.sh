#!/bin/bash

if [ $# -lt 2 ]
then
	echo "Usage: ./protprop_server.sh <input_fasta> <out_dir> [cpu_number] [PROF_or_NOT] "
	exit
fi
CurRoot="$(pwd)"


# ------- CPU number ------ #
BindX_CPU=1
if [ $# -gt 2 ]
then
	BindX_CPU=$3
fi

# ------- use profile or not ---- #
PROF_or_NOT=1
if [ $# -gt 3 ]
then
	PROF_or_NOT=$4
fi

# ------ part 0 ------ # related path
fulnam=`basename $1`
relnam=${fulnam%.*}
OUT_DIR=$2

# ------- run ProtProp Server --------- #
Server_Root=~/RaptorX_Property_Fast
cp $1 $Server_Root/$relnam.fasta

# ---- check if TGT file exist ----- #
has_TGT=0
if [ -f "$relnam.tgt" ]
then
	has_TGT=1
	cp $relnam.tgt $Server_Root/
fi

# ---- running ---------#
cd $Server_Root
	#-> 0. create 'tmp' folder
	rm -rf $OUT_DIR/$relnam
	mkdir -p $OUT_DIR/$relnam
	tmp=TMP"_"$relnam"_"$RANDOM
	mkdir -p $tmp/
	#------- start -------#
	util=bin
	program_suc=1
	for ((i=0;i<1;i++))
	do
		if [ $PROF_or_NOT -eq 1 ] #-> use profile
		then

			#-> 1. build TGT file
			if [ $has_TGT -eq 0 ]
			then
				#--> Fast_TGT
				echo "Running Fast_TGT to generate TGT file for sequence $relnam"
				./Fast_TGT.sh -i $relnam.fasta -c $BindX_CPU -o $tmp 1> $tmp/$relnam.tgt_log1 2> $tmp/$relnam.tgt_log2
				OUT=$?
				if [ $OUT -ne 0 ]
				then
					echo "Failed in generating TGT file for sequence $relnam"
					program_suc=0
					break
				fi
			else
				mv $relnam.tgt $tmp/$relnam.tgt
			fi
			util/Verify_FASTA $relnam.fasta $tmp/$relnam.seq
			cp $relnam.fasta $tmp/$relnam.fasta_raw
			#-> 1.1 TGT Update
			echo "Running TGT_Update to upgrade TGT file for sequence $relnam"
			tmptmp=TMPTMP"_"$relnam"_"$RANDOM
			mkdir -p $tmptmp
			mkdir -p $tmp/update/
			./TGT_Update -i $tmp/$relnam.tgt -o $tmp/update/$relnam.tgt -t $tmptmp
			rm -r $tmptmp
			#-> 2. generate SS3/SS8 file
			#--> SS8
			$util/DeepCNF_SS_Con -t $tmp/$relnam.tgt -s 0 > $tmp/$relnam.ss8
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating SS8 file for sequence $relnam"
				program_suc=0
				break
			fi
			#--> SS3
			$util/DeepCNF_SS_Con -t $tmp/$relnam.tgt -s 1 > $tmp/$relnam.ss3
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating SS3 file for sequence $relnam"
				program_suc=0
				break
			fi
			#-> 3. generate ACC/CN file
			#--> ACC
			$util/DeepCNF_SAS_Con -t $tmp/update/$relnam.tgt -m 0 > $tmp/$relnam.acc
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating ACC file for sequence $relnam"
				program_suc=0
				break
			fi
			#--> CN
			$util/AcconPred $tmp/$relnam.tgt 0 > $tmp/$relnam.cn
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating CN file for sequence $relnam"
				program_suc=0
				break
			fi
			#-> 4. generate DISO file
			./AUCpreD.sh -i $tmp/$relnam.tgt -o $tmp/$relnam.diso
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating DISO file for sequence $relnam"
				program_suc=0
				break
			fi

		else     #-> not use profile

			#-> 1. generate feature file
			util/Verify_FASTA $relnam.fasta $tmp/$relnam.seq
			cp $relnam.fasta $tmp/$relnam.fasta_raw
			#--> feat_file
			./Seq_Feat.sh -i $tmp/$relnam.seq
			mv $relnam.feat_noprof $tmp/$relnam.feat_noprof
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating noprof_feat file for sequence $relnam"
				program_suc=0
				break
			fi
			#--> pred_file for SS8/SS3
			$util/DeepCNF_Pred -i $tmp/$relnam.feat_noprof -w 5,5,5,5,5 -d 100,100,100,100,100 -s 8 -l 87 -m parameters/ss8_noprof_model > $tmp/$relnam.ss8_noprof 2> $tmp/$relnam.noprf_log3
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in prediction of SS8/SS3 (no_profile mode) for sequence $relnam"
				program_suc=0
				break
			fi
			#--> pred_file for ACC
			$util/DeepCNF_Pred -i $tmp/$relnam.feat_noprof -w 5,5,5,5,5 -d 100,100,100,100,100 -s 3 -l 87 -m parameters/acc_noprof_model > $tmp/$relnam.acc_noprof 2> $tmp/$relnam.noprf_log4
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in prediction of ACC (no_profile mode) for sequence $relnam"
				program_suc=0
				break
			fi
			#--> pred_file for CN
			$util/DeepCNF_Pred -i $tmp/$relnam.feat_noprof -w 5,5,5,5,5 -d 100,100,100,100,100 -s 15 -l 87 -m parameters/cn_noprof_model > $tmp/$relnam.cn_noprof 2> $tmp/$relnam.noprf_log5
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in prediction of CN (no_profile mode) for sequence $relnam"
				program_suc=0
				break
			fi
			#-> 2. generate SS3/SS8 file
			#--> SS8
			$util/Label_Parser $tmp/$relnam.seq $tmp/$relnam.ss8_noprof 0 > $tmp/$relnam.ss8_
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating SS8 noprof_file for sequence $relnam"
				program_suc=0
				break
			fi
			#--> SS3
			$util/Label_Parser $tmp/$relnam.seq $tmp/$relnam.ss8_noprof 1 > $tmp/$relnam.ss3_
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating SS3 noprof_file for sequence $relnam"
				program_suc=0
				break
			fi
			#-> 3. generate ACC/CN file
			#--> ACC
			$util/Label_Parser $tmp/$relnam.seq $tmp/$relnam.acc_noprof 2 > $tmp/$relnam.acc_
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating ACC noprof_file for sequence $relnam"
				program_suc=0
				break
			fi
			#--> CN
			$util/Label_Parser $tmp/$relnam.seq $tmp/$relnam.cn_noprof 3 > $tmp/$relnam.cn_
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating CN noprof_file for sequence $relnam"
				program_suc=0
				break
			fi
			#-> 4. generate DISO file
			./AUCpreD.sh -i $tmp/$relnam.seq -o $tmp/$relnam.diso_
			OUT=$?
			if [ $OUT -ne 0 ]
			then
				echo "Failed in generating DISO noprof_file for sequence $relnam"
				program_suc=0
				break
			fi

		fi
	done
	# ----------- end ------------- #
	if [ $program_suc -ne 1 ]
	then
        	exit 1
	fi
	# ----------- copy to $OUT_DIR/ ----- #
	if [ $PROF_or_NOT -eq 1 ] #-> use profile
	then

		cp util/0README $OUT_DIR/$relnam/0README.txt
		cp $tmp/$relnam.fasta_raw $OUT_DIR/$relnam/$relnam.fasta.txt
		cp $tmp/$relnam.seq $OUT_DIR/$relnam/$relnam.seq.txt
		awk '{if(NF>0){print $0}}' $tmp/$relnam.ss3 > $OUT_DIR/$relnam/$relnam.ss3.txt
		awk '{if(NF>0){print $0}}' $tmp/$relnam.ss8 > $OUT_DIR/$relnam/$relnam.ss8.txt
		awk '{if(NF>0){print $0}}' $tmp/$relnam.acc > $OUT_DIR/$relnam/$relnam.acc.txt
		awk '{if(NF>0){print $0}}' $tmp/$relnam.diso > $OUT_DIR/$relnam/$relnam.diso.txt
		# make simple prediction
		#-> SS3
		echo ">$relnam" > $OUT_DIR/$relnam/$relnam.ss3_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.ss3.txt | awk '{printf $2}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.ss3_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.ss3.txt | awk '{printf $3}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.ss3_simp.txt
		#-> SS8
		echo ">$relnam" > $OUT_DIR/$relnam/$relnam.ss8_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.ss8.txt | awk '{printf $2}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.ss8_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.ss8.txt | awk '{printf $3}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.ss8_simp.txt
		#-> ACC
		echo ">$relnam" > $OUT_DIR/$relnam/$relnam.acc_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.acc.txt | awk '{printf $2}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.acc_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.acc.txt | awk '{printf $3}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.acc_simp.txt
		#-> DISO
		echo ">$relnam" > $OUT_DIR/$relnam/$relnam.diso_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.diso.txt | awk '{printf $2}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.diso_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.diso.txt | awk '{printf $3}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.diso_simp.txt
		# make overall prediction
		head -n1 $OUT_DIR/$relnam/$relnam.fasta.txt > $OUT_DIR/$relnam/$relnam.all.txt
		tail -n1 $OUT_DIR/$relnam/$relnam.seq.txt >> $OUT_DIR/$relnam/$relnam.all.txt
		tail -n1 $OUT_DIR/$relnam/$relnam.ss3_simp.txt >> $OUT_DIR/$relnam/$relnam.all.txt
		tail -n1 $OUT_DIR/$relnam/$relnam.ss8_simp.txt >> $OUT_DIR/$relnam/$relnam.all.txt
		tail -n1 $OUT_DIR/$relnam/$relnam.acc_simp.txt >> $OUT_DIR/$relnam/$relnam.all.txt
		tail -n1 $OUT_DIR/$relnam/$relnam.diso_simp.txt >> $OUT_DIR/$relnam/$relnam.all.txt
		printf "\n\n" >> $OUT_DIR/$relnam/$relnam.all.txt
		printf "\n\n#---------------- details of SS3 prediction ---------------------------\n" > $OUT_DIR/$relnam/$relnam.all.ss3
		printf "\n\n#---------------- details of SS8 prediction ---------------------------\n" > $OUT_DIR/$relnam/$relnam.all.ss8
		printf "\n\n#---------------- details of ACC prediction ---------------------------\n" > $OUT_DIR/$relnam/$relnam.all.acc
		printf "\n\n#---------------- details of DISO prediction --------------------------\n" > $OUT_DIR/$relnam/$relnam.all.diso
		cat $OUT_DIR/$relnam/$relnam.all.txt $OUT_DIR/$relnam/$relnam.all.ss3 $OUT_DIR/$relnam/$relnam.ss3.txt $OUT_DIR/$relnam/$relnam.all.ss8 $OUT_DIR/$relnam/$relnam.ss8.txt $OUT_DIR/$relnam/$relnam.all.acc $OUT_DIR/$relnam/$relnam.acc.txt $OUT_DIR/$relnam/$relnam.all.diso $OUT_DIR/$relnam/$relnam.diso.txt > $OUT_DIR/$relnam/$relnam.all.txt_
		mv $OUT_DIR/$relnam/$relnam.all.txt_ $OUT_DIR/$relnam/$relnam.all.txt
		rm -f $OUT_DIR/$relnam/$relnam.all.ss3 $OUT_DIR/$relnam/$relnam.all.ss8 $OUT_DIR/$relnam/$relnam.all.acc $OUT_DIR/$relnam/$relnam.all.diso

	else                      #-> not use profile

		cp util/0README_noprof $OUT_DIR/$relnam/0README.txt
		cp $tmp/$relnam.fasta_raw $OUT_DIR/$relnam/$relnam.fasta.txt
		cp $tmp/$relnam.seq $OUT_DIR/$relnam/$relnam.seq.txt
		awk '{if(NF>0){print $0}}' $tmp/$relnam.ss3_ > $OUT_DIR/$relnam/$relnam.ss3_noprof.txt
		awk '{if(NF>0){print $0}}' $tmp/$relnam.ss8_ > $OUT_DIR/$relnam/$relnam.ss8_noprof.txt
		awk '{if(NF>0){print $0}}' $tmp/$relnam.acc_ > $OUT_DIR/$relnam/$relnam.acc_noprof.txt
		awk '{if(NF>0){print $0}}' $tmp/$relnam.diso_ > $OUT_DIR/$relnam/$relnam.diso_noprof.txt
		# make simple prediction
		#-> SS3
		echo ">$relnam" > $OUT_DIR/$relnam/$relnam.ss3_noprof_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.ss3_noprof.txt | awk '{printf $2}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.ss3_noprof_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.ss3_noprof.txt | awk '{printf $3}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.ss3_noprof_simp.txt
		#-> SS8
		echo ">$relnam" > $OUT_DIR/$relnam/$relnam.ss8_noprof_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.ss8_noprof.txt | awk '{printf $2}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.ss8_noprof_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.ss8_noprof.txt | awk '{printf $3}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.ss8_noprof_simp.txt
		#-> ACC
		echo ">$relnam" > $OUT_DIR/$relnam/$relnam.acc_noprof_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.acc_noprof.txt | awk '{printf $2}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.acc_noprof_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.acc_noprof.txt | awk '{printf $3}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.acc_noprof_simp.txt
		#-> DISO
		echo ">$relnam" > $OUT_DIR/$relnam/$relnam.diso_noprof_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.diso_noprof.txt | awk '{printf $2}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.diso_noprof_simp.txt
		grep -v "#" $OUT_DIR/$relnam/$relnam.diso_noprof.txt | awk '{printf $3}END{printf "\n"}' >> $OUT_DIR/$relnam/$relnam.diso_noprof_simp.txt
		# make overall prediction
		head -n1 $OUT_DIR/$relnam/$relnam.fasta.txt > $OUT_DIR/$relnam/$relnam.all.txt
		tail -n1 $OUT_DIR/$relnam/$relnam.seq.txt >> $OUT_DIR/$relnam/$relnam.all.txt
		tail -n1 $OUT_DIR/$relnam/$relnam.ss3_noprof_simp.txt >> $OUT_DIR/$relnam/$relnam.all.txt
		tail -n1 $OUT_DIR/$relnam/$relnam.ss8_noprof_simp.txt >> $OUT_DIR/$relnam/$relnam.all.txt
		tail -n1 $OUT_DIR/$relnam/$relnam.acc_noprof_simp.txt >> $OUT_DIR/$relnam/$relnam.all.txt
		tail -n1 $OUT_DIR/$relnam/$relnam.diso_noprof_simp.txt >> $OUT_DIR/$relnam/$relnam.all.txt
		printf "\n\n" >> $OUT_DIR/$relnam/$relnam.all.txt
		printf "\n\n#---------------- details of SS3 prediction ---------------------------\n" > $OUT_DIR/$relnam/$relnam.all.ss3
		printf "\n\n#---------------- details of SS8 prediction ---------------------------\n" > $OUT_DIR/$relnam/$relnam.all.ss8
		printf "\n\n#---------------- details of ACC prediction ---------------------------\n" > $OUT_DIR/$relnam/$relnam.all.acc
		printf "\n\n#---------------- details of DISO prediction --------------------------\n" > $OUT_DIR/$relnam/$relnam.all.diso
		cat $OUT_DIR/$relnam/$relnam.all.txt $OUT_DIR/$relnam/$relnam.all.ss3 $OUT_DIR/$relnam/$relnam.ss3_noprof.txt $OUT_DIR/$relnam/$relnam.all.ss8 $OUT_DIR/$relnam/$relnam.ss8_noprof.txt $OUT_DIR/$relnam/$relnam.all.acc $OUT_DIR/$relnam/$relnam.acc_noprof.txt $OUT_DIR/$relnam/$relnam.all.diso $OUT_DIR/$relnam/$relnam.diso_noprof.txt > $OUT_DIR/$relnam/$relnam.all.txt_
		mv $OUT_DIR/$relnam/$relnam.all.txt_ $OUT_DIR/$relnam/$relnam.all.txt
		mv $OUT_DIR/$relnam/$relnam.all.txt $OUT_DIR/$relnam/$relnam.all_noprof.txt
		rm -f $OUT_DIR/$relnam/$relnam.all.ss3 $OUT_DIR/$relnam/$relnam.all.ss8 $OUT_DIR/$relnam/$relnam.all.acc $OUT_DIR/$relnam/$relnam.all.diso

	fi
	# --------- make a zip file ---- #
	cd $OUT_DIR/
		#-> for Windows
		cd $relnam/
		rm -rf Windows
		mkdir -p Windows
		ls *.txt | awk -F".txt" '{print $1}' > txt_list
		for i in `cat txt_list`
		do
			cp $i.txt Windows/$i.rtf
		done
		rm -f txt_list
		mv Windows/0README.rtf ./
		cd ../
		#-> zip the whole directory
		zip -r $relnam.property.zip $relnam
		mv $relnam.property.zip $relnam
	cd ../
	# --------- rename not use profile mode ----- #
	if [ $PROF_or_NOT -ne 1 ]
	then
		mv $OUT_DIR/$relnam/0README.txt $OUT_DIR/$relnam/0README_noprof
		mv $OUT_DIR/$relnam/$relnam.fasta.txt $OUT_DIR/$relnam/$relnam.fasta
		mv $OUT_DIR/$relnam/$relnam.seq.txt $OUT_DIR/$relnam/$relnam.seq
		#-> raw prediction result
		mv $OUT_DIR/$relnam/$relnam.ss8_noprof.txt $OUT_DIR/$relnam/$relnam.ss8
		mv $OUT_DIR/$relnam/$relnam.ss3_noprof.txt $OUT_DIR/$relnam/$relnam.ss3
		mv $OUT_DIR/$relnam/$relnam.acc_noprof.txt $OUT_DIR/$relnam/$relnam.acc
		mv $OUT_DIR/$relnam/$relnam.diso_noprof.txt $OUT_DIR/$relnam/$relnam.diso
		#-> simp prediction result
		mv $OUT_DIR/$relnam/$relnam.ss8_noprof_simp.txt $OUT_DIR/$relnam/$relnam.ss8_simp
		mv $OUT_DIR/$relnam/$relnam.ss3_noprof_simp.txt $OUT_DIR/$relnam/$relnam.ss3_simp
		mv $OUT_DIR/$relnam/$relnam.acc_noprof_simp.txt $OUT_DIR/$relnam/$relnam.acc_simp
		mv $OUT_DIR/$relnam/$relnam.diso_noprof_simp.txt $OUT_DIR/$relnam/$relnam.diso_simp
		#-> overall prediction result
		mv $OUT_DIR/$relnam/$relnam.all_noprof.txt $OUT_DIR/$relnam/$relnam.all
	else
		mv $OUT_DIR/$relnam/0README.txt $OUT_DIR/$relnam/0README
		mv $OUT_DIR/$relnam/$relnam.fasta.txt $OUT_DIR/$relnam/$relnam.fasta
		mv $OUT_DIR/$relnam/$relnam.seq.txt $OUT_DIR/$relnam/$relnam.seq
		#-> raw prediction result
		mv $OUT_DIR/$relnam/$relnam.ss8.txt $OUT_DIR/$relnam/$relnam.ss8
		mv $OUT_DIR/$relnam/$relnam.ss3.txt $OUT_DIR/$relnam/$relnam.ss3
		mv $OUT_DIR/$relnam/$relnam.acc.txt $OUT_DIR/$relnam/$relnam.acc
		mv $OUT_DIR/$relnam/$relnam.diso.txt $OUT_DIR/$relnam/$relnam.diso
		#-> simp prediction result
		mv $OUT_DIR/$relnam/$relnam.ss8_simp.txt $OUT_DIR/$relnam/$relnam.ss8_simp
		mv $OUT_DIR/$relnam/$relnam.ss3_simp.txt $OUT_DIR/$relnam/$relnam.ss3_simp
		mv $OUT_DIR/$relnam/$relnam.acc_simp.txt $OUT_DIR/$relnam/$relnam.acc_simp
		mv $OUT_DIR/$relnam/$relnam.diso_simp.txt $OUT_DIR/$relnam/$relnam.diso_simp
		#-> overall prediction result
		mv $OUT_DIR/$relnam/$relnam.all.txt $OUT_DIR/$relnam/$relnam.all
		#-> move tgt files
		cp $tmp/$relnam.tgt $OUT_DIR/$relnam/$relnam.tgt
		cp $tmp/update/$relnam.tgt $OUT_DIR/$relnam/$relnam.tgt2
	fi
	# -------- prediction summary -------- #
	$util/generate_simp_summary_file $OUT_DIR/$relnam/$relnam.diso $OUT_DIR/$relnam/$relnam.ss3 $OUT_DIR/$relnam/$relnam.acc 0.5 $OUT_DIR/$relnam/$relnam.summary
	

	# ------ remove temporary folder ----- #
	rm -rf $tmp/
	rm -f $relnam.fasta
cd $CurRoot

