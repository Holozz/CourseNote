***Merge sort*** is a popular sorting algorithm known for its efficiency and stability. It follows the Divide and Conquer approach. It works by recursively dividing the input array into two halves, recursively sorting the two halves and finally merging them back together to obtain the sorted array.
归并排序（merge sort）是利用 **归并** 的思想实现的排序方法，该算法采用经典的 **分治**（divide-and-conquer）**策略**：
- 分（divide）：将问题分成一些小的问题，然后递归求解
- 治（conquer）：将分的阶段得到的各答案「修补」在一起
![[Pasted image 20260114113032.png]]Here's a step-by-step explanation of how merge sort works:
1. **Divide:** Divide the list or array recursively into two halves until it can no more be divided.
2. **Conquer:** Each subarray is sorted individually using the merge sort algorithm.
3. **Merge:** The sorted subarrays are merged back together in sorted order. The process continues until all elements from both subarrays have been merged.
## C++ Implementation

Int类型，**递归**实现
~~~cpp
	#include <iostream>
	#include <vector>
	using namespace std;
	// Merges two subarrays of arr[].
	// First subarray is arr[left..mid]
	// Second subarray is arr[mid+1..right]
	void merge(vector<int>& arr, int left, int mid, int right){
	    int n1 = mid - left + 1;
	    int n2 = right - mid;
	    // Create temp vectors
	    vector<int> L(n1), R(n2);
	    // Copy data to temp vectors L[] and R[]
	    for (int i = 0; i < n1; i++)L[i] = arr[left + i];
	    for (int j = 0; j < n2; j++)R[j] = arr[mid + 1 + j];
	    int i = 0, j = 0;
	    int k = left;
	    // Merge the temp vectors back 
	    // into arr[left..right]
	    while (i < n1 && j < n2) arr[k++]=L[i]<=R[j]?L[i++]:R[j++];
	    // Copy the remaining elements of L[] if there are any
	    while (i < n1) arr[k++] = L[i++];
	    // Copy the remaining elements of R[] if there are any
	    while (j < n2) arr[k++] = R[j++];
	}
	// begin is for left index and end is right index
	// of the sub-array of arr to be sorted
	void mergeSort(vector<int>& arr, int left, int right){
	    if (left >= right)return;
	    int mid = left + (right - left) / 2;
	    mergeSort(arr, left, mid);
	    mergeSort(arr, mid + 1, right);
	    merge(arr, left, mid, right);
	}
	// Driver code
	int main(){
	    vector<int> arr = {38, 27, 43, 10};
	    int n = arr.size();
	    mergeSort(arr, 0, n - 1);
	    for (int i = 0; i < arr.size(); i++)cout << arr[i] << " ";
	    cout << endl;
	    return 0;
	}
~~~

模板类，**迭代**实现
~~~cpp
	template <typename T>
	void mergeSort(T begin, T end){
	    using value_type = typename T::value_type;
	    int len = end - begin;
	    vector<value_type> p(len);
	    
	    for(int seg = 1; seg<len; seg=seg<<1){
	        for(int start=0; start<len; start+=2*seg){
	            int low = start, high = min(start+seg+seg, len);
	            int mid = min(start+seg, len);
	
	            int i=start;
	            int start1 = low, end1 = mid;
	            int start2 = mid, end2 = high;
	            
	            while(start1<end1 && start2<end2) p[i++] = begin[start1]<begin[start2] ? begin[start1++] : begin[start2++];
	            while(start1<end1) p[i++] = begin[start1++];
	            while(start2<end2) p[i++] = begin[start2++];
	        }
	        for(int j=0; j<len; j++) begin[j] = p[j];
	    }
	}
~~~
## Recurrence Relation of Merge Sort

The recurrence relation of merge sort is:  
$$T(n)=\begin{cases}\Theta(1)&\text{if }n=1\\ \\
2T\left(\frac n2\right)+\Theta(n)&\text{if }n>1&\end{cases}$$$$$$

- T(n) Represents the total time time taken by the algorithm to sort an array of size n.
- 2T(n/2) represents time taken by the algorithm to recursively sort the two halves of the array. Since each half has n/2 elements, we have two recursive calls with input size as (n/2).
- O(n) represents the time taken to merge the two sorted halves

## Complexity Analysis of Merge Sort

***Time Complexity:***
- **Best Case:** O(n log n), When the array is already sorted or nearly sorted.
- **Average Case:** O(n log n), When the array is randomly ordered.
- **Worst Case:** O(n log n), When the array is sorted in reverse order.
**Auxiliary Space:** O(n), Additional space is required for the temporary array used during merging.

## Applications of Merge Sort:

- Sorting large datasets
- [External sorting](https://www.geeksforgeeks.org/dsa/external-sorting/) (when the dataset is too large to fit in memory)
- Used to solve problems like [Inversion counting](https://www.geeksforgeeks.org/dsa/inversion-count-in-array-using-merge-sort/), [Count Smaller on Right](https://www.geeksforgeeks.org/dsa/count-smaller-elements-on-right-side/) & [Surpasser Count](https://www.geeksforgeeks.org/dsa/find-surpasser-count-of-each-element-in-array/)
- Merge Sort and its variations are used in library methods of programming languages. Its variation [TimSort](https://www.geeksforgeeks.org/dsa/timsort/) is used in Python, Java Android and Swift. The main reason why it is preferred to sort non-primitive types is stability which is not there in QuickSort. [Arrays.sort in Java](https://www.geeksforgeeks.org/java/arrays-sort-in-java/) uses QuickSort while [Collections.sort](https://www.geeksforgeeks.org/java/collections-sort-java-examples/) uses MergeSort.
- It is a preferred algorithm for sorting Linked lists.
- It can be easily parallelized as we can independently sort subarrays and then merge.
- The merge function of merge sort to efficiently solve the problems like [union and intersection of two sorted arrays](https://www.geeksforgeeks.org/dsa/union-and-intersection-of-two-sorted-arrays-2/).

### ***Advantages and Disadvantages of Merge Sort***

****Advantages****
- ****Stability**** : Merge sort is a stable sorting algorithm, which means it maintains the relative order of equal elements in the input array.
- ****Guaranteed worst-case performance:**** Merge sort has a worst-case time complexity of ****O(N logN)**** , which means it performs well even on large datasets.
- ****Simple to implement:**** The divide-and-conquer approach is straightforward.
- ****Naturally Parallel**** : We independently merge subarrays that makes it suitable for parallel processing.

****Disadvantages****
- ****Space complexity:**** Merge sort requires additional memory to store the merged sub-arrays during the sorting process.
- ****Not in-place:**** Merge sort is not an in-place sorting algorithm, which means it requires additional memory to store the sorted data. This can be a disadvantage in applications where memory usage is a concern.
- Merge Sort is ****Slower than QuickSort in general as**** QuickSort is more cache friendly because it works in-place.