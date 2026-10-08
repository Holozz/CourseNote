# lambda expressions
**语法**：
```python
	f = lambda x: x+1
```
$$就等同于$$
```python
	def f(x):
		return x+1
```
- lambda表达式就等同于一个无名函数
- 其中在lambda后面的`x`就是函数参数
- 函数返回值是冒号`:`后面的内容

- `lambda x: ....`相当于一个函数
- `(lambda x: ....)(parameter)`就是其返回值

**更复杂点**
```python
	def F(f):
		def g(x):
			def h(y):
				 return f(x, y)
			return h
		return g
```
$$等同于$$
```python
	F = lambda f: lambda x: lambda y: f(x, y)
```

---
*用lambda表达式直接构造递归函数计算阶乘*

~~~Python
	def anonymous_factorial
		return (lambda f: f(f))(lambda f: lambda x: 1 if x == 0 else x * f(f)(x - 1))
	>>>anonymous_factorial()(5)
	>>>120
	>>>anonymous_factorial()(5) ==
	>>>f(f)(5) ==
	>>>(lambda f: lambda x: 1 if x == 0 else x * f(f)(x - 1))(lambda f: lambda x: 1 if x == 0 else x * f(f)(x - 1))(5)
	>>>(lambda Δ: lambda x: 1 if x == 0 else x * Δ(Δ)(x - 1))(Δ)(5) ==
	>>>5*Δ(Δ)(5-1) ==
	>>>5*(lambda f: lambda x: 1 if x == 0 else x * f(f)(x - 1))(4) ==
	>>>.... ==
	>>>5*4*3*2*1*f(f)(0) ==
	>>>120
~~~