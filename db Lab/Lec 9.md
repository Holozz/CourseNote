---
cssclasses:
---

<div class="cover">
  <h1>2024级本科生《数据库系统实验》实验报告</h1>
  <h2>Lecture 9</h2>
  <div class="info">
    <p>班级：计科1班</p>
    <p>姓名：韩宇</p>
    <p style="margin-bottom: 400px;">学号：24319050</p>
    <p class="date" style="font-size: 1em">日期：10/28</p>
  </div>
</div>

<div style="page-break-after: always;"></div>

---

## 一、实验目的

学习实体完整性的建立，以及实践违反实体完整性的结果。

## 二、实验内容

(1)在数据库 school中建立表 Stu_Union,进行主键约束,在没有违反实体完整性的前提下插入并更新一条记录。
(2)演示违反实体完整性的插入操作。
(3)演示违反实体完整性的更新操作。
(4)演示事务的处理,包括事务的建立、处理,以及出错时的事务回退。
(5)通过建立 Scholarship表,插入数据,演示当与现有的数据环境不符时,无法建立实体完整性和参照完整性。
## 三、实验结果

### 1.在school数据库中建立一张新表class，包括class_id(varchar(4)), name(varchar(10)), department(varchar(20))三个列，并约束class_id为主键

在 `School` 数据库中创建 `class` 表，按题目设置三个列的数据类型，并用 `PK_class` 将 `class_id` 定义为主键，要求该列非空且不能重复，截图中建表成功

```sql
CREATE TABLE class (
    class_id varchar(4) NOT NULL,
    name varchar(10),
    department varchar(20),
    CONSTRAINT PK_class PRIMARY KEY (class_id)
);
```

![[Pasted image 20261028104313.png|522]]

### 2.创建事务T3，在事务中插入一个元组（‘0001’，’01CSC’,’’CS’）,并在T3中嵌套创建事务T4，T4也插入和T3一样的元组，编写代码测试，查看结果

先设置 `XACT_ABORT ON`，在外层事务 `T3` 中插入一条记录，再在内层事务 `T4` 中插入相同记录

第一次插入影响 1 行，第二次插入报主键重复错误，重复键值为 `0001`，开启 `XACT_ABORT` 后，这次错误会使整个事务回滚，外层第一次插入的记录也被撤销

```sql
SET XACT_ABORT ON;

BEGIN TRANSACTION T3;
INSERT INTO class (class_id, name, department)
VALUES ('0001', '01CSC', 'CS');

BEGIN TRANSACTION T4;
INSERT INTO class (class_id, name, department)
VALUES ('0001', '01CSC', 'CS');

COMMIT TRANSACTION T4;
COMMIT TRANSACTION T3;
```

![[Pasted image 20261028104628.png|521]]

接着改为 `XACT_ABORT OFF`，重新执行相同的嵌套事务，重复插入仍然报错，但只撤销失败的插入语句，外层已经插入的记录可以继续提交

查询返回 1 行，为 `('0001', '01CSC', 'CS')`，SQL Server 中内层事务不能独立提交，内层 `COMMIT` 只减少事务计数，最外层 `COMMIT` 才真正提交修改

```sql
SET XACT_ABORT OFF;
...
```

![[Pasted image 20261028104919.png|522]]

### 3.在表class中，尝试设置name=’01CSC‘的记录的class_id 为NULL，查看结果

按 `name = '01CSC'` 找到上一题插入的记录，尝试把 `class_id` 改为 `NULL`

执行报错，提示 `class_id` 列不允许有空值，更新失败，原记录保持不变，主键除了要求唯一，也要求非空

```sql
UPDATE class
SET class_id = NULL
WHERE name = '01CSC';
```

![[Pasted image 20261028105035.png|526]]

### 4.在表class中，不创建事务，插入两个元组 （‘0002’，’01CSC‘。 ’CS‘），（’0002‘，’03CSC‘，’CS‘），然后查看表中有几条记录，为什么？

不创建显式事务，用两条独立的 `INSERT` 插入主键同为 `0002` 的记录

第一条插入成功，影响 1 行，第二条因主键重复失败，重复键值为 `0002`，第一条已经自动提交，不会因第二条失败而撤销

```sql
INSERT INTO class (class_id, name, department)
VALUES ('0002', '01CSC', 'CS');

INSERT INTO class (class_id, name, department)
VALUES ('0002', '03CSC', 'CS');
```

![[Pasted image 20261028105326.png|518]]

查询表中数据，返回 2 行，分别为 `('0001', '01CSC', 'CS')` 和 `('0002', '01CSC', 'CS')`，第二条插入中的 `03CSC` 没有写入

```sql
SELECT * FROM class;
```

![[Pasted image 20261028105318.png|518]]

### 5.在表class中，创建事务，并设置开启回滚，然后插入两个元组（‘0003’，’03CSC‘。 ’CS‘），（’0001‘，’03CSC‘，’CS‘），查看结果，表中有几条记录？

设置 `XACT_ABORT ON`，在事务 `T5` 中先插入主键为 `0003` 的记录，再插入主键为 `0001` 的记录

第一条影响 1 行，第二条因表中已有 `0001` 而报主键重复错误，整个 `T5` 回滚，刚插入的 `0003` 也被撤销

```sql
SET XACT_ABORT ON;

BEGIN TRANSACTION T5;
INSERT INTO class (class_id, name, department)
VALUES ('0003', '03CSC', 'CS');

INSERT INTO class (class_id, name, department)
VALUES ('0001', '03CSC', 'CS');

COMMIT TRANSACTION T5;
```

![[Pasted image 20261028105515.png|520]]

出错后单独查询表和记录数，仍然只有 `0001`、`0002` 两条记录，`COUNT(*)` 返回 2

```sql
SELECT * FROM class;
SELECT COUNT(*) FROM class;
```

![[Pasted image 20261028105607.png|524]]

### 6.在完成上面几步的前提下，尝试设置’name‘为主键，看能否成功，并思考原因

先直接给 `name` 添加主键约束，执行报错，提示 `class` 表已经有定义好的主键

一张表只能有一个主键，原来的 `class_id` 主键尚未删除，所以这次报错的原因是已有主键，还没有验证 `name` 的取值能否满足唯一性

```sql
BEGIN TRANSACTION T6;

ALTER TABLE class
ADD CONSTRAINT PK_class_name PRIMARY KEY (name);

COMMIT TRANSACTION T6;

SELECT * FROM class;
```

![[Pasted image 20261028110238.png|530]]

再在事务中先删除原主键 `PK_class`，把 `name` 改为 `NOT NULL`，然后尝试建立新的主键

这次报错提示存在重复键值 `01CSC`，当前两条记录的 `name` 都是这个值，不满足主键的唯一性要求，所以仍不能创建主键

```sql
BEGIN TRANSACTION T6;

ALTER TABLE class DROP CONSTRAINT PK_class;
ALTER TABLE class ALTER COLUMN name varchar(10) NOT NULL;
ALTER TABLE class ADD CONSTRAINT PK_class_name PRIMARY KEY (name);

COMMIT TRANSACTION T6;
```

![[Pasted image 20261028110339.png|712]]

最后查询表，仍返回原来的两条记录，左侧对象资源管理器中 `class_id` 仍标记为主键
是因为本次开启了 `XACT_ABORT`，新主键创建失败后事务回滚，前面对原主键的删除也被撤销

![[Pasted image 20261028110542.png|718]]

## 四、问题&总结

- 主键要求非空且唯一，重复插入和将主键更新为 `NULL` 都会失败
- 本次重复键实验中，`XACT_ABORT OFF` 保留事务中此前成功的操作，`ON` 则使整个事务回滚，嵌套事务也不能独立提交
- 更换主键时，既要处理原有约束，也要检查新列是否非空、是否存在重复值
- 本次实验主要学习了新表格的创建，熟悉基本操作；以及学习事务的使用，了解其原子性和独立性
