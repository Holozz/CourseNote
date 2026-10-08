# Section1 实验要求与实验概述
实验要求：阅读README.md并完成实验任务和思考题
实验概述：
	在本次实验中，学习如何使用位图和地址池来管理资源。然后，实现在物理地址空间下的内存管理。接着，学习并开启二级分页机制。在开启分页机制后，实现在虚拟地址空间下的内存管理
	本次实验最精彩的地方在于分页机制。基于分页机制，可以将连续的虚拟地址空间映射到不连续的物理地址空间。同时，对于同一个虚拟地址，在不同的页目录表和页表下，我们会得到不同的物理地址。这为实现虚拟地址空间的隔离奠定了基础。但是，本实验最令人困惑的地方也在于分页机制。开启了分页机制后，程序中使用的地址是虚拟地址。我们需要结合页目录表和页表才能确定虚拟地址对应的物理地址。而我们常常会忘记这一点，导致了我们不知道某些虚拟地址表示的具体含义
实验目标：
	1. 学习使用位图和地址池来管理内存
	2. 实现物理页内存管理
	3. 开启二级分页机制
	4. 虚拟页内存管理
	5. 页面置换算法实现
>实验环境：**Ubuntu22.04，x86-64架构**
# Section2 实验步骤与实验结果
> 实验代码均附于压缩包内
## Assignment 1 物理页内存管理与分页机制
### 1.1 复现物理页内存管理
- 思路：先初始化一个 `MemoryManager`对象，然后分别分配内核和用户空间的页；随后再分别释放一些，重新分配
- 代码
	```cpp file:setup.cpp
	void first_thread(void* arg){
		...
		MemoryManager memoryManager;
	    int kernelStart = memoryManager.allocatePhysicalPages(KERNEL, 15);
	    printf("allocate %d pages at kernelStart: %d\n", 15, kernelStart);
	  
	    int userStart = memoryManager.allocatePhysicalPages(USER, 35);
	    printf("allocate %d pages at userStart: %d\n", 35, userStart);
	  
	    memoryManager.releasePhysicalPages(KERNEL, kernelStart, 10);
	    int sec_kernelStart = memoryManager.allocatePhysicalPages(KERNEL, 10);
	    printf("allocate %d pages again at sec_kernelStart: %d\n", 10, sec_kernelStart);
	  
	    memoryManager.releasePhysicalPages(USER, userStart, 25);
	    int sec_userStart = memoryManager.allocatePhysicalPages(USER, 25);
	    printf("allocate %d pages again at sec_userStart: %d\n", 25, sec_userStart);
	    ...
	}
	```
- 运行结果：
	如图，可以看到分别输出了分配的页数以及分配的地址；并且释放之后再次分配的页也是相同的起始地址
	![[Pasted image 20260525113140.png|600]]
### 1.2 开启二级分页机制
1. 开启分页机制的三步方案
	  代码在 `A1.2/src/kernel/memory.cpp` 的 `openPageMechanism()` 函数中
	  - 第一步：初始化页目录表和页表
		~~~cpp
		  // memory.cpp:111-128
		  // 页目录表指针
		  int *directory = (int *)PAGE_DIRECTORY;       // 0x100000
		  // 线性地址0~4MB对应的页表
		  int *page = (int *)(PAGE_DIRECTORY + PAGE_SIZE); // 0x101000
		
		  // 初始化页目录表
		  memset(directory, 0, PAGE_SIZE);              // 清空4KB页目录表
		  // 初始化线性地址0~4MB对应的页表
		  memset(page, 0, PAGE_SIZE);                   // 清空4KB页表
		
		  int address = 0;
		  // 将线性地址0~1MB恒等映射到物理地址0~1MB
		  for (int i = 0; i < 256; ++i)
		  {
			  // U/S = 1, R/W = 1, P = 1
			  page[i] = address | 0x7;                  // 页表项 = 物理页地址 | 属性
			  address += PAGE_SIZE;
		  }
		~~~
		  为什么要先建立0~1MB的恒等映射？ 因为一旦 PG 位置1，CPU 立刻开始用分页机制寻址。如果不提前
		  建好内核所在区域的页表，下一条指令就无法正确取指。由于内核放在 0~1MB
		  物理内存，所以必须先把这块的映射建好。恒等映射意味着虚拟地址 =
		  物理地址，这样开启分页前后的寻址结果一致，代码可以平滑过渡。
	  - 第二步：初始化页目录项
		~~~cpp
		  // memory.cpp:133-138
		  // 0~1MB
		  directory[0] = ((int)page) | 0x07;
		  // 3GB的内核空间
		  directory[768] = directory[0];
		  // 最后一个页目录项指向页目录表
		  directory[1023] = ((int)directory) | 0x7;
		
		  第三步：写 CR3 和置 CR0.PG=1
		
		  // memory.cpp:140
		  asm_init_page_reg(directory);
		
		  对应的汇编（在 asm_utils.asm 中）：
		  asm_init_page_reg:
		      push ebp
		      mov ebp, esp
		      push eax
		
		      mov eax, [ebp + 8]      ; 页目录表物理地址
		      mov cr3, eax             ; 写入 CR3（PDBR）
		      mov eax, cr0
		      or eax, 0x80000000       ; 置 PG 位（bit 31）= 1
		      mov cr0, eax             ; 开启分页机制
		
		      pop eax
		      pop ebp
		      ret
		~~~
	  在 `setup.cpp` 中调用：
	  `memoryManager.openPageMechanism()`;
	  `memoryManager.initialize()`;  // 注意：initialize 在分页开启之后
	  顺序很重要： 先开分页 (openPageMechanism)，再做内存管理初始化 (initialize)。因为
	  initialize 中用的地址在分页开启后都是虚拟地址，需要 MMU 正确翻译
2. directory[0]、directory[768]、directory[1023] 的作用
	-  directory[0] 
		directory[0] = ((int)page) | 0x07，是第 0 个页目录项，覆盖虚拟地址 0x00000000 ~ 0x003FFFFF（0~4MB），映射 0~4MB 虚拟地址空间指向我们 0x101000 处创建的页表（包含 256 个页表项，覆盖 0~1MB）
		作用： 让内核所在的 0~1MB虚拟地址能正确映射到物理地址
	- directory[768] 
		第 768 个页目录项对应虚拟地址的 31-22 位 = 1100000000 = 768，directory[768] = directory[0]，指向同一个页表，映射 3GB~4GB 内核空间，覆盖虚拟地址 0xC0000000 ~ 0xFFFFFFFF
		作用： 这是内核空间映射到 3GB 以上的关键设计。以后访问 0xC0000000 + addr 和直接访问 addr会落到同一个物理页。这样内核既可以通过低地址也可以通过高地址访问同一块物理内存，为进程隔离的用户空间（0~3GB）和共享内核空间（3GB~4GB）奠定基础。
	- directory[1023] — 自引用（递归映射）
		  directory[1023] = ((int)directory) | 0x7;
		- 第 1023 个（最后一个）页目录项指向页目录表本身
		- 这是构造 PDE 和 PTE 虚拟地址的核心技巧
		作用： 使得我们可以通过虚拟地址来访问页目录项和页表项。具体来说：
		- PDE 虚拟地址 = 0xFFFFF000 + (virtual[31:22] × 4) → toPDE()
		- PTE 虚拟地址 = 0xFFC00000 + (virtual[31:22] << 10) + (virtual[21:12] × 4) → toPTE()
3. QEMU Monitor 验证恒等映射
	执行`make monitor`
	然后另开终端连接：telnet 127.0.0.1 45474
	在 QEMU Monitor 中输入：`info mem`
	输出显示：
	![[屏幕截图 2026-06-01 155149.png|600]]
	这表示虚拟地址 0x00000000 ~ 0x00100000（0~1MB）被映射到物理地址 0x00000000 ~
	0x00100000，即恒等映射成立
	用 `info registers` 查看 CR3 ，如图
	![[屏幕截图 2026-06-01 155204 1.png|600]]
	以及用 xp /4wx	0x100000 查看页目录表前 4 项来交叉验证，如图，直接证明了恒等映射正确建立：虚拟地址 0x0 经过 MMU 翻译后，访问的物理地址也是0x0，因此两个命令读到完全一样的内容
	![[屏幕截图 2026-06-01 155224.png|600]]
## Assignment 2 动态分区分配算法
### 2.1 实现至少两种分配算法
- 选择 First Fit和Best Fit，其中First Fit就是src/3中的默认实现
- 对于Best Fit，只是在First Fit扫描到第一个满足的连续空白块之后，继续向后探索，记录好满足条件的最小的块，当将整个池都遍历一遍之后再选择记录下来的最小块进行分配，所以大体逻辑可以复用
- 代码：
	```cpp file:bitmap.cpp
	int BitMap::bestFit(const int count){
    if (count == 0) return -1;
    int index, minEmpty, bestStart;
    index = 0;
    bestStart = -1;
    minEmpty = length+1;

    while (index < length){

	```cpp file:setup.cpp
		...
	    printf("\n========== Best Fit ==========\n");
	    {
	        MemoryManager mm;
	        int a1, a2, a3, a4, a5, a6, a7, a8;
	        a1 = mm.allocatePhysicalPagesBestFit(KERNEL, 5);
	        printf("[BF] alloc  5 pages -> 0x%x\n", a1);
	        a2 = mm.allocatePhysicalPagesBestFit(KERNEL, 10);
	        printf("[BF] alloc 10 pages -> 0x%x\n", a2);
	        a3 = mm.allocatePhysicalPagesBestFit(KERNEL, 3);
	        printf("[BF] alloc  3 pages -> 0x%x\n", a3);
	        a4 = mm.allocatePhysicalPagesBestFit(KERNEL, 20);
	        printf("[BF] alloc 20 pages -> 0x%x\n", a4);
	        mm.releasePhysicalPages(KERNEL, a2, 10);
	        printf("[BF] free  10 pages from 0x%x\n", a2);
	        mm.releasePhysicalPages(KERNEL, a3, 3);
	        printf("[BF] free   3 pages from 0x%x\n", a3);
	        a5 = mm.allocatePhysicalPagesBestFit(KERNEL, 4);
	        printf("[BF] alloc  4 pages -> 0x%x  (reuse?)\n", a5);
	        a6 = mm.allocatePhysicalPagesBestFit(KERNEL, 7);
	        printf("[BF] alloc  7 pages -> 0x%x\n", a6);
	        mm.releasePhysicalPages(KERNEL, a1, 5);
	        printf("[BF] free   5 pages from 0x%x\n", a1);
	        a7 = mm.allocatePhysicalPagesBestFit(KERNEL, 6);
	        printf("[BF] alloc  6 pages -> 0x%x  (reuse?)\n", a7);
	        a8 = mm.allocatePhysicalPagesBestFit(KERNEL, 2);
	        printf("[BF] alloc  2 pages -> 0x%x  (reuse?)\n", a8);
	        printf("[BF] done, addresses: a1=0x%x a2=0x%x a3=0x%x a4=0x%x\n", a1,a2,a3,a4);
	        printf("a5=0x%x a6=0x%x a7=0x%x a8=0x%x\n", a5,a6,a7,a8);
	    }   // mm 析构，释放所有页
	    ...
	}
	```
- 运行结果，可以看到对 `a8`的分配是不一样的
	First Fit:
	![[屏幕截图 2026-06-01 181635.png|600]]
	Best Fit:
	![[屏幕截图 2026-06-01 181720.png|600]]
### 2.2 内存利用率分析
- 在Bitmap类中添加 `getUsedCount()` `getMaxFreeBlock()` `getFreeFragmentCount()`统计函数
- 利用大模型生成合适的内存分配序列，并在每一步打印相关执行信息,测试序列的 2 个关键分歧点：
	  1. 第 8 步 (alloc 6 页)：空洞A(10页)在前，空洞B(8页)在后。FF 直接取空洞A→打破大块；BF
	  选更紧凑的空洞B→保留完整空洞A
	  2. 第 12 步 (alloc 5 页)：经过前序分歧，两者碎片布局已完全不同，分配位置进一步分化
  每步打印的指标：used=已分配/总页数  max_free=最大连续空闲  fragments=空闲碎片数
- 代码
	```cpp file:bitmap.cpp
	int BitMap::getUsedCount() const{
	    int count = 0;
	    for (int i = 0; i < length; ++i) if (get(i)) ++count;
	    return count;
	}
	
	int BitMap::getMaxFreeBlock() const	{
	    int maxBlock = 0;
	    int currentBlock = 0;
	    for (int i = 0; i < length; ++i)
	    {
	        if (!get(i)) ++currentBlock;
	        else
	        {
	            if (currentBlock > maxBlock) maxBlock = currentBlock;
	            currentBlock = 0;
	        }
	    }
	    // 检查最后一个块
	    if (currentBlock > maxBlock) maxBlock = currentBlock;
	    return maxBlock;
	}
	
	int BitMap::getFreeFragmentCount() const{
	    int fragments = 0;
	    bool inFreeBlock = false;
	
	    for (int i = 0; i < length; ++i)
	    {
	        if (!get(i))
	        {
	            if (!inFreeBlock)
	            {
	                ++fragments;
	                inFreeBlock = true;
	            }
	        }
	        else inFreeBlock = false;
	    }
	    return fragments;
	}
	```
	```cpp file:setup.cpp
	void runTest(const char *algoName, AllocFn allocFn){
	    MemoryManager mm;
	
	    // 记录每次分配的结果，便于后续释放
	    struct Rec { int addr; int count; };
	    Rec rec[20];
	    int recIdx = 0, step = 0;
	
	    //序列设计（10 次分配 + 5 次释放)：先顺序分配 5 块，然后释放第 1 块和第 3 块
	    // ──── 第1~5步：分配 10 页 ────
	    ...
	    /*  此时空闲布局（两种算法相同）：
	     *    空洞A: [0,9]   — 10 页（靠前，较大）
	     *    空洞B: [14,21] —  8 页（靠后，较小）
	     *    尾部:  [31,N]  — 巨大空闲块
	     *    已用:  [10,13](4), [22,24](3), [25,30](6)
	     */
	    // ──── 第8步：分配 6 页  ────
	    // FF: 空洞A(10)→[0,5]，剩余[6,9]
	    // BF: 选更紧凑的B→[14,19]，保留完整空洞A
	    ++step;
	    rec[recIdx].count = 6;
	    rec[recIdx].addr = (mm.*allocFn)(KERNEL, 6);
	    printf("Step%d: alloc  6 pages -> 0x%x  [divergence]\n", step, rec[recIdx].addr);
	    ++recIdx;
	    printMemoryStats(mm.kernelPhysical, algoName);
	
	    // ──── 第9步：分配 3 页 ────
	    ++step;
	    rec[recIdx].count = 3;
	    rec[recIdx].addr = (mm.*allocFn)(KERNEL, 3);
	    printf("Step%d: alloc  3 pages -> 0x%x\n", step, rec[recIdx].addr);
	    ++recIdx;
	    printMemoryStats(mm.kernelPhysical, algoName);
	
	    // ──── 第10步：释放 rec[1]（4 页块，位于 [10,13]） ────
	    ++step;
	    mm.releasePhysicalPages(KERNEL, rec[1].addr, rec[1].count);
	    printf("Step%d: free   4 pages (addr=0x%x)\n", step, rec[1].addr);
	    printMemoryStats(mm.kernelPhysical, algoName);
	
	    // ──── 第11步：释放 rec[4]（6 页块，位于 [25,30]） ────
	    ++step;
	    mm.releasePhysicalPages(KERNEL, rec[4].addr, rec[4].count);
	    printf("Step%d: free   6 pages (addr=0x%x)\n", step, rec[4].addr);
	    printMemoryStats(mm.kernelPhysical, algoName);
	
	    // ──── 第12步：分配 5 页 ★ 第二个分歧点 ────
	    // FF 和 BF 由于之前的分配位置不同，此时面临的碎片布局已完全不同
	    ++step;
	    rec[recIdx].count = 5;
	    rec[recIdx].addr = (mm.*allocFn)(KERNEL, 5);
	    printf("Step%d: alloc  5 pages -> 0x%x  [divergence]\n", step, rec[recIdx].addr);
	    ++recIdx;
	    printMemoryStats(mm.kernelPhysical, algoName);
	
	    // ──── 第13步：分配 4 页 ────
	    ++step;
	    rec[recIdx].count = 4;
	    rec[recIdx].addr = (mm.*allocFn)(KERNEL, 4);
	    printf("Step%d: alloc  4 pages -> 0x%x\n", step, rec[recIdx].addr);
	    ++recIdx;
	    printMemoryStats(mm.kernelPhysical, algoName);
	
	    // ──── 第14步：释放 rec[3]（3 页块，位于 [22,24]） ────
	    ++step;
	    mm.releasePhysicalPages(KERNEL, rec[3].addr, rec[3].count);
	    printf("Step%d: free   3 pages (addr=0x%x)\n", step, rec[3].addr);
	    printMemoryStats(mm.kernelPhysical, algoName);
	
	    // ──── 第15步：分配 5 页 — 最终对比 ────
	    ++step;
	    rec[recIdx].count = 5;
	    rec[recIdx].addr = (mm.*allocFn)(KERNEL, 5);
	    printf("Step%d: alloc  5 pages -> 0x%x\n", step, rec[recIdx].addr);
	    ++recIdx;
	    printMemoryStats(mm.kernelPhysical, algoName);
	
	    printf("[%s] done. %d allocs + 5 frees\n\n", algoName, recIdx);
	}
	```
- 问题
	由于打印输出会有非常多行，且QEMU不能上下滚动来查看历史打印，导致每次运行只能看到最后几行的输出
	考虑到解决的难度，这里打算直接在每一步之间都加上 足够长的空循环，使得我可以及时在打印输出的过程中进行截图捕捉结果
	`for(int i=0; i<30000000; i++){}`
- 运行结果
	可以看到在前8步都还一样
	![[屏幕截图 2026-06-03 174434.png|600]]
	![[屏幕截图 2026-06-03 174447.png|600]]
	来到后面则发生变化
	![[屏幕截图 2026-06-03 174954.png|600]]
	![[Pasted image 20260603175416.png|600]]
	![[屏幕截图 2026-06-03 175002.png|600]]
	可以看到BF的内存利用率还是稍微好一点，但是产生的碎片也多一点
## Assignment 3 虚拟页内存管理与地址变换
### 3.1 复现虚拟页内存管理
- 虚拟页内存分配三步过程
	1. 从虚拟地址中分配若干连续的虚拟页
		```cpp
			int virtualAddress = allocateVirtualPages(type, count);
		    if (!virtualAddress) return 0;
		```
	2. 对每一个虚拟页，从物理地址池中分配1页
		```cpp
			physicalPageAddress = allocatePhysicalPages(type, 1);
		```
	3. 为虚拟页建立页目录项和页表项，使虚拟页内的地址经过分页机制变换到物理页内
		```cpp
			flag = connectPhysicalVirtualPage(vaddress, physicalPageAddress);
		```
- 在 `first_thread` 中分配多组虚拟页（如 100 页、10 页、100 页），打印虚拟地址；释放中间的 10 页后重新分配，观察地址变化
- 代码
	```cpp file:setup.cpp
		char *p1 = (char *)memoryManager.allocatePages(AddressPoolType::KERNEL, 100);
	    char *p2 = (char *)memoryManager.allocatePages(AddressPoolType::KERNEL, 10);
	    char *p3 = (char *)memoryManager.allocatePages(AddressPoolType::KERNEL, 100);
	    printf("%x %x %x\n", p1, p2, p3);	
	    memoryManager.releasePages(AddressPoolType::KERNEL, (int)p2, 10);
	    p2 = (char *)memoryManager.allocatePages(AddressPoolType::KERNEL, 100);
	    printf("%x\n", p2);
	    p2 = (char *)memoryManager.allocatePages(AddressPoolType::KERNEL, 10);
	```
- 运行结果
	![[Pasted image 20260603211606.png|600]]
### 3.2 PDE/PTE虚拟地址构造
1. 第141个页目录项
	偏移 = 141\*4 = 564 = 0x234
	于是$pde[31:22]=pde[21:12]=1000=0x3E8$，$pde[11:0]=0x234$，拼起来就是
	$pde=0xFA3E8234$
2. 第891个页目录项指向的页表的109个页表项的虚拟地址
	那么$pde[31:22]=0x3E8,pde[21:12]=891=0x37B,pde[11:0]=109*4=0x1B4$
	拼起来的结果：0xFA37B1B4
### 3.3 虚拟地址到物理地址的验证
- 分配1页内核虚拟内存，然后调用 `vaddr2paddr` ，随后向得到的物理地址写入'Z'，对应的ASCII码为 `0x5a`
- 然后 `make monitor` `telnet 127...`进行QEMU调试，查看物理地址的内容
- 代码
	```cpp file:setup.cpp
	void first_thread(void *arg)
	{
	    stdio.moveCursor(0);
	    for (int i = 0; i < 25 * 80; ++i) stdio.print(' ');
	    stdio.moveCursor(0);
	
	    char *p1 = (char *)memoryManager.allocatePages(AddressPoolType::KERNEL, 1);
	    int vAddr = (int)p1;
	    int pAddr = memoryManager.vaddr2paddr(vAddr);
	    printf("vAddr: 0x%x pAddr: 0x%x\n", vAddr, pAddr);
	
	    *p1 = 'Z';
	    printf("Write: %c in 0x%x\n", *p1, vAddr);
	
	    asm_halt();
	}
	```
- 结果验证
	![[屏幕截图 2026-06-04 100357.png|600]]
	随后运行 `make monitor` `telnet 127...`，可以看到确实在物理地址 `0x200000`处出现了 `0x5a`
	![[屏幕截图 2026-06-04 100251.png|600]]
## Assignment 4
### 4.1 页面置换算法
- 思路
	采用请求调页+ FIFO 置换策略。核心思想：allocatePages分配虚拟页时不立即分配物理页，程序首次访问时触发缺页中断，由中断处理程序按需分配物理页；当物理页耗尽时，按 FIFO 顺序换出最早分配的页
- 置换逻辑
	先 `popFIFO`取出最早的页
	`releasePhysicalPages()`释放该物理页
	清除PTE
	`flush_tlb_single()`刷新TLB
	`allocatePhysicalPages()`重新分配
	最后将虚拟页和物理页connect，再压进FIFO队列
- 代码
	- 维护FIFO队列
		```cpp file:memory.h
		enum AddressPoolType
		{
		    USER,
		    KERNEL
		};
		
		struct FIFOPageItem
		{
		    ListItem tag;
		    int virtualAddress;
		    int physicalAddress;
		};
		#define ListItem2FIFOItem(ADDRESS) \
		      ((FIFOPageItem *)((int)(ADDRESS) - (int)&((FIFOPageItem *)0)->tag))
		      
		class MemoryManager {
	  List fifoQueue;                              // FIFO链表
	  static const int MAX_FIFO_ITEMS = 1024;       // 预分配池容量
	  FIFOPageItem fifoPool[MAX_FIFO_ITEMS];        // 静态数组池（BSS段）
	  int kernelPhysicalStartAddress;               // 内核物理页起始地址
	  int userPhysicalStartAddress;                 // 用户物理页起始地址
	
	  void pushFIFO(int vaddr, int paddr);          // 入队
	  bool popFIFO(int &vaddr, int &paddr);         // 出队
	  bool isFIFOEmpty();
	  };
		```
	- 缺页中断入口
		```asm
		asm_page_fault_handler:
		    pushad
		    call c_page_interrupt_handler
		    popad
		    ; 处理错误码
		    add esp, 4
		    iret
		```
	- 内存管理
		```cpp file:memory.cpp 
		void MemoryManager::initialize(){
		    ...
		    // 剩余的空闲的内存
		    int freeMemory = this->totalMemory - usedMemory;
		    int freePages = freeMemory / PAGE_SIZE;
		    int kernelPages = freePages / 2;
		    int userPages = freePages - kernelPages;
		    int kernelPhysicalPages = 10;
		    this->kernelPhysicalStartAddress = usedMemory;
		    this->userPhysicalStartAddress = usedMemory + kernelPhysicalPages * PAGE_SIZE;
			...
		}
		void MemoryManager::openPageMechanism(){
	    ...
	    // 初始化页目录项
	    // 0~1MB
	    directory[0] = ((int)page) | 0x07;
	    // 3GB的内核空间
	    directory[768] = directory[0];
	    for (int i = 769; i < 1023; ++i){
	        page = page + PAGE_SIZE;
	        memset(page, 0, PAGE_SIZE);
	        directory[i] = ((int)page) | 0x07;
	    }
	    // 最后一个页目录项指向页目录表
	    directory[1023] = ((int)directory) | 0x7;
	    // 初始化cr3，cr0，开启分页机制
	    asm_init_page_reg(directory);
	    ...
	.}
		void MemoryManager::pushFIFO(int virtualAddress, int physicalAddress){
	    // 从池中分配一个空闲槽位
	    FIFOPageItem *item = 0;
	    for (int i = 0; i < MAX_FIFO_ITEMS; ++i){
	        if (fifoPool[i].tag.previous == 0 && fifoPool[i].tag.next == 0){
	            item = &fifoPool[i];
	            break;
	        }
	    }
	    if (!item)...
	    item->virtualAddress = virtualAddress;
	    item->physicalAddress = physicalAddress;
	    fifoQueue.push_back(&(item->tag));
	}
		bool MemoryManager::popFIFO(int &virtualAddress, int &physicalAddress){
	    if (fifoQueue.empty()) return false;
	    ListItem *oldest = fifoQueue.front();
	    fifoQueue.pop_front();
	    FIFOPageItem *victim = ListItem2FIFOItem(oldest);
	    virtualAddress = victim->virtualAddress;
	    physicalAddress = victim->physicalAddress;
	    // 归还槽位
	    victim->tag.previous = 0;
	    victim->tag.next = 0;
	    return true;
	}
		```
	- 刷新TLB：利用invlpg 指令刷新指定虚拟地址的单条 TLB 条目，放在 C 代码中用 inline asm，编译器自动处理寄存器分配和调用约定
	- 注册缺页中断：初始化中断计数和IDT等
	- 处理缺页中断：先读CR2寄存器，得到缺页虚拟地址；然后校验地址的合法性，是否已经被分配；尝试分配物理页，如果失败则触发前述的置换逻辑
		```cpp file:interrupt.cpp
		static inline void flush_tlb_single(int addr){
		    asm volatile("invlpg (%0)" ::"r" (addr) : "memory");
		}
	
		void InterruptManager::initialize(){
		    // 初始化中断计数变量
		    times = 0;
		    // 初始化IDT
		    IDT = (uint32 *)IDT_START_ADDRESS;
		    asm_lidt(IDT_START_ADDRESS, 256 * 8 - 1);
		
		    for (uint i = 0; i < 256; ++i) if (i != 14) setInterruptDescriptor(i, (uint32)asm_unhandled_interrupt, 0);
		    setInterruptDescriptor(14, (uint32)asm_page_fault_handler, 0);
		    // 初始化8259A芯片
		    initialize8259A();
		}
		
		extern "C" void c_page_interrupt_handler(){
	    uint32 cr2 = read_cr2();
	    printf("page fault on virtual address :0x%x\n", cr2);
	    bool is_valid = false;
	    // 计算地址所在的页面
	    uint32 page_addr = cr2 & 0xFFFFF000;
	    // 检查是否是内核地址空间（3GB以上）
	    if (cr2 >= 0xC0000000) {
	        // 内核地址空间，检查该地址是否在内核虚拟地址池的已分配范围内
	        int page_index = (page_addr - memoryManager.kernelVirtual.startAddress) / 4096;
	        if (page_index >= 0 && page_index < memoryManager.kernelVirtual.resources.length) {
	            // 检查该页是否已分配（即位图中该位是否为1）
	            is_valid = memoryManager.kernelVirtual.resources.get(page_index);
	        }
	    } else {
	        is_valid = false;
	    }
	
	    if (!is_valid) {
	        printf("Illegal memory access at 0x%x, process terminated\n", cr2);
	        asm_halt();
	        return;
	    }
	
	    // 合法地址，为其分配物理页
	    int physicalPageAddress;
	    bool flag = true;
	    physicalPageAddress = memoryManager.allocatePhysicalPages(AddressPoolType::KERNEL, 1);
	    if (physicalPageAddress == 0) flag = false;
	
	    if (!flag) {
	        if (memoryManager.isFIFOEmpty()) asm_halt();
	        int oldVaddr, oldPaddr;
	        memoryManager.popFIFO(oldVaddr, oldPaddr);
	        memoryManager.releasePhysicalPages(AddressPoolType::KERNEL, oldPaddr, 1);
	        int *pte = (int *)memoryManager.toPTE(oldVaddr);
	        *pte = 0;
	        physicalPageAddress = memoryManager.allocatePhysicalPages(AddressPoolType::KERNEL, 1);
	        flush_tlb_single(oldVaddr);
	    }
	    memoryManager.pushFIFO(cr2, physicalPageAddress);
	    flag = memoryManager.connectPhysicalVirtualPage(cr2, physicalPageAddress);
	    if (!flag) {
	        printf("connect with physical page failed\n");
	        asm_halt();
	    }
	
	    printf("Connect virtual Page:%d with physical Page:%d\n",
	           memoryManager.virtualPageID(cr2),
	           memoryManager.physicalPageID(physicalPageAddress));
	}
		
		```
	- 测试程序：分配 15 个内核虚拟页（只有 10 个物理页），依次访问触发缺页。前 10次直接分配物理页，第 11 次开始触发 FIFO 置换。
		```cpp file:setup.cpp
		void first_thread(void *arg)
		{
		    //第1个线程不可以返回
		    stdio.moveCursor(0);
		    for (int i = 0; i < 25 * 80; ++i) stdio.print(' ');
		    stdio.moveCursor(0);
		    char *p = (char *)memoryManager.allocatePages(AddressPoolType::KERNEL, 15);
		    for (int i = 0; i < 15; i++) p[i * PAGE_SIZE] = 'a';
		    *p = 'a';
		    asm_halt();
		}
		```
- 运行结果，可以看到第11次时正确从Page0开始重新分配
	![[屏幕截图 2026-06-04 210337.png|600]]
### 4.2 内存统计面板
- 这里直接利用上一个任务里的代码，也就是页面置换实现的代码，那么预计内核物理页会显示十个全部被占用，而虚拟页会有15个
- 添加`printMemoryStatus()`函数
	```cpp memory.cpp
	void MemoryManager::printMemoryStatus(){
	    // 统计各地址池已分配页数
	    int kernelPhysUsed = 0, userPhysUsed = 0, kernelVirtUsed = 0;
	    for (int i = 0; i < kernelPhysical.resources.length; ++i)
	        if (kernelPhysical.resources.get(i)) ++kernelPhysUsed;
	    for (int i = 0; i < userPhysical.resources.length; ++i)
	        if (userPhysical.resources.get(i)) ++userPhysUsed;
	    for (int i = 0; i < kernelVirtual.resources.length; ++i)
	        if (kernelVirtual.resources.get(i)) ++kernelVirtUsed;
	
	    int totalPhysAlloc = (kernelPhysUsed + userPhysUsed) * PAGE_SIZE;
	    int totalPhysFree = totalMemory - totalPhysAlloc;
	
	    printf("========== Memory Status ==========\n");
	    printf("Physical Memory:\n");
	    printf("  Total:    %d bytes (%d MB)\n", totalMemory, totalMemory / 1024 / 1024);
	    printf("  Allocated: %d bytes (%d KB)\n", totalPhysAlloc, totalPhysAlloc / 1024);
	    printf("  Free:     %d bytes (%d KB)\n", totalPhysFree, totalPhysFree / 1024);
	    printf("\n");
	    printf("Pool Usage:\n");
	    printf("  Kernel Physical: %d/%d (%.1f%%)\n",
	           kernelPhysUsed, kernelPhysical.resources.length,
	           100.0 * kernelPhysUsed / kernelPhysical.resources.length);
	    printf("  User Physical:   %d/%d (%.1f%%)\n",
	           userPhysUsed, userPhysical.resources.length,
	           100.0 * userPhysUsed / userPhysical.resources.length);
	    printf("  Kernel Virtual:  %d/%d (%.1f%%)\n",
	           kernelVirtUsed, kernelVirtual.resources.length,
	           100.0 * kernelVirtUsed / kernelVirtual.resources.length);
	    printf("\n");
	
	    // 统计页目录项(PDE)和页表项(PTE)
	    int pdeCount = 0, pteCount = 0;
	    for (int i = 0; i < 1024; ++i)
	    {
	        int *pde = (int *)toPDE(i << 22);
	        if (*pde & 0x1)
	        {
	            ++pdeCount;
	            // 遍历该页表中的1024个PTE
	            for (int j = 0; j < 1024; ++j)
	            {
	                int *pte = (int *)toPTE((i << 22) | (j << 12));
	                if (*pte & 0x1)
	                    ++pteCount;
	            }
	        }
	    }
	    printf("Page Tables:\n");
	    printf("  PDEs (present): %d / 1024\n", pdeCount);
	    printf("  PTEs (present): %d\n", pteCount);
	    printf("====================================\n");
	}
	```
- 运行结果
	![[屏幕截图 2026-06-04 225150.png|600]]
## 思考题
1.  二级页表的好处：
	- 按需分配：一级页表需要连续 4MB（1024×1024×4 字节）存放所有PTE，而二级页表按需分配——只为实际使用的 4MB 区域分配页表（每张页表4KB），未使用的 PDE 条目直接为空（不占页表空间）
	- 离散存储：页表可以分散在不同物理页中，不需要连续 4MB 物理内存
	- 二级页表空间开销更大的情况：
		  当进程使用的虚拟地址极度稀疏但覆盖了大量 4MB 区域，但是又刚好不能填满4MB的对齐区间时
2. 0x15 中断 0xe801 → 0xe820
	这里我也不是很清楚，从大模型得到的回答，我理解下来是这样：
	需要修改的代码：
	`getTotalMemory()` 中读取内存的代码当前是int 0x15, ax=0xe801	int memory = \*((int*)MEMORY_SIZE_ADDRESS);  
	需要改为 0xe820 需要修改 bootloader（bootloader.asm）中的内存探测代码，不再调用 int 0x15, ax=0xe801，改为循环调用 int 0x15, ax=0xe820 遍历 ARDS（Address Range Descriptor Structure）表，将结果写到固定地址（如 0x7c00）。然后memory.cpp 中解析 ARDS 条目（每个 20 字节），累加 type=1（可用内存）的条目
	- 优势：
		- 0xe801 只返回连续的低端和高端内存总量，无法处理内存空洞
		- 0xe820 返回完整的内存映射表，精确描述每一段内存的起止地址和类型，支持非连续内存布局
3. 多进程虚拟地址空间隔离
	- 隔离机制：每个进程拥有独立的页目录表（独立的CR3），PCB保存其物理地址，切换进程的时候就更改CR3
	- 页目录和页表的作用：
		- 页目录表：第一级翻译，决定一个 4MB 区间有没有页表、页表在哪
		- 页表：第二级翻译，将 4KB 虚拟页映射到具体物理页框
4. 通过递归映射构造 PDE 和 PTE 的虚拟地址
	- 动机：为了访问虚拟地址空间下的页目录项和页表项，要构造页目录项和页表项的虚拟地址 
	- 效果：当把最后一个页目录项指向页目录表（第一个项）的时候，CPU 把页目录表当作一张"页表"来翻译 PDE[1023] 覆盖的 4MB区域（0xFFC00000~0xFFFFFFFF）
	- 这样的话想要访问第 i 个 PDE的时候，由于虚拟地址的高31到12位是页目录项和页表项的定位，而PDE的页号应该是指向页目录表的那个页，也就是最后一个，另一方面，页目录号应该是指向刚才那个页表的，也就是最后一个页目录项
# 总结与心得
1. 这次实验进一步学习和实现了物理内存、虚拟内存、页面置换的内容
2. 从最底层的汇编utils，到C++层面的位图、地址池、内存管理类，一层层的封装和抽象更有利于认识和实现内存的管
3. 分页机制的巧妙实现，以及其中用到的递归引用，十分复杂，而且需要时刻认清操作的是虚拟地址还是物理地址
4. 页面置换算法的实现：这一块对于我是整个实验最难的部分，尽管我会用一个FIFO队列去实现最核心的先进先出逻辑，但是各处细节，包括将List类扩展为FIFO队列、回到Lab4学习注册并处理缺页中断、缺页发生后的逻辑、刷新TLB等等，这都是上课没有学到或者掌握的，需要重新去了解或者借助大模型来解决，修改了很多次、很长时间