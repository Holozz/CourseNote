## 1
两个子模式为 $R_1=(A,B,C)$、$R_2=(A,D,E)$，则
$$R_1\cap R_2=\{A\}$$

由二元分解的无损连接判定定理：若$(R_1\cap R_2)\to R_1 \quad\text{或}\quad (R_1\cap R_2)\to R_2$属于$F^+$，则分解是无损的
由 $A\to BC$，结合自反律 $A\to A$，由合并律得$A\to ABC$
因此$(R_1\cap R_2)\to R_1$成立，故该分解是无损分解

## 2
第1问里的就是BCND无损分解
### 1. $R_1(A,B,C)$ 满足 BCNF

其投影依赖可用下面这组依赖表示：
$A\to BC,\qquad BC\to A$

其中 $BC\to A$ 的推导为：
$BC\xrightarrow{B\to D}BCD \xrightarrow{CD\to E}BCDE \xrightarrow{E\to A}ABCDE$

因此，$R_1$ 的候选键为 A、BC,单独的 B 或 C 不能推出 $R_1$ 中的其他属性，所以每个非平凡函数依赖的决定因素都是超键，满足 BCNF

### 2. $R_2(A,D,E)$ 满足 BCNF

同理$A\to BC,\quad B\to D,\quad CD\to E$ 可得 $A\to DE$；再结合 $E\to A$，可得 $E\to AD$
因此，其投影依赖可表示为：$A\to DE,\qquad E\to AD$
$R_2$ 的候选键为 A,E 单独的 D 不能推出其他属性，因此满足 BCNF

## 3
$R(A,B,C,D,E),\qquad F=\{A\to BC,\ CD\to E,\ B\to D,\ E\to A\}$
然后得到正则覆盖 $F_c=F=\{A\to BC,\ CD\to E,\ B\to D,\ E\to A\}$
建立所有子模式 $A\cup BC,CD\cup E,B\cup D,E\cup A$,其中候选键A包含在ABC里，无需为候选键额外建表
所以结果是
$$
{ABC,\ CDE,\ BD,\ AE}
$$
## 4
问题1里的分解： $R_1=(A,B,C)$、$R_2=(A,D,E)$
显然不保持原来的全部依赖，比如 $B\to D$，计算$B^+_{F_1\cup F_2}=\{B\}$不能推出原来的依赖

## 5
设关系模式为：$R(\text{学生},\text{爱好},\text{语言})$

规定每个学生的爱好与掌握的语言相互独立，因此存在多值依赖：$\text{学生}\twoheadrightarrow\text{爱好}$
学生不能唯一确定爱好，只能确定爱好集合，所以是多值依赖，没有函数依赖

满足 BCNF：BCNF 要求每个非平凡函数依赖的决定因素都是超键,这里没有非平凡函数依赖，因此满足BCNF
不满足 4NF：4NF 要求每个非平凡多值依赖的决定因素都是超键,但对于$\text{学生}\twoheadrightarrow\text{爱好}$,既是非平凡的：爱好不包含于学生，且“学生、爱好”没有覆盖全部属性；又学生不是超键：同一学生可以对应多行。所以不满足4NF