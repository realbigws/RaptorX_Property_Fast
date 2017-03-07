

# make the subdir first
CXX = g++
#FLAG = -O3 -static
FLAG = -O3
SHELL :=/bin/bash

all:

	# ------ A3M to TGT -------#
	$(CXX) Verify_FASTA.cpp $(FLAG) -o Verify_FASTA
	$(CXX) A3M_To_PSI.cpp $(FLAG) -o A3M_To_PSI
	$(CXX) SS8_To_SS3.cpp $(FLAG) -o SS8_To_SS3
	$(CXX) ACC_ReFormat.cpp $(FLAG) -o ACC_ReFormat
	# move to ../ directory
	mv Verify_FASTA A3M_To_PSI SS8_To_SS3 ACC_ReFormat ../

	# ---- for TGT_Upgrede ----- #
	$(CXX) TPL_TGT_Get_PSM.cpp $(FLAG) -o TPL_TGT_Get_PSM
	$(CXX) TPL_TGT_Get_PSP.cpp $(FLAG) -o TPL_TGT_Get_PSP	
	$(CXX) TPL_TGT_Get_HMM.cpp $(FLAG) -o TPL_TGT_Get_HMM
	$(CXX) TPL_Get_SS2.cpp $(FLAG) -o TPL_Get_SS2
	$(CXX) TGT_Get_SS2.cpp $(FLAG) -o TGT_Get_SS2
	$(CXX) TPL_Get_SEQ.cpp $(FLAG) -o TPL_Get_SEQ
	$(CXX) TGT_Get_SEQ.cpp $(FLAG) -o TGT_Get_SEQ
	# move to ../ directory
	mv TPL_TGT_Get_PSM TPL_TGT_Get_PSP TPL_TGT_Get_HMM TPL_Get_SS2 TGT_Get_SS2 TPL_Get_SEQ TGT_Get_SEQ ../

	# ------ for RaptorX_Property -------#
	# DisoPred_Trans
	$(CXX) DisoPred_Trans.cpp $(FLAG) -o DisoPred_Trans
	# SS3/SS8/ACC Trans
	$(CXX) Label_Parser.cpp $(FLAG) -o Label_Parser
	# Label_Value_Gen
	$(CXX) Label_Value_Gen.cpp $(FLAG) -o Label_Value_Gen
	# Calc_AUC and Calc_TP_FP
	$(CXX) Calc_AUC.cpp $(FLAG) -o Calc_AUC
	$(CXX) Calc_TP_FP.cpp $(FLAG) -o Calc_TP_FP
	# move to ../ directory
	mv DisoPred_Trans Label_Parser Label_Value_Gen Calc_AUC Calc_TP_FP ../

# clean all the temp files
clean:
