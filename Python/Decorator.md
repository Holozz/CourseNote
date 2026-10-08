function decorators
### $$示例$$
```python
	def trace(fn):
		def traced(x):
			print("calling", fn, "on", x)
			return fn(x)
		return traced
	def square(x):
		return x*x
```
之后
```python
	@trace
	square(4)

```
**就等同于**
```python
	square = trace(square)
```

