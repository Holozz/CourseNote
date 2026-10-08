# Section 1 朴素贝叶斯预测
## 流程
- **数据**：从 `spam.csv` 读取短信文本，按 `ham` / `spam` 标签分类存放
- **划分**：`train_test_split` 按 80/20 划分，`stratify=labels` 保证训练集与测试集中类别比例一致，`random_state=10` 固定可复现
- **向量化**：将文本转为数值特征矩阵 — 词频（`CountVectorizer`）、TF-IDF 加权（`TfidfVectorizer`）、二元出现（`CountVectorizer(binary=True)`）
- **训练**：分别用 `MultinomialNB` 和 `BernoulliNB` 拟合，拉普拉斯平滑 $\alpha=0.5$
- **预测**：用训练好的模型对测试集进行类别推断
- **评估**：输出准确率、精确率、召回率、F1 分数及混淆矩阵，并绘制三种方案对比图
## 实验原理
1. 朴素贝叶斯分类器
	基于贝叶斯定理和特征条件独立假设的分类方法。对于给定的文本，计算它属于每个类别的后验概率，选择概率最大的类别作为预测结果。
	1. 贝叶斯定理
		对于类别 $C$ 和特征向量 $X = (x_1, x_2, ..., x_n)$：
		$$P(C|X) = \frac{P(X|C) \cdot P(C)}{P(X)}$$
		由于 $P(X)$ 对所有类别相同，只需要比较分子部分：
		$$\hat{C} = \arg\max_C P(C) \prod_{i=1}^{n} P(x_i|C)$$
	2. "朴素"假设
		假设所有特征词之间相互独立，这在现实中不成立，但朴素贝叶斯在文本分类任务中仍然表现良好。
	3. 拉普拉斯平滑
		为防止某个词在训练集中未出现过导致 $P(x_i|C) = 0$，在计算条件概率时加入平滑参数 $\alpha$：
		$$P(x_i|C) = \frac{\text{count}(x_i, C) + \alpha}{\sum_j \text{count}(x_j, C) + \alpha \cdot |V|}$$
		其中 $|V|$ 为词表大小，$\alpha$ 取 0 到 1 之间的值
2. 两种朴素贝叶斯
	1. 多项式朴素贝叶斯 (MultinomialNB)
		将文本视为词频向量，每个特征值是该词在文档中出现的次数。适用于考虑词频的场景，通常对长文本效果更好
		条件概率估计：
		$$P(x_i|C) = \frac{N_{i,C} + \alpha}{N_C + \alpha \cdot n}$$
		其中 $N_{i,C}$ 是词 $i$ 在类别 $C$ 中出现的总次数，$N_C$ 是类别 $C$ 中所有词的总数。
	2. 伯努利朴素贝叶斯 (BernoulliNB)
		使用 `BernoulliNB` 时，特征与模型假设匹配，例如对 `CountVectorizer` 使用 **`binary=True`** 得到 0/1 词向量，再训练 `BernoulliNB`；保持其它预处理一致以便公平对比
		将文本视为二元向量，每个特征值只能是 0 或 1，分别表示该词是否在文档中出现。适合短文本（如短信、推文），只关心词是否出现而非出现次数。
		条件概率估计：
		$$P(x_i|C) = \frac{D_{i,C} + \alpha}{D_C + 2\alpha}$$
		其中 $D_{i,C}$ 是类别 $C$ 中包含词 $i$ 的文档数，$D_C$ 是类别 $C$ 的总文档数。
3. 文本特征提取
	1. CountVectorizer（词频向量）
		统计每个词在文档中出现的次数，生成词频矩阵。最简单直接的特征表示方式。
	2. TfidfVectorizer（TF-IDF 加权）
		在词频基础上乘以逆文档频率（IDF），降低常见词（如 "the", "a"）的权重，提升稀有但具区分度的词的权重：
		$$\text{TF-IDF}(t, d) = \text{TF}(t, d) \times \log\frac{N}{\text{DF}(t)}$$
		其中 $\text{TF}(t,d)$ 是词 $t$ 在文档 $d$ 中的词频，$N$ 是文档总数，$\text{DF}(t)$ 是包含词 $t$ 的文档数。
	3. CountVectorizer (binary=True)（二元出现向量）
		将词频大于 0 的都记为 1，只保留"出现/未出现"信息，与 BernoulliNB 配套使用。
## 伪代码
```python
main():
    //数据加载
    Ham, Spam ← 从 CSV 文件中逐行读取，按标签分类
    统计标签分布并打印

    //数据合并与划分
    messages ← Ham + Spam                    // 合并所有消息
    labels   ← ['ham']×len(Ham) + ['spam']×len(Spam)   // 对应标签
    X_train, X_test, y_train, y_test ← train_test_split(
        messages, labels, test_size=0.2, stratify=labels, random_state=10
    )                                         // 分层采样，保持训练/测试集标签比例一致

    //方案一：TF-IDF + MultinomialNB
    vectorizer ← TfidfVectorizer()
    X_train_tfidf ← vectorizer.fit_transform(X_train)    // 拟合并转换训练集
    model ← MultinomialNB(alpha=0.5)
    model.fit(X_train_tfidf, y_train)                    // 训练
    y_pred ← model.predict(vectorizer.transform(X_test)) // 预测
    打印 accuracy, classification_report

    //方案二：词频 CountVectorizer + MultinomialNB
    vectorizer ← CountVectorizer()
    X_train_counts ← vectorizer.fit_transform(X_train)
    model ← MultinomialNB(alpha=0.5)
    model.fit(X_train_counts, y_train)
    y_pred ← model.predict(vectorizer.transform(X_test))
    打印混淆矩阵, accuracy, classification_report

    //方案三：二元 CountVectorizer + BernoulliNB
    vectorizer ← CountVectorizer(binary=True)
    X_train_bin ← vectorizer.fit_transform(X_train)
    model ← BernoulliNB(alpha=0.5)
    model.fit(X_train_bin, y_train)
    y_pred ← model.predict(vectorizer.transform(X_test))
    打印 accuracy, classification_report

    //结果对比可视化
    绘制 MultinomialNB 与 BernoulliNB 的混淆矩阵对比图（左右并列）
    绘制精确率、召回率、F1 分数的分组柱状图
```

## 代码展示
- 数据加载，读取时只取有效行；并划分训练集和测试集（ **80% / 20%**）
	```python
	def readFile(filename):
	    Ham = []
	    Spam = []
	    with open(filename, mode='r', encoding='latin-1') as file:
	        csv_reader = csv.reader(file)
	        next(csv_reader)
	        for line in csv_reader:
	            if line[0] == 'ham' and line[1]:
	                Ham.append(line[1])
	            if line[0] == 'spam' and line[1]:
	                Spam.append(line[1])
	    """统计标签分布"""
	    label_counts = Counter({'ham': len(Ham), 'spam': len(Spam)})
	    print("标签分布:", label_counts)

	    messages = Ham + Spam
	    labels = ['ham'] * len(Ham) + ['spam'] * len(Spam)

	    """
	    train_test_split 做分层抽样
	    确保训练集和测试集中 ham/spam 的比例一致
	    random_state 固定随机种子
	    """
	    X_train, X_test, y_train, y_test = train_test_split(
	        messages, labels, test_size=0.2,
	        random_state=10, stratify=labels
	    )
	    return X_train, y_train, X_test, y_test
	```
- TF-IDF的多项式朴素贝叶斯
	```python
	def TfidTrain(X_train, y_train):
	    """
	    TfidfVectorizer 将原始文本转为 TF-IDF 特征矩阵。
	    TF-IDF = 词频 × 逆文档频率，以降低高频无意义词的权重。
	    MultinomialNB 以 TF-IDF 权重作为多项式分布的依据。
	    alpha=0.5 是拉普拉斯平滑参数，防止零概率问题。
	    """
	    vectorizer = TfidfVectorizer()
	    X_train_tfidf = vectorizer.fit_transform(X_train)
	    model = MultinomialNB(alpha=0.5)
	    model.fit(X_train_tfidf, y_train)
	    return vectorizer, model

	def TfidTest(vectorizer, model, X_test, y_test):
	    X_test_tfidf = vectorizer.transform(X_test)
	    y_pred = model.predict(X_test_tfidf)
	    print("预测结果:", y_pred)
	    print("准确率:", accuracy_score(y_test, y_pred))
	    print("分类报告:\n", classification_report(
	        y_test, y_pred, target_names=['ham', 'spam']
	    ))
	    return y_pred
	```
- 词频特征的多项式朴素贝叶斯
	```python
	def MultinomialTrain(X_train, y_train):
	    """
	    CountVectorizer 统计每个词在文档中的出现次数，生成词频矩阵
	    与 TF-IDF 不同，不对词的重要性进行加权，所有词一视同仁
	    MultinomialNB 直接基于词频建模
	    """
	    vectorizer = CountVectorizer()
	    X_train_counts = vectorizer.fit_transform(X_train)
	    model = MultinomialNB(alpha=0.5)
	    model.fit(X_train_counts, y_train)
	    return vectorizer, model

	def MultinomialTest(vectorizer, model, X_test, y_test):
	    X_test_counts = vectorizer.transform(X_test)
	    y_pred = model.predict(X_test_counts)
	    """混淆矩阵："""
	    cm = confusion_matrix(y_test, y_pred, labels=['ham', 'spam'])
	    print("混淆矩阵:")
	    print("           预测ham  预测spam")
	    print(f"真实ham    {cm[0][0]:>6}    {cm[0][1]:>6}")
	    print(f"真实spam   {cm[1][0]:>6}    {cm[1][1]:>6}")
	    print("准确率:", accuracy_score(y_test, y_pred))
	    print("分类报告:\n", classification_report(
	        y_test, y_pred, target_names=['ham', 'spam']
	    ))
	    return y_pred
	```
- 二元特征的伯努利朴素贝叶斯
	```python
	def BernoulliTrain(X_train, y_train):
	    """CountVectorizer(binary=True)生成二元特征矩阵"""
	    vectorizer = CountVectorizer(binary=True)
	    X_train_counts = vectorizer.fit_transform(X_train)
	    model = BernoulliNB(alpha=0.5)
	    model.fit(X_train_counts, y_train)
	    return vectorizer, model

	def BernoulliTest(vectorizer, model, X_test, y_test):
	    X_test_counts = vectorizer.transform(X_test)
	    y_pred = model.predict(X_test_counts)
	    print("准确率:", accuracy_score(y_test, y_pred))
	    print("分类报告:\n", classification_report(
	        y_test, y_pred, target_names=['ham', 'spam']
	    ))
	    return y_pred
	```
## 创新点
1. 使用**三种方案**（TF-IDF多项式、词频多项式、二元特征伯努利）进行对比实验，在扩展任务之外还额外用了TFIDF方案
2. 使用**分层抽样**（`stratify=labels`）划分训练集和测试集，使训练集和测试集中 ham/spam 的比例一致，避免因划分不均导致评估偏差
3. 固定**随机种子**（`random_state=10`），保证每次运行的数据划分和模型结果可完全复现
4. 使用**拉普拉斯平滑**（$\alpha=0.5$），避免某些词因在训练集中未出现而导致条件概率为零的问题
5. 通过**混淆矩阵**表格和 sklearn 的 `ConfusionMatrixDisplay` 两种方式展示分类结果
6. 绘制分组**柱状图**直观对比 MultinomialNB 与 BernoulliNB 在精确率、召回率和 F1 分数上的差异，并在柱顶标注具体数值
7. 实现了**扩展任务A和B**
## 实验结果
- 包括了**扩展任务A**，使用对比图将两种结果一并展示；所示结果均为**测试集数据**
- 混淆矩阵：
	![[屏幕截图 2026-06-03 094845.png|600]]
- 性能评估：展示了整体准确率，以及分类报告各项数据
	- 考虑到短信数据集中 ham 与 spam 的类别不均衡问题，仅看准确率会掩盖对少数类（spam）的识别能力；若垃圾短信的 Recall 偏低，大量 spam 会被漏判为正常短信进入用户收件箱，导致用户体验下降甚至遭遇钓鱼诈骗的风险
	![[屏幕截图 2026-06-03 094930.png|600]]
	![[屏幕截图 2026-06-03 094856 1.png|600]]
	- 对比表格
	
| ($\alpha=0.5$) | Accuracy | Precision | Recall | F1   |
| -------------- | -------- | --------- | ------ | ---- |
| Multinomial    | 0.9928   | 0.99      | 0.99   | 0.99 |
| Bernoulli      | 0.9848   | 0.98      | 0.98   | 0.98 |
- **扩展任务B**：准确率下图所示（随$\alpha$变化）
	- $\alpha=0.01$
		![[Pasted image 20260603110044.png|400]]
	- $\alpha=0.1$
		![[Pasted image 20260603105541.png|400]]
	- $\alpha=1$
		![[Pasted image 20260603105910.png|400]]
	- $\alpha=10$
		![[Pasted image 20260603110000.png|400]]
	- 当 $\alpha \to 0$ 时，平滑几乎消失，未出现过的词的条件概率趋近于 0，模型容易因零概率问题而对未见词过度敏感、泛化能力下降；当 $\alpha$ 过大时，所有词的概率被强行拉向均匀分布，模型退化为"记不住任何有区分度的词"，出现**过平滑**，丧失分类能力
# Section 2 感知机
## 实验原理
1. 数据预处理：加载CSV文件，得到数值矩阵
	1. 数据去噪：去掉明显极端的数值
	2. 标准化房价
	3. 补全各项特征中的缺失值：文本就填None，数值就填中位数
	4. 将文本特征转为数值
	5. 把每个特征都调整到均值为0方差为1，标准化
2. 多层感知机模型
	1. 激活函数
		使用ReLU函数作为激活函数，表达式为$$\mathrm{Re}LU(x)=max(0, x)$$，计算比较简单，而且不会梯度消失；同时此问题里参数范围均标准化，不存在神经元死亡现象
	2. 参数初始化
		使用He初始化，表达式为$$w=\sqrt{ \frac{2}{n} }*rand(n,nm)$$这里n是输入层神经元个数，m是输出层神经元个数
		
	3. 损失函数
		使用MSE误差，表达式为$$L = \frac{1}{m}\sum_{j=1}^{m}(\hat{y}_j - y_j)^2$$
	4. 正向传播
		公式为$$\begin{align}&Z_{n}=A_{n-1}W_{n}+b_{n}\\&A_{n}=\mathrm{Re}LU(Z_{n})\\&\hat{y}=Z_{3}\end{align}$$
	5. 反向传播
		第 $i$ 层（$i=1,2$）先过 ReLU 的导数：$$\delta_i = dZ_i = dA_i \odot \text{ReLU}'(Z_i)$$$$dW_i = \delta_i \cdot A_{i-1}^T + \lambda \cdot W_i$$$$db_i = \sum \delta_i \quad (\text{按行求和})$$$$dA_{i-1} = W_i^T \cdot \delta_i$$
		梯度裁剪 $$\text{if } |dW_i| > \text{clip}, \quad dW_i = dW_i \times\frac{\text{clip}}{|dW_i|}$$
		参数更新 $$W_i \leftarrow W_i - \eta \cdot dW_i$$  $$b_i \leftarrow b_i - \eta \cdot db_i$$
## 伪代码
```python
main():
      // [1] 数据加载与预处理
      X_train, y, X_test, test_ids, y_mean, y_std ← load_and_preprocess()
      打印数据维度信息
      // 划分训练集/验证集 (80% / 20%)
      X_tr, X_val, y_tr, y_val ← train_test_split(X_train, y, test_size=0.2)
      // [2] 构建模型
      mlp ← MLP(layer_sizes=[input_dim, 64, 32, 1], lr=0.01, grad_clip=5.0,
  weight_decay=0.003)
      打印网络结构和参数数量
      // [3] 训练
      history ← mlp.train(X_tr, y_tr, X_val, y_val, epochs=500, batch_size=64)
      // [4] 验证集评估（还原到原始价格）
      y_val_pred ← mlp.predict(X_val)
      y_val_real ← exp(y_val × y_std + y_mean)       // 逆标准化 → 逆log
      y_val_pred_real ← exp(y_val_pred × y_std + y_mean)
      计算 MAE, RMSE 并打印
      // [5] 过拟合分析
      计算 val_loss / train_loss 比值
      根据比值判断过拟合程度: LOW / MILD / MODERATE / SEVERE
      // [6] 画图
      左图: 训练损失 & 验证损失曲线，标记最佳轮次
      右图: 预测值 vs 真实值散点图
      // [7] 生成提交文件
      y_test_pred ← mlp.predict(X_test)
      y_test_pred_real ← exp(y_test_pred × y_std + y_mean)
      保存为 submission.csv
  数据预处理
load_and_preprocess():
      train_raw ← pd.read_csv("train.csv")
      test_raw  ← pd.read_csv("test.csv")
      test_ids  ← test_raw["Id"]

      // 去噪 —— 移除异常样本
      移除 GrLivArea > 4000 的样本
      移除 LotArea > 100000 的样本
      移除 SalePrice 在 log 尺度上偏离均值 > 3σ的样本
      移除 TotalBsmtSF > 3000 的样本

      // 处理目标值
      y_log ← log(train_raw["SalePrice"])
      y ← (y_log - mean(y_log)) / std(y_log)         // 标准化到均值0方差1

      // 特征预处理
      X_train_raw ← train_raw 去掉 Id 和 SalePrice 列
      X_test_raw  ← test_raw  去掉 Id 列

      all_data ← 合并 X_train_raw 和 X_test_raw      // 保证编码一致
      数值列: 缺失值填中位数
      类别列: 缺失值填 "None"
      高基数类别列 (>10种):  标签编码 (字符串 → 整数)
      低基数类别列 (≤10种):  One-Hot 编码
      拆回训练集和测试集
      StandardScaler 标准化 (均值0, 方差1)
      转置 X 为 (特征数, 样本数)   // 方便 W @ X 矩阵乘法
      返回 X_train, y, X_test, test_ids, y_mean, y_std
MLP 类:
__init__(layer_sizes, lr, grad_clip, weight_decay, seed):
          self.lr ← lr
          self.grad_clip ← grad_clip
          self.weight_decay ← weight_decay
          self.rng ← RandomState(seed)
          self.params, self.cache ← 空字典
          self.num_layers ← len(layer_sizes) - 1
          for i in 0 .. num_layers-1:
              n_in  ← layer_sizes[i]
              n_out ← layer_sizes[i+1]
              W ← randn(n_out, n_in) × sqrt(2.0 / n_in)    // He 初始化
              b ← zeros(n_out, 1)
      // ---------- 激活函数 ----------
      relu(Z):  return max(0, Z)
      relu_derivative(Z):  return (Z > 0) 转为浮点数
      // ---------- 前向传播 ----------
forward(X):
          A ← X
          cache["A0"] ← A
          for i in 1 .. num_layers:
              Z ← W[i] @ A + b[i]
              cache["Z" + i] ← Z
              if i == num_layers:          // 输出层: 线性
                  A ← Z
              else:                         // 隐藏层: ReLU
                  A ← relu(Z)
              cache["A" + i] ← A
          return A
      // ---------- 反向传播 ----------
backward(X, y):
          m ← X 的样本数
          y_hat ← cache["A" + num_layers]
          // MSE 损失
          diff ← y_hat - y
          mse_loss ← mean(diff²)
          // MSE 对输出的梯度
          dA ← (2.0 / m) × diff
          for i in num_layers .. 1:
              A_prev ← cache["A" + (i-1)]
              Z     ← cache["Z" + i]
              W     ← params["W" + i]
              if i == num_layers:           // 输出层: 无激活函数
                  dZ ← dA
              else:                          // 隐藏层: ReLU 导数
                  dZ ← dA × relu_derivative(Z)
              // 权重梯度 + L2 正则化
              dW ← dZ @ A_prev.T + weight_decay × W
              db ← sum(dZ, axis=1)
              // 梯度裁剪
              if norm(dW) > grad_clip:
                  dW ← dW × grad_clip / norm(dW)
              // 梯度传回上一层
              dA ← W.T @ dZ
              // SGD 更新
              W[i] ← W[i] - lr × dW
              b[i] ← b[i] - lr × db
          return mse_loss
      // ---------- 训练 ----------
train(X, y, X_val, y_val, epochs, batch_size, lr_decay, decay_step,early_stop_patience):
          n_samples ← X 的样本数
          best_val_loss ← +∞
          patience_counter ← 0

          for epoch in 0 .. epochs-1:
              // 打乱数据
              perm ← 随机排列(0 .. n_samples-1)
              X_shuffled ← X[:, perm]
              y_shuffled ← y[:, perm]
              epoch_loss ← 0
              // Mini-batch 遍历
              for start in 0, batch_size, 2×batch_size, ...:
                  X_batch ← X_shuffled[:, start : start+batch_size]
                  y_batch ← y_shuffled[:, start : start+batch_size]
                  forward(X_batch)
                  loss ← backward(X_batch, y_batch)
                  epoch_loss ← epoch_loss + loss × 批量大小
              epoch_loss ← epoch_loss / n_samples
              // 验证集评估
              if X_val 存在:
                  y_pred_val ← forward(X_val)
                  val_loss ← mean((y_pred_val - y_val)²)
                  if val_loss < best_val_loss:
                      best_val_loss ← val_loss
                      best_epoch ← epoch
                      patience_counter ← 0
                      保存当前权重到 best_params
                  else:
                      patience_counter ← patience_counter + 1
              // 学习率衰减
              if (epoch+1) % decay_step == 0:
                  lr ← lr × lr_decay
              // 打印日志 (每 50 轮)
              // 早停
              if patience_counter >= early_stop_patience:
                  恢复到 best_params
                  break
          return history
      predict(X):
          return forward(X)
```
## 代码展示
- 数据预处理
	```python
	def load_and_preprocess():
	    train_raw = pd.read_csv("train.csv")
	    test_raw = pd.read_csv("test.csv")
	  
	    """保留测试集的ID"""
	    test_ids = test_raw["Id"].copy()
	    """数据去噪 —— 把训练集里明显不合理的极端值样本去掉。"""
	    n_before = len(train_raw)
	    removed_info = []
	    """面积超过 4000 平方英尺但售价极低的房子。"""
	    mask_grliv = train_raw["GrLivArea"] > 4000
	    if mask_grliv.sum() > 0:
	        removed_info.append(f"GrLivArea > 4000: {mask_grliv.sum()} samples")
	    train_raw = train_raw[~mask_grliv]
	    ...
	    
	    """处理目标值 SalePrice：取 log 后接近正态分布，再标准化到均值 0 方差 1，使梯度不会太大或太小。"""
	    y_log = np.log(train_raw["SalePrice"].values).reshape(-1, 1)
	    y = (y_log - y_log.mean()) / y_log.std()
	  
	    """去掉 ID 和 SalePrice，剩下的全是输入特征"""
	    X_train_raw = train_raw.drop(columns=["Id", "SalePrice"])
	    X_test_raw = test_raw.drop(columns=["Id"])
	    """
	    把训练集和测试集合在一起预处理，保证编码一致。
	    比如训练集里有的类别测试集里没有，合在一起就不会漏。
	    """
	    all_data = pd.concat([X_train_raw, X_test_raw], axis=0, ignore_index=True)
	    n_train = len(X_train_raw)
	  
	    """区分哪些列是数值，哪些列是文本类别"""
	    numeric_cols = all_data.select_dtypes(include=["int64", "float64"]).columns.tolist()
	    categorical_cols = all_data.select_dtypes(include=["object"]).columns.tolist()
	    """数值特征：缺失值填中位数;文本特征：缺失值统一填 None"""
	    for col in numeric_cols:
	        all_data[col] = all_data[col].fillna(all_data[col].median())
	    for col in categorical_cols:
	        all_data[col] = all_data[col].fillna("None")
	    """
	    文本转数字
	    类别多的字段（>10 种），用标签编码，直接把每个类别换成一个整数。
	    """
	    high_cardinality = [c for c in categorical_cols if all_data[c].nunique() > 10]
	    for col in high_cardinality:
	        all_data[col] = all_data[col].astype("category").cat.codes
	    """
	    类别少的字段（≤10 种），用one-hot编码
	    """
	    low_card_cols = [c for c in categorical_cols if c not in high_cardinality]
	    all_data = pd.get_dummies(all_data, columns=low_card_cols, drop_first=True)
	    ...
	  
	    """标准化每个特征都调整到均值 0 方差 1。"""
	    scaler = StandardScaler()
	    X_train = scaler.fit_transform(X_train)
	    X_test = scaler.transform(X_test)
	  
	    """检查数据里没有 NaN 或无穷大"""
	    assert not np.any(np.isnan(X_train)), "X_train contains NaN"
	    assert not np.any(np.isinf(X_train)), "X_train contains Inf"
	    """转置成 (特征数, 样本数) 的格式，方便后面矩阵乘法。这样做 W @ X 时，一行就是一个神经元的权重乘所有样本。"""
	    X_train = X_train.T
	    X_test = X_test.T
	    y = y.T
	  
	    return X_train, y, X_test, test_ids, y_log.mean(), y_log.std()
	```
- 前向传播
	```python
	def forward(self, X):
		"""
		前向传播：数据从输入层流向输出层。
		每层做一次线性变换（加权求和）再经过激活函数（引入非线性）。
		同时把中间结果存到 cache 里，供反向传播使用。
		"""
		A = X
		self.cache = {"A0": A}
		for i in range(1, self.num_layers + 1):
			W = self.params[f"W{i}"]
			b = self.params[f"b{i}"]
	
			"""线性变换：每个神经元对上一层所有输出加权求和"""
			Z = W @ A + b
			self.cache[f"Z{i}"] = Z
			if i == self.num_layers:
				"""最后一层直接输出数值"""
				A = Z
			else:
				"""隐藏层用 ReLU 激活，引入非线性"""
				A = self.relu(Z)
			self.cache[f"A{i}"] = A
		return A
	```
- 反向传播
	```python
	def backward(self, X, y):
	        """
	        反向传播：从输出层往回走，用链式法则算出每个参数的梯度。
	        核心思想是算出损失对每个权重的偏导数，告诉每个权重该往哪个方向调。
	        """
	        m = X.shape[1]
	        y_hat = self.cache[f"A{self.num_layers}"]
	        """MSE"""
	        diff = y_hat - y
	        mse_loss = np.mean(diff ** 2)
	        """MSE 对预测值的导数: dL/dy_hat = 2*(y_hat - y) / m"""
	        dA = (2.0 / m) * diff
	        """从最后一层往第一层逐层计算梯度"""
	        for i in range(self.num_layers, 0, -1):
	            A_prev = self.cache[f"A{i-1}"]
	            Z = self.cache[f"Z{i}"]
	            W = self.params[f"W{i}"]
	            if i == self.num_layers: dZ = dA
	            else: dZ = dA * self.relu_derivative(Z)
	            """
	            权重的梯度 = dZ 乘以上一层的输出（链式法则）。
	            额外加上 L2 正则化的梯度 weight_decay * W，推动所有权重向 0 靠近，防止某个权重过大导致过拟合。
	            """
	            dW = dZ @ A_prev.T + self.weight_decay * W
	            db = np.sum(dZ, axis=1, keepdims=True)
	            """
	            梯度裁剪 —— 如果某一步梯度太大，按比例缩小。
	            防止训练初期梯度爆炸，让训练更稳定。
	            """
	            dW_norm = np.linalg.norm(dW)
	            if dW_norm > self.grad_clip:
	                dW *= self.grad_clip / dW_norm
	            """把梯度继续往上一层传"""
	            dA = W.T @ dZ
	            """沿着梯度的反方向走一小步，让损失下降"""
	            self.params[f"W{i}"] -= self.lr * dW
	            self.params[f"b{i}"] -= self.lr * db
	  
	        return mse_loss
	```
- 训练
	```python
	def train(self, X, y, X_val=None, y_val=None,
	              epochs=500, batch_size=64, lr_decay=0.95, decay_step=50,
	              early_stop_patience=100, verbose=True):
	        """
	        训练过程：把整个训练集反复喂给模型，每次喂一小批（mini-batch），
	        每喂完一轮在验证集上评估，看有没有过拟合。
	        epochs: 训练多少轮
	        batch_size: 每批喂多少个样本，小批量比全量更快，比单个更稳定
	        lr_decay: 学习率衰减系数，每 decay_step 轮乘一次，越往后步长越小
	        early_stop_patience: 验证集上多少轮不进步就提前停止
	        """
	        n_samples = X.shape[1]
	        history = {"train_loss": [], "val_loss": []}
	        best_val_loss = float("inf")
	        patience_counter = 0
	        best_epoch = 0
	  
	        for epoch in range(epochs):
	            """每轮开始前打乱数据顺序，防止模型记住样本顺序"""
	            perm = self.rng.permutation(n_samples)
	            X_shuffled = X[:, perm]
	            y_shuffled = y[:, perm]
	            epoch_loss = 0.0
	            n_total = 0
	            """按批次遍历整个训练集"""
	            for start in range(0, n_samples, batch_size):
	                end = min(start + batch_size, n_samples)
	                X_batch = X_shuffled[:, start:end]
	                y_batch = y_shuffled[:, start:end]
	                batch_m = end - start
	  
	                """前向传播算出预测值，反向传播算出梯度并更新权重"""
	                self.forward(X_batch)
	                loss = self.backward(X_batch, y_batch)
	                epoch_loss += loss * batch_m
	                n_total += batch_m
	  
	            """这一轮的平均损失"""
	            epoch_loss /= n_total
	            history["train_loss"].append(epoch_loss)
	  
	            """在验证集上评估"""
	            if X_val is not None:
	                y_pred_val = self.forward(X_val)
	                val_loss = np.mean((y_pred_val - y_val) ** 2)
	                history["val_loss"].append(val_loss)
	  
	                """如果验证集损失创新低，保存当前权重作为最佳模型"""
	                if val_loss < best_val_loss:
	                    best_val_loss = val_loss
	                    best_epoch = epoch
	                    patience_counter = 0
	                    self.best_params = {
	                        k: v.copy() for k, v in self.params.items()
	                    }
	                else:
	                    patience_counter += 1
	  
	            """学习率衰减 —— 训练越往后步长越小，方便精细调参"""
	            if (epoch + 1) % decay_step == 0:
	                self.lr *= lr_decay
	            ...
	            """早停"""
	            if X_val is not None and patience_counter >= early_stop_patience:
	                if verbose:
	                    print(f"  >>> Early stopping at epoch {epoch}"
	                          f" (best: epoch {best_epoch}, val_loss={best_val_loss:.6f})")
	                self.params = {k: v.copy() for k, v in self.best_params.items()}
	                break
	  
	        history["best_epoch"] = best_epoch
	        history["best_val_loss"] = best_val_loss
	        return history
	```
## 创新点
1. 将文本特征转换为数字时，按照特征类别的数量使用了两种转换方法：低于10的使用One-Hot编码，大于10的采用标签编码
2. 异常数据检测使用多维标准，比如常识性的面积过大但是价格低的房子，统计上的超出$3\sigma$范围的数据
3. 对数据标准化，加速收敛和提高稳定性
4. 使用学习率衰减系数，使得学习率在训练初期较大，后期较小，帮助收敛
5. 训练时每一轮在验证集上评估，保留历史最佳参数
6. 使用批量梯度下降，兼顾收敛的稳定性和效率
7. 在训练开始前进行随机打乱，增强泛化性
8. 训练后分析数据，在输出的图中进行标注
9. 最后利用AI生成测试函数并进行评估，优化结果呈现
## 实验结果
- 结果如图：
	![[Pasted image 20260531163932.png|600]]
	![[Pasted image 20260531163943.png]]
- 结果分析
	训练曲线：
	- 训练损失持续下降，从 0.92 降至约 0.03；验证损失在 epoch 0~50 快速下降后趋于平稳，最佳验证损失出现在 epoch 93（0.2295），之后验证损失不再下降、略有回升，触发早停在 epoch 193
	- 两条曲线从 epoch 50 之后明显分叉——训练损失继续走低而验证损失横盘甚至微升，典型的过拟合信号
	**过拟合判断**：
	- val/train 比值 = 7.36×，落在 MODERATE（3~8×）区间，说明存在一定程度的过拟合，但属于正常范围
	- 损失差（gap）= 0.198，验证损失在最佳轮次后仅上升 2%，说明 L2 正则化（weight_decay=0.003）和早停机制抑制了过拟合恶化，模型未严重过拟合
	- 训练损失在最佳轮次时仍有 0.03，并未趋近于 0，也侧面说明模型没有完全"背诵"训练数据
	**预测 vs 真实散点图（右图）**：
	- 散点基本沿对角线分布，中低价位区域（<$200k）聚集紧密，模型对主流价位房源的预测较为准确
	- 高价区域（>$400k）散点明显发散、部分点偏离对角线较远，说明模型对高价极端样本的预测能力偏弱，这可能源于训练集中高价样本数量稀少
	- 验证集 MAE=$21,608、RMSE=$33,406，RMSE 显著大于 MAE，说明个别大误差样本拉高了均方根误差，与高价区发散现象一致
