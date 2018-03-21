

# make the subdir first
SHELL :=/bin/bash
CXX = g++
FLAG = -O3

Util_Dir = ./util_src/
DeepCNF_SS_Con_Dir = ./DeepCNF_SS_Con_src/
DeepCNF_SAS_Con_Dir = ./DeepCNF_SAS_Con_src/
AcconPred_Dir = ./AcconPred_src/
Diso_Feature_Make_Dir = ./Diso_Feature_Make_src/
Memb_Feature_Make_Dir = ./MemProt_Feat_src/
DeepCNF_Pred_Dir = ./DeepCNF_Pred_src/


all: tgt util sse acc feat pred


tgt:
	# --- A3M_To_TGT ---- #
	cd MSA_To_PSSM_cdhit_src&&make
	mv MSA_To_PSSM_cdhit_src/MSA_To_PSSM ../util
	$(CXX) A3M_To_TGT.cpp $(FLAG) -o A3M_To_TGT
	$(CXX) TGT_Update_acc_ss8_new.cpp $(FLAG) -o TGT_Update
	mv A3M_To_TGT TGT_Update ../

util:
	# ---- util ---- #
	cd $(Util_Dir)&&make
	#-> for A3M_To_TGT
	mv Verify_FASTA A3M_To_PSI SS8_To_SS3 ACC_ReFormat ../util
	#-> for TGT_Update
	mv TPL_TGT_Get_PSM TPL_TGT_Get_PSP TPL_TGT_Get_HMM TPL_Get_SS2 TGT_Get_SS2 TPL_Get_SEQ TGT_Get_SEQ ../util
	#-> for RaptorX_Property server
	mv Calc_AUC Calc_TP_FP DisoPred_Trans Label_Value_Gen Label_Parser ../bin
	$(CXX) generate_simp_summary_file.cpp $(FLAG) -o generate_simp_summary_file
	mv generate_simp_summary_file ../bin

sse:
	# ---- DeepCNF_SS_Con ---- #
	cd $(DeepCNF_SS_Con_Dir)&&make
	mv DeepCNF_SS_Con ../bin

acc:
	# ---- AcconPred ----- #
	cd $(AcconPred_Dir)&&make
	mv AcconPred ../bin
	cd $(DeepCNF_SAS_Con_Dir)&&make
	mv DeepCNF_SAS_Con ../bin

feat:
	# ---- Diso_Feature_Make --- #
	cd $(Diso_Feature_Make_Dir)&&make
	mv Diso_Feature_Make Diso_Feature_Make_noprof ../bin
	cd $(Memb_Feature_Make_Dir)&&make
	mv MemProt_Feat MemProt_Feat_noprof ../bin

pred:
	# ---- DeepCNF_Pred ---- #
	cd $(DeepCNF_Pred_Dir)&&make
	mv DeepCNF_Pred ../bin


# clean all the temp files
clean:

