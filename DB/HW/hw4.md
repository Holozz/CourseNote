## 1.
```sql
SELECT student.*, takes.*
FROM student, takes
WHERE student.id = takes.id

UNION

SELECT student.*, NULL
FROM student
WHERE NOT EXISTS (
    SELECT 1
    FROM takes
    WHERE takes.id = student.id
);

```

```sql

SELECT student.*, takes.*
FROM student, takes
WHERE student.id = takes.id

UNION

SELECT student.*, NULL
FROM student
WHERE NOT EXISTS (
    SELECT 1
    FROM takes
    WHERE takes.id = student.id
);

UNION

SELECT NULL, takes.*
FROM takes
WHERE NOT EXISTS (
    SELECT 1
    FROM student
    WHERE takes.id = student.id
);

```

## 2.
`on delete cascade`决定当一个元组被删除时，这个元组里面的manager ID所在的所有manager属性行都会被删除，而作为employee属性的行不会被删除——换言之，删除一个经理时，他的所有下属以及下属的下属……都会被删除，而他的上级经理不会被删除

## 3.
```sql
CREATE VIEW v AS
SELECT year, SUM(credits)
FROM ...
GROUP BY year
```

## 4.
```sql
SELECT id
FROM student JOIN advisor ON id = s_id
WHERE i_id is null
```

## 5.
```sql
SELECT *
FROM section JOIN classroom using(room_number)
```

## 6.
会
A先将r的SELECT权限给B
作为public成员，B有r的SELECT权限及其转授
B把r的SELECT授权给A
所以形成了 $A \to public \to B\to A$的循环