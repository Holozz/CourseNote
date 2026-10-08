---
tags: [机器学习, 数据挖掘, 神经网络, 深度学习, 反向传播, CNN, RNN, Transformer, GNN, 中山大学]
课程: 机器学习与数据挖掘
讲次: Lecture 7
主题: 神经网络
日期: 2026-11-03
status: complete
---

# 神经网络（Neural Networks）

> [!info] 本讲导读
> 回顾一下我们走过的路：
> - [[Ch2 线性回归|Ch2/Ch3]]：线性模型 $f(\boldsymbol{x})=\boldsymbol{w}^{\mathsf T}\boldsymbol{x}$——**简单但表达力有限**；
> - [[Ch4 线性回归与分类的概率视角|Ch4]]：从概率角度解释了损失函数的来源；
> - [[Ch5 模型的非线性化、过拟合及正则化|Ch5]]：引入**基函数** $\boldsymbol{\phi}(\boldsymbol{x})$——**表达力提升了，但 $\phi$ 是人设计的、固定的**；
> - [[Ch6 支持向量机|Ch6 SVM]]：用核技巧隐式定义 $\phi$——**不用显式构造，但核函数仍然是人选的**。
>
> **本讲要回答的问题**：能不能让 $\boldsymbol{\phi}(\boldsymbol{x})$ **自己从数据中学出来**？
>
> 这正是**神经网络**的全部意义：
> $$\boldsymbol{h}^{(1)} = a\bigl(\boldsymbol{W}_1\boldsymbol{x}\bigr),\qquad \boldsymbol{h}^{(2)} = a\bigl(\boldsymbol{W}_2\boldsymbol{h}^{(1)}\bigr),\qquad \hat{y} = \boldsymbol{W}_L\boldsymbol{h}^{(L-1)}$$
> 其中 $\boldsymbol{W}_\ell$ 是**可学习的参数**，$a(\cdot)$ 是**激活函数**。
>
> **一句话**：**深度学习 = 让特征工程本身也成为学习的一部分。**

## 目录

- [[#一、为什么需要神经网络|一、为什么需要神经网络]]
- [[#二、单层感知机与多层前馈神经网络|二、单层感知机与多层前馈神经网络]]
- [[#三、激活函数：为什么需要非线性|三、激活函数：为什么需要非线性]]
- [[#四、损失函数|四、损失函数]]
- [[#五、反向传播（Backpropagation）|五、反向传播（Backpropagation）]]
- [[#六、卷积神经网络（CNN）|六、卷积神经网络（CNN）]]
- [[#七、循环神经网络（RNN）|七、循环神经网络（RNN）]]
- [[#八、Transformer 与自注意力机制|八、Transformer 与自注意力机制]]
- [[#九、图神经网络（GNN）|九、图神经网络（GNN）]]
- [[#十、重点·难点·易错点汇总|十、重点·难点·易错点汇总]]
- [[#十一、知识点速查|十一、知识点速查]]
- [[#十二、本讲小结|十二、本讲小结]]

---

## 一、为什么需要神经网络

### 1.1 从大脑到层次化特征

课件用了一个思想实验引入：**"受人类大脑研究的启发，提出自底向上地对图像进行分层处理"**——像素→边缘→局部→对象。这不是"模拟大脑"（那太不严谨了），而是一个**层次化特征提取（hierarchical feature extraction）**的工程思想：低层特征（边缘、纹理）组合成中层特征（部件、形状），再组合成高层语义（"这是一只猫"）。

![[Ch7-img-vgg-net.png]]

> 上图是在 ImageNet 上训练的卷积网络各层的特征可视化。低层学的是"边缘"，中层学的是"纹理和部件"，高层学的是"整个对象"——这正是"层次化"的体现。

### 1.2 基函数的局限

[[Ch5 模型的非线性化、过拟合及正则化|Ch5]] 引入了基函数 $\boldsymbol{\phi}(\boldsymbol{x})$（多项式、高斯基、sigmoid 基等），[[Ch6 支持向量机|Ch6]] 用核技巧隐式定义了无限维 $\phi$。但它们有同一个问题：

> **基函数都是固定的，不能根据数据的特性进行自适应调整。**

举例：如果用高斯基 $\phi_k(\boldsymbol{x})=\exp\bigl(-\frac{\|\boldsymbol{x}-\boldsymbol{\mu}_k\|^2}{2s^2}\bigr)$，那么 $\boldsymbol{\mu}_k$ 和 $s$ **是谁选的？** 通常需要人为设定或用聚类初始化。如果数据的真实结构是"在 $(1,2)$ 附近有一个环形区域是类别 1"，但你的高斯基中心 $\boldsymbol{\mu}_k$ 恰好都落在别处——那再多的基函数也表达不好。

> [!important] 神经网络的核心贡献
> **把基函数 $\phi$ 的参数（位置、宽度、混合方式）也变成可学习的**，通过反向传播从数据中自动优化。这解决了"人设计特征"这一瓶颈，让模型的表达能力完全由数据决定。

### 1.3 让基函数变得可学：从 $\phi(\boldsymbol{x})$ 到 $a(\boldsymbol{W}\boldsymbol{x})$

课件用了三层图示说明这个"升级"（参见 [[Ch7-img-mlp-architecture.png]]）：

**原来的做法**（基函数模型）：

$$
\hat y = \boldsymbol{w}^{\mathsf T}\boldsymbol{\phi}(\boldsymbol{x}), \qquad \boldsymbol{\phi}(\boldsymbol{x}) = \bigl(\phi_1(\boldsymbol{x}),\dots,\phi_n(\boldsymbol{x})\bigr)
$$

$\phi_i$ 是**固定**的。

**现在的做法**（神经网络）：

$$
\hat y = \boldsymbol{w}_2^{\mathsf T}\,a(\boldsymbol{W}_1\boldsymbol{x}), \qquad \phi_i(\boldsymbol{x})=a(\boldsymbol{w}_{1,i}^{\mathsf T}\boldsymbol{x})
$$

$\phi_i$ 变成了 $a(\boldsymbol{w}_{1,i}^{\mathsf T}\boldsymbol{x})$，其中 $\boldsymbol{w}_{1,i}$ 是**可学习**的参数。

**关键差异**：原来的 $\phi_i(\boldsymbol{x})$ 是"人工设计的函数"（如 $x^2$、$e^{-x^2/2}$），现在的 $\phi_i(\boldsymbol{x})=a(\boldsymbol{w}_{1,i}^{\mathsf T}\boldsymbol{x})$ 是"以 $\boldsymbol{w}_{1,i}$ 为参数的可学习函数"——$\boldsymbol{w}_{1,i}$ 的每一个分量都可以调整，意味着**第 $i$ 个基函数可以自动学会关注输入的哪些维度、在什么位置激活**。

> [!tip] 与 [[Ch5 模型的非线性化、过拟合及正则化#1.2 思路一：分段线性 = 常数 + 一组 sigmoid 之和|Ch5 第 1.2 节]]的呼应
> Ch5 证明了"任意连续函数 ≈ 常数 + Σ 个 sigmoid($a_i x+b_i$)"。其中 $a_i,b_i$ 如果**固定**，需要人工选定；如果**可学**——就是神经网络了。所以**神经网络是 Ch5"分段线性逼近"思想的可学习版本**。

---

## 二、单层感知机与多层前馈神经网络

### 2.1 单层感知机（Single-Layer Perceptron）

最简单的神经网络：**没有隐藏层，直接把输入加权求和后过一个激活**。

$$
y = a\Bigl(\sum_{j=1}^{m}w_j x_j + b\Bigr) = a(\boldsymbol{w}^{\mathsf T}\boldsymbol{x}+b)
$$

若 $a$ 是符号函数 $\operatorname{sign}(\cdot)$，这就是 [[Ch3 线性分类器（Linear Classifiers）|逻辑回归]] 的前身——**感知机等价于线性分类器**。

**致命缺陷：解不了 XOR。**

![[Ch7-img-xor-problem.png]]

XOR 数据：

| $x_1$ | $x_2$ | $y$ |
|---|---|---|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

在 $(x_1,x_2)$ 平面上，标签 $+1$ 和 $-1$ 的点**交错排列**——任何一条直线都无法把它们分开。

> [!important] 为什么分不开？严格证明
> 反证：假设存在 $w_1,w_2,b$ 使所有点正确分类，即 $y=1\iff w_1x_1+w_2x_2+b\ge0$。
> - $(0,1)\to1$：$w_2+b\ge 0$ ①
> - $(1,0)\to1$：$w_1+b\ge 0$ ②
> - $(0,0)\to0$：$b<0$ ③
> - $(1,1)\to0$：$w_1+w_2+b<0$ ④
>
> 由 ①+②：$w_1+w_2+2b\ge0$，与 ④ 联立：$w_1+w_2+b<0$ 但 $w_1+w_2+2b\ge0$，得 $b>0$，与 ③ 矛盾。$\blacksquare$
>
> **根本原因**：单层感知机只能画直线（超平面），而 XOR 的数据布局需要**非线性边界**。

### 2.2 加一层：从"一条线"到"多条线组合"

**怎么解 XOR？** 用**两个隐藏神经元**加一个输出神经元。我给出一个显式构造：

$$
\text{隐藏层：}\ h_1=\operatorname{ReLU}(x_1+x_2),\quad h_2=\operatorname{ReLU}(x_1+x_2-1)
$$

$$
\text{输出：}\ y=h_1-2h_2
$$

逐样本验证：

| 输入 | $x_1+x_2$ | $h_1$ | $x_1+x_2-1$ | $h_2$ | $y=h_1-2h_2$ | 正确？ |
|---|---|---|---|---|---|---|
| $(0,0)$ | 0 | 0 | -1 | 0 | 0 | ✅ |
| $(1,0)$ | 1 | 1 | 0 | 0 | 1 | ✅ |
| $(0,1)$ | 1 | 1 | 0 | 0 | 1 | ✅ |
| $(1,1)$ | 2 | 2 | 1 | 1 | 0 | ✅ |

**原理**：$h_1$ 是"OR 门"（$x_1$ 或 $x_2$ 有一个为 1 就激活），$h_2$ 是"AND 门"（两个都为 1 才激活）。最终 $y=\text{OR}-2\times\text{AND}$ ——**用两个直线决策区域的组合，拼出了一个非线性区域**

> [!important] 加一层 = 增加"拼接能力"
> 单层感知机只能画一条直线；多层感知机可以**用多条直线的组合拼出任意形状的区域**——这就是为什么"加一层"就解决了 XOR。数学上，这正是 [[Ch5 模型的非线性化、过拟合及正则化#1.2 思路一：分段线性 = 常数 + 一组 sigmoid 之和|Ch5 第 1.2 节]]的"分段线性 = 常数 + Σ 个 sigmoid 之和"的直接实现。

### 2.3 多层前馈神经网络的一般结构

**L 层神经网络**的递归定义：

$$
\boldsymbol{h}^{(0)}=\boldsymbol{x}\quad\text{（输入层）}
$$

$$
\boldsymbol{h}^{\ell} = a\bigl(\boldsymbol{W}_\ell\,\boldsymbol{h}^{\ell-1}\bigr),\quad \ell=1,\dots,L-1\quad\text{（隐藏层）}
$$

$$
\hat y =
\begin{cases}
\boldsymbol{h}^{L} & \text{回归}\\[3pt]
\operatorname{softmax}(\boldsymbol{h}^{L}) & \text{分类}
\end{cases}
\quad\text{（输出层）}
$$

**为什么要写成递归？** 因为反向传播的核心就是**逐层回传梯度**——递归结构直接对应"前向计算 + 后向回传"的两步流程。

![[Ch7-img-nn-architecture.png]]

> [!warning] 一个关键事实：没有激活函数，多层退化为一层
> 若 $a(z)=z$（恒等），则：
> $$\hat y = \boldsymbol{W}_L(\boldsymbol{W}_{L-1}(\cdots(\boldsymbol{W}_1\boldsymbol{x})))=(\boldsymbol{W}_L\boldsymbol{W}_{L-1}\cdots\boldsymbol{W}_1)\boldsymbol{x}$$
> 多个矩阵连乘还是一个矩阵——所有层**坍缩**为一层！
> **所以激活函数的非线性是深度网络存在的根本原因**。没有它，堆再深的层也只是在做线性变换。

---

## 三、激活函数：为什么需要非线性

### 3.1 四种激活函数对比

![[Ch7-img-activation-functions.png]]

| 激活函数 | 公式 | 导数 | 输出范围 | 优点 | 缺点 |
|---|---|---|---|---|---|
| **Sigmoid** | $\sigma(z)=\frac{1}{1+e^{-z}}$ | $\sigma(1-\sigma)$ | $(0,1)$ | 输出可当概率 | 饱和时梯度消失；输出不以 0 为中心 |
| **Tanh** | $\frac{e^z-e^{-z}}{e^z+e^{-z}}$ | $1-\tanh^2(z)$ | $(-1,1)$ | 以 0 为中心 | 饱和时梯度消失（比 Sigmoid 稍好） |
| **ReLU** | $\max(0,z)$ | $1\ (z>0),\ 0\ (z\le0)$ | $[0,+\infty)$ | 正区间不饱和，计算简单 | 死亡神经元（$z<0$ 梯度=0） |
| **Leaky ReLU** | $\max(0.1z,z)$ | $1\ (z>0),\ 0.1\ (z\le0)$ | $(-\infty,+\infty)$ | 所有区间都有非零梯度 | 多一个超参数（0.1） |

### 3.2 为什么 Sigmoid/Tanh 会导致"梯度消失"

这个问题需要从**反向传播的结构**来理解。详细推导见 [[#五、反向传播（Backpropagation）|第五章]]，这里先给结论：

反向传播中，梯度从输出层往回传播时，**每经过一层都要乘以该层激活函数的导数**。对 Sigmoid：

$$
a'(z)=\sigma(z)\bigl(1-\sigma(z)\bigr)\le\frac{1}{4}
$$

$1/4$ 这个上界意味着：**每一层最多能把梯度缩小到原来的 $1/4$**。

对 $L$ 层网络：

$$
\left|\frac{\partial\mathcal{L}}{\partial\boldsymbol{W}_1}\right|\propto\prod_{\ell=1}^{L}\left|a'(\boldsymbol{z}^{\ell})\right|\le\left(\frac{1}{4}\right)^{L}
$$

**指数级衰减**：

| 层数 $L$ | $(1/4)^L$ | 梯度衰减 |
|---|---|---|
| 5 | 0.00098 | 千分之一 |
| 10 | $9.5\times10^{-7}$ | 百万分之一 |
| 20 | $9.1\times10^{-13}$ | 万亿分之一 |

> [!important] 后果：超过 5 层的 Sigmoid 网络基本不可训练
> 浅层（靠近输入的层）的梯度趋近于 0 $\Rightarrow$ 权重几乎不更新 $\Rightarrow$ 网络无法学到任何东西。
>
> **这就是"深度学习"在 Sigmoid 时代（2006 年以前）无法做深的根本原因**——不是不想深，是深了就"梯度消失"训练不动。

### 3.3 为什么 ReLU 能解决梯度消失

ReLU 的导数在 $z>0$ 时**恒等于 1**：

$$
\prod_{\ell=1}^{L}a'(\boldsymbol{z}^{\ell}) = 1\times 1\times\cdots\times 1 = 1
$$

**梯度不衰减**——这是 ReLU 让"深度"成为可能的根本原因。

**代价**：$z<0$ 时梯度为 0，该神经元**永久沉默**（"死亡神经元"）。但只要网络初始化得当且学习率合适，大部分神经元在大部分输入上都会激活（$z>0$），所以"死亡"只是少数。

> [!tip] 实践选择
> - **隐藏层默认用 ReLU**——最简单、最快、梯度不消失；
> - **输出层**用 Sigmoid（二分类概率）或 Softmax（多分类概率）；
> - **Sigmoid/Tanh 几乎不在隐藏层使用**——除非有特殊理由（如 LSTM 的门控）。

### 3.4 例题

> [!example]- 例 7.1：Sigmoid 梯度消失的数值演示
> 6 层 Sigmoid 网络，假设每层所有神经元的 $a'(z)$ 平均约为 0.2。
> 1. 梯度传到第 1 层时的衰减倍数？
> 2. 换成 ReLU（80% 激活），衰减倍数？
> 3. 结论？
>
> **解答：**
> 1. $0.2^6=0.000064$，即第 1 层梯度只有输出层的 **0.0064%**——基本为零。
> 2. $0.8^6=0.262$，第 1 层仍有 **26%** 的梯度信号。
> 3. **Sigmoid 网络超过 5 层就很难训练**；ReLU 可训练数百层（ResNet 就是 152 层）。

---

## 四、损失函数

神经网络的损失函数**与之前完全相同**——只是把 $\boldsymbol{w}$ 换成了多层参数 $\boldsymbol{\theta}=\{\boldsymbol{W}_1,\dots,\boldsymbol{W}_L\}$：

$$
\text{回归：}\ \mathcal{L}_r(\boldsymbol{\theta})=\frac{1}{N}\sum_i\bigl(y^{(i)}-\hat y(\boldsymbol{x}^{(i)})\bigr)^2
$$

$$
\text{分类：}\ \mathcal{L}_c(\boldsymbol{\theta})=-\frac{1}{N}\sum_i\sum_{k=1}^{K}y_k^{(i)}\log\hat y_k(\boldsymbol{x}^{(i)})
$$

这些正是 [[Ch4 线性回归与分类的概率视角|Ch4]] 从概率论推导的结果。神经网络没有发明新的损失函数，它只是**把特征学习也纳入了优化**。

---

## 五、反向传播（Backpropagation）

### 5.1 先直觉：为什么"从后往前"算梯度？

假设你有 3 层网络，要算 $\partial\mathcal{L}/\partial\boldsymbol{W}_1$。直接用定义（有限差分）算？**不行**——$\boldsymbol{W}_1$ 有几百万个参数，每个都要"扰动一次"算一次前向传播，太慢。

**反向传播的洞察**：利用**链式法则**，从输出层开始**逐步回传**梯度，**每一步只需用到上一步已经算好的梯度**——避免了重复计算。

> [!important] 反向传播不是一种"算法"，它是链式法则的一种高效实现
> 你可以用"朴素链式法则"来算 $\partial\mathcal{L}/\partial\boldsymbol{W}_1$，但那需要从输出一直展开到输入，计算量是指数级的。反向传播通过**存储中间结果（前向传播）+ 复用（后向传播）**，把复杂度降到了**与前向传播相同的量级**——这是它的核心价值。

### 5.2 记号与递归表示

先把网络的计算明确化：

$$
\boldsymbol{z}^{\ell} = \boldsymbol{W}_\ell\boldsymbol{h}^{\ell-1}\quad\text{（线性变换）},\qquad \boldsymbol{h}^{\ell}=a(\boldsymbol{z}^{\ell})\quad\text{（激活）}
$$

输出：$y=\boldsymbol{h}^L$（回归）或 $y=\operatorname{softmax}(\boldsymbol{h}^L)$（分类）。

要算的量是：$\dfrac{\partial\mathcal{L}}{\partial\boldsymbol{W}_\ell}$，对每一层 $\ell$。

### 5.3 第一步：输出层的梯度（"种子"）

这一步是反向传播的**起点**，取决于损失函数和输出激活。

**回归**（$\mathcal{L}=\frac12\|\boldsymbol{y}-\boldsymbol{h}^L\|^2$，输出层激活为恒等）：

$$
\frac{\partial\mathcal{L}}{\partial\boldsymbol{h}^L}=\boldsymbol{h}^L-\boldsymbol{y}
$$

**二分类**（$\mathcal{L}=-y\log\sigma(z^L)-(1-y)\log(1-\sigma(z^L))$，输出层为 Sigmoid）：

$$
\frac{\partial\mathcal{L}}{\partial z^L}=\sigma(z^L)-y
$$

**关键观察**：两种情况的梯度形式都是**"预测 − 真值"**——与 [[Ch3 线性分类器（Linear Classifiers）|Ch3]] 和 [[Ch4 线性回归与分类的概率视角|Ch4]] 完全一致。这不是巧合，而是因为**损失函数就是从这些分布的负对数似然推导出来的**。

### 5.4 核心：从后一层"传"到前一层

假设已经知道了 $\partial\mathcal{L}/\partial\boldsymbol{h}^{\ell+1}$（上一层的梯度），怎么算 $\partial\mathcal{L}/\partial\boldsymbol{h}^{\ell}$？

**链式法则**：

$$
\frac{\partial\mathcal{L}}{\partial h^{\ell,i}}=\sum_{j=1}^{n_{\ell+1}}\frac{\partial\mathcal{L}}{\partial h^{\ell+1,j}}\cdot\frac{\partial h^{\ell+1,j}}{\partial z^{\ell+1,j}}\cdot\frac{\partial z^{\ell+1,j}}{\partial h^{\ell,i}}
$$

其中：
- $\dfrac{\partial h^{\ell+1,j}}{\partial z^{\ell+1,j}}=a'(z^{\ell+1,j})$ —— **激活函数的导数**
- $\dfrac{\partial z^{\ell+1,j}}{\partial h^{\ell,i}}=W^{\ell+1}_{j,i}$ —— **连接权重**

写成向量形式（设 $\boldsymbol{g}^{\ell+1}=\bigl(a'(z^{\ell+1,1}),\dots,a'(z^{\ell+1,n_{\ell+1}})\bigr)^{\mathsf T}$）：

$$
\boxed{\ \frac{\partial\mathcal{L}}{\partial\boldsymbol{h}^{\ell}}=\boldsymbol{W}_{\ell+1}^{\mathsf T}\Bigl(\boldsymbol{g}^{\ell+1}\odot\frac{\partial\mathcal{L}}{\partial\boldsymbol{h}^{\ell+1}}\Bigr)\ }
$$

**这一步的物理意义**：$\partial\mathcal{L}/\partial\boldsymbol{h}^{\ell}$ 表示"第 $\ell$ 层输出变化一点点，损失会变多少"。答案是：**上一层的梯度 $\partial\mathcal{L}/\partial\boldsymbol{h}^{\ell+1}$，乘以激活函数导数 $a'$（过了这一关还能传多少），再乘以权重矩阵 $\boldsymbol{W}_{\ell+1}^{\mathsf T}$（通过哪条边传回来）**。

> [!important] 为什么说"乘以 $\boldsymbol{W}_{\ell+1}^{\mathsf T}$ 而不是 $\boldsymbol{W}_{\ell+1}$"
> 因为 $\boldsymbol{z}^{\ell+1}=\boldsymbol{W}_{\ell+1}\boldsymbol{h}^{\ell}$，所以 $\partial\boldsymbol{z}^{\ell+1}/\partial\boldsymbol{h}^{\ell}=\boldsymbol{W}_{\ell+1}$。但 $\partial\mathcal{L}/\partial\boldsymbol{h}^{\ell}$ 需要 $\boldsymbol{W}_{\ell+1}$ 的**转置**——这是因为链式法则中"内积换序"（$\frac{\partial\mathcal{L}}{\partial h^{\ell,i}}=\sum_j \frac{\partial\mathcal{L}}{\partial z^{j}}\cdot\frac{\partial z^{j}}{\partial h^{\ell,i}}=\sum_j g_j\cdot W_{j,i}$）。
> 这个"转置"是反向传播公式最容易记错的地方。

### 5.5 权重梯度

有了 $\partial\mathcal{L}/\partial\boldsymbol{h}^{\ell}$ 和 $\boldsymbol{g}^{\ell}$，权重梯度可以直接算：

$$
\boxed{\ \frac{\partial\mathcal{L}}{\partial\boldsymbol{W}_\ell}=\Bigl(\boldsymbol{g}^{\ell}\odot\frac{\partial\mathcal{L}}{\partial\boldsymbol{h}^{\ell}}\Bigr)\cdot(\boldsymbol{h}^{\ell-1})^{\mathsf T}\ }
$$

**展开看每一个元素**：

$$
\frac{\partial\mathcal{L}}{\partial W_\ell[i,j]}=\underbrace{\frac{\partial\mathcal{L}}{\partial h^{\ell,i}}}_{\text{损失对该神经元的梯度}}\times\underbrace{a'(z^{\ell,i})}_{\text{激活函数导数}}\times\underbrace{h^{\ell-1,j}}_{\text{前一层输出}}
$$

**三要素**：
1. **损失对该神经元的敏感度** $\partial\mathcal{L}/\partial h^{\ell,i}$ —— "这个神经元对损失有多大影响"
2. **激活函数的导数** $a'(z^{\ell,i})$ —— "这个神经元是否在活跃区（导数非零）"
3. **前一层的输出** $h^{\ell-1,j}$ —— "输入是什么，决定了更新方向"

> [!tip] 把这三要素记牢
> $$\frac{\partial\mathcal{L}}{\partial W_{\ell}[i,j]}=\text{（敏感度）}\times\text{（激活导数）}\times\text{（前一层输出）}$$
> 这个结构对**任意层**都成立——只是敏感度的计算需要"从后往前传"（这就是反向传播的全部）。

### 5.6 完整流程：前向 + 后向

```
前向传播（从输入到输出，存储中间结果）：
  h^0 = x
  for ℓ = 1 to L:
    z^ℓ = W_ℓ h^(ℓ-1)
    h^ℓ = a(z^ℓ)             ← 存储 h^(ℓ-1) 和 z^ℓ！
  loss = L(h^L, y)

反向传播（从输出到输入，复用梯度）：
  ∂L/∂h^L = 初始化（见 5.3 节）
  for ℓ = L downto 1:
    g^ℓ = a'(z^ℓ)
    ∂L/∂W_ℓ = (g^ℓ ⊙ ∂L/∂h^ℓ) · (h^(ℓ-1))ᵀ    ← 权重梯度
    ∂L/∂h^(ℓ-1) = W_ℓᵀ (g^ℓ ⊙ ∂L/∂h^ℓ)         ← 传给上一层

参数更新：
  for ℓ = 1 to L:
    W_ℓ ← W_ℓ - r · ∂L/∂W_ℓ
```

> [!important] 为什么需要存储前向结果
> **后向计算每一步都需要 $\boldsymbol{h}^{\ell-1}$**（在权重梯度公式里）。所以前向传播必须**把每层的输出存下来**，后向传播才能用。这就是"记忆化（memoization）"——用空间换时间。

### 5.7 例题：两层网络反向传播完整手算

> [!example]- 例 7.2：两层网络的反向传播（逐步推导，必做）
> 输入 $\boldsymbol{x}=(1,1)$，隐藏层 2 个神经元（Sigmoid 激活），输出 1 个神经元（Sigmoid + BCE，标签 $y=0$）。
> $\boldsymbol{W}_1=\begin{pmatrix}1&-1\\-1&1\end{pmatrix}$，$\boldsymbol{w}_2=(1,1)^{\mathsf T}$，偏置均为 0。
>
> **1. 前向传播**
>
> $\boldsymbol{z}^1=\boldsymbol{W}_1\boldsymbol{x}=\begin{pmatrix}1-1\\-1+1\end{pmatrix}=\begin{pmatrix}0\\0\end{pmatrix}$
>
> $\boldsymbol{h}^1=\sigma(0,0)=(0.5,\ 0.5)$
>
> $z^2=\boldsymbol{w}_2^{\mathsf T}\boldsymbol{h}^1=1\times0.5+1\times0.5=1$
>
> $\hat y=\sigma(1)=\frac{1}{1+e^{-1}}=0.7311$
>
> **2. 损失**
>
> $\mathcal{L}=-[0\times\log0.7311+1\times\log(1-0.7311)]=-\log(0.2689)=1.313$
>
> **3. 反向传播**
>
> 输出层梯度（"种子"）：
> $$\frac{\partial\mathcal{L}}{\partial z^2}=\hat y - y = 0.7311 - 0 = 0.7311$$
>
> $\boldsymbol{w}_2$ 的梯度：
> $$\frac{\partial\mathcal{L}}{\partial\boldsymbol{w}_2}=0.7311\times\boldsymbol{h}^1=0.7311\times(0.5,\ 0.5)=(0.3656,\ 0.3656)$$
>
> 传回隐藏层：
> $$\frac{\partial\mathcal{L}}{\partial\boldsymbol{h}^1}=\boldsymbol{w}_2\times0.7311=(1,1)\times0.7311=(0.7311,\ 0.7311)$$
>
> 隐藏层激活导数：$\boldsymbol{g}^1=\sigma(0)(1-\sigma(0))=(0.25,\ 0.25)$
>
> $\boldsymbol{W}_1$ 的梯度：
> $$\frac{\partial\mathcal{L}}{\partial W_1[i,j]}=\frac{\partial\mathcal{L}}{\partial h^1_i}\cdot g^1_i\cdot x_j=0.7311\times0.25\times x_j=0.1828\times x_j$$
> 由于 $x_1=x_2=1$，所有 4 个元素相同：
> $$\frac{\partial\mathcal{L}}{\partial\boldsymbol{W}_1}=\begin{pmatrix}0.1828&0.1828\\0.1828&0.1828\end{pmatrix}$$
>
> **4. 验证**：所有梯度为正 $\Rightarrow$ $\boldsymbol{W}_1$ 需要**减小**（沿负梯度方向），这会让 $\boldsymbol{z}^1$ 更负 $\Rightarrow$ $\hat y$ 更小 $\Rightarrow$ 损失下降 ✓

---

## 六、卷积神经网络（CNN）

### 6.1 为什么要发明 CNN？—— MLP 的参数量爆炸

**问题**：当输入是 $200\times200\times3$ 的图像，第一层有 32 个神经元时，MLP 第一层的参数量：

$$
200\times200\times3\times32 = 3{,}840{,}000
$$

> **模型参数过多导致**：① **训练成本非常高**；② **极其容易过拟合**（记住训练图像而不是学规律）。

**MLP 的根本问题**：全连接网络**从不考虑数据中的任何结构信息**。对 MLP 来说，"左上角的像素"和"右下角的像素"没有区别——它不知道"相邻像素"意味着什么。CNN 的设计思想是：**利用图像的局部性（相邻像素相关）和平移不变性（同一特征在不同位置都是同一个特征）**。

### 6.2 卷积操作

![[Ch7-img-convolution.png]]

**卷积的核心思想**：不是把每个输入神经元都连接到每个输出神经元，而是：

| 特性 | MLP（全连接） | CNN（卷积） |
|---|---|---|
| 连接方式 | 每个神经元连前层**所有**神经元 | **局部连接**：只连一个小区域（卷积核大小） |
| 参数 | 每个连接一组独立参数 | **参数共享**：所有位置用**同一组**参数 |

**效果**：假设卷积核 $5\times5$，输入 3 通道，输出 200 个特征图：

- MLP：$H\times W\times3\times200=H\times W\times600$ 个参数
- CNN：$5\times5\times3\times200=15{,}000$ 个参数

**差了好几个数量级。**

**卷积感受野**：输出特征图上的每个像素，对应原始输入中的一个区域。随着网络加深，感受野逐渐增大——浅层看"边缘"，深层看"整个对象"。

> **卷积核在"搜寻"什么？** 当图像区域与卷积核**匹配**时，输出值大。所以每个卷积核本质上是在**检测一种特定的模式**（锐化、边缘、纹理等），具体功能通过训练获得。

### 6.3 池化（Pooling）

**Max Pooling**：取局部区域的最大值。

作用：
- **平移不变性**：特征稍微移动，Max Pooling 的输出不变；
- **降维**：减小特征图尺寸，降低后续计算量；
- **增大感受野**：一个池化元素对应更大的原始区域。

### 6.4 经典 CNN 架构

![[Ch7-img-resnet.png]]

| 架构 | 年份 | 关键创新 |
|---|---|---|
| **LeNet** | 1989 | 第一个实用 CNN（手写数字识别），Conv-Pool-Conv-Pool-FC |
| **AlexNet** | 2012 | 深 CNN 赢得 ImageNet，ReLU、Dropout、GPU 训练 |
| **VGG** | 2014 | 全部用 $3\times3$ 卷积核堆叠——小核多层优于大核少层 |
| **ResNet** | 2015 | 跳跃连接（skip connection），152 层！ |

> [!important] ResNet 的跳跃连接：解决"更深反而更差"的问题
> $$\boldsymbol{h}^{\ell+1}=a\bigl(\boldsymbol{W}_{\ell+1}\boldsymbol{h}^{\ell}\bigr)+\boldsymbol{h}^{\ell}$$
> 为什么需要它？简单堆叠层会**梯度消失**（层太多，梯度传不回去）。跳跃连接让梯度能**直接流过**（不经过激活函数），相当于给梯度开了一条"高速公路"——所以 ResNet 能训练 152 层而不用怕梯度消失。

### 6.5 例题

> [!example]- 例 7.3：CNN 参数量与感受野计算
> 输入 $32\times32\times3$，第一层 16 个 $5\times5$ 卷积核，步长 1，padding=0。
> 1. 第一层参数量？
> 2. 输出特征图尺寸？
> 3. 每个输出像素的感受野？
> 4. 接 $2\times2$ Max Pooling（步长 2）后，尺寸和感受野各变为？
>
> **解答：**
> 1. 每个核：$5\times5\times3+1(\text{bias})=76$。16 个核：$76\times16=\mathbf{1{,}216}$。
>    对比 MLP：$32\times32\times3\times16=49{,}152$。**省了 40 倍。**
> 2. $(32-5)/1+1=28$。输出 $28\times28\times16$。
> 3. $5\times5$（直接对应原图的 $5\times5$ 区域）。
> 4. 池化后：$14\times14\times16$。感受野变为 $10\times10$（$2\times2$ 池化让感受野翻倍）。

---

## 七、循环神经网络（RNN）

### 7.1 处理序列数据的挑战

CNN 擅长图像（空间结构），但**序列数据**（文本、语音、时间序列）有独特的性质：

- **长度可变**：句子有长有短；
- **顺序重要**："我打了他"和"他打了我"字一样但意思相反；
- **上下文相关**：同一个词在不同语境中含义不同。

**MLP/CNN 无法自然处理这些特性**——需要一种能"记住过去"的模型。

### 7.2 RNN 的核心思想

**RNN 的本质**：用一个**递归方程**在每个时间步"记住"之前的信息：

$$
\boldsymbol{h}_t = \tanh\bigl(\boldsymbol{W}_{hh}\boldsymbol{h}_{t-1}+\boldsymbol{W}_{xh}\boldsymbol{x}_t\bigr),\qquad y_t=\boldsymbol{W}_{hy}\boldsymbol{h}_t
$$

**按时间展开**后，RNN 等价于一个"深度等于序列长度"的前馈网络——**但所有时间步共享同一组参数** $\boldsymbol{W}_{hh},\boldsymbol{W}_{xh},\boldsymbol{W}_{hy}$。

> [!important] 参数共享的两个后果
> 1. **参数量不随序列长度增长**——可以处理任意长的序列；
> 2. **同一参数在每个时间步都出现**——训练时梯度会跨时间步累加，这正是**梯度消失/爆炸**的根源。

### 7.3 RNN 的梯度消失

**核心公式**：

$$
\frac{\partial\boldsymbol{h}_T}{\partial\boldsymbol{h}_0}=\prod_{t=1}^{T}\operatorname{diag}\bigl(1-\boldsymbol{h}_t^2\bigr)\cdot\boldsymbol{W}_{hh}
$$

**梯度是 $T$ 个矩阵的连乘**——这与 CNN 的"梯度消失"本质相同：

- 若 $\boldsymbol{W}_{hh}$ 的谱范数 $<1$，梯度指数衰减 $\to 0$（**长程依赖消失**）
- 若 $>1$，梯度指数爆炸 $\to\infty$

**数值例子**：$T=100$，每步衰减 0.5，$\partial\boldsymbol{h}_{100}/\partial\boldsymbol{h}_0\approx0.5^{100}\approx10^{-31}$。

> [!important] LSTM 如何解决？
> LSTM 引入了**记忆单元** $\boldsymbol{c}_t$ 和三个**门**（遗忘门、输入门、输出门）：
> - **遗忘门 $\boldsymbol{f}_t=\sigma(\cdot)$**：控制"旧信息保留多少"。当 $\boldsymbol{f}_t\approx\boldsymbol{1}$ 时，$\boldsymbol{c}_t\approx\boldsymbol{c}_{t-1}$，梯度直接通过 $\boldsymbol{c}$ 传递（**不乘 $\boldsymbol{W}_{hh}$，只乘 $\boldsymbol{f}_t\approx 1$**）。
> - 这相当于给梯度开了一条"记忆高速公路"——长程依赖可以通过 $\boldsymbol{c}$ 传播，而不会被 $\tanh'$ 压缩。

---

## 八、Transformer 与自注意力机制

### 8.1 RNN 的两个根本问题

1. **串行执行**：$\boldsymbol{h}_t$ 必须等 $\boldsymbol{h}_{t-1}$ 算完，**无法并行**——GPU 利用率低。
2. **长程依赖困难**：即使有 LSTM，距离太远时信息仍然会被稀释。

**Transformer 的核心洞察**：用**自注意力（Self-Attention）**替代递归——**任意两个位置直接建立连接**，不依赖顺序

### 8.2 自注意力的 4 步

![[Ch7-img-attention-qkv.png]]

**（1）Query, Key, Value**：对输入序列 $\boldsymbol{X}\in\mathbb{R}^{n\times d}$，线性变换得到

$$
\boldsymbol{Q}=\boldsymbol{XW}_Q,\qquad\boldsymbol{K}=\boldsymbol{XW}_K,\qquad\boldsymbol{V}=\boldsymbol{XW}_V
$$

- $\boldsymbol{Q}$（查询）："我想找什么？"
- $\boldsymbol{K}$（键）："我能提供什么？"
- $\boldsymbol{V}$（值）："我实际的内容是什么？"

**（2）相似度**：

$$
\text{Attention}(\boldsymbol{Q},\boldsymbol{K},\boldsymbol{V})=\operatorname{softmax}\Bigl(\frac{\boldsymbol{QK}^{\mathsf T}}{\sqrt{d_k}}\Bigr)\boldsymbol{V}
$$

**为什么除以 $\sqrt{d_k}$？** $\boldsymbol{QK}^{\mathsf T}$ 的每个元素是 $d_k$ 个数的内积，方差为 $d_k$。不缩放的话值太大 $\Rightarrow$ softmax 饱和 $\Rightarrow$ 梯度消失。除以 $\sqrt{d_k}$ 把方差压回 $1$。

> [!important] 注意力与 RNN 的本质区别
> - RNN：$\boldsymbol{h}_t$ 只能通过 $\boldsymbol{h}_{t-1}$ 间接"看到" $\boldsymbol{h}_{t-100}$——**必须经过 100 步递归**。
> - Attention：$\boldsymbol{h}_t$ 可以直接**对 $\boldsymbol{h}_{t-100}$ 计算注意力权重**——**一步到位**。
>
> 这就是 Transformer 能捕获**长程依赖**的原因。

### 8.3 BERT vs GPT

| | BERT | GPT |
|---|---|---|
| 注意力方向 | **双向**（同时看左边和右边） | **单向**（只能看左边） |
| 训练任务 | 遮掩语言模型（MLM）：预测被遮住的词 | 自回归：预测下一个词 |
| 适合任务 | **理解类**（分类、问答、NER） | **生成类**（文本生成、对话） |

> [!tip] 为什么 GPT 用单向注意力？
> 生成文本时，必须**从左到右**逐词生成——不能"偷看"未来的词。所以 GPT 用掩码遮住右边，强制因果性。BERT 不需要生成，所以可以双向看。

---

## 九、图神经网络（GNN）

现实中的很多数据是**图结构**：社交网络（节点=人，边=关系）、分子（原子=节点，化学键=边）。GNN 的核心思想是**邻居聚合**：

$$
\boldsymbol{h}_v^{\ell+1}=\sigma\Bigl(\boldsymbol{W}_{\ell+1}\cdot\sum_{u\in\mathcal{N}(v)\cup v}\frac{\boldsymbol{h}_u^\ell}{\sqrt{|\mathcal{N}(u)||\mathcal{N}(v)|}}\Bigr)
$$

**直觉**：每个节点收集邻居的特征，通过神经网络变换，生成自己新的表示。叠多层后，每个节点能"看到"更远的邻居。

---

## 十、重点·难点·易错点汇总

> [!warning]+ 12 个关键点
> 1. **没有激活函数，多层退化为一层**——线性组合的线性组合还是线性组合。
> 2. **Sigmoid $a'\le 1/4$ 导致梯度消失**，$L$ 层后衰减 $\le(1/4)^L$。ReLU 在 $z>0$ 时 $a'=1$。
> 3. **ReLU 的死亡神经元**：$z<0$ 时梯度=0，该神经元永久沉默。Leaky ReLU 用 0.1 替代。
> 4. **反向传播 = 链式法则 + 记忆化**：前向存储 $\boldsymbol{h}^{\ell}$，后向复用 $\partial\mathcal{L}/\partial\boldsymbol{h}^{\ell+1}$。
> 5. **梯度公式三要素**：敏感度 × 激活导数 × 前一层输出。**转置**出现在回传公式中（$\boldsymbol{W}_{\ell+1}^{\mathsf T}$）——最容易记错的地方。
> 6. **CNN 的两个设计原则**：局部连接（利用空间局部性）+ 参数共享（平移不变性）→ 参数量从 $O(HWC\times K)$ 降到 $O(K^2C_{\text{in}}C_{\text{out}})$。
> 7. **小核堆叠优于大核**：3 层 $3\times3$ ≈ 1 层 $7\times7$ 的感受野，但参数少 45%，非线性更强。
> 8. **ResNet 跳跃连接**：$\boldsymbol{h}^{\ell+1}=a(\boldsymbol{W}_{\ell+1}\boldsymbol{h}^{\ell})+\boldsymbol{h}^{\ell}$，梯度直接流过，解决深网络训练困难。
> 9. **RNN 梯度消失**：$\prod_t \boldsymbol{W}_{hh}\cdot a'$，当 $\|\boldsymbol{W}_{hh}\|<1$ 时指数衰减。
> 10. **LSTM 的记忆单元**：梯度通过 $\boldsymbol{c}_t$ 直接传递（不经过 $\tanh'$），解决长程依赖。
> 11. **Transformer 的并行性**：自注意力矩阵乘法一次性计算所有位置，不依赖序列顺序。
> 12. **$\sqrt{d_k}$ 缩放**：防止 softmax 饱和。方差 $= d_k$ → 除以 $\sqrt{d_k}$ → 方差回到 1。

---

## 十一、知识点速查

### 核心公式

| 名称 | 公式 |
|---|---|
| 前馈网络 | $\boldsymbol{h}^{\ell}=a(\boldsymbol{W}_{\ell}\boldsymbol{h}^{\ell-1})$，$\boldsymbol{h}^{0}=\boldsymbol{x}$ |
| Sigmoid | $\sigma(z)=\frac{1}{1+e^{-z}}$，$\sigma'=\sigma(1-\sigma)\le\frac14$ |
| ReLU | $\max(0,z)$，ReLU'$=1\ (z>0),\ 0\ (z\le0)$ |
| MSE 损失 | $\mathcal{L}_r=\frac1N\sum(y-\hat y)^2$ |
| 交叉熵 | $\mathcal{L}_c=-\frac1N\sum\sum_k y_k\log\hat y_k$ |
| **反向传播递推** | $\frac{\partial\mathcal{L}}{\partial\boldsymbol{h}^{\ell}}=\boldsymbol{W}_{\ell+1}^{\mathsf T}\bigl(\boldsymbol{g}^{\ell+1}\odot\frac{\partial\mathcal{L}}{\partial\boldsymbol{h}^{\ell+1}}\bigr)$ |
| **权重梯度** | $\frac{\partial\mathcal{L}}{\partial\boldsymbol{W}_{\ell}}=\bigl(\boldsymbol{g}^{\ell}\odot\frac{\partial\mathcal{L}}{\partial\boldsymbol{h}^{\ell}}\bigr)(\boldsymbol{h}^{\ell-1})^{\mathsf T}$ |
| CNN 参数量 | $K\times K\times C_{\text{in}}\times C_{\text{out}}+C_{\text{out}}$ |
| RNN | $\boldsymbol{h}_t=\tanh(\boldsymbol{W}_{hh}\boldsymbol{h}_{t-1}+\boldsymbol{W}_{xh}\boldsymbol{x}_t)$ |
| 自注意力 | $\text{Attn}(\boldsymbol{Q},\boldsymbol{K},\boldsymbol{V})=\operatorname{softmax}\bigl(\frac{\boldsymbol{QK}^{\mathsf T}}{\sqrt{d_k}}\bigr)\boldsymbol{V}$ |
| ResNet | $\boldsymbol{h}^{\ell+1}=a(\boldsymbol{W}_{\ell+1}\boldsymbol{h}^{\ell})+\boldsymbol{h}^{\ell}$ |

### 概念对比

| | MLP | CNN | RNN | Transformer |
|---|---|---|---|---|
| 数据类型 | 向量 | 图像/空间 | 序列 | 序列 |
| 核心机制 | 全连接 | 卷积+池化 | 时间递归 | 自注意力 |
| 参数共享 | 否 | 空间 | 时间 | 位置 |
| 并行性 | ✅ | ✅ | ❌ | ✅ |
| 长程依赖 | ✅ | 受限于感受野 | ❌ | ✅ |

---

## 十二、本讲小结

1. **神经网络 = 可学习的特征映射**：把 [[Ch5 模型的非线性化、过拟合及正则化|Ch5]] 的"固定基函数"升级为"数据驱动的基函数"——这就是"深度学习 = 学习层次化表示"的全部意义。

2. **激活函数是深度的存在理由**：没有它，$L$ 层退化为 1 层；ReLU 解决了 Sigmoid 的梯度消失问题（$a'=1$ vs $a'\le 1/4$）。

3. **反向传播 = 链式法则 + 记忆化**：三要素（敏感度、激活导数、前一层输出）贯穿所有层。这个结构与 [[Ch3 线性分类器（Linear Classifiers）|Ch3]]/[[Ch4 线性回归与分类的概率视角|Ch4]] 的"误差 × 输入"梯度模式**完全一致**——神经网络只是多了"逐层回传"的步骤。

4. **CNN/RNN/Transformer 是针对特定数据结构的架构**：CNN 用局部连接+参数共享处理图像，RNN 用递归处理序列，Transformer 用自注意力替代递归实现并行。**训练算法（反向传播）是一样的，只是"计算图"的形状不同。**

5. **Loss 仍然是老朋友**：MSE（高斯假设）和交叉熵（伯努利/类别假设）——与 [[Ch4 线性回归与分类的概率视角|Ch4]] 完全一致。神经网络只换了特征学习的方式，损失函数的来源没有变。

---

## 关联笔记

- [[Ch5 模型的非线性化、过拟合及正则化]] —— 基函数、分段线性逼近（本讲的直接基础）
- [[Ch6 支持向量机]] —— 核方法（固定特征 vs 可学特征）
- [[Ch4 线性回归与分类的概率视角]] —— 损失函数的来源
- [[Ch3 线性分类器（Linear Classifiers）]] —— 逻辑回归、Sigmoid、反向传播中"误差 × 输入"的原型
- [[index]] —— 知识库索引
