---
title: Ch5 Advanced SQL
tags:
  - 数据库原理
  - SQL
  - 课程笔记
source: ch5.pdf — Database System Concepts, 7th Ed. (Silberschatz, Korth, Sudarshan), Chapter 5
目标: 掌握从编程语言访问 SQL（JDBC / SQLJ / ODBC / 嵌入式 SQL 与游标、SQL 注入与预编译语句、元数据）、函数与存储过程、触发器（行级/语句级/风险）、递归查询（传递闭包与不动点）、高级聚合与 OLAP（排名族、窗口框架、CUBE / ROLLUP / GROUPING、多维分析与实现），并能识别各处语法细节陷阱与课件笔误
---

> [!abstract] 一句话概括本章
> 前四章解决"如何写查询"，本章解决"如何把 SQL **用进真实系统**"——**五个板块**：① SQL 出不了数据库？用 **JDBC / 嵌入式 SQL** 把它接进程序（顺带学会防 SQL 注入）；② 业务逻辑搬进库里？**函数与存储过程**；③ 修改数据要自动"捎带干活"？**触发器**；④ "间接关系"查不动？**递归查询**（传递闭包）；⑤ 逐行报表不够看？**窗口函数与 OLAP**（排名、移动平均、CUBE / ROLLUP）。
> 主线一句话：**SQL 的边界在哪里，本章就把边界一条条往外推**——推到程序里（JDBC）、推到数据库内部（触发器/函数）、推到任意关系的闭包（递归）、推到多维分析（OLAP）。

> [!SUMMARY]+ Table of Contents
> - [[Ch5 Advanced SQL#1 从编程语言访问 SQL|1 从编程语言访问 SQL]]
>     - [[Ch5 Advanced SQL#1.1 为什么需要编程语言：SQL 的边界|1.1 为什么需要编程语言：SQL 的边界]]
>     - [[Ch5 Advanced SQL#1.2 两种接入方式：动态 API 与嵌入式 SQL|1.2 两种接入方式：动态 API 与嵌入式 SQL]]
>     - [[Ch5 Advanced SQL#1.3 JDBC：连接、语句与结果集|1.3 JDBC：连接、语句与结果集]]
>     - [[Ch5 Advanced SQL#1.4 ResultSet 读值细节与 NULL 处理|1.4 ResultSet 读值细节与 NULL 处理]]
>     - [[Ch5 Advanced SQL#1.5 PreparedStatement 与 SQL 注入|1.5 PreparedStatement 与 SQL 注入]]
>     - [[Ch5 Advanced SQL#1.6 元数据（Metadata）：让程序理解数据库|1.6 元数据（Metadata）：让程序理解数据库]]
>     - [[Ch5 Advanced SQL#1.7 JDBC 中的事务控制与高级特性|1.7 JDBC 中的事务控制与高级特性]]
>     - [[Ch5 Advanced SQL#1.8 SQLJ：编译期检查的嵌入式 SQL|1.8 SQLJ：编译期检查的嵌入式 SQL]]
>     - [[Ch5 Advanced SQL#1.9 ODBC 与嵌入式 SQL：游标四部曲|1.9 ODBC 与嵌入式 SQL：游标四部曲]]
> - [[Ch5 Advanced SQL#2 函数与存储过程（Functions and Procedures）|2 函数与存储过程（Functions and Procedures）]]
>     - [[Ch5 Advanced SQL#2.1 概念与动机|2.1 概念与动机]]
>     - [[Ch5 Advanced SQL#2.2 定义 SQL 函数|2.2 定义 SQL 函数]]
>     - [[Ch5 Advanced SQL#2.3 表函数（Table Function）|2.3 表函数（Table Function）]]
>     - [[Ch5 Advanced SQL#2.4 过程化构造：游标 FOR 循环|2.4 过程化构造：游标 FOR 循环]]
>     - [[Ch5 Advanced SQL#2.5 外部语言历程与安全|2.5 外部语言历程与安全]]
> - [[Ch5 Advanced SQL#3 触发器（Triggers）|3 触发器（Triggers）]]
>     - [[Ch5 Advanced SQL#3.1 触发器概念|3.1 触发器概念]]
>     - [[Ch5 Advanced SQL#3.2 行级触发器实例：credits_earned|3.2 行级触发器实例：credits_earned]]
>     - [[Ch5 Advanced SQL#3.3 语句级触发器与过渡表|3.3 语句级触发器与过渡表]]
>     - [[Ch5 Advanced SQL#3.4 何时不用触发器：风险与替代|3.4 何时不用触发器：风险与替代]]
> - [[Ch5 Advanced SQL#4 递归查询（Recursive Queries）|4 递归查询（Recursive Queries）]]
>     - [[Ch5 Advanced SQL#4.1 递归视图与传递闭包|4.1 递归视图与传递闭包]]
>     - [[Ch5 Advanced SQL#4.2 递归的表达力：固定次连接为何不够|4.2 递归的表达力：固定次连接为何不够]]
>     - [[Ch5 Advanced SQL#4.3 不动点计算示例|4.3 不动点计算示例]]
> - [[Ch5 Advanced SQL#5 高级聚合与 OLAP（Advanced Aggregation）|5 高级聚合与 OLAP（Advanced Aggregation）]]
>     - [[Ch5 Advanced SQL#5.1 排名函数族：RANK 与它的伙伴们|5.1 排名函数族：RANK 与它的伙伴们]]
>     - [[Ch5 Advanced SQL#5.2 分区排名与 Top-N|5.2 分区排名与 Top-N]]
>     - [[Ch5 Advanced SQL#5.3 窗口框架（Window Frame）|5.3 窗口框架（Window Frame）]]
>     - [[Ch5 Advanced SQL#5.4 OLAP 基础：多维数据、交叉报表与数据立方|5.4 OLAP 基础：多维数据、交叉报表与数据立方]]
>     - [[Ch5 Advanced SQL#5.5 CUBE 与 GROUPING 函数|5.5 CUBE 与 GROUPING 函数]]
>     - [[Ch5 Advanced SQL#5.6 ROLLUP 与分组集组合|5.6 ROLLUP 与分组集组合]]
>     - [[Ch5 Advanced SQL#5.7 OLAP 操作词汇与实现|5.7 OLAP 操作词汇与实现]]
> - [[Ch5 Advanced SQL#6 本章重难点与易错点汇总|6 本章重难点与易错点汇总]]
> - [[Ch5 Advanced SQL#7 综合例题（难度偏高）|7 综合例题（难度偏高）]]
> - [[Ch5 Advanced SQL#8 知识点速查|8 知识点速查]]
>     - [[Ch5 Advanced SQL#核心思想总结|核心思想总结]]

---

## 1 从编程语言访问 SQL

### 1.1 为什么需要编程语言：SQL 的边界

**通俗理解**：SQL 是"点菜式"语言——只说**要什么**，不说**怎么做**；但它也不会"做流程"：打印报表、弹窗问用户、把结果画成图形界面……这些"动起来"的事 SQL 一样都干不了。所以真实系统里，**SQL 永远被通用语言（Java、C、Python……）包着跑**。

**严谨说明**（课件 P3 原文）：

- 并非所有查询/操作都能用 SQL 表达——**SQL 不具备通用语言的完整表达能力**（SQL does not provide the full expressive power of a general-purpose language）；
- **非声明式动作**（non-declarative actions）——打印报表、与用户交互、把查询结果送到图形界面——**无法在 SQL 内部完成**。

| SQL 擅长 | SQL 干不了（要靠宿主语言） |
|---|---|
| 声明"我要什么"（查询、更新、约束） | 流程控制、循环、异常处理（过程化逻辑） |
| 集合层面的批量操作 | 打印、GUI、网络 IO 等**非声明式动作** |
| 优化器自动选择执行策略 | 复杂/数值计算（效率低甚至无法表达，见 [[#2.5 外部语言历程与安全\|2.5]]） |

### 1.2 两种接入方式：动态 API 与嵌入式 SQL

**通俗理解**：把程序和数据库接起来有两条路——**带电话本打电话**（程序拿着一组 API 函数，SQL 以字符串形式现说现打，灵活但编译器帮不了你）；或**把话术提前嵌进信里翻译**（嵌入式 SQL，写在源码里的 SQL 在**编译时**就被翻译成函数调用，编译器能查错）。

**严谨说明**（课件 P4）：通用语言访问 SQL 有**两种方式**：

| 方式 | 原理（课件原文） | 代表 |
|---|---|---|
| **API（动态）** | 程序用**一组函数**连接并与数据库服务器通信；SQL 作为字符串在运行时发送 | JDBC、ODBC |
| **嵌入式 SQL（静态）** | SQL 语句在**编译时**被翻译为函数调用（translated at compile time into function calls）；运行时这些函数调用通过提供动态 SQL 能力的 API 连接数据库 | 嵌入式 SQL、SQLJ |

> [!tip] 一句话抓本质
> 两条路**运行时殊途同归**（最终都经 API 发给数据库），差别只在**检查时机**：动态方式连 SQL 写错都是运行时才炸；静态方式在编译期就被预处理器查一遍。**JDBC 求灵活，SQLJ 求编译期安全**（见 [[#1.8 SQLJ：编译期检查的嵌入式 SQL|1.8]]）。

---

### 1.3 JDBC：连接、语句与结果集

**通俗理解**：JDBC 是 Java 世界的"数据库万能遥控器"——一套 Java API，负责：连上库、发 SQL、收结果、查库的"户口信息"（元数据）。

**严谨定义**（课件 P6）：JDBC 是 **Java 与支持 SQL 的数据库系统通信的 API**，支持查询/更新/取结果、以及**元数据检索**（查询数据库里有哪些关系、属性的名字与类型）。

**通信模型四步**（课件原文的 model）：

```text
① Open a connection        打开连接
② Create a "statement"     创建 statement 对象
③ Execute queries ...      用 statement 发查询、取回结果
④ Exception mechanism      用异常机制处理错误
```

**标准写法**（课件 P7 + P9 合并，Java 7 / JDBC 4 起的 try-with-resources 风格）：

```java
try (Connection conn = DriverManager.getConnection(
         "jdbc:oracle:thin:@db.yale.edu:2000:univdb", userid, passwd);
     Statement stmt = conn.createStatement()) {

    // 更新：executeUpdate，返回受影响行数
    stmt.executeUpdate(
        "insert into instructor values('77987', 'Kim', 'Physics', 98000)");

    // 查询：executeQuery，返回 ResultSet
    ResultSet rset = stmt.executeQuery(
        "select dept_name, avg(salary) from instructor group by dept_name");
    while (rset.next()) {                                  // 游标式逐行前进
        System.out.println(rset.getString("dept_name") + " " +
                           rset.getFloat(2));
    }
} catch (SQLException sqle) {
    System.out.println("SQLException: " + sqle);
}
```

| 要点 | 说明 |
|---|---|
| `try (…)` 自动关闭 | Java 7 / JDBC 4 起推荐；**连接与语句用完自动释放**，不必手写 `close()` |
| 旧式写法（课件 P8） | `Class.forName("oracle.jdbc.driver.OracleDriver")` 手动加载驱动——**JDBC 4 起已不需要**；且必须在 finally/末尾手动 `stmt.close(); conn.close();` |
| `executeUpdate` vs `executeQuery` | 前者跑 `insert/update/delete`，返回**受影响行数**；后者跑 `select`，返回 `ResultSet` |
| 取值 | `rset.next()` 前进一行（返回 false 表示没更多了）；`getString("列名")` 或 `getFloat(2)`（按位置） |

> [!info] 课件的 JDBC 知识地图（P10 子节清单）
> 连接数据库 → 发送 SQL 语句 → 异常与资源管理 → 取回查询结果 → **预编译语句** → **可调用语句** → **元数据** → 其他特性 → **Python 访问数据库**。
> Python 一条课件未展开（补充：Python 生态对应物是 **DB-API 2.0（PEP 249）**，`connect → cursor → execute → fetch*`，风格与 JDBC 同构）。

---

### 1.4 ResultSet 读值细节与 NULL 处理

**通俗理解**：查完的结果是一张"游标指着的表"，一行行往后读；读的时候有三个坑：**列号从 1 开始**、**按名取和按号取等价**、**NULL 读出来长得像 0**。

**严谨说明**（课件 P11）：

```java
// ① 两种取值等价（dept_name 是结果第一列时）
rs.getString("dept_name")   ≡   rs.getString(1)

// ② NULL 处理：必须用 wasNull() 二次确认
int a = rs.getInt("a");
if (rs.wasNull()) System.out.println("Got null value");
```

三个细节，条条是考点：

1. **列下标从 1 开始**（`getString(1)` 是第一列）——Java 数组的 0 基习惯会让你写成 `get(0)` 直接越界；
2. **`wasNull()` 判定的是"最近一次 getXXX"**——必须**紧跟**在取值之后调用，中间再读别的列就把标记冲掉了；
3. **`getInt` 遇到 SQL NULL 只能返回 Java 零值 `0`**——于是 `0` 有了两义：**真 0** 还是 **NULL**。这正是"取值 + wasNull"两步走的原因。

> [!warning] 易错点：`getFloat(2)` 对 NULL 组返回 0.0
> `avg(salary)` 在空分组上返回 NULL（见 [[Ch3 Intro to Sql#6 聚合函数与分组（GROUP BY HAVING）|Ch3 聚合的 NULL 规则]]），JDBC 读出来是 `0.0f`——**报表上会把"无数据"显示成"平均工资 0"**，业务上是两种完全不同的含义。正确姿势：

```java
float avg = rset.getFloat(2);
if (rset.wasNull()) System.out.println("N/A");
else                System.out.println(avg);
```

---

### 1.5 PreparedStatement 与 SQL 注入

**通俗理解**：把用户输入**拼字符串**造 SQL，等于让陌生人往你的合同里"填空"——他填的可能不是名字，而是"或者全部条件为真"的后门短语。**预编译语句把"合同模板"和"填空数据"分开送**：模板数据库只看一次、永不改变；数据无论多怪都只是数据。

**语法与复用**（课件 P12）：

```java
PreparedStatement pStmt = conn.prepareStatement(
    "insert into instructor values(?,?,?,?)");   // ① ? 是占位符，先送模板
pStmt.setString(1, "88877");                     // ② 按位置填值（1 基！）
pStmt.setString(2, "Perry");
pStmt.setString(3, "Finance");
pStmt.setInt(4, 125000);
pStmt.executeUpdate();                           // ③ 执行
pStmt.setString(1, "88878");                     // ④ 改几个值，再执行
pStmt.executeUpdate();                           //    模板复用
```

课件的 **WARNING**（原文力度）：

> always use prepared statements when taking an input from the user and adding it to a query
> **NEVER** create a query by concatenating strings
> —— 拼接会怎样？`name` 是 `D'Souza` 时，那个单引号直接把 SQL 字符串**戳断**，轻则语法错误，重则变成注入面。

**SQL 注入推演**（课件 P13 完整例子）：

```java
// 危险代码：字符串拼接
"select * from instructor where name = '" + name + "'"
```

若用户输入的不是名字，而是：

```text
X' or 'Y' = 'Y
```

拼出的真实语句就变成：

```sql
select * from instructor where name = 'X' or 'Y' = 'Y'
--                                          ^^^^^^^^^^^ 恒为真 → 返回全表！
```

更凶的输入：

```text
X'; update instructor set salary = salary + 10000; --
```

```sql
select * from instructor where name = 'X'; update instructor set salary = salary + 10000; --
--   查询                              ↑ 语句一结束，后门更新紧跟其后， -- 注释掉残余部分
```

**预编译语句为什么免疫**（课件原文）：prepared statement 内部把值做转义后**作为数据**发送——

```text
select * from instructor where name = 'X\' or \'Y\' = \'Y'
-- 整段都是"要匹配的字符串值"，结构（谓词骨架）永远由模板唯一确定
```

| | 字符串拼接 | PreparedStatement |
|---|---|---|
| SQL 结构 | 由用户输入**参与决定** → 可被改写 | **模板固定**，运行时不可变 |
| 用户输入身份 | 代码（可含 `' ; --`） | **纯数据**（自动转义） |
| `D'Souza` | 截断字符串 → 出错/被注入 | 正常按名字匹配 |
| 模板复用 | 每次重新拼、重新解析 | 模板只送一次，多次填值执行 |

> [!warning] 细节补充：`?` 只能出现在"值"的位置
> 占位符**不能**用于表名、列名、`order by` 的方向词等（这些是"结构"不是"值"）——想让用户决定排序字段，必须用**白名单映射**（服务端写死允许的列名），没有任何转义手段能安全地把"结构"参数化。

---

### 1.6 元数据（Metadata）：让程序理解数据库

**通俗理解**：元数据 = "**关于数据的数据**"——让程序不写死表结构，也能"看见"库里有什么：有哪些表？每列叫什么、什么类型？主键是哪几列？（课件两连问 "How is this useful?"——答案：**报表工具、管理界面、ORM 框架这类通用程序，靠它做到"换个数据库照样跑"**。）

**三类元数据**（课件 P14–P17）：

| 类型 | 获取方式 | 能回答什么 |
|---|---|---|
| **ResultSet 元数据** | `rs.getMetaData()` → `ResultSetMetaData` | 这次查询的结果**有几列**、列名、列类型 |
| **Database 元数据** | `conn.getMetaData()` → `DatabaseMetaData` | 这个库里**有哪些表**、某表**有哪些列** |
| **主键发现** | `dbmd.getPrimaryKeys("", "", tableName)` | 某表的主键列及**位置**（`KEY_SEQ`） |

```java
// 结果集元数据：遍历列名与类型
ResultSetMetaData rsmd = rs.getMetaData();
for (int i = 1; i <= rsmd.getColumnCount(); i++) {
    System.out.println(rsmd.getColumnName(i));
    System.out.println(rsmd.getColumnTypeName(i));
}

// 数据库元数据：department 表的全部列
// 参数：Catalog, Schema-pattern, Table-pattern, Column-Pattern
ResultSet rs = dbmd.getColumns(null, "univdb", "department", "%");
while (rs.next())
    System.out.println(rs.getString("COLUMN_NAME") + " " + rs.getString("TYPE_NAME"));

// 列出库里的表：参数最后一个是"表类型"数组
ResultSet rs = dbmd.getTables("", "", "%", new String[] {"TABLES"});
```

**通配符语义**（课件原文，记住三件套）：

| 参数值 | 含义 |
|---|---|
| `null` | 匹配**所有** Catalog / Schema |
| `""` | 匹配**当前** Catalog / Schema |
| `"%"` | 与 SQL **LIKE 子句**同义（任意字符序列） |

**主键与组合键**（P17）：`getPrimaryKeys` 返回的 `KEY_SEQ` 是该属性在主键中的**位置**——主键由多列组成时靠它还原列序。

> [!warning] 课件笔误：`"TABLES"` 应为 `"TABLE"`
> JDBC 标准的表类型取值是单数 **`"TABLE"`**（另有 `"VIEW"` 等）——照抄课件的 `{"TABLES"}` 会**一张表都匹配不到**。以 JDK 文档为准，这是"照抄课件代码"的典型翻车点。

---

### 1.7 JDBC 中的事务控制与高级特性

**事务**（课件 P18）——默认行为与手控开关：

| 状态 | 行为 | 风险/用法 |
|---|---|---|
| **默认（autocommit on）** | **每条 SQL 各自成一个事务、自动提交** | 对"多条更新才算一笔业务"的场景是 **bad idea**（课件原话） |
| `conn.setAutoCommit(false)` | 关闭自动提交 → 后续语句进入同一事务 | 转账等多步更新必须先关 |
| `conn.commit()` / `conn.rollback()` | 显式**提交** / **回滚**当前事务 | 与 [[Ch4 Intermediate SQL#3 事务（Transactions）|Ch4 事务语义]]完全对应 |
| `conn.setAutoCommit(true)` | 恢复自动提交 | 用完记得恢复默认 |

```java
conn.setAutoCommit(false);
try {
    stmt.executeUpdate("update account set balance = balance - 1000 where acc_no = 'A'");
    stmt.executeUpdate("update account set balance = balance + 1000 where acc_no = 'B'");
    conn.commit();
} catch (SQLException e) {
    conn.rollback();     // 异常路径必须回滚，否则事务悬着不结束
}
```

**其他特性速览**（课件 P19）：

| 特性 | 写法 | 说明 |
|---|---|---|
| 调用函数/过程 | `conn.prepareCall("{? = call some function(?)}")`<br>`conn.prepareCall("{call some procedure(?,?)}")` | `CallableStatement`，`?=` 是返回值占位 |
| 大对象读取 | `getBlob()` / `getClob()` | 类似 `getString`，但返回 `Blob` / `Clob` 对象；二进制用 `getBytes()` 取 |
| 大对象写入 | `blob.setBlob(parameterIndex, inputStream)` | 关联一个**打开的流**来更新大对象 |

> [!info] 学习资源
> 课件 P20 给出官方教程：[JDBC Basics Tutorial](https://docs.oracle.com/javase/tutorial/jdbc/index.html)。

---

### 1.8 SQLJ：编译期检查的嵌入式 SQL

**通俗理解**：JDBC 的 SQL 是字符串，写错了**编译器一声不吭，运行时才爆炸**。SQLJ 的做法是把 SQL **直接写进 Java 源码**（`#sql ...`），交给预处理器在**编译期**检查——错误提前暴露。

**严谨说明**（课件 P21）：

- 动机原文：**JDBC is overly dynamic, errors cannot be caught by compiler**；
- SQLJ = **在 Java 中嵌入 SQL**，用 `#sql` 标记；`#sql iterator` 声明**迭代器类型**（对应结果集的行类型）。

```java
// 声明迭代器：每个结果行是 (String dept_name, int avgSal)
#sql iterator deptInfoIter (String dept_name, int avgSal);

deptInfoIter iter = null;
#sql iter = { select dept_name, avg(salary) from instructor group by dept_name };
while (iter.next()) {
    String deptName = iter.dept_name();
    int   avgSal    = iter.avgSal();
    System.out.println(deptName + " " + avgSal);
}
iter.close();
```

| | JDBC | SQLJ |
|---|---|---|
| SQL 存在形式 | 字符串（运行时拼/送） | 源码内嵌 `#sql`（编译期翻译） |
| 错误发现时机 | **运行时** | **编译期** |
| 结果遍历 | `ResultSet` + `next()` | **迭代器** + `next()` |
| 灵活性 | 高（SQL 可动态生成） | 低（SQL 须在编译期确定） |

---

### 1.9 ODBC 与嵌入式 SQL：游标四部曲

**ODBC**（课件 P22–P23）：**Open DataBase Connectivity**——应用程序与数据库服务器通信的**标准**；提供一组 API：**开连接、发查询与更新、取回结果**；GUI、电子表格等通用软件都靠它（补充：ODBC 是 C 接口的跨语言标准，JDBC 可视为它在 Java 世界的对应物）。

**嵌入式 SQL**（课件 P24–P29，SQL 标准组成部分）：

- **宿主语言（host language）**：SQL 被嵌入的那种语言——标准定义了 C、C++、Java、Fortran、PL/1 等多种嵌入形式，传统源自 **System R 把 SQL 嵌入 PL/1**；
- **标记**：`EXEC SQL <嵌入语句>;` 交给**预处理器**识别——不同语言有变体（COBOL 用 `END-EXEC` 结尾；Java 嵌入用 `#sql { … };`）。

```sql
-- 连接（执行任何 SQL 前必须先连）
EXEC-SQL connect to server user user-name using password;

-- 宿主变量：冒号 : 前缀与 SQL 变量区分，且必须先在 DECLARE SECTION 中声明
EXEC-SQL BEGIN DECLARE SECTION;
    int credit_amount;
EXEC-SQL END DECLARE SECTION;
```

**游标四部曲**——嵌入式 SQL 处理多行结果的完整生命周期（课件 P26–P28，本节核心）：

```sql
-- ① declare：只声明，不执行
EXEC SQL
    declare c cursor for
        select ID, name from student
        where tot_cred > :credit_amount
END_EXEC

-- ② open：此刻才执行查询，结果存入临时关系；
--        也在此刻读取宿主变量 :credit_amount 的当前值
EXEC SQL open c;

-- ③ fetch：逐元组取进宿主变量；SQLSTATE 变 '02000' = 没有更多数据
EXEC SQL fetch c into :si, :sn END_EXEC

-- ④ close：删除保存结果的临时关系
EXEC SQL close c;
```

**更新当前行**（P29）：游标可以"边遍历边改"——声明时加 `for update`，取到某行后用 `where current of c` 精准更新它：

```sql
EXEC SQL
    declare c cursor for
        select * from instructor
        where dept_name = 'Music'
        for update
END_EXEC
-- 每 fetch 一行后执行：
update instructor set salary = salary + 1000 where current of c;
```

> [!warning] 四个高频细节
> 1. **`open` 时刻取宿主变量**：`credit_amount` 的值在 **open 执行的那一刻**被读取——open 之后再改宿主变量，**不会**改变已打开游标的结果集（课件原文点名此语义）；
> 2. **`SQLSTATE = '02000'`** 是"取完了"的标准信号——fetch 循环靠它终止；
> 3. **`close` 是真删除**：删掉装结果的临时关系，不是"指针归零"；
> 4. Java 嵌入的写法不同：用**迭代器**代替 fetch/close（与 [[#1.8 SQLJ：编译期检查的嵌入式 SQL|1.8]] 同一套思想）。

---

## 2 函数与存储过程（Functions and Procedures）

### 2.1 概念与动机

**通俗理解**：把反复用到的业务逻辑"打包存进数据库"，以后一句 SQL 就能调它——就像把常用工具钉在墙上，随取随用，而不是每次现做。

**严谨说明**（课件 P31）：

- 函数与过程（functions and procedures）允许把 **"业务逻辑"（business logic）存储在数据库中，并从 SQL 语句执行**；
- 可以用 **SQL 的过程化组件**定义，也可以用**外部语言**（Java、C、C++）定义；
- 课件给出的是 **SQL 标准语法**——**多数数据库实现的是非标准版本**（原话：Most databases implement nonstandard versions of this syntax）。

> [!warning] 先打预防针
> 本章的 PL 风格语法（`create function ... begin ... end`、`for r as select ...`）在不同 DBMS 里差异很大：Oracle 是 PL/SQL、SQL Server 是 T-SQL、MySQL 又是另一种——**考试以课件标准语法为准，落地查对应系统手册**（课件自己也这么提醒）。

---

### 2.2 定义 SQL 函数

**例子**（课件 P32）：给定系名，返回该系教师数：

```sql
create function dept_count (dept_name varchar(20))
returns integer
begin
    declare d_count integer;
    select count(*) into d_count
        from instructor
        where instructor.dept_name = dept_name;
    return d_count;
end

-- 调用：查教师超过 12 人的系的系名与预算
select dept_name, budget
from department
where dept_count(dept_name) > 12;
```

逐行拆解：

| 要素 | 作用 |
|---|---|
| `dept_name varchar(20)` | **形参**——调用时传入的系名 |
| `returns integer` | 标量返回类型（返回**一个值**） |
| `select ... into d_count` | 把查询结果**写进局部变量**（过程化 SQL 特有机制） |
| `count(*)` 聚合 | 即使系不存在也返回 **0 行聚合结果 = 0**，不会"取不到值"出错 |
| `where dept_count(dept_name) > 12` | 函数在查询中**像内置函数一样调用** |

> [!warning] 易错点 1：形参与列同名，右侧到底指谁
> `where instructor.dept_name = dept_name`——左边被**限定符**明确成"列"，右边 `dept_name` **既像列又像参数**：标准的意图是"参数"，但**同名极易读错，部分实现会直接报歧义错误**。工程规范：**参数改名**（如 `p_dept_name`），一眼分清：

```sql
create function dept_count (p_dept_name varchar(20)) ...   -- 参数带前缀，永不歧义
```

> [!warning] 易错点 2：函数在 WHERE 里是"每行调用"
> `dept_count(dept_name) > 12` 对 `department` 的**每一行都执行一次**——若函数内部是聚合子查询，就是 N 次子查询，性能堪忧（工程上这类需求更适合 `group by + having`，或建索引/物化汇总）。**能用集合操作一次算完的，别用逐行函数硬算**。

---

### 2.3 表函数（Table Function）

**通俗理解**：普通函数返回"一个数"，**表函数返回"一整张表"**——所以它能出现在 `from` 里，像一张真表那样被查询。

**例子**（课件 P33）：返回某系的全体教师：

```sql
create function instructor_of (dept_name char(20))
returns table (
    ID         varchar(5),
    name       varchar(20),
    dept_name  varchar(20),
    salary     numeric(8,2))
return table
(select ID, name, dept_name, salary
 from instructor
 where instructor.dept_name = instructor_of.dept_name);

-- 使用：表函数必须用 table( ) 包装后放进 from
select * from table (instructor_of ('Music'));
```

三个细节：

1. **`returns table (列清单)`**——返回类型就是一张关系的模式；
2. **`instructor_of.dept_name`**：函数体里列名 `dept_name` 与参数 `dept_name` **同名**，此处**用函数名限定参数**（`函数名.参数名`）——这正是 2.2 警告的歧义问题的课件标准解法；
3. **`table(…)` 包装**：表函数在 `from` 中必须包一层，标记"这是函数调用产生的关系"。

| | 标量函数（2.2） | 表函数（2.3） |
|---|---|---|
| 返回 | 单个值 | **一张表**（含模式定义） |
| 出现位置 | `select` / `where` 等表达式处 | **`from` 中**（`table(f(…))`） |
| 课件例子 | `dept_count(...)` | `instructor_of(...)` |

---

### 2.4 过程化构造：游标 FOR 循环

**通俗理解**：把"查一批、逐条处理"的套路缩成一个循环——SQL 帮你打开游标、逐行迭代、自动收尾。

**例子**（课件 P34）：求 Music 系的预算总和：

```sql
declare n integer default 0;
for r as
    select budget from department
    where dept_name = 'Music'
do
    set n = n + r.budget;
end for
```

- `for r as <查询> do … end for`：`r` 是**行变量**，循环体每轮拿到结果的一行（等价于"声明游标 → open → 反复 fetch → close"的语法糖，与 [[#1.9 ODBC 与嵌入式 SQL：游标四部曲|1.9 游标四部曲]] 是同一思想的过程化封装）；
- `declare n integer default 0` / `set n = n + r.budget`：**变量声明与赋值**是过程化 SQL 的基本件。

---

### 2.5 外部语言历程与安全

**通俗理解**：有些活 SQL 干不了或干得慢（复杂计算）——允许你用 **C/Java 写函数，挂到数据库里**，SQL 里直接调。但"让外来代码进数据库"是**引狼入室**级别的安全问题，必须管起来。

**声明**（课件 P35）：

```sql
create procedure dept_count_proc (in dept_name varchar(20), out count integer)
    language C
    external name '/usr/avi/bin/dept_count_proc';

create function dept_count (dept_name varchar(20))
    returns integer
    language C
    external name '/usr/avi/bin/dept_count';
```

- **动机**（课件原文）：比 SQL 定义的函数**更高效**；**SQL 无法完成的计算**可以执行；
- `in` / `out` 参数方向；`language C` 指定实现语言；`external name` 指向外部可执行代码。

**安全方案**（课件 P36，三种方式对比）：

| 方案 | 做法 | 代价 |
|---|---|---|
| **沙箱（sandbox）** | 用**安全语言**（如 Java）实现——它无法访问/破坏数据库的其他部分 | 语言能力受限 |
| **独立进程** | 外部函数在**单独进程**运行，**不接触数据库进程内存**；参数与结果经**进程间通信（IPC）**交换 | IPC 开销 |
| **直接执行** | 在数据库系统地址空间直接跑 | **无隔离，风险最高** |

课件原话：前两种**都有性能开销**（Both have performance overheads）；多数数据库系统**三种都支持**（含直接执行）。

> [!important] 权衡记法
> **效率 ↔ 隔离**二选一：要快就直接执行（信任你的代码），要稳就沙箱/独立进程（付开销）。这与操作系统里"系统调用 vs 库函数"的信任边界是同一种思想。

---

## 3 触发器（Triggers）

### 3.1 触发器概念

**通俗理解**：触发器 = 绑在数据修改上的**自动机关**——有人动了数据，它**不由分说**替你把"该顺手做的事"做掉（维护汇总、记审计日志、连锁更新）。

**严谨定义**（课件 P38）：触发器是**作为数据库修改的副作用（side effect），由系统自动执行的语句**（a statement that is executed automatically by the system as a side effect of a modification to the database）

设计一个触发器必须回答**两问**（课件原文）：

1. **何时执行**——Specify the **conditions** under which the trigger is to be executed；
2. **执行什么**——Specify the **actions** to be taken when the trigger executes。

|      | 完整性约束（[[Ch4 Intermediate SQL#4 完整性约束（Integrity Constraints）Ch4 §4]]） | 触发器                    |
| ---- | -------------------------------------------------------------------- | ---------------------- |
| 哲学   | **拒绝**不合法的数据                                                         | 数据一变就**自动做别的事**        |
| 典型用途 | 主键、外键、check、断言                                                       | 维护派生值（学分/汇总）、审计、级联     |
| 表达力  | 只能"接受/拒绝"                                                            | 任意过程化动作体               |
| 标准化  | 各系统高度一致                                                              | SQL:1999 才进标准，**方言味重** |

> [!warning] 语法声明（课件原文的免责声明）
> 触发器 **SQL:1999 才进入 SQL 标准**，此前多数数据库早已用**非标准语法**支持它——**课件语法在你的数据库上可能不完全工作，查系统手册**。下面所有例子按课件标准语法掌握。

---

### 3.2 行级触发器实例：credits_earned

**场景**：`student.tot_cred`（累计学分）应当随 `takes.grade`（成绩）变化自动维护——学生把挂科/未评分的课**修及格了**，学分才加上。

**例子**（课件 P39，逐要素标注）：

```sql
create trigger credits_earned
after update of takes on (grade)          -- ① 时机：takes 的 grade 列更新之后
referencing new row as nrow               -- ② 新旧行别名
referencing old row as orow
for each row                             -- ③ 粒度：行级（每受影响行触发一次）
when nrow.grade <> 'F' and nrow.grade is not null   -- ④ 条件：新成绩有效且非 F
     and (orow.grade = 'F' or orow.grade is null)   --    且旧成绩是 F / 未评分
begin atomic                             -- ⑤ 动作体（原子执行）
    update student
       set tot_cred = tot_cred + (select credits
                                    from course
                                   where course.course_id = nrow.course_id)
     where student.id = nrow.id;
end;
```

**语义一句话**：**成绩从「F / 未评分」变成「有效非 F」的那一刻，把这门课的学分加进 tot_cred**——其他任何成绩变动（B→C、A→F……）都不加。

逐要素表：

| 要素 | 课件写法 | 含义 |
|---|---|---|
| 触发时机 | `after update of takes on (grade)` | 只对 `takes` 表 `grade` **列**的 UPDATE 生效（insert/delete 不触发） |
| 行别名 | `referencing new row as nrow / old row as orow` | 动作体/条件里用 `nrow.` `orow.` 访问修改前后的行 |
| 粒度 | `for each row` | **逐行**触发（与语句级相对，见 [[#3.3 语句级触发器与过渡表|3.3]]） |
| 触发条件 | `when (…)` | 不满足就**整个跳过**，动作体不执行 |
| 动作体 | `begin atomic … end` | 一条（组）更新，原子执行 |

> [!important] ⚠️ 例子的隐藏 bug：只加不减，还会重复加
> 这是"教材例子能考试、生产代码不能照抄"的典型，两个缺陷：
>
> 1. **只加不减**：成绩后来变成 `F`（A→F）时 `when` 不满足 → 学分**不会扣回**；
> 2. **重复加**：`B → F → B`（重修场景）会两次满足"旧=F 且新=非F" → **同一门课学分被加两次**，`tot_cred` 虚增。
>
> 严谨修法是**差值式**——按"旧成绩算一次、新成绩算一次"的差更新（示意）：
>
> ```sql
> -- 语义：新有效则加 c，旧有效则减 c（伪代码级，方言自行适配）
> tot_cred = tot_cred + (CASE WHEN nrow 有效 THEN c ELSE 0 END)
>                      - (CASE WHEN orow 有效 THEN c ELSE 0 END)
> ```
>
> 或定期用 [[Ch4 Intermediate SQL#4.7 断言（ASSERTION）|Ch4 的断言思路]]做全量对账兜底。

---

### 3.3 语句级触发器与过渡表

**通俗理解**：行级是"来一行动一次"；语句级是"整批改完只动一次"——改一万行时，一次汇总当然比一万次触发快。

**严谨说明**（课件 P40）：

- 不对每个受影响行分别执行，而是**对一条语句影响的全部行执行一次动作**：`for each row` → **`for each statement`**；
- 引用整批数据用 **`referencing old table` / `referencing new table`**，得到包含受影响行的**临时表**——称为**过渡表（transition tables）**；
- **何时更好**：处理**更新大量行**的 SQL 时更高效（课件原文：Can be more efficient when dealing with SQL statements that update a large number of rows）。

| | 行级（for each row） | 语句级（for each statement） |
|---|---|---|
| 触发次数 | 每受影响行 1 次 | 每条语句 1 次 |
| 引用方式 | `old row` / `new row`（单行别名） | `old table` / `new table`（**过渡表**） |
| 擅长 | 逐行精细判断（如 credits_earned 的 when） | 整批汇总、批量审计、大批量更新 |
| 大批量性能 | 差（N 次触发） | **好**（1 次） |

---

### 3.4 何时不用触发器：风险与替代

**曾经的用途**（课件 P41）：① 维护汇总数据（如每系工资总额）；② 通过把变更记进**变更/增量关系（change / delta relations）**再由单独进程应用到副本，实现**数据库复制**。

**如今有更好的替代**（课件原文逐条对应）：

| 老用法 | 新方案 |
|---|---|
| 触发器维护汇总 | 数据库内置的**物化视图**设施（见 [[Ch4 Intermediate SQL#2.4 物化视图（Materialized View）|Ch4 §2.4]]） |
| 触发器记 delta 做复制 | 数据库**内置复制支持** |
| 触发器捎带业务动作 | **封装（encapsulation）**：定义更新方法（method），动作写在方法里随更新执行 |

**风险清单**（课件 P42）：

1. **意外触发**：
   - 从**备份副本加载数据**、在远程站点**复制更新**——这些本意是"搬运"，却会把触发器挨个点着；
   - 对策：此类操作前**禁用触发器**（Trigger execution can be disabled before such actions）；
2. **错误传播**：触发器里的错误会导致**引发它的关键事务失败**——顺手的副作用变成了要害；
3. **级联执行（cascading execution）**：触发器触发触发器，链式乃至循环执行——轻则性能雪崩，重则停不下来。

> [!tip] 工程经验三条
> ① 触发器**隐式改变行为**——看一条 `update` 语句，永远不知道它背后还干了什么（**调试黑洞**），重要逻辑尽量显式；② 能用约束解决的别用触发器，能用物化视图的别用触发器；③ 写触发器必须自问"**批量导入/复制时它会不会开火**"。

---

## 4 递归查询（Recursive Queries）

### 4.1 递归视图与传递闭包

**通俗理解**："这门课的**直接**先修课"好查，"**间接**也算"的先修链就麻烦了——A 先修 B、B 先修 C，那 C 也是 A 的先修（不管隔几层）。**递归查询就是"自己调自己"，一层层把关系接龙接下去，直到再也接不出新的为止**。

**严谨定义**（课件 P44）：**SQL:1999 允许递归视图定义（permits recursive view definition）**。课件例子——求某门课的（直接或间接）先修课：

```sql
with recursive rec_prereq (course_id, prereq_id) as (
    -- ① 基础项（seed）：直接先修
    select course_id, prereq_id
    from prereq
    union
    -- ② 递归项：已知的先修关系 接上 直接先修
    select rec_prereq.course_id, prereq.prereq_id
    from rec_prereq, prereq
    where rec_prereq.prereq_id = prereq.course_id
)
select * from rec_prereq;
```

> 课件 P44 源码笔误两处：把 `rec_prereq` 写成了 `rec_rereq`，且投影里多了个逗号——按正确拼写掌握。
> 课件以"**递归视图**"形式给出（`with recursive 视图名 as (...)`，SQL:1999 允许 `create recursive view`）；多数 DBMS 提供的查询写法是 `with recursive` 公用表表达式——**同一语义的两种载体**。

**结果是什么：传递闭包**（transitive closure，课件原话）。设直接先修关系为 $R$，则

$$R^{+} \;=\; R \cup R^{2} \cup R^{3} \cup \cdots \qquad\text{（}R^{k}\text{ 表示长度为 }k\text{ 的先修链）}$$

它必须满足**不动点方程**（自举定义——"全部先修 = 直接先修 ∪ 先修的先修"）：

$$\mathrm{rec\_prereq} \;=\; \mathrm{prereq} \;\cup\; \{\, (a, c) \mid (a, b) \in \mathrm{rec\_prereq},\ (b, c) \in \mathrm{prereq} \,\}$$

**执行过程通俗版**（迭代到稳定，即**求最小不动点**）：

```text
第 0 轮：结果 = prereq（直接先修）
第 1 轮：结果 ⋈ prereq 拼出"隔一层"的关系，并入结果（去重）
第 2 轮：再拼出"隔两层"……
……直到某一轮并入的新元组为 0 → 结果稳定 → 停止
```

> [!warning] 为什么必须是 `union` 而不是 `union all`
> 迭代靠**去重**收敛：一旦某轮的产出与已有结果完全相同，新元组数为 0，循环结束。若用 `union all`（不去重），**同样的元组会被反复产出**，结果集无限膨胀、**永不终止**。递归查询收敛的命门就在这一个词上。

> [!info] 与 [[Ch4 Intermediate SQL#2.3 视图套视图：依赖与视图展开|Ch4 视图展开]] 的关系（重要衔接）
> Ch4 讲过：**视图展开算法对递归视图不终止**（代入法陷入 `v → v → …`）。本节给出另一半答案：**SQL:1999 确实允许递归视图**——它的语义**不由展开定义**，而由这里的**不动点迭代**定义。展开管非递归，不动点管递归，两者拼起来才是完整的视图语义。

---

### 4.2 递归的表达力：固定次连接为何不够

**通俗理解**：不许用递归、也不许写循环，你只能"把 `prereq` 和自己连 k 次"——**k 是写死的数字**，那最多只能看清 k 层深的先修链；可先修链的深度是**数据说了算**的。递归的本质能力就是"**层数由数据决定，不由查询文本决定**"。

**严谨论证**（课件 P45 原文逻辑）：

- 非递归、非迭代的程序只能对 `prereq` 做**固定次数**的自连接——

$$R^{(k)} \;=\; R \cup R^{2} \cup \cdots \cup R^{k} \qquad (k \text{ 是查询文本里的常数})$$

- **反证构造**：给定任意一个用了 k 次连接的查询，**构造一条深度超过 k 的先修链**（或管理层级超过 k 的组织树），这个查询就**必然漏掉**链尾的传递关系——**总有一座它看不见的山**；
- 替代方案：写一个**过程**，按需迭代任意多次（教材 `findAllPrereqs` 过程，见书）——**用过程化的"循环次数不定"换掉递归**。

| 方案 | 层数由谁决定 | 代表 |
|---|---|---|
| 固定 k 次自连接 | **查询文本**（写死） | `R ⋈ R ⋈ R`（k 层封顶） |
| 递归查询 | **数据**（到稳定为止） | `with recursive` / 递归视图 |
| 过程迭代 | 数据（循环内计数） | `findAllPrereqs` 存储过程 |

---

### 4.3 不动点计算示例

课件 P46 用一组配图演示**不动点计算（Fixed-Point Computation）** 的逐步过程：从初始元组集出发，每轮用"已有结果 × 基本关系"推出新元组并入，直到集合不再增长（$T_{i+1} = T_i$）——此时 $T$ 就是不动点，即传递闭包。

![[Ch5-img-p46-178.jpeg]] ![[Ch5-img-p46-177.jpeg]]

> 图注：课件 P46 "Example of Fixed-Point Computation" 配图（上：初始状态；下：迭代至稳定的结果）。结合 [[#7 综合例题（难度偏高）|例题 8]] 手算一遍，不动点的每一步就都清楚了。

---

## 5 高级聚合与 OLAP（Advanced Aggregation）

### 5.1 排名函数族：RANK 与它的伙伴们

**通俗理解**：普通 `group by` 把行**压扁成汇总**，排名函数则**给每一行发个名次**，行数不变——"每个学生在全班排第几"就靠它。

**严谨定义与基本语法**（课件 P48）：

- **排名必须配合 `order by`**（Ranking is done in conjunction with an order by specification）——名次永远是"按某个序"的名次；
- 基础例子（`student_grades(ID, GPA)`）：

```sql
select ID, rank() over (order by GPA desc) as s_rank
from student_grades;
```

- ⚠️ **窗口里的 `order by` 只定名次序，不保证输出行序**——要让结果集按名次排好，**还得再写最外层 `order by`**（课件原话：An extra order by clause is needed to get them in sorted order）：

```sql
select ID, rank() over (order by GPA desc) as s_rank
from student_grades
order by s_rank;         -- 外层这个才是"结果排序"
```

**排名函数族对照**（课件 P48/P50/P51/P52）：

| 函数 | 语义 | 关键特性 |
|---|---|---|
| `rank()` | 并列同名次，**留空洞** | 2 人并列第 1 → 下一个是 **3** |
| `dense_rank()` | 并列同名次，**不留空洞** | 2 人并列第 1 → 下一个是 **2** |
| `row_number()` | 纯行号（1,2,3…） | **并列时分配不确定**（non-deterministic in presence of duplicates） |
| `percent_rank()` | 相对位置百分比 | 见下方公式 |
| `cume_dist()` | 累积分布 | "≤ 当前值的元组占比" |
| `ntile(n)` | 分桶 | 把分区内有序元组**均分进 n 个桶**（如四分位 `ntile(4)`） |

**百分位公式**（记号：分区内共 $N$ 行，当前 `rank` 为 $r$）：

$$\text{percent\_rank} = \frac{r - 1}{N - 1}, \qquad \text{cume\_dist} = \frac{\#\{\text{值} \le \text{当前值的行}\}}{N}$$

**并列规则**：`order by` 键值相同的行拿**相同名次**（rank/dense_rank 都如此）；`row_number` 则给并列行**任意**编出连续号。

**NULL 排序位置可指定**（SQL:1999，课件 P51）：

```sql
select ID, rank() over (order by GPA desc nulls last) as s_rank from student_grades;
-- 还可 nulls first；不写则依实现默认
```

**为什么不用朴素写法**（课件 P49）：

```sql
-- 朴素排名：数"比我高的" + 1 —— 语义对，效率差
select ID, (1 + (select count(*) from student_grades B
                  where B.GPA > A.GPA)) as s_rank
from student_grades A
order by s_rank;
```

- 朴素写法对**每行**执行一次子查询 → $O(N^2)$ 次比较（课件原话：resultant query is **very inefficient**）；
- 窗口函数一遍排序即可完成 → $O(N \log N)$。**语义等价、数量级差异**，这正是把排名"做进语言里"的意义。

---

### 5.2 分区排名与 Top-N

**分区（partition）= 把数据切成小格子，每个格子内部独立排名**（课件 P50）：

```sql
-- "求每系学生的系内名次"
select ID, dept_name,
       rank() over (partition by dept_name order by GPA desc) as dept_rank
from dept_grades
order by dept_name, dept_rank;
```

要点（课件原文）：

- **同一 `select` 里可以出现多个排名函数**（如同时要全院名次与系内名次——两个 `over(...)` 并列）；
- **排名在 `group by` / 聚合之后才做**（Ranking is done after applying group by clause/aggregation）——对应逻辑执行顺序：`FROM → WHERE → GROUP BY → HAVING → 窗口函数 → SELECT → ORDER BY`（衔接 [[Ch3 Intro to Sql#3 基本查询结构（SELECT-FROM-WHERE）|Ch3 逻辑执行顺序]]）；
- **Top-N 比 `limit n` 更强**：`limit n` 全表截断，排名可以做**每个分组各自的 top-n**（课件原话：more general than the limit n clause, since it allows top-n within each partition）。

> [!warning] 易错点：Top-N 不能直接写在 WHERE 里
> 窗口函数在 `WHERE` **之后**才计算——`where rank() over (...) <= 3` 会直接报错。必须**包一层**（子查询或 CTE）在外层过滤：

```sql
with ranked as (
    select ID, dept_name, GPA,
           rank() over (partition by dept_name order by GPA desc) as r
    from dept_grades)
select * from ranked where r <= 3;      -- ✅ 外层才能筛名次
```

---

### 5.3 窗口框架（Window Frame）

**通俗理解**：排名是"我在第几"，窗口是"**我周围那一段**"——算移动平均、算累计余额，都是"对一小段邻居求聚合"。

**动机**（课件 P53）：**平滑随机波动**（Used to smooth out random variations）。经典例子——三日移动平均："给定每天的销售额，求每天及其前后一天的平均值"：

```sql
-- 标准语序（课件 P53 原文写作 over (order by date between rows 1 preceding …)，
-- 标准语法应为 rows between … and …，以标准/实现文档为准）
select date, sum(value) over (
    order by date
    rows between 1 preceding and 1 following)
from sales;
```

**框架的两个维度**（课件 P53–P54 的规格清单）：

| 规格 | 含义 | 课件例子 |
|---|---|---|
| `rows between 1 preceding and 1 following` | 按**行位置**取：前 1 行 ~ 后 1 行 | 三日移动平均 |
| `rows between unbounded preceding and current row` | 从**第一行到当前行** | 累计（到此为止） |
| `rows unbounded preceding` | 同上的简写 | 累计 |
| `range between 10 preceding and current row` | 按**排序键的值**取：值 ∈ [当前值−10, 当前值] | 按值区间聚类 |
| `range interval 10 day preceding` | 按**时间值**回溯 10 天 | 课件注明 **不含当前行**（按课件记忆；区间开闭各实现可能有差异） |

**`ROWS` vs `RANGE`**（本节最核心的辨析）：

- **`ROWS`**：按**物理行位置**——"上一行"就是上一行，哪怕值差十万八千里；
- **`RANGE`**：按**排序键的值**——把**键值相同**的所有行当作一个整体一起进/出窗口（值相差在指定区间内的行都在框架内）。

**分区内的窗口**（课件 P55，账户余额经典题）：

```sql
-- 每笔交易之后，每个账户的余额
select account_number, date_time,
       sum(value) over (
           partition by account_number      -- 分区：各账户独立累计
           order by date_time               -- 排序：按时间先后
           rows unbounded preceding)        -- 框架：从头累计到当前笔
           as balance
from transaction
order by account_number, date_time;
```

（`value` 为正 = 存入，为负 = 取款；余额即分区内前缀和）

$$\text{balance}_k \;=\; \sum_{i=1}^{k} value_i \qquad (\text{各账户分区内按 } date\_time \text{ 排序})$$

> [!warning] 易错点 1：框架会在边界**自动收缩**
> `rows between 1 preceding and 1 following` 在**首行**只有"自己 + 后一行"共 2 行，在**末行**只有 2 行——移动平均必须**除以实际行数**而不是恒除以 3。窗口不会凭空补行。

> [!warning] 易错点 2：`over` 里的 `order by` ≠ 结果的 `order by`
> 没有 `rows/range` 显式框架时，框架默认**随 order by 而变**（有 order by 时常为"从头到当前"的累计框架）——这就是"为什么有时 sum over 变成了累计和"。要精确控制，**永远显式写出 `rows between ... and ...`**。

---

### 5.4 OLAP 基础：多维数据、交叉报表与数据立方

**通俗理解**：老板问的从来不是一行行流水，而是"**换个角度看**"——按商品？按颜色？按尺码？按三个一起？OLAP 就是"**在线、随你翻面**"地看同一堆数。

**严谨定义**（课件 P57）：

- **OLAP（Online Analytical Processing）**：对数据的**交互式分析**，能以在线方式（**可忽略的延迟**）把数据**汇总并从不同视角查看**；
- **多维数据（multidimensional data）**：可建模为**度量属性 + 维度属性**的数据：

| 概念 | 定义（课件原文） | 例子（sales 关系） |
|---|---|---|
| **度量属性（measure）** | **度量某个值**、**可以被聚合**的属性 | `quantity`（销量） |
| **维度属性（dimension）** | 定义度量（或其聚合）**被观察的视角** | `item_name`、`color`、`clothes_size` |

> [!warning] 课件笔误：`number` 与 `quantity` 混用
> P57 举例说度量是 "the attribute **number** of the sales relation"，P63 又把关系写成 `sales(item_name, color, clothes_size, **quantity)**` 而查询用 `sum(number)`——**两处字段名不一致**。本笔记统一用 `quantity`，做题以题干为准。

**本节贯穿数据**（课件 P58 的 `sales` 关系示例——下面的交叉报表与数据立方都建立在它之上）：

![[Ch5-img-p58-213.png]]

**交叉报表 cross-tab（pivot table）**（课件 P59 四要点）：

1. 一个维度的值 → **行表头**；
2. 另一个维度的值 → **列表头**；
3. 其余维度 → 列在**表头上方**（切片条件）；
4. 单元格 = 对应维度组合的 **(聚合) 值**。

![[Ch5-img-p59-229.png]]

**数据立方 data cube**（课件 P60）：交叉报表的**多维推广**——可有 $n$ 个维度（课件画了 3 维）；**交叉报表就是数据立方上的一个"视图"**（Cross-tabs can be used as views on a data cube）。

![[Ch5-img-p60-235.png]]

**层次与上下钻**（课件 P61）：维度可带**层次**（如 品类 → 商品），交叉报表可以沿层次 **drill down（下钻，粗→细）** 或 **roll up（上卷，细→粗）**。

![[Ch5-img-p61-240.jpeg]]

**关系表示**（课件 P62）：交叉报表可以**存成普通关系**——用特殊值 **`all`** 表示"该维度被聚合掉"的总计行；**SQL 标准实际用 NULL 代替 `all`**（尽管会与真正的 NULL 混淆——课件原话 despite confusion with regular null values）。

![[Ch5-img-p62-249.jpeg]]

> [!important] 这个"标准用 NULL 表示 all"是 5.5 的全部伏笔
> 一旦用 NULL 既表示"小计"又可能表示"真没值"，**读表的人无法区分**——解药就是下一节的 `grouping()` 函数。

---

### 5.5 CUBE 与 GROUPING 函数

**通俗理解**：`cube(A, B, C)` = "**A、B、C 这三列，各种组合方式的合计我全给你算一遍**"——3 列有 $2^3 = 8$ 种组合（三维全、任二维、任一维、总合计），一条 SQL 出齐。

**严谨定义**（课件 P63）：`cube` 操作计算**指定属性的每一个子集上的 group by 的并集**（union of group by's on **every subset** of the specified attributes）：

```sql
select item_name, color, size, sum(quantity)
from sales
group by cube(item_name, color, size);
```

一次产生 **8 个分组**（列全，`()` 表示空 group by 列表 = 总计）：

$$\{\,(a,b,c),\ (a,b),\ (a,c),\ (b,c),\ (a),\ (b),\ (c),\ (\,)\,\} \qquad 2^n \text{ 个子集}$$

- **每个分组里、不在该分组的属性列取 NULL**（For each grouping, the result contains the null value for attributes not present in the grouping）——这些 NULL 就是**小计/总计标记**（对应 [[#5.4 OLAP 基础：多维数据、交叉报表与数据立方|5.4]] 的 `all`）；
- 两维版本 `group by cube(item_name, color)` 算出的就是**关系型交叉报表**（P64）。

**`grouping()`：区分"标记 NULL"与"真 NULL"**（课件 P64）：

```sql
select item_name, color, size, sum(quantity),
       grouping(item_name) as item_name_flag,   -- 1 = 该列此处是"聚合标记 NULL"
       grouping(color)     as color_flag,       -- 0 = 该列是正常维度值
       grouping(size)      as size_flag
from sales
group by cube(item_name, color, size);
```

- `grouping(A)`：**A 的当前值若是"代表 all 的 NULL" → 返回 1，其他情况 → 0**（课件原文）。

**`decode()`：把标记 NULL 显示回 `'all'`**（课件 P65）：

```sql
decode(grouping(item_name), 1, 'all', item_name)
-- grouping 为 1 → 显示 'all'；否则显示 item_name 本身
```

> [!warning] 易错点：cube 结果里的 NULL 有两种身份
> ① **聚合标记**（该维度被汇总掉）；② **真正的 NULL**（数据本身就是 NULL）。**肉眼无法区分，必须用 `grouping()` 判别**——这是本节最高频的考点。记忆：**`grouping()` 是 NULL 的"验明正身器"**。

---

### 5.6 ROLLUP 与分组集组合

**通俗理解**：`cube` 把**所有**组合都算（"全都要"），`rollup` 只沿**一条层级线**往上卷（"按顺序逐级汇总"）——品类→商品→合计，不会凭空出现"只按颜色合计"这种跳跃组合。

**严谨定义**（课件 P66）：`rollup` 计算指定列表的**每一个前缀（prefix）** 上的 group by 的并集：

```sql
select item_name, color, size, sum(quantity)
from sales
group by rollup(item_name, color, size);
-- 只产生 4 个分组（前缀链）：
-- { (item_name, color, size), (item_name, color), (item_name), () }
```

**`cube` vs `rollup` 对照**（$n=3$ 时 8 vs 4，务必记牢）：

| | 分组集合 | 数量 | 适用 |
|---|---|---|---|
| `cube(a,b,c)` | **全部子集** | $2^n = 8$ | 任意维度组合都要 |
| `rollup(a,b,c)` | **全部前缀** | $n+1 = 4$ | 沿层级逐级汇总 |

**层级应用**（课件 P66 例）：`itemcategory(item_name, category)` 给出商品的品类——

```sql
select category, item_name, sum(quantity)
from sales, itemcategory
where sales.item_name = itemcategory.item_name
group by rollup(category, item_name);
-- 分组：(category, item_name) 明细 → (category) 品类小计 → () 总计
```

**多 rollup / 多 cube 组合**（课件 P67）：同一 `group by` 里可以写多个——**分组集合取笛卡尔积**：

```sql
select item_name, color, size, sum(quantity)
from sales
group by rollup(item_name), rollup(color, size);
-- {item_name, ()} × {(color,size), (color), ()} = 6 个分组：
-- (item_name,color,size) (item_name,color) (item_name)
-- (color,size) (color) ()
```

数量规律（数学块）：

$$|\text{rollup}(a_1,\dots,a_k)| = k+1, \qquad \Big|\prod_i \text{rollup}(\cdot)_i\Big| = \prod_i (k_i + 1)$$

---

### 5.7 OLAP 操作词汇与实现

**操作词汇**（课件 P68，四对概念，定义题高频）：

| 操作 | 定义（课件原文） | 方向 |
|---|---|---|
| **Pivoting** | 改变交叉报表所使用的维度（changing the dimensions used in a cross-tab） | 换视角 |
| **Slicing** | 只取**固定维度值**生成一张交叉报表 | 切一片 |
| **Dicing** | （slicing 的别名，尤其当**多个维度**同时固定值时） | 切一块 |
| **Rollup** | 从**细粒度**数据走向**粗粒度**汇总 | 细 → 粗 |
| **Drill down** | rollup 的**逆操作**：粗 → 细 | 粗 → 细 |

> [!tip] 词汇同源
> OLAP 口语里的 **rollup（上卷）** 与 SQL 的 **`group by rollup()`** 是同一思想：把细粒度汇总"卷"到粗粒度——**SQL 构造就是操作的实现**（对照 [[#5.6 ROLLUP 与分组集组合|5.6]]）。

**实现三类型**（课件 P69）：

| 类型 | 全称 | 存储方式 |
|---|---|---|
| **MOLAP** | Multidimensional OLAP | **内存多维数组**存数据立方（最早期做法） |
| **ROLAP** | Relational OLAP | **只用关系数据库特性**实现 |
| **HOLAP** | Hybrid OLAP | **混合**：部分汇总放内存，基表与其余汇总放关系库 |

**物化聚合与按需推导**（课件 P70，思想题高频）：

- 早期 OLAP **预计算全部聚合** → 空间/时间开销巨大：$n$ 维有 **$2^n$** 个 group by 组合；
- 现代做法：**只预计算一部分**，其余**从已算好的聚合推导**——
  - `(item_name, color)` 的聚合可以从更细的 `(item_name, color, size)` 聚合推出（把 size 维度再聚合掉即可），**比从头算便宜**；
  - **例外**：`median` 等少数**不可分解聚合（non-decomposable aggregates）** 推不出来（课件原文：for all but a few "non-decomposable" aggregates such as **median**）；
- 进一步优化：`(item_name, color, size)`、`(item_name, color)`、`(item_name)` 三个聚合可以用**对基数据的一次排序**同时算出（single sorting of the base data）。

**可分解性直觉**：能"由细算粗无损合并"的聚合就是可分解的——`sum`（再相加）、`count`（再相加）、`min/max`（取极值）都行；`avg` 需连同 `(sum, count)` 一起保存再换算；**median 的中间值无法从分组的 median 合并出来**——这就是它被点名的原因。

---

## 6 本章重难点与易错点汇总

| # | 易错点 | 一句话记忆 |
|---|---|---|
| 1 | JDBC 结果列下标**从 1 开始**（不是 0） | `getString(1)` 是第一列，0 直接越界 |
| 2 | `getXXX` 遇 NULL 返回零值 → **0 两义**，必须紧跟 `wasNull()` | wasNull 只认"刚刚那次读" |
| 3 | 用户输入**拼字符串**造 SQL = 注入；`D'Souza` 都能把语句戳断 | 模板与数据分离，`?` 只放值 |
| 4 | 课件 `getTables` 的 `"TABLES"` 是笔误，标准值 `"TABLE"` | 照抄课件 → 一张表都查不到 |
| 5 | JDBC **默认每条语句自动提交** | 多步业务先 `setAutoCommit(false)` |
| 6 | 嵌入式游标：**open 时刻**读宿主变量；`SQLSTATE='02000'` 结束；`close` 删临时关系 | declare 只声明，open 才执行 |
| 7 | `where current of c` 要配合 `declare ... for update` | 想改必须先声明可更新 |
| 8 | 函数形参与列**同名** → 歧义；参数用 `p_` 前缀或 `函数名.参数名` 限定 | 同名是读代码的雷 |
| 9 | 函数在 `where` 里**每行执行一次** | 能集合一次算的别逐行调 |
| 10 | 表函数要 `table(…)` 包装放 `from`；标量函数放表达式 | 返回表进 from，返回值进表达式 |
| 11 | 触发器语法 **SQL:1999 才标准化**，课件语法 ≠ 你的 DBMS | 动手前查系统手册 |
| 12 | credits_earned 只处理"F/未评分 → 有效"：**只加不减、B→F→B 重复加** | 教材例子不能照抄进生产 |
| 13 | 大批量更新用**语句级触发器 + 过渡表**（old/new table）更高效 | 逐行触发是 N 次，语句级是 1 次 |
| 14 | 备份恢复/复制会**误触发** → 操作前禁用触发器；还有级联触发风险 | 触发器的扳机藏在数据里 |
| 15 | 递归查询必须 **`union` 去重**才收敛，`union all` 会无限膨胀 | 收敛靠去重 |
| 16 | 固定 k 次自连接只能看 k 层；递归的层数**由数据决定** | 写死的 k 打不过任意深的链 |
| 17 | 递归视图语义 = **不动点**，不是视图展开（展开对递归不终止） | 展开管非递归，不动点管递归 |
| 18 | `rank` 并列**留空洞**（1,1,3），`dense_rank` 不留，`row_number` **不确定** | 空洞看 rank，连续看 dense，行号别当名次 |
| 19 | 窗口的 `order by` **不排序结果**；要输出有序得再写外层 `order by` | 一个负责排名，一个负责呈现 |
| 20 | **Top-N 不能写进 `where`**（窗口在 where 之后才算） | 包一层 CTE/子查询再筛 |
| 21 | 窗口框架在边界**自动收缩**（首行只含 1 行邻居） | 移动平均要除以实际行数 |
| 22 | `ROWS` 按**位置**、`RANGE` 按**键值**；框架不写清会随 order by 变累计 | 要精确就显式 `rows between` |
| 23 | `cube` = 全子集 $2^n$，`rollup` = **前缀** $n+1$；多 rollup 组合是**笛卡尔积** | cube 全都要，rollup 顺着卷 |
| 24 | cube 结果的 NULL **两义**（聚合标记 vs 真 NULL）→ `grouping()` 验明正身，`decode` 显示 'all' | NULL 的验身器是 grouping |
| 25 | `2^n` 预算太贵 → 部分物化 + 可分解聚合推导；median **不可分解** | 细的能推粗的，median 不能 |
| 26 | 课件三处笔误：`rec_rereq`、`between rows` 语序、`number/quantity` 混用 | 代码以标准与手册为准 |

---

## 7 综合例题（难度偏高）

> 沿用通用模式：`instructor(ID, name, dept_name, salary)`、`student(ID, name, dept_name, tot_cred)`、`takes(ID, course_id, ..., grade)`、`course(course_id, title, dept_name, credits)`、`prereq(course_id, prereq_id)` 等。

**例题 1（SQL 注入完整推演）** 某查询用拼接构造：`"select * from instructor where name = '" + name + "'"`。分别代入以下输入，写出**实际执行的 SQL**、指出后果，并回答 prepared statement 为何免疫：

(a) `X' or 'Y' = 'Y`　(b) `X'; update instructor set salary = salary + 10000; --`　(c) `D'Souza`

<details><summary>参考解答</summary>

**(a)**

```sql
select * from instructor where name = 'X' or 'Y' = 'Y'
```

`'Y' = 'Y'` 恒真 → `where` 整体为真 → **返回整张 instructor 表**（越权读全量数据）。这就是"鉴权绕过型"注入。

**(b)**

```sql
select * from instructor where name = 'X'; update instructor set salary = salary + 10000; --
```

原本的字符串在 `X'` 处**闭合**，`；` 让语句提前结束 → **追加了一条恶意 UPDATE**（全员加薪 1 万），`--` 把残余的 `';'` 注释掉保持语法完整。能否执行取决于驱动与 DBMS 是否允许多语句批量执行——**但只需 (a) 这种只读注入就足以泄露全部数据**。

**(c)** 无恶意但同样出事：字符串在 `D'` 处被截断 → 后半句变成乱码/语法错误 → **正常用户的名字含单引号就报错**（这正是课件问 "What if name is D'Souza?" 的用意：拼接连**守法输入**都接待不好）。

**prepared statement 免疫的原因**：SQL **结构**由模板（含 `?`）唯一决定，运行时不可改写；输入只作为**数据**发送，单引号等字符被内部转义（课件：`name = 'X\' or \'Y\' = \'Y'`）——(a) 会变成"寻找名叫 `X' or 'Y' = 'Y` 的人"（找不到，返回空），(b) 的 `;` 也只是一个普通字符。**结构 ≠ 数据，注入无从下手**。

</details>

**例题 2（ResultSet 细节判断）** 下列代码有什么问题？如何修复？

```java
ResultSet rs = stmt.executeQuery(
    "select ID, avg(salary) from instructor group by dept_name");   // 列2可能为 NULL
while (rs.next()) {
    System.out.println(rs.getString(1) + " " + rs.getFloat(2));
    int x = rs.getInt(1);          // ①
    if (rs.wasNull()) …            // ②
    System.out.println(rs.getFloat(0));   // ③
}
```

<details><summary>参考解答</summary>

- **③ 是致命错误**：列号 **1 基**，`getFloat(0)` 直接抛 `SQLException`（JDBC 列下标没有 0）——Java 数组习惯的典型翻车；
- **② 时序错误**：`wasNull()` 判定的是**最近一次 getXXX**，此时刚读过的是 ① 的 `getInt(1)`（ID），与②想判的"avg 是否为 NULL"无关——`wasNull` 必须**紧贴**在读取目标列之后；
- **隐藏的业务错误**：`avg(salary)` 为空分组（或全 NULL 工资）时返回 SQL NULL，`getFloat(2)` 返回 **0.0f**，报表会显示"平均工资 0"——与"平均工资恰好为 0"混淆。

**正确写法**：

```java
while (rs.next()) {
    String id  = rs.getString(1);        // 下标 1 起步
    float  avg = rs.getFloat(2);         // 紧接着就问
    String out = rs.wasNull() ? "N/A" : String.valueOf(avg);
    System.out.println(id + " " + out);
}
```

</details>

**例题 3（JDBC 事务编程）** 某同学写出的转账代码如下，找出全部问题并给出正确版本：

```java
stmt.executeUpdate("update account set balance = balance - 1000 where acc_no = 'A'");
stmt.executeUpdate("update account set balance = balance + 1000 where acc_no = 'B'");
```

<details><summary>参考解答</summary>

**问题**：JDBC **默认 autocommit 开启**——两条 `update` 是**两个独立事务**，第一条提交后若第二条失败/进程崩溃，**A 少了 1000 而 B 没多**，原子性（[[Ch4 Intermediate SQL#3 事务（Transactions）|Ch4 §3]]）荡然无存；此外异常路径没有任何回滚处理。

**正确版本**：

```java
conn.setAutoCommit(false);                       // ① 关自动提交：后续语句同属一个事务
try {
    stmt.executeUpdate("update account set balance = balance - 1000 where acc_no = 'A'");
    stmt.executeUpdate("update account set balance = balance + 1000 where acc_no = 'B'");
    conn.commit();                               // ② 两步一起永久化
} catch (SQLException e) {
    conn.rollback();                             // ③ 异常必须回滚，否则事务悬置
} finally {
    conn.setAutoCommit(true);                    // ④ 恢复连接默认状态（连接会被复用）
}
```

**要点**：`setAutoCommit(false)` 之后，`commit`/`rollback` 成为**必须显式执行**的边界；rollback 是**事务级**（两条一起撤），不是只撤最后一条。

</details>

**例题 4（游标四部曲：排序与时刻语义）** 把下列嵌入式 SQL 步骤排成合法顺序，并回答问题：

```sql
(a) EXEC SQL fetch c into :si, :sn END_EXEC
(b) EXEC SQL close c;
(c) declare c cursor for select ID, name from student where tot_cred > :credit_amount
(d) EXEC SQL open c;
```

问：① open 之后把宿主变量 `credit_amount` 改成 999，继续 fetch 的结果会变吗？② 循环何时终止？③ `close` 删掉了什么？④ 若想边遍历边给 `instructor` 加薪，声明要加什么、更新怎么写？

<details><summary>参考解答</summary>

**顺序：(c) declare → (d) open → (a) fetch×N → (b) close**。

- **① 不会变**：查询在 **open 执行的那一刻**才真正运行，`credit_amount` 的值在**那时**被读入、结果固化进临时关系——open 之后改宿主变量对已打开的游标**没有任何影响**（课件原文点名此语义）。想用新值？**先 close 再重新 open**（或重新声明执行）。
- **② `SQLSTATE = '02000'`**（no more data）——SQL 通信区（SQLCA）里的这个变量变绿灯时停止 fetch。
- **③ 结果的临时关系**——open 时物化的那份数据被删除（不是"删表"，更不是"删游标变量"）。
- **④** 声明时加 **`for update`**；更新用 **`where current of c`**：

```sql
declare c cursor for select * from instructor where dept_name = 'Music' for update;
-- 每 fetch 一行后：
update instructor set salary = salary + 1000 where current of c;
```

</details>

**例题 5（函数与表函数细节）** (a) 2.2 的 `dept_count` 有哪些隐患？给出严谨改写。(b) `instructor_of` 函数体里 `instructor.dept_name = instructor_of.dept_name` 中 `instructor_of.dept_name` 指什么？为什么必须这么写？(c) 调用位置：`where dept_count(dept_name) > 12` 与 `from table(instructor_of('Music'))` 分别属于哪类函数的用法？

<details><summary>参考解答</summary>

**(a) 隐患与改写**：

- 隐患 1：**形参与列同名**（`dept_name`）——右操作数到底解析为参数还是列，依赖实现，可能报歧义 → 参数改名 `p_dept_name`；
- 隐患 2：**在 where 中逐行调用**，每行跑一次聚合子查询 → 集合方式更好（等价的高效写法 `group by + having`，见 [[Ch3 Intro to Sql#聚合函数|Ch3]]）；

```sql
create function dept_count (p_dept_name varchar(20))
returns integer
begin
    declare d_count integer;
    select count(*) into d_count
        from instructor
        where instructor.dept_name = p_dept_name;   -- 形参带前缀，零歧义
    return d_count;
end
```

（补充点：`count(*)` 聚合**必出一行**，系不存在时得到 0，不会"取不到值"出错——这比裸 `select ... into` 单行查询安全。）

**(b)** `instructor_of.dept_name` 是**用"函数名.参数名"限定引用函数的形参**——函数体内列 `dept_name` 与参数 `dept_name` 同名，不加限定则整句 `instructor.dept_name = dept_name` 无法区分左右各指什么（课件此处正是 2.2 歧义问题的标准解法）。

**(c)**

- `where dept_count(…) > 12`：返回**单个整数**参与比较 → **标量函数**；
- `from table(instructor_of('Music'))`：返回**一整张表**，`table()` 包装后作为关系出现在 `from` → **表函数**。判别口诀：**比较表达式里的是标量，from 里的是表函数**。

</details>

**例题 6（行级触发器推演 + 缺陷分析）** `credits_earned` 触发器（3.2）已建。学生 S9 的 `takes.grade` 依次发生下列变化，每次触发器是否动作？`tot_cred` 净变化多少（设该课 `credits = 4`，S9 初始 `tot_cred = 0`，初始成绩为 F）？

| 次序 | 变化 | 判定 |
|---|---|---|
| 1 | F → B | ？ |
| 2 | B → C | ？ |
| 3 | C → F | ？ |
| 4 | F → A | ？ |
| 5 | A → F | ？ |
| 6 | F → B（重修再及格） | ？ |

最后回答：该触发器设计上有什么系统性缺陷？

<details><summary>参考解答</summary>

`when` = **新成绩非 F 且非 NULL，且旧成绩为 F 或 NULL**——只有"F/未评分 → 有效及格"才动作：

| 次序 | 变化 | 触发？ | tot_cred |
|---|---|---|---|
| 1 | F → B | ✅ 动作 | 0 → **4** |
| 2 | B → C | ❌ 旧不是 F/NULL，新也非"由败转胜" | 4 |
| 3 | C → F | ❌ 新是 F | 4 |
| 4 | F → A | ✅ 动作 | 4 → **8** |
| 5 | A → F | ❌（且语义上"变挂科了"却没扣分） | 8 |
| 6 | F → B | ✅ 动作 | 8 → **12** |

**系统性缺陷**：

1. **只加不减**——第 3、5 步成绩转为 F 却不扣学分，`tot_cred` 只升不降；
2. **重复累计**——第 6 步（重修及格）再次满足 when，同一门课的学分**加了两次**（12 ≠ 应有的 4+8 中按"每门课只算一次"的语义……按本例应为 8：B 的 4 + A 的 4，第 6 步是同一 `course_id` 再加 4 → 虚增）；
3. 根因：条件把"状态转换"建模成**单向增量**，而不是"按新旧状态的**差值**"更新——严谨写法应为 `Δ = (新有效 ? c : 0) − (旧有效 ? c : 0)`，或定期全量对账（[[Ch4 Intermediate SQL#4.7 断言（ASSERTION）|Ch4 断言]]）。

**结论**：课件例子演示语法完全合格，但**直接上生产会算错账**——考"读代码找 bug"时要能一眼看出这两个坑。

</details>

**例题 7（触发器选型与风险判断）** 判断下列场景该用行级、语句级还是不该用触发器，并说明理由：

(a) 每次单个成绩变动更新对应学生的 `tot_cred`；
(b) 一次 `update` 批量改 5 万行，需要记录"本次共改了多少行、总金额变化多少"；
(c) 从备份文件恢复 100 万行历史数据；
(d) 维护"每系工资总额"汇总列。

<details><summary>参考解答</summary>

| 场景 | 选择 | 理由 |
|---|---|---|
| (a) | **行级触发器** | 需要逐行判断（`when` 涉及该行新旧值），每行各自更新 |
| (b) | **语句级触发器 + 过渡表** | 一次语句触发一次，用 `referencing new table` 拿整批数据汇总——5 万次触发 vs 1 次，效率天壤之别（课件：处理大量行的语句时更高效） |
| (c) | **不该用（先禁用触发器）** | 恢复备份的本意是"搬运"，却会把所有触发器点着——意外触发 + 拖慢恢复 + 可能引发级联（课件原文对策：trigger execution can be disabled before such actions） |
| (d) | **优先不用** | 课件明确：如今用**物化视图**内置维护汇总更合适；触发器维护汇总是"老办法"（还有封装方法等替代）——触发器只在上述设施缺失时兜底 |

</details>

**例题 8（递归查询执行推演）** 设 `prereq` 为：`(A,B), (B,C), (C,D)`。写出 `rec_prereq` 递归查询**每一轮**的中间结果，直至稳定；并回答：① 最终结果几行？② 若把 `union` 改成 `union all` 会发生什么？③ 若加入 `(D,A)`（成环）结果如何、会死循环吗？④ 该查询与 Ch4"视图展开"的关系？

<details><summary>参考解答</summary>

**迭代过程**（seed = 直接先修；每轮：`已有结果 ⋈ prereq`（按 `rec.prereq_id = prereq.course_id` 连接）并入，去重）：

| 轮次 | 本轮新产出 | 累计结果 |
|---|---|---|
| seed | — | (A,B) (B,C) (C,D) |
| 第 1 轮 | (A,C)（A→B→C）、(B,D)（B→C→D） | + (A,C) (B,D) |
| 第 2 轮 | (A,D)（A→B→C→D，用 (A,C) 接 (C,D)） | + (A,D) |
| 第 3 轮 | 无新元组 → **不动点，停止** | 共 **6 行** |

**①** 6 行：{(A,B),(B,C),(C,D),(A,C),(B,D),(A,D)}，即 $R^+ = \bigcup_{i=1}^{3} R^i$。

**②** `union all` **不去重**：每轮产出的元组与已有结果重复也算"新行"，下一轮又拿它们去连接、再产出重复……**结果集无限膨胀，查询永不终止**——递归收敛的命门就是 `union` 的去重。

**③** 加 `(D,A)` 后成环：迭代仍会终止！因为去重保证"可产出的元组是有限集"（4 个元素上的有序对至多 $4 \times 4 = 16$ 个），最终达到**全连通**的不动点（含 (A,A),(B,B) 等自环对——A 经 A→B→C→D→A 回到自己）后不再增长。**环不会死循环，只会让闭包变大**。

**④** Ch4 讲**视图展开**（代入替换）时指出：递归视图会让展开陷入 `v → v → …` 而不终止；本节给出递归视图的**真正语义 = 不动点迭代**——展开管非递归，不动点管递归，两者合起来才是完整的视图语义（两条笔记此处互相引用）。

</details>

**例题 9（表达力论证）** 有人说："我写一个查询，把 `prereq` 自连接 10 次，就能查出 10 层以内的全部先修关系，实际数据里先修链很少超过 5 层，所以不需要递归。" 请评价。

<details><summary>参考解答</summary>

**技术上他说的对，工程上他错在三点**：

1. **能力边界**：k 次自连接只能展开到 $R^{(k)}$（k 层）——课件的反证法：**给定任意非递归查询，总能构造一条深度 > k 的先修链让它失效**。"实际没超过 5 层"是**对数据的假设**，不是查询的保证——数据一旦长深（新增课程依赖、组织架构调整），查询**静默漏结果**（不报错，只少行——比报错更危险）；
2. **成本**：10 次自连接的中间结果是 $O(|R|^{10})$ 量级的爆炸（优化器会消解一部分，但深度代价仍远高于递归的"到稳定即停"）；
3. **可维护性**：深度上限**写死在查询文本里**——改需求 = 改查询；递归的终止条件是**数据自己说了算**（不动点），查询文本无需随数据深度调整。

**结论**：固定连接适用于"深度确实有界且很小、且有 schema 级保证"的场景；一般化的传递闭包应交给**递归查询**（或教材的过程迭代方案）——"层数由数据决定，不由查询决定"才是正确抽象。

</details>

**例题 10（排名族手算）** `student_grades` 的 GPA 为：3.9, 3.9, 3.7, 3.5, 3.5, 3.5, 3.2（N=7）。分别写出 `rank()`、`dense_rank()`、`row_number()`、`percent_rank()`、`cume_dist()`（按 GPA 降序）的结果，并给出 `ntile(4)` 的分桶；最后回答 Top-N 的正确写法。

<details><summary>参考解答</summary>

| 行 | GPA | rank | dense_rank | row_number（示例一种） | percent_rank $=(r-1)/(N-1)$ | cume_dist（≤该值行数/N） |
|---|---|---|---|---|---|---|
| 1 | 3.9 | **1** | 1 | 1 | 0/6 = **0** | 2/7 ≈ 0.286 |
| 2 | 3.9 | **1** | 1 | 2 | **0** | 2/7 ≈ 0.286 |
| 3 | 3.7 | **3** | 2 | 3 | 2/6 ≈ 0.333 | 3/7 ≈ 0.429 |
| 4 | 3.5 | **4** | 3 | 4 | 3/6 = 0.5 | 6/7 ≈ 0.857 |
| 5 | 3.5 | **4** | 3 | 5 | 0.5 | 6/7 |
| 6 | 3.5 | **4** | 3 | 6 | 0.5 | 6/7 |
| 7 | 3.2 | **7** | 4 | 7 | 6/6 = 1 | 7/7 = 1 |

- **rank 留空洞**：1,1,**3**,4,4,4,**7**；**dense_rank 连续**：1,1,2,3,3,3,4；
- **row_number 并列不确定**：本表给出的 (1…7) 只是可能之一，3.9 的两行谁拿 1、谁拿 2 实现说了算——**不要用它表达名次**；
- **ntile(4)**：$N=7$ 分 4 桶 → 桶大小先按 $\lceil 7/4 \rceil = 2$ 分配 → 前面桶各 2 行、末桶 1 行：**2,2,2,1**，即第 1–2 行第 1 桶、3–4 行第 2 桶、5–6 行第 3 桶、第 7 行第 4 桶；
- **Top-N 写法**：窗口函数不能出现在 `where`（它在 WHERE 之后才算）→ CTE/子查询包一层再筛（见 5.2 警示框）。

</details>

**例题 11（窗口框架手算）** `sales(date, value)` 五天数据：`(d1,10), (d2,20), (d3,30), (d4,40), (d5,50)`。分别计算：(a) `rows between 1 preceding and 1 following` 的 `sum`；(b) `rows unbounded preceding`（累计）的 `sum`；(c) 解释 (a) 中 d1 与 d5 的值为何不是"三天平均"的除数 3；(d) 两账户交易表按 55 的写法求逐笔余额（含取款），说明分区与框架各起什么作用。

<details><summary>参考解答</summary>

**(a) 三日滑窗（边界自动收缩）**：

| 行 | 框架内行 | sum | （若是 avg 则除以**实际行数**） |
|---|---|---|---|
| d1 | d1,d2（**只有 2 行**，没有"前一行"） | 30 | 30/2 = 15 |
| d2 | d1,d2,d3 | 60 | 20 |
| d3 | d2,d3,d4 | 90 | 30 |
| d4 | d3,d4,d5 | 120 | 40 |
| d5 | d4,d5（**只有 2 行**） | 90 | 90/2 = 45 |

**(b) 累计**：10, 30, 60, 100, 150（$\text{balance}_k = \sum_{i \le k} value_i$）。

**(c)** 框架**越界即收缩**——窗口只包含**实际存在**的行，d1 的"前一行"不存在，框架里就只有 2 行。**任何基于窗口的平均都必须除以实际参与行数**（或用 `avg()` 直接算，它自己会处理），写死 `/3` 是常见 bug。

**(d)** `sum(value) over (partition by account_number order by date_time rows unbounded preceding)`：

- **`partition by account_number`**：各账户**互不干扰**地累计（A 的余额不会混进 B 的交易）；
- **`order by date_time`**：分区内**按时间排**，保证"累计到第 k 笔"的次序正确；
- **`rows unbounded preceding`**：框架 = 从分区第一行到当前行 → 逐笔前缀和；取款使 `value` 为负，前缀和即**实时余额**（例：A 账户 +500, −200, +100 → 余额 500, 300, 400）。

**三件套缺一不可**：没有 partition 会"全表混算"，没有 order 累计次序无意义，没有框架（默认框架随 order by 变）语义随实现漂移。

</details>

**例题 12（CUBE / ROLLUP / GROUPING 手算）** `sales(item_name, color, size, quantity)` 有 4 行：

| item_name | color | size | quantity |
|---|---|---|---|
| hat | red | S | 10 |
| hat | red | L | 20 |
| hat | blue | S | 30 |
| cap | red | S | 40 |

(a) `group by cube(item_name, color)` 产生哪些分组？写出结果行（含 NULL 标记）；(b) 用 `grouping()` 标出哪些 NULL 是聚合标记；(c) `rollup(item_name, color, size)` 与 `cube(item_name, color, size)` 各几组？(d) `group by rollup(item_name), rollup(color)` 又是几组、列全？

<details><summary>参考解答</summary>

**(a)** $2^2 = 4$ 个分组（(item,color)、(item)、(color)、()）：

| item_name | color | sum(quantity) | 来自分组 |
|---|---|---|---|
| hat | red | 30 | (item,color) |
| hat | blue | 30 | (item,color) |
| cap | red | 40 | (item,color) |
| hat | NULL | 60 | (item) 小计 |
| cap | NULL | 40 | (item) 小计 |
| NULL | red | 70 | (color) 小计 |
| NULL | blue | 30 | (color) 小计 |
| NULL | NULL | **100** | () 总计 |

**(b)** 后 4 行的 NULL 都是**聚合标记**（该维度被汇总掉），不是数据缺失——`grouping(item_name)` 在这 4 行返回 **1**，前 4 行返回 **0**；`grouping(color)` 同理。若要显示成 `'all'`：`decode(grouping(item_name), 1, 'all', item_name)`。**注意**：本例数据本身无真 NULL；若数据里真有 NULL（如某商品没填颜色），它所在的行 `grouping(color)` 返回 **0**——这就是"两义靠 grouping 验明正身"的完整闭环。

**(c)**

- `rollup(item_name, color, size)`：前缀链 = (a,b,c), (a,b), (a), () → **4 组**（注意**没有** (b,c)、(c) 这类非前缀组）；
- `cube(item_name, color, size)`：全部子集 → **8 组**。
- 记忆：**rollup 顺着层级卷（k+1），cube 全都要（2^k）**。

**(d)** `{item_name, ()} × {color, ()} = 2 × 2 =` **4 组**：(item,color), (item), (color), ()——多 rollup 之间是**分组集合的笛卡尔积**（课件 P67 规律）。

</details>

**例题 13（OLAP 概念判断组）** 判断并说明理由：

(a) `sales` 关系中 `color` 是度量属性；(b) "把交叉报表从『按商品×颜色』换成『按商品×尺码』"叫 slicing；(c) MOLAP 把立方存进关系表；(d) 4 维数据要预计算 $4^2 = 16$ 种聚合；(e) `(item_name, color)` 的聚合能从 `(item_name, color, size)` 的聚合推出，`median` 不能；(f) 从"品类合计"点进"该品类各商品"是 rollup。

<details><summary>参考解答</summary>

| # | 判断 | 解析 |
|---|---|---|
| (a) | ❌ | `color` **定义观察视角** → 是**维度**；度量是可聚合的数值（`quantity`）——"能被 sum 的是度量，能被分组的是维度" |
| (b) | ❌ | 换维度 = **pivoting**；slicing 是**固定某维度取值**切一片（多维固定叫 dicing） |
| (c) | ❌ | 正好反了：MOLAP 用**内存多维数组**；存进关系表（只用关系特性）的是 **ROLAP**；部分内存 + 部分关系才是 HOLAP |
| (d) | ❌ | $n$ 维是 **$2^n$** 个分组组合 → 4 维是 $2^4 = \mathbf{16}$……等等，$2^4$ **恰好也是 16**——但理由必须对：**是 $2^n$ 不是 $n^2$**（换 3 维：$2^3=8 \ne 9$；换 5 维：$2^5=32 \ne 25$，公式就露馅了）。**结论：数值碰巧对，公式是错的**——这类"结论对、理由错"的选项照样判错 |
| (e) | ✅ | `(item,color)` 可由更细的 `(item,color,size)` 再按 size 聚合得到（可分解聚合，比从头算便宜）；**median 不可分解**——各分组的 median 合不出整体 median（课件点名） |
| (f) | ❌ | 粗 → 细是 **drill down（下钻）**；细 → 粗才是 rollup（上卷）——方向说反 |

</details>

---

## 8 知识点速查

| 知识点 | 核心要点 | 关键语法 / 记号 |
|---|---|---|
| 接入两方式 | API 动态（运行时发字符串）vs 嵌入式静态（编译期翻译、可查错） | JDBC/ODBC vs `EXEC SQL` / SQLJ |
| JDBC 四步 | 连接 → 语句 → 执行取结果 → 异常处理 | `try(Connection…; Statement…)` |
| 取结果 | 列号 **1 基**；按名与按号等价；`next()` 推进 | `rs.getString(1)` / `rs.getFloat("col")` |
| NULL 读取 | `getXXX` 遇 NULL 返回零值 → 紧跟 `wasNull()` | `if (rs.wasNull()) …` |
| SQL 注入 | 拼接让输入变"代码"；模板与数据分离即免疫 | `prepareStatement("… where name = ?")` |
| 元数据 | 结果列 / 库中表列 / 主键位置三类 | `getMetaData` `getColumns` `getPrimaryKeys`（`KEY_SEQ`） |
| JDBC 事务 | 默认每条自动提交；多步业务手控 | `setAutoCommit(false)` + `commit/rollback` |
| 可调用/LOB | 调库内函数过程；大对象读写 | `prepareCall("{call p(?,?)}")`、`setBlob(idx, stream)` |
| SQLJ | SQL 内嵌 Java、编译期检查、迭代器取结果 | `#sql iterator …;` `#sql iter = {…};` |
| ODBC | 应用↔DB 的标准 API（开连接/发语句/取结果） | C 接口跨语言标准 |
| 嵌入式游标 | declare（只声明）→ open（执行+取宿主变量值）→ fetch（'02000' 止）→ close（删临时关系） | `open c` / `fetch into` / `close c` |
| 游标更新 | 声明可更新 + 更新当前行 | `for update` / `where current of c` |
| SQL 函数 | 业务逻辑入库；`into` 写变量；标量返回单值 | `create function … returns integer …` |
| 表函数 | 返回关系、`from` 中用 `table()` 包装；参数用 `函数名.参数` 限定 | `from table(f('Music'))` |
| FOR 循环 | 游标迭代语法糖 | `for r as select … do … end for` |
| 外部历程 | C/Java 写函数挂进库；快但危险 | `language C external name '…'` |
| 外部历程安全 | 沙箱（安全语言）/ 独立进程 + IPC / 直接执行，前两种有开销 | 信任 ↔ 隔离权衡 |
| 触发器概念 | 修改的副作用、系统自动执行；先定条件再定动作 | `create trigger … after … when … begin atomic … end` |
| 行级触发器 | 每受影响行触发；`old row/new row` 别名 | `for each row` + `when` |
| 语句级触发器 | 每语句一次；整批数据用过渡表 | `for each statement` + `referencing old/new table` |
| credits_earned 教训 | 只加不减、F→X→F 重复加 | 差值式更新 / 定期对账 |
| 触发器风险 | 备份/复制误触发（先禁用）、错误连坐事务、级联执行 | 能不用就不用 |
| 递归查询 | seed ∪ 递归项，迭代到不动点；传递闭包 | `with recursive r as (base union recursive)` |
| 收敛条件 | **union 去重**才终止；union all 无限膨胀 | 一个词决定生死 |
| 表达力 | 固定 k 次连接只见 k 层；递归层数由数据决定 | $R^{(k)}$ vs $R^{+}=\bigcup_i R^i$ |
| 排名族 | rank 留空洞 / dense 连续 / row_number 不确定；配合 order by | `rank() over (order by …)` |
| 分区 | 分格独立排名；多排名并列；聚合之后才排名 | `over (partition by … order by …)` |
| Top-N | 窗口不能进 where → 包 CTE | `where r <= n`（外层） |
| 窗口框架 | 按位置（ROWS）/ 按键值（RANGE）取段；边界自动收缩 | `rows between 1 preceding and 1 following` |
| 累计/移动 | 累计 = unbounded preceding；移动平均除以实际行数 | 分区+排序+框架三件套 |
| 多维数据 | 度量（可聚合）× 维度（观察视角） | `sales(quantity; item, color, size)` |
| 交叉报表/立方 | crosstab 是 cube 的视图；'all'/NULL 标聚合 | cross-tab、data cube |
| CUBE | 全子集分组，$2^n$ 个 | `group by cube(a,b,c)` |
| GROUPING/DECODE | 验明 NULL 身份（1=聚合标记）并显示 'all' | `grouping(a)`、`decode(grouping(a),1,'all',a)` |
| ROLLUP | 前缀链分组 $k+1$ 个；多 rollup 笛卡尔积 | `group by rollup(a,b,c)` |
| OLAP 操作 | pivoting 换维、slicing/dicing 固定值、rollup 细→粗、drill down 粗→细 | — |
| OLAP 实现 | MOLAP 内存数组 / ROLAP 关系 / HOLAP 混合 | — |
| 物化聚合 | $2^n$ 全算太贵 → 部分物化 + 可分解推导；median 不可分解；一次排序算多聚合 | sum/count/min/max 可分解 |

### 核心思想总结

1. **本章是"SQL 的出圈史"**：出到程序里（JDBC/嵌入式——关键矛盾是**结构与数据的边界**，注入就发生在这条边界被抹掉的瞬间）、出到数据库内部（函数/触发器——把逻辑下沉换取**就近与自动**）、出到任意关系深度（递归——用**不动点**突破固定层数）、出到多维视角（OLAP——同一份数据的**2^n 张面孔**）。
2. **两条"分离"贯穿全章**：SQL 模板与用户数据分离（PreparedStatement）、声明式结果与过程化处理分离（游标/迭代器/触发器动作体）——**分离处即风险处，也是设计点**。
3. **触发器 = 自动化 ↔ 不可见性的交易**：它替你"顺手干活"，也把行为藏进数据修改的影子里——所以课件花整整两页讲"**何时不该用**"（物化视图、内置复制、封装方法是更好的答案）。
4. **递归的语义是不动点，不是展开**：seed 给出初值，`union` 去重保证收敛，迭代到"再也长不出新的"——这与 Ch4 视图展开（代入到只剩基本表）互补，共同构成视图的完整语义。
5. **窗口函数 = 聚合不压扁**：`group by` 把 N 行压成 1 行，窗口函数让每行都带上"所属分区 + 邻域"的聚合结果——排名、移动平均、累计余额是同一机制的三张面孔；**partition 划圈、order 定序、frame 划段**，三件套各司其职。
6. **OLAP 的本质是"预计算与存储的经济学"**：$2^n$ 张面孔不可能全存 → 只存一部分（物化），其余靠**可分解性**推导——**median 之不可分解，正是这套经济学的边界**；`cube`/`rollup`/`grouping()` 则是把这套多维账本搬进 SQL 语法的三个扳手。
