# 1. Insertion Sort
# 2. Shell Sort
## (1). 简介
- 以其设计者*希尔（Donald Shell)* 命名
- 又称为**缩小增量**排序
### 基本思想
先将整个待排对象序列按照一定间隔分割成为若干子序列，分别进行直接插入排序，然后缩小间隔，对整个对象序列重复以上的划分子序列和分别排序工作，直到最后间隔为1，此时整个对象序列已 “基本有序”，进行最后一次直接插入排序。
## (2). 算法实现
~~~C
	void ShellSort(SqList &L, int dlta[],int t){
		for(int k=0;k<t;++k) ShellInsert(L,dlta[k]);
	}
		说明：dlta[3]={5，3，1}
		//一趟希尔排序,按间隔dk划分子序列
	void ShellInsert(SqList &L, int gap){
		
		for (int i=gap+1;i<=L.length;++i) {
			if (LessThan(L.r[i].key,L.r[i-gap].key)) {
				L.r[0]=L.r[i];
				for (int j=i-gap;j>0                            
				&&LessThan(L.r[0].key,L.r[j].key); j-=gap){
					L.r[j+gap]=L.r[j];
					L.r[j+gap]=L.r[0];
				}
		}
	}
~~~
## (3)
- 步长的选择是希尔排序的重要部分，理论上只要最终步长为1任何步长序列都可以工作。
- 目前已知的最好步长序列由Marcin Ciura设计（1，4，10，23，57，132，301，701，1750，…），用这样步长序列的希尔排序比插入排序和堆排序都要快，甚至在小数组中比快速排序还快；但是在涉及大量数据时希尔排序还是比快速排序慢。