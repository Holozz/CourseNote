---
cssclasses: 
---

<div class="cover">
  <h1>2024级本科生《数据库系统实验》实验报告</h1>
  <h2>Lecture 3</h2>
  <div class="info">
    <p>班级：计科1班</p>
    <p>姓名：韩宇</p>
    <p style="margin-bottom: 400px;">学号：24319050</p>
    <p class="date" style="font-size: 1em">日期：2026-09-23</p>
  </div>
</div>

---

## 一、实验目的

熟悉SQL的数据查询语言，能够使用SQL语句对数据库进行单表查询、连接查询

## 二、实验内容

1. 单表查询
	- 查询的目标表达式为所有列、指定列或指定列的运算。
	- 用 DISTINCT保留字消除重复行
	-  对查询结果排序和分组。
	-  集合分组使用集函数进行各项统计
2. 连接查询
	- 笛卡儿连接和等值连接
	- 自连接
	-  外连接
	-  复合条件连接
	-  多表连接

## 三、实验结果

### (1)查询全部课程的详细记录;

直接从表 `courses`里查找全部 （ `*`）即可
```sql
SELECT *
FROM COURSES;
```

![[Pasted image 20260923105224.png|638]]
### (2)查询所有有选修课的学生的编号;

先验证学生数量为 100000
在 `choices`里用学生编号 `sid`为依据进行分组查找，这样就能找到每一个选课的学生的情况，并且数量也是100000没有遗漏

```sql
SELECT DISTINCT sid
FROM STUDENTS;

SELECT sid
FROM CHOICES
GROUP BY sid
HAVING COUNT(*) > 0;

```

![[Pasted image 20260923105357.png|619]]

![[Pasted image 20260923105702.png|621]]
### (3)查询课时<88(小时)的课程的编号;

在 `courses`表中找课时（ `hour`）小于80 的即可

```sql
SELECT cid
FROM COURSES
WHERE hour < 88;
```

![[Pasted image 20260923105804.png|621]]
### (4)请找出总分超过400分的学生;

需要的输出：学生
条件：总分数的数值大小
条件来源：在 `choices`表里找到每个学生的所有课程的分数并相加得到总分
过滤：与400比大小

所以需要用到两个表： `students`和 `choices`
并且要按学生来分组，以统计每个学生各自上的所有课程，然后使用 `SUM`对其分数求和，使用 `HAVING` 过滤

如果只需要得到 学生编号 则用第一种写法直接获取即可；
如果需要学生的 全部信息 则要在得到编号之后再全部查找，嵌套了一次

```sql
SELECT STUDENTS.sid
FROM STUDENTS JOIN CHOICES ON STUDENTS.sid = CHOICES.sid
GROUP BY STUDENTS.sid
HAVING SUM(score)>400

SELECT *
FROM STUDENTS , (
SELECT STUDENTS.sid
FROM STUDENTS JOIN CHOICES ON STUDENTS.sid = CHOICES.sid
GROUP BY STUDENTS.sid
HAVING SUM(score)>400
) AS A
WHERE STUDENTS.sid = A.sid;
```

![[Pasted image 20260923110911.png|624]]
![[Pasted image 20260923111332.png|633]]
### (5)查询课程的总数;

直接使用 `COUNT()`

```sql
SELECT COUNT(*)
FROM COURSES;
```

![[Pasted image 20260923111637.png|633]]
### (6)查询所有课程和选修该课程的学生总数;

先将 `courses` 与 `choices` 连接起来，可以得到包含所有课程和学生选课的信息的表；
再以 `courses.id` 分类，对于每个不同课程的信息单独统计；
用 `COUNT() AS NUM_STU` 查找每个类下有多少条目，就是有多少学生选了该门课程，同时把课程的id也带上；
最后，嵌套一个外层查询，以刚刚得到的 `cid`+`NUM_STU` 与 `courses`连接，就可以在 `courses`里查找得到该门课程的全部信息，得到最终结果

```sql
SELECT *
FROM courses, (
	SELECT courses.cid, COUNT(*) AS NUM_STU
	FROM courses JOIN choices ON courses.cid = choices.cid
	GROUP BY courses.cid
	) AS B
WHERE courses.cid = B.cid
```

![[Pasted image 20260923113711.png|633]]
### (7)查询选修成绩超过60的课程超过两门的学生编号;

要知道学生以及成绩信息，可以将 `students`和 `choices`连接；
随后学生编号来分组，可以得到每个学生的所有课程的信息；
再对每个学生分别统计其考试成绩，大于60的就计数，这里同时用到条件判断 `CASE`和计数 `COUNT`；
再用 `HAVING` 将大于2的学生过滤出来即可

```sql
SELECT STUDENTS.sid
FROM STUDENTS JOIN CHOICES ON STUDENTS.sid = CHOICES.sid
GROUP BY STUDENTS.sid
HAVING COUNT(CASE WHEN score>60 THEN 1 END)>2;
```

![[Pasted image 20260923122703.png|634]]
### (8)统计各个学生的选修课程数目和平均成绩;

直接在 `choices`表格里按学生分类然后统计数目和平均值即可

```sql
SELECT sid, COUNT(*) AS choice_NUM, AVG(score) AS avg_score
FROM CHOICES
GROUP BY sid
```

![[Pasted image 20260926151848.png|632]]
### (9)查询选修Java的所有学生的编号及姓名;

先把 `choices`和 `courses`连接起来，查询课程是JAVA的条目，得到所有选JAVA的学生编号表；
得到学生编号表后，将其与 `students`连接进一步得到学生的姓名

```sql
SELECT DISTINCT STUDENTS.sid, sname
FROM STUDENTS JOIN (
				SELECT sid, cname
				FROM CHOICES, COURSES
				WHERE CHOICES.cid = COURSES.cid AND COURSES.cname='JAVA'
				)
				AS C ON STUDENTS.sid = C.sid;
```

![[Pasted image 20260923125737.png|605]]
### (10)查询姓名为sssht的学生所选的课程的编号和成绩;

先在 `students`查找这个学生的编号；
得到编号用作为WHERE语句的条件进行嵌套查询，外层就是在 `choices`里查询这个编号对应的课程以及成绩

```sql
SELECT cid, score
FROM choices
WHERE sid = (	
			SELECT sid
			FROM students
			WHERE sname='sssht');

```

![[Pasted image 20260923130316.png|602]]
### (11)查询其他课时比课程C++多的课程的名称;

这个要用到自连接，只需要 `courses`表格；
一边是只有C++这个课的 `courses`，一边是所有课程的 `courses`，将两边的课程时长进行比较即可；

```sql
SELECT DISTINCT x.cname
FROM courses AS x, courses AS y
WHERE x.[hour] > y.[hour] AND y.cname = 'C++'
```

![[Pasted image 20260923130752.png|602]]


## 四、问题&总结
### 问题
- 一些关键字作为变量名的时候，想要继续使用就要用 [] 显式的标注
- 理论课上所学的 **自然连接** 以及左连接、右连接等在 SQL Server里似乎没有对应的关键字，输入之后显示未定义等错误信息
- 对于连接的使用不太熟练，直接用逗号连接和使用JOIN ON等关键字
- 以及复杂条件判断需要用到的 CASE 关键字也不是很熟悉
### 总结
这次相当于进一步熟悉SQL的语法，题目本身逻辑不难，重点在于考虑如何用SQL的语法来表达这些逻辑；
以及在作业的后半段，我感觉全部用大写（或者全部小写）不利于阅读，即便SQL Server为关键字都标注的颜色；所以后面我选择为SQL语法的关键字使用大写，所有数据库里自定义的元素就用小写

