<div class="cover" style="text-align: center; margin-top: 60px; margin-bottom: 100px">
  <h1 style="font-size: 2em;">2024级本科生《数据库系统实验》实验报告</h1>
  <h2 style="font-size: 1.6em;margin-bottom: 200px">Lecture 2</h2>
  <div class="info" style="font-size: 1.2em">
	  <p>班级：计科1班</p>
	  <p>姓名：韩宇 </p>
	  <p style="margin-bottom:400px">学号：24319050</p>
	  <p style="font-size: 1em;">日期：2026年9月16日</p>
  </div>
</div>


# 一、实验目的

- 熟悉SQL的数据定义语言，
- 能够熟练地使用SQL语句来创建和更改基本表,创建和取消索引。

# 二、实验内容

- 使用 CREATE语句创建基本表
- 更改基本表的定义，增加列，删除列，修改列的数据类型
- 创建表的升降序索引
- 取消表、表的索引或表的约束 

# 三、实验结果

>由于此次实验没有涉及每列具体数据，实验结果就是对表格的操作结果，故和语句的执行界面一并在图里可见

1. 创建数据库表 CUSTOMERS(CID, CNAME,CITY, DISCNT)，数据库AGENTS(AID, ANAME,CITY, PERCENT)，数据库表 PRODUCTS(PID. PNAME)，其中，CID，AID, PID分别是各表的主键，具有唯一性约束，表AGENTS中的PERCENT属性具有小于100的约束
	这里注意 `CREATE TABLE`不要漏掉括号
	![[Pasted image 20260916105600.png|600]]
2. 创建数据库表ORDERS( ORDNA, MONTH,CID,AID,PID,QTY, DOLLARS)。其中， ORDNA是主键，具有唯一性约束。CID，AID，PID是外键，分别参照的是表 CUSTOMERS的CID字段，表 AGENTS的AID字段，表 PRODUCTS的PID字段
	![[Pasted image 20260916110915.png|602]]
3. 增加数据库表 PRODUCTS的三个属性列：CITY, QUANTITY, PRICE
	![[Pasted image 20260916111441.png|602]]
4. 为以上4个表建立各自的按主键增序排列的索引
	![[Pasted image 20260916111832.png|606]]
5. 取消步骤(4)建立的4个索引
	![[Pasted image 20260916112105.png|612]]
6. 创建表CUSTOMERS的按CNAME降序排列的唯一性索引
	![[Pasted image 20260916112409.png|615]]
7. 删除步骤(3)创建的表AGENTS中的CITY属性
	![[Pasted image 20260916112517.png|618]]
8. 修改表CUSTOMERS中CITY属性为CHAR(40)
	![[Pasted image 20260916112646.png|617]]
9. 删除步骤(1)创建的表ORDERS
	![[Pasted image 20260916112957.png|613]]

# 四、问题&总结

刚开始编写Sql语句老是出现以下问题：
- 忘记一开始要切换到目标数据库进行操作
- 写了一句语法正确但不合目标的语句，不知道怎么撤销
- 漏掉括号、逗号，导致语法错误
- 忘记添加唯一性限制
- 大小写不习惯

以及对SqlServer的使用也不甚熟悉，不习惯进行每条语句的单独执行和图形化查询数据库信息
