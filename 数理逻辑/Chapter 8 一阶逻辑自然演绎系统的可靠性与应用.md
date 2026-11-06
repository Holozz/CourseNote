---
tags:
  - 数理逻辑
  - 一阶逻辑
  - 自然演绎
  - 可靠性
  - 量词等值
  - 课程笔记
课程: 数理逻辑
章节: 第八章 一阶逻辑自然演绎系统的可靠性与应用
教材:
---

> [!info] 本章定位
> 本章承接 [[Chapter 7 一阶逻辑的代入定理和自然演绎系统]]，将“每条规则保持语义后承”提升为“整段形式推导保持语义后承”，再用该系统证明量词交换、量词否定以及量词与联结词的等值律. 理解本章的关键有四点：代入定理是实例规则可靠性的语义桥梁；带方框规则必须连同被解除的假设一起表述；新参数条件保证赋值可以任意改变或从局部见证恢复；可靠性只能把形式推导送到语义后承，反方向属于完备性.

**材料**：刘咏梅，2026 年秋季《第八讲：一阶逻辑的自然演绎系统的应用》，`Lec08-FONatDedApp-Post.pdf`，全部 30 个 PDF 物理页面，每页一张幻灯片. 本文统一使用 **PDF 物理页码**. 课件中的规则、证明和例题均已覆盖；补充的等号规则证明、完整归纳框架、反模型及课件未展开的等值证明模式均明确标注.

**记号**：$\Gamma\vdash A$ 表示从前提集 $\Gamma$ 存在一段合法自然演绎推导得到 $A$，$\Gamma\models A$ 表示每个使 $\Gamma$ 中全部公式为真的解释与对象赋值也使 $A$ 为真. $A[t/x]$ 表示只把 $A$ 中自由出现的 $x$ 替换为项 $t$，并默认 $t$ 在 $A$ 中对 $x$ 可自由代入. $\mathcal M\models_l A$ 表示 $A$ 在解释 $\mathcal M$ 与对象赋值 $l$ 下为真. 论域始终非空.

## 目录

- [[#1. 代入定理与自然演绎规则回顾|1. 代入定理与自然演绎规则回顾]]
	- [[#1.1 代入定理|1.1 代入定理]]
	- [[#1.2 命题规则、量词规则与方框|1.2 命题规则、量词规则与方框]]
	- [[#1.3 两种典型量词推导|1.3 两种典型量词推导]]
- [[#2. 单条规则的可靠性|2. 单条规则的可靠性]]
	- [[#2.1 规则可靠性的统一表述|2.1 规则可靠性的统一表述]]
	- [[#2.2 不带方框的等号与量词规则|2.2 不带方框的等号与量词规则]]
	- [[#2.3 带方框的命题规则|2.3 带方框的命题规则]]
	- [[#2.4 全称引入的可靠性|2.4 全称引入的可靠性]]
	- [[#2.5 存在消去的可靠性|2.5 存在消去的可靠性]]
- [[#3. 从规则可靠性到系统可靠性|3. 从规则可靠性到系统可靠性]]
	- [[#3.1 逐行语义不变量|3.1 逐行语义不变量]]
	- [[#3.2 全称推理例子的逐行验证|3.2 全称推理例子的逐行验证]]
	- [[#3.3 存在推理例子的逐行验证|3.3 存在推理例子的逐行验证]]
	- [[#3.4 可靠性与完备性的边界|3.4 可靠性与完备性的边界]]
- [[#4. 等号与量词次序的应用|4. 等号与量词次序的应用]]
	- [[#4.1 函数对等号保持一致|4.1 函数对等号保持一致]]
	- [[#4.2 两个存在量词可以交换|4.2 两个存在量词可以交换]]
	- [[#4.3 从统一见证到逐点见证|4.3 从统一见证到逐点见证]]
	- [[#4.4 逆方向不成立的反模型|4.4 逆方向不成立的反模型]]
- [[#5. 量词等值律的结构|5. 量词等值律的结构]]
	- [[#5.1 量词否定与同类量词交换|5.1 量词否定与同类量词交换]]
	- [[#5.2 量词与合取、析取的分配|5.2 量词与合取、析取的分配]]
	- [[#5.3 变量无关时的量词外提|5.3 变量无关时的量词外提]]
	- [[#5.4 蕴含中的量词对偶|5.4 蕴含中的量词对偶]]
- [[#6. 例题：量词等值律的自然演绎证明|6. 例题：量词等值律的自然演绎证明]]
	- [[#6.1 存在量词对析取的分配|6.1 存在量词对析取的分配]]
	- [[#6.2 否定全称与存在反例|6.2 否定全称与存在反例]]
	- [[#6.3 从蕴含前件移出量词|6.3 从蕴含前件移出量词]]
	- [[#6.4 全称量词对合取的分配|6.4 全称量词对合取的分配]]
	- [[#6.5 其余等值式的证明模式|6.5 其余等值式的证明模式]]
- [[#7. 易错点速查|7. 易错点速查]]
- [[#8. 知识点速查|8. 知识点速查]]
	- [[#8.1 可靠性证明的依赖关系|8.1 可靠性证明的依赖关系]]
	- [[#8.2 量词推导检查表|8.2 量词推导检查表]]

---

## 1. 代入定理与自然演绎规则回顾

对应课件第 3—9 页. 这些内容在上一章已经建立，本节只保留本章可靠性论证直接使用的部分.

### 1.1 代入定理

> [!note] 定义：自由代入
> 项 $t$ 在公式 $A$ 中对变量 $x$ **可自由代入**，是指用 $t$ 替换 $A$ 中每个自由出现的 $x$ 后，$t$ 中的任何变量都不会被替换位置外层的量词捕获.

例如，若 $A=\forall y\neg(x=y+y)$，则项 $x+y$ 不能在 $A$ 中对 $x$ 自由代入，因为新放入的 $y$ 会落入 $\forall y$ 的作用域. 这不是排版限制，而是保证语法代入与语义赋值更新一致所必需的条件.

> [!important] 代入定理
> 若 $t$ 在 $A$ 中对 $x$ 可自由代入，令 $a=t^{\mathcal M}[l]$，则
> $$
> \mathcal M\models_l A[t/x]
> \quad\Longleftrightarrow\quad
> \mathcal M\models_{l[x\mapsto a]}A.
> $$

左侧先在语法中写入项 $t$，再按原赋值求真值；右侧先求出 $t$ 的指称 $a$，把 $x$ 的值更新为 $a$，再判断原公式 $A$. 代入定理说明这两条路径等价. 本章证明 $\forall e$、$\exists i$、$\forall i$ 和 $\exists e$ 可靠时，都要显式使用这座桥梁.

### 1.2 命题规则、量词规则与方框

命题逻辑部分继续使用 $\land i/e$、$\lor i/e$、$\to i/e$、$\neg i/e$、$\bot e$ 和经典双重否定消去. 一阶逻辑增加下列规则.

| 规则 | 输入 | 输出 | 关键条件 |
|---|---|---|---|
| $=i$ | 无 | $t=t$ | $t$ 是合法项 |
| $=e$ | $t_1=t_2$，$A[t_1/x]$ | $A[t_2/x]$ | 两项均可自由代入 |
| $\forall e$ | $\forall xA$ | $A[t/x]$ | $t$ 可自由代入 |
| $\exists i$ | $A[t/x]$ | $\exists xA$ | $t$ 可自由代入 |
| $\forall i$ | 任意参数框内得到 $A[a/x]$ | $\forall xA$ | $a\ne x$，且 $a$ 不出现在外部未解除假设或 $A$ 中 |
| $\exists e$ | $\exists xA$，见证框中由 $A[a/x]$ 得到 $C$ | $C$ | $a\ne x$，且 $a$ 不出现在外部假设、$A$ 或 $C$ 中 |

**方框的语义**不是“多画一层边框”，而是改变当前可用的假设集合. $\to i$、$\neg i$ 和 $\forall i$ 各关闭一个局部框；$\lor e$ 比较两个平行分支；$\exists e$ 关闭一个局部见证框. 证明可靠性时，必须把框内增加了什么假设、关框时解除什么条件写入命题.

### 1.3 两种典型量词推导

**全称前提推出全称结论**：

$$
\forall x(P(x)\to Q(x)),\ \forall xP(x)\vdash\forall xQ(x).
$$

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\forall x(P(x)\to Q(x))$ | 前提 |
| 2 | 全局 | $\forall xP(x)$ | 前提 |
| 3 | 任意参数 $a$ | $P(a)\to Q(a)$ | $\forall e$，1 |
| 4 | 任意参数 $a$ | $P(a)$ | $\forall e$，2 |
| 5 | 任意参数 $a$ | $Q(a)$ | $\to e$，3、4 |
| 6 | 全局 | $\forall xQ(x)$ | $\forall i$，3—5 |

**全称规律作用于存在见证**：

$$
\forall x(P(x)\to Q(x)),\ \exists xP(x)\vdash\exists xQ(x).
$$

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\forall x(P(x)\to Q(x))$ | 前提 |
| 2 | 全局 | $\exists xP(x)$ | 前提 |
| 3 | 见证 $a$ | $P(a)$ | $\exists e$ 的局部假设 |
| 4 | 见证 $a$ | $P(a)\to Q(a)$ | $\forall e$，1 |
| 5 | 见证 $a$ | $Q(a)$ | $\to e$，4、3 |
| 6 | 见证 $a$ | $\exists xQ(x)$ | $\exists i$，5 |
| 7 | 全局 | $\exists xQ(x)$ | $\exists e$，2、3—6 |

第一段推导中的 $a$ 代表任意对象，因此可以全称化；第二段中的 $a$ 只代表前提保证存在的某个对象，因此只能在消去其名字后把结论带出框. 两种新参数不能互换身份.

## 2. 单条规则的可靠性

对应课件第 11—15 页. 证明整个系统可靠之前，先证明每一种局部推理都保持语义后承.

### 2.1 规则可靠性的统一表述

> [!note] 定义：规则可靠
> 对一条不带方框的规则 $r$，设其前提集合为 $\Gamma_r$、结论为 $D_r$. 若 $\Gamma_r\models D_r$，则规则 $r$ 可靠.

这一定义表达的是：任取解释与对象赋值，只要规则上方列出的全部公式为真，横线下的公式就必真. 对带方框的规则，局部假设必须进入相应分支的前提集，可靠性表述如下.

| 规则 | 需要证明的语义命题 |
|---|---|
| $\to i$ | 若 $\Gamma\cup\{A\}\models B$，则 $\Gamma\models A\to B$ |
| $\lor e$ | 若 $\Gamma\models A\lor B$，$\Gamma\cup\{A\}\models C$，$\Gamma\cup\{B\}\models C$，则 $\Gamma\models C$ |
| $\neg i$ | 若 $\Gamma\cup\{A\}\models\bot$，则 $\Gamma\models\neg A$ |
| $\forall i$ | 若 $\Gamma\models A[a/x]$ 且 $a$ 满足新鲜性条件，则 $\Gamma\models\forall xA$ |
| $\exists e$ | 若 $\Gamma\models\exists xA$，$\Gamma\cup\{A[a/x]\}\models C$ 且 $a$ 满足新鲜性条件，则 $\Gamma\models C$ |

### 2.2 不带方框的等号与量词规则

**全称消去 $\forall e$**. 要证 $\forall xA\models A[t/x]$. 任取 $\mathcal M,l$ 并假设 $\mathcal M\models_l\forall xA$. 令 $a=t^{\mathcal M}[l]$. 全称语义给出 $\mathcal M\models_{l[x\mapsto a]}A$；由代入定理反向得到 $\mathcal M\models_l A[t/x]$.

**存在引入 $\exists i$**. 要证 $A[t/x]\models\exists xA$. 任取 $\mathcal M,l$ 并假设 $\mathcal M\models_l A[t/x]$. 令 $a=t^{\mathcal M}[l]$. 代入定理给出 $\mathcal M\models_{l[x\mapsto a]}A$，所以 $a$ 就是存在量词所需的见证，故 $\mathcal M\models_l\exists xA$.

> [!abstract] 补充证明：等号引入可靠
> 在一阶逻辑中，等号解释为论域上的恒等关系. 任意项 $t$ 在 $\mathcal M,l$ 下都与自身具有同一指称，因此 $\mathcal M\models_l t=t$. 故 $\models t=t$.

> [!abstract] 补充证明：等号消去可靠
> 假设 $\mathcal M\models_l t_1=t_2$ 且 $\mathcal M\models_l A[t_1/x]$. 令两项的共同指称为 $a$. 由代入定理，第二个假设等价于 $\mathcal M\models_{l[x\mapsto a]}A$. 因 $t_2$ 的指称也为 $a$，再次反用代入定理得到 $\mathcal M\models_l A[t_2/x]$. 可自由代入条件保证两次调用代入定理合法.

上述四条规则都没有局部假设要解除，可靠性直接表现为“前提公式同时为真时，结论为真”.

### 2.3 带方框的命题规则

这些规则的证明只使用联结词语义，但它们展示了处理方框的一般方法.

**蕴含引入**. 假设 $\Gamma\cup\{A\}\models B$. 任取满足 $\Gamma$ 的 $\mathcal M,l$. 若 $A$ 假，则 $A\to B$ 真；若 $A$ 真，则 $\mathcal M,l$ 满足 $\Gamma\cup\{A\}$，由假设可得 $B$ 真，所以 $A\to B$ 仍真. 因此 $\Gamma\models A\to B$.

**析取消去**. 假设 $\Gamma\models A\lor B$，且两个分支分别满足 $\Gamma\cup\{A\}\models C$ 和 $\Gamma\cup\{B\}\models C$. 任取满足 $\Gamma$ 的 $\mathcal M,l$. 由第一条件，$A,B$ 至少一个为真；若 $A$ 真则由左分支得 $C$，若 $B$ 真则由右分支得 $C$. 所以无论进入哪一分支，$C$ 都真.

**否定引入**. 假设 $\Gamma\cup\{A\}\models\bot$. 任取满足 $\Gamma$ 的 $\mathcal M,l$. 若 $A$ 也真，便会推出永假的 $\bot$，矛盾. 因而 $A$ 假，即 $\neg A$ 真. 这证明 $\Gamma\models\neg A$.

### 2.4 全称引入的可靠性

> [!important] 命题
> 若 $\Gamma\models A[a/x]$，且新参数 $a\ne x$ 并且不出现在 $\Gamma$ 或原公式 $A$ 中，则 $\Gamma\models\forall xA$.

**证明思路**：要证明全称公式，必须让 $x$ 取任意 $d\in D$. 新参数 $a$ 不在外部前提中，所以可以暂时把 $a$ 的值改成这个任意 $d$，而不破坏前提；再用代入定理把 $A[a/x]$ 转回 $A$.

**证明**：任取满足 $\Gamma$ 的解释与赋值 $\mathcal M,l$，并任取 $d\in D$. 令 $l'=l[a\mapsto d]$. 因 $a$ 不出现在 $\Gamma$ 中，赋值一致性引理保证 $\mathcal M\models_{l'}\Gamma$. 由已知语义后承，$\mathcal M\models_{l'}A[a/x]$.

参数项 $a$ 在 $l'$ 下的指称正是 $d$. 代入定理给出 $\mathcal M\models_{l'[x\mapsto d]}A$. 又因 $a$ 不出现在 $A$ 中，$l'[x\mapsto d]$ 与 $l[x\mapsto d]$ 在 $A$ 的自由变量上相同，故 $\mathcal M\models_{l[x\mapsto d]}A$. 这个结论对任意 $d\in D$ 成立，因此 $\mathcal M\models_l\forall xA$.

这里两处新鲜性各有作用：$a$ 不在 $\Gamma$ 中，保证改变 $a$ 的值不破坏前提；$a$ 不在 $A$ 中，保证完成代入后可以删除对 $a$ 的临时赋值. 若缺少任一条件，参数便可能携带外部依赖，不再代表任意对象.

### 2.5 存在消去的可靠性

> [!important] 命题
> 若 $\Gamma\models\exists xA$，并且 $\Gamma\cup\{A[a/x]\}\models C$，其中新参数 $a\ne x$ 并且不出现在 $\Gamma$、$A$ 或 $C$ 中，则 $\Gamma\models C$.

**证明思路**：存在前提提供某个对象 $d$，用新参数 $a$ 在局部框中给它命名. 分支推导得到 $C$ 后，因为 $C$ 不含 $a$，可以删除这个临时名字，把结论带出框.

**证明**：任取满足 $\Gamma$ 的 $\mathcal M,l$. 由 $\Gamma\models\exists xA$，有 $\mathcal M\models_l\exists xA$，故存在 $d\in D$ 使 $\mathcal M\models_{l[x\mapsto d]}A$. 令 $l'=l[a\mapsto d]$.

因为 $a$ 不出现在 $A$ 中，$l'[x\mapsto d]$ 与 $l[x\mapsto d]$ 在 $A$ 的自由变量上相同. 因而 $\mathcal M\models_{l'[x\mapsto d]}A$. 代入定理反向给出 $\mathcal M\models_{l'}A[a/x]$. 又因 $a$ 不出现在 $\Gamma$ 中，$\mathcal M\models_{l'}\Gamma$. 所以 $l'$ 满足分支的全部前提，由 $\Gamma\cup\{A[a/x]\}\models C$ 得 $\mathcal M\models_{l'}C$.

最后，$a$ 不出现在 $C$ 中，赋值一致性引理允许从 $l'$ 恢复为 $l$，得到 $\mathcal M\models_l C$. 因 $\mathcal M,l$ 任意，故 $\Gamma\models C$.

> [!warning] 三个新鲜性条件不能合并成一句“取新变量”后略过
> $a\notin\Gamma$ 保证外部前提不依赖见证名；$a\notin A$ 使代入与赋值更新的还原成立；$a\notin C$ 防止把只关于这个局部见证的信息带到框外. 三者在证明中承担不同任务.

## 3. 从规则可靠性到系统可靠性

对应课件第 7 页及第 16—17 页. 第 2 节只证明了局部规则正确，本节说明一段任意长度、含嵌套方框的证明为何仍然正确.

### 3.1 逐行语义不变量

> [!important] 一阶自然演绎系统的可靠性
> 对任意前提集 $\Gamma$ 和公式 $D$，若 $\Gamma\vdash D$，则 $\Gamma\models D$.

设一段证明的第 $i$ 行为 $A_i$，该行所在位置仍未解除的局部假设集合为 $\Delta_i$. 证明下面的逐行不变量：

$$
\Gamma\cup\Delta_i\models A_i.
$$

按证明行号作强归纳.

1. 若第 $i$ 行是全局前提，则 $A_i\in\Gamma$，后承立即成立.
2. 若第 $i$ 行是局部假设，则 $A_i\in\Delta_i$，后承同样立即成立.
3. 若第 $i$ 行由不带方框的规则从较早行得到，归纳假设保证各输入行由当前上下文后承；该规则的可靠性再推出当前结论.
4. 若第 $i$ 行关闭一个或多个方框，则归纳假设先给出相应扩展上下文中的分支结论，再应用第 2.3—2.5 节对应的带方框规则，把局部假设或参数依赖合法消去.

证明最后一行 $D$ 位于所有局部框之外，所以 $\Delta_i=\varnothing$. 逐行不变量便退化为 $\Gamma\models D$，得到系统可靠性.

这一论证是对**证明结构**的归纳，而不是对公式结构的归纳. 公式结构归纳用于代入定理等语法递归命题；这里归纳对象是证明行或证明树节点.

### 3.2 全称推理例子的逐行验证

令 $\Gamma=\{\forall x(P(x)\to Q(x)),\forall xP(x)\}$. 对第 1.3 节第一段证明，可靠性传递如下.

| 行 | 局部可靠性事实 | 与 $\Gamma$ 合成后的结论 |
|---|---|---|
| 1 | 前提自身后承 | $\Gamma\models\forall x(P(x)\to Q(x))$ |
| 2 | 前提自身后承 | $\Gamma\models\forall xP(x)$ |
| 3 | $\forall x(P(x)\to Q(x))\models P(a)\to Q(a)$ | $\Gamma\models P(a)\to Q(a)$ |
| 4 | $\forall xP(x)\models P(a)$ | $\Gamma\models P(a)$ |
| 5 | $P(a)\to Q(a),P(a)\models Q(a)$ | $\Gamma\models Q(a)$ |
| 6 | 由新参数条件应用 $\forall i$ | $\Gamma\models\forall xQ(x)$ |

第 3—5 行位于任意参数框内，但没有增加关于 $a$ 的性质假设. 新鲜性保证 $\Gamma$ 不含 $a$，故第 6 行可以把任意实例提升为全称结论.

### 3.3 存在推理例子的逐行验证

令 $\Gamma=\{\forall x(P(x)\to Q(x)),\exists xP(x)\}$. 对第 1.3 节第二段证明，局部见证框中的上下文为 $\Gamma\cup\{P(a)\}$.

| 行 | 当前后承 |
|---|---|
| 1 | $\Gamma\models\forall x(P(x)\to Q(x))$ |
| 2 | $\Gamma\models\exists xP(x)$ |
| 3 | $\Gamma\cup\{P(a)\}\models P(a)$ |
| 4 | $\Gamma\cup\{P(a)\}\models P(a)\to Q(a)$ |
| 5 | $\Gamma\cup\{P(a)\}\models Q(a)$ |
| 6 | $\Gamma\cup\{P(a)\}\models\exists xQ(x)$ |
| 7 | $\Gamma\models\exists xQ(x)$ |

第 6 行的结论已经不含 $a$，因此第 7 行可用 $\exists e$ 消去局部见证. 若第 6 行只得到 $Q(a)$，则不能直接带出框，因为那会把“某个对象满足 $Q$”错误地变成关于外部指定对象 $a$ 的断言.

### 3.4 可靠性与完备性的边界

| 元定理 | 方向 | 排除的坏情况 |
|---|---|---|
| 可靠性 | $\Gamma\vdash D\Rightarrow\Gamma\models D$ | 系统证明出语义上不成立的结论 |
| 完备性 | $\Gamma\models D\Rightarrow\Gamma\vdash D$ | 语义上必然成立却在系统中无法证明 |

课件第 7 页把二者合写为 $\Gamma\vdash D$ 当且仅当 $\Gamma\models D$. 本讲随后展开的是可靠性方向. 不能在可靠性证明中先用“语义后承必有形式证明”，因为那正是完备性方向，会造成循环论证.

## 4. 等号与量词次序的应用

对应课件第 19—21 页. 这些例子展示如何把新参数框、见证框和命题规则组合起来.

### 4.1 函数对等号保持一致

要证无前提定理：

$$
\vdash\forall x\forall y(x=y\to f(x)=f(y)).
$$

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 任意参数 $a,b$；假设框 | $a=b$ | 假设 |
| 2 | 同上 | $f(a)=f(a)$ | $=i$ |
| 3 | 同上 | $f(a)=f(b)$ | $=e$，1、2，模板 $f(a)=f(u)$ |
| 4 | 任意参数 $a,b$ | $a=b\to f(a)=f(b)$ | $\to i$，1—3 |
| 5 | 全局 | $\forall x\forall y(x=y\to f(x)=f(y))$ | 两次 $\forall i$ |

等号消去不是使用一个额外的“函数同余公理”. 第 3 行直接来自等号规则：在公式模板 $f(a)=f(u)$ 中，把等指项 $a$ 替换为 $b$. 因而函数保持等号是该自然演绎等号规则的导出性质.

### 4.2 两个存在量词可以交换

要证：

$$
\exists x\exists yF(x,y)\vdash\exists y\exists xF(x,y).
$$

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\exists x\exists yF(x,y)$ | 前提 |
| 2 | 见证 $a$ | $\exists yF(a,y)$ | $\exists e$ 的局部假设 |
| 3 | 嵌套见证 $b$ | $F(a,b)$ | $\exists e$ 的局部假设 |
| 4 | 嵌套见证 $b$ | $\exists xF(x,b)$ | $\exists i$，3 |
| 5 | 嵌套见证 $b$ | $\exists y\exists xF(x,y)$ | $\exists i$，4 |
| 6 | 见证 $a$ | $\exists y\exists xF(x,y)$ | $\exists e$，2、3—5 |
| 7 | 全局 | $\exists y\exists xF(x,y)$ | $\exists e$，1、2—6 |

两个见证框必须按后开先关的顺序嵌套. 第 5 行先把 $a,b$ 都隐藏到量词后面，结论不再含局部名字，才可依次关闭两个存在消去框.

### 4.3 从统一见证到逐点见证

课件证明：

$$
\exists y\forall xF(x,y)\vdash\forall x\exists yF(x,y).
$$

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\exists y\forall xF(x,y)$ | 前提 |
| 2 | 见证 $b$ | $\forall xF(x,b)$ | $\exists e$ 的局部假设 |
| 3 | 见证 $b$ 内的任意参数 $a$ | $F(a,b)$ | $\forall e$，2 |
| 4 | 同上 | $\exists yF(a,y)$ | $\exists i$，3 |
| 5 | 见证 $b$ | $\forall x\exists yF(x,y)$ | $\forall i$，3—4 |
| 6 | 全局 | $\forall x\exists yF(x,y)$ | $\exists e$，1、2—5 |

前提提供一个对所有 $x$ 都有效的统一见证 $b$. 固定任意 $a$ 后，同一个 $b$ 当然可以作为关于该 $a$ 的存在见证，所以可得到逐点存在结论.

### 4.4 逆方向不成立的反模型

> [!example] 补充反模型
> 逆方向 $\forall x\exists yF(x,y)\models\exists y\forall xF(x,y)$ 不成立. 取论域 $D=\{0,1\}$，令 $F(x,y)$ 当且仅当 $x=y$. 对每个 $x$，选择 $y=x$，所以 $\forall x\exists yF(x,y)$ 为真. 但不存在同一个 $y$ 同时等于 $0$ 和 $1$，所以 $\exists y\forall xF(x,y)$ 为假.

这说明异类量词一般不能交换. $\exists y\forall x$ 要求先选定一个统一见证；$\forall x\exists y$ 允许见证依赖于 $x$. 两者的信息强度不同.

## 5. 量词等值律的结构

对应课件第 22 页. 课件要求用自然演绎证明以下等值. 本节先说明每组等值的条件和证明结构，第 6 节展开课件第 23—30 页给出的代表性推导.

### 5.1 量词否定与同类量词交换

在经典一阶逻辑中：

$$
\neg\forall xA\equiv\exists x\neg A,
\qquad
\neg\exists xA\equiv\forall x\neg A.
$$

从右向左的证明通常直接使用 $\forall e$ 或 $\exists e$ 制造矛盾；从左向右需要反证法或双重否定消去，因此依赖经典逻辑. 在直觉主义逻辑中，$\exists x\neg A\vdash\neg\forall xA$ 仍成立，但 $\neg\forall xA\vdash\exists x\neg A$ 一般不可推出.

同类量词可交换：

$$
\forall x\forall yA\equiv\forall y\forall xA,
\qquad
\exists x\exists yA\equiv\exists y\exists xA.
$$

全称情形连续取两个任意参数，再按相反顺序全称引入；存在情形连续打开两个见证框，再按相反顺序存在引入. 第 4.2 节已经给出存在方向的一半，交换变量名即可得到反向.

### 5.2 量词与合取、析取的分配

无须附加自由变量条件的两组等值是：

$$
\forall xA\land\forall xB\equiv\forall x(A\land B),
$$

$$
\exists xA\lor\exists xB\equiv\exists x(A\lor B).
$$

第一组中，全称前提允许对同一个任意参数分别实例化，再合取；反向则对全称合取实例化后分别取出两个分量. 第二组中，前向按析取分支分别打开存在见证；反向先打开一个满足析取式的见证，再对见证处的析取作分支讨论.

不要把它们误写为 $\exists xA\land\exists xB\equiv\exists x(A\land B)$ 或 $\forall xA\lor\forall xB\equiv\forall x(A\lor B)$. 左侧的两个量词可以选择不同对象或不同真值分支，通常不足以推出右侧的统一选择.

### 5.3 变量无关时的量词外提

若 $x$ 不自由出现在 $B$ 中，则对 $Q\in\{\forall,\exists\}$ 和 $\circ\in\{\land,\lor\}$，有

$$
(QxA)\circ B\equiv Qx(A\circ B).
$$

条件 $x\notin\operatorname{FV}(B)$ 保证在任意参数框或见证框中，$B$ 的真值不依赖临时参数. 例如 $\forall xA\land B\vdash\forall x(A\land B)$ 时，$B$ 可直接带入任意参数框；反向从 $\forall x(A\land B)$ 得到 $B$ 时，还使用了一阶逻辑论域非空这一约定，以便任选一个对象进行全称实例化.

### 5.4 蕴含中的量词对偶

若 $x$ 不自由出现在 $B$ 中，则量词位于蕴含前件时发生对偶：

$$
Qx(A\to B)\equiv \overline QxA\to B,
$$

其中 $\overline\forall=\exists$，$\overline\exists=\forall$. 两个具体形式是

$$
\forall x(A\to B)\equiv(\exists xA\to B),
$$

$$
\exists x(A\to B)\equiv(\forall xA\to B).
$$

量词位于蕴含后件时保持类型：

$$
Qx(B\to A)\equiv(B\to QxA).
$$

前件位置出现对偶，源于 $A\to B$ 在经典逻辑中等值于 $\neg A\lor B$，量词跨过否定时发生 $\forall/\exists$ 对换；后件位置没有穿过否定，所以量词类型保持. 这只是结构解释，正式作业若要求自然演绎，仍需按规则构造推导.

## 6. 例题：量词等值律的自然演绎证明

对应课件第 23—30 页. 下列推导中的 $a,b$ 均为满足相应新鲜性条件的新参数.

### 6.1 存在量词对析取的分配

**方向一**：$\exists xA\lor\exists xB\vdash\exists x(A\lor B)$.

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\exists xA\lor\exists xB$ | 前提 |
| 2 | 左析取分支 | $\exists xA$ | 假设 |
| 3 | 左分支见证 $a$ | $A[a/x]$ | $\exists e$ 的局部假设 |
| 4 | 左分支见证 $a$ | $A[a/x]\lor B[a/x]$ | $\lor i$，3 |
| 5 | 左分支见证 $a$ | $(A\lor B)[a/x]$ | 代入的结构定义 |
| 6 | 左析取分支 | $\exists x(A\lor B)$ | $\exists i$，5，并关闭见证框 |
| 7 | 右析取分支 | $\exists xB$ | 假设 |
| 8 | 右分支见证 $b$ | $B[b/x]$ | $\exists e$ 的局部假设 |
| 9 | 右分支见证 $b$ | $A[b/x]\lor B[b/x]$ | $\lor i$，8 |
| 10 | 右分支见证 $b$ | $(A\lor B)[b/x]$ | 代入的结构定义 |
| 11 | 右析取分支 | $\exists x(A\lor B)$ | $\exists i$，10，并关闭见证框 |
| 12 | 全局 | $\exists x(A\lor B)$ | $\lor e$，1、2—6、7—11 |

课件在两个平行分支中都写 $x_0$. 由于两个见证框的作用域互不重叠，这样写合法；本文改用 $a,b$，更清楚地显示二者不是同一个已知对象.

**方向二**：$\exists x(A\lor B)\vdash\exists xA\lor\exists xB$.

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\exists x(A\lor B)$ | 前提 |
| 2 | 见证 $a$ | $(A\lor B)[a/x]$ | $\exists e$ 的局部假设 |
| 3 | 见证 $a$ | $A[a/x]\lor B[a/x]$ | 代入的结构定义 |
| 4 | 左析取分支 | $A[a/x]$ | 假设 |
| 5 | 左析取分支 | $\exists xA$ | $\exists i$，4 |
| 6 | 左析取分支 | $\exists xA\lor\exists xB$ | $\lor i$，5 |
| 7 | 右析取分支 | $B[a/x]$ | 假设 |
| 8 | 右析取分支 | $\exists xB$ | $\exists i$，7 |
| 9 | 右析取分支 | $\exists xA\lor\exists xB$ | $\lor i$，8 |
| 10 | 见证 $a$ | $\exists xA\lor\exists xB$ | $\lor e$，3、4—6、7—9 |
| 11 | 全局 | $\exists xA\lor\exists xB$ | $\exists e$，1、2—10 |

第 10 行已经不含见证名 $a$，所以可以合法关闭存在消去框.

### 6.2 否定全称与存在反例

**方向一**：$\neg\forall xA\vdash\exists x\neg A$. 这一方向使用经典反证法.

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\neg\forall xA$ | 前提 |
| 2 | 反证框 | $\neg\exists x\neg A$ | 假设 |
| 3 | 反证框内任意参数 $a$ | $a$ 为新参数 | 开任意参数框 |
| 4 | 嵌套反证框 | $\neg A[a/x]$ | 假设 |
| 5 | 嵌套反证框 | $\exists x\neg A$ | $\exists i$，4 |
| 6 | 嵌套反证框 | $\bot$ | $\neg e$，5、2 |
| 7 | 任意参数 $a$ | $A[a/x]$ | PBC，4—6 |
| 8 | 反证框 | $\forall xA$ | $\forall i$，3—7 |
| 9 | 反证框 | $\bot$ | $\neg e$，8、1 |
| 10 | 全局 | $\exists x\neg A$ | PBC，2—9 |

第 7 行不是从语义直觉“没有反例所以都成立”直接跳得，而是先对任意参数 $a$ 假设 $\neg A[a/x]$，把它概括成被第 2 行禁止的存在反例，再用 PBC 得到 $A[a/x]$.

**方向二**：$\exists x\neg A\vdash\neg\forall xA$.

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\exists x\neg A$ | 前提 |
| 2 | 否定引入框 | $\forall xA$ | 假设 |
| 3 | 见证 $a$ | $\neg A[a/x]$ | $\exists e$ 的局部假设 |
| 4 | 见证 $a$ | $A[a/x]$ | $\forall e$，2 |
| 5 | 见证 $a$ | $\bot$ | $\neg e$，4、3 |
| 6 | 否定引入框 | $\bot$ | $\exists e$，1、3—5 |
| 7 | 全局 | $\neg\forall xA$ | $\neg i$，2—6 |

这一方向只用否定引入，不依赖 PBC. 对偶等值 $\neg\exists xA\equiv\forall x\neg A$ 可用相同结构证明：一个方向打开存在见证制造矛盾，另一个方向对任意参数证明否定.

### 6.3 从蕴含前件移出量词

假设 $x$ 不自由出现在 $B$ 中. 课件证明：

$$
\forall x(A\to B)\equiv(\exists xA\to B).
$$

**方向一**：$\forall x(A\to B)\vdash\exists xA\to B$.

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\forall x(A\to B)$ | 前提 |
| 2 | 蕴含引入框 | $\exists xA$ | 假设 |
| 3 | 见证 $a$ | $A[a/x]$ | $\exists e$ 的局部假设 |
| 4 | 见证 $a$ | $A[a/x]\to B$ | $\forall e$，1；$x$ 不自由出现在 $B$ 中 |
| 5 | 见证 $a$ | $B$ | $\to e$，4、3 |
| 6 | 蕴含引入框 | $B$ | $\exists e$，2、3—5 |
| 7 | 全局 | $\exists xA\to B$ | $\to i$，2—6 |

**方向二**：$\exists xA\to B\vdash\forall x(A\to B)$.

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\exists xA\to B$ | 前提 |
| 2 | 任意参数 $a$ 内的假设框 | $A[a/x]$ | 假设 |
| 3 | 同上 | $\exists xA$ | $\exists i$，2 |
| 4 | 同上 | $B$ | $\to e$，1、3 |
| 5 | 任意参数 $a$ | $A[a/x]\to B$ | $\to i$，2—4 |
| 6 | 全局 | $\forall x(A\to B)$ | $\forall i$，2—5 |

条件 $x\notin\operatorname{FV}(B)$ 同时保证第 4 行的实例确为 $A[a/x]\to B$，并保证最终结论满足参数新鲜性. 若 $B$ 含自由 $x$，右侧把哪个 $x$ 绑定、哪个仍自由会发生变化，等值一般失效.

### 6.4 全称量词对合取的分配

**方向一**：$\forall xA\land\forall xB\vdash\forall x(A\land B)$.

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\forall xA\land\forall xB$ | 前提 |
| 2 | 全局 | $\forall xA$ | $\land e$，1 |
| 3 | 全局 | $\forall xB$ | $\land e$，1 |
| 4 | 任意参数 $a$ | $A[a/x]$ | $\forall e$，2 |
| 5 | 任意参数 $a$ | $B[a/x]$ | $\forall e$，3 |
| 6 | 任意参数 $a$ | $A[a/x]\land B[a/x]$ | $\land i$，4、5 |
| 7 | 任意参数 $a$ | $(A\land B)[a/x]$ | 代入的结构定义 |
| 8 | 全局 | $\forall x(A\land B)$ | $\forall i$，4—7 |

课件第 29 页证明的是特殊情形 $\forall xA\land B\vdash\forall x(A\land B)$，其中假设 $x$ 不自由出现在 $B$ 中. 此时第 5 行直接复用全局公式 $B$，并用 $B[a/x]=B$ 将第 6 行识别为 $(A\land B)[a/x]$. 上表给出课件第 22 页一般分配律的完整形式.

**方向二**：$\forall x(A\land B)\vdash\forall xA\land\forall xB$.

| 行号 | 作用域 | 公式 | 依据 |
|---|---|---|---|
| 1 | 全局 | $\forall x(A\land B)$ | 前提 |
| 2 | 任意参数 $a$ | $(A\land B)[a/x]$ | $\forall e$，1 |
| 3 | 任意参数 $a$ | $A[a/x]\land B[a/x]$ | 代入的结构定义 |
| 4 | 任意参数 $a$ | $A[a/x]$ | $\land e$，3 |
| 5 | 全局 | $\forall xA$ | $\forall i$，2—4 |
| 6 | 新任意参数 $b$ | $(A\land B)[b/x]$ | $\forall e$，1 |
| 7 | 新任意参数 $b$ | $A[b/x]\land B[b/x]$ | 代入的结构定义 |
| 8 | 新任意参数 $b$ | $B[b/x]$ | $\land e$，7 |
| 9 | 全局 | $\forall xB$ | $\forall i$，6—8 |
| 10 | 全局 | $\forall xA\land\forall xB$ | $\land i$，5、9 |

课件第 30 页同样给出 $x$ 不自由出现在 $B$ 时的特殊形式 $\forall x(A\land B)\vdash\forall xA\land B$. 在那个证明中，从任意实例的合取直接取出 $B$ 并带出参数框合法，因为 $B$ 不含参数；一般形式则需另开一个任意参数框得到 $\forall xB$.

### 6.5 其余等值式的证明模式

课件第 22 页还列出若干未逐页展开的等值. 下表给出可复现的自然演绎路线，属于对课件题目的补充解析.

| 等值 | 正向证明主线 | 反向证明主线 |
|---|---|---|
| $\neg\exists xA\equiv\forall x\neg A$ | 任取 $a$，假设 $A[a/x]$，用 $\exists i$ 与前提矛盾，再 $\neg i,\forall i$ | 假设 $\exists xA$，开见证 $a$，由 $\forall e$ 得 $\neg A[a/x]$，制造矛盾后 $\neg i$ |
| $\forall x\forall yA\equiv\forall y\forall xA$ | 任取 $b,a$，依次两次 $\forall e$，再按 $a,b$ 的次序两次 $\forall i$ | 对称交换 $x,y$ |
| $\exists x\exists yA\equiv\exists y\exists xA$ | 嵌套打开见证 $a,b$，按相反顺序两次 $\exists i$，再依次关闭见证框 | 对称交换 $x,y$ |
| $(QxA)\circ B\equiv Qx(A\circ B)$ | 在任意参数或见证框中与不含 $x$ 的 $B$ 用 $\circ$ 的规则组合 | 从量化后的复合式实例化或取见证，再用 $\circ$ 的规则分解；析取情形用 $\lor e$ |
| $\exists x(A\to B)\equiv(\forall xA\to B)$ | 假设 $\forall xA$，打开蕴含式见证并用 $\forall e,\to e$ 得 $B$ | 经典反证：若没有满足 $A\to B$ 的对象，则每个对象都使 $A$ 真且 $B$ 假，与 $\forall xA\to B$ 矛盾 |
| $Qx(B\to A)\equiv(B\to QxA)$ | 对 $B$ 作假设，在量词框中使用原前提，最后引入 $Q$ | 取任意参数或存在见证，用 $B\to QxA$ 与 $B$ 得量化结论，再实例化或取见证 |

表中涉及析取、存在或 $\exists x(A\to B)$ 反向的某些路线依赖经典规则及论域非空. 写成逐行证明时，仍须分别检查新参数不出现在外部未解除假设、原模板和带出框的结论中.

## 7. 易错点速查

| 常见的错误说法 | 应当如何判断 |
|---|---|
| “规则看起来保真，所以整个系统自然可靠” | 先逐条证明局部规则可靠，再对证明行或证明树作归纳；嵌套方框必须连同活动假设处理 |
| “$\Gamma\vdash A$ 与 $\Gamma\models A$ 可以在证明中随时互换” | 可靠性只允许从 $\vdash$ 推到 $\models$；反向必须另有完备性定理 |
| “$\forall e$ 可以代入任意字符串” | 代入对象必须是合法项，并且在原公式中对该变量可自由代入，防止变量捕获 |
| “全称引入只要最后一行含参数即可” | 参数必须代表任意对象，不能出现在外部未解除假设或原模板中；含参数的额外假设要先解除 |
| “存在消去就是从 $\exists xA$ 得到 $A(a)$” | $A(a)$ 只是局部见证假设；只有不含见证名的结论才能通过 $\exists e$ 带出框 |
| “$\forall x\exists yF$ 与 $\exists y\forall xF$ 只是量词顺序不同” | 前者允许 $y$ 依赖 $x$，后者要求统一见证；用二元素等号模型即可反驳逆向后承 |
| “量词与所有联结词都按同一方向分配” | 无条件成立的是 $\forall$ 对 $\land$、$\exists$ 对 $\lor$；其余形式通常需要变量无关条件或根本不成立 |
| “$x$ 不自由出现在 $B$ 中只是书写方便” | 该条件保证 $B[a/x]=B$，并阻止临时参数进入外部结论，是量词外提和蕴含等值成立的实质条件 |
| “$\neg\forall xA\Rightarrow\exists x\neg A$ 不需要经典逻辑” | 该方向通常使用 PBC 或双重否定消去；直觉主义逻辑中一般不成立 |
| “证明中两个不同方框都写 $a$，所以它们是同一对象” | 参数身份由作用域决定；平行且互不重叠的框可复用名字，但实际书写最好换名以避免误读 |

## 8. 知识点速查

### 8.1 可靠性证明的依赖关系

| 要证明的结论 | 直接依赖 | 关键条件 |
|---|---|---|
| $\forall e$、$\exists i$ 可靠 | 代入定理、量词语义 | 项可自由代入 |
| $=e$ 可靠 | 等号恒等解释、代入定理 | 两侧实例均合法 |
| $\forall i$ 可靠 | 赋值一致性、代入定理 | 参数不在外部前提和原公式中 |
| $\exists e$ 可靠 | 存在语义、赋值一致性、代入定理 | 参数不在外部前提、原公式和结论中 |
| 带方框命题规则可靠 | 联结词语义 | 正确记录与解除局部假设 |
| 整个系统可靠 | 每条规则可靠、对证明结构归纳 | 每行引用与作用域合法 |

可靠性主线可以概括为：语法代入由代入定理转成赋值更新；新鲜性条件控制临时赋值的引入与删除；逐行归纳把局部保真串成全局保真.

### 8.2 量词推导检查表

| 检查对象 | 执行问题 |
|---|---|
| 代入 | 替换的是否只是自由出现？项中变量是否会被外层量词捕获？ |
| $\forall i$ | 参数是否真正任意？是否出现在任何外部未解除假设或原模板中？ |
| $\exists e$ | 见证假设是否仍在局部框内？最终结论是否完全不含见证名？ |
| 嵌套方框 | 是否按后开先关关闭？关框后是否引用了已经失效的局部行？ |
| 量词换序 | 两个量词是否同类？若异类，是否错误地把依赖见证当成统一见证？ |
| 量词外提 | 被移过的公式是否含被量化变量的自由出现？ |
| 经典性 | 是否使用了 PBC、排中律或双重否定消去？若是，应标明结论属于经典系统 |
| 元语言层次 | 当前是在证明语义后承，还是在构造形式推导？是否未经完备性就从前者跳到后者？ |

**五句话总结**：

1. 代入定理把公式实例的真值还原为原公式在更新赋值下的真值.
2. 不带方框的规则逐点保真，带方框的规则还必须正确消除局部假设或临时参数.
3. 对证明结构作归纳，可由全部局部规则可靠推出 $\Gamma\vdash D\Rightarrow\Gamma\models D$.
4. 同类量词可以交换，异类量词一般不能交换；存在—全称比全称—存在要求更强的统一见证.
5. 量词等值式的形式证明依赖严格的作用域与自由变量检查，不能只凭熟悉的语义等值跳步.

> [!info]- 材料范围、补充内容与页面覆盖
> | PDF 物理页 | 课件内容 | 笔记位置 |
> |---|---|---|
> | 1—2 | 标题与内容提要 | 本章定位、材料说明 |
> | 3 | 自由代入与代入定理 | 1.1 |
> | 4—6 | 命题、等号和量词自然演绎规则 | 1.2 |
> | 7 | 可靠性与完备性定理 | 3.1、3.4 |
> | 8—9 | 两个量词推导例子 | 1.3 |
> | 10 | 第二部分提要 | 2 节导言 |
> | 11—13 | 不带方框规则及 $\forall e,\exists i$ 可靠性 | 2.1—2.2 |
> | 14—15 | 带方框规则的可靠性命题 | 2.3—2.5 |
> | 16—17 | 两段证明的逐行可靠性说明 | 3.2—3.3 |
> | 18 | 第三部分提要 | 4—6 节导言 |
> | 19 | 函数保持等号 | 4.1 |
> | 20 | 两个存在量词交换 | 4.2 |
> | 21 | $\exists y\forall xF\vdash\forall x\exists yF$ | 4.3—4.4 |
> | 22 | 待证量词等值式总表 | 5.1—5.4 |
> | 23—24 | $\exists$ 对 $\lor$ 的双向分配 | 6.1 |
> | 25—26 | $\neg\forall xA\equiv\exists x\neg A$ | 6.2 |
> | 27—28 | $\forall x(A\to B)\equiv(\exists xA\to B)$ | 6.3 |
> | 29—30 | $x$ 不自由出现时 $\forall$ 与 $\land$ 的外提 | 6.4 |
>
> **补充内容**：第 2.2 节补全 $=i,=e$ 的可靠性证明；第 3.1 节给出从局部规则到系统可靠性的强归纳框架；第 4.4 节给出异类量词逆向失败的反模型；第 6.4 节将课件特殊形式推广到第 22 页列出的一般分配律；第 6.5 节给出课件未逐页展开等值式的证明路线. 这些内容均不冒充课件原有证明.
