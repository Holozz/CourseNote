# Definition
#### start with the keyword **def** and optionally end with a **return**
#### if without a return, return a **None** by default.
```python
def func_name(parameter_1,parameter_2,...)
	func_content
	return ()
print(func_name)
```

# Parameter/Argument

- #### Parameter - a variable in a method definition
- #### Argument - the actual value passed to the function

the function scope starts by a "`:`"
~~~python
	def add_1(x):
		return x+1
	y = 1
	print(add_1(y))
~~~

in this block, the variable `x` is a parameter and `y` is a argument.

## mutable and immutable objects

in python, strings, tuples and numbers are immutable objects, whereas list, dict, etc. are mutable objects.

- **immutable**: let `a=5`, then let `a=10`，what really happens is creating 10, then let `a` points to it, while 5 is deserted. The value of a hasn't changed, and it's just recreating an `a` with the value 10.

- **mutable**: let variable `a=[1,2,3,4]`, then let `a[2]=5`. This will change the third element of `a`, and `a` itself hasn't been moved.

## The transmission of variable to parameter

- **immutable**：类似 C++ 的值传递，如整数、字符串、元组。如 fun(a)，传递的只是 a 的值，没有影响 a 对象本身。如果在 fun(a) 内部修改 a 的值，则是新生成一个 a 的对象。
- **mutable**：类似 C++ 的引用传递，如 列表，字典。如 fun(a)，则是将 la 真正的传过去，修改后 fun 外部的 la 也会受影响

python 中一切都是对象，严格意义我们不能说值传递还是引用传递，我们应该说传不可变对象和传可变对象。

# Scope
##### the operations in the functions won\`t change the outside real value of x, usually.

___
~~~python
	x = 2
	print(add_1(10))
	print(x)
~~~
the outside x is still 2, the output will be:
~~~
11
2
~~~
