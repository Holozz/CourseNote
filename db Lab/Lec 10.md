---
cssclasses:
---

<div class="cover">
  <h1>2024级本科生《数据库系统实验》实验报告</h1>
  <h2>Lecture 10</h2>
  <div class="info">
    <p>班级：计科1班</p>
    <p>姓名：韩宇</p>
    <p style="margin-bottom: 400px;">学号：24319050</p>
    <p class="date" style="font-size: 1em">日期：11/4</p>
  </div>
</div>

<div style="page-break-after: always;"></div>

---

## 一、实验目的

学习建立外键，以及利用FOREIGN KEY…REFERENCES子句以及各种约束保证参照完整性
## 二、实验内容

- 不违反参照完整性的插入数据示例
- 违反参照完整性的插入数据示例
- 级联删除 
- 两张表的互相参照问题

## 三、实验结果

## (1) 用alter table语句将SC表中的on delete cascade改为on delete no action,重新插入SC的数据（按照实验一）。再删除Stu_Union中sno为‘10001’的数据。观察结果，并分析原因

准备阶段已插入 `95002` 的两条选课记录，本题先将 `SC.sno` 的外键删除规则改为 `NO ACTION`，再插入 `10001` 对应课程 `0001`、`0002` 的记录。尝试删除 `10001` 时，SQL Server 报错 547，因为 `SC` 中仍有记录引用该学号。

```sql
ALTER TABLE SC DROP CONSTRAINT FK__SC__sno__3864608B;

ALTER TABLE SC ADD CONSTRAINT FK_SC_Stu_Union
FOREIGN KEY (sno) REFERENCES Stu_Union(sno)
ON DELETE NO ACTION;

INSERT INTO SC VALUES ('10001', '0001', 2);
INSERT INTO SC VALUES ('10001', '0002', 2);
DELETE FROM Stu_Union WHERE sno = '10001';
```

![[Pasted image 20261104113415.png|586]]


删除失败后分别查询两张表，`Stu_Union` 中仍有学生 `10001`，`SC` 中仍有该学生的两条选课记录。

```sql
SELECT * FROM Stu_Union WHERE sno = '10001';

SELECT * FROM SC WHERE sno = '10001';
GO
```

![[Pasted image 20261104113410.png|589]]

## (2) 用alter table语句将SC表中的on delete no action改为on delete set NULL,重新插入SC的数据（按照实验一） 。再删除Stu_Union中sno为‘10001’的数据。观察结果，并分析原因


先删除上一题建立的学号外键，直接尝试改为 `SET NULL`。截图中报错 1761，因为 `sno` 属于联合主键 `(sno, cno)`，不能取空值。

```sql
ALTER TABLE dbo.SC DROP CONSTRAINT FK_SC_Stu_Union;
ALTER TABLE dbo.SC ADD CONSTRAINT FK_SC_Stu_Union
FOREIGN KEY (sno) REFERENCES Stu_Union(sno)
ON DELETE SET NULL;
```

![[Pasted image 20261104114725.png|594]]



接着删除课程外键和联合主键，将 `sno`、`cno` 改为允许空值，再建立两个使用 `SET NULL` 的外键。截图显示两个新外键创建成功。

```sql
ALTER TABLE SC DROP CONSTRAINT FK__SC__cno__395884C4;
ALTER TABLE SC DROP CONSTRAINT PK_SC;

ALTER TABLE SC ALTER COLUMN sno CHAR(5) NULL;
ALTER TABLE SC ALTER COLUMN cno CHAR(4) NULL;

-- 重新建立两个外键，设置删除时置空
ALTER TABLE SC ADD CONSTRAINT FK_SC_Stu_Union
    FOREIGN KEY (sno) REFERENCES Stu_Union(sno)
    ON DELETE SET NULL;

ALTER TABLE SC ADD CONSTRAINT FK_SC_Course
    FOREIGN KEY (cno) REFERENCES Course(cno)
    ON DELETE SET NULL;
```

![[Pasted image 20261104115246.png|600]]



沿用第一题保留下来的选课记录，再次删除 `10001`。查询结果中 `Stu_Union` 已没有该学生，`SC` 仍有 4 行。原来属于 `10001` 的两行只将 `sno` 置为 `NULL`，课程号和成绩都保留，`95002` 的两行也保持原样。

```sql
DELETE FROM Stu_Union WHERE sno = '10001';
SELECT * FROM Stu_Union
SELECT * FROM SC
```

![[Pasted image 20261104115223.png|600]]

## (3) 建立事务T3，修改ICBC_Card表的外键属性，使其变为on delete set NULL,尝试删除students表中一条记录。观察结果，并分析原因


按课件建立学生卡和银行卡表并插入数据。随后开启 `XACT_ABORT`，在事务 `T3` 中把银行卡表的学生卡外键改为 `SET NULL`，尝试删除 `800005753`。截图中报错 547，冲突来自 `CHOICES` 的 `FK_CHOICES_STUDENTS`，该学生仍被选课记录引用。

```sql
CREATE TABLE Stu_Card (
    card_id CHAR(14),
    stu_id CHAR(10) REFERENCES students(sid) ON DELETE CASCADE,
    remained_money DECIMAL(10, 2),
    CONSTRAINT PK_stu_card PRIMARY KEY (card_id)
);

INSERT INTO Stu_Card VALUES ('05212567', '800001216', 100.25);
INSERT INTO Stu_Card VALUES ('05212222', '800005753', 200.50);

SELECT * FROM Stu_Card;

CREATE TABLE ICBC_Card (
    bank_id CHAR(20),
    stu_card_id CHAR(14)
        REFERENCES Stu_Card(card_id) ON DELETE CASCADE,
    restored_money DECIMAL(10, 2),
    CONSTRAINT PK_Icbc_card PRIMARY KEY (bank_id)
);

INSERT INTO ICBC_Card VALUES ('955884402312', '05212567', 15000.1);
INSERT INTO ICBC_Card VALUES ('9558844023645', '05212222', 50000.3);

SELECT * FROM ICBC_Card;




SET XACT_ABORT ON;
BEGIN TRANSACTION T3;
ALTER TABLE ICBC_Card DROP CONSTRAINT [FK__ICBC_Card__stu_c__42E1EEFE];

ALTER TABLE dbo.ICBC_Card ADD CONSTRAINT FK_ICBC_StuCard
FOREIGN KEY (stu_card_id) REFERENCES dbo.Stu_Card(card_id)
ON DELETE SET NULL;
DELETE FROM dbo.students WHERE sid = '800005753'
COMMIT TRANSACTION T3;
```

![[Pasted image 20261104120513.png|605]]



出错后再次查询，学生 `800005753` 的学生卡 `05212222` 仍存在，余额为 `200.50`。本次删除失败触发事务回滚，事务中的外键修改也随之撤销，因此未观察到银行卡外键置空。

```sql
SELECT * FROM dbo.Stu_Card WHERE stu_id = '800005753';


SET XACT_ABORT OFF;
```

![[Pasted image 20261104120606.png|608]]


## (4) 创建一个班里的学生互助表，规定：包括学生编号，学生姓名，学生的帮助对象，每个学生有且仅有一个帮助对象，帮助对象也必须是班里的学生。（表的自参照问题）


以 `student_id` 为主键，每个学生只登记一行。`help_id` 要求非空，并通过自参照外键引用本表的学生编号，因此每人必须指定一个本班学生作为帮助对象。截图显示建表成功。

```sql
CREATE TABLE ClassHelp (
    student_id varchar(10) NOT NULL PRIMARY KEY,
    student_name varchar(20) NOT NULL,
    help_id varchar(10) NOT NULL,
    CONSTRAINT FK_ClassHelp_Target
				FOREIGN KEY (help_id)
				REFERENCES ClassHelp(student_id)
);
```

![[Pasted image 20261104121344.png|612]]


## (5) 学校学生会的每个部门都有一个部长，每个部长领导多个部员，每个部只有一个部员有评测部长的权利，请给出体现这两种关系（领导和评测）的两张互参照的表的定义。（两个表互相参照的问题）


先建立 `Lead_Department`，再建立带有 `FK_Leader` 的 `DeptMember`，最后用 `ALTER TABLE` 添加反向的 `FK_Reviewer`，截图显示执行成功。

`FK_Leader` 同时检查部门和部长编号，保证部员对应本部门部长。`FK_Reviewer` 同时检查部门和评测人编号，保证指定的评测人属于本部门。部门编号唯一，部长编号和部员编号分别为各表的主键。`reviewer_id` 可以留空，便于先录入部门和部员再指定评测人，因此当前约束允许每部门至多指定一名评测人。

```sql
CREATE TABLE Lead_Department (
    department_id varchar(10) NOT NULL UNIQUE,
    department_name varchar(20) NOT NULL,
    leader_id varchar(10) NOT NULL PRIMARY KEY,
    reviewer_id varchar(10) NULL,
	CONSTRAINT UQ_Lead_Department_Leader
		UNIQUE (department_id, leader_id)
);

CREATE TABLE DeptMember (
    member_id varchar(10) NOT NULL PRIMARY KEY,
    member_name varchar(20) NOT NULL,
    department_id varchar(10) NOT NULL,
	leader_id varchar(10) NOT NULL,
	CONSTRAINT UQ_DeptMember_Member 
	    UNIQUE (department_id, member_id),

    CONSTRAINT FK_Leader
        FOREIGN KEY (department_id, leader_id)
        REFERENCES Lead_Department(department_id, leader_id)
);

ALTER TABLE Lead_Department
ADD CONSTRAINT FK_Reviewer
	FOREIGN KEY (department_id, reviewer_id)
	REFERENCES DeptMember(department_id, member_id);
```

![[Pasted image 20261104134935.png|618]]



## 四、问题&总结

- 修改外键的删除规则时，先确认约束名称。使用 `SET NULL` 前，还要确认引用列允许空值。
- 删除主表记录时需要考虑所有引用它的外键。本次 `CHOICES` 的外键阻止删除，事务中的外键修改也被回滚。
- 自参照外键可以限制帮助对象的范围，两表互参照可以先建表再补外键。组合外键可以同时检查人员编号和部门编号。
