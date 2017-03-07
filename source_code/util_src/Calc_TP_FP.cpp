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
#include <time.h>
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

//=================== upper and lower case ====================//
//----------upper_case-----------//
void toUpperCase(char *buffer) 
{  
	for(int i=0;i<(int)strlen(buffer);i++) 
	if(buffer[i]>=97 && buffer[i]<=122) buffer[i]-=32;
}
void toUpperCase(string &buffer)
{
	for(int i=0;i<(int)buffer.length();i++) 
	if(buffer[i]>=97 && buffer[i]<=122) buffer[i]-=32;
}
//----------lower_case-----------//
void toLowerCase(char *buffer)
{  
	for(int i=0;i<(int)strlen(buffer);i++) 
	if(buffer[i]>=65 && buffer[i]<=90) buffer[i]+=32;
}
void toLowerCase(string &buffer)
{
	for(int i=0;i<(int)buffer.length();i++) 
	if(buffer[i]>=65 && buffer[i]<=90) buffer[i]+=32;
}


//========== calculate TP/FP related measurements ==========//
//-> input examle
/*
 1 0.842039
 1 0.775209
 1 0.755237
 1 0.661877
 1 0.515135
 1 0.394574
 1 0.357573
 1 0.277307
 1 0.222007
 1 0.168835
 1 0.149776
 1 0.136482
 1 0.129423
 1 0.115352
 1 0.115104
 1 0.121574
 1 0.143086
 1 0.161823
 1 0.184361
 1 0.196237
 1 0.203620
 1 0.212567
 0 0.209723
 0 0.185400
 0 0.181789
 0 0.179994
*/

int Load_Data(string &in_file,vector <int> &label, vector <double> &value)
{
	ifstream fin;
	string buf,temp;
	fin.open(in_file.c_str(), ios::in);
	if(fin.fail()!=0)
	{
		fprintf(stderr,"%s not found!\n",in_file.c_str());
		exit(-1);
	}
	//load
	label.clear();
	value.clear();
	int count=0;
	for(;;)
	{
		if(!getline(fin,buf,'\n'))break;
		if(buf=="")continue;
		if(buf[0]=='#')continue;
		istringstream www(buf);
		int lab;
		double val;
		www>>lab>>val;
		label.push_back(lab);
		value.push_back(val);
		count++;
	}
	return count;
}

//-------- calculate TP/FP -----------//
void Calculate_TP_FP_Value(vector <int> &label, vector <double> &value, double thres,
	int &TP, int &FP, int &TN, int &FN)
{
	int i;
	int size=(int)label.size();
	TP=0;
	FP=0;
	TN=0;
	FN=0;
	for(i=0;i<size;i++)
	{
		int pred;
		if(value[i]<thres)pred=0;
		else pred=1;
		if(pred==label[i])
		{
			if(pred==1)TP++;
			else TN++;
		}
		else
		{
			if(pred==1)FP++;
			else FN++;
		}
	}
}

//=========== calculate TP/FP related measurement ==========//
//---- predictive -----//
//-> precision (or, positive predictive value, PPV)
double Precision(int TP, int FP, int TN, int FN)
{
	if(TP==0)return 0;
	return 1.0*TP/(TP+FP);
}
//-> negative_predictive_value ( NPV)
double negative_predictive_value(int TP, int FP, int TN, int FN)
{
	if(TN==0)return 0;
	return 1.0*TN/(TN+FN);
}

//----- data -----//
//-> recall (or, sensitivity, true positive rate, TPR)
double Recall(int TP, int FP, int TN, int FN)
{
	if(TP==0)return 0;
	return 1.0*TP/(TP+FN);
}
//-> specificity (or, true negative rate, TNR)
double specificity(int TP, int FP, int TN, int FN)
{
	if(TN==0)return 0;
	return 1.0*TN/(TN+FP);
}

//----- accuracy ----//
//-> accuracy
double Accuracy(int TP, int FP, int TN, int FN)
{
	if(TP+TN==0)return 0;
	return 1.0*(TP+TN)/(TP+TN+FP+FN);
}
//-> balanced accurcy
double balanced_accurcy(int TP, int FP, int TN, int FN)
{
	if(TP==0 && TN==0)return 0;
	if(TP==0)return 0.5*TN/(TN+FP);
	if(TN==0)return 0.5*TP/(TP+FN);
	return 0.5*( 1.0*TP/(TP+FN) + 1.0*TN/(TN+FP) );
}
//-> F1 score
double F1_score(int TP, int FP, int TN, int FN)
{
	if(TP==0)return 0;
	return 2.0*TP/(2.0*TP+FP+FN);
}

//------ Matthews correlation coefficient (MCC) ---//
double MCC_Value(int TP, int FP, int TN, int FN)
{
	if(TP*TN==0 && FP*FN==0)return 0;
	return 1.0*( 1.0*TP*TN-1.0*FP*FN )/sqrt( 1.0*(TP+FP)*(TN+FP)*(TP+FN)*(TN+FN) );
}


//----------- main -------------//
int main(int argc,char **argv)
{

	//---- TP_TP_Calc ----//__140714__//
	{
		if(argc<3)
		{
			fprintf(stderr,"Version 1.01 \n");
			fprintf(stderr,"Calc_TP_FP <label_value_file> <threshold> \n");
			fprintf(stderr,"[note]: <label_value_file> should be <label, value> \n");
			fprintf(stderr,"        <label> should be 0 or 1, with 1 be true label \n");
			fprintf(stderr,"        <value> between 0 to 1, more higher more true label \n");
			fprintf(stderr,"        for example:    1   0.923 \n");
			exit(-1);
		}
		//---- read argument ----//
		string label_value_file=argv[1];
		double threshold=atof(argv[2]);
		string name;
		getBaseName(label_value_file,name,'/','.');
		//---- process -----//
		vector <int> label;
		vector <double> value;
		//-> calculate TP/FP
		Load_Data(label_value_file,label,value);
		int TP,FP,TN,FN;
		Calculate_TP_FP_Value(label,value,threshold,TP,FP,TN,FN);
		//-> calculate TP/FP related values
		double Prec=Precision(TP, FP, TN, FN);
		double NPV=negative_predictive_value(TP, FP, TN, FN);
		double Reca=Recall(TP, FP, TN, FN);
		double Spec=specificity(TP, FP, TN, FN);
		double Acc=Accuracy(TP, FP, TN, FN);
		double Bacc=balanced_accurcy(TP, FP, TN, FN);
		double F1=F1_score(TP, FP, TN, FN);
		double MCC=MCC_Value(TP, FP, TN, FN);
		//-> printf
		printf("%s -> TP %d FP %d TN %d FN %d -> Prec %lf NPV %lf Reca %lf Spec %lf Acc %lf Bacc %lf F1 %lf MCC %lf \n",
			name.c_str(),TP,FP,TN,FN,Prec,NPV,Reca,Spec,Acc,Bacc,F1,MCC);
		//exit
		exit(0);		
	}
}
