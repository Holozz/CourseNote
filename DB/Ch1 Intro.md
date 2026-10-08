> [!SUMMARY]+ Table of Contents
> - [[Ch1 Intro#结构|结构]]
> - [[Ch1 Intro#语言|语言]]
> - [[Ch1 Intro#数据库|数据库]]
### 结构
- 三层抽象：
	- view level
	- logical level
	- physical level
- 实例与模式（Instances and Schemas）：
	- Logical Schema – the overall logical structure of the database
	    - Example: The database consists of information about a set of customers and accounts in a bank and the relationship between them
	    - Analogous to type information of a variable in a program
  - Physical schema – the overall physical structure of the database
  - Instance – the actual content of the database at a particular point in time
	- Analogous to the value of a variable
### 语言
- 数据定义语言DDL
	- 特定语句定义数据库的模式
	- DDL编译器生成表模板存放在**数据字典**
	- 数据字典存储的数据：
	    - database schema
	    - {==integrity constraints==}{>>完整性约束<<} i.e. primary key
	    - authorization
- 数据操作语言DML
	- 用于访问与更新数据 aka query language
  - 两种语言：
    - Procedural DML
    - Declarative DML
- SQL Query Language
	- nonprocedural 非过程化的查询，每次直接返回一个结果表格
		- e.g. 
			`select name`  
			`from instructor`  
			`where dept_name = 'Comp. Sci.'`  
  - 为了实现更复杂的功能，通常把sql内嵌在高级语言里
  - 应用程序为了访问数据库，通常使用以下方法之一：
    - 允许内嵌SQL的语言扩展
    - 能使SQL语句被发送到数据库的API
### 数据库
- 数据库设计
	- 逻辑上
		- 商业考虑：应该把什么属性放进数据库
		- 计算机考虑：应该用什么样的关联表格把这些属性分别存储
	- 物理上 —— 数据库使用什么样的物理布局
- 数据库引擎
	- 数据库系统被分为各自处理相应功能的几个模块
	- storage manager
	    - 在存储在数据库里的低级数据和应用程序以及查询之间提供接口
	    - 负责的功能：
	      - 和OS的文件管理器交互
	      - 对数据的存储、拿取和更新
	- query processor component
		- 组成：
			- DDL interpreter
			- DML compiler
			- Query evaluation engine
		- Query Processing
			1. Parsing and Translation
			2. Optimization
			3. Evaluation
	- transaction management component
		- A transaction is a collection of operations that performs a single logical function in a database application
		- ensures the database remains in a consistent state despite system failures
		- **Concurrency-control manager** controls the interaction among the concurrent transactions to ensure the consistency of the database
- 数据库架构
	- 集中式
	- 客户端-服务端
	- 并行数据库
	- 分布式数据库
- 数据库应用
	- Two-tier架构：应用在客户端，唤醒在服务器上的数据库系统
	- Three-tier架构：客户端机器作为前端，不直接对数据库发送命令
	- ![[Pasted image 20260914161822.png|423]]
- 数据库用户
- 数据库管理员