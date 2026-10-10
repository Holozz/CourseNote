---
cssclasses:
---

<div class="cover">
  <h1>2024级本科生《数据库系统实验》实验报告</h1>
  <h2>Lecture 6</h2>
  <div class="info">
    <p>班级：计科1班</p>
    <p>姓名：韩宇</p>
    <p style="margin-bottom: 400px;">学号：24319050</p>
    <p class="date" style="font-size: 1em">日期：10/10</p>
  </div>
</div>

<div style="page-break-after: always;"></div>

---

## 一、实验目的

熟悉SQL的有关视图的操作，
能够使用SQL语句创建需要的视图，对视图进行查询和取消视图。
## 二、实验内容

1.  定义常见的视图形式，包括：
	- 行列子集视图
	- WITH CHECK OPTION的视图
	- 基于多个基表的视图
	- 基于视图的视图
	- 带表达式的视图
	- 分组视图
2.  考察 WITH CHECK OPTION这一语句在视图定义后产生的影响，包括对修改操作、删除操作、插入操作的影响
3.  讨论视图的数据更新情况，对子行列视图进行数据更新。
4.  使用DROP语句删除一个视图，由该视图导出的其他视图定义仍在数据字典中，但已不能使用，必须显式删除。同样的原因，删除基表时，由该基表导出的所有视图定义都必须显式删除。


## 三、实验结果

### (1) 定义选课信息和课程名称的视图 VIEWC;

要把选课信息和课程名称放在一起，所以用 `choices.cid = courses.cid` 将 `choices` 和 `courses` 两张表连接起来，保留 `choices` 的全部列，再加上课程名称 `cname`

```sql
CREATE VIEW viewc AS
SELECT choices.*, cname
FROM choices, courses
WHERE choices.cid = courses.cid;
```

![[Pasted image 20261010102627.png|512]]

### (2) 定义学生姓名与选课信息的视图 VIEWS;

只是要补上学生姓名，所以改为连接 `students` 和 `choices`，按学生编号 `sid` 相等来匹配，得到姓名加上该学生的选课信息

```sql
CREATE VIEW views AS
SELECT sname, choices.*
FROM students, choices
WHERE students.sid = choices.sid;
```

![[Pasted image 20261010102948.png|519]]

### (3)定义年级低于1998的学生的视图S1(SID, SNAME, GRADE);

这里的年级低于我理解成单纯指数值小于1998

只需要 `students` 一张表，用 `WHERE grade < 1998` 筛选，再只保留 `sid`、`sname`、`grade` 三列，得到行列子集视图

```sql
CREATE VIEW s1 AS
SELECT sid, sname, grade
FROM students
WHERE grade < 1998;
```

![[Pasted image 20261010103224.png|528]]

### (4)查询学生为“ uxj of” 的学生的选课信息;

前面定义的 `views` 已经包含姓名和选课信息，直接按 `sname` 筛选即可，这里按 SQL 文件和截图中的实际姓名 `uxjof` 查询

返回 3 条选课记录，学生编号都是 `800023963`，课程号分别为 `10018`、`10046`、`10037`，成绩分别为 84、94、98

```sql
SELECT *
FROM views
WHERE sname = 'uxjof';
```

![[Pasted image 20261010103545.png|532]]

### (5)查询选修课程“UML” 的学生的编号和成绩;

先在 `courses` 里用子查询取出 UML 的课程号，再将 `students` 和 `choices` 按学生编号连接，筛选选了这门课的记录，最后输出学生编号和成绩

SQL 文件中的原查询返回 5,965 行，成绩为 `NULL` 的选课记录也保留在结果中

```sql
SELECT students.sid, score
FROM students, choices
WHERE students.sid = choices.sid
  AND choices.cid = (SELECT cid FROM courses WHERE cname = 'UML');
```

![[Pasted image 20261010104314.png|535]]

还尝试了加上 `DISTINCT` 的写法，返回 5,961 行，比原查询少 4 行，这里去重的是整个 `sid`、`score` 组合，同一个学生如果成绩不同，仍然会保留多行

```sql
SELECT DISTINCT students.sid, score
FROM students, choices
WHERE students.sid = choices.sid
  AND choices.cid = (SELECT cid FROM courses WHERE cname = 'UML');
```

![[Pasted image 20261010104254.png|537]]

### (6)向视图S1插入记录(60000001,Lily,2001);

直接向 `s1` 插入这三个值，对应的是基表 `students` 中的学生编号、姓名和年级

此时视图没有加 `WITH CHECK OPTION`，插入成功，影响 1 行，写入基表的记录年级为 2001，不满足 `grade < 1998`，所以之后通过 `s1` 查询不到这条记录

```sql
INSERT INTO s1
VALUES ('60000001', 'Lily', 2001);
```

![[Pasted image 20261010104934.png|538]]

### (7)定义包括更新和插入约束的视图S1,尝试向视图插入记录(60000001,Lily, 1997),删除所有年级为1999的学生记录,讨论更新和插入约束带来的影响

先用 `ALTER VIEW` 修改已经存在的 `s1`，加上 `WITH CHECK OPTION`，之后通过这个视图插入或更新的数据，都要求修改后仍满足 `grade < 1998`

```sql
ALTER VIEW s1 AS
SELECT sid, sname, grade
FROM students
WHERE grade < 1998
WITH CHECK OPTION;
```

再尝试插入年级为 1997 的 Lily，1997 满足视图条件，但上一题已经在基表中插入了学号 `60000001`，所以这次报的是主键重复错误，不能把这个错误当成 `WITH CHECK OPTION` 的检查失败

```sql
INSERT INTO s1
VALUES ('60000001', 'Lily', 1997);
```

![[Pasted image 20261010105448.png|545]]

删除时仍然只能操作视图里可见的行，`s1` 中只有年级小于 1998 的记录，找不到年级为 1999 的行，所以这条删除语句执行成功，但影响 0 行

```sql
DELETE
FROM s1
WHERE grade = 1999;
```

![[Pasted image 20261010112011.png|546]]

`WITH CHECK OPTION` 对通过视图进行的插入和更新检查新值是否满足视图条件，删除这里没有匹配的记录，不能据此认为是检查选项阻止了删除；直接操作基表也不受这个视图检查选项的限制

### (8)在视图 VIEWS中将姓名为“ uxjof” 的学生的选课成绩都加上5分

在 `views` 中按姓名筛选，直接把对应的 `score` 加上 5，虽然这个视图连接了两张表，这次修改的列只来自 `choices`，SQL Server 可以通过视图更新对应的基表记录

更新影响 3 行

```sql
UPDATE views
SET score = score + 5
WHERE sname = 'uxjof';
```

![[Pasted image 20261010110716.png|556]]

再查询一次，按课程号和前面的结果对应，`10018` 的成绩从 84 变为 89，`10046` 从 94 变为 99，`10037` 从 98 变为 103，结果行的顺序和之前不同，所以按课程号比较

```sql
SELECT *
FROM views
WHERE sname = 'uxjof';
```

![[Pasted image 20261010110735.png|557]]

### (9)取消以上建立的所有视图

依次用 `DROP VIEW` 删除 `s1`、`viewc`、`views`，执行成功后，视图列表里已经没有这三个视图，删除视图只删除它的定义，基表和已经写入或修改的数据仍然保留

```sql
DROP VIEW s1;
DROP VIEW viewc;
DROP VIEW views;
```

![[Pasted image 20261010112439.png|567]]

## 四、问题&总结

- 这次主要练习视图的创建、查询、更新和删除，查询时可以直接用前面定义好的视图，省去重复写连接条件
- 通过视图插入和更新，实际改的是基表的数据，记录不在视图里显示，也不代表基表里没有这条记录
- 插入的Lily那条数据，在视图增加约束条件的时候重新创建了一遍视图，所以之后Lily存在于数据库中，但是并不在视图里了
- `WITH CHECK OPTION` 的条件检查和基表的主键约束要分开看，删除时也要先考虑记录是否在视图的范围内
