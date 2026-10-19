---
title: Ch4 Intermediate SQL
tags:
  - 数据库原理
  - SQL
  - 课程笔记
source: ch4.pdf — Database System Concepts, 7th Ed. (Silberschatz, Korth, Sudarshan), Chapter 4
目标: 掌握连接表达式（自然连接/内连接/外连接）、视图（定义、展开、物化、更新）、事务边界、完整性约束（单关系约束、参照完整性、复杂 CHECK、断言、延迟检查）、SQL 数据类型与域、索引、授权（GRANT/REVOKE/角色/视图授权），并能识别各处 NULL 与三值逻辑陷阱
---

> [!abstract] 一句话概括本章
> 本章是 SQL 的"中级篇"：在 [[Ch3 Intro to Sql|Ch3 基础查询]]之上补 **七块工程能力**——**连接表达式**（更省事的多表拼接）、**视图**（虚拟表：安全 + 逻辑独立性）、**事务**（全做或全不做）、**完整性约束**（数据不烂的底线）、**数据类型**（怎么存）、**索引**（怎么快）、**授权**（谁能干什么）。
> 全章主线只有一句话：**把"数据可信、可控、可维护"的规则从应用程序搬进数据库，由 DBMS 自动、强制、无一遗漏地执行**。

> [!SUMMARY]+ Table of Contents
> - [[Ch4 Intermediate SQL#1 连接表达式（Join Expressions）|1 连接表达式（Join Expressions）]]
>     - [[Ch4 Intermediate SQL#1.1 连接的通用模型：连接条件与连接类型|1.1 连接的通用模型：连接条件与连接类型]]
>     - [[Ch4 Intermediate SQL#1.2 自然连接（Natural Join）|1.2 自然连接（Natural Join）]]
>     - [[Ch4 Intermediate SQL#1.3 自然连接的危险|1.3 自然连接的危险]]
>     - [[Ch4 Intermediate SQL#1.4 连接条件的三种写法：NATURAL / USING / ON|1.4 连接条件的三种写法：NATURAL / USING / ON]]
>     - [[Ch4 Intermediate SQL#1.5 外连接（Outer Join）|1.5 外连接（Outer Join）]]
>     - [[Ch4 Intermediate SQL#1.6 连接家族全景对比|1.6 连接家族全景对比]]
> - [[Ch4 Intermediate SQL#2 视图（Views）|2 视图（Views）]]
>     - [[Ch4 Intermediate SQL#2.1 为什么需要视图|2.1 为什么需要视图]]
>     - [[Ch4 Intermediate SQL#2.2 视图的定义与使用|2.2 视图的定义与使用]]
>     - [[Ch4 Intermediate SQL#2.3 视图套视图：依赖与视图展开|2.3 视图套视图：依赖与视图展开]]
>     - [[Ch4 Intermediate SQL#2.4 物化视图（Materialized View）|2.4 物化视图（Materialized View）]]
>     - [[Ch4 Intermediate SQL#2.5 视图更新（Update of a View）|2.5 视图更新（Update of a View）]]
>     - [[Ch4 Intermediate SQL#2.6 视图、物化视图、派生表与 CTE 对比|2.6 视图、物化视图、派生表与 CTE 对比]]
> - [[Ch4 Intermediate SQL#3 事务（Transactions）|3 事务（Transactions）]]
>     - [[Ch4 Intermediate SQL#3.1 事务：工作的原子单位|3.1 事务：工作的原子单位]]
>     - [[Ch4 Intermediate SQL#3.2 事务边界：隐式开始，显式结束|3.2 事务边界：隐式开始，显式结束]]
>     - [[Ch4 Intermediate SQL#3.3 原子性与隔离性|3.3 原子性与隔离性]]
> - [[Ch4 Intermediate SQL#4 完整性约束（Integrity Constraints）|4 完整性约束（Integrity Constraints）]]
>     - [[Ch4 Intermediate SQL#4.1 完整性约束的作用与分类|4.1 完整性约束的作用与分类]]
>     - [[Ch4 Intermediate SQL#4.2 单关系约束：NOT NULL、PRIMARY KEY、UNIQUE、CHECK|4.2 单关系约束：NOT NULL、PRIMARY KEY、UNIQUE、CHECK]]
>     - [[Ch4 Intermediate SQL#4.3 参照完整性：FOREIGN KEY|4.3 参照完整性：FOREIGN KEY]]
>     - [[Ch4 Intermediate SQL#4.4 引用动作：CASCADE、SET NULL、SET DEFAULT|4.4 引用动作：CASCADE、SET NULL、SET DEFAULT]]
>     - [[Ch4 Intermediate SQL#4.5 事务中的约束检查与延迟检查|4.5 事务中的约束检查与延迟检查]]
>     - [[Ch4 Intermediate SQL#4.6 复杂 CHECK 条件（含子查询）|4.6 复杂 CHECK 条件（含子查询）]]
>     - [[Ch4 Intermediate SQL#4.7 断言（ASSERTION）|4.7 断言（ASSERTION）]]
> - [[Ch4 Intermediate SQL#5 SQL 数据类型与 Schema|5 SQL 数据类型与 Schema]]
>     - [[Ch4 Intermediate SQL#5.1 日期时间类型（DATE、TIME、TIMESTAMP、INTERVAL）|5.1 日期时间类型（DATE、TIME、TIMESTAMP、INTERVAL）]]
>     - [[Ch4 Intermediate SQL#5.2 大对象类型（BLOB、CLOB）|5.2 大对象类型（BLOB、CLOB）]]
>     - [[Ch4 Intermediate SQL#5.3 用户自定义类型（CREATE TYPE）|5.3 用户自定义类型（CREATE TYPE）]]
>     - [[Ch4 Intermediate SQL#5.4 域（CREATE DOMAIN）|5.4 域（CREATE DOMAIN）]]
> - [[Ch4 Intermediate SQL#6 索引定义（Index）|6 索引定义（Index）]]
>     - [[Ch4 Intermediate SQL#6.1 索引的动机与定义|6.1 索引的动机与定义]]
>     - [[Ch4 Intermediate SQL#6.2 索引的创建与细节|6.2 索引的创建与细节]]
> - [[Ch4 Intermediate SQL#7 授权（Authorization）|7 授权（Authorization）]]
>     - [[Ch4 Intermediate SQL#7.1 权限总览|7.1 权限总览]]
>     - [[Ch4 Intermediate SQL#7.2 GRANT：授予权限|7.2 GRANT：授予权限]]
>     - [[Ch4 Intermediate SQL#7.3 REVOKE：撤销权限|7.3 REVOKE：撤销权限]]
>     - [[Ch4 Intermediate SQL#7.4 角色（ROLE）|7.4 角色（ROLE）]]
>     - [[Ch4 Intermediate SQL#7.5 视图与授权|7.5 视图与授权]]
>     - [[Ch4 Intermediate SQL#7.6 授权的转移：WITH GRANT OPTION、CASCADE 与 RESTRICT|7.6 授权的转移：WITH GRANT OPTION、CASCADE 与 RESTRICT]]
>     - [[Ch4 Intermediate SQL#7.7 REFERENCES 权限|7.7 REFERENCES 权限]]
> - [[Ch4 Intermediate SQL#8 本章重难点与易错点汇总|8 本章重难点与易错点汇总]]
> - [[Ch4 Intermediate SQL#9 综合例题（难度偏高）|9 综合例题（难度偏高）]]
> - [[Ch4 Intermediate SQL#10 知识点速查|10 知识点速查]]
>     - [[Ch4 Intermediate SQL#核心思想总结|核心思想总结]]

---

## 1 连接表达式（Join Expressions）

### 1.1 连接的通用模型：连接条件与连接类型

**通俗理解**：所谓"连接"，就是把两张表**按规则拼成一张大表**。规则分两半：

- **谁和谁算一对**（行怎么配）→ 叫**连接条件**（join condition）；
- **配不上的人怎么办**（未匹配行的去留）→ 叫**连接类型**（join type）。

好比相亲：条件是"三观合得来"，类型决定"没配上的人是直接离场（inner），还是留在场上、旁边位置记 NULL（outer）"

**严谨说明**（课件原文定义）：

| 概念 | 定义 | 决定什么 |
|---|---|---|
| **Join condition（连接条件）** | 定义两个关系中**哪些元组彼此匹配**，以及结果中出现哪些属性 | 决定结果的**行**（以及列） |
| **Join type（连接类型）** | 定义在给定连接条件下，各自关系中**未与对方任何元组匹配的元组**如何处理 | 决定**未匹配行**的命运 |

从关系代数看，任何连接都是"笛卡尔积 + 谓词筛选 + 列取舍"：

$$R \bowtie_{\theta} S \;=\; \sigma_{\theta}(R \times S)$$

其中 $\theta$ 就是连接条件；连接类型只在"未匹配元组"的处理上与上式产生差异（见 [[#1.5 外连接（Outer Join）|1.5]]）。**inner join 就是上式本身，outer join = 上式 ∪ 补 NULL 的未匹配行**。

> [!tip] 连接表达式出现在哪
> 课件原话：连接操作 "typically used as subquery expressions in the from clause"——即 `from` 里能放的不只是表名，还可以放**子查询**和**连接表达式**。这解释了为什么 `from A join B on ...` 后面还能继续 `join C on ...` 一路链下去。

---

### 1.2 自然连接（Natural Join）

**通俗理解**：自然连接 = "**自动找出两张表的所有同名列，要求它们的值全部相等，然后把同名列合并成一列**"。你不用告诉它按什么连，它自己找同名字段。

**严谨定义**：设 $com(R,S)$ 为 $R$ 与 $S$ 的公共属性（同名列）集合，则

$$R \bowtie S \;=\; \pi_{A_1,\dots,A_k}\!\Big(\sigma_{\theta}(R \times S)\Big), \qquad \theta \equiv \bigwedge_{A \in com(R,S)} R.A = S.A$$

三个要点，一个都不能少：

1. **匹配条件 = 所有公共属性逐一相等**（自动推断，无法选择、无法关掉）；
2. **结果中每个公共属性只保留一份**（合列，不会出现两个 `course_id`）；
3. 结果仍是一个关系（去向：可继续参与连接、可被投影选择）。

**例子**（课件 P4–P8）：列出教师姓名及其所教课程的 course id——本质上是 `student` 与 `takes` 按 `ID` 配对：

```sql
-- 传统写法：逗号连接 + where 指定条件
select name, course_id
from student, takes
where student.ID = takes.ID;

-- 自然连接写法：同名列只有 ID，自动等值 + 合列
select name, course_id
from student natural join takes;
```

![[Ch4-img-06-student.jpeg|471]] ![[Ch4-img-07-takes.jpeg|426]]

![[Ch4-img-08-natural-join.jpeg|574]]

多表可以链式书写（课件 P5 的通用模板）：

```sql
select A1, A2, ..., An
from r1 natural join r2 natural join ... natural join rn
where P;
```

> [!warning] 易错点 1：NULL 永远配不上
> 连接条件底层用 `=` 比较，而 `null = null` 的结果是 **unknown**（见 [[Ch3 Intro to Sql#5 空值 NULL 与三值逻辑|Ch3 三值逻辑]]）。所以**只要公共列里有 NULL，该行就永远参与不了自然连接**，会被 inner 类连接静默丢掉——这是外连接存在的根本原因之一。

> [!warning] 易错点 2：同名列 ≠ 同语义列
> 自然连接只看**列名**，完全不懂**语义**。两张毫不相干的表只要都叫 `dept_name`、`year`、`name`，就会被强行等值——下一节的"危险"正是由此而来。

---

### 1.3 自然连接的危险

**通俗理解**：自然连接是"按名字认亲戚"，可**同名不代表同义**。把不该相等的列强行相等，结果就是**静默丢行**——查询不报错、不警告，只是结果悄悄少了几行，这是最阴险的一类 bug

**课件案例**（P9）：列出学生姓名与他所修课程的课程名。三个关系的列：

| 关系 | 列 |
|---|---|
| `student` | ID, name, **dept_name**, tot_cred |
| `takes` | ID, course_id, ... |
| `course` | course_id, title, **dept_name**, credits |

```sql
-- ❌ 错误版本：链式自然连接
select name, title
from student natural join takes natural join course;

-- ✅ 正确版本：course 改用显式连接条件
select name, title
from student natural join takes, course
where takes.course_id = course.course_id;
```

**错在哪**：`(student natural join takes)` 的结果与 `course` 的公共列有**两列**——`course_id`（应该相等）和 `dept_name`（不该相等！）。自然连接把"$\text{学生的系} = \text{课程的系}$"也当成了匹配条件，于是**所有"本系学生选修外系课程"的 (姓名, 课程名) 对都被丢掉了**；正确版本则能正常输出这些对。

> [!important] 记忆口诀
> **natural join 的本质 = 把所有同名列全部写成 `=`**。所以用它之前先自问一句："这两张表的所有同名列，**全都**应该相等吗？"只要有一个"不该等"，就改用 `on` / `using` 显式指定。

> [!tip] 工程实践
> 课件给出的正确版本里，`student natural join takes` 之所以安全，是因为这两个表的公共列**恰好只有 `ID` 且语义一致**。生产代码中更稳妥的做法是**全部写 `on`**，把匹配条件摆在明面上——自然连接的"自动"正是错误的温床。

---

### 1.4 连接条件的三种写法：NATURAL / USING / ON

**通俗理解**：告诉数据库"按什么连"有三种办法：**完全不说**（natural，它自己猜）、**点名几列**（using）、**写完整条件**（on，想怎么写就怎么写）。三者匹配的"行"可能一样，但**输出的"列"不一样**

| 写法 | 条件来源 | 输出列 | 表达力 |
|---|---|---|---|
| `natural join` | 所有同名列（自动） | 同名列合并为一列 | 只能等值，且无法选择、无法增删 |
| `join ... using (a, b)` | 指定列相等 | 指定列合并为一列 | 只能等值，但**由你点名** |
| `join ... on P` | 任意谓词 `P` | **两表列全部保留**（含重复的 `course_id`、`prereq_id` 两列） | 任意比较（`>`、`<>`、`and/or`、跨列复合）皆可 |

在 `course` 与 `prereq`（公共列恰好只有 `course_id`）上，课件 P17–P18 的对照：

```sql
-- 内连接：on 写法 —— 结果里 course.course_id 和 prereq.course_id 是两列
select * from course inner join prereq on course.course_id = prereq.course_id;

-- 内连接：using 写法 —— course_id 合并为一列
select * from course inner join prereq using (course_id);

-- 内连接：自然连接 —— 在本例中与 using 等价（公共列恰好只有 course_id）
select * from course natural join prereq;

-- 传统写法：逗号连接 + where，等价于 inner join on
select * from course, prereq where course.course_id = prereq.course_id;
```

**课件 P17 的思考题：`inner join on` 与 `natural join` 有什么区别？** 答案就在上表：

1. **条件来源不同**：`on` 由你写明，`natural` 自动用掉**全部**同名列——一旦两表还共有别的同名列（例如假设 `prereq` 也加了 `dept_name`），`natural` 会**多要求一列相等，结果行变少**，而 `on` / `using` 不受影响；
2. **输出列不同**：`on` 保留两份 `course_id`，`natural` / `using` 只留一份。

> [!warning] 易错点：`on` 是连接的一部分，`where` 是连接之后的过滤
> 这在外连接里会引发质变（详见 1.5）：`on` 决定"谁算匹配"，**不会删除**补了 NULL 的保留行；而 `where` 是在补 NULL **之后**执行的过滤，NULL 参与比较永远是 unknown，会把刚保留下来的行全部筛掉。

---

### 1.5 外连接（Outer Join）

**通俗理解**：inner join 配不上就**扔行** → 信息丢失。外连接说："配不上的也留下，对面的列**补 NULL**。"

三种方向（课件 P10）：

| 形式 | 关系代数记号 | 保留谁 |
|---|---|---|
| left outer join | $R\ \text{⟕}\ S$ | 左表所有行（右边补 NULL） |
| right outer join | $R\ \text{⟖}\ S$ | 右表所有行（左边补 NULL） |
| full outer join | $R\ \text{⟗}\ S$ | 两表所有行（缺的补 NULL） |

**严谨定义**（设 $\theta$ 为连接条件，$\mathrm{null}_S$ 表示 $S$ 的所有属性均取 NULL 的"空元组"）：

$$
\begin{aligned}
R\ \text{LEFT OUTER}_{\theta}\ S &= \sigma_{\theta}(R \times S)\;\cup\;\{\, r \cup \mathrm{null}_S \mid r \in R,\ \nexists s \in S:\theta(r,s) \,\}\\[4pt]
R\ \text{RIGHT OUTER}_{\theta}\ S &= \sigma_{\theta}(R \times S)\;\cup\;\{\, \mathrm{null}_R \cup s \mid s \in S,\ \nexists r \in R:\theta(r,s) \,\}\\[4pt]
R\ \text{FULL OUTER}_{\theta}\ S &= R\ \text{LEFT OUTER}_{\theta}\ S\;\cup\;R\ \text{RIGHT OUTER}_{\theta}\ S
\end{aligned}
$$

也就是说：**外连接 = 内连接结果 ∪（单方未匹配元组补 NULL）**，方向只决定"保哪一边"，full 两个都保。

**课件例子**（P11–P14）：`course` 与 `prereq`，其中 `prereq` 里有一行 `CS-437` 在 `course` 中**没有对应课程**（course 信息缺失），`course` 里有一门 `CS-315` **没有任何先修课记录**（prereq 信息缺失）

![[Ch4-img-11-course.jpeg]] ![[Ch4-img-11-prereq.jpeg]]

```sql
-- 左外连接：三门课全保留，CS-315 / CS-190 的先修列补 NULL
select * from course natural left outer join prereq;
```

![[Ch4-img-12-left-outer.jpeg]]

```sql
-- 右外连接：两条先修记录全保留，CS-437 的课程信息补 NULL
select * from course natural right outer join prereq;
```

![[Ch4-img-13-right-outer.jpeg]]

```sql
-- 全外连接：两边未匹配的都保留
select * from course natural full outer join prereq;
```

![[Ch4-img-14-full-outer.jpeg]]

**语法**：`natural` / `using` / `on` 可与三种外连接任意组合，注意词序——`natural` 在最前：

```sql
R natural left outer join S
R left outer join S on P
R left outer join S using (a)
R full outer join S on P
```

> [!warning] 本章最大的陷阱：`on` 条件与 `where` 条件在外连接中的天壤之别
>
> ```sql
> -- A. on 只决定"谁算匹配"，左表配不上的行照样保留（补 NULL）→ 仍是左外连接语义
> select * from course left outer join prereq
>     on course.course_id = prereq.course_id;
>
> -- B. 想找"没有先修课的课程"：补完 NULL 后用 is null 把它们捞出来 ✅
> select * from course left outer join prereq
>     on course.course_id = prereq.course_id
>    where prereq.course_id is null;
>
> -- C. ❌ 如果把匹配条件（或任何引用右表列的等值条件）写进 where：
> select * from course left outer join prereq
>     on course.course_id = prereq.course_id
>    where course.course_id = prereq.course_id;   -- 或 where prereq.course_id = 'CS-190'
> ```
>
> C 的后果：先按左外连接补出 NULL 行，`where` 再做等值比较——`NULL = 任何值` 是 unknown，**刚保留下来的未匹配行被全部过滤**，左外连接**退化成内连接**，外连接的"保行"意义归零。
> **判断铁律**：补 NULL 之后，凡是在 `where` 里拿右表（或左表）的列做普通比较的行，都会被三值逻辑杀掉；要留住它们只能用 `is null` / `is not null`。

> [!tip] `natural ... using` 与 `on` 的 NULL 细节
> `using (a)` 与 `natural` 合并后的单列，在"未匹配补 NULL"场景下同样只有一份；`is null` 判定的就是这合并后的一列，不会出现"判错列"的问题。而 `on` 写法保留两列，`is null` 必须**指明判右表那一列**（`prereq.course_id is null`）——判成左表的列会得到完全相反的结果。

---

### 1.6 连接家族全景对比

| 写法 | 匹配条件 | 未匹配行 | 结果列 |
|---|---|---|---|
| `R, S`（逗号，即 cross join） | 无（笛卡尔积 $R \times S$） | 不存在"未匹配"概念 | 两表全保留 |
| `R inner join S on P` | 显式谓词 P | **丢弃** | 两表全保留（列名可重复） |
| `R inner join S using (a)` | 指定列相等 | 丢弃 | a 合并一列 |
| `R natural join S` | 全部同名列相等 | 丢弃 | 同名列合并一列 |
| `left outer join`（条件三选一） | 同上任一 | **左表未匹配 → 保留 + 右侧补 NULL** | 视条件写法而定 |
| `right outer join` | 同上任一 | 右表未匹配 → 保留 + 左侧补 NULL | 同上 |
| `full outer join` | 同上任一 | 两边未匹配 → 都保留 + 补 NULL | 同上 |

**SQL 与关系代数对照**（衔接 [[Ch2 关系模型导论|Ch2 关系代数]]）：

| SQL 写法                           | 关系代数                                                   |
| -------------------------------- | ------------------------------------------------------ |
| `R, S`                           | $R \times S$                                           |
| `R inner join S on P`            | $\sigma_P(R \times S)$                                 |
| `R natural join S`               | $R \bowtie S$                                          |
| `R left/right/full outer join S` | $R\ \text{⟕}\ S$ / $R\ \text{⟖}\ S$ / $R\ \text{⟗}\ S$ |

**一道速判题**：`course` 与 `prereq` 各有 3 行、2 行（公共列 `course_id`）——笛卡尔积 6 行，inner join 1 行，left outer 3 行，right outer 2 行，full outer 4 行。行数怎么来的，手算一遍就懂（见 [[#9 综合例题（难度偏高）|例题 2]]）。

![[Ch4-img-15-join-dimensions.jpeg]]

![[Ch4-img-16-right-using.jpeg]] ![[Ch4-img-16-full-using.jpeg]]

![[Ch4-img-17-inner-on.jpeg]] ![[Ch4-img-17-left-on.jpeg]]

---

## 2 视图（Views）

### 2.1 为什么需要视图

**通俗理解**：不是所有人都该看见全部数据——财务能看工资，普通教师不能；报表读者只关心三个字段。**视图 = 数据库里的"滤镜/窗口"**：底表不动，给不同的人开不同窗口。

**严谨定义**（课件 P19）：任何**不属于概念模型**（不是实际存储的基本关系）、但以**"虚拟关系"（virtual relation）** 形式对用户可见的关系，称为一个**视图（view）**。

视图解决两类问题：

| 动机 | 说明 |
|---|---|
| **安全性（隐藏数据）** | 只需姓名和系、不需工资的人，给他看 `select ID, name, dept_name from instructor` 定义的窗口，而非整张 `instructor` |
| **逻辑独立性（简化）** | 常用的多表连接/聚合查询起个名字反复使用；底层模式改变时只改视图定义，外部查询一行不动 |

> [!important] 视图存的是"表达式"，不是"结果"
> 普通视图**不占数据存储、不保存查询结果**——它只是一段被保存的查询表达式，每次用到时现场代入计算。因此**基表一变，视图立刻变**（永远最新）。想要"存结果"的是物化视图，见 [[#2.4 物化视图（Materialized View）|2.4]]。

---

### 2.2 视图的定义与使用

**语法骨架**（课件 P20）：

```sql
create view v as <query expression>;   -- query expression 是任意合法 SQL 查询表达式
```

**严谨说明**：视图定义 ≠ "求值查询并创建新关系"；它是**保存表达式**，之后任何引用 `v` 的查询都会被**代入该表达式**（substitution）——视图本质上是数据库级的"宏"。

**例子**（课件 P21）：

```sql
-- ① 隐藏 salary 的视图
create view faculty as
select ID, name, dept_name
from instructor;

-- 使用方式与普通表完全相同
select name from faculty where dept_name = 'Biology';

-- ② 聚合视图：必须显式给计算列命名（select 列表有聚合/表达式时必须起名）
create view departments_total_salary(dept_name, total_salary) as
select dept_name, sum(salary)
from instructor
group by dept_name;
```

要点：

- 视图的**列名** = 查询选择列表的列名；含 `sum(...)` 这类表达式时**必须**用 `v(col1, col2, ...)` 显式命名；
- 视图一旦定义，**在任何查询中与基本表同等待遇**（可以出现在 `from`、可以继续 join、可以被授权）；
- `drop view v` 删除定义（不影响数据）。

> [!tip] 视图 vs 子查询
> 视图能做的，`with`（CTE）或 FROM 子查询往往也能做——但它们是"一次性、语句内"的匿名临时物；视图是**命名的、存在数据库里、可跨语句复用、可单独授权**的 schema 对象。这是"起名字 + 发钥匙"带来的本质差异。

---

### 2.3 视图套视图：依赖与视图展开

**通俗理解**：视图可以建在视图之上（就像宏套宏）。要搞清一个视图到底在算什么，就不断把"宏定义"替换进去，直到里面**只剩基本表**——这个过程叫**视图展开（view expansion）**。

**严谨定义**（课件 P22–P25）：

- **直接依赖**：定义 $v_1$ 的表达式中用到了视图 $v_2$ → $v_1$ **直接依赖** $v_2$；
- **依赖（传递）**：$v_1$ 直接依赖 $v_2$，或存在从 $v_1$ 到 $v_2$ 的依赖路径 → $v_1$ **依赖** $v_2$；
- **递归视图**：$v$ 依赖它**自己** → 称 $v$ 是 recursive 的。

**展开算法**（课件原文，反复替换直到没有视图）：

```text
repeat
    在表达式 e 中找到任意一个视图关系 vi
    把 e 中的 vi 替换为定义 vi 的表达式
until e 中不再含任何视图关系
```

**例子**（课件 P23–P24）：先定义 `physics_fall_2017`，再在其上定义 `physics_fall_2017_watson`；展开后者得到只含 `course`、`section` 基本表的等价查询：

```sql
-- 展开前
create view physics_fall_2017_watson as
select course_id, room_number
from physics_fall_2017
where building = 'Watson';

-- 展开后（把 physics_fall_2017 的定义整体代入，外层谓词原样保留）
create view physics_fall_2017_watson as
select course_id, room_number
from ( select course.course_id, sec_id, building, room_number
       from course, section
       where course.course_id = section.course_id
         and course.dept_name = 'Physics'
         and section.semester = 'Fall'
         and section.year = '2017' )
where building = 'Watson';
```

**终止性**：只要视图定义**不递归**（不存在依赖环），每次替换都让"视图数"减少，循环必然终止；一旦 $v$ 依赖自己，**展开过程永不结束**——即**递归视图无法用"展开"来定义语义**。注意：SQL:1999 起**允许**递归视图定义，它的语义由**不动点**给出（反复迭代到结果稳定，见 [[Ch5 Advanced SQL#4 递归查询（Recursive Queries）|Ch5 §4 递归查询]]），而不是靠展开；展开算法管不到它。

> [!warning] 易错点：展开 = "整体代入"，不是"条件随便合并"
> 直觉上你会想把 `building = 'Watson'` 直接并进最内层的 `where`——本例恰好等价（该列在内层可见、且中间没有改变"行与结果对应关系"的算子）。但**一般情况下不等价**：若内层含 `group by` / 聚合 / `distinct`，"先过滤再聚合"与"先聚合再过滤"是两回事。所以课件的算法统一用**派生表整体替换**（如上例的 `from ( ... ) where ...`），这是一条永远安全的展开策略。

---

### 2.4 物化视图（Materialized View）

**通俗理解**：普通视图是"每次都现场算的滤镜"，物化视图是**把滤镜结果截图存成一张真表**——查询飞快，但**截图会过期**。

**严谨定义**（课件 P26）：

- 某些数据库系统允许视图关系被**物理存储**：视图定义时创建**物理副本** → 称为**物化视图（materialized view）**；
- 一旦定义它的基本关系被更新，物化视图的结果就**过期（out of date）** → 必须**维护**：或在底表更新时同步更新视图，或延迟到查询时增量刷新（维护策略是查询处理章节的主题）。

| | 普通视图 | 物化视图 | 基本表 |
|---|---|---|---|
| 是否存储数据 | ❌ 只存表达式 | ✅ 存结果副本 | ✅ 存数据本身 |
| 查询时计算 | 每次现场代入 | 直接读（或按需刷新） | 直接读 |
| 底表更新后 | 自动最新 | **可能过期，需维护** | 就是它自己 |
| 额外代价 | 查询慢 | 存储 + 维护开销 | — |

---

### 2.5 视图更新（Update of a View）

**通俗理解**：往"滤镜"里插数据，最终得落到真表上——于是问题来了：**这条修改能不能唯一地翻译成对底表的修改？** 三种答案：能（补默认值）、多解（不知道改哪）、根本语义不成立。

**情形一：可翻译，但缺值**（课件 P27）——往 `faculty`（不含 salary）插一行：

```sql
insert into faculty values ('30765', 'Green', 'Music');
```

这条插入必须翻译成对 `instructor` 的插入，但 `salary` 没有值。两种处理（课件原文）：

1. **拒绝该插入**（reject the insert）；
2. 插入 `('30765', 'Green', 'Music', null)`——salary 补 NULL（前提是 salary 允许 NULL）。

**情形二：无法唯一翻译**（课件 P28–P29）——视图跨了两张表：

```sql
create view instructor_info as
select ID, name, building
from instructor, department
where instructor.dept_name = department.dept_name;

insert into instructor_info values ('69987', 'White', 'Taylor');
```

两个致命歧义（课件原文）：

- Taylor 楼里若有**多个系**，这条插入该归属哪个系？（**多解**）
- Taylor 楼里若**一个系都没有**，`dept_name` 填什么？（**无解**）

**情形三：语义根本不成立**（课件 P29–P30）——插入违反视图自身条件的行：

```sql
create view history_instructors as
select * from instructor
where dept_name = 'History';

insert into history_instructors values ('25566', 'Brown', 'Biology', 100000);
```

课件的追问："What happens?"——这条 Biology 教员一旦进入 `instructor`，**永远不会出现在该视图里**，即"通过视图插入了视图自己都看不见的行"，更新语义失效。课件把它归为"根本无法正确翻译的更新"。

> [!tip] 补充：`with check option` 让"情形三"有明确答案
> SQL 标准提供 `create view v as <query> with check option`：带此选项后，**凡不满足视图定义条件（WHERE）的插入/更新一律被拒绝**——这正是"情形三"的工程解法。未加该选项时行为依实现而定（可能插入一条视图永远查不到的行），因此**对带 WHERE 的可更新视图，建议总是加上 `with check option`**。

**什么时候允许更新：可更新简单视图的四个条件**（课件 P30，"most SQL implementations allow updates only on simple views"）：

1. `from` 子句中**只有一个**数据库关系；
2. `select` 列表只含该关系的**纯属性名**——不含表达式、聚合、`distinct`；
3. `select` 列表中**未列出**的属性必须能被置为 NULL（即允许补默认/NULL 值）；
4. 没有 `group by`、没有 `having`。

口诀：**一表、纯列、可空补、无分组**。

> [!warning] 易错点：满足四条件 ≠ 语义上就该更新
> `history_instructors` 满足全部四条（单表、纯列、无分组），语法上"可更新"——但插入违反 WHERE 的行仍是语义荒谬的（情形三）。**四条件是"能不能翻译"的语法门槛，不是"该不该允许"的语义保证**；语义问题靠 `with check option` 兜底。

**三情形总结**：

| 情形 | 例子 | 问题本质 | 典型处理 |
|---|---|---|---|
| 可唯一翻译 | `faculty` | 未列出的列缺值 | 拒绝，或补 NULL |
| 无法唯一翻译 | `instructor_info`（两表） | 多解 / 无解 | 拒绝 |
| 语义不成立 | `history_instructors` | 插入违反视图谓词 | 拒绝（`with check option` 强制拒绝） |

---

### 2.6 视图、物化视图、派生表与 CTE 对比

**通俗理解**：四种"虚拟表"各有分工——**视图**是"起好名字放进数据库的表定义"，**物化视图**是"存了结果的视图"，**派生表**是"写在 from 里的临时子查询"，**CTE（with）**是"一条语句内的具名临时结果"。

| | 普通视图 | 物化视图 | 派生表（FROM 子查询） | CTE（`with`） |
|---|---|---|---|---|
| 定义位置 | schema（`create view`） | schema | 单条语句内 | 单条语句内 |
| 命名/跨语句复用 | ✅ | ✅ | ❌ 匿名 | ❌ 语句内命名 |
| 存储数据 | ❌ | ✅ | ❌ | ❌ |
| 可单独授权 | ✅（见 [[#7.5 视图与授权|7.5]]） | ✅ | ❌ | ❌ |
| 可更新性 | 受四条件限制 | 一般只读 | 一般不可直接更新 | 一般只读 |
| 底表更新后 | 自动最新 | 需维护刷新 | 现场计算 | 现场计算 |

---

## 3 事务（Transactions）

### 3.1 事务：工作的原子单位

**通俗理解**：转账 = "A 少 1000" + "B 多 1000" 两步。若中间断电只执行了前半，钱就凭空消失了。**事务（transaction）就是把多条语句捆成"要么全做、要么全不做"的一个原子单位**。

**严谨定义**（课件 P31）：一个事务由**一串查询和/或更新语句**组成，是**工作的"单位"（unit of work）**。

### 3.2 事务边界：隐式开始，显式结束

| 规则 | 课件原文语义 |
|---|---|
| **开始** | SQL 标准规定：**执行任何 SQL 语句时，事务隐式开始**（no explicit "begin" required） |
| **结束（二选一，必须显式）** | `commit work`——事务的更新**永久化**（permanent） |
| | `rollback work`——事务内**全部更新被撤销**（undone） |

```sql
update account set balance = balance - 1000 where acc_no = 'A';
update account set balance = balance + 1000 where acc_no = 'B';
commit work;     -- 两条一起生效；不 commit 而崩溃 → rollback，两条都不生效
```

> [!warning] 易错点：`rollback` 是事务级撤销，不是语句级
> `rollback work` 撤销的是**整个事务**里做过的所有修改，**无法只撤最后一条**。想"保留前面、放弃后面"，唯一办法是先 `commit work` 结束当前事务，再开始新的事务。
>
> 补充（工程实践）：标准要求事务以 `commit`/`rollback` 显式结束；很多 DBMS 为了方便提供 **autocommit**（每条语句自成事务）或"会话断开时自动回滚未提交事务"——答题以课件语义为准，写代码时必须清楚自己关没关 autocommit。

### 3.3 原子性与隔离性

课件点名了事务的两条性质：

- **原子事务（atomic transaction）**：**要么完全执行，要么回滚得仿佛从未发生**（either fully executed or rolled back as if it never occurred）；
- **隔离（isolation from concurrent transactions）**：事务之间相互隔离，一个事务看不到另一个事务"做到一半"的中间状态。

> [!info] 本章只是"预告"
> 事务的完整故事（ACID 四性质、并发调度、可串行化、锁与 MVCC、故障恢复）在教材的事务处理章节展开。**本章只需记牢两件事：隐式开始、必须 commit/rollback 收尾**。

---

## 4 完整性约束（Integrity Constraints）

### 4.1 完整性约束的作用与分类

**通俗理解**：约束是数据库的**底线规则**——余额不能低于 0、工资不能是 1 块钱、电话不能为空。没有约束时，"合法用户执行合法操作"也能把数据改烂；有了约束，DBMS 在**每次修改的瞬间**自动拦截。

**严谨定义**（课件 P32）：完整性约束**防止对数据库的意外破坏**——确保**被授权的修改**不会导致**数据一致性丧失**（guard against accidental damage, by ensuring that authorized changes do not result in a loss of data consistency）。教材例子：支票账户余额须 > $10,000；银行员工时薪须 ≥ $4.00；客户必须有非空电话号。

**分类**：

| 类别 | 覆盖节 | 作用范围 |
|---|---|---|
| 单关系约束（not null / primary key / unique / check） | [[#4.2 单关系约束：NOT NULL、PRIMARY KEY、UNIQUE、CHECK\|4.2]] | 一张表内部 |
| 参照完整性（foreign key） | [[#4.3 参照完整性：FOREIGN KEY\|4.3]] | 跨表引用 |
| 断言（assertion） | [[#4.7 断言（ASSERTION）\|4.7]] | 任意复杂的全局命题 |

> [!important] 为什么约束必须由 DBMS 执行
> 应用程序检查靠的是"每个入口都记得检查"——只要有一个入口漏了（另一条路径、手工改库、并发竞态），数据就烂了。约束写进 schema，**DBMS 保证无一入口遗漏**，且约束与数据同生命周期、同时生效。

---

### 4.2 单关系约束：NOT NULL、PRIMARY KEY、UNIQUE、CHECK

**通俗理解**：一张表内部的四条家规——"这列必须填"（not null）、"这列是身份证号"（primary key）、"这列别重复"（unique）、"值必须满足某条件"（check）。

```sql
create table department (
    dept_name varchar(20) primary key,
    building  varchar(15) not null,
    budget    numeric(12,2) not null check (budget > 0)
);
```

#### NOT NULL

- **含义**：该列的每个元组都必须有值（不允许 NULL）；
- 课件例子：`name varchar(20) not null`、`budget numeric(12,2) not null`。

#### PRIMARY KEY

- **含义**：主键 = 候选键的"钦定代表"，同时蕴含 **UNIQUE + NOT NULL** 双重约束；
- 关系 $R$ 的主键 $K$：

$$\forall\, t \in R,\ \forall A \in K:\ t[A] \neq \mathrm{null} \qquad\wedge\qquad \forall\, t_1 \neq t_2 \in R:\ \exists A \in K:\ t_1[A] \neq t_2[A]$$

#### UNIQUE

- **含义**（课件 P35 原文）：`unique (A1, ..., Am)` 声明这组属性构成**候选键**；**候选键允许为 NULL——这与主键不同**（candidate keys are permitted to be null, in contrast to primary keys）；
- 形式化：

$$\forall\, t_1 \neq t_2 \in R:\ \bigvee_{A \in K} t_1[A] \neq t_2[A]$$

> [!warning] 易错点：UNIQUE 与 PRIMARY KEY 对 NULL 的态度相反
> - **主键列：绝不允许 NULL**；
> - **UNIQUE 列：允许 NULL**（NULL 不参与等值比较，多个 NULL 互不"相等"，所以多数 DBMS 允许该列出现多行 NULL——**不要依赖 UNIQUE 给 NULL 判重**，判重请自己加 `is not null` 或额外约束）；
> - 个别实现（如 Oracle 的唯一索引）把 NULL 视为相等，**只允许一个 NULL**——跨平台代码不要赌这个行为；
> - 一张表可以有**多个** unique 约束，但只有**一个**主键。

#### CHECK (P)

- **含义**（课件 P36）：`check (P)` 规定关系中**每个元组都必须满足谓词 P**：

$$\forall\, t \in R:\ P(t)$$

```sql
create table section (
    course_id varchar(8),
    sec_id    varchar(8),
    semester  varchar(6),
    year      numeric(4,0),
    building  varchar(15),
    room_number varchar(7),
    time_slot_id varchar(4),
    primary key (course_id, sec_id, semester, year),
    check (semester in ('Fall', 'Winter', 'Spring', 'Summer'))
);
```

> [!warning] 易错点（细节题高频）：CHECK 只在谓词为 **FALSE** 时判定违约
> 违约条件是 "$P$ 算出 **false**"；三值逻辑下 $P$ 为 **unknown** 时**不算违约**。因此：
> - `check (credits > 0)` **挡不住 NULL**——`NULL > 0` 是 unknown → 放行。想禁 NULL 必须**另外写 `not null`**；
> - 这条规则在 [[#4.7 断言（ASSERTION）|断言]]里会造成更隐蔽的漏洞（见例题 9）。

**四件套对比**：

| 约束 | 防什么 | NULL 允许？ | 数量限制 |
|---|---|---|---|
| `not null` | 缺值 | ❌（这正是它禁的） | 每列一个 |
| `primary key` | 缺值 + 重复 | ❌ | 每表一个（可多列组合） |
| `unique` | 重复 | ✅（一般实现允许多个 NULL） | 每表可多个 |
| `check (P)` | 不合法值 | P 为 unknown 时放行 ⚠️ | 每处一个，可多个 |

---

### 4.3 参照完整性：FOREIGN KEY

**通俗理解**：学生选的课必须**真实存在**——选课记录引用了 `course` 里没有的课号，就是"悬空引用"，报表一 join 就缺一块。**外键 = "我引用的东西必须在对方表里真实存在"**。

**严谨定义**（课件 P37）：设 $A$ 是一组属性，$R$、$S$ 都含 $A$，且 $A$ 是 $S$ 的主键。若 $R$ 中出现的任何 $A$ 值也必须出现在 $S$ 中，则称 $A$ 是 $R$ 的**外键（foreign key）**。形式化（仅对 $R.A$ 的**非空值**检查）：

$$\pi_A(R) \setminus \pi_A(S) = \emptyset \qquad\Longleftrightarrow\qquad \pi_A(R) \subseteq \pi_A(S)$$

教材直觉例子：若 `instructor` 某元组里出现系名 "Biology"，则 `department` 中必须存在 "Biology" 的元组。

**DDL 写法**（课件 P38）：

```sql
foreign key (dept_name) references department          -- 默认引用对方主键
foreign key (dept_name) references department (dept_name)  -- 显式指定被引用列
```

要点：

- 被引用列必须是对方的**主键或候选键（unique）**；
- 默认引用被引用表的**主键属性**；
- **FK 值允许 NULL** → 表示"暂不引用任何人"的可选引用（一旦填了就必须存在）；
- ⚠️ **检查是双向的**：
  - $R$ 插入/更新外键值时 → 查 $S$ 是否存在；
  - $S$ **删除/更新被引用值**时 → 查 $R$ 里还有谁在引用！→ 这就是 [[#4.4 引用动作：CASCADE、SET NULL、SET DEFAULT|4.4]] 要解决的问题。

---

### 4.4 引用动作：CASCADE、SET NULL、SET DEFAULT

**通俗理解**：父表的一行要被删除/修改，子表里引用它的行怎么办？四种策略（课件 P39）：

| 动作                      | 语义                    | 例子（`course` 引用 `department`）        |
| ----------------------- | --------------------- | ----------------------------------- |
| **默认：拒绝（reject）**       | 违反约束的操作**直接被拒**       | 还有课挂在 Biology 系 → 不许删 Biology 系     |
| `on delete cascade`     | 父行删除时**连带删掉**所有引用它的子行 | 删 Biology → 该系所有课程一并删除              |
| `on update cascade`     | 父键更新时**子行跟着改**        | 系改名 Biology → Biology→Bio，课表同步改     |
| `on delete set null`    | 子行的 FK 列**置 NULL**    | 删 Biology → 这些课的 `dept_name` 变 NULL |
| `on delete set default` | 子行 FK 列**置为预设默认值**    | 删 Biology → 课程归到默认系                 |
|                         |                       |                                     |

```sql
create table course (
    course_id varchar(8) primary key,
    title     varchar(50),
    dept_name varchar(20) not null,
    credits   numeric(2,0),
    foreign key (dept_name) references department
        on delete cascade
        on update cascade
);
```

> [!warning] 易错点 1：`set null` 与 `not null` 天生矛盾
> 上例若把 `dept_name` 声明为 `not null`，同时又写 `on delete set null`——删除父行时子行**要置 NULL 却不许 NULL** → 该置空操作本身违反约束，**删除最终被拒**（或实现直接报错）。**二者只能选一个**：要么去掉 `not null` 用 set null，要么改用 cascade / reject。

> [!warning] 易错点 2：默认动作是"拒绝"，不是"静默放过"
> 没写任何 `on delete` / `on update` 时，**任何会破坏引用关系的删除/更新都被拒绝**。看到"删除失败/更新失败"，第一反应：是不是有外键在守着。

> [!tip] 级联是会传播的
> `cascade` 之下若还有更下层的表（A→B→C），删除会沿链一路传播；设计时要当心**循环引用**（A 引用 B、B 又引用 A）导致删除死局——这是模式设计阶段就要避免的坑。

---

### 4.5 事务中的约束检查与延迟检查

**通俗理解**：约束什么时候查？**每条语句后立刻查（立即检查）** 还是 **事务提交时统一查（延迟检查）**？——遇到"自己引用自己"的表，立刻查会逼你写出反人类的插入顺序。

**课件案例**（P40）：家谱表，父母也是 person：

```sql
create table person (
    ID     char(10) primary key,
    name   char(40),
    mother char(10),
    father char(10),
    foreign key (father) references person(ID),
    foreign key (mother) references person(ID)
);
```

插入一个人时其父母必须已存在——而父母自己也是人，也要有父母……**鸡生蛋问题**。课件给出三种解法：

1. **先插父母、再插本人**（把插入顺序排成拓扑序）；
2. **初始把 father/mother 置 NULL，全部插完后再 update 补上**——⚠️ 若这两列声明了 `not null`，此路不通；
3. **延迟约束检查（defer constraint checking）**：先全插完，提交时再统一验证。

**延迟检查语法**（SQL 标准）：

```sql
-- 定义时声明可延迟（多数 DBMS 支持；MySQL 8.0 不支持 deferrable）
foreign key (father) references person(ID) deferrable initially deferred

-- 或在会话中切换检查时机
set constraints all deferred;    -- 此后改为提交时检查
```

| | 立即检查（immediate，默认） | 延迟检查（deferred） |
|---|---|---|
| 检查时机 | **每条语句执行后** | **`commit` 时**（或手动 `set constraints ... immediate`） |
| 中间状态 | 必须时刻合法 | 允许"事务内暂时违约"，提交时必须整体合法 |
| 适用场景 | 常规约束 | 自引用、循环引用、多表成组修改 |

> [!info] 关键理解
> **约束合法性的判断单位是"检查时机"**：deferred 不是"不检查"，而是把检查推迟到 `commit`——提交那一刻数据库整体仍必须合法；若事务以 `rollback` 结束，中间那些"违约"状态随事务一起消失，自然无需检查。

---

### 4.6 复杂 CHECK 条件（含子查询）

**通俗理解**：`check` 的谓词可以写得很复杂，甚至**引用别的表**——"每条开课记录的时段号，必须真的存在于时段表里"。

**课件例子**（P41）：

```sql
check (time_slot_id in (select time_slot_id from time_slot))
```

**逐层拆解这条约束的含义**：

1. `section` 每个元组的 `time_slot_id` 必须是 `time_slot` 里真实存在的时段标识；
2. ⚠️ **检查是双向的**——不只 `section` 插入/修改时要查，**当 `time_slot` 发生变化（某行被删/被改）导致引用悬空时，同样必须检查**。约束的成立依赖**两张表的每一次修改**；
3. **语义上它与外键完全等价**：

```sql
foreign key (time_slot_id) references time_slot(time_slot_id)  -- 等价写法
```

> [!tip] 为什么教材还教这种写法
> ① 外键只能表达"列值存在于对方主键/候选键"这一种形状；`check` + 子查询能表达**任意关系谓词**（如 `check (budget > (select avg(budget) from department))` 这类跨表比较）。② 但工程上，**能用外键就用外键**——DBMS 对外键有专门的维护通路与优化（配合 `on delete` 动作），而 `check` 里的子查询每次相关修改都要重新求值，**代价高且很多实现支持受限**。

---

### 4.7 断言（ASSERTION）

**通俗理解**：`check` 约束守的是"**这一行**"，外键守的是"**这两个值**"，而**断言守的是"整个数据库永远成立的一条命题"**——凡是"全库不变量"（涉及聚合、跨多表、逐行核对总账）都得用它。

**严谨定义**（课件 P42）：断言（assertion）是**表达"我们希望数据库始终满足的条件"的谓词**。

**语法**：

```sql
create assertion <assertion-name> check (<predicate>);
```

**课件给的两个典型断言**：

1. **学分对账**：每个学生元组的 `tot_cred` 必须等于其**成功修完**课程的学分总和；
2. **排课冲突**：一位教师不能在同一学期、同一时段在两个不同教室上课。

```sql
-- 断言 1：学分对账（coalesce 把 NULL 统一成 0，堵住三值逻辑漏洞）
create assertion tot_cred_consistent check (
    not exists (
        select * from student S
        where coalesce(S.tot_cred, 0) <> coalesce((
            select sum(C.credits)
            from takes T, course C
            where T.ID = S.ID and T.course_id = C.course_id
              and T.grade <> 'F' and T.grade is not null
        ), 0)
    )
);

-- 断言 2：同一教师同一学期同一时段不得占用两个不同教室
create assertion no_double_booking check (
    not exists (
        select *
        from teaches T1, section S1, teaches T2, section S2
        where T1.ID = T2.ID
          and T1.semester = T2.semester and T1.year = T2.year
          and S1.course_id = T1.course_id and S1.sec_id = T1.sec_id
          and S1.semester = T1.semester and S1.year = T1.year
          and S2.course_id = T2.course_id and S2.sec_id = T2.sec_id
          and S2.semester = T2.semester and S2.year = T2.year
          and S1.time_slot_id = S2.time_slot_id
          and (T1.course_id <> T2.course_id or T1.sec_id <> T2.sec_id)
          and (S1.building <> S2.building or S1.room_number <> S2.room_number)
    )
);
```

> [!warning] 易错点（本章最隐蔽的坑）：三值逻辑会让断言"睁眼瞎"
> `check (P)` **只在 P 为 false 时判定违约**，P 为 **unknown 不算违约**。若断言 1 偷懒写成 `where S.tot_cred <> (select sum(...))`：学生没选课 → `sum` 是 NULL → `5 <> NULL` = **unknown** → `where` 不选中该行 → **违规数据查不出来，断言形同虚设**。
> **对策**：断言里凡是可能接触 NULL 的比较，一律先 `coalesce(...)` 归一化，或用 `is [not] distinct from` 做 NULL 安全比较——**确保"真出错时谓词算出 false"，而不是 unknown**。

> [!info] 现实骨感
> 断言表达力最强，但**主流 DBMS 基本都不支持 `create assertion`**（教材也承认这点），工程上用**触发器**或"冗余列 + 同步维护"来实现同样的全局不变量。**考试要会写，落地要知道它常用不了。**

---

## 5 SQL 数据类型与 Schema

### 5.1 日期时间类型（DATE、TIME、TIMESTAMP、INTERVAL）

**通俗理解**：SQL 用四个类型覆盖"时刻"与"时长"——**date 记哪天、time 记几点几分几秒、timestamp 记"日期 + 时间"的完整时刻、interval 记一段时长**。时长能和时刻做加减，两个时刻相减得到时长。

| 类型 | 含义 | 字面量例子 |
|---|---|---|
| `date` | 年（4 位）、月、日 | `date '2005-7-27'` |
| `time` | 时、分、秒（可带小数秒） | `time '09:00:30'`、`time '09:00:30.75'` |
| `timestamp` | date + time 的完整时刻 | `timestamp '2005-7-27 09:00:30.75'` |
| `interval` | 一段时间（period of time） | `interval '1' day` |

**运算规则**（课件原文）：

- 两个 date/time/timestamp **相减 → 得到 interval**：`date '2005-7-27' - date '2004-7-27'` → 一段约 365 天的 interval；
- interval **可以加到** date/time/timestamp 上：`date '2005-7-27' + interval '1' day` → 新的日期时刻；
- 字面量书写：`interval '1' day`（数字与单位分开写）。

> [!warning] 易错点：月份加减的"月末钳制"
> `date '2005-1-31' + interval '1' month` 的结果是 **`2005-02-28`**，不是 3 月 3 日，也不是报错——SQL 标准规定：目标月没有"这一天"时，**取该月最后一天**。1 月 31 日 + 1 个月 − 1 天 ≠ 2 月 28 日（那是另一种算法），这是日期计算的经典细节题。
>
> 补充：不同实现对 `date + interval` 的**返回类型**可能不同（有的返回 `date`，有的返回 `timestamp`），跨系统移植时注意显式转换。

### 5.2 大对象类型（BLOB、CLOB）

**通俗理解**：照片、视频、CAD 文件这类"巨块"数据，不要混进普通行里——用专门的**大对象类型**存，且**查询只返回一个指针**，数据本身按需流式读取。

**严谨定义**（课件 P44）：

| 类型 | 全称 | 内容 |
|---|---|---|
| `blob` | binary large object | 一大团**不加解释的二进制数据**（怎么解释由**数据库之外的应用程序**负责） |
| `clob` | character large object | 一大团字符数据 |

- **关键机制**：查询返回大对象时，**返回的是指针（pointer）而非大对象本身**——避免把几十 MB 的数据在结果集里整体搬运。

### 5.3 用户自定义类型（CREATE TYPE）

**通俗理解**：`numeric(12,2)` 谁都能用——但"12 万美元"和"12 公斤"都是数字，编译器分不清。`create type` 让你**造一个新类型**，让"金额"和"重量"在类型层面就互不相通。

```sql
create type Dollars as numeric(12,2) final;

create table department (
    dept_name varchar(20),
    building  varchar(15),
    budget    Dollars          -- budget 从此"是 Dollars"，不再是裸 numeric
);
```

要点：

- `final`：该类型**不可再被继承**（SQL 标准中类型可有 `final` / `instantiable` 等修饰，`final` = 终结类，不允许真子类型）；
- **强类型**：`Dollars` 与 `numeric` 是不同类型，不能隐式混用/随意比较（需显式转换）——这正是类型存在的意义。

### 5.4 域（CREATE DOMAIN）

**通俗理解**：域 = "**给'类型 + 约束'起个名字**"——`degree_level` 本质还是字符串，但从此"只能取三个合法值"这条规则跟着名字走，任何列只要声明这个域就自动继承约束。

```sql
create domain person_name char(20) not null;

create domain degree_level varchar(10)
    constraint degree_level_test
    check (value in ('Bachelors', 'Masters', 'Doctorate'));
```

要点：

- 域可以携带 `not null`、`check` 等**约束**（这是它与 type 最大的不同）；
- `check` 里的 **`value` 关键字**指代"正在被检查的域值"；
- `constraint degree_level_test` 给约束**命名**，便于后续管理；
- 任何列声明为该域后，**自动继承**全部域约束。

> [!warning] 易错点：TYPE 与 DOMAIN 的本质区别
> | | `create type` | `create domain` |
> |---|---|---|
> | 本质 | 定义一个**全新类型**（强类型） | 给**已有类型 + 约束**取名（仍是底层类型） |
> | 能否带 check/not null | 本身不能（类型层面无约束概念） | ✅ 这正是它的核心能力 |
> | 与其他值互操作 | 与底层类型**不兼容**，需显式转换 | 值本质是底层类型，底层兼容即可赋值比较 |
> | 修饰符 | 可 `final` | 用 `constraint` 命名内部约束 |
>
> 记忆：**type 造"新物种"，domain 贴"合格证"**。（课件原话：Types and domains are similar. Domains can have constraints, such as not null, specified on them.）

---

## 6 索引定义（Index）

### 6.1 索引的动机与定义

**通俗理解**：在一本书里找"某个词"，没有目录就得逐页翻。**索引就是表的目录**：让"按值查找"不必扫描全表。

**严谨定义**（课件 P47）：

- 背景：**很多查询只涉及表中一小部分记录**（many queries reference only a small proportion of the records）；逐条读出全部记录再挑出目标，效率不可接受；
- **定义**：关系某属性上的**索引（index）**是一种**数据结构**，使数据库系统能**高效找到该属性具有指定值的元组，而无需扫描关系的全部元组**。

### 6.2 索引的创建与细节

```sql
create index <name> on <relation-name> (attribute);

-- 课件例子：给 student.ID 建索引
create index studentID_index on student (ID);

-- 此后按 ID 的点查直接走索引，不扫全表
select * from student where ID = '12345';
```

补充细节（工程常识，课件未展开）：

- 索引**只影响性能，不影响查询结果**——同一查询有无索引返回完全相同的数据，因此建索引是"纯优化动作"；
- 可建在**多个属性**上：`create index idx on student (dept_name, name);`
- 可建**唯一索引**强制唯一性：`create unique index ...`；主键/唯一约束通常**自动**创建索引；
- ⚠️ **索引不是越多越好**：每次 `insert / update / delete` 都要同步维护索引结构——**索引加速读、拖慢写**，高频写入表上的冗余索引是常见性能杀手。

---

## 7 授权（Authorization）

### 7.1 权限总览

**通俗理解**：权限就是**钥匙串**——可以按"关系/视图"为单位，给每个用户配不同的钥匙。DBMS 把"谁能对什么做什么"变成**强制执行的规则**，而不是靠自觉。

**数据操作权限**（课件 P49，每种权限英文名与 SQL 动词的对应）：

| 传统叫法 | SQL 权限 | 允许什么 | 禁止什么 |
|---|---|---|---|
| Read | `select` | 读取数据 | 修改数据 |
| Insert | `insert` | 插入**新**数据 | 修改已有数据 |
| Update | `update` | 修改数据 | 删除数据 |
| Delete | `delete` | 删除数据 | — |
| — | `all privileges` | 以上全部的简写 | — |

**模式（schema）修改权限**（课件 P50）：

| 权限 | 允许什么 |
|---|---|
| `index` | 创建、删除索引 |
| `resources` | 创建**新的关系** |
| `alteration` | 给关系**增删属性** |
| `drop` | 删除关系 |
| `references` | 用本表的列作**外键引用**（见 [[#7.7 REFERENCES 权限|7.7]]） |

每类权限施加的粒度是**指定的数据库部分**——某个关系、某个视图（课件原话：on specified parts of a database, such as a relation or a view）。

### 7.2 GRANT：授予权限

**语法骨架**（课件 P51）：

```sql
grant <privilege list> on <relation or view> to <user list>;

-- 例子
grant select on department to Amit, Satoshi;
grant select on instructor to U1, U2, U3;
```

- `<user list>` 三种形态：
  1. **user-id**：具体用户；
  2. **`public`**：授予**所有合法用户**（数据库世界的"公开"）；
  3. **角色（role）**：授予一个角色（见 [[#7.4 角色（ROLE）|7.4]]）。

**两条铁律**（课件原文）：

1. **授权者必须自己已持有该权限**（或本人是 DBA）——你给不出你没有的东西；
2. **对视图授予权限，不隐含对基表的任何权限**（granting a privilege on a view does not imply granting any privileges on the underlying relations）。

### 7.3 REVOKE：撤销权限

**语法骨架**（课件 P53）：

```sql
revoke <privilege list> on <relation or view> from <user list>;

-- 例子
revoke select on student from U1, U2, U3;
```

**四条语义细节（细节题全在这里，逐条吃透）**：

| # | 规则 | 一句话理解 |
|---|---|---|
| 1 | `<privilege-list>` 可写 **`all`**，撤销该被撤销者持有的全部权限 | 一键清空钥匙串 |
| 2 | 被撤销者列表含 **`public`** 时：**所有用户**失去该权限，**但被显式授予过的用户保留** | "收回公开" ≠ "收回个人" |
| 3 | 同一权限被**不同授权者授予过两次**时，撤销其中一个授权后，**用户仍保留该权限**（还有一条授权链撑着） | 有备份钥匙就不算丢 |
| 4 | **依赖被撤权限的所有权限一并撤销**（依赖 = 被撤者拿此权限再转授出去的下游授权） | 抽掉主干，枝叶跟着掉 |

> [!warning] 易错点：规则 2、3 是反直觉判断题重灾区
> - "撤销了 public 的 select，某用户还能 select 吗？"——**看他有没有被单独 grant 过**；
> - "从 A 撤销了 select，通过 A 转授拿到 select 的 B 还能用吗？"——看 `cascade`/`restrict`（见 [[#7.6 授权的转移：WITH GRANT OPTION、CASCADE 与 RESTRICT|7.6]]），以及 B 是否还有别的授权来源（规则 3）。

### 7.4 角色（ROLE）

**通俗理解**：给 50 个教师逐个授权太蠢——**先把权限发给"教师"这个帽子，谁当教师谁戴帽**。角色是"权限的打包名"，是权限管理的中间层。

**严谨定义与语法**（课件 P54–P55）：角色（role）用于**区分不同用户在数据库中能访问/更新什么**。

```sql
create role instructor;                 -- ① 创建角色
grant instructor to Amit;               -- ② 把角色授予用户（Amit 戴上"instructor"帽）
grant select on takes to instructor;    -- ③ 权限发给角色 → 所有戴帽者自动获得
```

**角色可以授予角色（继承链）**：

```sql
create role teaching_assistant;
grant teaching_assistant to instructor;  -- instructor 角色继承 teaching_assistant 的全部权限

create role dean;
grant instructor to dean;                -- dean 继承 instructor
grant dean to Satoshi;                   -- Satoshi 戴 dean 帽 → 一路继承 instructor、teaching_assistant
```

> [!important] 方向铁律：`grant R to X` = **X 取得 R 的全部权限**
> 记忆：**箭头从"被授予的角色"指向"获益者"**——`grant 角色 to 用户/角色`，受益的是 to 后面那个。`grant select on takes to instructor` 反过来是"把**权限**发给**角色**"（to 后面是角色），所有持有 instructor 角色的人随之获益。两个方向别搞反：
>
> | 语句 | to 后面是 | 效果 |
> |---|---|---|
> | `grant <role> to <user/role>` | 用户/角色 | 它**获得该角色的权限** |
> | `grant <privilege> on t to <role>` | 角色 | **该角色的持有者**获得此权限 |

### 7.5 视图与授权

**课件案例**（P56）：

```sql
create view geo_instructor as
    (select * from instructor where dept_name = 'Geology');

grant select on geo_instructor to geo_staff;
```

课件抛出两个问题：① 若 `geo_staff` 对 `instructor` **没有权限**，它还能查 `geo_instructor` 吗？② 若视图**创建者**对 `instructor` 缺权限呢？

**逐问拆解**：

1. **能查**——这正是视图的价值：授权给**视图**，等于发了一条"只含 Geology 系教员"的**受控数据出口**，查询视图**不需要**对基表的权限；
2. 视图查询的基表访问是**以视图定义者（owner）的身份**进行的（definer's rights）——因此：
   - **创建者必须持有基表上被引用的权限**，否则视图根本无法工作（实现层面会在创建时检查）；
   - 被授权者**永远拿不到基表本身的权限**：`geo_staff` 不能 `select * from instructor`，只能透过窗口看 Geology 的那一角。

> [!important] 视图在授权体系中的双重身份
> ① **权限收窄器**：把宽表切成窄窗口（隐藏 `salary`、只留某系行），再把窗口授权出去——最小权限原则的标准落地；
> ② **权限不传染**：对视图的授权**绝不向基表扩散**（7.2 铁律 2），撤销视图权限也**不影响**基表上的其他授权。视图与基表是**两把独立的钥匙**。

### 7.6 授权的转移：WITH GRANT OPTION、CASCADE 与 RESTRICT

**通俗理解**：默认授权是"**到我为止**"；加了 `with grant option` 就是"**你可以再发给别人**"——于是形成**授权链**。撤销时又来一道选择题：链上的人怎么办（**连坐** cascade，还是**拒绝撤销** restrict）？

```sql
-- Amit 获得 select，且有权继续转授
grant select on department to Amit with grant option;

-- Amit 转授给 Satoshi（他必须先持有 with grant option 才合法）
grant select on department to Satoshi;

-- 撤销时的两种模式（课件 P57）
revoke select on department from Amit, Satoshi cascade;   -- 连同依赖此权限的下游授权一并撤销
revoke select on department from Amit, Satoshi restrict;  -- 若存在依赖此权限的授权 → 拒绝执行本次撤销
```

| 关键字 | 语义 | 依赖授权（下游转授）的命运 |
|---|---|---|
| `cascade` | 级联撤销 | **一起被撤销** |
| `restrict` | 受限撤销 | **只要有下游依赖，整个 revoke 被拒绝**（上游也保留） |

与 [[#7.3 REVOKE：撤销权限|7.3]] 规则 4 的关系：**"依赖被撤权限的授权也会被撤销"描述的就是依赖链的传播**；`cascade` 是"传播执行"，`restrict` 是"有依赖就罢工"。**答题时先看题干给没给关键字**——未指明时按课件给出的默认语义处理，不要自行脑补。

> [!tip] 完整授权图景
> `with grant option` 造出**授权有向图**：节点是 (用户, 权限)，边是"谁转授给谁"。撤销 = 在图上**剪枝**：cascade 剪掉全部下游，restrict 发现有下游就整刀不下去——这就是"依赖"一词的图论含义。

### 7.7 REFERENCES 权限

**课件例子**（P57）：

```sql
grant reference (dept_name) on department to Mariano;
```

**为什么需要它（why is this required）**——这是本节最考理解的问题：

- 给 `department` 建外键，**影响的不只是自己的表**：一旦 Mariano 的表引用了 `department.dept_name`，那么**今后任何人删/改 department 的行，都可能被 Mariano 表的约束挡住**（默认 reject）；
- 换句话说，**建外键 = 对被引用表的未来修改施加了限制 = 让渡了部分控制权**——所以哪怕不给 Mariano 任何 `select` / `insert` 权限，也必须**单独批准他"引用"这列**；
- 这正体现了权限设计的细粒度思想：**读（select）、写（insert/update/delete）、引用（references）是三种独立的能力**，可以分开发放。

---

## 8 本章重难点与易错点汇总

| # | 易错点 | 一句话记忆 |
|---|---|---|
| 1 | 自然连接把**所有**同名列全部 `=`，同名不同义 → 静默丢行 | natural = 按名字认亲戚，认错了不出声 |
| 2 | `natural` / `using` / `on` 输出列不同：on 保留两列，另两者合列 | 条件怎么写，列就怎么出 |
| 3 | **外连接中 `on` 与 `where` 语义天壤之别**：where 里的等值条件会杀掉刚补的 NULL 行，左外退化成内连接 | 行留存靠 `on`，行过滤靠 `where`，补 NULL 后只能 `is null` |
| 4 | `null = null` 是 unknown → 含 NULL 的行参与不了任何等值连接 | NULL 连不上，配对永远失败 |
| 5 | 视图存**表达式**不存结果，基表变视图立刻变（物化视图才存结果且会过期） | 普通视图是宏，物化视图是快照 |
| 6 | 视图展开 = 整体代入 + 派生表包裹，条件不能随意合并 | 展开看聚合，聚合挡住下推 |
| 7 | 可更新视图四条件：**一表、纯列、可空补、无分组** | 四条是语法门槛，不是语义保证 |
| 8 | 通过带 WHERE 的视图可插入"视图永远看不见的行" → `with check option` 拦截 | 插进滤镜的数据，先问滤镜认不认 |
| 9 | 事务**隐式开始**，必须 `commit work` / `rollback work` **显式结束**；rollback 撤销整个事务而非最后一条 | 开得无声，收须有声；反悔就是全反悔 |
| 10 | 主键禁止 NULL，**UNIQUE 允许 NULL**（别依赖 UNIQUE 给 NULL 判重） | 主键零容忍，唯一键放 NULL 一马 |
| 11 | `check(P)` 只在 P 为 **false** 时违约，**unknown 放行** → check 挡不住 NULL | 三值逻辑下"没查出错"≠"查过了" |
| 12 | 外键违约检查是**双向的**：既查引用方插入，也查被引用方删除/更新 | 父行要走，先问子行答不答应 |
| 13 | 默认引用动作是 **reject**；`set null` 与 `not null` 互相矛盾 | 不写动作 = 谁都不许动 |
| 14 | 含子查询的 `check` 在**被引用关系变化时**同样要检查（双向依赖，代价高） | 约束盯的是关系，不是单表 |
| 15 | 断言里的 `<>` 遇 NULL 变 unknown → **约束形同虚设**；必须 `coalesce` 归一 | 断言怕的不是错，是"算不出对错" |
| 16 | `create assertion` 主流 DBMS 基本不支持（工程用触发器替代） | 考试要会写，落地要知道没人用 |
| 17 | 自引用表插入顺序死锁 → 先插父 / 先置 NULL / **延迟检查（deferrable，commit 时统一查）** | 立即查卡顺序，延迟查卡提交 |
| 18 | revoke 含 `public`：**显式授权者保留**；双授权撤销一条仍保留 | 收回公开 ≠ 收回个人 |
| 19 | `grant <role> to X` → **X 获得角色权限**；角色可授予角色形成继承链 | to 后面是获益人 |
| 20 | 对**视图**授权 ≠ 对基表授权；视图以**定义者权限**查询基表 | 两把独立的钥匙 |
| 21 | `with grant option` + `cascade`/`restrict`：级联剪枝 vs 有依赖就拒绝 | 授权是一张图，撤销是剪枝 |
| 22 | `references` 权限：建外键会**限制别人对父表的修改**，须单独授权 | 引用也是要付权限的 |
| 23 | `date + interval '1' month` 月末钳制（1/31 + 1 月 = 2/28）；blob/clob 查询返回**指针** | 月份看日历，大对象只给地址 |
| 24 | `type` 造新类型（可 `final`、不可混用），`domain` = 类型 + 约束（`value` 关键字） | type 造物种，domain 贴合格证 |
| 25 | 索引只加速读、拖慢写，且**不改变查询结果** | 目录不改书的内容，只改翻书速度 |

---

## 9 综合例题（难度偏高）

> 除特别说明外，沿用本课程通用关系模式： `instructor(ID, name, dept_name, salary)`、`department(dept_name, building, budget)`、`course(course_id, title, dept_name, credits)`、`section(course_id, sec_id, semester, year, building, room_number, time_slot_id)`、`teaches(ID, course_id, sec_id, semester, year)`、`student(ID, name, dept_name, tot_cred)`、`takes(ID, course_id, sec_id, semester, year, grade)`、`prereq(course_id, prereq_id)`、`time_slot(time_slot_id, day, start_time, end_time)`

**例题 1（自然连接危险：手算两种写法的结果差异）** 设数据如下：

`student`：

| ID | name | dept_name | tot_cred |
|---|---|---|---|
| 10128 | Alice | Biology | 60 |
| 10129 | Bob | Comp. Sci. | 30 |

`course`：

| course_id | title | dept_name | credits |
|---|---|---|---|
| BIO-101 | Intro to Biology | Biology | 4 |
| CS-101 | Intro to Computer Science | Comp. Sci. | 4 |

`takes`：`(10128, CS-101)`、`(10129, CS-101)`（各选了 CS-101）。

请手算下列两个查询的结果，并解释差异根源：

```sql
-- (a) select name, title from student natural join takes natural join course;
-- (b) select name, title from student natural join takes, course
--     where takes.course_id = course.course_id;
```

<details><summary>参考解答</summary>

**(a) 结果只有 1 行**：`('Bob', 'Intro to Computer Science')`。

逐步推演：

1. `student natural join takes`：公共列恰好只有 `ID` → 安全，得到两行（Alice 一行、Bob 一行，各带 `course_id = CS-101`）；
2. 再 `natural join course`：上一步结果与 `course` 的公共列有**两列**——`course_id`（应该等）和 `dept_name`（不该等！）：
   - Alice 行：`dept_name = 'Biology'`，`CS-101` 的 `dept_name = 'Comp. Sci.'` → **不相等 → 该行被丢弃**；
   - Bob 行：`'Comp. Sci.' = 'Comp. Sci.'` → 保留。

**(b) 结果 2 行**：`('Alice', 'Intro to Computer Science')`、`('Bob', 'Intro to Computer Science')`。

**(差异根源)**：错误写法把"$\text{学生所在系} = \text{课程所在系}$"当成了匹配条件——凡是**本系学生选外系课程**的组合全部静默丢失。查询不报错、不警告，只是行数悄悄少了，这是自然连接最危险的地方。**只要存在一个"同名但不该相等"的列，就必须放弃 natural，改用 `on` / `using` 显式写条件。**

</details>

**例题 2（外连接手算：行数与 NULL 位置）** 设 `course` 3 行、`prereq` 2 行：

| course_id | title | dept_name | credits |
|---|---|---|---|
| CS-101 | Intro to CS | Comp. Sci. | 4 |
| CS-190 | Game Design | Comp. Sci. | 4 |
| CS-315 | Robot Learning | Comp. Sci. | 4 |

| course_id | prereq_id |
|---|---|
| CS-101 | CS-190 |
| CS-437 | CS-315 |

（注意：`CS-437` 在 course 中**不存在**；`CS-315`、`CS-190` 没有先修记录。）

请回答：(a) `course, prereq`（笛卡尔积）、inner join、left outer、right outer、full outer 各多少行？(b) 写出 right outer join 的结果（含 NULL 补位）；(c) 写一条 SQL 找"没有任何先修课的课程"，并说明另外两种写法错在哪。

<details><summary>参考解答</summary>

**(a) 行数**：

| 写法 | 行数 | 理由 |
|---|---|---|
| 笛卡尔积 `course, prereq` | $3 \times 2 = 6$ | 无条件组合 |
| inner join（按 `course_id`） | **1** | 只有 `CS-101 = CS-101` 配上 |
| left outer | **3** | 3 门课全保留（未匹配补 NULL） |
| right outer | **2** | 2 条先修记录全保留（未匹配补 NULL） |
| full outer | **1 + 2 + 1 = 4** | 匹配 1 + 左独有 2（CS-190、CS-315）+ 右独有 1（CS-437） |

**(b) right outer join 结果**（右表未匹配的行保留，左侧补 NULL）：

| course_id | title | dept_name | credits | prereq_id |
|---|---|---|---|---|
| CS-101 | Intro to CS | Comp. Sci. | 4 | CS-190 |
| CS-437 | NULL | NULL | NULL | CS-315 |

**(c) 三种写法**：

```sql
-- ✅ 写法一：左外连接 + is null（利用"补出的 NULL 行"）
select course_id
from course left outer join prereq using (course_id)
where prereq_id is null;

-- ✅ 写法二：not exists（推荐，天然不受 NULL 干扰）
select C.course_id from course C
where not exists (select * from prereq P where P.course_id = C.course_id);

-- ❌ 错法一：not in —— 若 prereq.course_id 里混入一个 NULL，整个 not in 返回空集！
select course_id from course
where course_id not in (select course_id from prereq);

-- ❌ 错法二：where prereq_id = null —— null = null 是 unknown，永远找不到行
```

**额外警示**：结果中的 `CS-437` 行说明 `prereq` 引用了不存在的课程——这正是 [[#4.3 参照完整性：FOREIGN KEY|4.3]] 外键要杜绝的"悬空引用"；给 `prereq.course_id` 加上 `foreign key ... references course`，这类脏数据根本进不来。

</details>

**例题 3（NATURAL / USING / ON 辨析 + `on` 与 `where` 的质变）** 假设 `course` 与 `prereq` 的公共列恰好只有 `course_id`。请回答：

(a) 三种内连接写法返回的**行**是否相同？**列**是否相同？
(b) 若 `prereq` 额外增加一列 `dept_name`，三种写法的结果会怎样变化？
(c) 下面两条语句哪条是左外连接语义，哪条退化成了内连接？各返回什么？

```sql
-- Q1
select * from course left outer join prereq
    on course.course_id = prereq.course_id
   where prereq.course_id = 'CS-190';

-- Q2
select * from course left outer join prereq
    on course.course_id = prereq.course_id and prereq.course_id = 'CS-190';
```

<details><summary>参考解答</summary>

**(a) 行相同，列不同**：公共列只有 `course_id`，三种写法的匹配行完全一致；但输出列——`natural` / `using` 把 `course_id` **合并为一列**，`on` 写法**保留两列**（`course.course_id` 和 `prereq.course_id` 并存）。

**(b) `natural` 结果可能变少，`on` / `using` 不变**：`natural` 会**自动追加** `$dept\_name = dept\_name$` 这条匹配条件——学生选课的系与先修记录的系必须一致才配上，不一致的行被丢；`using (course_id)` 和 `on course.course_id = prereq.course_id` 由你写死了条件，**不受新增同名列影响**。这就是"自动"的代价。

**(c) Q2 是左外连接语义，Q1 退化成内连接**：

- **Q1**：`on` 先完成连接（3 行：CS-101 匹配、CS-190/CS-315 补 NULL），**随后** `where` 过滤——`prereq.course_id = 'CS-190'` 对 NULL 行是 unknown → 全被杀掉；CS-101 行的 `prereq.course_id` 是 `CS-190` → 保留。**最终只有 1 行，效果与 inner join 无异**。
- **Q2**：`and prereq.course_id = 'CS-190'` 写在 **on** 里，它只影响"谁算匹配"：CS-190 这门课找不到满足条件的右行 → **照样保留、右侧补 NULL**；CS-101 与 `prereq(CS-101, CS-190)` 匹配成功。**结果是"保留全部左行，其中匹配上的带右值、其余补 NULL"的左外连接。**

**一句话总结**：`on` 条件不删左表行，`where` 条件删——**补 NULL 之后，任何对右表列的普通比较都会把保留行清空**。

</details>

**例题 4（视图展开：多层代入与终止性）** 给出三层视图：

```sql
create view v1 as
select course.course_id, sec_id, building, room_number
from course, section
where course.course_id = section.course_id
  and course.dept_name = 'Physics'
  and section.semester = 'Fall' and section.year = '2017';

create view v2 as
select course_id, room_number from v1 where building = 'Watson';

create view v3 as
select room_number, count(*) as cnt from v2 group by room_number;
```

(a) 把 `v3` 完整展开成只含基本表的等价查询（写清每一步替换）；(b) 展开过程为什么一定终止？(c) 若允许 `create view v4 as select * from v4`，会发生什么？(d) 能否把 `building = 'Watson'` 直接并进 `v3` 最内层的 where？为什么？

<details><summary>参考解答</summary>

**(a) 三步代入**：

```sql
-- 第 1 步：v3 中的 v2 → 代入 v2 的定义
select room_number, count(*) from (
    select course_id, room_number from v1 where building = 'Watson'
) group by room_number;

-- 第 2 步：结果中的 v1 → 代入 v1 的定义（用派生表整体包裹，外层谓词原样保留）
select room_number, count(*) from (
    select course_id, room_number from (
        select course.course_id, sec_id, building, room_number
        from course, section
        where course.course_id = section.course_id
          and course.dept_name = 'Physics'
          and section.semester = 'Fall' and section.year = '2017'
    ) where building = 'Watson'
) group by room_number;
```

**(b) 终止性**：依赖图是 `v3 → v2 → v1 → 基本表` 的**无环链**——每替换一次，表达式中的"视图数"至少减一，故 `until 不再含视图` 必然达到（课件原话：as long as the view definitions are not recursive, this loop will terminate）。

**(c) 递归视图**：`v4` 依赖自己 → **展开**时 `v4 → v4 → v4 ...` **无限循环，永不终止**——所以**视图展开算法只对非递归视图有效**。注意别把结论说过头：SQL:1999 其实**允许**递归视图定义（语义 = 不动点迭代，不靠展开，见 [[Ch5 Advanced SQL#4 递归查询（Recursive Queries）|Ch5 §4]]）；被展开"拒绝"的只是用代入法去解释递归视图这条路。

**(d) 不能**：本例恰好"看起来可行"（`building` 在内层可见、中间没有聚合类算子），但 **`v3` 含 `group by`**——把 `building='Watson'` 推到最内层是"先选房间再聚合"，与题目的"对 v2 聚合"（v2 本身已含该过滤）虽然在此例数值等价，但**一旦谓词涉及聚合后才有的语义（如对 count 的筛选）就完全不等价**。通用规则：**展开用"整体代入 + 派生表包裹"，谓词下推必须逐算子证明等价**（选择可下推过投影，但不能随意越过聚合/去重）。

</details>

**例题 5（视图更新：四条件判断 + 三情形分析）** 判断下列视图哪些"语法上可更新"（按四条件），并回答每个 `insert` 的命运：

```sql
create view faculty as select ID, name, dept_name from instructor;
create view departments_total_salary(dept_name, total_salary) as
    select dept_name, sum(salary) from instructor group by dept_name;
create view instructor_info as
    select ID, name, building from instructor, department
    where instructor.dept_name = department.dept_name;
create view history_instructors as
    select * from instructor where dept_name = 'History';
create view name_upper as select ID, upper(name) as nm from instructor;
```

```sql
insert into faculty values ('30765', 'Green', 'Music');
insert into history_instructors values ('25566', 'Brown', 'Biology', 100000);
```

<details><summary>参考解答</summary>

**语法判断（一表、纯列、可空补、无分组）**：

| 视图 | 可更新？ | 卡在哪条 |
|---|---|---|
| `faculty` | ✅ | 四条全过 |
| `departments_total_salary` | ❌ | `group by` + 聚合（条件 4、条件 2） |
| `instructor_info` | ❌ | `from` 里两个关系（条件 1） |
| `history_instructors` | ✅（语法上） | 四条全过（WHERE 不是判定项） |
| `name_upper` | ❌ | select 列表是表达式 `upper(name)`（条件 2） |

**两条 insert 的命运**：

1. `insert into faculty values ('30765', 'Green', 'Music')`：视图不含 `salary`，翻译到 `instructor` 时缺值 → 按课件两种处理：**拒绝**，或插入 `('30765', 'Green', 'Music', null)`（salary 补 NULL）。
2. `insert into history_instructors values ('25566', 'Brown', 'Biology', 100000)`：该行 `dept_name = 'Biology'`，**不满足视图的 `where dept_name = 'History'`**——插入后它在 `instructor` 里存在，却**永远查不出于该视图**（"通过视图插入视图看不见的行"）。课件将此列为"根本无法正确翻译"的更新：合理语义是**拒绝**；SQL 标准用 **`with check option`** 把拒绝变成强制规定。若无此选项，部分实现会放行（留下一条"隐形行"）——这就是必须加 `with check option` 的原因。

**另记**：`instructor_info` 的插入还有**多解/无解**问题（Taylor 楼多个系？没有系？）——无法唯一翻译，直接拒绝。

</details>

**例题 6（事务边界与原子性）** 下面是一段转账程序，逐问分析：

```sql
update account set balance = balance - 1000 where acc_no = 'A';
update account set balance = balance + 1000 where acc_no = 'B';
rollback work;
update account set balance = balance + 500 where acc_no = 'C';
commit work;
```

(a) 事务从哪条语句开始？在何处结束、共几个事务？(b) 执行完毕后 A、B、C 各自发生了什么？(c) 若把 `rollback work` 改成"只撤销第二条"，SQL 做得到吗？(d) 若全程不写 commit/rollback 会怎样？

<details><summary>参考解答</summary>

**(a)** 标准规定**执行第一条 SQL 语句时事务隐式开始**，`rollback work` 显式结束第 1 个事务；随后执行 update C 时**又隐式开启**第 2 个事务，`commit work` 结束它。**共 2 个事务**：`{update A, update B}` 与 `{update C}`。

**(b)**

- 第 1 个事务：`rollback` 把 A、B 的修改**全部撤销** → **A、B 余额不变**（仿佛从未执行）；
- 第 2 个事务：`commit` → **C 增加 500，永久生效**。

**(c)** 做不到。`rollback` 是**事务级**撤销，一次回滚事务内**所有**修改；想保留第一条、撤销第二条，只能先 `commit work` 结束当前事务，再把第二条放进新事务去 rollback——**"选择性撤销"必须靠切分事务实现**。

**(d)** 标准语义下事务必须以 `commit`/`rollback` 结束；实际实现中未显式结束时，依 **autocommit 设置**可能"每条自动提交"（A、B 都生效！），或在**会话断开时整体回滚**——行为依实现而定。**这正是转账代码绝不能依赖默认设置的原因**：必须显式控制事务边界。

</details>

**例题 7（约束组合矛盾：DDL 细节大搜查）** 判断下列写法的问题，并说明运行结果：

```sql
-- (1)
create table course (
    course_id varchar(8) primary key,
    title varchar(50),
    dept_name varchar(20) not null,
    credits numeric(2,0) check (credits > 0),
    foreign key (dept_name) references department
        on delete set null
);
-- 随后：delete from department where dept_name = 'Biology';  （Biology 系下有课程）

-- (2) credits numeric(2,0) check (credits > 0) 但不写 not null：插入 (…, NULL) 会怎样？

-- (3) 用 unique 代替 primary key：允许几行 NULL？
```

<details><summary>参考解答</summary>

**(1) 矛盾必然爆发**：`dept_name` 既 `not null`，又 `on delete set null`——删除 Biology 时 DBMS 要把所有引用它的 `course.dept_name` 置 NULL，但 NOT NULL 禁止 NULL → **置空操作本身违约，删除最终被拒绝**（或实现直接报约束冲突）。二者不可兼得：要么去掉 `not null`，要么改 `on delete cascade`（连课一起删）/ 默认 reject（不许删）。

**(2) NULL 蒙混过关**：`check (credits > 0)` 只在谓词为 **false** 时违约；`NULL > 0` = **unknown** → **插入成功**，表里出现 `credits = NULL` 的行。想真正堵死必须写 `credits numeric(2,0) not null check (credits > 0)`——**check 与 not null 是两把独立的锁**。

**(3) UNIQUE 列可有多个 NULL**：NULL 不参与等值比较，多数实现下（如 PostgreSQL / MySQL / SQL Server）**允许多行 NULL**——即"唯一约束挡不住重复的 NULL"；个别实现（如 Oracle 的唯一索引）把 NULL 视为相等，只允许一个。而 `primary key` **一行 NULL 都不允许**，且一张表只能有一个主键、可有多个 unique。**判重需求必须自己对 NULL 特殊处理，别把期望寄托在 unique 上。**

</details>

**例题 8（自引用表：插入顺序与延迟检查）** 对 4.5 的 `person(ID, primary key; father, mother → person(ID))`（两 FK 列**允许 NULL**，默认立即检查）：

(a) 依次插入 `P1(父亲 F 未定)`、`P2(P1 的父亲)`、`P3(P1 的母亲)` 是否合法？若 `P1.father = 'P2'` 在插入 P1 时就写上，会怎样？
(b) 用"先置 NULL 后 update"方案写出插入顺序，并指出它在什么条件下**不可行**；
(c) 用延迟检查改写外键定义，说明检查发生在何时、rollback 场景下又如何。

<details><summary>参考解答</summary>

**(a)** 允许 NULL 时：先插 `P1`（father/mother 均 NULL）→ 再插 `P2`（father/mother NULL）→ 再插 `P3` ——每步都合法。**但如果插入 P1 时直接写 `father = 'P2'`**：立即检查发现 `P2` 尚不存在 → **违约，插入被拒**——这就是"鸡生蛋"问题：**立即检查逼你按拓扑序（先被引用者）插入**。

**(b)** 顺序：先把 `father/mother` 置 NULL 插入所有人，最后用 `update person set father = 'P2' ...` 逐个补全——补全时每个人已存在，合法。**不可行条件**：两列若声明了 **`not null`**，第一步就插不进去（课件原文点明此限制）。

**(c)**

```sql
foreign key (father) references person(ID) deferrable initially deferred
foreign key (mother) references person(ID) deferrable initially deferred
```

`initially deferred` → 该约束在**每条语句后不查**，统一推迟到 **`commit` 时**检查——事务中间可以出现"引用尚未补齐"的暂时违约，提交那一刻必须全部合法。若事务最终 **`rollback`**，中间状态随事务一起消失，**这些违约从未存在过，无需检查**。注意 MySQL 8.0 不支持 `deferrable`，只能靠插入顺序或触发器实现同样效果。

</details>

**例题 9（复杂 CHECK 与断言：双向检查 + 三值逻辑陷阱）** (a) `section` 上的 `check (time_slot_id in (select time_slot_id from time_slot))`——列出**所有**会触发该检查的修改操作；它与外键写法各有什么优劣？
(b) 下面"学分对账"断言写法有什么隐蔽漏洞？如何修复？

```sql
create assertion bad_assertion check (
    not exists (select * from student S
        where S.tot_cred <> (select sum(C.credits)
                             from takes T, course C
                             where T.ID = S.ID and T.course_id = C.course_id
                               and T.grade <> 'F' and T.grade is not null))
);
```

<summary>参考解答</summary>

**(a) 触发时机是双向的**：

| 谁变了 | 是否检查 | 原因 |
|---|---|---|
| `section` 插入/更新 `time_slot_id` | ✅ | 引用方提供了新值，须查是否存在 |
| `time_slot` **删除**某行 | ✅ | 被引用值消失 → 引用它的 section 变悬空！ |
| `time_slot` **更新**某 `time_slot_id` | ✅ | 同上（值被改走） |

**即：两张表的每一次相关修改都要重新验证谓词**——约束盯的是"两个关系之间的关系"，不是单表。

与外键对比：该 `check` 语义上**等价于** `foreign key (time_slot_id) references time_slot(time_slot_id)`；外键有专门维护通路、可挂 `on delete` 动作、优化器友好，**工程首选外键**；`check + 子查询`的价值在于能表达外键覆盖不了的**任意谓词**（跨表比较、带函数的条件），但每次相关修改都要重新求值、代价高，且部分实现对 `check` 里的子查询支持受限。

**(b) 漏洞：三值逻辑让断言"睁眼瞎"**——

- 学生**没有任何选课**（或全部不及格/未评分）→ 子查询 `sum(...) = NULL`；
- `S.tot_cred <> NULL` = **unknown** → `where` **不选中该行** → `not exists` 认为"没有违规"；
- 即便该学生 `tot_cred = 999` 明明对不上账，断言也**查不出来、判定通过**。

`check (P)` 只在 P 为 **false** 时违约，**unknown 等于放行**——约束形同虚设。

**修复**：把两侧统一 `coalesce` 成 0（或用 `is [not] distinct from` 做 NULL 安全比较），确保"真出错时谓词算出 **false**"：

```sql
where coalesce(S.tot_cred, 0) <> coalesce((select sum(...) ...), 0)
```

此时"无选课但 tot_cred = 5" → `5 <> 0` = **false** → 违规被抓出 ✅（完整写法见 [[#4.7 断言（ASSERTION）|4.7]]）。

</details>

**例题 10（授权链推演：cascade / restrict / public / 双授权）** 依次执行：

```sql
-- ① DBA
grant select on department to Amit with grant option;
-- ② Amit
grant select on department to Satoshi;
-- ③ DBA
grant select on department to Satoshi;          -- 又显式授了一次（第二授权来源）
-- ④ DBA
grant select on department to public;
-- ⑤ Satoshi
grant select on department to Farouk;           -- 需要 Satoshi 也有转授权？——见解答
```

问：(a) 执行 `revoke select on department from Amit cascade` 后，Amit、Satoshi、Farouk 各是什么状态？换成 `restrict` 呢？(b) 执行 `revoke select on department from public` 后，Satoshi 还能查吗？普通未被显式授权的用户呢？(c) 执行 `revoke select on department from Satoshi`（假设 Farouk 的授权依赖 Satoshi）在 cascade / restrict 下的结果？

<details><summary>参考解答</summary>

**前置澄清**：⑤ 要合法，Satoshi 必须持有 `with grant option`——他从 ②（Amit 有转授权资格）拿到的授权**携带转授权能力**；而 ③ 是 DBA 的普通授权（无转授权）。转授权链的"依赖"要看**权力来源**。为聚焦题意，设 ⑤ 的授权依赖于 ② 这条链。

**(a) 从 Amit 撤销**：

- **cascade**：Amit 失去；② 这条"Amit 转授给 Satoshi"的下游授权**依赖被撤权限 → 一并撤销**；但 Satoshi 还有 ③ 这条**独立来源** → **Satoshi 仍保留 select**（规则 3：双授权撤一条仍保留）；Satoshi 既然还持有，⑤ Farouk 的授权**不受影响**。
- **restrict**：Amit 名下**存在依赖此权限的授权**（②）→ **整个 revoke 被拒绝**，Amit 的权限原样保留。

**(b) 从 public 撤销**：**所有靠 public 获得该权限的用户失去权限**；但**被显式授权的用户保留**——Satoshi（③ 显式）✅ 继续可查；只有"纯靠 public"的普通用户被收回。（规则 2：收回公开 ≠ 收回个人。）

**(c) 从 Satoshi 撤销**（下游 Farouk 依赖他）：

- **cascade**：Satoshi 失去，**Farouk 的授权一并被撤**（依赖链剪枝）；
- **restrict**：存在依赖 → **拒绝执行**，Satoshi 与 Farouk 都保留。

**通用方法**：把授权画成有向图（谁转授给谁），撤销 = 剪掉 (用户, 权限) 节点及其下游（cascade）或有下游就不剪（restrict）；**再检查该节点是否还有第二条独立入链**（双授权 / 显式授权 / public）。

</details>

**例题 11（角色链 + 视图授权 + references 权限）** 执行：

```sql
create role instructor;
create role teaching_assistant;
create role dean;
grant teaching_assistant to instructor;
grant select on takes to instructor;
grant instructor to Amit;
grant instructor to dean;
grant dean to Satoshi;

create view geo_instructor as
    select * from instructor where dept_name = 'Geology';
grant select on geo_instructor to geo_staff;

grant reference (dept_name) on department to Mariano;
```

(a) 谁能 `select` from `takes`？(b) `geo_staff` 没有任何 instructor 基表权限，能查 `geo_instructor` 吗？能直接查 `instructor` 吗？(c) `reference` 权限让 Mariano 能做什么、不能做什么？为什么必须单独授予？

<details><summary>参考解答</summary>

**(a) Amit 与 Satoshi 都能**（方向铁律：`grant R to X` → X 获得 R 的权限）：

- `grant select on takes to instructor` → 权限发给 **instructor 角色** → 戴该帽者获益；
- `grant instructor to Amit` → **Amit** 持有 instructor → 有 select on takes；
- `grant teaching_assistant to instructor` → instructor **继承** TA 的全部权限 → Amit 也连带获得 TA 权限；
- `grant instructor to dean; grant dean to Satoshi` → **Satoshi** 持有 dean，dean 又持有 instructor → **继承链 Satoshi → dean → instructor** → Satoshi 同样能 select on takes（并连带 TA 权限）。

链条记忆：**权限沿"被授予 → 获益者"方向流动，持有角色 = 戴上那顶帽子的全部权限**。

**(b)**

- **能查 `geo_instructor`**：对视图的 select 权限给他开了"Geology 系教员"这条受控出口；查询时基表访问**以视图定义者（owner）的身份**进行，`geo_staff` 自己**不需要** instructor 的权限；
- **不能查 `instructor`**：对视图授权**绝不隐含对基表的任何权限**（7.2 铁律 2）——他 `select * from instructor` 会直接报权限错误。
- 反向提醒：既然以定义者权限执行，**创建视图者必须持有基表上被引用的权限**，否则视图无法工作——这正是课件抛出的第二个问题的答案。

**(c)**

- **能**：把 `department.dept_name` 作为**外键引用目标**（在自己的表上写 `references department(dept_name)`）；
- **不能**：`select` / `insert` / `update` / `delete` department——`reference` 不给任何读写权；
- **为何必须单独授予**：一旦 Mariano 的表建了外键，**今后任何人删/改 department 的行都可能被他表的约束（默认 reject）挡住**——建外键等于**对 department 的未来修改施加限制、让渡部分控制权**。读、写、引用是三种独立能力，必须分开批准。

</details>

**例题 12（数据类型 / 索引细节判断）** 判断下列说法对错并说明理由：

(a) `date '2005-1-31' + interval '1' month` 的结果是 `2005-03-03`；
(b) `date '2005-7-27' - date '2004-7-27'` 得到一个 `date` 值；
(c) 查询一个含 `blob` 列的行，DBMS 会把整个二进制对象放进结果集返回；
(d) `create type Dollars as numeric(12,2) final` 之后，`budget Dollars` 可以与 `numeric` 列直接比较，无需转换；
(e) `create domain degree_level ... check (value in ('Bachelors', ...))` 中 `value` 指任意列名；
(f) 建了 `studentID_index` 后，`select * from student where ID = '12345'` 不再扫描全表，且**任何** SQL 的执行结果都会改变。

<details><summary>参考解答</summary>

| # | 判断 | 解析 |
|---|---|---|
| (a) | ❌ | 结果是 **`2005-02-28`**——SQL 标准的"月末钳制"：目标月没有 31 日就取该月**最后一天**，不会进位到 3 月 |
| (b) | ❌ | 两个日期相减得到 **`interval`**（一段时间），不是 `date`；相减得时刻、时刻相减得时长 |
| (c) | ❌ | 返回的是**指针**，大对象本身按需读取——避免在结果集里整体搬运几十 MB 数据（blob 的解释权在**应用**，DBMS 不管内容） |
| (d) | ❌ | `Dollars` 是**新类型**（`final` = 不可再被继承），与 `numeric` **不兼容**，比较/赋值需显式转换——这正是自定义类型的意义（防"金额当重量"混用） |
| (e) | ❌ | `value` 是域约束中的**关键字**，指代"**当前正在被检查的域值**"，与任何列名无关 |
| (f) | 前半 ✅ 后半 ❌ | 索引让点查**免于全表扫描**（走目录直接定位）；但索引**只影响性能，绝不改变结果**——同一查询有无索引返回完全相同的数据。且索引要随 insert/update/delete 维护，**加速读、拖慢写** |

</details>

**例题 13（连接 + 视图 + 授权综合设计）** 需求：教务处人员只能看到"每系教师人数与平均工资"，不能看到个人工资；且希望该视图可更新。请：(a) 写出视图；(b) 授予教务处角色 `edu_office` 查询权限但不给基表权限；(c) 判断该视图能否更新，说明原因与替代方案。

<details><summary>参考解答</summary>

```sql
-- (a) 聚合视图（计算列显式命名）
create view dept_salary_stats(dept_name, num_instructors, avg_salary) as
select dept_name, count(*), avg(salary)
from instructor
group by dept_name;

-- (b) 权限只发到视图，基表一概不给
create role edu_office;
grant select on dept_salary_stats to edu_office;
-- 注意：不要 grant select on instructor —— 视图授权与基表授权彼此独立
```

**(c) 不能更新**：视图含 `group by` + 聚合，违反可更新四条件中的"无分组"与"纯列（只含属性名）"两条——人数、平均工资**无法唯一翻译**回 `instructor` 的某几行（多对一不可逆）。

**替代方案**：确需修改工资的场景，另行授予 `update` 权限在**基表**上（配合独立角色）；或改用**只含纯属性、单表**的视图做行级收窄（如 `where dept_name = '...'` + `with check option`），聚合类视图在所有主流实现中都只作**只读报表**使用。

</details>

---

## 10 知识点速查

| 知识点           | 核心要点                                                                             | 关键语法 / 公式                                                                                 |
| ------------- | -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| 连接两维度         | 条件定行，类型定未匹配行去留                                                                   | $R \bowtie_\theta S = \sigma_\theta(R \times S)$                                          |
| 自然连接          | 全部同名列自动等值 + 合列；同名不同义 → 静默丢行                                                      | `r1 natural join r2`                                                                      |
| 三种连接条件        | natural 自动 / using 点名合列 / on 任意谓词且两列都留                                           | `join ... using (a)` / `join ... on P`                                                    |
| 外连接           | 未匹配补 NULL；left/right/full = 保左/保右/全保                                             | $R\ \text{⟕} S = \sigma_\theta(R\times S) \cup \{r\cup \mathrm{null}_S \mid \nexists s\}$ |
| on vs where   | `on` 定匹配不删保留行；`where` 过滤会杀 NULL 行（外连接退化）                                         | 判 NULL 只能 `is null`                                                                       |
| 视图            | 存表达式不存结果，用时代入；隐藏数据 + 逻辑独立                                                        | `create view v as <query>`                                                                |
| 视图展开          | 反复整体代入到只剩基本表；非递归才终止                                                              | `e[v ← 定义]` until 无视图                                                                     |
| 物化视图          | 物理存储结果，底表更新后过期需维护                                                                | `create materialized view ...`                                                            |
| 视图更新          | 三情形：缺值可补 / 多解不可译 / 违谓词应拒                                                         | 四条件：一表、纯列、可空补、无分组                                                                         |
| 视图防越权插入       | 带 WHERE 的视图强制拒绝违反谓词的写入                                                           | `with check option`                                                                       |
| 事务            | 语句隐式开始；commit 永久 / rollback 全撤                                                   | `commit work` / `rollback work`                                                           |
| 原子性/隔离性       | 全做或全不做；并发事务互不可见中间态                                                               | atomic / isolation                                                                        |
| not null      | 该列必须有值                                                                           | `col type not null`                                                                       |
| primary key   | NOT NULL + UNIQUE，每表一个                                                           | `primary key (A1,...,Ak)`                                                                 |
| unique        | 候选键，**允许 NULL**，每表可多个                                                            | `unique (A1,...,Am)`                                                                      |
| check         | 每元组须满足 P；**false 才违约，unknown 放行**                                                | $\forall t \in R:\ P(t)$；挡不住 NULL                                                         |
| 外键            | 引用值必须存在于对方主键/候选键（非空值）                                                            | $\pi_A(R) \subseteq \pi_A(S)$；`foreign key ... references`                                |
| 引用动作          | 默认 reject；cascade 连删/连改；set null/default 置换                                      | `on delete cascade` 等                                                                     |
| 延迟检查          | 自引用/成组修改先做后验，commit 时统一查                                                         | `deferrable initially deferred`                                                           |
| 复杂 check      | 子查询谓词，**双向检查**（引用方与被引用方都盯）                                                       | `check (x in (select ...))` ≈ 外键                                                          |
| 断言            | 全库不变量；三值逻辑下须 coalesce 防 unknown；实现基本不支持                                          | `create assertion n check (P)`                                                            |
| 日期时间          | date/time/timestamp/interval；相减得 interval；月末钳制                                   | `interval '1' day`；1/31 + 1月 = 2/28                                                       |
| 大对象           | blob 二进制 / clob 字符；查询返回**指针**                                                    | `blob`, `clob`                                                                            |
| create type   | 新类型、可 `final`、不可与底层混用                                                            | `create type Dollars as numeric(12,2) final`                                              |
| create domain | 类型 + 约束（not null / check with `value`）命名复用                                       | `create domain d as T check (value ...)`                                                  |
| 索引            | 按值免全表扫描；只改性能不改结果；加速读拖慢写                                                          | `create index i on r (a);`                                                                |
| 权限种类          | 数据：select/insert/update/delete/all；模式：index/resources/alteration/drop/references | `grant <privs> on <obj> to <users>`                                                       |
| 授权规则          | 授权者须已持有；视图授权 ≠ 基表授权；user/public/role                                             | `to public` = 全体                                                                          |
| 撤销语义          | public 收回但显式保留；双授权保留一条即保留；依赖链撤销                                                  | `revoke ... from ...`                                                                     |
| 角色            | 权限打包；可授予角色形成继承链                                                                  | `grant <role> to <user/role>` → to 后获益                                                    |
| 视图授权          | 以定义者权限查基表；给窗口不给仓库                                                                | `grant select on view to u`                                                               |
| 授权转移          | with grant option 转授；cascade 剪枝 / restrict 有依赖即拒                                 | `revoke ... cascade / restrict`                                                           |
| references    | 建外键 = 限制父表修改 → 单独授权                                                              | `grant reference (a) on r to u`                                                           |

### 核心思想总结

1. **连接 = 两个正交问题**：谁配谁（condition）+ 配不上怎么办（type）。所有连接家族差异都能拆回这两问——`natural` 把条件"自动化"换来了省事与隐患，`outer` 把"未匹配行"从丢弃改为补 NULL。
2. **视图是"虚拟 + 代入"**：不存数据、存表达式，用时展开替换——由此派生出视图的三重身份：**安全窗口**（授权收窄）、**逻辑屏障**（模式变化隔离外部查询）、**命名复用**（跨语句、可授权）；而"能不能更新"取决于**更新能否唯一翻译回底表**。
3. **约束把数据质量从应用搬进 DBMS**：单关系四件套管"行内"，外键管"跨表"，断言管"全库"——层次逐级升高，表达力逐级增强，代价与实现支持度逐级下降。
4. **三值逻辑是全章的隐形主角**：NULL 让连接配不上、让 check 放行、让断言失效、让外连接成为必需——**凡是"没查出错"，先问一句"是 false 还是 unknown"**。
5. **授权是一张有向图**：节点 (用户, 权限)，边是转授；`grant R to X` 定方向，`cascade/restrict` 定剪枝，`public` 与多来源授权决定"撤了还在不在"——视图则是这张图上**不传染**的独立出口。
	1. **事务给一切修改划边界**：隐式开始、显式收尾；原子性保证"全或无"，隔离性保证"看不到半成品"——约束检查何时发生（立即/延迟）也由这条边界统一调度。
											