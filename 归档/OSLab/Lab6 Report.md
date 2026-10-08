# Section1 实验要求与实验概述
实验要求：阅读README.md并完成实验任务和思考题
实验概述：
	在本次实验中，我们首先使用硬件支持的原子指令来实现自旋锁SpinLock，自旋锁将成为实现线程互斥的有力工具。接着，我们使用SpinLock来实现信号量，最后我们使用SpinLock和信号量来给出两个实现线程互斥的解决方案
实验目标：
	1. 掌握自旋锁（SpinLock）和信号量（Semaphore）的实现原理，理解原子指令 xchg 在互斥中的作用
	2. 使用同步原语解决经典并发问题（消失的芝士汉堡、生产者-消费者、读者-写者、哲学家就餐），理解竞态条件的危害
	3. 理解死锁的四个必要条件，掌握至少一种死锁预防策略
	4. 对比 MESA、Hoare、Hasen三种线程唤醒模型的语义差异，理解管程（Monitor）与信号量的代码结构差异
>实验环境：**Ubuntu22.04，x86-64架构**
# Section2 实验步骤与实验结果
> 实验代码均附于压缩包内
## Assignment 1 自旋锁与信号量复现
### 1.1 基本复现
1. 自旋锁：
	```cpp file:sync.cpp
	SpinLock::SpinLock(){initialize();}
	
	void SpinLock::initialize(){bolt = 0;}
	
	void SpinLock::lock(){
	    uint32 key = 1;
	    do{
			asm_atomic_exchange(&key, &bolt);
		} while (key);}
		
	void SpinLock::unlock(){bolt = 0;}
	```
	信号量：
	```cpp file:sync.cpp
	Semaphore::Semaphore(){initialize(0);}
	
	void Semaphore::initialize(uint32 counter){
	    this->counter = counter;
	    semLock.initialize();
	    waiting.initialize();
	}
	
	void Semaphore::P(){
	    PCB *cur = nullptr;
	    while (true){
	        semLock.lock();
	        if (counter > 0){
	            --counter;
	            semLock.unlock();
	            return;
	        }
	  
	        cur = programManager.running;
	        waiting.push_back(&(cur->tagInGeneralList));
	        cur->status = ProgramStatus::BLOCKED;
	  
	        semLock.unlock();
	        programManager.schedule();
	    }
	}
	
	void Semaphore::V(){
	    semLock.lock();
	    ++counter;
	    if (waiting.size()){
	        PCB *program = ListItem2PCB(waiting.front(), tagInGeneralList);
	        waiting.pop_front();
	        semLock.unlock();
	        programManager.MESA_WakeUp(program);
	    }
	    else{
	        semLock.unlock();
	    }
	}
	```
2. 解决芝士汉堡问题
	```cpp file:setup.cpp
	void a_mother(void *arg){
	    semaphore.P();
	    int delay = 0;
	    printf("mother: start to make cheese burger, there are %d cheese burger now\n", cheese_burger);
	    // make 10 cheese_burger
	    cheese_burger += 10;
	    printf("mother: oh, I have to hang clothes out.\n");
	    // hanging clothes out
	    delay = 0xfffffff;
	    while (delay)--delay;
	    // done
	    printf("mother: Oh, Jesus! There are %d cheese burgers\n", cheese_burger);
	    semaphore.V();
	}
	void a_naughty_boy(void *arg){
	    semaphore.P();
	    printf("boy   : Look what I found!\n");
	    // eat all cheese_burgers out secretly
	    cheese_burger -= 10;
	    // run away as fast as possible
	    semaphore.V();
	}	
	```
3. 参照src\2和src\3下的实现方法，进行复现，执行 `make && make run` 结果如下
	![[Pasted image 20260518103949.png|550]]
### 1.2 替代锁机制实现
选择使用 Bit Test and Set 方法实现
- 这里以 `src\3` 下实现信号量的代码为基础进行改动，由于信号量的实现用到了锁机制，所以只需要在实现BTS锁后将其代换进信号量里的实现即可，一样可以验证实现的正确性；并且，多了一层封装，改动更少更合理
- 实现锁机制：新增 `asm_bts_atomic_exchange` 函数，使用 `lock bts` 原子操作
	```nasm file:asm_utils.asm
	; 将 mem 指向的内存的第 0 位置为 1，并返回旧值
	asm_bts_atomic_exchange:
	    push ebp
	    mov ebp, esp
	    
	    mov ebx, [ebp + 4 * 2]  ; 获取内存地址参数
	    lock bts dword [ebx], 0 ; 原子操作：设置第 0 位，并将原值存入进位标志 CF
	    setc al                 ; 如果 CF=1（原值为 1），al=1；否则 al=0
	    movzx eax, al           ; 零扩展到 eax 作为返回值
	    
	    pop ebp
	    ret
	```
- 封装为CPP类：创建并定义 `BTSLock` 类，并将 `Semaphore` 类中使用的锁改为这个类
	```cpp sync.cpp
	"""类声明（在sync.h中"""
	class BTSLock{
		private:
		    uint32 bolt; // 锁变量
		
		public:
		    BTSLock();
		    void initialize();
		    void lock();
		    void unlock();
	};
	
	BTSLock::BTSLock(){initialize();}
	void BTSLock::initialize(){bolt = 0;}
	void BTSLock::lock(){
	    while (asm_bts_atomic_exchange(&bolt));
	}
	void BTSLock::unlock(){bolt = 0;}
	```
- 由于 `setup.cpp`里使用的是信号量的实现，而我只更改了被封装在信号量实现里的锁，所以对于总体运行逻辑完全无需改动
- 执行修改后代码，验证正确性：
	![[Pasted image 20260518120014.png|550]]
- 分析对比：教程的 xchg 方式需要 key 变量和 do...while 结构，bts 方式更简洁，test-and-set语义天然匹配"检查锁是否空闲并获取锁"这一操作
	  1. 原子性安全：bts 方式只需一个参数，在内存上直接完成原子操作，不存在教程 xchg 方式中"register
	  参数不能为共享变量"的假设隐患
	  2. 语义匹配：bts 的 test-then-set 语义天然对应加锁操作；xchg 需要引入 key=1 的中间变量来模拟
	  test-and-set
	  3. lock 前缀：bts 需显式 lock 前缀（教学上更清晰），xchg 为隐式 lock（初学者可能忽视原子性来源）
	  4. 粒度差异：bts 操作单个 bit，bolt 其余 31 bits 理论上可承载额外信息；xchg 操作完整 dword
- 需要注意的点
	  1. 不要在中断上下文使用：BTSLock 是自旋锁，如果中断处理函数中也尝试获取同一把锁，会造成死锁（单核上中断抢占持有锁的线程，中断里永远等不到释放）。信号量的 semLock 只在 P()/V()的线程上下文中使用，不涉及中断，所以这里是安全的。
	  2. asm_bts 函数必须正确导出：需要在 asm_utils.asm 中加 global asm_bts，在 asm_utils.h 中加 extern "C"uint32 asm_bts(uint32 \*addr)，否则链接阶段会找不到符号。
	  3. P() 中的 while(true) 循环不变式：被 MESA 唤醒的线程重新争锁，拿到锁后必须重新检查 counter >
	  0（因为可能在它被唤醒到获取锁之间，counter已被其他新线程消耗）。这个不变式只依赖于锁的正确性，不依赖于锁的实现方式，所以用 BTSLock 不会破坏它。
	  4. unlock() 的普通写操作：bolt = 0
	  不是原子指令。在多核场景下这可能导致其他核的缓存行不能立即看到更新——但在本实验的单核 QEMU环境下（配合时间中断做调度），上下文切换发生在指令边界，bolt = 0执行完才会被切换，所以安全。如果你未来要考虑多核，应该用 lock and 或 mov + mfence 配合。
## Assignment 2 生产者-消费者问题
### 2.1 展示竞态条件
- 设计实现（在src/3的基础上
	- 缓冲区数组以及共享索引定义
		- buffer[5] — 固定大小的环形缓冲区
		-  in、out、count — 共享索引/计数器（无保护）
		- next_item — 全局条目计数器
	- 生产者和消费者线程定义
		- 2 个生产者线程（P1、P2），每个执行 8 次生产操作
		- 从 next_item 读取并递增
- 代码：
	```cpp file:setup.cpp
	#define BUFFER_SIZE 5
	int buffer[BUFFER_SIZE];
	int in = 0;
	int out = 0;
	int count = 0;
	int next_item = 0;
	
	void producer(void *arg){
		const char *name = (const char *) arg;
		for(int i = 0; i<8; i++){
			int item = next_item;
			next_item++;
	
			int delay = 0xffffff;
			while (delay) --delay;
	
			printf("%s: want to produce item=%d, count=%d, in=%d\n", name, item, count, in);
	
			if (count == BUFFER_SIZE)printf("  *** RACE: %s sees count=%d (FULL) but writes anyway! ***\n", name, count);
	
			buffer[in] = item;
	
			delay = 0xffffff;
			while (delay) --delay;
			in = (in + 1) % BUFFER_SIZE;
			count++;
			printf("  %s: produced item=%d, count=%d, in=%d, out=%d\n", name, item, count, in, out);
		}
	}
	
	void consumer(void *arg)
	{
	    const char *name = (const char *)arg;
	    for (int i = 0; i < 8; ++i)
	    {
	        int delay = 0xffffff;
	        while (delay) --delay;
	
	        printf("%s: want to consume, count=%d, out=%d\n", name, count, out);
	        if (count == 0)printf("  *** RACE: %s sees count=%d (EMPTY) but reads anyway! ***\n", name, count);
	
	        int item = buffer[out];
	        delay = 0xffffff;
	        while (delay) --delay;
	
	        out = (out + 1) % BUFFER_SIZE;
	        count--;
	        printf("  %s: consumed item=%d, count=%d, in=%d, out=%d\n", name, item, count, in, out);
	    }
	}	
	```
	然后在第一个线程里定义两个生产者和两个消费者来演示：
	```cpp file:setup.cpp
	void first_thread(void *arg)
	{
		...
	    in = 0;
	    out = 0;
	    count = 0;
	    next_item = 0;
	    programManager.executeThread(producer, (void *)"P1", "producer1", 1);
	    programManager.executeThread(producer, (void *)"P2", "producer2", 1);
	    programManager.executeThread(consumer, (void *)"C1", "consumer1", 1);
	    programManager.executeThread(consumer, (void *)"C2", "consumer2", 1);
		...
	}
	```
- 会出现的问题
	- 有界缓冲区：溢出或变为负数
	- 生产者和消费者竞态：
		- 在检查和写入之间加入延迟以扩大竞态窗口
		- 即使 count == BUFFER_SIZE也继续写入 — 演示缓冲区溢出
		- 即使 count == 0也继续读取 — 演示空缓冲区读取
	- 总结：
		1. 缓冲区溢出 — 生产者看到过时的 count 值并向已满的缓冲区写入
		2. 空缓冲区读取 — 消费者看到过时的 count 值并从空缓冲区读取
		3. count 不一致 — 对 count 的非原子递增/递减导致计数错误
		4. 数据丢失 — 条目在消费前被覆盖
		5. 重复消费 — 两个消费者读取相同的槽位
- 运行后结果如图，**问题包括**： `count` 为0时C2还要继续读出；读出之后 `count`变为了负数；以及好几个线程同时对 `count` `in` 等进行操作导致变化无常
	![[屏幕截图 2026-05-23 163501.png|600]]
### 2.2 使用信号量解决
- 设计实现（在上一问的基础上）：
	- 三个信号量：
		- `empty` — 初始值为 BUFFER_SIZE(5)，表示空槽位数
		- `full` — 初始值为 0，表示已填充槽位数
		- `mutex` — 初始值为 1，保证互斥访问
	- 生产者 `producer_sema`：P(empty) → P(mutex) → 随后写入buffer → V(mutex) → V(full)
		- 缓冲区满时 empty.P() 阻塞生产者
		- `mutex` 保护对 `buffer`、`in`、`count`、`next_item` 的访问
	
	- 消费者 `consumer_sema`：P(full) → P(mutex) → 读取buffer → V(mutex) → V(empty)
		- 缓冲区空时 full.P() 阻塞消费者
		- `mutex` 保护临界区
	
	- 利用AI实现辅助缓冲区状态打印 `print_buffer_state`()：
		- 显示 [ _ _ 3 4 5 ] 格式的缓冲区内容（_ 表示空槽）
		- 显示 in、out、count 三个索引值
- 代码：
	```cpp file:setup.cpp
	#define BUFFER_SIZE 5
	int buffer[BUFFER_SIZE];
	int in = 0;
	int out = 0;
	int count = 0;
	int next_item = 0;
	Semaphore empty;
	Semaphore full;
	Semaphore mutex;
	
	void producer(void *arg){
	    const char *name = (const char *)arg;
	    for (int i = 0; i < 8; ++i){
	        empty.P();
	        mutex.P();
	
	        int item = next_item;
	        next_item++;
	        buffer[in] = item;
	        in = (in + 1) % BUFFER_SIZE;
	        count++;
	
	        printf("---------\n%s: produced item=%d\n, ", name, item);
	        print_buffer_state();
	
	        mutex.V();
	        full.V();
	    }
	}
	
	void consumer(void *arg){
	    const char *name = (const char *)arg;
	    for (int i = 0; i < 8; ++i){
	    	full.P();
	    	mutex.P();
	    	
	    	int item = buffer[out];
	    	out = (out + 1) % BUFFER_SIZE;
	    	count--;
	        printf("----------\n%s: consumed item=%d\n", name, item);
	        print_buffer_state();
	        
	        mutex.V();
	        empty.V();
	     }
	}
	
	void print_buffer_state(){
	    printf("  buffer: [");
	    for (int i = 0; i < BUFFER_SIZE; ++i)
	    {
	        if (i > 0) printf(" ");
	        bool valid = false;
	        if (count > 0)
	        {
	            int idx = out;
	            for (int j = 0; j < count; ++j)
	            {
	                if (idx == i)
	                {
	                    valid = true;
	                    break;
	                }
	                idx = (idx + 1) % BUFFER_SIZE;
	            }
	        }
	        if (valid) printf("%d", buffer[i]);
	        else printf("_");
	    }
	    printf("] in=%d out=%d count=%d\n", in, out, count);
	}
	```
- 运行结果：可以看到非常有序地进行读和写
	![[屏幕截图 2026-05-23 174927.png|600]]
### 2.3 读者-写者问题
- 同步机制:

| 信号量     | 初值  | 作用                                            |
| ------- | --- | --------------------------------------------- |
| `lock`  | 1   | 控制对 `shared_value`的访问，写者必须获取，第一个读者获取、最后一个读者释放 |
| `mutex` | 1   | 保护 `read_count` 的互斥访问                         |

- 读者优先算法
	读者：`P(mutex)` → `read_count++` → 若 `read_count=1` 则 `P(lock)` →`V(mutex)` → 读 → `P(mutex)` → `read_count--` → 若 `read_count=0` 则 `V(lock)` →`V(mutex)`
	写者：`P(lock)` → 写 → `V(lock)`
- 饥饿演示设计
	- 5 个读者，每个执行 6 次读循环：`think → enter → read → exit → repeat`
	- 1 个写者，执行 4 次写操作
	- 创建多个读者，并且读者在临界区内的延迟较小，在临界区外的思考时间灵活，进入临界区，然后完成一段时间的任务（`delay()`模拟），退出，等待下一次任务——读者交错进出，不会在临界区内占着一直不出来
	- 写者打印 `WAITING for lock...` 消息进行等待，吐过最后一个读者释放 lock唤醒了写者，另一个"思考中"的读者在写者被调度之前抢到 `mutex`成为新的"第一个读者"并拿走锁，就造成了写者饥饿现象
- 利用AI实现伪随机数生成器
	 1. 模拟非临界区的计算任务 在现实世界的程序中，线程不会只是一味地读写共享资源。它通常会遵循“读取数据 -> 处理数据（思考） -> 写入结果”的模式。 thinking 模拟了线程在获取锁之前或释放锁之后，执行与共享资源无关的本地计算任务的时间
	2. 增加线程交替（Interleaving）的可能性 如果不进行“思考”直接进入循环，由于 CPU 执行速度极快，可能出现以下情况：线性同余生成器（LCG）：seed = 1103515245 × seed + 12345，用 delay_rand(max)产生可变延迟使调度不可预测

- 代码：
	```cpp file:setup.cpp
	Semaphore lock;   // 控制对共享资源的访问, 初始=1
	Semaphore mutex;  // 保护read_count, 初始=1
	int read_count = 0;
	int shared_value = 0;
	
	// 简单线性同余伪随机数生成器 (LCG)
	uint32 rand_seed = 12345;
	uint32 my_rand()
	{
	    rand_seed = 1103515245 * rand_seed + 12345;
	    return rand_seed;
	}
	
	void delay_rand(uint32 max)
	{
	    uint32 d = my_rand() % max;
	    while (d)
	        --d;
	}
	
	void reader(void *arg)
	{
	    const char *name = (const char *)arg;
	    for (int i = 0; i < 6; ++i)
	    {
	        // 思考/等待一段时间
	        printf("%s: thinking...\n", name);
	        delay_rand(0x8fffff);
	
	        // 进入读临界区
	        mutex.P();
	        read_count++;
	        if (read_count == 1)
	        {
	            lock.P();
	            printf("%s: First reader, Locked~\n", name);
	        }
	        mutex.V();
	
	        // 读临界区 
	        printf("%s: Reading... shared_value=%d, read_count=%d\n", name, shared_value, read_count);
	        // 停留一段时间 
	        delay_rand(0x4fffff);
	
	        // 退出读临界区
	        mutex.P();
	        read_count--;
	        printf("%s: Done, read_count=%d\n", name, read_count);
	        if (read_count == 0)
	        {
	            lock.V();
	            printf("%s: Last reader, release Lock\n", name);
	        }
	        mutex.V();
	    }
	}
	
	void writer(void *arg)
	{
	    const char *name = (const char *)arg;
	    for (int i = 0; i < 4; ++i)
	    {
	        // 等待一段时间再尝试写
	        printf("%s: thinking...\n", name);
	        delay_rand(0xafffff);
	
	        printf("%s: wants to write, WAITING for lock...\n", name);
	
	        lock.P();
	        // === 写临界区 ===
	        shared_value++;
	        printf("%s: Writing in... shared_value=%d\n", name, shared_value);
	        delay_rand(0x3fffff);
	        
	        lock.V();
	        printf("%s: Done\n", name);
	    }
	}
		
	```
- 运行结果如图，可以看到写者直到 读者 `lock`释放之后再开始写入
	![[屏幕截图 2026-05-23 184918.png|600]]
## Assigment 3 哲学家就餐问题
### 3.1 初步解决方法
- 数据结构
	- chopsticks[5] — 5 个信号量，代表 5 根筷子，每根初始值均为 1
	- 哲学家 i 需要：左筷子 = i，右筷子 = (i+1) % 5
	- 创建5个哲学家线程
- 哲学家线程
	每个哲学家循环 5 次：思考 → 饿了 → P(左筷子) → P(右筷子) → 吃饭 → V(右筷子) → V(左筷子)
	- 思考：随机延迟（临界区外）
	- 拿左筷子：chopsticks[left].P()
	- 拿右筷子：chopsticks[right].P()
	- 吃饭：随机延迟（模拟进食）
	- 放筷子：先放右、后放左
- 每个动作伴随着一个打印
- 代码：
	```cpp file:setupp.cpp
	#define N 5
	Semaphore chopsticks[N];
	
	void philosopher(void *arg)
	{
	    int id = (int)arg;
	    int left = id;
	    int right = (id + 1) % N;
	
	    for (int i = 0; i < 5; ++i)
	    {
	        // thinking
	        printf("Philosopher %d: thinking...\n", id);
	        delay_rand(0xafffff);
	
	        // hungry, try to pick up chopsticks
	        printf("Philosopher %d: hungry, picking up chopsticks\n", id);
	
	        chopsticks[left].P();
	        printf("  Philosopher %d: picked up left chopstick %d\n", id, left);
	
	        chopsticks[right].P();
	        printf("  Philosopher %d: picked up right chopstick %d, EATING\n", id, right);
	
	        // eating
	        delay_rand(0x6fffff);
	
	        // put down chopsticks
	        chopsticks[right].V();
	        printf("  Philosopher %d: put down right chopstick %d\n", id, right);
	
	        chopsticks[left].V();
	        printf("  Philosopher %d: put down left chopstick %d, done eating\n", id, left);
	    }
	}
	```
- 运行结果如图：
	![[屏幕截图 2026-05-23 194130.png|600]]
	![[屏幕截图 2026-05-23 194207.png|600]]
	可以看到五个哲学家会轮流用餐，并且打印了每一个的状态，这里因为设置的 `delay` 是比较短的，所以没有出现死锁之类的现象
### 3.2 死锁演示
 - 稳定复现死锁：
	只要让所有哲学家都拿起了左边筷子而没有拿起右边筷子即可。可以看到，在上一题中，实际是有这种可能性的，只是延迟太短，导致CPU执行太快直接按顺序给哲学家用餐了，所以这里只需要在拿起左右筷子之间插入更更更更更长的延时即可，也就是修改 `delay()`函数
	P(左筷子) → delay(0xfffffff) → P(右筷子)
- 5 个同优先级的哲学家在 round-robin 调度下：
	  1. P0 拿左筷0 → delay → 时间片耗尽，被抢占
	  2. P1 拿左筷1 → delay → 被抢占
	  3. P2 拿左筷2 → delay → 被抢占
	  4. P3 拿左筷3 → delay → 被抢占
	  5. P4 拿左筷4 → delay → 被抢占
	  6. 现在 5 人都拿着左筷子，全部阻塞在 chopsticks[right].P() 上
	  7. P0 等筷1（P1 拿着）、P1 等筷2（P2 拿着）... P4 等筷0（P0 拿着）→ 循环等待 → 死锁
- 由于第一次就会死锁，"EATING" 之后的代码都执行不到，所以把哲学家函数里的循环也去掉，执行一次即可
- **四个必要条件**在此场景中的体现

| 条件    | 体现                |
| ----- | ----------------- |
| 互斥访问  | 每根筷子是初值为 1 的信号量   |
| 持有并等待 | 哲学家持有左筷子，等待右筷子    |
| 不可剥夺  | 只能由持有者主动释放筷子      |
| 循环等待  | P0→P1→P2→P3→P4→P0 |

- 代码：
	```cpp file:setup.cpp
	#define N 5
	Semaphore chopsticks[N];
	
	void delay()
	{
	    uint32 d = 0xfffffff;
	    while (d) --d;
	}
	
	void philosopher(void *arg)
	{
		int id = (int)arg;
		int left = id;
		int right = (id + 1) % N;
		printf("Philosopher %d: thinking...\n", id);
	
		// hungry, try to pick up chopsticks
		printf("Philosopher %d: hungry, picking up chopsticks\n", id);
		chopsticks[left].P();
		printf("  Philosopher %d: picked up left chopstick %d\n", id, left);
	
		delay();
	
		chopsticks[right].P();
		printf("  Philosopher %d: picked up right chopstick %d, EATING\n", id, right);
	
		//eating...(Deadlock)
		delay();
	
		// put down chopsticks
		chopsticks[right].V();
		printf("  Philosopher %d: put down right chopstick %d\n", id, right);
	
		chopsticks[left].V();
		printf("  Philosopher %d: put down left chopstick %d, done eating\n", id, left);
	}
	```
- 运行结果：可以看到五个哲学家轮流拿起了左边的筷子，然后就卡住了，陷入死锁
	![[Pasted image 20260523200746.png|600]]
### 3.3 死锁解决方案
- 解决：奇偶编号策略
	只需要在上一题实现的基础上，对于拿起左边筷子和拿起右边筷子这两个动作之前，先判断哲学家的编号即可——如果是奇数则先执行拿左边筷子，如果是偶数就先执行拿右边筷子。其他部分都不需要改动
- **破坏死锁原理**：原先是因为有可能每个人都拿起了左边的筷子，导致循环等待。这里由于不会每一人都先去拿自己同一侧的筷子，所以避免了循环等待
- 代码：
	```cpp file:setup.cpp
	void philosopher(void *arg)
	{
	    ...
	    if(id%2 == 0){
	        printf("Philosopher %d: trying to pick up right chopstick %d\n", id, right);
	        chopsticks[right].P();
	        printf("  Philosopher %d: picked up right chopstick %d, EATING\n", id, right);
	
	        delay();
	
	        printf("Philosopher %d: hungry, picking up left chopstick %d\n", id, left);
	        chopsticks[left].P();
	        printf("  Philosopher %d: picked up left chopstick %d\n", id, left);
	    }
	    else{
	        printf("Philosopher %d: hungry, picking up left chopstick %d\n", id, left);
	        chopsticks[left].P();
	        printf("  Philosopher %d: picked up left chopstick %d\n", id, left);
	
	        delay();
	
	        printf("Philosopher %d: trying to pick up right chopstick %d\n", id, right);
	        chopsticks[right].P();
	        printf("  Philosopher %d: picked up right chopstick %d, EATING\n", id, right);
	    }
	    ...
	}
	```
- 运行结果：可以看到哲学家0~4都输出了 `done eating` 
	![[屏幕截图 2026-05-23 213142.png|600]]
## Assignment 4 选做题
### 4.1 Hoare/Hasen 唤醒模型
  - **三种唤醒模型**

| 模型    | 唤醒者  | 被唤醒者    | 适用场景                             |
| ----- | ---- | ------- | -------------------------------- |
| MESA  | 继续跑  | 进就绪队列排队 | 实际通用，锁的实现简单，适合不精确的唤醒，没有显式指定      |
| Hoare | 立刻阻塞 | 立刻运行    | 对执行顺序有严格要求的场景；条件保证场景；实时系统；理论教学研究 |
| Hasen | 继续跑  | 保证下一个运行 | 保证被唤醒者拿到资源；复杂度和易读性的折中            |

- Hoare实现：基于src/3
	- sync.h — 新增 HoareSemaphore 类
	  - 多了一个 PCB \*signaler 成员，记录被阻塞的唤醒者
	  - P() 用 if 实现而非 while
	- sync.cpp — 实现 Hoare 的 P/V：
	  1. 如果 signaler 不为空说明被唤醒的线程完成了，把唤醒者叫起来，释放资源
	  2. 如果没人在等，则counter++
	  3. Hoare 唤醒：从等待队列取一个线程，把自己（唤醒者）阻塞，存入 signaler，然后 schedule()立刻切换到被唤醒的线程
- 逻辑：
	Hoare: A调用V() → B标记READY → A阻塞自己 → schedule()立即切换 → B马上运行然后调用V() → 发现signaler(A) → 唤醒A → A继续
- 期望输出：
	  Hoare mother: making burger...
	  Hoare boy: eating burger! 
	  Hoare mother: after V()
- 代码：
	Hoare模型的实现
	```cpp file:sync.cpp
	HoareSemaphore::HoareSemaphore(){initialize(0);}
	void HoareSemaphore::initialize(uint32 counter)
	{
	    ...
	    signaler = nullptr;
	}
	void HoareSemaphore::P()
	{
	    PCB *cur = nullptr;
	    semLock.lock();
	    if (counter > 0)
	    {
	        --counter;
	        semLock.unlock();
	        return;
	    }
	    //没有空闲资源，必须等待
	    cur = programManager.running;
	    waiting.push_back(&(cur->tagInGeneralList));
	    cur->status = ProgramStatus::BLOCKED;
	
	    semLock.unlock();
	    programManager.schedule();
	    //被唤醒之后会直接获得资源并运行，打断原先正在运行的线程
	}
	void HoareSemaphore::V()
	{
	    PCB *woken = nullptr;
	    PCB *sig = nullptr;
	
	    semLock.lock();
	
	    if (signaler != nullptr)
	    {
	        //本线程是由原先其他线程唤醒的，则需要归还
	        sig = signaler;
	        signaler = nullptr;
	        sig->status = ProgramStatus::READY;
	        programManager.readyPrograms.push_front(&(sig->tagInGeneralList));
	
	        if (waiting.empty())
	        {
	            ++counter;
	        }
	        else
	        {
	            //立即移交资源给后面的线程
	            woken = ListItem2PCB(waiting.front(), tagInGeneralList);
	            waiting.pop_front();
	            woken->status = ProgramStatus::READY;
	            programManager.readyPrograms.push_front(&(woken->tagInGeneralList));
	        }
	
	        semLock.unlock();
	        return;
	    }
	
	    if (waiting.empty())
	    {
	        ++counter;
	        semLock.unlock();
	        return;
	    }
	
	    //立即移交资源
	    woken = ListItem2PCB(waiting.front(), tagInGeneralList);
	    waiting.pop_front();
	    woken->status = ProgramStatus::READY;
	
	    sig = programManager.running;
	    sig->status = ProgramStatus::BLOCKED;
	    signaler = sig;
	
	    //被唤醒的线程直接放到队列最前端
	    programManager.readyPrograms.push_front(&(woken->tagInGeneralList));
	
	    semLock.unlock();
	    programManager.schedule();
	    //调度
	}
		
	```
	运行时可以在 `setup.cpp` 中选择执行某一个模型（注释掉另一个）：
	```cpp file:setup.cpp
	void first_thread(void *arg)
	{
	    ...
	    printf("---------------- MESA Model ----------------\n");
	    mesaSem.initialize(1);
	    programManager.executeThread(mesa_mother, nullptr, "mesa_mother", 1);
	    programManager.executeThread(mesa_boy, nullptr, "mesa_boy", 1);
	    printf("---------------- Hoare Model ----------------\n");
	    hoareSem.initialize(1);
	    programManager.executeThread(hoare_mother, nullptr, "hoare_mother", 1);
	    programManager.executeThread(hoare_boy, nullptr, "hoare_boy", 1);
	    ...
	}
	```
- 出现问题：在Hoare方案里，mother线程在调用 `HoareSemaphore::V()` 之后boy线程并没有立即抢占执行，而是在mother执行完之后才执行，导致变成了和MESA方案一样的结果
	![[屏幕截图 2026-05-24 143136 1.png|600]]
- 原因分析：
	可能是mother线程里的delay不够，导致在mother调用 `HoareSemaphore::V()`的那一瞬间，在 `setup.cpp`里还未执行 `programManager.executeThread(hoare_boy, nullptr, "hoare_boy", 1)`，也就是boy可能都还没创建，自然导致即使mother让出也没有没有来抢占的线程，进而mother重新继续执行完；随后boy线程姗姗来迟
- 修改：对mother线程增加delay时间
	```cpp file:setup.cpp
	void hoare_mother(void *arg)
	{
	    hoareSem.P();
	    printf("Hoare mother: making burger...\n");
	    
	    int delay = 0xffffffff;
	    while(delay) --delay;
	
	    hoareSem.V();
	    printf("Hoare mother: done V()\n");
	    // this prints AFTER boy runs
	}
	```
- 运行结果&对比线程执行顺序：可以看到在Hoare实现中，mother线程在让出之后确实立即中断了，然后是boy线程执行完毕才归还资源，随后mother线程执行最后一步
	![[屏幕截图 2026-05-24 143036.png|600]]
	![[Pasted image 20260524162618.png|600]]
### 4.2 管程实现
- 管程基本结构：
	- 一个互斥锁：`SpinLock monitorMutex`
	- 两个条件变量：
		  `ConditionVariable notFull`/"缓冲区没满"
		  `ConditionVariable notEmpty`  "缓冲区没空"
- 管程实现：
	- `wait()` 释放锁、阻塞自己、被唤醒后重新拿锁
		  1. 把自己加入 `waiting` 队列（此时还持有锁，signal 不会错过我）
		  2. `lock.unlock()` + `schedule()` — 原子地放锁并让出 CPU
		  3. 被唤醒后 `lock.lock()` — 重新拿回锁
	- `signal()` 唤醒一个正在等的线程
		  1. 从等待队列取出一个线程
		  2. 设为 READY，放到就绪队列最前面
		  3. 自己继续跑（MESA），被唤醒者等调度  
- 采用 Assignment 2 中的问题作为基础，在此基础上将其信号量的方法改为管程来实现
- **管程跟信号量方案的区别**

|        | 信号量                        | 管程                        |
| ------ | -------------------------- | ------------------------- |
| 结构     | 3 个信号量（empty, full, mutex） | 1 把锁 + 2 个条件变量            |
| 条件表达   | 用 empty或者full 来判断          | 直接while(count=SIZE)       |
| P/V 顺序 | 先等待empty空位 后拿 mutex互斥锁     | 只有一个锁，直接拿；后续再检查是否 notFULL |
| 阻塞/唤醒  | P() 阻塞，V() 唤醒              | wait() 阻塞，signal() 唤醒     |

- 代码
	```cpp file:sync.cpp
	ConditionVariable::ConditionVariable(){initialize();}
	void ConditionVariable::initialize(){waiting.initialize();}
	void ConditionVariable::wait(SpinLock &lock)
	{
	    PCB *cur = programManager.running;
	    waiting.push_back(&(cur->tagInGeneralList));
	    cur->status = ProgramStatus::BLOCKED;
	
	    lock.unlock();
	    programManager.schedule();
	
	    lock.lock();
	}
	void ConditionVariable::signal()
	{
	    if (waiting.size())
	    {
	        PCB *program = ListItem2PCB(waiting.front(), tagInGeneralList);
	        waiting.pop_front();
	        program->status = ProgramStatus::READY;
	        programManager.readyPrograms.push_front(&(program->tagInGeneralList));
	    }
	}
	```
	```cpp file:setup.cpp
	void producer_monitor(void *arg)
	{
	    const char *name = (const char *)arg;
	    for (int i = 0; i < 8; ++i)
	    {
	        monitorMutex.lock();
	        while (count == BUFFER_SIZE) notFull.wait(monitorMutex);
	
	        int item = next_item;
	        next_item++;
	        buffer[in] = item;
	        in = (in + 1) % BUFFER_SIZE;
	        count++;
	
	        printf("Monitor %s: produced item=%d, ", name, item);
	        print_buffer_state();
	
	        notEmpty.signal();
	        monitorMutex.unlock();
	        int delay = 0xfffff;
	        while (delay) --delay;
	    }
	}
	
	void consumer_monitor(void *arg)
	{
	    const char *name = (const char *)arg;
	    for (int i = 0; i < 8; ++i)
	    {
	        monitorMutex.lock();
	        while (count == 0) notEmpty.wait(monitorMutex);
	
	        int item = buffer[out];
	        out = (out + 1) % BUFFER_SIZE;
	        count--;
	
	        printf("Monitor %s: consumed item=%d, ", name, item);
	        print_buffer_state();
	
	        notFull.signal();
	        monitorMutex.unlock();
	        int delay = 0xfffff;
	        while (delay) --delay;
	    }
	}
	```
- 运行结果：可以看到正确实现，跟使用信号量的结果一致
	![[屏幕截图 2026-05-24 151332.png|600]]
## 思考题
1. 实现自旋锁时，通常调用 `asm_atomic_exchange(&key, &bolt)` 这里的 bolt 是多个线程竞争的共享锁变量，而 key 通常是一个局部变量（在线程自己的栈上）。
	- 原子性限制 ：硬件指令（如 X86 的 xchg ）通常只能保证“一个寄存器与一个内存地址”或“两个寄存器”之间的原子交换。它无法原子地交换“两个独立的内存地址”。
	- 逻辑隔离 ： key 的作用是存放线程尝试获取锁的结果。如果 key 也是共享的，那么在原子交换完成到你检查 key 的值（ while(key) ）这段极短的时间内，另一个线程可能会修改这个共享的 key ，导致当前线程读到错误的状态，从而破坏锁的逻辑。
	违反假设的问题 ：
	如果 key 是共享变量，可能会出现“明明拿到了锁，但因为 key 被别人改了，导致线程以为没拿到而继续等待”或者“两个线程都以为自己拿到了锁”的竞态条件
2. 信号量的阻塞唤醒与循环检查
	实现阻塞和唤醒：
	- 阻塞 ：当资源不足（ counter == 0 ）时，当前线程（ programManager.running ）的状态被设为 BLOCKED ，并被放入信号量的 waiting 队列中，随后调用 schedule() 主动让出 CPU。
	- 唤醒 ：当另一个线程调用 V() 操作时，它从 waiting 队列中取出一个 PCB，通过 MESA_WakeUp 将其状态改为 READY 并放入就绪队列，等待调度器重新选中它。
	 P 操作要在 while 循环中检查 counter： 
	 - 为了应对 Mesa 模型下的“虚假唤醒”或“资源抢占”问题
	- 当线程被唤醒并放入就绪队列后，到它真正抢到 CPU 执行之间，可能存在时间差。
	- 在这段时间内，可能有一个新来的、优先级更高的线程正好执行了 P 操作并抢走了刚刚释放的资源。
	- 如果不使用 while 重新检查，被唤醒的线程会盲目地认为资源还在，直接减去 counter （此时 counter 已经是 0 了），导致资源计数变为负数，逻辑崩溃
3. 单核与多核 CPU 的锁机制差异
	单核 CPU：开/关中断有效 在单核环境下，并发是通过线程切换实现的，而线程切换的唯一触发点是 中断
	- 如果关闭了中断，当前线程就绝对不会被剥夺 CPU 控制权，也不会有其他线程运行。因此，关中断能完美实现对共享资源的互斥访问。
	多核 CPU：开/关中断失效 在多核环境下，多个 CPU 核心是物理上并行运行的。
	- 即使核心 A 关闭了中断，核心 B 依然在正常运行，并且可以访问同一块内存地址。
	- 关中断只能保证“当前核心”不发生线程切换，无法约束“其他核心”对共享变量的读写。因此，多核环境下必须依赖硬件提供的原子指令
4. 自旋锁的优缺点与适用场景
	优缺点：
	- 优点 ： 响应速度快，不需要像信号量经历“状态切换 -> 存入队列 -> 触发调度 -> 上下文切换”的繁琐过程。如果锁很快就会释放，而且更节省开销
	- 缺点 ： 浪费 CPU 资源 。在等待期间，线程处于“忙等”状态，占用 CPU 却不做事情
	适用场景 ： 自旋锁比信号量更合适的场景
	1. 临界区非常短 ：执行临界区代码的时间甚至比一次上下文切换的时间还短。
	2. 多核环境且不允许睡眠 ：例如在中断处理程序中，由于中断上下文不能阻塞，只能使用自旋锁。
	3. 已知等待时间短
# 总结与心得
总结：
	本次实验学习实现了线程同步机制
	  1. 硬件原子指令
		  xchg指令是实现所有锁的根基——它保证"读-改-写"操作在总线层面是原子的，不会被其他 CPU 或 DMA打断。基于 xchg 实现的自旋锁是最简单的互斥原语：拿不到就在原地转圈，适合保护极短的临界区。
	  2. 信号量
		  在自旋锁的基础上加入等待队列和调度器配合，实现了 P() 和 V()操作，信号量不仅能做互斥（counter=1），还能做同步（counter=0 时生产者等消费者，counter=N时消费者等生产者）。线程在 P() 中阻塞时会主动让出 CPU（调用schedule()），避免了自旋锁的忙等待浪费。
	  3. 管程
		  管程是对信号量的进一步封装——把"条件判断"从隐式的 counter 变为显式的while(condition) wait()，代码意图更清晰。条件变量 wait/signal替代了信号量的计数语义，使得复杂的同步逻辑更容易编写和维护。
	  横向对比：三种唤醒模型。 MESA 是实用主义的产物（实现简单、while 兜底），Hoare
	  是理论模型的基准（唤醒即运行、条件可保证），Hasen 是两者的折中
心得：
1. 并发 bug 是概率性的
	在生产者-消费者竞态条件演示中，不加锁的程序不是每次都崩溃——可能跑几次才出一次错。并发调试的困难：不能因为"跑着没问题"就以为代码是对的
2. 锁的顺序很重要
	信号量方案中，empty.P() 和 mutex.P() 的顺序如果写反就会死锁。管程只用一把锁，消除了这个陷阱
3. 线程执行：要安排时间与顺序
	实现Hoare 模型时遇到了输出与MESA模型一样的输出，原来是因为mother线程的delay太短了，导致mother线程快速执行完毕之后boy线程才生成
4. 同步机制的实现本质：拿到资源的线程要“告诉”所有线程，资源正在被占用；退出时候不仅释放资源，还要主动把其他线程给唤醒，让出锁