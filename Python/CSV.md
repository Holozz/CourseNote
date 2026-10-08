## CSV

`csv` 是 Python 内建的一个模块，主要用于处理 CSV（Comma-Separated Values ，逗号分隔值）格式的文件。这个格式广泛用于存储表格数据，它可以很方便地将数据以文本形式保存，每一行代表一条记录，每个字段由逗号（或其他分隔符）分隔。
## 主要功能

1. **读取 CSV 文件**：
    - `csv.reader()` 用于读取 CSV 文件，它返回一个可迭代的对象，迭代时每次返回一行数据，作为一个列表
2. **写入 CSV 文件**：
    - `csv.writer()` 用于将数据写入 CSV 文件。你可以传递一个包含数据的可迭代对象，它会将数据写成 CSV 格式
3. **处理字典形式的 CSV 文件**：
    - `csv.DictReader()` 和 `csv.DictWriter()` 使得你可以以字典的形式读取和写入 CSV 文件，每一行数据变成一个字典，其中键是列的名字
### 基本用法
 需要用到 [[With  Open]]函数
#### 1. 读取 CSV 文件

```python
	 import csv
	 with open('example.tsv', mode='r') as file:
	    csv_reader = csv.reader(file, delimiter='\t')
	    for row in csv_reader:
	        print(row)
```
- 每一行 `row` 是一个列表，包含 CSV 文件中的字段。
#### 2. 写入 CSV 文件

```python
	import csv
	
	# 数据准备
	data = [
	    ['name', 'age', 'city'],
	    ['Alice', 30, 'New York'],
	    ['Bob', 25, 'Los Angeles']
	]
	
	# 打开文件进行写入
	with open('output.csv', mode='w', newline='') as file:
	    csv_writer = csv.writer(file)
	    
	    # 写入数据
	    csv_writer.writerows(data)
	    ```
	
	- `writerows()` 会将数据写入 CSV 文件，每行的数据作为列表传入。
	
	#### 3. 使用 `DictReader` 和 `DictWriter`
	
	`csv.DictReader()` 使得每一行数据以字典的形式表示，其中字典的键是 CSV 文件的表头（第一行数据），值是每一列的数据。
	
	```python
	
	import csv
	
	# 读取 CSV 文件（使用字典形式）
	with open('example.csv', mode='r') as file:
	    csv_reader = csv.DictReader(file)
	    
	    # 迭代每一行
	    for row in csv_reader:
	        print(row)
```

输出会类似于：

``` python
	{'name': 'Alice', 'age': '30', 'city': 'New York'}
	{'name': 'Bob', 'age': '25', 'city': 'Los Angeles'}
```

`csv.DictWriter()` 用于将字典数据写入 CSV 文件：

```python
	import csv
	
	# 数据准备
	data = [
	    {'name': 'Alice', 'age': 30, 'city': 'New York'},
	    {'name': 'Bob', 'age': 25, 'city': 'Los Angeles'}
	]
	
	# 打开文件进行写入
	with open('output.csv', mode='w', newline='') as file:
	    fieldnames = ['name', 'age', 'city']
	    csv_writer = csv.DictWriter(file, fieldnames=fieldnames)
	    
	    # 写入表头
	    csv_writer.writeheader()
	    
	    # 写入数据
	    csv_writer.writerows(data)
```

### 参数说明
- `delimiter`：指定字段之间的分隔符，默认为逗号（`,`）。可以设置为其他字符（如制表符 `\t`）
- `quotechar`：指定用来包裹字段的引号字符，默认为双引号（`"`）。这对于包含分隔符或换行符的字段是必要的
- `lineterminator`：指定行终止符，默认为换行符。可以调整为其他符号（如 Windows 下使用 `\r\n`）
## 设置字段分隔符
```python
	import csv
	with open('example.tsv', mode='r') as file:
	    csv_reader = csv.reader(file, delimiter='\t')  # 使用制表符作为分隔符
	    for row in csv_reader:
	        print(row)
```
## 读取带引号的字段
```python
	import csv
	with open('example.csv', mode='r') as file:
	    csv_reader = csv.reader(file, quotechar='"')  # 指定用双引号包裹字段
	    for row in csv_reader:
	        print(row)
```
