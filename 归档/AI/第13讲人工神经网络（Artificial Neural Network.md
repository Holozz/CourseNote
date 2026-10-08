> 课程：人工智能（专业必修）| 第六章：机器学习 授课对象：计算机科学与技术专业 二年级
---

## 目录

- [[#一、前情回顾：机器学习概述]]
- [[#二、人工神经网络发展历史]]
- [[#三、生物神经元结构]]
- [[#四、人工神经元模型 MP]]
- [[#五、感知机模型（Perceptron）]]
- [[#六、多层感知机（MLP）]]
- [[#七、激活函数详解]]
- [[#八、训练：前向传播 + 反向传播]]
- [[#九、梯度消失问题与 ReLU]]
- [[#十、深度学习简介]]
- [[#十一、例题精讲]]

## 一、前情回顾：机器学习概述

机器学习的核心目标是：**通过数据自动学习一个函数 $f(x)$，完成从输入到输出的映射**。

$$\text{机器学习} \approx \text{机器自动找一个函数}$$

根据输出类型，机器学习任务分为三类：

|任务类型|输出|举例|
|---|---|---|
|回归（Regression）|一个数值|预测房价|
|分类（Classification）|一个类别|判断良恶性肿瘤|
|生成（Generation）|一段数据|生成图像、文本|

**关键问题**：如何设计函数结构（模型）和优化策略（训练方法）来更好地完成映射？

---

## 二、人工神经网络发展历史

```
1943年 → McCulloch & Pitts 提出 MP 神经元模型（神经网络起源）
1949年 → Hebb 发现突触强度可变 → Hebb 学习率 → 启发权值学习
1958年 → Rosenblatt 提出感知机（Perceptron）
1969年 → Minsky《Perceptron》书指出感知机无法解决 XOR → 神经网络冷冬
1986年 → Rumelhart & Hinton 提出反向传播算法（BP）→ 两层网络复苏
2006年 → Hinton 提出深度学习（Deep Learning）→ 神经网络大复苏
至今  → 深度学习统治 CV、NLP、语音识别等领域
```

> [!important] 历史规律 神经网络经历了两次寒冬与复苏。每次复苏都源于新算法/新硬件的突破，不是单靠更多数据或更大网络。

---

## 三、生物神经元结构

理解 ANN 之前，先理解**生物原型**。

人脑中约有 **1000 亿个神经元**，它们通过**突触**相互连接，形成高度复杂的并行网络。

### 神经元的组成（1904年已知）

- **树突（Dendrites）**：多个，负责**接收**其他神经元的信号
- **细胞体（Soma）**：对输入信号进行**积累和处理**
- **轴突（Axon）**：只有一条，负责**输出**信号
- **突触（Synapse）**：轴突末梢与其他神经元树突的连接点，**信号强度可变**（Hebb 发现）

### 信息传递过程

当某神经元接收的信号**累积超过阈值**，它会激活，经突触刺激下一个神经元，实现链式传播。

```
多个树突输入信号 → 细胞体积累 → 超过阈值 → 轴突输出 → 突触传递 → 下一个神经元
```

---

## 四、人工神经元模型 MP

> [!note] 核心概念 MP 模型（McCulloch-Pitts，1943）是人工神经网络的**最小单元**，用数学结构模拟生物神经元
### 结构类比

|生物神经元|MP 模型|
|---|---|
|树突（多个输入）|输入 $a_1, a_2, \ldots, a_n$|
|突触连接强度|权值 $w_1, w_2, \ldots, w_n$|
|细胞体（积累计算）|加权求和 $\sum w_i a_i$|
|激活阈值|激活函数 $g(\cdot)$|
|轴突（单个输出）|输出 $z$|

### 数学公式

$$z = g(\mathbf{W} \times \mathbf{a}) = g(a_1 w_1 + a_2 w_2 + \cdots + a_n w_n)$$

其中，MP 模型中的激活函数 $g$ 使用**符号函数（sgn）**：

$$\text{sgn}(x) = \begin{cases} 1 & x \geq 0 \ -1 & x < 0 \end{cases}$$

### 理解 MP 神经元（以肿瘤分类为例）

- **已知属性（特征）**：细胞大小 $a_1$、细胞形状 $a_2$、分化程度 $a_3$
- **未知属性（目标）**：恶性肿瘤 / 良性肿瘤 → 输出 $z$

> [!warning] MP 模型的根本缺陷 MP 模型中**权重是人工预先设置的**，不能通过数据自动学习！ 这是它无法实用的根本原因。

---

## 五、感知机模型（Perceptron）

### 从 MP 到感知机

Hebb 发现突触强度可变（1949），启发研究者开始用**调整权值**的方式让机器自学习。

**感知机（1958，Rosenblatt）** 在 MP 基础上引入了**可学习的权重**。

### 结构

感知机由**两层神经元**组成：

- **输入层**：不做计算，只负责传输数据
- **输出层**：进行加权求和 + 激活函数计算

$$\hat{y} = \text{sgn}(\mathbf{w} \times \mathbf{a})$$

### 感知机训练法则

感知机通过**迭代更新权值**来学习：

$$W_t \leftarrow W_t + \Delta W_t, \quad \Delta W_t = \eta (y - \hat{y}) \cdot \mathbf{a}$$

其中：
- $y$：真实标签
- $\hat{y}$：感知机当前预测值
- $\eta$：**学习率**（如 0.1），控制每次更新的幅度
- $\mathbf{a}$：当前训练样本

> [!tip] 学习率的理解 学习率 $\eta$ 太大→更新步子太大，容易"跨过"最优点来回震荡；太小→收敛太慢。这是神经网络调参的核心超参数之一。

### 感知机的几何含义

感知机本质上是在 $n$ 维空间中找一个**超平面**（决策边界）： $$w_1 a_1 + w_2 a_2 + \cdots + w_n a_n = 0$$

- 超平面一侧 → 输出 1（正类）
- 另一侧 → 输出 -1（负类）

**二维情况**：分界线是一条直线 $w_1 a_1 + w_2 a_2 = 0$

> [!warning] 感知机的致命缺陷：只能做线性分类 1969 年，Minsky 在《Perceptron》一书中用严格数学证明： **单层感知机无法解决 XOR（异或）问题。**
> 
> XOR 问题的四个点：(0,0)→0，(0,1)→1，(1,0)→1，(1,1)→0 在二维平面上，**没有任何一条直线能将这四点正确分类**。
> 
> 这直接导致了神经网络研究的第一次寒冬。

---

## 六、多层感知机（MLP）

### 多层感知机的提出

解决 XOR 问题的思路：**增加隐藏层（Hidden Layer）**。

1986 年，Rumelhart 和 Hinton 提出**反向传播算法（BP）**，解决了多层网络训练中的计算问题，掀起了两层神经网络的研究热潮。

### MLP 的结构

**多层感知机（Multi-Layer Perceptron，MLP）** 又叫**多层神经网络**，包含：

- **输入层（Input Layer）**：节点数 = 特征维度，不计算
- **隐藏层（Hidden Layer）**：1 个或多个，节点数可自由设定（超参数）
- **输出层（Output Layer）**：节点数 = 目标维度

```
输入层  →  隐藏层1  →  隐藏层2  →  ...  →  输出层
  x         h(1)        h(2)               y'
```

### 数学表达

不含偏置的 MLP（两个隐藏层）：

$$\mathbf{a} = g(\mathbf{W_1} \times \mathbf{x})$$ $$\mathbf{z} = g(\mathbf{W_2} \times \mathbf{a}) = g(\mathbf{W_2} \times g(\mathbf{W_1} \times \mathbf{x}))$$

含偏置（更完整的形式）：

$$\mathbf{a} = g_1(\mathbf{W_1} \times \mathbf{x} + \mathbf{b_1})$$ $$\mathbf{z} = g_2(\mathbf{W_2} \times \mathbf{a} + \mathbf{b_2})$$

> [!note] 偏置（Bias）的作用 偏置 $\mathbf{b}$ 类似线性方程中的截距，让决策边界不必过原点，提高模型的表达能力。 **没有偏置，网络的决策超平面必须过原点，大幅限制能力。**

### 为什么 MLP 能解决 XOR？

> [!important] 关键：隐藏层的空间变换 从输入层到隐藏层，激活函数对数据进行了**非线性空间扭曲**。 原本线性不可分的数据，经过隐藏层的变换，在新的特征空间中变得**线性可分**。 再由输出层做一次线性分类，就能完成非线性任务。

**一个重要问题**：如果 $g_1$ 是线性函数会怎样？

$$\mathbf{z} = g_2(\mathbf{W_2} \times (g_1(\mathbf{W_1} \times \mathbf{x}))) = g_2(\mathbf{W_2} \mathbf{W_1} \mathbf{x}) = g_2(\mathbf{W'} \mathbf{x})$$

多层线性变换**等价于一层线性变换**！加再多层也没用，堆叠没有意义。

**结论：非线性激活函数是多层神经网络能力的核心来源。**

### 通用近似定理（Universal Approximation Theorem）

> [!quote] 定理（Cybenko 1989, Hornik et al. 1989） 对于任意连续函数 $f(\mathbf{x})$，存在一个带有单隐藏层、足够多节点的神经网络，能以任意精度 $\epsilon > 0$ 逼近它： $$F(\mathbf{x}) = \sum_{i=1}^{m} \nu_i \varphi(\mathbf{W}_i^T \mathbf{x} + b_i), \quad |F(\mathbf{x}) - f(\mathbf{x})| < \epsilon$$

**通俗理解**：只要隐藏层神经元足够多，MLP 理论上可以拟合任何连续函数。这是神经网络万能近似能力的理论保证。

**本质**：神经网络通过**矩阵参数 $W$ 与激活函数 $g$** 来拟合特征与目标之间的真实函数关系。

### 隐藏层节点数的选择

输入/输出层节点数由任务决定；隐藏层节点数是**超参数**，通常：

- 根据经验设置
- 使用**网格搜索（Grid Search）**：预设几个候选值，交叉验证选最优

---

## 七、激活函数详解

> [!note] 为什么需要激活函数？ 没有激活函数，多层线性叠加等价于单层线性，无法拟合非线性函数。激活函数引入非线性，是神经网络表达复杂映射的关键。

### 四种常见激活函数对比

#### 1. sgn（符号函数）

$$\text{sgn}(x) = \begin{cases} 1 & x \geq 0 \ -1 & x < 0 \end{cases}$$

- 用途：MP 神经元、早期感知机
- 缺点：不可微，无法用梯度下降训练

#### 2. Sigmoid 函数

$$\sigma(x) = \frac{1}{1 + e^{-x}}$$

导数：

$$\frac{d\sigma}{dx} = \sigma(x)(1 - \sigma(x))$$

> [!warning] Sigmoid 的导数值域 $$0 \leq \sigma'(x) \leq 0.25$$ 导数最大只有 0.25！这意味着每反向传播一层，梯度至少衰减为 $\frac{1}{4}$。 **层数一多，梯度指数级衰减 → 梯度消失问题（Vanishing Gradient）。**

- 输出范围：$(0, 1)$，适合概率输出
- 用途：多层感知机（MLP）的隐藏层，二分类输出层

#### 3. tanh（双曲正切函数）

$$\tanh(x) = \frac{e^x - e^{-x}}{e^x + e^{-x}}$$

- 输出范围：$(-1, 1)$，以 0 为中心
- 导数最大值为 1，比 Sigmoid 梯度消失稍缓
- 用途：深层神经网络（DNN）

#### 4. ReLU（修正线性单元）

$$\text{ReLU}(x) = \max(0, x)$$

导数：

$$\frac{d\text{ReLU}}{dx} = \begin{cases} 0 & x \leq 0 \ 1 & x > 0 \end{cases}$$

> [!success] ReLU 的三大优势
> 
> 1. **不存在梯度消失**：正区间梯度恒为 1，不会衰减
> 2. **计算效率高**：仅需判断正负，无指数运算
> 3. **稀疏激活**：部分神经元输出为 0，减少参数依赖，缓解过拟合

- 用途：现代深层神经网络（DNN）的首选激活函数

### 激活函数使用建议（总结）

|激活函数|推荐场景|梯度消失风险|
|---|---|---|
|sgn|MP 神经元、感知机|不适用（不可微）|
|Sigmoid|浅层 MLP、输出层（概率）|⚠️ 较高（最大 0.25）|
|tanh|循环神经网络（RNN）|⚠️ 中等|
|ReLU|深层神经网络（主流）|✅ 无（正区间）|

---

## 八、训练：前向传播 + 反向传播

> [!note] 神经网络训练的目标 找到最优参数 $\mathbf{W}$，使**损失函数 $\mathcal{L}$（预测误差）最小化**。

### 损失函数（Loss Function）

最常用的均方误差（MSE）：

$$\mathcal{L} = \frac{1}{2}(y - y')^2$$

对整个数据集：

$$\mathcal{L}(\mathbf{w}) = \frac{1}{2} \sum_{n=1}^{N} (\text{target}_n - \text{output}_n(\mathbf{w}))^2$$

> [!tip] 为什么前面加 $\frac{1}{2}$？ 纯粹是为了求导方便：对 $(y-y')^2$ 求导会出现系数 2，乘以 $\frac{1}{2}$ 恰好消掉，推导更整洁。

### 梯度下降（Gradient Descent）

**核心思想**：沿着损失函数梯度的**反方向**更新参数，逐步逼近最小值。

$$\mathbf{w}^{[l]} \leftarrow \mathbf{w}^{[l]} - \alpha \frac{\partial \mathcal{L}(\mathbf{w})}{\partial \mathbf{w}^{[l]}}$$

其中 $\alpha$ 是**学习率（learning rate）**，控制步长。

**算法步骤**：

1. 随机初始化所有参数 $\mathbf{w}$
2. 重复：
    - 前向传播计算预测值
    - 计算损失 $\mathcal{L}$
    - 反向传播计算各参数梯度
    - 更新参数
3. 直到梯度接近 0（收敛）

### 前向传播（Forward Propagation）

按照**从输入层到输出层的顺序**，依次计算每层的输出，并将中间结果存储下来（供反向传播使用）。

**目的**：在当前参数下计算预测误差。

以两输入、两隐藏、两输出的网络为例，输入 $x_1=0.05, x_2=0.10$：

```
Step 1: 计算隐藏层净输入
net_h1 = w1*x1 + w2*x2 + b1*1
       = 0.15*0.05 + 0.20*0.10 + 0.35 = 0.3775

Step 2: 通过 Sigmoid 激活
out_h1 = σ(0.3775) = 1/(1+e^{-0.3775}) ≈ 0.59327

Step 3: 类似计算 out_h2 ≈ 0.59688

Step 4: 计算输出层净输入
net_o1 = w5*out_h1 + w6*out_h2 + b2
       = 0.40*0.59327 + 0.45*0.59688 + 0.60 ≈ 1.10591

Step 5: 激活得输出
out_o1 = σ(1.10591) ≈ 0.75137
out_o2 ≈ 0.77293
```

目标：$\text{target}_{o1} = 0.01, \text{target}_{o2} = 0.99$

$$E_{total} = \frac{1}{2}(0.01 - 0.75137)^2 + \frac{1}{2}(0.99 - 0.77293)^2 \approx 0.2984$$

### 反向传播（Backpropagation）

**核心思想**：利用**链式法则（Chain Rule）**，从输出层反向逐层计算每个参数对损失的梯度。

**目的**：根据误差调整参数。

#### 输出层权重的梯度（以 $w_5$ 为例）

$$\frac{\partial E_{total}}{\partial w_5} = \frac{\partial E_{total}}{\partial \text{out}_{o1}} \cdot \frac{\partial \text{out}_{o1}}{\partial \text{net}_{o1}} \cdot \frac{\partial \text{net}_{o1}}{\partial w_5}$$

**逐项计算**：

（1）$\frac{\partial E_{total}}{\partial \text{out}_{o1}} = -(\text{target}_{o1} - \text{out}_{o1}) = -(0.01 - 0.75137) = 0.74137$

（2）利用 Sigmoid 导数公式：

$$\frac{\partial \text{out}_{o1}}{\partial \text{net}_{o1}} = \text{out}_{o1}(1 - \text{out}_{o1}) = 0.75137 \times 0.24863 \approx 0.18682$$

（3）$\frac{\partial \text{net}_{o1}}{\partial w_5} = \text{out}_{h1} = 0.59327$

**合并**：

$$\frac{\partial E_{total}}{\partial w_5} = 0.74137 \times 0.18682 \times 0.59327 \approx 0.08217$$

**参数更新**（学习率 $\eta = 0.5$）：

$$w_5^+ = w_5 - \eta \cdot \frac{\partial E_{total}}{\partial w_5} = 0.40 - 0.5 \times 0.08217 \approx 0.35892$$

#### 隐藏层权重的梯度（以 $w_1$ 为例）

$w_1$ 通过 $h_1$ 同时影响 $o_1$ 和 $o_2$，因此：

$$\frac{\partial E_{total}}{\partial \text{out}_{h1}} = \frac{\partial E_{o1}}{\partial \text{out}_{h1}} + \frac{\partial E_{o2}}{\partial \text{out}_{h1}}$$

其中：

$$\frac{\partial E_{o1}}{\partial \text{out}_{h1}} = \frac{\partial E_{o1}}{\partial \text{out}_{o1}} \cdot \frac{\partial \text{out}_{o1}}{\partial \text{net}_{o1}} \cdot \frac{\partial \text{net}_{o1}}{\partial \text{out}_{h1}}$$

再向前一层：

$$\frac{\partial E_{total}}{\partial w_1} = \frac{\partial E_{total}}{\partial \text{out}_{h1}} \cdot \frac{\partial \text{out}_{h1}}{\partial \text{net}_{h1}} \cdot \frac{\partial \text{net}_{h1}}{\partial w_1}$$

**链式法则的一般形式**（L 层网络，对第 1 层参数）：

$$\frac{\partial \mathcal{L}}{\partial \mathbf{W}^{(1)}} = \frac{\partial \mathcal{L}}{\partial y'} \cdot \frac{\partial y'}{\partial \mathbf{h}^{(2)}} \cdot \frac{\partial \mathbf{h}^{(2)}}{\partial \mathbf{h}^{(1)}} \cdot \frac{\partial \mathbf{h}^{(1)}}{\partial \mathbf{W}^{(1)}}$$

> [!important] 反向传播的本质 反向传播 = 链式法则 + 从输出到输入的逐层梯度计算。 它不一次性计算所有梯度，而是**复用中间结果**，避免重复计算，效率极高。

### 训练收敛效果（示例数值）

|阶段|总误差|
|---|---|
|初始|0.298371|
|第1轮 BP 后|0.291028|
|10000 轮后|0.000035|

10000 轮后输出：$o_1 \approx 0.0159$（目标 0.01），$o_2 \approx 0.9841$（目标 0.99）✅

---

## 九、梯度消失问题与 ReLU

### 梯度消失问题（Vanishing Gradient Problem）

> [!warning] 核心问题 使用 Sigmoid 激活函数时，反向传播每经过一层，梯度至多乘以 **0.25**。 对于 $L$ 层网络，第 1 层的梯度约为 $(0.25)^{L-1}$ 倍——指数级衰减！ 层数一深，底层几乎接收不到有效的训练信号，等价于只有顶层在学习。

**数学原因**：
$$\text{Sigmoid 导数：} \sigma'(x) = \sigma(x)(1-\sigma(x)) \in [0, 0.25]$$

每层反向传播都要乘一个不超过 0.25 的系数 → 梯度快速消失。
### 解决方案：使用 ReLU
$$\text{ReLU}(x) = \max(0, x), \quad \frac{d\text{ReLU}}{dx} = \begin{cases} 0 & x \leq 0 \ 1 & x > 0 \end{cases}$$
**在正区间，ReLU 导数恒为 1**，梯度不会衰减，可以有效训练深层网络。

> [!warning] ReLU 的缺陷："神经元死亡（Dead Neuron）" 当某个神经元的输入始终为负，输出恒为 0，该神经元的梯度也恒为 0，**永远无法更新**——称为"死亡的 ReLU"。 改进方案：Leaky ReLU（负区间有小斜率）、ELU 等。

### 其他解决梯度消失的手段
- **无监督逐层预训练（Unsupervised Pre-training）**：Hinton 2006 年提出，用受限玻尔兹曼机（RBM）逐层初始化权重，再整体微调
- **深度信念网络（DBN，Deep Belief Network）**：基于逐层预训练的深度模型
- **批归一化（Batch Normalization）**：让每层输入分布稳定，缓解梯度问题
- **残差连接（Residual Connection）**：跨层直接传递梯度（ResNet）

## 十、深度学习简介

### 什么是深度学习

深度学习（Deep Learning）= 使用**很多隐藏层**（深层）的神经网络，配合大量数据和高效训练算法。

### 主要深度学习框架

|框架|机构|特点|
|---|---|---|
|TensorFlow|Google|工业界广泛使用|
|PyTorch|Meta（Facebook）|学术界主流，动态图|
|Keras|独立（集成于TF）|高层 API，易用|
|PaddlePaddle|百度|国产，工业场景|

### 应用领域

- **计算机视觉（CV）**：图像分类、目标检测、人脸识别
- **自然语言处理（NLP）**：机器翻译、文本生成、问答系统（GPT 等）
- **语音识别**：语音转文字、声纹识别
- **医疗健康**：疾病检测（如中大眼科中心婴幼儿眼病筛查系统，《Nature Medicine》2023）
- **科学研究**：微波成像（崔铁军院士课题组基于 MLP 的超表面成像系统）

---

## 十一、例题精讲

### 例题 1：MP 神经元基础计算

**题目**：一个 MP 神经元有 3 个输入 $a_1, a_2, a_3$，权值分别为 $w_1=0.5, w_2=-0.3, w_3=0.8$，激活函数为 $\text{sgn}$。当输入为 $a_1=1, a_2=2, a_3=-1$ 时，求输出 $z$
**解答**：
$$\sum = a_1 w_1 + a_2 w_2 + a_3 w_3 = 1 \times 0.5 + 2 \times (-0.3) + (-1) \times 0.8$$ $$= 0.5 - 0.6 - 0.8 = -0.9$$

$$z = \text{sgn}(-0.9) = -1$$

**输出为 -1（负类）。**

---

### 例题 2：感知机训练一步
**题目**：感知机有 2 个输入，权值 $w_1=0.2, w_2=0.4$，学习率 $\eta=0.1$。训练样本 $(a_1, a_2) = (1, 0)$，真实标签 $y = 1$
（1）计算预测值 $\hat{y}$；  
（2）更新权值。
**解答**：
（1）$\hat{y} = \text{sgn}(w_1 a_1 + w_2 a_2) = \text{sgn}(0.2 \times 1 + 0.4 \times 0) = \text{sgn}(0.2) = 1$
（2）$\Delta W = \eta(y - \hat{y}) \cdot \mathbf{a} = 0.1 \times (1 - 1) \times \mathbf{a} = 0$
**预测正确，权值不更新**：$w_1 = 0.2, w_2 = 0.4$（不变）
**变换题目**：若真实标签 $y = -1$，则：
$$\Delta w_1 = 0.1 \times (-1 - 1) \times 1 = -0.2 \Rightarrow w_1^+ = 0.2 - 0.2 = 0$$ $$\Delta w_2 = 0.1 \times (-1 - 1) \times 0 = 0 \Rightarrow w_2^+ = 0.4$$
---
### 例题 3：感知机为何不能解决 XOR

**题目**：验证单层感知机无法正确分类 XOR 问题（$(0,0)\to0$, $(0,1)\to1$, $(1,0)\to1$, $(1,1)\to0$）
**解答**：
感知机的决策边界为直线 $w_1 x_1 + w_2 x_2 + b = 0$。
要使分类正确，需要同时满足：
- $(0,0)$：$b < 0$（分类为 0）
- $(1,1)$：$w_1 + w_2 + b < 0$（分类为 0）
- $(0,1)$：$w_2 + b > 0$（分类为 1）
- $(1,0)$：$w_1 + b > 0$（分类为 1）

将后两个不等式相加：$w_1 + w_2 + 2b > 0$，即 $w_1 + w_2 + b > -b > 0$（因为 $b < 0$）。
但由第二个条件 $w_1 + w_2 + b < 0$，产生矛盾！

**结论：不存在满足所有条件的参数，单层感知机无法解决 XOR 问题。**

---

### 例题 4：MLP 前向传播完整计算 ⭐

**题目**：一个三层 MLP，输入层 2 个节点，隐藏层 2 个节点，输出层 1 个节点。
参数：$W_1 = \begin{pmatrix}0.1 & 0.2 \ 0.3 & 0.4\end{pmatrix}$，$W_2 = \begin{pmatrix}0.5 & 0.6\end{pmatrix}$，偏置均为 0，激活函数均为 Sigmoid
输入 $\mathbf{x} = (1, 0)^T$，计算输出
**解答**：
**隐藏层计算**：
$$\mathbf{h}^{(1)} = W_1 \mathbf{x} = \begin{pmatrix}0.1 \times 1 + 0.2 \times 0 \ 0.3 \times 1 + 0.4 \times 0\end{pmatrix} = \begin{pmatrix}0.1 \ 0.3\end{pmatrix}$$
通过 Sigmoid：
$$h_1 = \sigma(0.1) = \frac{1}{1+e^{-0.1}} \approx 0.5250$$
$$h_2 = \sigma(0.3) = \frac{1}{1+e^{-0.3}} \approx 0.5744$$
**输出层计算**：
$$\text{net}_{o} = W_{2}\mathbf{h} = 0.5 \times 0.5250 + 0.6 \times 0.5744 = 0.2625 + 0.3446 = 0.6071$$
$$y' = \sigma(0.6071) \approx 0.6474$$
---

### 例题 5：反向传播梯度计算（链式法则）⭐⭐

**题目**（课件原题）：考虑以下神经网络：

- $x_1, x_2$ 为输入节点（无激活函数）
- 输出节点 $\text{node3}$：净输入 $I_3 = w_{13} x_1 + w_{23} x_2 + \theta$，激活函数为 Sigmoid
- 训练样本：$x_1=1, x_2=0, y=0$
- 初始参数：$w_{13}=0, w_{23}=0, \theta=0$
- 损失函数：$L = \frac{1}{2}(O_3 - y)^2$

求 $\frac{\partial L}{\partial w_{13}}$。

**解答**：

**前向传播**：

$$I_3 = 0 \times 1 + 0 \times 0 + 0 = 0$$

$$O_3 = \sigma(0) = \frac{1}{1+e^0} = \frac{1}{2}$$

**链式法则**：

$$\frac{\partial L}{\partial w_{13}} = \frac{\partial L}{\partial O_3} \cdot \frac{\partial O_3}{\partial I_3} \cdot \frac{\partial I_3}{\partial w_{13}}$$

逐项计算：

$$\frac{\partial L}{\partial O_3} = O_3 - y = \frac{1}{2} - 0 = \frac{1}{2}$$

$$\frac{\partial O_3}{\partial I_3} = \sigma(I_3)(1 - \sigma(I_3)) = \frac{1}{2} \times \frac{1}{2} = \frac{1}{4}$$

$$\frac{\partial I_3}{\partial w_{13}} = x_1 = 1$$

**合并**：

$$\frac{\partial L}{\partial w_{13}} = \frac{1}{2} \times \frac{1}{4} \times 1 = \boxed{-\frac{1}{8}}$$

> [!warning] 注意符号 有些教材中损失函数对输出求导写为 $-(y - O_3)$，注意不要搞反符号方向。 本题 $\frac{\partial L}{\partial O_3} = \frac{\partial \frac{1}{2}(O_3-y)^2}{\partial O_3} = (O_3 - y) = \frac{1}{2}$，正值。

---

### 例题 6：梯度消失定量分析 ⭐⭐

**题目**：一个 5 层的 MLP，每层都使用 Sigmoid 激活函数。已知第 5 层（输出层）的梯度大小为 1.0，请估计第 1 层（紧接输入层的隐藏层）能接收到的梯度大小范围，并解释其含义。

**解答**：

Sigmoid 导数满足：$0 \leq \sigma'(x) \leq 0.25$

从第 5 层反向传播到第 1 层，需经过 4 次 Sigmoid 求导（每层乘一次导数）：

$$|\text{第 1 层梯度}| \leq 1.0 \times (0.25)^4 = 1.0 \times \frac{1}{256} \approx 0.0039$$

即第 1 层梯度**最多只有输出层的 $\frac{1}{256}$**，实际往往更小。

**含义**：底层权重几乎不更新，神经网络实际上只有顶层在有效学习，5 层网络退化为近似 1 层网络的效果。

**解决方案**：将 Sigmoid 换为 ReLU（正区间导数为 1，不衰减）。

---

### 例题 7：综合题——完整 BP 一步更新 ⭐⭐⭐

**题目**：给定 MLP：输入 $x=2$，一个隐藏节点，输出 1 个节点。参数初始值：$w_1=0.5$（输入到隐藏），$w_2=0.3$（隐藏到输出），偏置均为 0，激活函数均为 Sigmoid，真实标签 $y=1$，学习率 $\eta=1$。

（1）完成前向传播；  
（2）计算损失；  
（3）反向传播，计算 $\frac{\partial L}{\partial w_2}$ 和 $\frac{\partial L}{\partial w_1}$；  
（4）更新 $w_1, w_2$。

**解答**：

**（1）前向传播**：

$$\text{net}_h = w_1 \times x = 0.5 \times 2 = 1.0$$ $$h = \sigma(1.0) = \frac{1}{1+e^{-1}} \approx 0.7311$$

$$\text{net}_o = w_2 \times h = 0.3 \times 0.7311 = 0.21933$$ $$y' = \sigma(0.21933) \approx 0.5546$$

**（2）损失**：

$$L = \frac{1}{2}(y - y')^2 = \frac{1}{2}(1 - 0.5546)^2 = \frac{1}{2}(0.4454)^2 \approx 0.0992$$

**（3）反向传播**：

$\frac{\partial L}{\partial w_2}$（输出层权重）：

$$\frac{\partial L}{\partial w_2} = \underbrace{(y' - y)}_{-0.4454} \cdot \underbrace{y'(1-y')}_{0.5546 \times 0.4454 \approx 0.2469} \cdot \underbrace{h}_{0.7311}$$ $$\approx (-0.4454) \times 0.2469 \times 0.7311 \approx -0.08041$$

$\frac{\partial L}{\partial w_1}$（隐藏层权重，链式法则多传一层）：

$$\frac{\partial L}{\partial w_1} = \underbrace{\frac{\partial L}{\partial y'}}_{\approx -0.1099} \cdot \underbrace{w_2}_{0.3} \cdot \underbrace{h(1-h)}_{0.7311 \times 0.2689 \approx 0.1966} \cdot \underbrace{x}_{2}$$

其中 $\frac{\partial L}{\partial \text{net}_o} = (y'-y) \cdot y'(1-y') = -0.4454 \times 0.2469 \approx -0.1099$

$$\frac{\partial L}{\partial w_1} = (-0.1099) \times 0.3 \times 0.1966 \times 2 \approx -0.01296$$

**（4）参数更新**：

$$w_2^+ = w_2 - \eta \cdot \frac{\partial L}{\partial w_2} = 0.3 - 1 \times (-0.08041) = 0.38041$$

$$w_1^+ = w_1 - \eta \cdot \frac{\partial L}{\partial w_1} = 0.5 - 1 \times (-0.01296) = 0.51296$$

**两个权重均增大，符合"增大输出"向目标 1 靠拢的直觉。** ✅

---

## 📌 重点总结

> [!summary] 本讲核心知识点
> 
> 1. **MP 神经元**：N 输入 → 加权求和 → sgn 激活 → 1 输出；权重不可学习
> 2. **感知机**：权重可学，但只能线性分类，无法解决 XOR
> 3. **MLP**：引入隐藏层 + 非线性激活函数，可拟合任意连续函数（UAT）
> 4. **激活函数**：sgn → Sigmoid → ReLU，解决梯度消失
> 5. **训练**：前向传播（计算误差）+ 反向传播（链式法则更新参数）
> 6. **梯度消失**：Sigmoid 导数 ≤ 0.25，层深则梯度指数衰减；ReLU 解决
> 7. **深度学习**：深层 MLP + 大数据 + 高效优化器

---

## ❗ 易错点与难点提示

> [!warning] 常见错误
> 
> 1. **偏置忘加**：MLP 公式 $\mathbf{a} = g(\mathbf{W}\mathbf{x} + \mathbf{b})$ 中，$\mathbf{b}$ 不可少，否则决策面过原点
> 2. **Sigmoid 导数公式记错**：$\sigma'(x) = \sigma(x)(1-\sigma(x))$，不是 $\sigma(x)\sigma(-x)$（虽然等价但容易混）
> 3. **反向传播链式法则方向**：一定是从**输出层到输入层**，不能搞反
> 4. **多路径梯度叠加**：隐藏层节点影响多个输出节点，反向传播时梯度要**相加**（$\frac{\partial E_{total}}{\partial \text{out}_{h1}} = \frac{\partial E_{o1}}{\partial \text{out}_{h1}} + \frac{\partial E_{o2}}{\partial \text{out}_{h1}}$）
> 5. **线性激活 = 网络退化**：不加非线性激活函数，多层 = 单层，切记
> 6. **感知机 vs MLP 的激活函数**：感知机用 sgn，MLP 用 Sigmoid/ReLU/tanh

---

_参考资料：超算习堂 https://easyhpc.net/course/143_