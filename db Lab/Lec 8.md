---
cssclasses:
---

<div class="cover">
  <h1>2024级本科生《数据库系统原理实验》实验报告</h1>
  <h2>Lecture 8</h2>
  <div class="info">
    <p>班级：计科1班</p>
    <p>姓名：韩宇</p>
    <p style="margin-bottom: 400px;">学号：24319050</p>
    <p class="date" style="font-size: 1em">日期：10/21 </p>
  </div>
</div>

<div style="page-break-after: always;"></div>

---

## 一、实验目的

认识NULL值在数据库中的特殊含义。
了解SQL对空值和空集的处理。
熟练使用SQL语句进行对空置、空集相关的操作
## 二、实验内容

- 通过实验验证 SQL SERVER对NULL的处理，包括:
- 在查询的目标表达式中包含空值的运算。
- 在查询条件中空值与比较运算符的运算结果。
- 使用“ IS NULL”或“ IS NOT NULI”来判断元组该列是否为空值。
- 对存在取空值的列按值进行 ORDER BY排序。
- 使用保留字 DISTINCT对空值的处理。
- 使用 GROUP BY对存在取空值的属性值进行分组。
- 结合分组考察空值对各个集合函数的影响，特别注意对 COUNT( * )和 COUNT(列名)的不同影响。
- 考察结果集是空集时，各个集函数的处理情况。
- 验证嵌套查询中返回空集的情况下与各个谓词的运算结果。
- 进行与空值有关的等值连接运算。 

## 三、实验结果

### (1)通过查询选修课程C++的学生的人数，其中成绩合格的学生人数，不合格的学生人数，讨论NULL值的特殊含义

先把 `choices` 和 `courses` 按课程号连接，筛选 C++ 的选课记录，再按学号去重统计人数，及格条件为 `score >= 60`，不及格为 `score < 60`，空成绩用 `IS NULL` 判断

返回选课学生 5876 人，其中有及格记录的 4715 人，有不及格记录的 722 人，有空成绩记录的 487 人

同一学生可能有多条选课记录，并且这些记录属于不同的成绩类别，所以这三类去重人数可能重叠，不能直接相加

```sql
SELECT COUNT(DISTINCT ch.sid) AS total_students,
       COUNT(DISTINCT CASE WHEN ch.score >= 60 THEN ch.sid END) AS passed_students,
       COUNT(DISTINCT CASE WHEN ch.score < 60 THEN ch.sid END) AS failed_students,
       COUNT(DISTINCT CASE WHEN ch.score IS NULL THEN ch.sid END) AS null_score_students
FROM choices AS ch
JOIN courses AS c ON ch.cid = c.cid
WHERE c.cname = 'C++';
```

![[Pasted image 20261021111048.png]]

再按选课记录统计，不对学号去重，总记录数为 6031，其中及格 4817 条，不及格 724 条，空成绩 490 条，满足 `6031 = 4817 + 724 + 490`

`NULL` 表示成绩未知或缺失，不等于 0，与 60 比较得到的是 `UNKNOWN`，所以 `score >= 60` 和 `score < 60` 都不会选中空成绩的记录，需要单独统计

```sql
SELECT COUNT(*) AS total_records,
       COUNT(CASE WHEN ch.score >= 60 THEN 1 END) AS passed_records,
       COUNT(CASE WHEN ch.score < 60 THEN 1 END) AS failed_records,
       COUNT(CASE WHEN ch.score IS NULL THEN 1 END) AS null_score_records
FROM choices AS ch
JOIN courses AS c ON ch.cid = c.cid
WHERE c.cname = 'C++';
```

![[Pasted image 20261021111059.png]]

### (2)查询选修课程C++的学生的编号和成绩，使用 ORDER BY按成绩进行排序时,取NULL的项是否出现在结果中？如果有，在什么位置

查询 C++ 的学生编号和成绩，先按成绩升序排列，同分时再按学号升序排列

返回 6031 行，截图中最前面的成绩均为 `NULL`，空值没有被忽略，在 SQL Server 中升序时排在非空成绩之前，如果改为降序，则排在最后

```sql
SELECT ch.sid, ch.score
FROM choices AS ch
JOIN courses AS c ON ch.cid = c.cid
WHERE c.cname = 'C++'
ORDER BY ch.score ASC, ch.sid ASC;
```

![[Pasted image 20261021111252.png]]

### (3)在上面的查询的过程中，如果加上保留字 DISTINCT会有什么效果呢?

在上一题中加上 `DISTINCT`，返回 6024 行，比原查询少 7 行，去掉的是重复的 `sid`、`score` 组合

同一学生的相同成绩只保留一行，同一学生的多条空成绩也会合并，不同学生的空成绩仍分别保留，所以结果中仍然有多行 `NULL`，不能理解为把所有空成绩合并成一行

```sql
SELECT DISTINCT ch.sid, ch.score
FROM choices AS ch
JOIN courses AS c ON ch.cid = c.cid
WHERE c.cname = 'C++'
ORDER BY ch.score ASC, ch.sid ASC;
```

![[Pasted image 20261021111354.png]]


### (4)按年级对所有的学生进行分组，能得到多少个组?与现实的情况有什么不同?

按 `grade` 分组，并用 `COUNT(*)` 统计每组人数，再按年级升序排列

返回 15 行，对应 15 个组，其中 1991 到 2004 共 14 个已知年级，另外还有一个 `NULL` 组，包含 6686 人

分组时所有年级为空的学生被放在同一组，但现实中这些学生只是年级未知，不能认为他们实际属于同一个年级

```sql
SELECT grade, COUNT(*)
FROM students
GROUP BY grade
ORDER BY grade ASC;
```

![[Pasted image 20261021111842.png]]

### (5)结合分组,使用集合函数求每个课程选修的学生的平均分,总的选课记录数,最高成绩,最低成绩,讨论考察取空值的项对集合函数的作用的影响

将选课记录与课程表连接，按课程名称分组，使用集合函数分别计算各项；另外成绩先转为 `decimal`，可以得到小数

`COUNT(*)` 包含空成绩所在的记录，`COUNT(score)` 忽略空成绩，两者之差就是空成绩记录数，`AVG`、`MAX`、`MIN` 也忽略空成绩，所以平均分按 5541 条非空成绩计算，不把未知成绩当作 0

如果一个组的成绩全为 `NULL`，`COUNT(*)` 仍统计该组记录，`COUNT(score)` 为 0，平均分、最高分和最低分均为 `NULL`

```sql
SELECT c.cname,
       AVG(CAST(ch.score AS decimal)) AS avgScore,
       COUNT(*) AS totalRecords,
       COUNT(ch.score) AS scoredRecords,
       COUNT(*) - COUNT(ch.score) AS nullRecords,
       MAX(ch.score) AS maxScore,
       MIN(ch.score) AS minScore
FROM choices AS ch
JOIN courses AS c ON ch.cid = c.cid
GROUP BY c.cname;
```

![[Pasted image 20261021112631.png]]

### (6)采用嵌套查询的方式,利用比较运算符和谓词ALL的结合来查询表 STUDENTS中最晚入学的学生年级。当存在 GRADE取空值的项时,考虑可能出现的情况,并解释

依旧把年级理解为入学年份，数值越大，入学越晚，用 `grade >= ALL` 要求该年级不小于子查询返回的所有年级，再用 `DISTINCT` 去掉重复年级

直接查询返回 0 行，子查询中存在 `NULL`，对于最大的已知年级，与其他已知年级的比较成立，但与 `NULL` 比较为 `UNKNOWN`，整体条件仍为 `UNKNOWN`，较小年级则存在不满足的比较，条件为 `FALSE`，两种情况都不能通过只保留 `TRUE` 的 `WHERE`

```sql
SELECT DISTINCT grade
FROM students
WHERE grade >= ALL (
    SELECT grade
    FROM students
);
```

![[Pasted image 20261021113128.png]]

在外层和子查询中都加上 `grade IS NOT NULL`之后就能正确得到答案，排除未知年级后再比较，返回 1 行，年级为 2004，即已知年级中最晚入学的是 2004 级

如果不存在空年级，原查询也能得到最大年级，如果年级全部为空，修改后的查询返回空集，无法确定已知的最晚年级

子查询为空集时，`ALL` 的判断为 `TRUE`，但这里外层的 `IS NOT NULL` 仍会排除空年级，学生表本身为空时，外层没有记录，也返回空集

```sql
SELECT DISTINCT grade
FROM students
WHERE grade IS NOT NULL
  AND grade >= ALL (
      SELECT grade
      FROM students
      WHERE grade IS NOT NULL
  );
```

![[Pasted image 20261021113141.png]]

## 四、问题&总结

- 这次主要验证 `NULL` 在比较、排序、去重、分组和集合函数中的处理，判断空值要用 `IS NULL` 或 `IS NOT NULL`
- 统计人数时要区分选课记录数和去重学生数，`COUNT(*)` 与 `COUNT(score)` 的统计范围也不同
- 使用 `ALL` 查询最大年级时，需要处理子查询中的空值，否则可能返回空集
- 以后对于统计的结果不能想当然地认为没问题，要考虑NULL值的存在
