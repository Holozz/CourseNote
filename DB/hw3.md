## 1.

```sql
--a.查找至少选修过一门计算机科学课程的每位学生的ID和姓名，确保结果中没有重复的姓名
SELECT id, name
FROM student JOIN (SELECT DISTINCT id
					FROM takes, course
					WHERE course_id = "Computer Science"
						AND takes.course_id = course.course_id
					) AS a
WHERE student.id = a.id
--------------------------------------------------------------------

--b.查找未选修过2017年之前开设的任何课程的每位学生的ID和姓名
SELECT id, name
FROM student JOIN (SELECT DISTINCT id
					FROM takes
					WHERE year>=2017
					) AS b
WHERE student.id = b.id
--------------------------------------------------------------------

--c.找到每个系的教师的最高薪水
SELECT dept_name, max(salary)
FROM instructor
GROUP BY dept_name
--------------------------------------------------------------------

--d.找到在所有系中计算出的每个系最高薪水的最低值
SELECT min(c)
FROM (SELECT dept_name, max(salary) AS c
	FROM instructor
	GROUP BY dept_name)
--------------------------------------------------------------------
```

## 2.
```sql
SELECT dept_name
FROM (SELECT dept_name, SUM(salary) AS s
		FROM instructor
		GROUP BY dept_name) AS d,
WHERE s > (SELECT AVG(s)
		   FROM d
		  ) 

```

## 3.
```sql
WHERE (SELECT COUNT(title) FROM course) = 
	(SELECT DISTINCT COUNT(title) FROM course)
```

## 4. 

```sql
--a.查找银行中的拥有账户但没有贷款的每位顾客的ID
SELECT id
FROM depositor,
EXCEPT (SELECT id
		FROM borrower
		)
--------------------------------------------

--b. 查找与顾客'12345'住在相同街道和城市的顾客的ID
SELECT b.ID
FROM customer AS a, customer AS b
WHERE a.id = '12345'
	AND a.customer_city = b.customer_city
	AND a.customer_street = b.customer_street
---------------------------------------------

--c. 查找每个至少有一位在银行拥有账户并住在"Harrison"的顾客的分行的名称
SELECT DISTINCT branch_name
FROM account
WHERE account_number IN(SELECT account_number
						FROM depositor
						WHERE id IN(SELECT id
									FROM customer
									WHERE customer_city = "Harrison"
									)
						)


	
```

## 5.
```sql
--a.找到每位在"Broolyn"的每个分行都有账户的顾客----------------------------
SELECT id
FROM depositor, account
WHERE depositor.account_number = account.account_number
	AND branch_name IN (SELECT branch_name
					    FROM branch
						WHERE branch_city = "Brooklyn")
GROUP BY id
HAVING COUNT(DISTINCT branch_name) = (SELECT COUNT(branch_name)
									  FROM branch
									  WHERE branch_city = "Broolyn"
									 )
---------------------------------------------------------------------



--b.找到银行中所有贷款金额的总和------------------------------------------
SELECT sum(amount)
FROM loan
---------------------------------------------------------------------



--c.找到具有资产超过至少一个位于"Brooklyn"分行的资产的所有分行名称-------------
SELECT branch_name
FROM branch
WHERE assets > some (SELECT assets
					FROM branch
					WHERE branch_city = "Brooklyn")
---------------------------------------------------------------------

```