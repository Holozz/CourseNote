# Section1 实验要求与实验概述
实验要求：阅读README.md并完成实验任务和思考题
实验概述：
	在本章中，我们首先会简单讨论保护模式下的特权级的相关内容。特权级保护是保护模式的特点之一，通过特权级保护，我们区分了内核态和用户态，从而限制用户态的代码对特权指令的使用或对资源的访问等。但是，用户态的代码有时不得不使用一些特权指令，如输入输出等。因此，我们介绍了系统调用的概念和如何通过中断来实现系统调用。通过系统调用，我们可以实现从用户态到内核态转移，然后在内核态下执行特权指令等，执行完成后返回到用户态。在实现了系统调用后，我们通过三步来创建了进程。这里，我们需要重点理解我们是如何通过分页机制来实现进程之间的虚拟地址空间的隔离。最后，我们介绍了 fork/wait/exit 的一种简洁的实现思路
实验目标：
	1. 学习系统调用和特权级的转换
	2. 创建第一个进程
	3. 实现Wait和Exit功能
	4. 处理僵尸进程和孤儿进程
	5. 额外实现系统调用
>实验环境：**Ubuntu22.04，x86-64架构**
# Section2 实验步骤与实验结果
> 实验代码均附于压缩包内
## Assignment 1 系统调用与特权级转换
### 1.1 复现系统调用并分析特权级机制
1. 编写自定义系统调用
	返回两个整数的最大值&计算阶乘
	```cpp file:setup.cpp
	int syscall_max(int first, int second, int third, int forth, int fifth){
		 int a = first, b = second;
		 return (a>b)? a : b;
		 }

	int syscall_factorial(int first, int second, int third, int forth, int fifth){
		 int n = first;
		 int res = 1;
		 for(int i=1; i<=n; i++) res *= i;
		 return res;
		 }

	```
2. 在进程中调用
	```cpp
	 systemService.setSystemCall(1, (int)syscall_max);
	 systemService.setSystemCall(2, (int)syscall_factorial);
	
	 ret = asm_system_call(1, 100, 200);
	 printf("max(100, 200) is %d\n", ret);
	 ret = asm_system_call(2, 5);
	 printf("Factorial(5) is %d\n", ret);	
	```
	结果如下
	 ![[屏幕截图 2026-06-19 183229.png|300]]
3. 分析系统调用的完整执行流程
	1. 用户态：
		关键在于 `asm_system_call` 函数把参数存入寄存器 eax/ebx/ecx/edx/esi/edi 然后执行 `int 0x80`
		```asm
			asm_system_call:
		    push ebp
		    mov ebp, esp
		
		    push ebx
		    push ecx
		    push edx
		    push esi
		    push edi
		    push ds
		    push es
		    push fs
		    push gs
		
		    mov eax, [ebp + 2 * 4]
		    mov ebx, [ebp + 3 * 4]
		    mov ecx, [ebp + 4 * 4]
		    mov edx, [ebp + 5 * 4]
		    mov esi, [ebp + 6 * 4]
		    mov edi, [ebp + 7 * 4]
		
		    int 0x80
		
		    pop gs
		    pop fs
		    pop es
		    pop ds
		    pop edi
		    pop esi
		    pop edx
		    pop ecx
		    pop ebx
		    pop ebp
		
		    ret
		```
	2. 特权级转移
		这是CPU硬件行为，从TSS读取 `ss0/esp0`切换到内核栈，自动压栈
	3. 内核态
		关键在 `asm_system_call_handler`，保存寄存器，然后设置内核数据段，随后系统调用到对应函数
		```nasm
		asm_system_call_handler:
	    push ds
	    push es
	    push fs
	    push gs
	    pushad
	    push eax
	    ; 栈段会从tss中自动加载
	    mov eax, DATA_SELECTOR
	    mov ds, eax
	    mov es, eax
	    mov eax, VIDEO_SELECTOR
	    mov gs, eax
	    pop eax
	    ; 参数压栈
	    push edi
	    push esi
	    push edx
	    push ecx
	    push ebx
	    sti    
	    call dword[system_call_table + eax * 4]
	    cli
	    add esp, 5 * 4
	    mov [ASM_TEMP], eax
	    popad
	    pop gs
	    pop fs
	    pop es
	    pop ds
	    mov eax, [ASM_TEMP]
	    iret
		```
	4. 返回
		关键在于上一步中代码里最后一句 `ret`，从内核栈弹出寄存器的内容，恢复到用户态继续执行 `asm_system_call`中 `int 0x80`的下一行
### 1.2 GDB 分析栈与段寄存器变化
1. 首先启动GDB调试，设置断点：
	![[屏幕截图 2026-06-20 143146 1.png|500]]
2. 随后运行至断点处，先查看一次寄存器的内容：
	可以看到**esp、eip、ss、cs等寄存器的内容**
	![[屏幕截图 2026-06-20 143645.png|600]]
	![[屏幕截图 2026-06-20 143707.png|600]]
	验证CPL的值，以及查看栈上的参数：
	可以看到CPL=3，处于用户态
	![[屏幕截图 2026-06-20 143907.png|500]]
3. 执行 `int 0x80` 查看特权级转换
	单步执行后查看寄存器内容，可以看到**进入handler后 `cs=0x20 ss=0x10`以及esp的内容** 说明CPL=0，处于内核态
	![[屏幕截图 2026-06-20 144123.png|600]]
	![[屏幕截图 2026-06-20 144137.png|600]]
	验证**SS和ESP的来源：**
	**可以看到 `ss0=0x10, esp0=-1073584480`，是来自TSS**
	![[Pasted image 20260620145331.png|600]]
	查看内核栈上CPU压入的5个值：
	![[Pasted image 20260620145717.png|600]]
	**这就是 `iret` 返回时需要恢复的信息，会恢复为一开始的时候的值，保存在内核栈里，是在 `int 0x80` 执行时CPU压入的值**
	至于**esp0和ss0的作用：ss0保存内核栈的段选择子，从而在特权级切换的时候加载ss使栈段指向内核数据段；esp0保存内核栈的栈顶地址，CPU从esp0加载esp使当前指针指向当前进行的内核栈**
## Assignment 2 进程创建与 Fork
### 2.1 进程的创建过程分析
1. 截图展示多个进程通过系统调用输出各自信息的运行结果。
	- 创建三个用户进程：
		```cpp
		void first_process()
		{
		    asm_system_call(0, 132, 324, 12, 124);
		    asm_halt();
		}
		void second_process()
		{
		    asm_system_call(0, 1, 2, 3, 4);
		    asm_halt();
		}
		void third_process()
		{
		    asm_system_call(000, 6, 6, 5, 7);
		    asm_halt();
		}
		void first_thread(void *arg)
		{
		    printf("start process\n");
		    programManager.executeProcess((const char *)first_process, 1);
		    programManager.executeProcess((const char *)second_process, 2);
		    programManager.executeProcess((const char *)third_process, 3);
		    asm_halt();
		}
		```
	- 运行结果 
		![[Pasted image 20260622105832.png|600]]
2. 进程创建的三步方案
	1. 在线程PCB基础上扩展进程PCB
		需要利用创建的线程的PCB，扩展出页目录表和虚拟地址池，如下代码：
		```cpp
		int ProgramManager::executeProcess(const char *filename, int priority){
		    ...
		    // 找到刚刚创建的PCB
		    PCB *process = ListItem2PCB(allPrograms.back(), tagInAllList);
		    // 创建进程的页目录表
		    process->pageDirectoryAddress = createProcessPageDirectory();
		    if (!process->pageDirectoryAddress){
		        process->status = ProgramStatus::DEAD;
		        interruptManager.setInterruptStatus(status);
		        return -1;
		    }
		    
		    // 创建进程的虚拟地址池
		    bool res = createUserVirtualPool(process);
		    if (!res){
		        process->status = ProgramStatus::DEAD;
		        interruptManager.setInterruptStatus(status);
		        return -1;
		    }
		    interruptManager.setInterruptStatus(status);
		    return pid;
		}
		```
	2. ProcessStartStack 如何让 iret 跳到用户态
		`load_process()`函数在进程PCB顶部构造了一个假的中断栈帧，初始化之后就调用`asm_start_process((int)interruptStack)`进入用户态
		```cpp
		void load_process(const char *filename){
		    interruptManager.disableInterrupt();
		    PCB *process = programManager.running;
		    ProcessStartStack *interruptStack =
		        (ProcessStartStack *)((int)process + PAGE_SIZE - sizeof(ProcessStartStack));
		    ...//初始化interruptStack
		    if (interruptStack->esp == 0)
		    {
		        printf("can not build process!\n");
		        process->status = ProgramStatus::DEAD;
		        asm_halt();
		    }
		    interruptStack->esp += PAGE_SIZE;
		    interruptStack->ss = programManager.USER_STACK_SELECTOR;
		
		    asm_start_process((int)interruptStack);
		}
			
		```
	3. schedule 中的 CR3 切换
		通过 `activateProgramPage()`函数，先更新内核栈指针，然后调用 `asm_update_cr3`进行切换地址空间
		```cpp
		void ProgramManager::activateProgramPage(PCB *program){
		    int paddr = PAGE_DIRECTORY;
		    if (program->pageDirectoryAddress){
		        tss.esp0 = (int)program + PAGE_SIZE;
		        paddr = memoryManager.vaddr2paddr(program->pageDirectoryAddress);
		    }
		    asm_update_cr3(paddr);
		}
		```
3. 线程的PCB 中 `pageDirectoryAddress` 为 0，而进程的不为 0
	- 线程：共享内核的地址空间，不需要独立页表。pageDirectoryAddress = 0  作为标记，activateProgramPage 看到 0 就直接用内核页目录
	- 进程：需要独立的用户空间（0~3GB），每个进程有自己的页目录表，存储进程独有的用户页映射。内核部分（3~4GB）从内核页目录复制，保证内核空间共享
### 2.2 Fork的实现与分析
#### 2.2.1
编写进程，调用 `fork()`：
```cpp
void first_process()
{
    int pid = fork();
    if (pid == -1) printf("can not fork\n");
    else{
        if (pid) printf("I am father, fork reutrn: %d\n", pid);
        else{
            printf("I am child, fork return: %d, my pid: %d\n", pid, programManager.running->pid);
        }
    }
    asm_halt();
}
```
结果如下，先后打印了父进程和子进程的信息
![[Pasted image 20260620160740.png|600]]
#### 2.2.2 **结合代码逻辑**分析 fork 如何解决以下四个关键问题：
- 如何为子进程创建独立的虚拟地址空间（页目录表复制）
	在 `copyProcess()`中对父进程页目录的前 768 项（用户空间 0~3GB）逐项检查，如果父进程有页表（PDE 存在位=1）：
    1. 从用户物理池分配一页给子进程作页表 → childPageDir[i] = paddr
    2. 切到子进程地址空间（cr3=子进程页目录）
	3. memset 子进程页表为空
    4. 切回父进程地址空间（cr3=父进程页目录）
	```cpp
	// 复制页目录表
	for (int i = 0; i < 768; ++i){
		// 无对应页表
		if (!(parentPageDir[i] & 0x1)) continue;
		// 从用户物理地址池中分配一页，作为子进程的页目录项指向的页表
		int paddr = memoryManager.allocatePhysicalPages(AddressPoolType::USER, 1);
		if (!paddr){
			child->status = ProgramStatus::DEAD;
			return false;
		}
		// 页目录项
		int pde = parentPageDir[i];
		// 构造页表的起始虚拟地址
		int *pageTableVaddr = (int *)(0xffc00000 + (i << 12));
		asm_update_cr3(childPageDirPaddr); // 进入子进程虚拟地址空间
		childPageDir[i] = (pde & 0x00000fff) | paddr;
		memset(pageTableVaddr, 0, PAGE_SIZE);
		asm_update_cr3(parentPageDirPaddr); // 回到父进程虚拟地址空间
	}
	```
	这使得子进程有独立页目录和空页表，但物理页还没复制
- 如何复制父进程的用户空间数据到子进程
	紧接着上一个循环，第二个循环对每个 PDE → 对每个 PTE进行检查，如果父进程有物理页（PTE 存在位=1）：
	1. 从用户物理池分配一页给子进程 → pageTableVaddr[j] = paddr
	2. 父进程物理页内容 → memcpy 到中转页（buffer）
    3. 切到子进程地址空间
    4. 中转页内容 → memcpy 到子进程物理页（逐页复制）
    5. 切回父进程地址空间
    如下所示：
	```cpp
	// 复制页表和物理页
	for (int i = 0; i < 768; ++i){
		// 无对应页表
		if (!(parentPageDir[i] & 0x1))continue;
		// 计算页表的虚拟地址
		int *pageTableVaddr = (int *)(0xffc00000 + (i << 12));
		// 复制物理页
		for (int j = 0; j < 1024; ++j){
			// 无对应物理页
			if (!(pageTableVaddr[j] & 0x1))continue;
			// 从用户物理地址池中分配一页，作为子进程的页表项指向的物理页
			int paddr = memoryManager.allocatePhysicalPages(AddressPoolType::USER, 1);
			if (!paddr){
				child->status = ProgramStatus::DEAD;
				return false;
			}
			// 构造物理页的起始虚拟地址
			void *pageVaddr = (void *)((i << 22) + (j << 12));
			// 页表项
			int pte = pageTableVaddr[j];
			// 复制出父进程物理页的内容到中转页
			memcpy(pageVaddr, buffer, PAGE_SIZE);
			asm_update_cr3(childPageDirPaddr); // 进入子进程虚拟地址空间
			pageTableVaddr[j] = (pte & 0x00000fff) | paddr;
			// 从中转页中复制到子进程的物理页
			memcpy(buffer, pageVaddr, PAGE_SIZE);
			asm_update_cr3(parentPageDirPaddr); // 回到父进程虚拟地址空间
		}
	}
	```
	关键：使用了一个内核中转页（buffer）跨地址空间传输数据。因为父子进程的用户空间虚拟地址相同但映射到不同物理页，不能直接 memcpy。
- 如何设置子进程的内核栈，使其第一次被调度时能正确运行
	关键在于 `copyProcess()`函数，先复制父进程的 `ProcessStartStack`，再令子进程的eax=0，设置子进程的栈帧，当 子进程第一次被调度时：`asm_switch_thread` → `ret` 到 `asm_start_process(childpss)` →`popad/pop gs.../iret` → 进入用户态，且 `eax=0`
	```cpp
	bool ProgramManager::copyProcess(PCB *parent, PCB *child)
	{
	    // 复制进程0级栈
	    ProcessStartStack *childpss =
	        (ProcessStartStack *)((int)child + PAGE_SIZE - sizeof(ProcessStartStack));
	    ProcessStartStack *parentpss =
	        (ProcessStartStack *)((int)parent + PAGE_SIZE - sizeof(ProcessStartStack));
	    memcpy(parentpss, childpss, sizeof(ProcessStartStack));
	    // 设置子进程的返回值为0
	    childpss->eax = 0;
	    // 准备执行asm_switch_thread的栈的内容
	    child->stack = (int *)childpss - 7;
	    child->stack[0] = 0;
	    child->stack[1] = 0;
	    child->stack[2] = 0;
	    child->stack[3] = 0;
	    child->stack[4] = (int)asm_start_process;
	    child->stack[5] = 0;             // asm_start_process 返回地址
	    child->stack[6] = (int)childpss; // asm_start_process 参数
		...
	```
- 如何保证父进程的 fork 返回子进程 pid，子进程的 fork 返回 0
	- 父进程：`ProgramManager::fork()` 直接 `return pid`（子进程的 pid，>0），这个返回值经过`asm_system_call_handler` 的 `mov [ASM_TEMP], eax → popad → mov eax, [ASM_TEMP] → iret`  回到用户态，eax = 子进程pid
	- 子进程：还没被调度！它的内核栈已经被设置好：`ProcessStartStack.eax = 0 +asm_start_process` 入口。当调度器选中它时，`asm_start_process` 从 `ProcessStartStack`恢复 `eax = 0 → iret`到用户态 → `fork()` 返回 0
#### 2.2.3 使用 GDB或 QEMU Monitor跟踪子进程**第一次被调度执行**的过程
1. 在 `asm_switch_thread`打断点，运行到断点前，查看ESP
	![[屏幕截图 2026-06-20 165038.png|600]]
	如图，可以 看到esp，当前尚未切换的栈
	![[屏幕截图 2026-06-20 165305.png|600]]
2. 单步运行至 ` mov esp, [eax]`，**切换到子进程**
	**查看当前ESP以及子进程栈上的内容**：
	![[屏幕截图 2026-06-20 165451.png|600]]
3. 在 `asm_start_process`设置断点，运行到断点前
	查看eax的内容，可以看到eax=0，说明子进程的 `fork()`返回0
	![[屏幕截图 2026-06-20 165711.png|600]]
4. 然后 继续单步执行指导 `iret`，就返回到了用户态
5. 在这个过程中，**子进程的跳转地址**总结为：`schedule() → asm_switch_thread(cur, child) → ret → asm_start_process → iret → 用户态first_process`
6. 子进程 vs 父进程返回路径对比
	  - 父进程（fork 返回 >0）
	    `fork() → int 0x80 → asm_system_call_handler → syscall_fork()→ ProgramManager::fork() → executeProcess 返回 pid → return pid→ 沿调用链原路返回 → iret → 用户态，eax = 子进程pid`
	  - 子进程（fork 返回 0）
	    `[尚未存在] → 被调度选中 → asm_switch_thread → ret → asm_start_process→ iret → 用户态 first_process，eax = 0`
	  - 可以看到父进程回到用户态是通过`asm_system_call` 的 `iret` ，而子进程是`asm_start_process 的 iret`；以及父进程的eax是`ProgramManager::fork()`的返回值（子进程 pid；而子进程是 `ProcessStartStack.eax`
## Assignment 3 Wait/Exit 与进程生命周期
### 3.1Exit的实现与分析
#### 3.1.1 复现
创建一个父进程并进行 `fork()`，子进程运行 `exit(42)`
```cpp
void first_process()
{
    int pid = fork();
    if (pid == -1){
        printf("can not fork\n");
        asm_halt();
    }
    else{
        if (pid){
            printf("I am father\n");
            asm_halt();
        }
        else{
            printf("I am child, exit(42)\n");
            exit(42);
        }
    }
}
```
结果如下
![[Pasted image 20260620205055.png|600]]
#### 3.1.2 分析 `exit`的完整执行过程
- 进程资源的释放
	首先判断 `pageDirectoryAddress`是否是0（区分是否是进程）
	然后对进程的前768个页目录项，分别遍历其1024个页表项，以释放物理页、释放页表物理页、释放页目录表、释放虚拟地址池
	```cpp
	void ProgramManager::exit(int ret){
	    ...
	    // 第二步，如果PCB标识的是进程，则释放进程所占用的物理页、页表、页目录表和虚拟地址池bitmap的空间。
	    if (program->pageDirectoryAddress){
	        pageDir = (int *)program->pageDirectoryAddress;
	        for (int i = 0; i < 768; ++i){
	            if (!(pageDir[i] & 0x1)) continue;
	
	            page = (int *)(0xffc00000 + (i << 12));
	            for (int j = 0; j < 1024; ++j){
	                if(!(page[j] & 0x1)) continue;
	                paddr = memoryManager.vaddr2paddr((i << 22) + (j << 12));
	                memoryManager.releasePhysicalPages(AddressPoolType::USER, paddr, 1);
	            }
	            paddr = memoryManager.vaddr2paddr((int)page);
	            memoryManager.releasePhysicalPages(AddressPoolType::USER, paddr, 1);
	        }
	        memoryManager.releasePages(AddressPoolType::KERNEL, (int)pageDir, 1);
	        int bitmapBytes = ceil(program->userVirtual.resources.length, 8);
	        int bitmapPages = ceil(bitmapBytes, PAGE_SIZE);
	        memoryManager.releasePages(AddressPoolType::KERNEL, (int)program->userVirtual.resources.bitmap, bitmapPages);
	
	    }
		...
	}
	```
- 进程状态的变换
	将状态改为DEAD，并将 `retValue`存入PCB中
	```cpp
		void ProgramManager::exit(int ret){
		    // 关中断
		    interruptManager.disableInterrupt();
		    // 第一步，标记PCB状态为`DEAD`并放入返回值。
		    PCB *program = this->running;
		    program->retValue = ret;
		    program->status = ProgramStatus::DEAD;
		    int *pageDir, *page;
		    int paddr;
		    ...
		}
	```
- `exit` 最后调用 `schedule`，在 `schedule()` 中，状态为 DEAD的进程不进入就绪队列，因此不会再被调度执行
````cpp
void ProgramManager::exit(int ret){
	...
	// 第三步，立即执行线程/进程调度。
	schedule();
}
````
### 3.2 Wait的实现与父子进程同步
#### 3.2.1 复现
```cpp
void first_process()
{
    int pid = fork();
    int retval;
    if (pid){
        pid = fork();
        if (pid){
            while ((pid = wait(&retval)) != -1) printf("wait for a child process, pid: %d, return value: %d\n", pid, retval);

            printf("all child process exit, programs: %d\n", programManager.allPrograms.size());
            
            asm_halt();
        }
        else{
            uint32 tmp = 0xffffff;
            while (tmp)
                --tmp;
            printf("child 2 exit, pid: %d\n", programManager.running->pid);
            exit(123934);
        }
    }
    else{
        uint32 tmp = 0xffffff;
        while (tmp)
            --tmp;
        printf("child 1 exit, pid: %d\n", programManager.running->pid);
        exit(-123);
    }
}
```
结果如下
![[Pasted image 20260620220639.png|600]]
输出正确
#### 3.2.2 结合代码分析 `wait` 的执行逻辑
- 父进程如何遍历子进程列表寻找 DEAD 状态的子进程
	`ProgramManager::wait()` 遍历 `allPrograms`，通过`child->parentPid == this->running->pid` 找到子进程，检查 `status == DEAD`
	```cpp
	int ProgramManager::wait(int *retval)
	{
	    PCB *child;
	    ListItem *item;
	    bool interrupt, flag;
	
	    while (true){
	        interrupt = interruptManager.getInterruptStatus();
	        interruptManager.disableInterrupt();
	        item = this->allPrograms.head.next;
	        // 查找子进程
	        flag = true;
	        while (item){
	            child = ListItem2PCB(item, tagInAllList);
	            if (child->parentPid == this->running->pid){
	                flag = false;
	                if (child->status == ProgramStatus::DEAD) ...
	}
	```
- 找到后如何回收子进程的 PCB 资源
	找到 DEAD 子进程后，取出 `retValue` → 调用 `releasePCB()` 从`allPrograms` 中移除并标记 PCB 槽位为可用
	```cpp
	int ProgramManager::wait(int *retval)
{
    ...
                if (child->status == ProgramStatus::DEAD) break;
            }
            item = item->next;
        }

        if (item){ // 找到一个可返回的子进程
            if (retval) *retval = child->retValue;

            int pid = child->pid;
            releasePCB(child);
            interruptManager.setInterruptStatus(interrupt);
            return pid;
        }
    ...
	```
- 未找到时如何进入阻塞（调用 `schedule`）等待子进程退出
	存在子进程但不是 DEAD → 调用 `schedule()` 让出 CPU。因为 `wait`外层是 `while(true)`，下次被调度回来继续查找。如果完全没有子进程 → 返回 -1
	```cpp
	int ProgramManager::wait(int *retval){
    ...
        else {
            if (flag) { // 子进程已经返回
                interruptManager.setInterruptStatus(interrupt);
                return -1;
            }
            else {// 存在子进程，但子进程的状态不是DEAD
                interruptManager.setInterruptStatus(interrupt);
                schedule();
            }
        }
    ...
}
	```
### 3.3 僵尸进程与孤儿进程处理（方案A）
- 首先添加 `ProgramManager`类的成员变量 `initPid`来记录init进程的pid
	```cpp
	void ProgramManager::initialize(){
    ...
    initPid = -1;
}

	```
- 然后在 `exit()`中添加逻辑：在资源释放之后，调度之前，处理子进程
	```cpp
	void ProgramManager::exit(int ret){
	    ...
	    // 处理子进程：回收僵尸子进程，将存活子进程过户给 init
	      if (program->pageDirectoryAddress && initPid != -1){
	          ListItem *item = this->allPrograms.head.next;
	          while (item){
	              PCB *child = ListItem2PCB(item, tagInAllList);
	              item = item->next;  // 先保存下一个，防止 releasePCB 导致指针失效
	              if (child->parentPid == program->pid){
	                  if (child->status == ProgramStatus::DEAD) releasePCB(child);
	                  else child->parentPid = initPid;
	              }
	          }
	      }
	    schedule();
	}
	```
- 在 `setup`中编写init进程，然后将其创建在 `first_thread`里，将新进程的 `parentPid`改为initPid；编写测试用例
	```cpp
	void init_process(){
	      while (true){
	          int retval;
	          int pid = wait(&retval);
	          if (pid != -1)printf("init reaped child pid: %d, retval: %d\n", pid, retval);
	          else for(volatile int i = 0; i < 100000; ++i);
	      }
	}
	
	void child_process(){
		printf("child: pid=%d, parentPid=%d\n", programManager.running->pid, programManager.running->parentPid);
		exit(200);
	}
	
	void parent_no_wait(){
		printf("parent: pid=%d, forking child\n", programManager.running->pid);
		int pid = fork();
		if (pid == 0) child_process();
		else{
		  // 父进程：不调用 wait，直接 exit
		  // 子进程成为孤儿，由 init 负责回收
		  printf("parent exit without wait\n");
		  exit(300);
		}
	}
	void first_thread(void *arg){
	    printf("start process\n");
	    // 第一步：创建 init 进程（pid=1），负责回收所有孤儿
	    int initPid = programManager.executeProcess((const char *)init_process, 1);
	    programManager.initPid = initPid;
	    printf("init process created, pid: %d\n", initPid);
	      // 第二步：创建测试进程（父进程不 wait 直接退出）
	    programManager.executeProcess((const char *)parent_no_wait, 1);
	    PCB *newProcess = ListItem2PCB(programManager.allPrograms.back(), tagInAllList);
	    newProcess->parentPid = initPid;
	    asm_halt();
	}	
	```
- 运行结果如下：可以看到两个子进程都被顺利回收
	![[Pasted image 20260620231620.png|600]]
## Assignment 4.1 新增系统调用
- 先在 `thread.h`中增加一个成员变量 `sleepTicks`用于记录sleep的剩余tick数，0表示未在sleep
	```cpp file:thread.h
	int sleepTicks;
	```
- 在 `syscall`新增系统调用： `getpid` `sleep`
	```cpp file:syscall.cpp
	int getpid() {
	      return asm_system_call(6);
	}
	int syscall_getpid() {
	      return programManager.running->pid;
	}
	
	void sleep(int ticks) {
	      asm_system_call(7, ticks);
	}
	void syscall_sleep(int ticks) {
	      if (ticks <= 0) return;
	      programManager.running->sleepTicks = ticks;
	      programManager.running->status = ProgramStatus::BLOCKED;
	      programManager.schedule();
	}
	```
- 在 `interrupt.cpp`中增加唤醒逻辑
	```cpp
	extern "C" void c_time_interrupt_handler()
	{
	    ...
		ListItem *item = programManager.allPrograms.head.next;
		while (item)
		{
		  PCB *p = ListItem2PCB(item, tagInAllList);
		  item = item->next;
		  if (p->status == ProgramStatus::BLOCKED && p->sleepTicks > 0)
		  {
			  --p->sleepTicks;
			  if (p->sleepTicks == 0)
			  {
				  programManager.MESA_WakeUp(p);
			  }
		  }
		}
	}
	```
- 最后在 `setup`中注册系统调用并编写测试函数
	```cpp
	...
	systemService.setSystemCall(6, (int)syscall_getpid);
	systemService.setSystemCall(7, (int)syscall_sleep);
	...
	
	void child_a(){
		int pid = getpid();
		printf("child A: my pid is %d\n", pid);
		sleep(8);
		printf("child A: sleeping 8 ticks...\n");
		printf("child A: sleeping 10 more ticks...\n");
		sleep(10);
		printf("child A: all done, pid %d exiting with 100\n", getpid());
		exit(100);
	}
	
	void child_b(){
		int pid = getpid();
		printf("child B: my pid is %d\n", pid);
		printf("child B: sleeping 20 ticks...\n");
		sleep(20);
		printf("child B: woke up after 20 ticks, pid %d exiting with 200\n", getpid());
		exit(200);
	}
	void first_process(){
		int pid = getpid();
		printf("parent: my pid is %d\n", pid);
		// fork 第一个子进程
		pid = fork();
		if (pid == 0) child_a();
		// fork 第二个子进程
		pid = fork();
		if (pid == 0) child_b();
		// 父进程循环 wait 回收所有子进程
		// 父进程自己也 sleep，让子进程有机会运行
	      printf("parent: sleeping 5 ticks while children work\n");
	      sleep(5);
	      printf("parent: woke up, now waiting for children\n");
		int retval;
		while ((pid = wait(&retval)) != -1)
		{
		  printf("parent: child %d exited with %d\n", pid, retval);
		}
	
		printf("parent: all children reaped, pid %d exiting\n", getpid());
		exit(0);
	}
	```
- 运行结果如下
	可以看到A和B按照时间顺序来sleep并且A先醒来；
	A的两次sleep均生效；
	pid返回正常，说明getpid正确
	![[屏幕截图 2026-06-21 003637.png|600]]
# 总结与心得
- 这次在线程之后实现了进程，了解了系统调用和特权级转换的内容，包括其中栈与寄存器的值的保存和传递；实现了进程的创建三步方案，了解了与线程的区别在于有自己的页表等；另外还实现了Wait和Exit，了解了进程的生命周期，以及孤儿进程和僵尸进程的问题；最后，额外实现了新的系统调用，额外增加了进程的唤醒逻辑
- 这次依旧是进程与系统调用的内容，其中的QEMU与GDB调试依旧比较麻烦，不好操作，但也依旧加深了对这个过程中各个重要寄存器和栈的理解；另外，自己动手实现代码，才知道在底层上的进程是如何实现的，有很多细节值得研究
