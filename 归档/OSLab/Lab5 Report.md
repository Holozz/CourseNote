# Section1 实验要求与实验概述
实验要求：阅读README.md并完成四个实验任务和思考题
实验概述：
	在本次实验中，我们将会学习到C语言的可变参数机制的实现方法。在此基础上，我们会揭开可变参数背后的原理，进而实现可变参数机制。实现了可变参数机制后，我们将实现一个较为简单的printf函数。此后，我们可以同时使用printf和gdb来帮助我们debug
	本次实验另外一个重点是内核线程的实现，我们首先会定义线程控制块的数据结构——PCB。然后，我们会创建PCB，在PCB中放入线程执行所需的参数。最后，我们会实现基于时钟中断的时间片轮转(RR)调度算法。在这一部分中，我们需要重点理解 `asm_switch_thread`是如何实现线程切换的，体会操作系统实现并发执行的原理
实验目标：
- 格式化输出层 ：通过理解 C 语言可变参数机制（ stdarg.h ），在内核中实现 printf 函数，为后续调试提供“可见性”。
- 数据结构层 ：设计并实现线程控制块（PCB），管理每个线程独立的内核栈空间。
- 执行流切换层 ：编写汇编级上下文切换函数 asm_switch_thread ，掌握通过修改 esp 寄存器实现“灵魂交换”的底层技术。
- 策略调度层 ：实现从简单的 RR（时间片轮转）到复杂的优先级抢占式调度算法，并学习如何通过阻塞（Sleep）与唤醒（Wakeup）管理线程生命周期。

>实验环境：**Ubuntu22.04，x86-64架构**
# Section2 实验步骤与实验结果
> 实验代码均附于压缩包内
## Assignment 1 printf的实现
### 1.1 基本printf
利用材料里的代码，添加自己的测试语句：
```cpp file:setup.cpp
printf("print percentage: %%\n"
           "print char \"N\": %c\n"
           "print string \"Hello World!\": %s\n"
           "print decimal: %d\n"
           "print decimal: %d\n"
           "print decimal: %d\n",
           'N', "Hello World!", -1, 3,23);
```
使用Makefile进行编译运行，结果如下
![[屏幕截图 2026-05-07 134205.png|600]]
### 1.2 增强printf
这里仿照 `%d` 和 `%x` 实现 八进制转换 `%o` 和无符号整数转换 `%u`。对于八进制转换，只需要仿照十六进制，将传入 `itos()` 的参数改为8即可；对于无符号整数，则只需要在转换为字符串之前加上符号，再对负数取反即可。关键代码如下
```cpp file:stdio.cpp
case 'd':
	temp = va_arg(ap, int);
	if (temp < 0)
	{
		counter += printf_add_to_buffer(buffer, '-', idx, BUF_LEN);
		temp = -temp;
	}
	itos(number, temp, 10);
	for (int j = 0; number[j]; ++j)
	{
		counter += printf_add_to_buffer(buffer, number[j], idx, BUF_LEN);
	}
	break;
	
case 'x':
	temp = va_arg(ap, int);
	itos(number, temp, 16);
	for (int j = 0; number[j]; ++j)
	{
		counter += printf_add_to_buffer(buffer, number[j], idx, BUF_LEN);
	}
	break;

case 'o':
	temp = va_arg(ap, int);
	itos(number, temp, 8);
	for (int j = 0; number[j]; ++j)
	{
		counter += printf_add_to_buffer(buffer, number[j], idx, BUF_LEN);
	}
	break;

case 'u':
	temp = va_arg(ap, int);
	if (temp < 0){
		counter += printf_add_to_buffer(buffer, '-', idx, BUF_LEN);
		temp = -temp;
	}
	itos(number, temp, 10);
	for (int j = 0; number[j]; ++j)
	{
		counter += printf_add_to_buffer(buffer, number[j], idx, BUF_LEN);
	}
	break;

```
结果如下
![[Pasted image 20260507143817.png|600]]
![[Pasted image 20260507143750.png|600]]
## Assignment 2 线程的实现
### 2.1 基本线程
这里我给PCB类对象加上了 `color` 属性，使得不同线程打印出来是不同颜色以便区分；
这里的想法是，为了避免将所有地方的print函数都改为带颜色参数的麻烦，直接在`print()` 内部去检查当前运行线程的颜色并打印带颜色的字符即可，不用改动参数列表；
最后，为了使每次线程运行的时间更明显，在自定义函数内部使用了十万次循环
```cpp
"thread.h"
struct PCB
{
	...
    uint8 color;
    ...
};
"program.cpp"
int ProgramManager::executeThread(ThreadFunction function, void *parameter, const char *name, int priority, uint8 color)
{
	...
    thread->color = color;
    ...
}
"stdio.cpp"
void STDIO::print(uint8 c)
{
    uint8 color = 0x07;
    if(programManager.running->color) color = programManager.running->color;
    print(c, color);
}

```
结果如下
![[屏幕截图 2026-05-07 212545.png|600]]
### 2.2 多线程并发展示
利用上一题的颜色设计，这里可以让不同的线程**不仅打印在不同行**，**还能以不同颜色打印**以便区分；
这里将三个线程作为 `first_thread` 的子线程进行创建；
每个线程的函数内末尾都有一个**2000000的空循环以能够观察**到线程切换的效果；
每个线程都会**输出自己的PID和执行次数**
```cpp file:setup.cpp
void my_thread(void *arg)
{
    int line = (int)arg;
    int count = 0;
    while (1)
    {
        // 防止打印时被切换导致光标错位
        bool status = interruptManager.getInterruptStatus();
        interruptManager.disableInterrupt();

        stdio.moveCursor(line, 0);
        printf("Thread %s (PID %d) is running. Counter: %d    ", 
               programManager.running->name, 
               programManager.running->pid, 
               count++);

        interruptManager.setInterruptStatus(status);

        // 延时以便观察
        for (int i = 0; i < 2000000; ++i);
    }
}
void first_thread(void *arg)
{
    printf("First thread (Main) started. Creating workers...\n");
    
    // 三个线程，分别在第 5, 10, 15 行打印，颜色分别为绿、红、蓝
    programManager.executeThread(my_thread, (void *)5, "A", 1, 0x02);
    programManager.executeThread(my_thread, (void *)10, "B", 1, 0x04);
    programManager.executeThread(my_thread, (void *)15, "C", 1, 0x01);

    while(1) {
        asm_halt();
    }
}
```
输出结果如下，可以看到每个线程在轮流切换执行，具体顺序是A->B->C，A先执行
![[屏幕截图 2026-05-07 213050 1.png|600]]
![[屏幕截图 2026-05-07 213059.png|600]]
## Assignment 3 线程调度切换的秘密
### 3.1 跟踪线程切换
1. 首先使用 `b asm_switch_thread` 设置断点，并设置 `display /i $pc` `layout asm` 开启汇编窗口和反汇编
   ![[屏幕截图 2026-05-08 103303.png|600]]
2. 使用 `si` 单步运行跟踪执行
3. 首先在push ebp , ebx , edi , esi 执行前查看这几个寄存器的内容：
	   ![[屏幕截图 2026-05-08 145918.png|600]]
	   还有栈和pc地址：
	   ![[屏幕截图 2026-05-08 145945.png|600]]
	   push ebp , ebx , edi , esi执行后再查看一次寄存器内容：
	   ![[屏幕截图 2026-05-08 150233.png|600]]
	   ![[屏幕截图 2026-05-08 150255.png|600]]
4. 使用 `x /10x $esp` 观察栈地址在两个线程切换前后的变化
   先查看一开始的
   ![[屏幕截图 2026-05-08 103331.png|600]]
   然后查看push ebp , ebx , edi , esi 执行后，栈指针 $esp 的变化：
   ![[屏幕截图 2026-05-08 103417.png|600]]
   此时eax里是：
   ![[屏幕截图 2026-05-08 150529.png|600]]
   然后把当前的栈顶地址 $esp 存进了旧线程的 PCB 里，输入 x /x $eax 验证一下：
   ![[屏幕截图 2026-05-08 150631.png|600]]
   切换后可以看到esp发生了变化，已经是新的线程：
   ![[屏幕截图 2026-05-08 103457.png|600]]
   ![[屏幕截图 2026-05-08 151711.png|600]]
   ![[屏幕截图 2026-05-08 151744.png|600]]
5. 切换完成后，再次查看寄存器的内容，发现都变成了新的线程的初始化值**0**：
   ![[Pasted image 20260508152108.png|400]]
6. 最后执行 `ret` ：发现跳回到函数开头
   ![[屏幕截图 2026-05-08 152253.png|600]]
### 3.2 分析线程栈布局
如图：
![[Pasted image 20260508155417.png|600]]
- `esp`指向的位置如图
- `ebp` `ebx` `edi` `esi` 保存的位置如图
- `function` `parameter` `program_exit` 的位置如图
- `ret` 执行后，
  对于新创建的线程来说：pop出四个寄存器，栈顶变成 `function` ，执行 `ret` 后CPU就弹出 `function` 存到 `eip` ，程序跳转到线程函数开始执行
  对于被中断后保存上下文的线程来说：该线程被重新换上， `asm_switch_thread` 先 `pop` 恢复通用寄存器，然后 `ret` 回到 `schedule` 函数。最终由中断处理程序的 `iret` 指令弹出栈中的 `EIP` ，使 `eip` 回到线程被中断的那一行
## Assignment 4 调度算法的实现
### 4.1 实现一种调度算法
这里来实现优先级调度算法
1. 更新 `executeThread()` 函数的参数列表，同时接收 `priority` 和 `ticks` ，以便实现不同优先级和执行时间的线程
	```cpp file:program.cpp
	int ProgramManager::executeThread(ThreadFunction function, void *parameter, const char *name, int priority, int ticks, uint8 color)
	{
		...
	thread->ticks = ticks;
		...
	}
	```
	
2. 抢占的机制：每次时钟中断时检查 `readyPrograms` 中是否有优先级高于当前线程的线程，如果有就立即换下，以实现抢占式的优先级调度
	```cpp file:interrupt.cpp
	extern "C" void c_time_interrupt_handler() {
	    PCB *cur = programManager.running;
	    cur->ticksPassedBy++;
	    // 检查就绪队列是否有更高优先级的线程
	    ListItem *iter = programManager.readyPrograms.front();
	    while(iter) {
	        if (ListItem2PCB(iter, tagInGeneralList)->priority > cur->priority) {
	            programManager.schedule(); // 发现更高优先级，立即抢占
	            break;
	        }
	        iter = iter->next;
	    }
	}
	```
	
3. 挑选最高优先级线程，需要在`readyPrograms` 链表中遍历寻找优先级最高的节点
	```cpp file:program.cpp
	void ProgramManager::schedule()
	{
	    bool status = interruptManager.getInterruptStatus();
	    interruptManager.disableInterrupt();
	    if (readyPrograms.size() == 0)
	    {
	        interruptManager.setInterruptStatus(status);
	        return;
	    }
	    if (running->status == ProgramStatus::RUNNING)
	    {
	        running->status = ProgramStatus::READY;
	        running->ticks = running->priority * 10;
	        readyPrograms.push_back(&(running->tagInGeneralList));
	    }
	    else if (running->status == ProgramStatus::DEAD)
	    {
	        releasePCB(running);
	    }
	    ListItem *max_priority_item = readyPrograms.front();
	    ListItem *iter = max_priority_item;
	    while (iter) {
	        if (ListItem2PCB(iter, tagInGeneralList)->priority > 
	            ListItem2PCB(max_priority_item, tagInGeneralList)->priority) {
	            max_priority_item = iter;
	        }
	        iter = iter->next;
	    }
	    readyPrograms.erase(max_priority_item);
	    PCB *next = ListItem2PCB(max_priority_item, tagInGeneralList);
	    PCB *cur = running;
	    next->status = ProgramStatus::RUNNING;
	    running = next;
	    asm_switch_thread(cur, next);
	    interruptManager.setInterruptStatus(status);
	}
	```
	
	
4. 最后修改用于测试的线程函数如下：
	```cpp file:setup.cpp
		void my_thread(void *arg)
	{
		    // 该线程需要完成的工作量
		    int limit = (int)arg; 
		    for (int i = 0; i <= limit; ++i)
		    {
		        // 打印线程标识、PID、当前进度和已运行的总时间
		        printf("Thread %s (PID %d): Count %d/%d, TotalTicks: %d\n", 
		               programManager.running->name, 
		               programManager.running->pid, 
		               i, 
		               limit,
		               programManager.running->ticksPassedBy);
		        // 模拟耗时
		        for (int j = 0; j < 5000000; ++j);
		    }
		    // 结束
		    printf(">>> Thread %s (PID %d) FINISHED.\n", 
		           programManager.running->name, 
		           programManager.running->pid);
		}
		void first_thread(void *arg)
	{
	    printf("First thread (Main) started...\n");
	    // 三个线程，分别在第 5, 10, 15 行打印，颜色分别为绿、红、蓝
	    programManager.executeThread(my_thread, (void *)5, "A", 3, 50, 0x02);
	    programManager.executeThread(my_thread, (void *)10, "B", 10, 30, 0x04);
	    programManager.executeThread(my_thread, (void *)15, "C", 5, 20, 0x01);
	    while(1) asm_halt();
	}
	```
	
根据设置的ABC线程的优先级不同，应该是B最先运行，最先来的A最后运行，可以看到运行结果确实如下：
![[屏幕截图 2026-05-08 164320.png|600]]
### 4.2 对比分析
- 这里依旧使用上一题的ABC线程函数进行测试，各自的优先级和执行时间都不同，并按照一个tick就是1s；
- 作为对比，使用FCFS算法进行测试；
- 只需要更改中断，取消RR算法中的时间片的逻辑，使得`schedule()` 仅在 `program_exit()` 中被调用，即线程执行完毕后才切换下一个
	```cpp file:interrupt.cpp
	extern "C" void c_time_interrupt_handler() {
	    PCB *cur = programManager.running;
	    cur->ticksPassedBy++; // 仅记录运行时间
	    // 不再检查 ticks，也不调用 schedule()
	}
	```
- 运行发现FCFS算法只能打印 `firstThread()` 的初始化语句，似乎并没有执行三个子线程ABC……
- 原因分析：在first_thread里创建完子线程最后死循环调用了 `asm_halt()` ，这是因为在RR算法下时钟中断会强制打断循环，让其他线程换上来，而这时我已经把 `c_time_interrupt_handler()` 改成了非抢占的FCFS算法，所以应该不需要这个死循环了，直接删去————结果发现还是不可以
- 进一步分析：删去死循环后，`first_thread` 退出并进入 `program_exit` 时，代码里是以pid为依据进行判断的，但是 `first_thread` pid 就恰好是0，所以也会直接导致退出。。这样的话就再修改一下 exit 的逻辑，只要就绪队列里还有线程，就继续调度：
	```cpp file:program.cpp
	  void program_exit()
	{
	    PCB *thread = programManager.running;
	    thread->status = ProgramStatus::DEAD;
	
	    if (!programManager.readyPrograms.empty()) {
	        programManager.schedule();
	    } else {
	        interruptManager.disableInterrupt();
	        printf("All threads finished. System halt.\n");
	        asm_halt();
	    }
	}
	```
- 这时，运行可以看到正确执行了ABC三个线程，并且是以创建的顺序，A先执行，C最后执行：
	![[屏幕截图 2026-05-08 164803.png|600]]
	作为对比，可以看到优先级调度中最后才执行A：
	![[屏幕截图 2026-05-08 164320 2.png|600]]
- 分析：
	- FCFS：
		在这种算法下，任务按顺序排队，长任务会阻塞后续任务
		- 线程 A (50s) ：等待 0s，周转 50s
		- 线程 B (30s) ：必须等 A 跑完，等待 50s，周转 80s
		- 线程 C (20s) ：必须等 A, B 跑完，等待 80s，周转 100s
		- 结论 ：平均周转时间为 76.7s  短任务（C）和高优先级任务（B）的等待时间非常长
		- 优点 ：
			- 实现极其简单 ：只需一个简单的先进先出队列
			- 公平性 ：按到达顺序处理，不会出现“饥饿”现象（每个任务最终都能跑完）
			- 开销小 ：减少了频繁切换线程带来的上下文切换开销
		- 缺点 ：
			- 护航效应 (Convoy Effect) ：如果一个长任务排在前面，后面所有的短任务都会被阻塞，导致系统响应速度极慢
			- 不分轻重缓急 ：无法处理紧急任务
	- 抢占式优先级调度（优先级 B > C > A，且 A 先启动）
		- 线程 B (30s) ：提交后立即抢占 A，等待 0s，周转 30s
		- 线程 C (20s) ：等 B 完后立即执行，等待 30s，周转 50s
		- 线程 A (50s) ：被多次抢占，最后执行。等待时间 = B 运行时间 + C 运行时间 = 50s，周转 100s
		- 结论 ：平均周转时间为 60s  重要任务（B）几乎零等待
		- 优点 ：
			- 实时性强 ：高优先级（紧急）任务可以立即打断低优先级任务，保证关键业务的响应
			- 灵活性高 ：可以根据任务的重要性动态调整 CPU 分配
		- 缺点 ：
			- 饥饿问题 (Starvation) ：如果源源不断有高优先级任务进入，低优先级任务（如 A）可能永远无法获得 CPU，导致“饿死”
			- 实现复杂 ：需要维护有序队列或在每次时钟中断时进行全局搜索
			- 开销较大 ：频繁的抢占会导致较多的上下文切换
## Assignment 5 线程的生命周期管理
### 5.1 实现 `thread_yield`
- 利用4.2里的优先级调度算法版本的代码，在 `ProgramManager` 类中添加一个 `yield` 函数
	
- 相比于 `schedule()` ， `yield` 不需要判断当前线程是否是DEAD态，因为yield是主动调用，不会处于DEAD；并且，也不需要更改 ticks，直接将当前线程放回就绪队列尾部即可
	
- 所以对照 `schedule()` 的代码，并把以下部分：
	```cpp file:program.cpp
		void ProgramManager::schedule(){
			...
			if (running->status == ProgramStatus::RUNNING)
		    {
		        running->status = ProgramStatus::READY;
		        running->ticks = running->priority * 10;
		        readyPrograms.push_back(&(running->tagInGeneralList));
		    }
		    else if (running->status == ProgramStatus::DEAD)
		    {
		        releasePCB(running);
		    }
		    ...
		}
	```
	
	修改为：
	```cpp file:program.cpp
	void ProgramManager::yield(){
		...
		running->status = ProgramStatus::READY;
		readyPrograms.push_back(&(running->tagInGeneralList));	
		...	
	}
	```
	
- 测试函数的编写：通过打印语句来观察何时调用yield，何时再次被调度回来；同时打印自身的 `name` `pid` `ticks` 等信息，验证是否正确恢复yield之前的状态而不是重新开始：
	```cpp file:setup.cpp
	void yield_thread(void *arg) {
	    int count = 0;
	
	    while(1) {
	        printf("Thread %s (PID %d): Count %d, TotalTicks: %d\n", 
	               programManager.running->name, 
	               programManager.running->pid, 
	               count++, 
	               programManager.running->ticksPassedBy);
	        for (int j = 0; j < 5000000; ++j);
	        printf("%s is about to yield itself.\n", programManager.running->name);
	        programManager.yield();
	        // 回来后继续执行
	        printf("%s has returned from yield!\n", programManager.running->name);
	    }
	}
	```
	
- 出现**问题**：使用A、B两个线程进行测试，结果只运行B，未运行A。不确定是不是B没有yield成功
	
- 原因分析：我所用的调度算法是优先级调度，而B的优先级被我设置比A高，所以每次B线程yield之后虽然被放回了就绪队列，作为高优先级在队列中，**依然会优先于A被调度出来**，所以导致了A未能运行；所以`yield`只是一个**自身的主动**礼让，但是优先级调度 `schedule` 依然会把高优先级的线程给揪出来
	
- 解决：可以更改调度算法，比如使用RR；但是我可以让A和B的优先级相同，这样就会优先选择处在队列前面的线程，也算是实现了切换：
	```cpp file:setup.cpp
		programManager.executeThread(yield_thread, (void *)5, "A", 10, 50, 0x02);
		programManager.executeThread(yield_thread, (void *)10, "B", 10, 50, 0x04);
	```
	
- 运行结果如下
	![[屏幕截图 2026-05-09 111956.png|600]]

### 5.2 实现 `thread_sleep` 和 `thread_wakeup`
- 依旧使用上题的算法和刚实现的 `yield`
	
- 在 `ProgramManager`类中添加 `block`和 `unblock` 函数用来实现阻塞和唤醒功能
	
- 创建 `waitList` 以存放被阻塞的线程，每次阻塞放生就往其中添加线程，唤醒时就从里面拿回线程；创建两个测试函数 `sleeper`和`waker`，`sleeper`主动调用 `block` 阻塞自己，然后 `schedule`就会切换线程为 `waker` 从而再把 `sleeper`唤醒；
	
- 由于上一题中已经出现优先级不同导致的调度问题，所以这里把两个测试函数的优先级设置相同；
	```cpp file:setup.cpp
	List waitList;
	PCB *sleeper_pcb = nullptr;
	void sleeper(void *arg){
	    printf("sleeper (PID %d) is running and about to sleep...\n", programManager.running->pid);
	    for (int i = 0; i < 5000000; ++i);
	    
	    printf("sleeper is going to sleep...\n");
	    programManager.block(&waitList);
	    
	    // 被唤醒后执行这里
	    printf("sleeper (PID %d) is AWAKENED and finished.\n", programManager.running->pid);
	    while(1) asm_halt();    
	}
	void waker(void *arg)
	{
	    printf("Waker (PID %d) is running...\n", programManager.running->pid);
	    for (int i = 0; i < 20000000; ++i);
	    
	    printf("Waker is waking up Sleeper (PID %d)...\n", sleeper_pcb->pid);
	    
	    // 从等待队列中移除并唤醒
	    waitList.erase(&(sleeper_pcb->tagInGeneralList));
	    programManager.unblock(sleeper_pcb);
	    
	    printf("Waker finished its job, then yield...\n");
	    programManager.yield();
	    while(1) asm_halt();
	}
	
	void first_thread(void *arg)
	{
	    waitList.initialize();
	    printf("First thread (Main) started...\n");
	    
	    programManager.executeThread(sleeper, nullptr, "sleeper", 1, 50, 0x02);
	    sleeper_pcb = ListItem2PCB(programManager.allPrograms.back(), tagInAllList);
	    programManager.executeThread(waker, nullptr, "waker", 1, 50, 0x04);
	
	    while(1) asm_halt();
	}
	```
	
- 然后只要定义 `block`和 `unblock`即可
	```cpp file:program.cpp
	void ProgramManager::block(List *waitList)
	{
	    bool status = interruptManager.getInterruptStatus();
	    interruptManager.disableInterrupt();
	    running->status = ProgramStatus::BLOCKED;
	    if (waitList)
	    {
	        waitList->push_back(&(running->tagInGeneralList));
	    }
	    schedule();
	    interruptManager.setInterruptStatus(status);
	}
	
	void ProgramManager::unblock(PCB *thread)
	{
	    bool status = interruptManager.getInterruptStatus();
	    interruptManager.disableInterrupt();
	    if (thread->status != ProgramStatus::BLOCKED)
	    {
	        interruptManager.setInterruptStatus(status);
	        return;
	    }
	    thread->status = ProgramStatus::READY;
	    readyPrograms.push_back(&(thread->tagInGeneralList));
	    interruptManager.setInterruptStatus(status);
	}
	```
	
- `sleeper`线程状态的变化：
	在 `block`之前的状态：![[屏幕截图 2026-05-09 155701.png|600]]
	`block`执行后， `schedule`还未调用前：![[屏幕截图 2026-05-09 155744.png|600]]
	可见状态从 RUNNING变为了BLOCKED，线程成功被阻塞
	
- 运行结果如下：
	![[屏幕截图 2026-05-09 153819.png|600]]
# 总结与心得
1. 学习了可变参数的机制，以往使用 printf并不知道其底层实现，通过本次实验才发现，其本质是利用了 C 语言函数调用时**参数连续入栈**的特性。通过指针算术运算，能从栈中取出每一个参数。实现增强型格式化输出

2. 上下文切换的 asm_switch_thread 的实现，了解了线程切换的真实过程，所谓的“线程切换”其实只需要保存好当前线程的寄存器现场，然后把 esp 强制指向另一个线程的栈顶。当 ret 指令执行时，CPU 就会到另一个线程的代码中继续运行，是对硬件寄存器的直接操控

3. 调度算法：效率与公平的权衡，在实现 FCFS 和优先级抢占调度时，体会到了算法对系统行为的影响。FCFS 实现简单，对于这个小实验，以及刚学习线程调度的我来说比较舒服；抢占式优先级调度实际上看起来聪明一点，但是后面继续利用的时候也因为优先级这个问题出现了bug，本质上都是我对调度策略逻辑不严密导致的

4. 调试：在没有图形界面的环境下，利用 GDB 跟踪 c_time_interrupt_handler 是很大的挑战，这一部分呢虽然不用编写代码，但是要一点点debug，找到想要的执行步骤进行探查，还要查看各种寄存器、栈的地址和内容，实在麻烦，这一块可能不是最难的，但是最需要仔细和耐心，强制我去了解每一字节内存的用途

5. 唤醒与阻塞：最后实现的 yield 、 sleep 和 wake 机制，标志着线程从被动调度走向了主动协作，这一块在实现前面的基础上倒是比较有趣，可以让线程函数自己把自己给阻塞或者放弃，而不用schedule的调度就实现变化，以及线程和线程之间的唤醒，让线程更加灵活