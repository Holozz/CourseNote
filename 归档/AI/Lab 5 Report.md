# 5.1 Minimax算法求解双人博弈问题
## 实验原理
- 假设：
	-  玩家A和玩家B的行动逐层交替；
	-  A和B的利益关系对立，即假设A要使分数更大，B就要使分数更小；
	- A和B均采取最优策略。
- Minimax搜索：找到博弈树中内部节点的值，其中Max节点（A) 的每一步扩展要使收益最大, Min节点（B）的扩展要使收益最小
- 状态 ：每行剩余牌的区间：`((l₁,r₁), (l₂,r₂), ...)`，原始牌值存于 `card`
- 角色：Max = 小红（先手），Min = 小蓝（后手）
- 动作 ：任选一行，取其左端  `card[i][l]`  或右端 `card[i][r-1]`
-  状态转移：S → S'：将选中行的 l+1 或 r-1
## 伪代码
核心思想是将博弈建模为博弈树上的递归对抗搜索：
  - 节点 = 所有行的当前剩余牌面（例如 ((2,4,5,1), (3,6)) → ((4,5,1), (3,6)) 表示第1行被拿了左端的2）
  - 边 = 选择某行的左端或右端拿走一张牌
  - 叶子 = 所有行均为空（牌被拿完）
  递归逻辑：
  1. Max 层（小红）：遍历所有可行操作，选择让 score 最大的后继
  2. Min 层（小蓝）：遍历所有可行操作，选择让 score 最小的后继
  3. 回溯到根节点，得到小红的最优第一步和最终分差
```python
 F(S, isMax):
      if S 终局 (所有行 l==r):
          return 0
      if isMax:                    // 小红回合
          best = -∞
          for each 可行走法 m in S:
              S' = apply(m, S)
              best = max(best, card_val(m) + F(S', false))
          return best
      else:                        // 小蓝回合
          best = +∞
          for each 可行走法 m in S:
              S' = apply(m, S)
              best = min(best, -card_val(m) + F(S', true))
```
## 代码展示
- 总体入口，串联起文件IO、搜索树、输出答案；调用 `Card` 和  `first_step` 
	```python
	def solve(filename: str):
    global mmry, Card
    mmry = {}
    total_cards, Card = Card(filename)
    print(total_cards)
    print(Card)
    total_sum = total_cards * (total_cards + 1) // 2
    # 初始状态: 每行 l=0, r=len(row)
    init_state = tuple((0, len(row)) for row in Card)
    best_action, best_diff = first_step(init_state)
    row_idx, side, val = best_action
    print(f"第{row_idx+1}行 {'左' if side == 'L' else '右'}端 牌点数{val}")
    red = (total_sum + best_diff) / 2
    print(f"小红: {red:.0f} 小蓝: {red - best_diff:.0f}")
	```
- 读取文件，构造初始状态；被 `solve` 调用
	```python
	def Card(filename):
    card = []
    with open(filename, 'r') as f:
        lines = [line.strip() for line in f]
    for line in lines[1:]:
        row = tuple(int(x.strip()) for x in line.split(','))
        card.append(row)
    return int(lines[0]), tuple(card)
	```
- 最顶层的调度函数，遍历根节点的所有第一步走法，找出最优第一步；被 `solve` 调用，调用 `decision` `minmax`
	```python
	def first_step(state: State):
    global Card
    best_diff = -float('inf')
    best_action = None
    for r, (l, r_end) in enumerate(state):
        child = decision(state, r, 'L')
        diff = Card[r][l] + minmax(child, False)
        print(f"row: {r+1}, side: L, val: {Card[r][l]}, diff: {diff}")
        if diff > best_diff:
            best_diff = diff
            best_action = (r, 'L', Card[r][l])
        if r_end - l > 1:
            child = decision(state, r, 'R')
            diff = Card[r][r_end - 1] + minmax(child, False)
            print(f"row: {r+1}, side: R, val: {Card[r][r_end - 1]}, diff: {diff}")
            if diff > best_diff:
                best_diff = diff
                best_action = (r, 'R', Card[r][r_end - 1])
    return best_action, best_diff
	```
- 核心算法函数，进行记忆化搜索，递归搜索博弈树，返回 `state`下的最优分差；调用`decision`
	```python
	def minmax(state: State, isMaxPlayer: bool) -> int:
    global mmry, Card
    key = (state, isMaxPlayer)
    if key in mmry:
        return mmry[key]
    if all(l == r for l, r in state):
        mmry[key] = 0
        return 0
    if isMaxPlayer:
        best = -float('inf')
        for i, (l, r) in enumerate(state):
            if l >= r:
                continue
            child = decision(state, i, 'L')
            best = max(best, Card[i][l] + minmax(child, False))
            # 取右端 (只在左右不同时尝试, 避免重复)
            if r - l > 1:
                child = decision(state, i, 'R')
                best = max(best, Card[i][r - 1] + minmax(child, False))
        mmry[key] = best
        return best
    else:  # 小蓝回合: 最小化分差 (小蓝得分使分差缩小)
        best = float('inf')
        for i, (l, r) in enumerate(state):
            if l >= r:
                continue
            child = decision(state, i, 'L')
            best = min(best, -Card[i][l] + minmax(child, True))
            if r - l > 1:
                child = decision(state, i, 'R')
                best = min(best, -Card[i][r - 1] + minmax(child, True))
        mmry[key] = best
        return best
	```
- 状态转移函数，返回每一步执行动作之后的新的状态；被 `minimax`调用，没有调用其他函数
	```python
	def decision(state: State, row_idx: int, side: str) -> State:
    new_state = list(state)
    l, r = new_state[row_idx]
    if side == 'L':
        new_state[row_idx] = (l + 1, r)
    else: 
        new_state[row_idx] = (l, r - 1)
    return tuple(new_state)
	```
## 创新点
1. 使用 指针来表示和访问状态，使得状态的传参开销小
2. 统一评分：让两人的各自最大化目标改为对同一个数据的最大化目标和最小化目标，便于管理和传参
3. 记忆化搜索，`minmax()`函数返回的是从当前局面开始的最优结果，然后使用 `mmry` 变量存储状态和对应的结果，减少每个状态被重复搜索的次数
## 实验结果
展示一些 `test_cases`结果：
![[屏幕截图 2026-05-13 172234.png|400]]
![[屏幕截图 2026-05-13 172243.png|400]]
# 5.2 象棋AI
## 实验原理
- 假设：
	-  玩家A和玩家B的行动逐层交替；
	-  A和B的利益关系对立，即假设A要使分数更大，B就要使分数更小；
	- A和B均采取最优策略。
- Minimax搜索：找到博弈树中内部节点的值，其中Max节点（A) 的每一步扩展要使收益最大, Min节点（B）的扩展要使收益最小
- 状态设定：是博弈树的节点，即 `board` 变量，一个10\*9的二维列表，正数代表红子，负数代表黑子，0代表无子
- 动作定义：是一个四元组 `(r, c, nr, nc)` ，代表把棋子从 `(r, c)` 移动到 `(nr, nc)` 
- 生成动作：产生当前局面下所有合法的走法，考虑当前的局面加上象棋中的规则来遍历
- 评价函数：`evaluate(board)` 根据当前 `board` 上的棋子来计算的局面分数，红子为正数，黑子为负数；并且特殊的棋子在特殊位置的分数也不尽相同
- 极大化：红方，试图使局面分数最大；对应 `isMaximizing == True`
- 极小化：黑方，阻挠红方得分，即试图使得分数最小；对应 `isMaximizing == False`
- 终局：设定的 `depth==0`或者没有合法走法了 `not_has_any_move`
- $\alpha/\beta$剪枝：即利用局面分数作为依据
## 伪代码
```python
 function alphabeta(board, depth, alpha, beta, isMaximizing):
      if depth == 0 or 无合法走法:
          return (evaluate(board), None)
      if isMaximizing:          // 红方（我方），求极大值
          best = -∞
          for each 己方棋子 + 合法走法:
              new_board = 模拟走子(board, 走法)
              val = alphabeta(new_board, depth-1, alpha, beta, false)[0]
              if val > best:
                  best = val
                  best_move = 当前走法
              alpha = max(alpha, best)
              if beta <= alpha: break     // β剪枝
          return (best, best_move)
      else:                     // 黑方（对方），求极小值
          best = +∞
          for each 己方棋子 + 合法走法:
              new_board = 模拟走子(board, 走法)
              val = alphabeta(new_board, depth-1, alpha, beta, true)[0]
              if val < best:
                  best = val
                  best_move = 当前走法
              beta = min(beta, best)
              if beta <= alpha: break     // α剪枝
          return (best, best_move)
```
## 代码展示
- 初始化函数，直接返回一个棋盘，即一个10x9 的二维列表，定义了棋子类型，正数=红，负数=黑，0=空
	```python
	def init_board():
	    """返回 10x9 的二维列表，正数=红，负数=黑，0=空"""
	    b = [[0]*9 for _ in range(10)]
	    # 黑方（上方，行0-4）
	    back = [CHE, MA, XIANG, SHI, JIANG, SHI, XIANG, MA, CHE]
	    for c, p in enumerate(back):
	        b[0][c] = -p
	    b[2][1] = b[2][7] = -PAO
	    for c in range(0, 9, 2):
	        b[3][c] = -BING
	    # 红方（下方，行5-9）
	    for c, p in enumerate(back):
	        b[9][c] = p
	    b[7][1] = b[7][7] = PAO
	    for c in range(0, 9, 2):
	        b[6][c] = BING
	    return b
	```
- 求棋子的所有可能落点函数，要考虑不同类型棋子的走法，以及棋盘边界，是否目标落点有棋子；这也是后面给出合法走法函数 `legal_moves`和判断是否还有走法函数 `has_any_move` 函数的基础
	```python
	def get_moves(board, r, c):
	    p = board[r][c]
	    if p == 0:
	        return []
	    red = is_red(p)
	    t = abs(p)
	    moves = []
	    if t == CHE:
	        for dr, dc in [(-1,0),(1,0),(0,-1),(0,1)]:
	            nr, nc = r+dr, c+dc
	            while in_board(nr, nc):
	                if board[nr][nc] == 0:
	                    moves.append((nr, nc))
	                else:
	                    if not same_side(p, board[nr][nc]):
	                        moves.append((nr, nc))
	                    break
	                nr += dr; nc += dc
	    elif t == MA:
	        for dr, dc in [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)]:
	            #马腿检查
	            if abs(dr) == 2:
	                br, bc = r + dr//2, c
	            else:
	                br, bc = r, c + dc//2
	              #边界检查
	            if not in_board(br, bc):
	                continue
	            if board[br][bc] != 0:
	                continue
	            nr, nc = r+dr, c+dc
	            if in_board(nr, nc) and not same_side(p, board[nr][nc]):
	                moves.append((nr, nc))
	    elif t == XIANG:
	        # 象走田，不能过河
	        for dr, dc in [(-2,-2),(-2,2),(2,-2),(2,2)]:
	            nr, nc = r+dr, c+dc
	            if not in_board(nr, nc): continue
	            if red and nr < 5: continue
	            if not red and nr > 4: continue
	            # 塞象眼
	            er, ec = r+dr//2, c+dc//2
	            if board[er][ec] != 0: continue
	            if not same_side(p, board[nr][nc]):
	                moves.append((nr, nc))
	    elif t == SHI:
	        ...
	    elif t == JIANG:
	        ...
	    elif t == PAO:
			 ...
	    elif t == BING:
	        ...
	    return moves
	```
- 判断是否有将军情况，只需要判断一方的将的位置是否在另一方的下一步范围内即可
	```python
	def is_in_check(board, isRed):
	    kr, kc = find_king(board, isRed) or (99,99)
	    for r in range(10):
	        for c in range(9):
	            p = board[r][c]
	            if p == 0 or is_red(p) == isRed:
	                continue
	            if (kr, kc) in get_moves(board, r, c):
	                return True
	    if kings_face(board):
	        return True
	    return False
	```
- 评估函数，根据当前棋局、棋子位置、棋子种类来综合给出局面分数，是 $\alpha/\beta$剪枝的重要依据
	```python
	def evaluate(board):
	    score = 0
	    """遍历直接计算子力和位置分"""
	    for r in range(10):
	        for c in range(9):
	            p = board[r][c]
	            if p == 0:
	                continue
	            red = is_red(p)
	            ptype = abs(p)
	            # 子力分
	            base_val = PIECE_VALUE.get(ptype, 0)
	            # 位置分
	            pos_table = POS_TABLES.get(ptype, None)
	            pos_val = 0
	            if pos_table:
	                # 红方从 row 0=黑底线 到 row 9=红底线，位置表也是红方视角
	                row = r
	                if not red:
	                    row = 9 - r
	                pos_val = pos_table[row][c]
	         
	            piece_score = base_val + pos_val
	            score += piece_score if red else -piece_score
	    # 额外阵型/灵活性奖励
	    score += _mobility_bonus(board, True)   # 红方机动性
	    score -= _mobility_bonus(board, False)  # 黑方机动性
	    return score
	```
- 剪枝函数：是象棋AI的核心，Minmax算法加上 $\alpha/\beta$剪枝，返回当前局面下的最优得分以及走法
	```python
	def alphabeta(board, depth, alpha, beta, isMaximizing):
	    if depth == 0 or not has_any_move(board, isMaximizing):
	        return evaluate(board), None
	    moves = []
	    value = -float('inf') if isMaximizing else float('inf')
	    for r in range(10):
	        for c in range(9):
	            if board[r][c] == 0 or is_red(board[r][c]) != isMaximizing:
	                continue
	            for nr, nc in legal_moves(board, r, c):
	                new_board = copy.deepcopy(board)
	                new_board[nr][nc] = board[r][c]
	                new_board[r][c] = 0
	                new_board_score = alphabeta(new_board, depth-1, alpha, beta, not isMaximizing)[0]
	                if isMaximizing:
	                    """极大化搜索，分数更高则更新value以及move"""
	                    if new_board_score > value:
	                        value = new_board_score
	                        moves = [(r, c, nr, nc)]
	                    """剪枝"""
	                    alpha = max(alpha, value)
	                    if beta <= alpha:
	                        return value, moves
	                else:
	                    """极小化搜索，分数更低则更新value以及move"""
	                    if new_board_score < value:
	                        value = new_board_score
	                        moves = [(r, c, nr, nc)]
	                    """剪枝"""
	                    beta = min(beta, value)
	                    if beta <= alpha:
	                        return value, moves
	    return evaluate(board), moves
	```
## 创新点&优化
1. 使用 `ChessGame` 类管理棋盘状态、用户输入等
2. 利用AI做成UI界面，交互逻辑等，在用户点击棋子时会显示当前的可选落位；记录双方每次的走棋；将军时会提示不能走非解围走法
3. 提供悔棋功能和红黑互换选项
4. 对局面的评估采用多重因素，首先考虑棋子本身类型作为基础分；其次按照不同棋子在棋盘的位置来给定特殊分数，比如过河的兵就会大量提升分数；还会给予灵活性奖励
5. 利用AI实现了线程化搜索，避免AI思考界面卡死
## 实验结果
开局
![[屏幕截图 2026-05-13 175927.png|600]]
AI思考（当搜索深度大时明显等待很久
![[屏幕截图 2026-05-13 175952.png|600]]
将死
![[屏幕截图 2026-05-13 181600.png|600]]
# 5.3 遗传算法解决TSP问题
## 实验原理：遗传算法（GA）
- 遗传算法是模拟生物在自然环境中的遗传和进化过程而形成的一种自适应全局优化概率搜索算法，遗传算法从任意一个初始化的群体出发，通过随机选择、交叉和变异等遗传操作，使群体一代一代地进化到搜索空间中越来越好的区域，直至抵达最优解。一般的迭代方法容易陷入局部极小的陷阱而出现”死循环”现象，使迭代无法进行。遗传算法很好地克服了这个缺点，是一种全局优化算法。
- 在这个问题中，遗传算法各个要素的定义和实现如下：
	- 基因的定义：用访问城市的顺序的list作为编码，每一个list作为一个个体
	- 初始群体设定：随机生成`Population_Size`个随机序列
	- 适应度函数 `fitness()` 设计：当前城市经过顺序的总路程的长度的倒数
	- 自然选择：采用锦标赛选择，每次从种群中随机选择 `tournament_size` 个个体并选择适应度最高的个体，重复 `pop_size` 次
	- 基因重组：采用PMX或者OX方法对两个个体进行交叉产生子代
	- 变异：基于 `mutation_possibility` 的概率进行变异，可以选择交换或者反转来变异
	- 遗传操作设计：包括交叉，变异，选择
	- 控制参数设定：
	    ```python
	    Crossover_Probability = 0.8
	    Mutation_Probability = 0.2
	    Population_Size = 500
	    Generations_Time = 1000
	    ```
	
## 伪代码
![[Pasted image 20260512123531.png|600]]

## 代码展示
- 总体运行逻辑，集成在GA()，接收参数依次为：城市坐标集合、种群规模、繁衍代数、精英个体数、交叉概率、变异概率、锦标赛每次选择的个体数、交叉方式、变异方式、随机种子、产生数据图表的迭代间隔、调试输出
	```python
		def GA(coords, pop_size=100, generations=500, elite_size=4,
	       crossover_possibility=0.8, mutation_possibility=0.6, tournament_size=3,
	       crossover='ox', mutation='swap', seed=None, snapshot_interval=200,verbose=True):
		    """Solve one TSP instance with a genetic algorithm.
		    Returns:
		    best_tour : list
		    best_length : float
		    history : list
		    snapshots : list of (gen, tour, length)
		    """
		    if seed is not None:
		        random.seed(seed)
		    crossover_fn = order_crossover if crossover == 'ox' else pmx_crossover
		    mutation_fn = swap_mutation if mutation == 'swap' else inversion_mutation
		  
		    n = len(coords)
		    population = init_population(n, pop_size)
		    best_tour = None
		    best_length = float('inf')
		    history = []
		    snapshots = []
		  
		    for gen in range(generations):
		        lengths = [tour_length(t, coords) for t in population]
		        fitness = [1.0 / l for l in lengths]
		  
		        min_idx = min(range(len(lengths)), key=lambda i: lengths[i])
		        if lengths[min_idx] < best_length:
		            best_length = lengths[min_idx]
		            best_tour = population[min_idx][:]
		
		        history.append(best_length)
		        """使用AI产生测试代码：将当前信息以图片形式输出"""
		        # Record snapshot every snapshot_interval (include gen 0)
		        if gen % snapshot_interval == 0:
		            # Show current best tour (may differ from all-time best for current gen)
		            current_tour = population[min_idx][:]
		            snapshots.append((gen, current_tour, lengths[min_idx]))
		  
		        if verbose and gen % 50 == 0:
		            print(f"  Gen {gen:4d} | Best: {best_length:12.2f}")
		
		        sorted_idx = sorted(range(len(lengths)), key=lambda i: lengths[i])
		        new_pop = [population[sorted_idx[i]][:] for i in range(elite_size)]
		
		        while len(new_pop) < pop_size:
		            p1 = tournament_select(population, fitness, tournament_size)
		            p2 = tournament_select(population, fitness, tournament_size)
		
		            if random.random() < crossover_possibility:
		                child = crossover_fn(p1, p2)
		            else:
		                child = p1[:]
		  
		            child = mutation_fn(child, mutation_possibility*pow(0.9985, gen))
		            new_pop.append(child)
		  
		        population = new_pop
		
		    if verbose:
		        print(f"  DONE  | Best: {best_length:12.2f}")
		
		    return best_tour, best_length, history, snapshots
	```
- 种群初始化函数，返回一个二维列表： `pop_size`个长度为 `n_cities`的 `list`
	```python
		def init_population(n_cities, pop_size):
		    base = list(range(n_cities))
		    population = []
		    for _ in range(pop_size):
		        perm = base[:]
		        random.shuffle(perm)
		        population.append(perm)
		    return population
	```
- 计算路径长度函数，通过调用计算两点距离函数，不断累加，返回路径总长度：
	```python
		def tour_length(tour, coords):
		    total = 0.0
		    n = len(tour)
		    for i in range(n):
		        total += calc_distance(coords[tour[i]], coords[tour[(i + 1) % n]])
		    return total
	```
- 锦标赛选择函数：从种群里随机抽取 `tournament_size`个个体并以 `fitness`选择适应度最高的个体
	```python
		def tournament_select(population, fitness, tournament_size=3):
		    indices = random.sample(range(len(population)), tournament_size)
		    best_idx = max(indices, key=lambda x: fitness[x])
		    return population[best_idx][:]
	```
- 交叉函数，分别是OX和PMX
	```python
	def order_crossover(parent1, parent2):
    n = len(parent1)
    s, t = sorted(random.sample(range(n), 2))
    child = [-1] * n
    child[s:t + 1] = parent1[s:t + 1]
    pos = (t + 1) % n
    for city in parent2[t + 1:] + parent2[:t + 1]:
        if city not in child:
            child[pos] = city
            pos = (pos + 1) % n
    return child
	def pmx_crossover(parent1, parent2):
	    n = len(parent1)
	    s, t = sorted(random.sample(range(n), 2))
	    child = parent1[:]
	    for i in range(s, t + 1):
	        if child[i] == parent2[i]:
	            continue
	        j = child.index(parent2[i])
	        child[i], child[j] = child[j], child[i]
	    return child
	```
- 变异函数，分别是交换变异和反转变异：
	```python
	def swap_mutation(tour, mutation_possibility=0.1):
	    tour = tour[:]
	    if random.random() < mutation_possibility:
	        i, j = random.sample(range(len(tour)), 2)
	        tour[i], tour[j] = tour[j], tour[i]
	    return tour
	def inversion_mutation(tour, mutation_possibility=0.1):
		    tour = tour[:]
	    if random.random() < mutation_possibility:
	        i, j = sorted(random.sample(range(len(tour)), 2))
	        tour[i:j + 1] = reversed(tour[i:j + 1])
	    return tour
	```
- 此外还利用AI生成了测试代码，可以以多种方式调试输出：每隔一定代数的当前解、指定使用哪种交叉方式和变异方式来进行算法、执行单元测试即分别测试文件读取、计算距离、种群、自然选择、变异交叉等步骤是否有误，见于文件 `test_tsp_ga.py`
## 创新点&优化
1. 采用多种的变异方式和交叉方式，比较得出更优者
2. 对于变异概率，采用了变化的变异率（指数函数），使得在早期多尝试，后期维持稳定
3. 可变参数的总体运行逻辑函数 `GA()` 使得可以灵活调整每次的变异概率、交叉概率、精英个体数、适应度函数等等
4. 使用AI产生了更直观的测试输出，使得更易于发现算法的问题
## 实验结果
1. 对于规模小的城市集，可以得到较为优秀甚至最优解：
	对于Djibouti38个城市，给定最优解是6656，这里算法第一次得到7381.06
	![[屏幕截图 2026-05-13 094459.png|600]]
	修改参数第二次得到6881.95
	![[屏幕截图 2026-05-13 094648.png|600]]
	![[屏幕截图 2026-05-13 094705.png|600]]
	![[屏幕截图 2026-05-13 094712.png|600]]
	对于Western Sahara29个城市，经过三次不同的随机种子，得到了最优解
	![[屏幕截图 2026-05-13 094814.png|600]]
	![[屏幕截图 2026-05-13 094852.png|600]]
	![[屏幕截图 2026-05-13 095016.png|600]]
	![[Figure_2.png|600]]
2. 可见算法的正确性，接下来测试卡塔尔194个城市的数据集
	![[屏幕截图 2026-05-13 094336.png|600]]
	并不是很理想，更改参数继续
	![[屏幕截图 2026-05-13 110210.png|600]]
	![[屏幕截图 2026-05-13 110210 1.png|600]]
	![[屏幕截图 2026-05-13 111630.png|600]]
	改了多次仍然不太理想，目前最好是
	![[屏幕截图 2026-05-13 110736.png|600]]
3. 可见对于大规模的问题不仅运行时间明显变长，答案的正确性也下降了