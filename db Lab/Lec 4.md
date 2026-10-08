---
cssclasses:
---

<div class="cover">
  <h1>2024级本科生《数据库系统实验》实验报告</h1>
  <h2>Lecture 4</h2>
  <div class="info">
    <p>班级：计科1班</p>
    <p>姓名：韩宇</p>
    <p style="margin-bottom: 400px;">学号：24319050</p>
    <p class="date" style="font-size: 1em">日期：2026/9/30</p>
  </div>
</div>

<div style="page-break-after: always;"></div>

---

## 一、实验目的

- 熟悉SQL的数据查询语言，
- 能够使用SQL语句对数据库进行嵌套查询、集合运算。

## 二、实验内容

1. 嵌套查询
	- 通过实验验证对子查询的两个限制条件：不能使用order by子句；外层   select语句变量可以用在子查询中，但反之不行
	- 体会相关子查询和不相关子查询的不同：相关子查询要使用外层select  语句提供的数据；不相关子查询即内层子查询不依赖于外层select语句。
	- 考察4类谓词的用法,包括:
		第1类,IN, NOT IN
		第2类,带有比较运算符的子查询
		第3类,SOME,ANY或ALL谓词的子查询
		第4类,带有 EXISTS谓词的子查询
2. 集合运算
	- 使用保留字 UNION 、INTERSECT 、EXCEPT进行集合或、交、减运算。

## 三、实验结果

### (1)查询选修C++课程的成绩比姓名为ZNKOO的学生高的所有学生的编号和姓名;

要输出的是学生的编号和姓名，要比的是成绩，所以三张表都要用上：`students`（编号、姓名）、`choices`（成绩）、`courses`（定位 C++ 这门课）

这里用相关子查询来写：外层 `students` 每取到一个学生，就交给内层 `EXISTS` 判断"他有没有一条选课记录满足条件"，内层的 `choices.sid = students.sid` 直接引用了外层的值，所以它是相关的。内层里面还嵌了两处不相关子查询，分别取出 C++ 的 `cid` 和 ZNKOO 的 `sid`，最后用 `score >` 把成绩和 ZNKOO 的 C++ 成绩比大小

```sql
SELECT sid, sname
FROM students
WHERE EXISTS (
			SELECT *
			FROM choices
			WHERE cid = (SELECT cid FROM courses WHERE cname = 'C++')
			  AND choices.sid = students.sid
			  AND score > (SELECT score
			  			   FROM choices
			  			   WHERE sid = (SELECT sid FROM students WHERE sname = 'ZNKOO')
			  			     AND cid = (SELECT cid FROM courses WHERE cname = 'C++')
			  			  )
			);
```


![[Pasted image 20260930113024.png|658]]

### (2)找出和学生883794999或学生850955252的年级一样的学生的姓名;

只要 `students` 一张表就够了,内层先用 `OR` 把这两个学生找出来、取出他们的 `grade`，外层再用 `IN` 判断某个学生的年级在不在这个集合里，在就输出他的姓名。

注意 `sid` 在学生表里是 `char(10)` 类型，这里直接写数字，是靠 SQL Server 的隐式类型转换去比较的

```sql
SELECT sname
FROM students
WHERE grade IN (
	SELECT grade
	FROM students
	WHERE sid = 883794999 OR sid = 850955252
	);
```

![[Pasted image 20260930113416.png|595]]

### (3)查询没有选修Java的学生名称;

"没有选修"这种否定条件有两种典型写法，两种都验证了一下：

- 第一种用 `!= ALL`（等价于 `NOT IN`）：先在 `choices` 里求出所有选了 JAVA 的学生编号，再要求外层学生的编号**与这个集合里的每一个都不相等**；
- 第二种用相关子查询 `NOT EXISTS`：对每个学生，检查 `choices` 里**不存在**一条既属于他、课程又是 JAVA 的选课记录。

```sql
SELECT sname
FROM students
WHERE sid != ALL (SELECT sid
				  FROM choices
				  WHERE cid = (SELECT cid FROM courses WHERE cname = 'JAVA'));

SELECT sname
FROM students s
WHERE NOT EXISTS (
	SELECT 1
	FROM choices c
	WHERE c.sid = s.sid
	  AND c.cid = (SELECT cid FROM courses WHERE cname = 'JAVA')
	);
```

![[Pasted image 20260930114326.png|626]]

### (4)找出课时最少的课程的详细信息;

同样用了两种写法：

- `<= ALL`：要求课时小于等于所有课程的课时，那么剩下的就是最小的那些；
- `= (SELECT MIN(...))`：先用集函数求出全体课时里的最小值，再让课时等于它

```sql
SELECT * FROM courses
WHERE [hour] <= ALL (SELECT [hour] FROM courses);

SELECT * FROM courses
WHERE [hour] = (SELECT MIN([hour]) FROM courses);
```

![[Pasted image 20260930114247.png]]

###  (5)查询工资最高的教师的编号和开设的课程号;

要输出的是"教师编号 + 课程号"，所以要把 `teachers` 和 `choices` 两张表连起来用：先用不相关子查询 `MAX(salary)` 求出全体教师中的最高工资，再拿它筛出工资等于这个值的教师，最后按 `tid` 相等到 `choices` 里取出该教师开设的课程号

```sql
SELECT teachers.tid, cid
FROM teachers, choices
WHERE salary = (SELECT MAX(salary) FROM teachers)
  AND teachers.tid = choices.tid;
```


![[Pasted image 20260930152946.png]]

### (6)找出选修课程ERP成绩最高的学生编号;

要比较的对象是"选了 ERP 的学生的成绩"，如果直接用嵌套子查询去比，那段"取 ERP 选课记录"的子句就得重复写两遍。这里用 `WITH ... AS (...)` 定义了一个公共表表达式 `x`，先把"选了 ERP 的学生及其成绩"整理成一张临时表，再在 `x` 里保留成绩等于 `MAX(b)` 的行

```sql
WITH x AS (
	SELECT sid, score AS b
	FROM choices
	WHERE cid = (SELECT cid FROM courses WHERE cname = 'ERP')
	)
SELECT sid
FROM x
WHERE b = (SELECT MAX(b) FROM x);
```


![[Pasted image 20260930154131.png]]

### (7)查询没有学生选修的课程名称;

用相关子查询 `NOT EXISTS`：对 `courses` 里的每一门课，检查 `choices` 里是否**不存在** `cid` 与它相同的选课记录。子查询中的 `courses.cid = choices.cid` 引用了外层的课程表，因此它是相关子查询 —— 外层的每一门课都要单独判断一次

```sql
SELECT cname
FROM courses
WHERE NOT EXISTS (
	SELECT *
	FROM choices
	WHERE courses.cid = choices.cid
	);
```


![[Pasted image 20260930155019.png]]

### (8)查询讲授课程UML的教师所讲授的所有课程名称;

这题是三层嵌套：

1. 最内层：在 `courses` 里取出 UML 的 `cid`；
2. 中间层：在 `choices` 里用这个 `cid` 找出所有讲授 UML 的教师的 `tid`；
3. 最外层：再回到 `choices` 用这些 `tid` 找出他们开设的所有课程的 `cid`，最后在 `courses` 里取课程名

```sql
SELECT cname
FROM courses
WHERE cid IN (
	SELECT cid
	FROM choices
	WHERE tid IN (
		SELECT tid
		FROM choices
		WHERE cid = (SELECT cid FROM courses WHERE cname = 'UML')
		)
	);
```


![[Pasted image 20260930155612.png]]

### (9)使用集合交运算，查询既选修了database又选修了UML课程的学生编号;

两个 `SELECT` 分别取出"选了 database 的学生编号"和"选了 UML 的学生编号"，它们的列数和列的类型完全一致，因此可以直接用 `INTERSECT` 求交集，得到同时满足这两个条件的学生编号

```sql
SELECT sid
FROM choices
WHERE choices.cid = (SELECT cid FROM courses WHERE cname = 'database')
INTERSECT
SELECT sid
FROM choices
WHERE cid = (SELECT cid FROM courses WHERE cname = 'UML');
```

![[屏幕截图 2026-09-30 155932.png]]

### (10)使用集合减运算，查询选修了database却没有选修UML课程的学生编号;

把 (9) 里的 `INTERSECT` 换成 `EXCEPT`，就是"在第一个结果里、但不在第二个结果里"的集合减运算

```sql
SELECT sid
FROM choices
WHERE choices.cid = (SELECT cid FROM courses WHERE cname = 'database')
EXCEPT
SELECT sid
FROM choices
WHERE cid = (SELECT cid FROM courses WHERE cname = 'UML');
```

得到 5454 行。（它和 (9) 的 303 行是不相交的两部分，加起来正好是选修了 database 的学生总数。）

![[Pasted image 20260930160059.png]]

## 四、问题&总结

- 这次的练习已经能熟练书写查询语句了，没什么难点
- 新的语法点包括集合的运算，如交并补；还有EXITS的使用：如果引用外层的属性就会进行遍历判断，如果没有和外层有任何联系则就会literally返回一个bool值
- 更改了习惯：前两次尝试多用FROM后面接多个关系的连接，这样写起来对我很费力；这次几乎没有使用，全部用WHERE子句来实现对多个关系的复合查询，主要靠嵌套子句来实现，于性能上有优化，对我自己也读着更轻松