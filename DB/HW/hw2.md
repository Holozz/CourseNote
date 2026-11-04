### 1.
employee：pid
works：pid
company：cid
### 2.
a.查找每位不在“BigBank”工作的员工的ID 和姓名
$$\Pi_{pid\ ,person\ name}(\sigma_{company\ name\neq"big\ park"}(works))$$
b.查找每位至少和数据库中的一位员工薪资一样多的员工的ID 和姓名
$$\textit{I}_1 \leftarrow \rho_{\textit{I}_1}(\textit{works}), \quad \textit{I}_2 \leftarrow \rho_{\textit{I}_2}(\textit{works})$$
$$\Pi_{I_{1}.person\ name,\ I_{1}.pid}\Big(\sigma_{\textit{I}_1.\textit{salary} = \textit{I}_2.\textit{salary} \ \wedge\ \textit{I}_1.\textit{pid}\neq\textit{I}_2.\textit{pid}}(\textit{I}_1 \times \textit{I}_2)\Big)$$
### 3.
a.找到每个贷款金额大于$10000 的贷款号
$$
\Pi_{loan\_number}(\sigma_{amount>10000}(loan))
$$
b.找到每位有账户余额大于$6000 的存款人的ID
$$
\Pi_{ID}\Big(\sigma_{balance>6000}(account\bowtie depositer)\Big)
$$
c.找到每位在“Uptown”分行有账户余额大于$6000 的存款人的ID
$$
\Pi_{ID}\Big(\sigma_{balance>6000\wedge branch\_name=\text{"Uptown"}}(account\bowtie depositer)\Big)
$$
### 4.
1. 属性值未知  
    某个元组的某个属性值目前不知道，可暂时取为NULL
2. 属性值不存在或不适用  
    某个属性对该元素不合适，比如上下级关系，最下级和最上级分别没有下级和上级
### 5.
a. 找到物理系的每位教师的ID 和姓名
$$
\Pi_{ID,\ name}\Big(\sigma_{dept\_name=\text{"Physics"}}(instructor)\Big)
$$

b. 找到位于“Watson”教学楼的每位系的教师的ID 和姓名
$$
\Pi_{ID,\ name}\Big(\sigma_{building=\text{"Watson"}}(department \bowtie instructor)\Big)
$$

c. 找到至少选修过一门“Comp. Sci.”系的每位学生的ID 和姓名
$$
E\leftarrow\rho_{E}(\Pi_{course\_id}\Big(\sigma_{dept\_name=\text{"Comp.Sci"}}(department \bowtie course)\Big))
$$
$$
F\leftarrow\rho_{F}(\Pi_{ID}\Big(\sigma_{takes.course\_id=E.course\_id}(takes \bowtie E)\Big))
$$
$$
\Pi_{ID,\ name}(\sigma_{student.ID=F.ID}(student \bowtie F))
$$

d. 找到在2018 年至少选修过一门课程的每位学生的ID 和姓名
$$
\Pi_{ID,\ name}\Big(\sigma_{year=2018}(takes\bowtie student)\Big)
$$
e. 找到在2018 年没有选修过任何课程的每位学生的ID 和姓名
$$
I_{1}\leftarrow \rho_{I_{1}}(\Pi_{ID,\ name}\Big(\sigma_{year=2018}(takes\bowtie student)\Big))
$$
$$
I_{2}\leftarrow \rho_{I_{2}}(\Pi_{ID,\ name}(student))
$$
$$
I_{2}-I_{1}
$$
