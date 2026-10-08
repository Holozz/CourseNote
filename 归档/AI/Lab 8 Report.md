## 流程
- **环境**：OpenAI Gym `CartPole-v0`——小车在轨道上左右移动，保持竖直杆不倒；状态空间 $\mathcal{S} \subseteq \mathbb{R}^4$（位置、速度、角度、角速度），动作空间 $\mathcal{A} = \{0, 1\}$（左移/右移），每存活一步获得 +1 奖励
- **网络**：Q 网络为 2 层全连接（4→128→128→2），ReLU 激活，输出各动作的 Q 值
- **算法**：Double DQN——在线网络 $Q_w$ 选择动作，目标网络 $Q_{w'}$ 评估价值，解耦动作选择与价值计算，抑制 Q 值高估
- **探索策略**：ε-greedy，ε 从 1.0 指数衰减至 0.01（decay=0.999）
- **经验回放**：容量 10000 的 Replay Buffer，随机采样 batch_size=128 打破样本时间相关性
- **训练**：MSE 损失 + Adam 优化器（lr，γ）；目标网络每 5 回合同步一次
- **评估**：每回合记录 Reward 与 20 回合滑动平均；当滑动平均 ≥195 时停止训练；画训练曲线并保存 `training_curve.png`

## 实验原理
### 1. 马尔可夫决策过程（MDP）

|符号|含义|CartPole 中的实例|
|---|---|---|
|$\mathcal{S}$|状态空间|小车位置 $x$、速度 $\dot{x}$、杆角度 $\theta$、角速度 $\dot{\theta}$|
|$\mathcal{A}$|动作空间|向左施加力 / 向右施加力|
|$p(s'\mid s,a)$|状态转移函数|物理引擎模拟（环境未知）|
|$R(s,a)$|奖励函数|每存活一步 +1|
|$\gamma$|折扣因子|0.99，平衡即时与未来奖励|
### 2. 动作价值函数与贝尔曼方程

动作价值函数 $Q^\pi(s,a)$：从状态 $s$ 出发，先执行动作 $a$，之后按策略 $\pi$ 行动的期望累积折扣回报：

$$Q^\pi(s,a) = \mathbb{E}_\pi\left[\sum_{k=0}^{\infty} \gamma^k R_{t+k+1} \mid S_t=s, A_t=a\right]$$

贝尔曼最优方程（动作价值形式）：

$$\boxed{Q^*(s,a) = R(s,a) + \gamma \sum_{s' \in \mathcal{S}} P(s' \mid s,a) \max_{a'} Q^*(s',a')}$$

最优策略可直接从 $Q^*$ 导出：$\pi^*(s) = \arg\max_a Q^*(s,a)$

### 3. Q-Learning 与 Deep Q-Network（DQN）

表格型 Q-Learning（异策略时序差分方法）：

$$Q(S_t, A_t) \leftarrow Q(S_t, A_t) + \alpha\left[R_{t+1} + \gamma \max_{a'} Q(S_{t+1}, a') - Q(S_t, A_t)\right]$$

- 使用 $\max_{a'} Q(S_{t+1}, a')$ 作为目标，而非实际执行的下一动作 → **异策略**（Off-Policy）
- TD 误差 $\delta_t = R_{t+1} + \gamma \max_{a'} Q(S_{t+1}, a') - Q(S_t, A_t)$ 表示"现实与预期的差距"

DQN：用深度神经网络 $Q_w(s,a)$ 近似 Q 函数，解决连续/高维状态空间无法建表的问题。训练时最小化 TD 误差：

$$\mathcal{L}(w) = \mathbb{E}_{(s,a,r,s')\sim \mathcal{D}}\left[\left(r + \gamma \max_{a'} Q_{w}(s', a') - Q_w(s,a)\right)^2\right]$$

Naïve DQN 的两大问题：

|问题|原因|后果|
|---|---|---|
|样本时间相关性|相邻帧/状态高度相似，违反 SGD 的 i.i.d 假设|训练不稳定，参数震荡|
|移动靶子（Semi-Gradient）|目标值 $y_i$ 本身依赖 $Q_w$，参数更新同时目标也在变|可能发散，不保证收敛|

### 4. Classic DQN 的两大改进

经验回放（Experience Replay Buffer）：
- 与环境交互产生 $(s, a, r, s', done)$ 存入固定容量缓存 $\mathcal{B}$
- 训练时随机采样 mini-batch → 打破时间相关性，使梯度估计接近 i.i.d
- 同一经验可被多次使用 → 提高数据利用率

目标网络（Target Network）：
- 维护两个网络：在线网络 $Q_w$（频繁更新）和 目标网络 $Q_{w'}$（定期更新）
- 目标值用目标网络计算：$y = r + \gamma \max_{a'} Q_{w'}(s', a')$
- 在一段时间内目标固定 → 训练稳定，避免"移动靶子"问题
- 每隔固定步数 $w' \leftarrow w$

```text
Classic DQN 伪码：
1. 初始化在线网络 Q_w 和目标网络 Q_{w'} (w' ← w)
2. 初始化经验回放池 B
3. 循环：
   a. 用 ε-greedy 选动作 a，执行 → (s, a, r, s')
   b. 将 (s,a,r,s') 存入 B
   c. 从 B 随机采样 mini-batch
   d. 用目标网络计算：y_i = r_i + γ max_{a'} Q_{w'}(s_i', a')
   e. 梯度更新：最小化 (Q_w(s_i,a_i) - y_i)^2
   f. 每隔 C 步：w' ← w
```

### 5. 创新点：Double DQN
问题：Classic DQN 在目标值中同时用目标网络选动作和算价值：

$$y^{\text{DQN}} = r + \gamma Q_{w'}\left(s', \arg\max_{a'} Q_{w'}(s', a')\right)$$

由于 $\max$ 运算 + 估计噪声 → $Q_{w'}$ 的误差在取 $\max$ 时被系统性放大：

$$\mathbb{E}[\max_{a}(X_a + \epsilon_a)] \geq \max_a \mathbb{E}[X_a]$$
****
即估计值带有随机噪声时，取 max 操作会系统性高估 Q 值

解决：将动作选择和价值评估分离到两个网络：

$$\boxed{y^{\text{Double DQN}} = r + \gamma \; Q_{w'}\left(s', \arg\max_{a'} Q_{w}(s', a')\right)}$$

- 在线网络 $Q_w$：选择最优动作 $\arg\max_{a'} Q_w(s', a')$（基于当前知识）
- 目标网络 $Q_{w'}$：评估该动作的价值 $Q_{w'}(s', a^*)$（基于历史知识）

两个网络参数不同、误差不完全相同 → 解耦后误差不会同向叠加，有效抑制高估

### 6. ε-greedy 探索策略

强化学习的核心困境——探索与利用（Exploration vs Exploitation）：
- 利用（Exploitation）：选当前 Q 值最高的动作，最大化即时收益
- 探索（Exploration）：随机尝试未知动作，可能发现更优策略

ε-greedy 策略：

$$\pi(a \mid s) = \begin{cases} 1 - \varepsilon + \frac{\varepsilon}{|\mathcal{A}|} & \text{if } a = \arg\max_a Q(s,a) \\ \frac{\varepsilon}{|\mathcal{A}|} & \text{otherwise} \end{cases}$$

- 以 $1-\varepsilon$ 的概率贪心选择（利用），以 $\varepsilon$ 的概率均匀随机选择（探索）
- $\varepsilon$ 从 1.0 指数衰减（$\varepsilon \leftarrow \varepsilon \times 0.999$）至最小值 0.01
- 初期 $\varepsilon$ 大 → 充分探索状态空间；后期 $\varepsilon$ 小 → 收敛到最优策略

## 伪代码

```python
main():
    // [1] 初始化
    env ← gym.make("CartPole-v0")
    固定随机种子 (73)
    agent ← DQNAgent(state_dim=4, action_dim=2)

    // [2] 超参数
    episodes ← 500
    γ ← 0.99
    lr ← 4e-3
    batch_size ← 128
    ε ← 1.0, ε_min ← 0.01, ε_decay ← 0.999

    // [3] 训练循环
    rewards_history ← []
    avg_history ← []
    total_steps ← 0

    for episode in 0 .. episodes-1:
        state ← env.reset()
        episode_reward ← 0

        while True:
            // ε-greedy 选择动作
            if random() < ε:
                action ← random(0,1)
            else:
                action ← argmax Q_net(state)

            next_state, reward, done ← env.step(action)
            total_steps ← total_steps + 1

            // 存入经验回放池
            memory.push(state, action, reward, next_state, done)
            // 从回放池采样并更新网络
            agent.train()

            state ← next_state
            episode_reward ← episode_reward + reward
            if done: break

        // 记录并计算滑动平均
        rewards_history.append(episode_reward)
        avg_reward ← mean(rewards_history[-20:])
        avg_history.append(avg_reward)

        // 每 10 回合同步目标网络
        if episode % 10 == 0:
            agent.update_target()

        // ε 衰减
        if ε > ε_min: ε ← ε × ε_decay

        // 收敛判据
        if avg_reward ≥ 195:
            break

    // [4] 画训练曲线并保存
    plot(avg_history)
    savefig("training_curve.png")
```

## 代码展示

- Q 网络结构：两层隐藏层（各 128 神经元）+ ReLU，输入 4 维状态，输出 2 维 Q 值

    ```python file:CartPole.py
    class QNetwork(nn.Module):
        def __init__(self, state_dim, action_dim):
            super(QNetwork, self).__init__()
            self.net = nn.Sequential(
                nn.Linear(state_dim, 128),
                nn.ReLU(),
                nn.Linear(128, 128),
                nn.ReLU(),
                nn.Linear(128, action_dim)
            )

        def forward(self, x):
            return self.net(x)
    ```

- 经验回放池：基于 `deque` 的定长队列，`sample()` 用 `random.sample` 随机打乱采样，`zip(*)` 批量解包各分量

    ```python file:CartPole.py
    class ReplayBuffer:
        def __init__(self, capacity):
            self.buffer = deque(maxlen=capacity)

        def push(self, state, action, reward, next_state, done):
            self.buffer.append((state, action, reward, next_state, done))

        def sample(self, batch_size):
            batch = random.sample(self.buffer, batch_size)
            states, actions, rewards, next_states, dones = zip(*batch)
            return (np.array(states), np.array(actions),
                    np.array(rewards), np.array(next_states), np.array(dones))
    ```

- ε-greedy 动作选择：以概率 ε 随机探索，否则取 Q 值最大的动作；`torch.no_grad()` 禁用梯度计算以节省内存

    ```python file:CartPole.py
    def select_action(self, state):
        if random.random() < self.epsilon:
            return random.randrange(self.action_dim)
        state = torch.FloatTensor(state).unsqueeze(0).to(self.device)
        with torch.no_grad():
            q_values = self.q_net(state)
        return q_values.argmax().item()
    ```

- Double DQN 训练——核心：在线网络选动作，目标网络评价值

    ```python file:CartPole.py
    def train(self):
        if len(self.memory) < self.batch_size:
            return
        // 从回放池采样 mini-batch
        states, actions, rewards, next_states, dones = \
            self.memory.sample(self.batch_size)
        // 当前 Q 值
        current_q = self.q_net(states).gather(1, actions)

        // Double DQN 目标值计算
        with torch.no_grad():
            // 在线网络 q_net 选最优动作
            next_actions = self.q_net(next_states).argmax(1).unsqueeze(1)
            // 目标网络 target_net 评估该动作的价值
            next_q = self.target_net(next_states).gather(1, next_actions)
            // 贝尔曼目标：即时奖励 + 折扣未来价值（终止状态不计未来）
            target_q = rewards + self.gamma * next_q * (1 - dones)

        loss = nn.MSELoss()(current_q, target_q)
        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()
    ```

    关键步骤：
    1. `self.q_net(next_states).argmax(1)` → 在线网络**选出最优动作索引** $a^* = \arg\max_a Q_w(s', a)$
    2. `self.target_net(next_states).gather(1, next_actions)` → 目标网络**仅计算该动作的 Q 值** $Q_{w'}(s', a^*)$
    3. `(1 - dones)` → 终止状态未来价值为 0（没有下一步），保证公式正确

- 目标网络同步：将在线网络参数完整复制到目标网络

    ```python file:CartPole.py
    def update_target(self):
        self.target_net.load_state_dict(self.q_net.state_dict())
    ```

- 训练主循环：交互 → 存储 → 采样 → 训练 → 评估，每步产生一个样本

    ```python file:CartPole.py
    for episode in range(episodes):
        state, _ = env.reset()
        episode_reward = 0
        while True:
            action = agent.select_action(state)
            next_state, reward, terminated, truncated, _ = env.step(action)
            done = terminated or truncated
            agent.memory.push(state, action, reward, next_state, done)
            agent.train()
            state = next_state
            episode_reward += reward
            if done:
                break
        // 滑动平均评估，判断收敛
        avg_reward = np.mean(rewards_history[-20:])
        if avg_reward >= 195:
            break
    ```

## 创新点
1. 使用 Double DQN 算法：使用DQN算法训练了几次后更新为DoubleDQN，将动作选择和动作价值评估分派给在线网络和目标网络分别完成，有效抑制 Classic DQN 中因 max 操作与估计噪声叠加导致的 Q 值系统性高估问题
2. 目标网络定期硬更新（Hard Update，每 10 回合同步一次）：在一段时间内保持训练目标固定，避免"移动靶子"导致的训练震荡；间隔并非过密（避免目标频繁变化）也非过疏（避免目标过时），并且不断调整该参数尝试找出优解
3. ε 指数衰减策略：从完全随机探索（ε=1.0）平滑过渡到少量探索（ε_min=0.01），decay=0.999 保证衰减过程持续整个训练周期；初期充分探索状态-动作空间，末期以利用为主；并且多次调整decay值寻找优解
4. Double DQN 与 DQN 公式对比直接在代码中体现：`self.q_net(...).argmax(1)`  + `self.target_net(...).gather(1, next_actions)` ，清晰展示"解耦"的实现方式
5. 训练曲线绘制包含参数信息文本框（图右侧）：一键展示所有超参数与最终结果，便于实验对比与复现
6. 固定所有随机种子（random / numpy / torch）

## 实验结果

- Double DQN 在 CartPole-v0 上成功学习到使杆保持直立的控制策略，20 回合滑动平均 Reward 超过 198 时自动停止
- 训练曲线：可以看到
	1. ![[Figure_1.png|600]]
	2. ![[Figure_2.png|600]]
	3. ![[Figure_3.png|600]]
	4. 更改为DoubleDQN后有一优解：
		![[Figure_7.png|600]]
		
	5. 随后又找到最优解（目前）：
		71轮训练之后Reward就达到了199以上（Seed=10），并且有一次运行在第50多轮训练的时候就达到了195以上
		并且训练数也是比较低，训练了几次，普遍在3k到5k就会达到180
		![[Figure_8.png|600]]
		![[Pasted image 20260614183917.png|400]]
- 曲线分析：
    - 滑动平均 Reward 从初始约 20 逐步上升，普遍经历约 100~150 回合的持续学习后都能突破 180，但是不同参数的后面的情况也不同，好的会继续上升至190+，不好的则会来回震荡
    - 前期波动较大是 ε 较大时探索行为导致的正常现象
    - 随着 ε 衰减（探索逐渐转向利用），曲线趋于平稳上升，在收敛附近波动极小
    - 水平虚线标注了 180和 198，直观展示训练进程
    - 平均 Reward 的稳定提升表明：经验回放池积累了足够的多样化经验后，网络在 Q 值估计和策略选择上逐步收敛
- 收敛效率分析：
    - 记录了首次达到 avg≥180 的样本数反映算法数据效率
    - 最终滑动平均 Reward 和总交互步数标记在图右侧信息框中
    - Double DQN 的解耦设计有效抑制了 Q 值高估，但也有震荡的情况
