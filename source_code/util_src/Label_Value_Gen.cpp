#include <string>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <cmath>
#include <map>
#include <iomanip>
#include <algorithm>
#include <getopt.h>
using namespace std;


//======================= I/O related ==========================//
//-------- utility ------//
void getBaseName(string &in,string &out,char slash,char dot)
{
	int i,j;
	int len=(int)in.length();
	for(i=len-1;i>=0;i--)
	{
		if(in[i]==slash)break;
	}
	i++;
	for(j=len-1;j>=0;j--)
	{
		if(in[j]==dot)break;
	}
	if(j==-1)j=len;
	out=in.substr(i,j-i);
}
void getRootName(string &in,string &out,char slash)
{
	int i;
	int len=(int)in.length();
	for(i=len-1;i>=0;i--)
	{
		if(in[i]==slash)break;
	}
	if(i<=0)out=".";
	else out=in.substr(0,i);
}

//================ load label_file ==================//
//example
/*
>A0A183
0000000000000000000001111111111111000000000000000000

[note]:
in this example, we use '0' to indicate order state and '1' for disorder state
*/

//----- load label file -----//
int Load_Label_File(string &input_file, int skip_lines,
	vector <int> &diso_label, char posi_char, char nega_char)
{
	//start
	ifstream fin;
	string buf,temp;
	//read
	fin.open(input_file.c_str(), ios::in);
	if(fin.fail()!=0)
	{
		fprintf(stderr,"input_file %s not found!\n",input_file.c_str());
		exit(-1);
	}
	//skip header
	for(int i=0;i<skip_lines;i++)
	{
		if(!getline(fin,buf,'\n'))
		{
			fprintf(stderr,"input_file %s format bad!\n",input_file.c_str());
			exit(-1);
		}
	}
	//read label string
	if(!getline(fin,buf,'\n'))
	{
		fprintf(stderr,"input_file %s format bad!\n",input_file.c_str());
		exit(-1);
	}
	diso_label.resize(buf.length());
	for(int i=0;i<(int)buf.length();i++)
	{
		char cur=buf[i];
		if(cur==posi_char)diso_label[i]=1;
		else if(cur==nega_char)diso_label[i]=0;
		else diso_label[i]=-1;
	}
	//return size
	return (int)buf.length();
}

//================= load pred_file =================//

//------ load AUCpreD result --------//
//example of AUCpreD
/*
#AUCpreD: order/disorder state prediction results
#Disorder residues are marked with asterisks (*) above threshold 0.200
# Ordered residues are marked with dots (.) below threshold 0.200
   1 M * 0.988
   2 S * 0.977
   3 Q * 0.970
   4 Q * 0.964
   5 K * 0.959
   6 Q * 0.951
   7 Q * 0.939
   8 S * 0.921
...
*/
int Load_Diso_File_AUCpreD(string &diso_file,string &seqres, vector <double> &prob_out)
{
	//start
	ifstream fin;
	string buf,temp;
	//read
	fin.open(diso_file.c_str(), ios::in);
	if(fin.fail()!=0)
	{
		fprintf(stderr,"diso_file %s not found!\n",diso_file.c_str());
		exit(-1);
	}
	//init
	int count=0;
	prob_out.clear();
	seqres="";
	//skip
	for(;;)
	{
		if(!getline(fin,buf,'\n'))
		{
			fprintf(stderr,"file %s format bad!\n",diso_file.c_str());
			exit(-1);
		}
		if(buf=="")continue;
		if(buf[0]=='#')continue;
		else goto start;
	}
	//load
	for(;;)
	{
		if(!getline(fin,buf,'\n'))break;
start:
		istringstream www(buf);
		string amino;
		www>>temp>>amino>>temp;
		double tmp_prob;
		www>>tmp_prob;
		prob_out.push_back(tmp_prob);
		seqres+=amino[0];
		count++;
	}
	//return
	return count;
}

//------ load vsl2 result --------//
//example of vsl2 result
/*
VSL2 Predictor of Intrinsically Disordered Regions
Center for Information Science and Technology
Temple University, Philadelphia, PA

Predicted Disordered Regions:
1-17
128-133
164-172

Prediction Scores:
========================================
NO.     RES.    PREDICTION      DISORDER
----------------------------------------
1       M       0.886592        D
2       G       0.872914        D
3       S       0.859414        D
...
*/
int Load_Diso_File_vsl2(string &diso_file,string &seqres, vector <double> &prob_out)
{
	//start
	ifstream fin;
	string buf,temp;
	//read
	fin.open(diso_file.c_str(), ios::in);
	if(fin.fail()!=0)
	{
		fprintf(stderr,"diso_file %s not found!\n",diso_file.c_str());
		exit(-1);
	}
	//init
	int count=0;
	prob_out.clear();
	seqres="";
	//skip
	for(;;)
	{
		if(!getline(fin,buf,'\n'))
		{
			fprintf(stderr,"file %s format bad!\n",diso_file.c_str());
			exit(-1);
		}
		if(buf=="")break;
		int len=(buf).length();
		if(len<40)continue;
		temp=buf.substr(0,40);
		if(temp=="NO.     RES.    PREDICTION      DISORDER")
		{
			if(!getline(fin,buf,'\n'))
			{
				fprintf(stderr,"file %s format bad!\n",diso_file.c_str());
				exit(-1);
			}
			break;
		}
	}
	//load
	for(;;)
	{
		if(!getline(fin,buf,'\n'))
		{
			fprintf(stderr,"file %s format bad!\n",diso_file.c_str());
			exit(-1);
		}
		if(buf=="========================================")break;
		istringstream www(buf);
		string amino;
		www>>temp>>amino;
		double tmp_prob;
		www>>tmp_prob;
		prob_out.push_back(tmp_prob);
		seqres+=amino[0];
		count++;
	}
	//return
	return count;
}

//------ load IUpred result --------//
//example of IUpred
/*
# IUPred
# Copyright (c) Zsuzsanna Dosztanyi, 2005
#
# Z. Dosztanyi, V. Csizmok, P. Tompa and I. Simon
# J. Mol. Biol. (2005) 347, 827-839.
#
#
# Prediction output
# T0589
    1 S     0.4051
    2 N     0.4330
    3 A     0.4685
    4 M     0.5382
...
*/
int Load_Diso_File_IUpred(string &diso_file,string &seqres, vector <double> &prob_out)
{
	//start
	ifstream fin;
	string buf,temp;
	//read
	fin.open(diso_file.c_str(), ios::in);
	if(fin.fail()!=0)
	{
		fprintf(stderr,"diso_file %s not found!\n",diso_file.c_str());
		exit(-1);
	}
	//init
	int count=0;
	prob_out.clear();
	seqres="";
	//skip
	for(;;)
	{
		if(!getline(fin,buf,'\n'))
		{
			fprintf(stderr,"file %s format bad!\n",diso_file.c_str());
			exit(-1);
		}
		if(buf=="")continue;
		if(buf[0]=='#')continue;
		else goto start;
	}
	//load
	for(;;)
	{
		if(!getline(fin,buf,'\n'))break;
start:
		istringstream www(buf);
		string amino;
		www>>temp>>amino;
		double tmp_prob;
		www>>tmp_prob;
		prob_out.push_back(tmp_prob);
		seqres+=amino[0];
		count++;
	}
	//return
	return count;
}

//------ load Espritz result --------//
//example of Espritz
/*
******************************************************************************************************

Licensed to: Dr Sheng Wang (Academic, TTIC) located in Chicago, United States.
This license is for non-commercial use only. Please see LICENSE file for details (http://protein.bio.unipd.it/LICENSE).
Contact silvio.tosatto@unipd.it for commercial licensing details.


******************************************************************************************************
D       0.236318
D       0.239508
D       0.234664
D       0.163835
D       0.119222
...
*/
int Load_Diso_File_Espritz(string &diso_file,string &seqres, vector <double> &prob_out)
{
	//start
	ifstream fin;
	string buf,temp;
	//read
	fin.open(diso_file.c_str(), ios::in);
	if(fin.fail()!=0)
	{
		fprintf(stderr,"diso_file %s not found!\n",diso_file.c_str());
		exit(-1);
	}
	//init
	int count=0;
	prob_out.clear();
	seqres="";
	//skip
	for(int i=0;i<8;i++)
	{
		if(!getline(fin,buf,'\n'))
		{
			fprintf(stderr,"file %s format bad!\n",diso_file.c_str());
			exit(-1);
		}
	}
	//load
	for(;;)
	{
		if(!getline(fin,buf,'\n'))break;
		istringstream www(buf);
		double tmp_prob;
		www>>temp>>tmp_prob;
		prob_out.push_back(tmp_prob);
		count++;
	}
	//return
	return count;
}

//============== process consecutive posi/nega labels =====//
void Process_Consecutive_Labels(vector <int> &diso_label,int label_type,int label_min)
{
	int i,k;
	int size=(int)diso_label.size();
	int start,len;
	int first=1;
	for(i=0;i<size;i++)
	{
		if(diso_label[i]==label_type)
		{
			if(first==1)
			{
				first=0;
				start=i;
				len=1;
			}
			else
			{
				len++;
			}
		}
		else
		{
			if(first==0)
			{
				first=1;
				if(len<label_min) //remove these labels
				{
					for(k=0;k<len;k++)diso_label[start+k]=-1;
				}
			}
		}
	}
	//terminal
	if(first==0)
	{
		first=1;
		if(len<label_min) //remove these labels
		{
			for(k=0;k<len;k++)diso_label[start+k]=-1;
		}
	}
} 


//============== output <label value> format ==============//
//example
/*
#-> 365 <raget_name>
 1 0.742146
 0 0.905539
...
*/
void Output_Canonical_Format(string &targ_name,string &out_file,
	vector <int> &diso_label,vector <double> &prob_out)
{
	if(out_file!="")
	{
		FILE *fp=fopen(out_file.c_str(),"wb");
		int len=(int)diso_label.size();
		fprintf(fp,"#-> %d %s\n",len,targ_name.c_str());
		for(int i=0;i<len;i++)
		{
			if(diso_label[i]==0 || diso_label[i]==1)
			{
				fprintf(fp," %d %lf \n",diso_label[i],prob_out[i]);
			}
			else
			{
				fprintf(fp,"# %d %lf \n",diso_label[i],prob_out[i]);
			}
		}
		fclose(fp);
	}
	else
	{
		int len=(int)diso_label.size();
		printf("#-> %d %s\n",len,targ_name.c_str());
		for(int i=0;i<len;i++)
		{
			if(diso_label[i]==0 || diso_label[i]==1)
			{
				printf(" %d %lf \n",diso_label[i],prob_out[i]);
			}
			else
			{
				printf("# %d %lf \n",diso_label[i],prob_out[i]);
			}
		}
	}
}

//========== main process =========//
void Main_Process(string &label_file,string &pred_file,string &out_file,
	char posi_char,char nega_char,int posi_min,int nega_min,int file_type,int skip_lines)
{
	//load label_file
	vector <int> label_record;
	int label_size=Load_Label_File(label_file,skip_lines,label_record,posi_char,nega_char);
	//load pred_file
	string pred_seqres;
	vector <double> prob_out;
	int pred_size;
	if(file_type==0 || file_type==1)pred_size=Load_Diso_File_AUCpreD(pred_file,pred_seqres,prob_out);
	else if(file_type==2) pred_size=Load_Diso_File_IUpred(pred_file,pred_seqres,prob_out);
	else if(file_type==3) pred_size=Load_Diso_File_Espritz(pred_file,pred_seqres,prob_out);
	else if(file_type==4) pred_size=Load_Diso_File_vsl2(pred_file,pred_seqres,prob_out);
	else
	{
		fprintf(stderr,"ERROR: invalide file_type %d \n",file_type);
		exit(-1);
	}
	//check
	if(label_size!=pred_size)
	{
		fprintf(stderr,"ERROR: label_size %d not equal to pred_size %d \n",label_size,pred_size);
		exit(-1);
	}
	//remove un-consecutive labels
	Process_Consecutive_Labels(label_record,1,posi_min);
	Process_Consecutive_Labels(label_record,0,nega_min);
	//output
	string targ_name;
	getBaseName(label_file,targ_name,'/','.');
	Output_Canonical_Format(targ_name,out_file,label_record,prob_out);
}



//---- readme ----//
void Usage(char *arg)
{
	fprintf(stderr,"Label_Value_Gen V1.01 [Sep-30-2015] \n");
	fprintf(stderr,"    Generate <label value> file from real label file and predicted result file \n\n");
	fprintf(stderr,"USAGE: ./Label_Value_Gen -i label_file -I pred_file [-o output_file] \n");
	fprintf(stderr,"           [-p posi_char] [-n nega_char] [-P posi_min] [-N nega_min] \n");
	fprintf(stderr,"           [-f file_type] [-s skip_lines] \n\n");
	fprintf(stderr,"Options:\n\n");
	fprintf(stderr,"***** required arguments *****\n");
	fprintf(stderr,"-i label_file  :  input label file in FASTA format \n");
	fprintf(stderr,"-I pred_file   :  input predicted result file from a specific method \n\n");
	fprintf(stderr,"***** optional arguments *****\n");
	fprintf(stderr,"-o output_file :  default would be screen out, if output_file is not specified \n");
	fprintf(stderr,"-p posi_char   :  positive label in label_file [default = '1']\n");
	fprintf(stderr,"-n nega_char   :  negative label in label_file [default = '0']\n");
	fprintf(stderr,"-P posi_min    :  minimal consecutive positive labels [default = 1]\n");
	fprintf(stderr,"-N nega_min    :  minimal consecutive negative labels [default = 1]\n");
	fprintf(stderr,"-f file_type   :  file type of pred_file [default 0 for AUCpreD]\n");
	fprintf(stderr,"                  1 for DisoPred3, 2 for IUpred, 3 for Espritz, 4 for VSL2 \n");
	fprintf(stderr,"-s skip_lines  :  skip X lines in label_file [default = 1] \n\n");
}

//------------ main -------------//
int main(int argc, char** argv)
{
	//------- Label_Value_Gen -----//
	{
		if(argc<2)
		{
			Usage(argv[0]);
			exit(-1);
		}
		string label_file="";
		string pred_file="";
		string output_file="";
		char posi_char='1';
		char nega_char='0';
		int posi_min=1;
		int nega_min=1;
		int file_type=0;
		int skip_lines=1;

		//---- read arguments ----//
		extern char* optarg;
		char c = 0;
		while ((c = getopt(argc, argv, "i:I:o:p:n:P:N:f:s:")) != EOF)
		{
			switch (c)
			{
				case 'i':
					label_file = optarg;
					break;
				case 'I':
					pred_file = optarg;
					break;
				case 'o':
					output_file = optarg;
					break;
				case 'p':
					posi_char = optarg[0];
					break;
				case 'n':
					nega_char = optarg[0];
					break;
				case 'P':
					posi_min = atoi(optarg);
					break;
				case 'N':
					nega_min = atoi(optarg);
					break;
				case 'f':
					file_type = atoi(optarg);
					break;
				case 's':
					skip_lines = atoi(optarg);
					break;
				default:
					Usage(argv[0]);
					exit(-1);
			}
		}
		//---- check required arguments -----//
		if(label_file=="" || pred_file=="")
		{
			Usage(argv[0]);
			exit(-1);
		}
		//process
		Main_Process(label_file,pred_file,output_file,
			posi_char,nega_char,posi_min,nega_min,
			file_type,skip_lines);
		//exit
		exit(0);
	}
}
