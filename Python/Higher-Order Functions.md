# Control
## the difference between call expressions and if 
$$代码实现$$
```python
	if A:
		B
	else:
		C
	
```

```python
	def if_(A, B, C)
		if A:
			return B
		else:
			return C
```

对于if功能的实现，实际上以上两段代码都能做到
**但是**，第一段会判断A之后，在B和C之间挑一个*计算并执行*
而第二段则是在传参的时候就把A，B，C全都*计算*，再在函数内部决定执行哪一个

---
# Control Expressions
## and
对于and操作符，只有当两边式子的值均为True的时候才会为True
而且，如果==第一个为False==，则第二个式子不再被计算，直接跳过将整体判为False
所以会存在第二个式子不合法但是正常编译的情况
## or
相同的，如果or的==第一个式子==为True，第二个式子也不会被计算

# Functions as Return Values
## Functions are first-class
functions can be passed as arguments and can be returned as return values

## Higher-order function
a function that takes a function as a argument value or returns a function as a return value.
##  $$代码示例$$
`function as a return value`
```python
	def make_adder(n)
		def adder(k)
			return n+k
		return adder
	>>>add_three = make_adder(3)
	>>>add_three(4)
	>>>7
```

`function as a argument value`
```python
	from math import pi,sqrt
	def circle(l)
		return pi*l*l
	
	def square(l)
		return l*l
		
	def triangle(l)
		return sqrt(3)/4*l*l
		
	def area(l, term)
		return term(l)
		
	>>>area(3, square)
	>>>9
	>>>area(4, triangle)
	>>>1.7...
```