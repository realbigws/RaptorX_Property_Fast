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
#include "Fast_Sort.h"
using namespace std;

// typedef
typedef long long int U_INT;  //-> for vector size


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

//========== load data ==========//
//example
/*
#-> 80 A0A183
 1 0.988000
 1 0.977000
 1 0.970000
 1 0.964000
...
*/
U_INT Load_Data(string &input_file,vector <double> &value,vector <int> &label)
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
	//load
	U_INT count=0;
	value.clear();
	label.clear();
	for(;;)
	{
		if(!getline(fin,buf,'\n'))break;
		if(buf=="")continue;
		if(buf[0]=='#')continue;
		istringstream www(buf);
		int lab;
		double val;
		www>>lab>>val;
		value.push_back(val);
		label.push_back(lab);
		count++;
	}
	return count;
}

//========== calculate AUC ==================//
/*
use Wilcoxon-Mann-Whitney statistic.

The meaning and use of the area under a receiver operating characteristic (ROC) curve.
by Hanley JA, McNeil BJ. 
Radiology 1982; 143: 29-36.
*/

//--- label should be 0 or 1
double Calc_AUC_Value(double *value,int *label,U_INT *index,U_INT totnum)
{
	//Fast_Sort
	Fast_Sort <double> fast_sort_d;
	fast_sort_d.fast_sort_1(value,index,totnum);
	//get zero number
	U_INT zero_num=0;
	for(U_INT i=0;i<totnum;i++)
	{
		if(label[i]==0)zero_num++;
	}
	U_INT one_num=totnum-zero_num;
	//calculate
	double passed_zero=0;
	double auc_totnum=0;
	for(U_INT i=0;i<totnum;i++)
	{
		U_INT idx=index[i];
		if(label[idx]==1)
		{
			auc_totnum+=(zero_num-passed_zero);
		}
		else
		{
			passed_zero++;
		}
	}
	//final value
	return 1.0*auc_totnum/zero_num/one_num;
}

//========= main process =========//
void Main_Process(string &reso_file)
{
	//load data
	vector <double> value_;
	vector <int> label_;
	U_INT total_num=Load_Data(reso_file,value_,label_);
	//init data
	double *value=new double[total_num];
	int *label=new int[total_num];
	U_INT *index=new U_INT[total_num];
	//copy datra
	for(int i=0;i<total_num;i++)
	{
		value[i]=value_[i];
		label[i]=label_[i];
	}
	//calculate auc
	double auc_value=Calc_AUC_Value(value,label,index,total_num);
	string name;
	getBaseName(reso_file,name,'/','.');
	printf("%s -> AUC %lf \n",name.c_str(),auc_value);
	//delete
	delete [] value;
	delete [] label;
	delete [] index;
}

//------------ main -------------//
int main(int argc, char** argv)
{
	//------- Calc_AUC -----//
	{
		if(argc<2)
		{
			fprintf(stderr,"Version 1.01 \n");
			fprintf(stderr,"Calc_AUC <label_value_file> \n");
			fprintf(stderr,"[note]: <label_value_file> should be <label, value> \n");
			fprintf(stderr,"        <label> should be 0 or 1, with 1 be true label \n");
			fprintf(stderr,"        <value> between 0 to 1, more higher more true label \n");
			fprintf(stderr,"        for example: 1 0.977000 \n");
			exit(-1);
		}
		string input_file=argv[1];
		//process
		Main_Process(input_file);
		//exit
		exit(0);
	}
}

