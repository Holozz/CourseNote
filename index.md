# 知识库索引 (Knowledge Base Index)

> [!info] 索引说明
> 本索引基于 [[LLM Wiki]] 方法论构建，按学科分类列出所有笔记文件。每个条目包含 Wiki-link、一句话摘要和核心主题。查询时先查此索引，再钻入具体页面。

**最后更新**: 2026-10-19
**涵盖学科**: C++ Language · OS (操作系统) · DC (数字电路) · AI (人工智能) · ML (机器学习与数据挖掘) · 图论 · 代数结构 · DIP (数字图像处理) · DB (数据库原理) · Python · Algorithm · HTML · C Language · CN (计算机网络) · FA (形式语言与自动机) · 数理逻辑 · 最优化理论
**笔记总数**: 112

---

## 📁 C++ Language (8 篇)

> C++ 面向对象编程与泛型编程，涵盖类、运算符重载、继承、多态、模板、STL 等核心专题。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[Chapter 3 类]] | 类的基础：ADT 概念、构造/析构、static 成员、动态内存、深拷贝三件套、初始化列表、const 正确性 | ADT, constructor/destructor, static, new/delete, deep copy, initializer list, const |
| 2 | [[Chapter 4 运算符重载]] | 运算符重载的两种形式（成员/友元），前缀/后缀 `++`/`--`，深拷贝赋值三步法，`operator[]`，函数对象，`explicit` | operator overloading, friend, assignment, functor, implicit conversion |
| 3 | [[Chapter 5 继承与派生（Inheritance & Derivation）]] | 继承体系：访问控制表、构造/析构顺序、类型兼容与对象切片、四种 C++ 转型、多重继承与虚基类 | inheritance, access control, casting, multiple inheritance, virtual base, diamond problem |
| 4 | [[Chapter 6 多态]] | 运行时多态核心：虚函数、override vs hide、纯虚函数与抽象类、虚析构、RTTI、vtable 机制、final | polymorphism, virtual function, abstract class, RTTI, vtable, dynamic_cast |
| 5 | [[Chapter 7 模板]] | 泛型编程基础：函数模板与重载决议、类模板、非类型参数、数组引用推导、编译期零开销抽象 | template, generic programming, class template, non-type parameter, template deduction |
| 6 | [[Week 8]] | Week 8 习题课：运算符重载 Q&A，前后缀 `++`/`--` 详析，深浅拷贝对比，自赋值检查 | operator overloading review, increment/decrement, deep copy, self-assignment |
| 7 | [[期中]] | 期中复习：Week 5-10 知识点汇总，语法速查表，专题深挖（friend / overloading / copying / inheritance / explicit） | midterm review, friend, operator=, copy ctor vs assignment, inheritance chain, explicit |
| 8 | [[Chapter 9 标准模板库（STL）]] | STL 四大组件（容器/迭代器/算法/适配器）、顺序容器 vector/list/deque、关联容器 map/set、迭代器分类与 auto/decltype、算法与容器分离的设计思想 | STL, containers, iterators, algorithms, vector, map, set, generic programming |

---

## 📁 OS — 操作系统 (15 篇)

> 操作系统核心课程笔记，从 OS 概述到文件系统实现，覆盖进程管理、内存管理、存储与 I/O。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[Ch1 操作系统概述]] | OS 目标、硬件基础（SMP/NUMA）、双模式、系统调用、云计算与虚拟化 | OS goals, dual-mode, system calls, cloud computing, virtualization |
| 2 | [[Ch2 操作系统结构]] | OS 演进史、系统服务、系统调用分类、内核架构对比（monolithic vs microkernel vs hybrid） | kernel architecture, system services, system calls, OS evolution |
| 3 | [[Ch3 中断]] | 三种控制流中断（硬件中断/异常/系统调用），Linux Top Half / Bottom Half 机制，中断上下文约束 | interrupt, exception, trap, Top/Bottom Half, interrupt context |
| 4 | [[Ch4 进程]] | 进程内存布局、PCB、fork/exec/wait/exit、三级调度器、IPC 全家族（共享内存/消息传递/管道/socket/RPC） | process, PCB, fork, IPC, scheduler types |
| 5 | [[Ch5 线程]] | 线程 vs 进程、Pthreads、隐式线程（线程池/Fork-Join/OpenMP/GCD）、信号处理与线程取消 | thread, Pthreads, thread pool, implicit threading |
| 6 | [[Ch6 进程调度]] | 调度算法全览（FCFS/SJF/RR/Priority/MLFQ）、多处理器调度、实时调度（RM/EDF）、优先级反转与继承 | CPU scheduling, real-time, priority inversion, multiprocessor |
| 7 | [[Ch7 进程同步（Process Synchronization）]] | 竞态→临界区→Peterson→TAS/CAS→信号量→管程（Hoare/Hasen/MESA）→经典同步问题→事务内存 | synchronization, semaphore, monitor, critical section, mutex |
| 8 | [[Ch8 — 并发：死锁与饥饿（Deadlock & Starvation]] | 死锁四条件、RAG、预防/避免（Banker's Algorithm）/检测/恢复、哲学家就餐问题 | deadlock, Banker's Algorithm, resource allocation graph, starvation |
| 9 | [[Ch9 物理内存管理]] | 地址空间布局→绑定→MMU→分段→分页（TLB）→多级/哈希/倒排页表→Buddy System | paging, TLB, page table structures, segmentation, buddy system |
| 10 | [[Ch10 虚拟内存管理]] | 请求调页、COW、页面置换算法全谱系（FIFO/OPT/LRU/Clock/Enhanced）、抖动与工作集、Slab 分配器 | demand paging, page replacement, thrashing, working-set, Slab |
| 11 | [[Ch11 大容量存储]] | HDD 机械与寻道时间、SSD（写放大/磨损均衡/TRIM/NVMe）、磁盘调度算法、RAID 0-6、NAS/SAN | HDD, SSD, disk scheduling, RAID, storage networking |
| 12 | [[Ch12 IO 管理]] | 轮询/中断/DMA 三大 I/O 技术、MMIO、阻塞/非阻塞/异步模型、缓冲 vs 缓存、Spooling、STREAMS | I/O techniques, DMA, buffering, caching, device driver |
| 13 | [[Ch13 文件系统]] | 文件抽象→打开文件表→访问方法→目录结构（树/DAG）→硬/软链接→Linux 权限模型 | file system, directory structure, hard/soft link, permissions |
| 14 | [[Ch14 文件系统实现]] | 分层架构→inode→五种分配方式→空闲空间管理→缓冲/页缓存→日志文件系统/fsck | inode, allocation methods, buffer cache, journaling, fsck |
| 15 | [[Ch15 典型文件系统]] | 文件操作全流程（fopen→fd→read/write）→FAT32 布局与 LFN→Ext2/3 inode 多级索引→硬链接/软链接→文件系统对比 | FAT32, Ext2/3, inode, hard link, symbolic link, file descriptor, directory traversal |

---

## 📁 DC — 数字电路 (10 篇)

> 数字逻辑电路，从基本概念到组合/时序电路设计，涵盖逻辑化简、MSI 器件和状态机设计。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[Chapter1 基本概念]] | 模拟 vs 数字、数字波形（周期/频率/占空比）、串并行传输、数字 IC 分类与可编程逻辑器件 | analog vs digital, waveforms, PLD, FPGA |
| 2 | [[Chapter2 数字系统、运算和编码]] | 进制转换、有符号数三种表示（原码/反码/补码）、浮点数、BCD 码、奇偶校验与 CRC | number systems, two's complement, floating-point, CRC |
| 3 | [[Chapter3 逻辑门]] | 七种基本逻辑门（NOT/AND/OR/NAND/NOR/XOR/XNOR）、真值表、布尔表达式、有效电平 | logic gates, truth tables, NAND, NOR, XOR |
| 4 | [[Chapter4 布尔代数和逻辑化简]] | 布尔代数定律（交换/结合/分配/DeMorgan）、标准形式、卡诺图化简、无关项 | Boolean algebra, Karnaugh map, minterm, maxterm, don't-care |
| 5 | [[Chapter5 组合逻辑分析]] | 组合 vs 时序、四种表示法、分析与设计流程、NAND/NOR 通用门实现、设计与故障分析 | combinational logic, universal gates, design workflow |
| 6 | [[Chapter6 组合逻辑电路函数]] | 加法器（半加/全加/行波/超前进位）、比较器、译码器/编码器、MUX/DEMUX、组合逻辑竞争与冒险 | adder, comparator, decoder, multiplexer, hazards |
| 7 | [[Chapter7 锁存器、触发器和定时器]] | SR/D/JK/T 锁存器与触发器、建立/保持时间、亚稳态、555 定时器（单稳/多谐） | latch, flip-flop, setup/hold, metastability, 555 timer |
| 8 | [[Chapter8 计数器]] | 异步 vs 同步计数器、FSM (Moore/Mealy)、六步设计法、自启动设计、级联计数器 | counter, FSM, synchronous design, JK flip-flop, self-starting |
| 9 | [[Chapter9 移位寄存器（Shift Register）]] | SISO/SIPO/PISO/PIPO、74HC194 双向寄存器、Johnson 计数器、环形计数器、串并转换应用 | shift register, Johnson counter, ring counter, serial-parallel |
| 10 | [[Chapter10 内存和外存]] | 半导体存储器：SRAM/DRAM、ROM 家族（掩膜/PROM/EPROM/EEPROM）、Flash、存储器扩展、FIFO/LIFO | memory, SRAM, DRAM, ROM, Flash, FIFO, LIFO |

---

## 📁 AI — 人工智能 (12 篇)

> 人工智能课程笔记，覆盖搜索算法、概率推理、机器学习、深度学习与强化学习全栈内容。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[第5、6讲 搜索技术I]] | 搜索问题形式化（六大要素）→盲目搜索族（BFS/DFS/UCS/DLS/IDS/双向）→A* 算法→启发式函数设计 | search problem formulation, BFS, DFS, UCS, A*, heuristic |
| 2 | [[第7讲 搜索技术II]] | 对抗性搜索：MiniMax→Alpha-Beta 剪枝→评价函数→MCTS，博弈问题形式化 | adversarial search, MiniMax, Alpha-Beta pruning, MCTS |
| 3 | [[第8讲 高级搜索算法]] | 爬山法→模拟退火（Metropolis 准则）→遗传算法（编码/选择/交叉/变异/模式定理），TSP 与背包问题 | hill-climbing, simulated annealing, genetic algorithm, TSP |
| 4 | [[第9讲 朴素贝叶斯]] | 概率推理基础→贝叶斯定理→朴素贝叶斯分类器（拉普拉斯平滑/m-估计）→贝叶斯网络→应用案例 | Bayes, Naive Bayes, Bayesian Network, probabilistic reasoning |
| 5 | [[第10讲 决策树 Decision Tree]] | CLS→ID3（信息增益）→C4.5（增益率）→CART（Gini），连续属性离散化，算法对比 | decision tree, ID3, C4.5, CART, entropy, information gain |
| 6 | [[第11讲 机器学习（Machine Learning]] | ML 定义→模型+损失+优化框架→监督/半监督/无监督/强化→评估指标→感知机→深度学习兴起 | ML pipeline, supervised learning, evaluation metrics, perceptron |
| 7 | [[第12讲 无监督学习：聚类算法 (Clustering)]] | K-means（K-means++/||）→DBSCAN（密度聚类）→距离度量→轮廓系数→聚类验证 | K-means, DBSCAN, clustering, silhouette, distance metrics |
| 8 | [[第13讲人工神经网络（Artificial Neural Network]] | MP 神经元→感知机→MLP→激活函数（Sigmoid/tanh/ReLU）→正向/反向传播→梯度消失→深度学习导论 | ANN, perceptron, backpropagation, vanishing gradient, activation functions |
| 9 | [[第14讲 深度学习与典型神经网络（Deep Learning and Classical Neural Networks）]] | CNN（卷积/池化/参数效率）→RNN→LSTM（三门控+记忆单元）→深度学习可解释性（显著性图） | CNN, RNN, LSTM, pooling, explainability |
| 10 | [[第15讲 深度学习II - Transformer]] | Word2Vec/GloVe→Seq2Seq→Attention（Q/K/V）→Transformer（Self-Attention/Multi-Head/位置编码/残差/LayerNorm） | Transformer, self-attention, word embeddings, positional encoding |
| 11 | [[第16讲 强化学习——决策智能]] | MDP→Bellman 方程→DP/MC/TD→SARSA/Q-Learning→DQN 系列→策略梯度→Actor-Critic→AlphaGo (MCTS) | RL, MDP, Q-Learning, DQN, policy gradient, AlphaGo, MCTS |
| 12 | [[AI 期末复习总结（第8~16讲）]] | 📝 第 8~16 讲期末总复习，公式速查 + 概念精炼 + 算法对比全表 | review, summary, all lectures, final exam |

---

## 📁 ML — 机器学习与数据挖掘 (9 篇)

> 中山大学《机器学习与数据挖掘》课程笔记：从回归、分类到非线性化与正则化、支持向量机、神经网络及训练优化，并含 Transformer、GPT、BERT 与后训练对齐补充。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[ML/Ch1 回归]] | 回归问题课堂速记（片段）：单特征/多特征模型与代价函数、矩阵求导记号 | regression, single/multi-feature, cost function, matrix calculus |
| 2 | [[ML/Ch2 线性回归]] | 线性回归全流程：单/多特征模型、均方误差、正规方程推导与几何投影解释、梯度下降与 SGD/小批量、牛顿法 | linear regression, MSE, normal equation, projection, gradient descent, SGD, Newton's method |
| 3 | [[ML/Ch3 线性分类器（Linear Classifiers）]] | 线性分类器全流程：逻辑回归与 Sigmoid、平方误差 vs 交叉熵（凸性证明/梯度消失）、无解析解与梯度下降、决策边界与超平面、One-vs-All 与 Softmax、多分类交叉熵与矩阵梯度、13 道例题 | logistic regression, sigmoid, cross-entropy, convexity, Hessian, decision boundary, hyperplane, One-vs-All, softmax, one-hot, multi-class gradient |
| 4 | [[ML/Ch4 线性回归与分类的概率视角]] | 概率视角统一框架：条件概率建模、均值 vs 众数预测、高斯/伯努利/类别分布与谱分解、i.i.d. 与对数似然、三条推导链（高斯→平方误差、伯努利→交叉熵、类别→多分类交叉熵）、指数族与 GLM、MAP 与正则化（L2/L1）、11 道例题 | probabilistic view, conditional probability, MLE, log-likelihood, Gaussian, covariance, spectral decomposition, Bernoulli, categorical, cross-entropy, exponential family, GLM, MAP, ridge, Lasso |
| 5 | [[ML/Ch5 模型的非线性化、过拟合及正则化]] | 非线性化（基函数 / 分段线性 = 常数 + 一组 sigmoid 之和，直通神经网络）、过拟合与欠拟合、偏差-方差分解、模型复杂度、模型选择（验证集 / 留一法 / K 折交叉验证 / AIC·BIC）、正则化（L2 权重衰减、L1 稀疏解及其次梯度与几何解释、正则项 = 负对数先验）、11 道例题（含多项式阶数实测表与 L1/L2 稀疏性实测） | nonlinearization, basis function, piecewise linear, hard sigmoid, ReLU, overfitting, underfitting, generalization, bias-variance decomposition, model complexity, model selection, validation set, LOOCV, K-fold CV, AIC, BIC, L2/ridge, weight decay, L1/Lasso, sparsity, subgradient, MAP, data leakage |
| 6 | [[ML/Ch6 支持向量机]] | 最大间隔分类器：从"零损失超平面有无穷多个"到间隔最大化、函数间隔 vs 几何间隔、尺度不变性与 QP 形式；拉格朗日对偶完整推导、KKT 与支持向量的稀疏性、原问题 vs 对偶的复杂度；软间隔与松弛变量（C 与 λ=1/(2C)）；核方法（Mercer 定理、高斯核无限维、核技巧）；与逻辑回归的统一误差函数框架（hinge vs logistic）、12 道例题 | SVM, maximal margin, functional/geometric margin, scale invariance, QP, Lagrange duality, KKT, complementary slackness, support vector, sparsity, soft margin, slack variable, box constraint, kernel trick, Mercer theorem, RBF kernel, hinge loss, logistic loss, convex surrogate |
| 7 | [[ML/Ch7 神经网络]] | 神经网络：可学习基函数（激活函数 Sigmoid/Tanh/ReLU/Leaky ReLU）、反向传播（链式法则+记忆化）、CNN（局部连接+参数共享+池化+LeNet/AlexNet/VGG/ResNet）、RNN/LSTM、Transformer 自注意力机制（QKV+多头）、GNN 节点聚合；梯度消失、感受野、跳跃连接、11 道例题 | neural network, activation function, backpropagation, gradient vanishing, CNN, convolution, pooling, ResNet, skip connection, RNN, LSTM, Transformer, self-attention, QKV, multi-head attention, BERT, GPT, GNN, GCN |
| 8 | [[ML/Ch8 神经网络的训练与优化]] | Lecture 8 全部 29 页：SGD 与病态曲率、动量、RMSProp/EMA、Adam 六步与偏差校正、预处理与初始化、Dropout 训练测试缩放、BN/LN/IN 统计轴、超参数与损失曲线；12 道例题 | SGD, momentum, RMSProp, EMA, Adam, bias correction, whitening, initialization, dropout, batch normalization, layer normalization, instance normalization, hyperparameter tuning |
| 9 | [[ML/Ch8 Supplement2 Transformer、GPT 与 BERT]] | Supplement 2 全部 35 页：QKV 与维度、因果遮罩、多头与位置编码、Encoder-Decoder、GPT 预训练/微调/上下文学习、BERT MLM/NSP 与下游任务、SFT/RM/RLHF/PPO 及图示 GRPO、多模态与推理历史案例；12 道例题 | Transformer, self-attention, causal mask, multi-head attention, positional encoding, GPT, BERT, MLM, NSP, in-context learning, SFT, reward model, RLHF, PPO, GRPO |

---

## 📁 图论 — Graph Theory (1 篇)

> 图论及其应用课程，覆盖基本概念、树、匹配、平面图、着色、谱图论与连通性。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[Note]] | 期末复习总结：核心定义、算法步骤、对比表格、易错点、公式速查 | graph theory, tree, matching, planar graph, coloring, spectral graph theory, connectivity |

---

## 📁 代数结构 (2 篇)

> 代数结构课程笔记，覆盖集合关系与函数、运算与代数一般概念、群论（子群/循环群/置换群）、环与域的基础理论。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[代数结构 期末复习笔记]] | 📝 Lecture 1-12 期末复习用：集合与关系、运算与代数一般概念、整数/高斯整数/多项式剩余类、群论（子群/陪集/正规子群/商群/同态/直积/循环群/置换群）、环论（环/整环/域/理想/商环/同态/特征/素理想/极大理想）、有限域、常见群/环/域总表 | group, cyclic group, permutation group, normal subgroup, coset, Lagrange, homomorphism, direct product, ring, ideal, field, finite field, Galois field |
| 2 | [[例题]] | 📝 同态映射像与原像、子环与理想对比、$U_n$ 单位群循环性、环同态分类、有限域 $\mathbb{F}_4/\mathbb{F}_8/\mathbb{F}_9$ 运算与元素阶、素/极大理想判别与证明、高斯整环极大理想、加法群同构、环同构经典例子 | ring homomorphism, unit group, cyclic group U_n, maximal ideal, prime ideal, finite field, quotient ring, isomorphism, Gaussian integer |

---

## 📁 DIP — 数字图像处理 (4 篇)

> 数字图像处理课程笔记（Gonzalez & Woods, *Digital Image Processing*），覆盖数字图像基础与像素关系、灰度变换与空间滤波、频率域滤波（傅里叶变换、取样定理、DFT/FFT、低通/高通/同态滤波）、图像复原（噪声模型、空间滤波复原、自适应滤波、频域去卷积）。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[Ch 2]] | 数字图像基础：灰度分辨率与动态范围、饱和度与对比度、图像内插（最近邻/双线性）、像素间基本关系（4/8/m 邻接、连通、区域、距离测度）与基本数学工具 | grayscale resolution, dynamic range, interpolation, adjacency, distance measures |
| 2 | [[Ch 3 灰度变换与空间滤波]] | 空间域增强全流程：基本灰度变换（负片/对数/幂次/分段线性/灰度切割/位图切割）、直方图均衡化与匹配、局部直方图增强、平滑滤波（均值/高斯/中值）、锐化滤波（拉普拉斯/非锐化掩模/Sobel），7 道例题 | histogram equalization, histogram matching, convolution vs correlation, median filter, Laplacian, Sobel, gamma correction |
| 3 | [[Ch 4 频率域滤波]] | 频域滤波完整体系：傅里叶级数与变换、冲激与取样定理、混叠、2D DFT 及其性质（可分/平移/旋转/周期/共轭对称）、频谱中心化、频域滤波六步法、ILPF/BLPF/GLPF 与 IHPF/BHPF/GHPF、频域拉普拉斯、高频提升/加强、同态滤波、零延拓与缠绕误差、FFT，17 道例题 | Fourier transform, sampling theorem, aliasing, DFT, spectrum centering, BLPF, GLPF, high-boost filtering, homomorphic filter, zero padding, FFT |
| 4 | [[Ch 5 图像复原]] | 图像复原完整体系：复原 vs 增强（客观/主观）、退化模型 $g=h*f+\eta$、六种噪声 PDF（高斯/瑞利/伽马/指数/均匀/脉冲）与白噪声、噪声参数估计、空间滤波复原（算术/几何/谐波/逆谐波均值、中值/最大/最小/中点/修正阿尔法均值）、自适应滤波器（局部噪声消除、自适应中值 Level A/B）、周期噪声带阻与陷波、退化函数估计与逆滤波/维纳/约束最小二乘方/几何均值，13 道例题 | image restoration, noise model, Rayleigh PDF, salt-and-pepper, arithmetic/geometric/harmonic/inverse-harmonic mean, alpha-trimmed mean, adaptive median, bandreject filter, notch filter, inverse filtering, Wiener filter, constrained least squares |

---

## 📁 DB — 数据库原理 (7 篇)

> 数据库系统原理课程笔记（Database System Concepts 7th Ed.），覆盖数据库概述、关系模型与关系代数、SQL 基础 → 中级 SQL（连接/视图/事务/完整性约束/授权）→ 高级 SQL（JDBC/函数/触发器/递归/OLAP）→ 数据库设计与 E-R 模型 → 规范化与依赖理论。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[Ch1 Intro]] | 数据库系统概述：三层模式抽象、实例与模式、DDL/DML 与数据字典、SQL 非过程化查询、数据库设计与 DBMS 组件 | three-level schema, DDL/DML, data dictionary, DBMS components |
| 2 | [[Ch2 关系模型导论]] | 关系数据库的结构（属性/域/元组/NULL/键）、数据库模式与模式图、关系代数（选择投影并交差商、广义投影、聚集、外连接）与完整性约束总览 | relational model, keys, schema diagram, relational algebra, integrity constraints |
| 3 | [[Ch3 Intro to Sql]] | SQL 全流程：DDL、SELECT-FROM-WHERE、集合运算、NULL 三值逻辑、聚合与分组、嵌套子查询、数据库修改，附 5 道综合例题 | SQL, DDL, subquery, three-valued logic, GROUP BY, DML |
| 4 | [[Ch4 Intermediate SQL]] | 中级 SQL 七块：连接表达式（natural/using/on、left/right/full 外连接）、视图（定义/展开/物化/更新）、事务、完整性约束（外键/级联/断言/延迟检查）、数据类型与域、索引、授权（GRANT/REVOKE/角色/视图授权），13 道例题 | join, view, transaction, integrity constraint, index, authorization, role |
| 5 | [[Ch5 Advanced SQL]] | 高级 SQL 五大块：从程序访问 SQL（JDBC/SQLJ/ODBC/游标、SQL 注入与 PreparedStatement、元数据）、函数与存储过程、触发器（行级/语句级/风险）、递归查询（传递闭包与不动点）、高级聚合与 OLAP（排名族、窗口框架、CUBE/ROLLUP/GROUPING、MOLAP/ROLAP/HOLAP），13 道例题 | JDBC, SQL injection, cursor, trigger, recursive query, window function, CUBE, ROLLUP, OLAP |
| 6 | [[Ch6 数据库设计与E-R模型（E-R Model）]] | 数据库设计与 E-R 模型：设计三阶段与两大陷阱、E-R 基本元素（实体/关系/属性四类）、约束（映射基数、参与、l..h、三元箭头）、主键与弱实体集、E-R→关系模式转换（复合/多值属性、冗余消除）、扩展特性（特化/概化、完整性约束、聚合）、设计问题与 E-R/UML 记号，12 道例题 | E-R model, entity set, relationship, cardinality, weak entity, specialization, aggregation, UML |
| 7 | [[Ch7 规范化（Normalization）]] | 从教师与院系冗余引出规范化，按直觉—定义—手算串联函数依赖、键与闭包、无损与依赖保持、BCNF/3NF、正则覆盖和分解算法，展开 3NF 正确性证明、MVD/4NF 与时态设计，12 道详细例题 | normalization, functional dependency, attribute closure, lossless join, dependency preservation, BCNF, 3NF, canonical cover, MVD, 4NF, temporal data |

---

## 📁 Python (7 篇)

> Python 编程语言学习笔记，涵盖核心语法、高级特性与实用模块。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[Python/Function]] | 函数定义、参数类型、返回值、作用域 | function, arguments, scope |
| 2 | [[Python/Higher-Order Functions]] | 高阶函数：map/filter/reduce、lambda 表达式、闭包 | higher-order functions, lambda, closure |
| 3 | [[Python/Decorator]] | 装饰器原理、语法糖、带参数装饰器、应用场景 | decorator, wrapper, functools |
| 4 | [[Python/With Open]] | 上下文管理器、文件操作、with 语句原理 | context manager, file I/O, with statement |
| 5 | [[Python/CSV]] | CSV 文件读写、DictReader/DictWriter | CSV, data processing |
| 6 | [[Python/Matplot]] | Matplotlib 绘图基础：折线图、散点图、柱状图、子图 | matplotlib, visualization, plotting |
| 7 | [[Python/Environments]] | Python 虚拟环境：venv、pip、依赖管理 | virtual environment, pip, dependencies |

---

## 📁 Algorithm — 算法与数据结构 (16 篇)

> 算法与数据结构学习笔记，覆盖算法设计与分析基础、排序、图论、线性表、字符串与常用技巧。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[Chapter 1 基础知识]] | 算法设计与分析基础：算法特征、分类、分析方法、渐近表示、数学基础 | algorithm basics, analysis, asymptotic notation, recursion |
| 2 | [[进制转换]] | 进制转换方法与实现 | number base conversion |
| 3 | [[欧拉筛]] | 线性筛法求素数 | prime sieve, Euler sieve |
| 4 | [[单调栈]] | 单调栈原理与应用（下一个更大元素等） | monotonic stack |
| 5 | [[String]] | 字符串算法：KMP、字符串哈希等 | string, KMP, hashing |
| 6 | [[Graph]] | 图论算法：最短路、最小生成树、拓扑排序等 | graph, shortest path, MST, topological sort |
| 7 | [[Exchange Sort]] | 交换排序：冒泡排序、快速排序 | bubble sort, quick sort |
| 8 | [[Insertion Sort]] | 插入排序：直接插入、希尔排序 | insertion sort, shell sort |
| 9 | [[Selection Sort]] | 选择排序：简单选择、堆排序 | selection sort, heap sort |
| 10 | [[Merge Sort]] | 归并排序：递归与非递归实现 | merge sort, divide and conquer |
| 11 | [[Radix Sort]] | 基数排序：LSD/MSD | radix sort, counting sort |
| 12 | [[Bucket Sort]] | 桶排序：分桶 + 桶内排序 | bucket sort |
| 13 | [[C++ sort()函数]] | C++ STL sort 函数用法与原理 | STL sort, comparator |
| 14 | [[Sequence List]] | 顺序表：动态数组实现与操作 | sequence list, dynamic array |
| 15 | [[Linked List]] | 链表：单向/双向/循环链表及操作 | linked list, operations |
| 16 | [[算法设计/Chapter 2 分治策略]] | 第 2 章全部 114 页：递归与分治分析、排序及逆序对、芯片测试、快速幂、整数三乘法与 Strassen、最近点对预排序、锦标赛与最坏线性选择、单位根求值及凸包；16 道例题 | divide and conquer, recursion, recurrence, merge sort, inversions, chip testing, quicksort, fast power, Strassen, closest pair, tournament, median of medians, FFT, convex hull |

---

## 📁 HTML (2 篇)

> Web 基础：HTML 标签、CSS 布局、网络协议入门。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[HTML/HTML]] | HTML 标签、表单、CSS 基础、页面布局 | HTML, CSS, forms, layout |
| 2 | [[HTML/IP, TCP, DNS....]] | 网络协议基础：IP 地址、TCP 连接、DNS 解析 | networking, IP, TCP, DNS |

---

## 📁 C Language (1 篇)

> C 语言入门基础知识。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[Basic Knowledge]] | C 语言基本语法：数据类型、控制流、函数、指针基础 | C language, syntax, pointers |

---

## 📁 CN — 计算机网络 (5 篇)

> 计算机网络（Kurose & Ross 自顶向下方法）：从应用层到传输层，覆盖协议原理、套接字编程与实验。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[CN/Ch1 简介]] | 网络构成（主机/交换机/链路）、网络边缘与网络核心、分组交换 vs 电路交换（转发/路由）、性能四时延与流量强度、吞吐量与瓶颈链路、五层协议栈 | network edge/core, packet switching, circuit switching, forwarding vs routing, delay, traffic intensity, throughput, bottleneck link, protocol layering |
| 2 | [[CN/Ch2 应用层]] | 应用体系结构（C/S vs P2P）、进程与套接字、HTTP（持续/非持续连接、报文格式、状态码、Cookie、Web 缓存、HTTP/1.1→3）、SMTP/IMAP、DNS（层次结构、资源记录、迭代 vs 递归）、P2P（BitTorrent 一报还一报）、CDN 与 DASH、UDP/TCP 套接字编程 | application architecture, socket, HTTP, persistent connection, cookie, web cache, conditional GET, SMTP, IMAP, DNS, resource record, P2P, BitTorrent, tit-for-tat, CDN, DASH, socket programming |
| 3 | [[CN/Ch3 传输层]] | 传输层服务与逻辑通信、多路复用/分解（UDP 二元组 vs TCP 四元组）、UDP（报文段结构、反码和检验和、伪首部、弱保护）、可靠数据传输原理（rdt1.0→3.0、GBN、SR 与窗口窘境、停等性能与流水线）、TCP（报文段结构、字节序号与累积确认、RTT 估计与超时、快速重传、流量控制 rwnd、三次握手/四次挥手、TIME_WAIT）、拥塞控制原理（三种情形与代价）、TCP 拥塞控制（AIMD、慢启动、ssthresh、快速恢复、CUBIC、BBR、ECN、公平性）；42 条易错点表 + 12 道高难例题 | transport layer, multiplexing/demultiplexing, UDP, checksum, one's complement, reliable data transfer, rdt, stop-and-wait, pipelining, GBN, selective repeat, sliding window, TCP, sequence number, cumulative ACK, RTT estimation, Karn's algorithm, fast retransmit, flow control, rwnd, three-way handshake, four-way teardown, TIME_WAIT, congestion control, AIMD, slow start, ssthresh, fast recovery, CUBIC, BBR, ECN, fairness |
| 4 | [[CN/Lab1 IPv4]] | IPv4 地址与子网划分实验：地址分类、子网掩码、CIDR、分组转发与路由表 | IPv4, subnetting, subnet mask, CIDR, routing table |
| 5 | [[CN/Lab2 路由器]] | 路由器实验（待补充） | router, lab |

---

## 📁 FA — 形式语言与自动机 (4 篇)

> 形式语言与自动机基础：DFA、NFA 与 ε-NFA 的定义、状态设计和语言接受，子集构造、ε-闭包与等价性证明，以及正则表达式和有限自动机的双向转换。

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[FA/Ch1 DFA]] | DFA 基础：字母表、字符串与语言，五元组与扩展转移函数，状态图/转移表、语言接受、构造技巧和等价证明 | DFA, alphabet, string, language, transition function, regular language |
| 2 | [[FA/Lecture_1_DFA]] | Lecture 1 深入讲解：有限状态的记忆本质、DFA 三种表示、典型模式与余数自动机、双向包含证明及编程实现 | finite automaton, DFA design, state invariant, induction, divisibility automaton |
| 3 | [[FA/Ch2 NFA 与 ε-NFA]] | 第二章全部 38 页：非确定性接受语义、棋盘 NFA 与完整子集构造、归纳等价证明、ε-闭包与扩展转移、前置闭包消除 ε 及接受状态修正、两条确定化路线；10 道自拟例题与速查表 | NFA, epsilon-NFA, subset construction, epsilon closure, extended transition, equivalence proof, state complexity |
| 4 | [[FA/Ch3 正则表达式（Regular Expressions）]] | 正则表达式的递归语义与模式构造，Thompson 法 RE→ε-NFA，GNFA 状态消除与 k-path 动态规划完成 DFA→RE，并含代数法则和 8 道例题 | regular expression, regular language, Thompson construction, epsilon-NFA, GNFA, state elimination, k-path |

---

## 📁 数理逻辑 (4 篇)

> 命题逻辑课程笔记，涵盖语法与语义、真值函数和联结词完备集、自然演绎及其可靠性与完备性，以及公式范式、Horn 逻辑和 SAT 求解与建模.

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[数理逻辑/Chapter 2 命题逻辑的语法与语义]] | 第二讲全部 31 页：递归语法与最小性、语法树、结构归纳、权重与唯一可读性、子公式计数、语义和后承、等值置换、全部一元与二元函数、完备集与不变量反证；6 道补充例题 | syntax, semantics, structural induction, unique readability, subformula, logical equivalence, entailment, truth function, functional completeness, NOR |
| 2 | [[数理逻辑/Chapter 3 命题逻辑自然演绎系统]] | 第三讲全部 28 页：语法与语义、全部基本规则、方框及假设解除，5 项导出规则证明、4 道课件例题、2 道练习及 5 个反模型；推导逐行注明作用域 | natural deduction, inference rule, assumption discharge, proof scope, MT, PBC, LEM, DS, countermodel |
| 3 | [[数理逻辑/Chapter 4 命题逻辑自然演绎系统的可靠性和完备性]] | 第四讲全部 35 页：两类归纳、无子证明与一般可靠性、逐行上下文、真值赋值引理、消除文字假设和有限前提完备性；补全合取情形并说明无穷前提范围 | soundness, completeness, strong induction, structural induction, proof context, truth assignment lemma, finite premises |
| 4 | [[数理逻辑/Chapter 5 命题逻辑范式和 SAT 求解器]] | 第五讲全部 36 页：NNF/CNF/DNF 的定义、等值转换与存在性证明，主范式与完整真值表，Horn 标记算法及正确性和线性实现条件，SAT 与 P/NP，DPLL、GSAT 和 N 皇后完整编码；7 道补充或展开例题 | normal form, CNF, DNF, NNF, minterm, maxterm, Horn-SAT, least model, NP-completeness, DPLL, GSAT, N-queens |

---

## 📁 最优化理论 (6 篇)

> 按授课课件逐次整理最优化理论，分别维护每次课的定义、证明、习题与材料覆盖.

| # | 笔记 | 摘要 | 核心主题 |
|---|------|------|----------|
| 1 | [[最优化理论/第 1 次课 绪论与基础知识]] | 2026-09-07 课件全部 27 页：四类建模案例、向量与矩阵范数、不等式证明、梯度与 Hessian、Taylor 展开及优化基本概念，含 6 道补充例题 | optimization modeling, norm, least squares, RPCA, gradient, Hessian, Taylor expansion, local and global optimum |
| 2 | [[最优化理论/第 2 次课 算法评价、收敛速度与凸集]] | 2026-09-14 课件全部 21 页：迭代框架、Q/R 收敛及反例、复杂度、凸集/仿射集/凸锥与三种包、超平面/半空间/范数球，含全部三页习题及思考题解析 | convergence, Q-convergence, R-convergence, complexity, convex set, affine set, convex cone, convex hull, hyperplane, norm ball |
| 3 | [[最优化理论/第 3 次课 凸集的保凸运算与凸函数]] | 2026-09-21 课件全部 16 页：范数球与椭球、多面体与单纯形、矩阵凸锥、交集和仿射像/逆像等保凸运算；凸/严格凸/强凸与凹性定义，含四页习题、核心证明及两处勘误 | ellipsoid, simplex, positive semidefinite cone, affine image, preimage, convex function, strict convexity, strong convexity |
| 4 | [[最优化理论/第 4 次课 凸函数的一阶与二阶条件]] | 2026-09-28 课件全部 8 页：正无穷扩展与示性函数、凸/严格凸/凹/强凸的一阶条件、驻点最优性与梯度单调性、Hessian 判据及二次函数分类；补足证明、域条件及反例，含 4 道例题解析 | extended-real function, indicator function, first-order condition, gradient monotonicity, Hessian, strong convexity, quadratic function |
| 5 | [[最优化理论/第 5 次课 常见凸函数、保凸运算与共轭函数]] | 2026-10-12 课件全部 27 页：幂函数、负对数与熵、范数、最大值及 log-sum-exp、负对数行列式；加权和/仿射/上确界/单调复合、共轭三例与次水平集，含全部三页习题及边界辨析 | log-sum-exp, log determinant, convexity-preserving operations, composition, conjugate function, sublevel set |
| 6 | [[最优化理论/第 6 次课 凸优化问题、最优性条件与典型模型]] | 2026-10-19 课件全部 23 页：域与解集、凸优化局部/全局性质、可行方向与变分不等式、等式/非负约束最优性、LP 标准化及 QP/QCQP、投资组合均值—方差建模；7 节详细例题与思考题解析，修正价格因子等条件 | convex optimization, feasible direction, variational inequality, complementarity, LP standard form, QP, QCQP, mean-variance model |

---

## 🗺️ 附录：跨学科主题索引

以下主题在多个学科中均有涉及，方便交叉查阅：

| 主题 | C++ Language | OS | DC | AI |
|------|:--:|:--:|:--:|:--:|
| **并发/同步** | — | [[Ch7 进程同步（Process Synchronization）\|Ch7]], [[Ch8 — 并发：死锁与饥饿（Deadlock & Starvation\|Ch8]] | — | — |
| **内存管理** | [[Chapter 3 类\|Ch3]] (new/delete) | [[Ch9 物理内存管理\|Ch9]], [[Ch10 虚拟内存管理\|Ch10]] | — | — |
| **状态机** | — | — | [[Chapter8 计数器\|Ch8]] | [[第16讲 强化学习——决策智能\|L16]] (MDP) |
| **抽象/分层** | [[Chapter 5 继承与派生（Inheritance & Derivation）\|Ch5]] | [[Ch2 操作系统结构\|Ch2]], [[Ch13 文件系统\|Ch13]] | — | — |
| **调度/决策** | — | [[Ch6 进程调度\|Ch6]] | — | [[第8讲 高级搜索算法\|L8]], [[第16讲 强化学习——决策智能\|L16]] |

---

> [!tip] 使用方式
> - **查询时**：先扫本索引找到相关笔记，再用 Wiki-link 钻入详细内容
> - **新增笔记时**：在此索引中添加对应条目，保持索引同步
> - **健康检查**：定期检查是否有孤立笔记（在此索引中无条目）或索引断裂（链接指向不存在的文件）
