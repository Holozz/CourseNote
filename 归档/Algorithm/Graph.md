## 一、图的基本概念
### 1. 图的定义
- 图由顶点集 \(V\) 和边集 \(E\) 组成： \(G = (V, E)\)
- 可以是**有向图**（边有方向）或**无向图**（边无方向）
### 2. 常见术语
- **完全图**：所有顶点之间都有边相连
- **稀疏图 / 稠密图(sparse graph)**：边数少 / 多
- **完全图**：任何两点之间都有边（有向图需要双向连接）
- **邻接顶点**：如果 (u, v) $\in$ E(G) ，则称 u 与 v 互为邻接顶点
- **权**：边上的数值。带权的连通图又称*网络*
- **度**（Degree）：与顶点相连的边数
  - 有向图中分为**入度**和**出度**
- **路径**：顶点序列，相邻顶点之间有边相连
	-  **路径长度**：带权图的路径路径上各边的权之和，无全图默认权为1
- **回路（环）**：起点与终点相同的路径
- **连通图**：任意两个顶点之间都有路径
- **生成树**：包含所有顶点的极小连通子图，边数一定为 \(n-1\)

---
## 二、图的存储结构
### 1. 邻接矩阵
- 使用二维数组表示顶点间的连接关系
- 无向图矩阵对称，有向图不一定对称
- 适合稠密图，空间复杂度 \(O(n^2)\)
设图 A = (V, E)是一个有 n 个顶点的无权图, 图的邻接矩阵是一个
二维数组 A.edge\[n]\[n]，定义：
 $$ 
 \mathbf{AEdge}[i][j]=
\begin{cases}
\mathbf{1}, & \text{如果<}\boldsymbol{i},\boldsymbol{j}\boldsymbol{>}\boldsymbol{\in}\boldsymbol{E}\text{ 或者}(\boldsymbol{i},\boldsymbol{j})\boldsymbol{\in}\boldsymbol{E} \\
\mathbf{0}, & \text{否则} & & 
\end{cases}
$$
若为有向带权图，则：
$$
\mathbf{A.edge}[\boldsymbol{i}][\boldsymbol{j}]=
\begin{cases}
\mathbf{W}(\boldsymbol{i},\boldsymbol{j}), & \text{若}\boldsymbol{i}\neq\boldsymbol{j}\text{且}<\boldsymbol{i},\boldsymbol{j}>\in\mathbf{E}\text{或}(\boldsymbol{i},\boldsymbol{j})\in\mathbf{E} \\
\infty, & \text{若}\boldsymbol{i}\neq\boldsymbol{j}\text{且}<\boldsymbol{i},\boldsymbol{j}>\in\mathbf{E}\text{或}(\boldsymbol{i},\boldsymbol{j})\not\in\mathbf{E} \\
\boldsymbol{0}, & \text{若}\boldsymbol{i}=\boldsymbol{j} & 
\end{cases}
$$
代码实现：
~~~cpp
	#define INFINITY MAX_VAL
	/* {有向图，无向图，带权有向图，带权无向图} */
	typedef enum {DG, AG, WDG, WAG} GraphKind;
	typedef struct ArcType
	{     VexType vex1, vex2 ;/* 弧或边所依附的两个顶点 */
		  ArcValType ArcVal ;/* 弧或边的权值 */
		  ArcInfoType ArcInfo ;/* 弧或边的其它信息 */
	} ArcType ;/* 弧或边的结构定义 */
	
	typedef struct
	{	GraphKind kind ;/* 图的种类标志 */
		int vexnum , arcnum ;/* 图的当前顶点数和弧数 */
		VexType vexs[MAX_VEX] ;/* 顶点数组 */
		AdjType adj[MAX_VEX][MAX_VEX]; /* 边数组 */
	} MGraph ;/* 图的结构定义 */
	
	图的创建
	AdjGraph *Create_Graph(MGraph * G){
		printf(“请输入图的种类标志：”) ;
		scanf(“%d”, &G->kind) ;
		G->vexnum = 0 ; /* 初始化顶点个数 */
		return(G) ;
	}

	图的顶点定位
	图的顶点定位操作实际上是确定一个顶点在vexs数组中的位置(下标) ，
	其过程完全等同于在顺序存储的线性表中查找一个数据元素。
	算法实现：
	int LocateVex(MGraph *G , VexType *vp){
	    int k ;
		for (k=0 ; k<G->vexnum ; k++)
		if (G->vexs[k]==*vp) return(k) ;
		return(-1) ; /* 图中无此顶点 */
	}
	
	添加顶点：
	int AddVertex(MGraph *G , VexType *vp){
		int k , j ;
		if (G->vexnum >= MAX_VEX)
		{ printf(“Vertex Overflow !\n”) ; return(-1) ; }
		
		if (LocateVex(G , vp) != -1)
		{ printf(“Vertex has existed !\n”) ; return(-1) ; }
		
		k = G->vexnum ; G->vexs[G->vexnum++] = *vp ;
		
		if (G->kind==DG||G->kind==AG)/* 不带权的有向图或无向图 */
		for (j=0 ; j<G->vexnum ; j++)
		G->adj[j][k].ArcVal=G->adj[k][j].ArcVal=0 ;
		
		else
		for (j=0 ; j<G->vexnum ; j++)/* 带权的有向图或无向图 */{
			G->adj[j][k].ArcVal=INFINITY ;
			G->adj[k][j].ArcVal=INFINITY ;
		}
		
		return(k) ;
	}
	
	添加边：
	int AddArc(MGraph *G , ArcType *arc){
		int k=LocateVex(G, &arc->vex1);
		int j=LocateVex(G, &arc->vex1) ;
		if (k==-1||j==-1){
			printf(“Arc’s Vertex do not existed !\n”);
			return(-1) ;
		}
		if (G->kind==DG||G->kind==WDG)/* 有向图或带权的有向图*/{
			G->adj[k][j].ArcVal = arc->ArcVal;
			G->adj[k][j].ArcInfo = arc->ArcInfo ;
		}
		else/* 无向图或带权的无向图，需对称赋值 */{
			G->adj[k][j].ArcVal = arc->ArcVal ;
			G->adj[j][k].ArcVal = arc->ArcVal ;
			G->adj[k][j].ArcInfo = arc->ArcInfo ;
			G->adj[j][k].ArcInfo = arc->ArcInfo ;
		}
		return(1);
	}
}
~~~
### 2. 邻接表(Adjacency List)
- 每个顶点对应一个链表，存储其邻接顶点
- 适合稀疏图，空间复杂度 \(O(n+e)\)
- 可扩展为**逆邻接表**（用于有向图）、**多重邻接表**
### 3. 十字链表（有向图）
- 同时存储出边和入边，便于双向查找
### 4. 邻接多重表（无向图）
- 每条边只存储一次，便于边的处理
---

## 三、图的遍历
### 1. 深度优先搜索（DFS）
- 递归或栈实现
- 类似“一条路走到黑，再回溯”
- 时间复杂度：\(O(n+e)\)
### 2. 广度优先搜索（BFS）
- 队列实现
- 按层次遍历
- 时间复杂度：\(O(n+e)\)

代码实现BFS和DFS：
~~~cpp
	#include <iostream>
	#include <vector>
	#include <queue>
	using namespace std;
	int n;
	vector<vector<int>> graph;
	void printBFS(){
	    queue<int> q;
	    vector<int> visited(n + 1, 0);
	    int flag = 0;
	    while(flag < n){
	        //Find unvisited node to start new component
	        for(int i = 1; i <= n; i++) {
	            if(visited[i] == 0){
	                q.push(i);
	                visited[i] = 1;
	                break;
	            }
	        }
	        while(!q.empty()){
	            int t = q.front();
	            q.pop();
	            cout << t << " ";
	            flag++;
	            for(int i = 1; i <= n; i++){
	                if(visited[i] == 1) continue;
	                if(graph[t][i] == 1) {
	                    q.push(i);
	                    visited[i] = 1;
	                }
	            }
	        }
	    }
	    cout << endl;
	}
	
	void dfs(int root, vector<int>& visited, int& flag) {
	    visited[root] = 1;
	    cout << root << " ";
	    flag++;
	    // 从右到左扫描邻接节点
	    for(int i = 1; i <= n; i++) {
	        if(visited[i] == 0 && graph[root][i] == 1)
	           dfs(i, visited, flag);
	    }
	}
	
	void printDFS() {
	    vector<int> visited(n + 1, 0);
	    int flag = 0;
	    while(flag < n) {
	        // 找到第一个未访问的节点
	        int start = -1;
	        for(int i = 1; i <= n; i++) {
	            if(visited[i] == 0) {
	                start = i;
	                break;
	            }
	        }
	        if(start == -1) break;
	        dfs(start, visited, flag);
	    }
	    cout << endl;
	}
~~~
### 3. 遍历应用
- 生成树/森林
- 连通分量检测
- 拓扑排序（有向无环图）
---
## 四、连通性问题
### 1、生成树和生成森林
### 2、连通分量
## 五、最短路径问题

### 1、最小生成树（MST）
#### 1. 定义
- 连通带权图中权值和最小的生成树
#### 2. Prim算法
- 从某一顶点开始，逐步添加最小权值边
- 适合稠密图，时间复杂度 \($O(n^2)$\)
#### 3. Kruskal算法
- 按权值从小到大选择边，避免环
- 适合稀疏图，时间复杂度 \( $O( e\log e)$ \)
- 常用并查集实现
- **基本思想**：设有一个有 n 个顶点的连通网络 N = { V, E }, 最初先构造一个只有 n 个顶点, 没有边的非连通图 T = { V, Æ }, 图中每个顶点自成一个连通分量。当在 E 中选到一条具有最小权值的边时, 若该边的两个顶点落在不同的连通分量上，则将此边加入到 T 中;否则将此边舍去，重新选择一条权值最小的边。如此重复下去, 直到所有顶点在同一个连通分量上为止。
---

## 六、图的应用领域
- **社交网络**：用户关系图
- **计算机网络**：拓扑结构
- **图像分割**：图割算法
- **路径规划**：最短路径问题（如Dijkstra、Floyd算法）
- **推荐系统**：图神经网络
- **计算机图形学**：网格结构、半边结构
- **编译器优化**：依赖图、控制流图
---

## 七、重要算法总结
| 算法       | 适用场景         | 时间复杂度           |
| -------- | ------------ | --------------- |
| DFS      | 遍历、连通性检测     | \(O(n+e)\)      |
| BFS      | 最短路径（无权图）、遍历 | \(O(n+e)\)      |
| Prim     | 最小生成树（稠密图）   | \(O(n^2)\)      |
| Kruskal  | 最小生成树（稀疏图）   | \(O(e \log e)\) |
| Dijkstra | 单源最短路径（非负权）  | \(O(n^2)\)      |
| Floyd    | 所有顶点对最短路径    | \(O(n^3)\)      |

---

## 八、复习要点
1. **图的定义与分类**（有向/无向、带权/无权）
2. **存储结构的选择**（矩阵 vs 表）
3. **DFS与BFS的区别与实现**
4. **最小生成树两种算法的思想与适用场景**