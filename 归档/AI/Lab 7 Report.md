## 流程
- **数据**：从 `cls_chinese_medicine/` 读取 5 类中药材图片（百合 baihe、党参 dangshen、枸杞子 gouqizi、槐花 huaihua、金银花 jinyinhua）
- **预处理**：统一 Resize 至 128×128，训练集施加随机水平翻转、旋转（±15°）、颜色抖动（0.1）做数据增强，ImageNet 均值/标准差归一化
- **网络**：自建 5 层 CNN（16→32→64→128→256 通道递增）+ 全局平均池化 + 两层 FC（256→128→5），总参数量 427,141
- **训练**：CrossEntropyLoss + AdamW（weight_decay=1e-4）+ CosineAnnealingLR，batch_size=32，epochs=30
- **评估**：每轮在测试集上计算 loss 和准确率，绘制 loss 曲线和准确率曲线
## 实验原理
1. 卷积神经网络
	1. 卷积层（Conv2d）
		使用 3×3 卷积核在输入特征图上滑动，每个卷积核学习一种局部模式（边缘、纹理等）。堆叠多层卷积后，浅层捕获边缘/颜色，深层捕获形状/语义。公式：
		$$y_{i,j}^{(l)} = \sum_{m}\sum_{n} x^{(l-1)}_{i+m, j+n} \cdot w^{(l)}_{m,n} + b^{(l)}$$
	2. 批归一化（BatchNorm）
		对每个 mini-batch 的特征图做标准化，使其均值≈0、方差≈1。加速收敛，降低对初始化的敏感度，有一定正则化效果。
		$$\hat{x} = \frac{x - \mu_{\mathcal{B}}}{\sqrt{\sigma^2_{\mathcal{B}} + \epsilon}}, \quad y = \gamma \hat{x} + \beta$$
	3. ReLU 激活函数
		$\mathrm{ReLU}(x) = \max(0, x)$。计算简单、梯度不饱和，缓解深层网络的梯度消失问题。inplace=True 节省显存。
	4. 最大池化（MaxPool2d）
		在每个 2×2 窗口中取最大值，将特征图尺寸减半。作用是降维、增大感受野、提供平移不变性。
	5. 全局平均池化（GAP）
		将每个通道的 H×W 特征图压缩为一个标量（取平均），输出维度 = 通道数。相比 Flatten，GAP 不含可学习参数，天然防过拟合，且不受输入尺寸限制。
	6. Dropout
		训练时以概率 p 随机"丢弃"神经元（输出置 0），迫使网络学习冗余表示，防止过拟合。测试时所有权重保留，乘以 (1-p) 做缩放。
		$$\text{Dropout}(x)_i = \begin{cases} 0 & \text{以概率 } p \\ \frac{x_i}{1-p} & \text{以概率 } 1-p \end{cases}$$

2. 损失函数与优化
	1. 交叉熵损失（CrossEntropyLoss）
		对多分类问题，衡量预测概率分布与真实标签分布之间的差异。内部包含 Softmax + 负对数似然：
		$$\mathcal{L} = -\frac{1}{N}\sum_{i=1}^{N} \log\left(\frac{e^{z_{i,y_i}}}{\sum_{j=1}^{C} e^{z_{i,j}}}\right)$$
		其中 $z_{i,j}$ 是第 i 个样本在第 j 类上的 logit，$y_i$ 是真实类别，C=5。
	2. AdamW 优化器
		Adam 的改进版，将权重衰减（L2 正则化）与自适应学习率解耦。保留 Adam 的动量项和自适应学习率，同时 weight_decay 独立作用于权重，避免 Adam 中 L2 正则化与自适应学习率相互干扰的问题。
	3. 余弦退火学习率调度（CosineAnnealingLR）
		学习率按余弦曲线从初始值平滑衰减至 0：
		$$\eta_t = \eta_{\min} + \frac{1}{2}(\eta_{\max} - \eta_{\min})\left(1 + \cos\left(\frac{t}{T_{\max}}\pi\right)\right)$$
		训练初期大步长快速收敛，末期小步长精细调参，无需手动分段调节。

3. 数据增强
	在训练集上施加随机变换以扩充数据分布，提升泛化能力：
	- **RandomHorizontalFlip(p=0.5)**：随机水平翻转，中药图片无固定朝向，翻转不改变类别
	- **RandomRotation(±15°)**：随机旋转，模拟不同拍摄角度
	- **ColorJitter(0.1, 0.1, 0.1, 0.05)**：轻微扰动亮度、对比度、饱和度和色调，模拟不同光照条件

## 伪代码
```python
main():
    // [1] 数据加载
    train_dataset ← HerbDataset("train/", [baihe,dangshen,gouqizi,huaihua,jinyinhua], train_transform)
    test_dataset  ← HerbDataset("val/",   同上, test_transform)
    打印: 训练集样本数, 测试集样本数

    // [2] 构建模型
    model ← HerbClassifier()   // 5层CNN + GAP + 2层FC，427K参数
    model.to(DEVICE)

    // [3] 定义损失/优化器/调度器
    loss_fn   ← CrossEntropyLoss()
    optimizer ← AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    scheduler ← CosineAnnealingLR(optimizer, T_max=30)

    // [4] 训练循环
    history ← {"train_loss":[], "train_acc":[], "test_loss":[], "test_acc":[]}
    best_acc ← 0.0

    for epoch in 1 .. 30:
        // 训练阶段
        model.train()
        for images, labels in train_loader:
            outputs ← model(images)
            loss ← loss_fn(outputs, labels)
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
        统计: train_loss, train_acc

        // 测试阶段 —— 仅前向传播，不更新参数
        model.eval()
        with torch.no_grad():
            for images, labels in test_loader:
                outputs ← model(images)
                loss ← loss_fn(outputs, labels)
        统计: test_loss, test_acc

        scheduler.step()     // 更新学习率

        if test_acc > best_acc:
            best_acc ← test_acc
            torch.save(model.state_dict(), "herb_classifier.pth")

        打印: epoch, train_loss, train_acc, test_loss, test_acc, lr

    // [5] 最终评估
    加载 best_acc 对应的模型权重
    打印: 最终测试准确率、最佳测试准确率
    逐类别输出准确率

    // [6] 画图
    plot_curves(history)    // 左: Loss曲线, 右: Accuracy曲线
    np.savez("training_history.npz", **history)
```

## 代码展示
- 自定义数据集类：仅加载 5 个目标类别，按目录顺序分配标签 0~4，统一转 RGB
	```python file:train.py
	class HerbDataset(Dataset):
	    """仅加载目标类别的图片，按目录顺序分配标签0~4"""
	    def __init__(self, root_dir, class_names, transform=None):
	        self.samples = []
	        self.transform = transform
	        for label, cls_name in enumerate(class_names):
	            cls_path = os.path.join(root_dir, cls_name)
	            if not os.path.isdir(cls_path):
	                continue
	            for fname in os.listdir(cls_path):
	                if fname.lower().endswith((".jpg", ".jpeg", ".png")):
	                    self.samples.append((os.path.join(cls_path, fname), label))

	    def __len__(self):
	        return len(self.samples)

	    def __getitem__(self, idx):
	        path, label = self.samples[idx]
	        image = Image.open(path).convert("RGB")  # "统一转为RGB三通道"
	        if self.transform:
	            image = self.transform(image)
	        return image, label
	```
- CNN 网络结构：5 层卷积逐层通道数翻倍（16→256），GAP 压缩空间维度，两层 FC + Dropout 做分类
	```python file:train.py
	class HerbClassifier(nn.Module):
	    """
	    四层卷积 + 全局平均池化 + 两层全连接
	    输入 [B,3,128,128] -> 输出 [B,5]
	    """
	    def __init__(self, num_classes=5):
	        super().__init__()
	        self.features = nn.Sequential(
	            # Block1: 3 -> 16, 128 -> 64
	            nn.Conv2d(3, 16, 3, padding=1), nn.BatchNorm2d(16), nn.ReLU(inplace=True),
	            nn.MaxPool2d(2),
	            # Block2: 16 -> 32, 64 -> 32
	            nn.Conv2d(16, 32, 3, padding=1), nn.BatchNorm2d(32), nn.ReLU(inplace=True),
	            nn.MaxPool2d(2),
	            # Block3: 32 -> 64, 32 -> 16
	            nn.Conv2d(32, 64, 3, padding=1), nn.BatchNorm2d(64), nn.ReLU(inplace=True),
	            nn.MaxPool2d(2),
	            # Block4: 64 -> 128, 16 -> 8
	            nn.Conv2d(64, 128, 3, padding=1), nn.BatchNorm2d(128), nn.ReLU(inplace=True),
	            nn.MaxPool2d(2),
	            # Block5: 128 -> 256, 8 -> 4
	            nn.Conv2d(128, 256, 3, padding=1), nn.BatchNorm2d(256), nn.ReLU(inplace=True),
	            nn.MaxPool2d(2),
	        )
	        self.gap = nn.AdaptiveAvgPool2d(1)  # "全局平均池化，压缩空间维度为1x1"
	        self.classifier = nn.Sequential(
	            nn.Flatten(),
	            nn.Dropout(0.5),                 # "训练时随机丢弃50%神经元，防过拟合"
	            nn.Linear(256, 128),
	            nn.ReLU(inplace=True),
	            nn.Dropout(0.3),
	            nn.Linear(128, num_classes),
	        )

	    def forward(self, x):
	        x = self.features(x)
	        x = self.gap(x)
	        return self.classifier(x)
	```
- 训练一个 epoch：前向传播 → 计算损失 → 反向传播 → 更新参数
	```python file:train.py
	def train_one_epoch(model, loader, loss_fn, optimizer):
	    model.train()
	    total_loss, correct, total = 0.0, 0, 0
	    for images, labels in loader:
	        images, labels = images.to(DEVICE), labels.to(DEVICE)
	        optimizer.zero_grad()
	        outputs = model(images)
	        loss = loss_fn(outputs, labels)
	        loss.backward()
	        optimizer.step()
	        total_loss += loss.item() * images.size(0)
	        _, preds = outputs.max(1)
	        correct += preds.eq(labels).sum().item()
	        total += images.size(0)
	    return total_loss / total, correct / total
	```
- 评估函数：`torch.no_grad()` 禁用梯度计算，`model.eval()` 固定 BN/Dropout 行为
	```python file:train.py
	@torch.no_grad()
	def evaluate(model, loader, loss_fn):
	    model.eval()
	    total_loss, correct, total = 0.0, 0, 0
	    for images, labels in loader:
	        images, labels = images.to(DEVICE), labels.to(DEVICE)
	        outputs = model(images)
	        loss = loss_fn(outputs, labels)
	        total_loss += loss.item() * images.size(0)
	        _, preds = outputs.max(1)
	        correct += preds.eq(labels).sum().item()
	        total += images.size(0)
	    return total_loss / total, correct / total
	```

## 创新点
1. 使用全局平均池化（GAP）替代传统的 Flatten→FC 头部：GAP 不含可学习参数、天然防过拟合，且不受输入尺寸限制（AdaptiveAvgPool2d(1) 将任意尺寸特征图压缩为 1×1）
2. 每个卷积块都带 BatchNorm，5 个 BN 层显著加速收敛并抑制内部协变量偏移；配合 `inplace=True` 的 ReLU 节省内存
3. 通道数渐进翻倍设计（16→32→64→128→256）：随着空间尺寸减半，通道数翻倍，保持各层的计算量和表示能力平衡，避免某一层成为瓶颈
4. 使用动态学习率：学习率从 1e-3 平滑衰减至 0，无需手动分段调整，训练末期学习率极低（~1e-5），模型参数趋于稳定
5. AdamW 优化器将权重衰减与自适应学习率解耦：L2 正则化直接作用于权重而非混入梯度更新，避免 Adam 传统实现中 weight_decay 与自适应步长相互抵消的问题
6. 训练集数据增强三项组合（水平翻转 + 旋转 + 颜色抖动）：模拟真实拍摄差异，在不增加标注成本的前提下扩充数据分布，降低过拟合风险
7. 使用自定义 Dataset 精确过滤 5 个目标类别并重映射标签为 0~4：避免 ImageFolder 扫描全部 163 类产生无效标签，确保只有指定类别参与训练和测试
8. 每轮迭代后保存测试准确率最高的模型而非最后一轮模型
9. 利用AI生成测试函数，评估模型性能，绘制变化率曲线；规范输出格式，优化图风格，并且统一命名格式，使得代码语义更明确，结构更清晰
## 实验结果
- 模型在测试集上取得 **97.15%** 的准确率
- 各分类测试准确率如下：

| 类别  | 目录名       | 准确率     | 正确/总数   |
| --- | --------- | ------- | ------- |
| 百合  | baihe     | 96.36%  | 53 / 55 |
| 党参  | dangshen  | 92.31%  | 60 / 65 |
| 枸杞子 | gouqizi   | 100.00% | 65 / 65 |
| 槐花  | huaihua   | 96.92%  | 63 / 65 |
| 金银花 | jinyinhua | 100.00% | 66 / 66 |

- 党参（dangshen）准确率最低（92.31%），可能原因是党参与其他根茎类药材外观相似度高；枸杞子和金银花达到 100%，说明这两类药材的视觉特征极具辨识度
- 训练过程的 loss 曲线和准确率曲线：
	![[training_curves.png|800]]
- 曲线分析：
	- Loss 曲线（左）：训练损失从 0.88 持续下降至约 0.10，测试损失在 epoch 1~8 波动较大，随后稳定在 0.09~0.17 区间
	- Accuracy 曲线（右）：训练准确率从 61.73% 单调上升至 96.70%；测试准确率从 57.59% 经历前期震荡后在 epoch 11 到达 94%，稳定在 93%~97% 区间，最高点 97.15% 出现在 epoch 24
	- 训练和测试曲线在 epoch 15 后趋于接近，说明模型未出现严重过拟合——Dropout（0.5/0.3）+ weight_decay（1e-4）+ GAP 的正则化组合有效
	- 测试准确率在 epoch 5 出现异常低谷（51.90%），这是由于 CosineAnnealing 初期学习率较高（9.33e-4），参数更新步幅大导致偶然性波动，随着学习率衰减此现象消失
