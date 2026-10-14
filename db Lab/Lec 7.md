---
cssclasses:
---

<div class="cover">
  <h1>2024级本科生《数据库系统实验》实验报告</h1>
  <h2>Lecture 7</h2>
  <div class="info">
    <p>班级：计科1班</p>
    <p>姓名：韩宇</p>
    <p style="margin-bottom: 400px;">学号：24319050</p>
    <p class="date" style="font-size: 1em">日期：10/14</p>
  </div>
</div>

<div style="page-break-after: always;"></div>

---

## 一、实验目的

熟悉SQL的数据控制操作，
能够使用SQL语句对用户进行授予和收回权限
## 二、实验内容

(1)使用 GRANT语句对用户授权 ， 对单个用户和多个用户授权 ， 或使用保
留字PUBLIC对所有用户授权。 对不同的操作对象包括数据库、 视图、 基本表等进行不同权限的授权。
(2)使用 WITH GRANT OPTION子句授予用户传播该权限的权利。
(3)在授权时发生循环授权,考察DBS能否发现这个错误。 如果不能 ，结合取消权限操作 ， 查看DBS对循环授权的控制。
(4)使用 REVOKE子句收回授权 ， 查看取消授权的级联反应。

## 三、实验结果

### 实验准备

#### 1.

使用管理员连接 `VLADI` 创建实验账号，截图中的实际 Windows 登录名为 `VLADI\50672`，普通用户连接分别使用 `USER1`、`USER2`、`USER3`

在新建登录名窗口中填写 `USER1`，选择 SQL Server 身份验证，设置密码，默认数据库选择 `School`，后续账号按各自的登录名配置

![[Pasted image 20261014105936.png|531]]

#### 2.

服务器角色只保留默认的 `public`

![[Pasted image 20261014110046.png|535]]
在用户映射中勾选 `School`，数据库用户为 `USER1`，数据库角色也只保留 `public`，登录名负责连接服务器，映射后的数据库用户用于接受 `School` 中的授权

![[Pasted image 20261014110147.png|527]]

#### 3.

在服务器属性的安全页选择 SQL Server 和 Windows 混合身份验证，使 Windows 管理员和 SQL Server 登录名都可以连接

![[Pasted image 20261014110441.png|537]]


### 0. 注意:以下各题目,若无特别指明,均指由管理员授权或取消授权
### (1)授予所有用户对表 STUDENTS的查询权限

由管理员执行，把 `students` 的查询权限授予数据库角色 `PUBLIC`，`USER1`、`USER2`、`USER3` 都属于这个角色，执行成功后可通过该角色获得查询权限

```sql
GRANT SELECT ON students
TO PUBLIC;
```

![[Pasted image 20261014112929.png|567]]
### (2)授予所有用户对表 COURSES的查询和更新权限

同样授权给 `PUBLIC`，这次同时授予 `SELECT` 和 `UPDATE`，作用对象是整个 `courses` 表，语句执行成功

```sql
GRANT SELECT, UPDATE
ON courses
TO PUBLIC;
```

![[Pasted image 20261014113051.png|575]]

### (3)授予USER1对表 TEACHERS的查询,更新工资的权限,且允许 USERI1可以传播这些权限

要允许查询教师信息，但更新只针对工资，所以先创建仅含 `salary` 一列的视图 `Tsalary`，第一张截图选中并执行的是创建视图

截图下方曾写了对整个 `teachers` 表授予 `SELECT, UPDATE` 的语句，这样会把更新范围扩大到整个表，后面改为分别给基表查询权限、给工资视图更新权限

```sql
CREATE VIEW Tsalary AS
SELECT salary FROM teachers;
```

![[Pasted image 20261014113525.png|578]]

由管理员给 `USER1` 授予 `teachers` 的查询权限及 `Tsalary` 的更新权限，两项都加上 `WITH GRANT OPTION`，允许 `USER1` 继续传播各自对象上的对应权限，截图中的授权语句执行成功

工资更新是通过 `Tsalary` 进行，不是授予整个 `teachers` 表的更新权限

```sql
GRANT SELECT
ON teachers
TO USER1
WITH GRANT OPTION;

GRANT UPDATE
ON Tsalary
TO USER1
WITH GRANT OPTION;
```

![[Pasted image 20261014113629.png|583]]
### (4)授予USER2对表 CHOICES的查询,更新成绩的权限

成绩更新也采用视图的写法，先创建只含 `score` 的 `CHgrade`，再由管理员给 `USER2` 授予 `choices` 的查询权限和 `CHgrade` 的更新权限

创建视图和授权分开执行，这里的授权没有加 `WITH GRANT OPTION`，没有同时授予继续传播这些权限的权利

```sql
CREATE VIEW CHgrade AS
SELECT score FROM choices;
```

```sql
GRANT SELECT
ON choices
TO USER2;

GRANT UPDATE
ON CHgrade
TO USER2;
```

![[Pasted image 20261014113854.png|587]]
### (5)由USER1授予USER2对表 TEACHERS的查询权限和传播的此项权限的权利

切换查询窗口的连接为 `USER1`，它在第 (3) 题获得了 `teachers` 的查询权限和传播权限，所以可以再授予 `USER2`，并通过 `WITH GRANT OPTION` 让 `USER2` 继续传播，语句执行成功

```sql
-- 由 USER1 执行
GRANT SELECT
ON teachers
TO USER2
WITH GRANT OPTION;
```

![[Pasted image 20261014114258.png|595]]
### (6)由USER2授予USER3对表 TEACHERS的查询权限,和传播的此项权限的权利。再由USER3授予USER2上述权限,这样的SQL语句能否成功得到执行?

先切换为 `USER2`，把 `teachers` 的查询权限及传播权授予 `USER3`，截图中执行成功

```sql
-- 由 USER2 执行
GRANT SELECT
ON teachers
TO USER3
WITH GRANT OPTION;
```

![[Pasted image 20261014114701.png|598]]

成功执行：
再切换为 `USER3`，用相同写法把权限授回 `USER2`，两条授权形成 `USER2 → USER3 → USER2` 的循环，本次 SQL Server 中两次授权均成功执行，没有因形成循环而报错

循环中的最初权限来源仍是管理员对 `USER1` 的授权，截图没有继续测试收回这条来源后的结果

```sql
-- 由 USER3 执行
GRANT SELECT
ON teachers
TO USER2
WITH GRANT OPTION;
```

![[Pasted image 20261014114753.png|607]]

### (7)取消USER1对表 STUDENTS的查询权限,考虑由USER2的身份对表 STUDENTS进行查询,操作能否成功?为什么？

回到管理员连接，执行取消 `USER1` 查询权限的语句，语句执行成功

第 (1) 题的权限授予的是 `PUBLIC`，只对 `USER1` 执行 `REVOKE` 不会取消它从 `PUBLIC` 获得的查询权限，也不会取消 `USER2` 从这个角色获得的权限，因此此时按题目要求以 `USER2` 身份查询，仍可以成功

```sql
REVOKE SELECT
ON students
FROM USER1;
```

![[Pasted image 20261014115200.png|591]]
USER1仍能查询，需要收回public
接着由管理员收回 `PUBLIC` 对 `students` 的查询权限，语句执行成功，这次取消的是角色这一条权限来源

若没有其他独立授权，普通用户之后就不能继续通过 `PUBLIC` 查询该表；管理员连接不能用来代替普通用户验证这一结果

```sql
REVOKE SELECT
ON students
FROM PUBLIC;
```

![[Pasted image 20261014115458.png|591]]


### (8)取消USER1和USER2的关于表 COURSES的权限

第 (2) 题给 `courses` 的权限也授予了 `PUBLIC`，所以这里直接从 `PUBLIC` 收回 `SELECT` 和 `UPDATE`，同时去掉 `USER1`、`USER2` 通过该角色获得的权限，也会影响依赖该角色授权的其他普通用户，截图中执行成功

`CASCADE` 用于同时收回依赖该授权传播出的权限，前面对 `courses` 的授权没有加 `WITH GRANT OPTION`

```sql
REVOKE SELECT, UPDATE
ON courses
FROM PUBLIC
CASCADE;
```

![[Pasted image 20261014115906.png|612]]

## 四、问题&总结
### 问题

当时对象资源管理器显示的是 `USER1`，但查询窗口中的身份检查返回 Windows 管理员登录 `Vladi\50672`、数据库用户 `dbo`，`sysadmin` 成员检查结果为 1，实际执行查询的仍是管理员连接

可以用下面的语句检查当前查询窗口的身份，不能只看左侧对象资源管理器的登录名

```sql
SELECT
    SUSER_SNAME() AS [当前登录账号],
    USER_NAME() AS [当前数据库用户],
    IS_SRVROLEMEMBER('sysadmin') AS [是否为管理员];
```

![[Pasted image 20261014111805.png|550]]
这一度导致我的实验无法进行

摸索了一会，发现关闭ssms重新进再登录就好了
之前是旧查询窗口仍保留着 Windows 管理员账号的连接，`USER1` 的权限设置没有问题。
以后切换账号时，需要更改查询窗口的连接，或在新账号连接下重新打开查询窗口

重新使用 `USER1` 的查询窗口后，执行 `SELECT * FROM courses` 报错，提示没有 `COURSES` 的 `SELECT` 权限，这张截图发生在第 (2) 题的公开授权之前

```sql
-- 由 USER1 执行
SELECT * FROM courses;
```

![[Pasted image 20261014112319.png|546]]

### 总结

- 这次主要练习 `GRANT`、`REVOKE` 和 `WITH GRANT OPTION`，查询权限可以给基表，限制更新范围时可以给只包含目标列的视图
- 判断用户能否操作时，要同时看直接授权和 `PUBLIC` 等角色提供的权限，取消一条来源不一定取消全部权限
- 测试权限时先确认查询窗口的实际账号，再切换用户进行验证，管理员连接的查询结果不能代替普通用户的结果
