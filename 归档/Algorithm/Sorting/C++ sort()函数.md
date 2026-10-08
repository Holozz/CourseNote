The sort() function is used to sort elements in a container or array. It provides a simple and efficient way to sort data in C++.
- Works on random-access iterators (arrays, vectors, deques).
- Default sort is ascending order.
~~~cpp
	#include <iostream>
	using namespace std;
	
	int main()
	{
	    vector<int> v = {5, 3, 2, 1, 4};
	    // Sort vector (by default in ascending order)
	    sort(v.begin(), v.end());
	    for (int i : v)
	        cout << i << " ";
	    return 0;
	}
~~~

## Syntax of sort()
The **std::sort()** function is defined inside the *\<algorithm>* header file.
 **Parameters**
- **first**: Iterator to the beginning of the range to be sorted.
- **last**: Iterator to the element just after the end of the range.
~~~cpp
	#include <algorithm>
	#include <iostream>
	#include <vector>
	using namespace std;
	struct Point
	{
	    int x;
	    int y;
	};
	int main()
	{
	    vector<Point> points = {{3, 5}, {1, 2}, {4, 1}};
	
	    // Sort points by x value (ascending)
	    sort(points.begin(), points.end(), [](const Point &a, const Point &b) { return a.x < b.x; });
	    // Print sorted points
	    for (auto p : points)
	        cout << "(" << p.x << "," << p.y << ") ";
	    return 0;
	}
~~~