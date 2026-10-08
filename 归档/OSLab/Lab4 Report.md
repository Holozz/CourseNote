# Section1 实验要求与实验概述
实验要求：阅读README.md并完成四个实验任务和思考题
实验概述：
	在本章中，首先了解一份C代码是如何通过预编译、编译、汇编和链接生成最终的可执行文件。接着，为了更加有条理地管理项目，学习一种C/C++项目管理方案。随后开始学习C和汇编混合编程方法，即如何在C代码中调用汇编代码编写的函数和如何在汇编代码中调用使用C编写的函数。学习保护模式下的中断处理机制和可编程中断部件8259A芯片。最后通过编写实时钟中断处理函数来将本章的所有内容串联起来。通过本章的学习，将掌握使用C语言来编写内核的方法，理解保护模式的中断处理机制和处理时钟中断，为后面的二级分页机制和多线程/进程打下基础。
实验目标：
	理解C/C++ 编译流程（预处理→编译→汇编→链接）；掌握C/汇编混合编程（C 调用汇编，汇编调用C）；学习使用Makefile 管理大型C/C++ 项目；理解保护模式下的中断处理机制（IDT、中断描述符）；学习可编程中断控制器8259A 的编程方法；实现时钟中断处理函数（8253/8254 定时器）
>实验环境：**Ubuntu22.04，x86-64架构**
# Section2 实验步骤与实验结果
> 实验代码均附于压缩包内
## Assignment 1 混合编程的基本思路
### 1.1 复现与分析
可以看到Makefile里已经写好了编译命令，直接执行 `make main.out` 即可，结果如下
![[Pasted image 20260420113830.png|400]]
C代码调用汇编函数的语法和汇编代码调用C函数的语法
### 1.2 带参数的混合编程
编写C语言函数，直接返回 `a*b` 即可
```c file:c_func.c
int c_multiply(int a, int b) {
	return a*b;
}
```
编写测试函数，注意要声明 `extern "C" int call_mul(int a, int b);` `extern "C" int asm_add(int a, int b);`
```cpp file:main.cpp
extern "C" void function_from_asm();
extern "C" int call_mul(int a, int b);
extern "C" int asm_add(int a, int b);

int main() {
    std::cout << "Call function from assembly." << std::endl;
    function_from_asm();
    int a = 3, b = 5;
    int mul = call_mul(a, b);
    int sum = asm_add(a, b);
    std::cout<<"a*b = "<<mul<<std::endl;
    std::cout<<"a+b = "<<sum<<std::endl;
    
    std::cout << "Done." << std::endl;
    return 0;
}

```
编写汇编部分，注意被C调用的汇编函数的开头和结尾分别要加上：
```
push ebp
mov ebp, esp
...
pop ebp
ret
```
以及调用C函数的汇编部分要将参数先入栈：
```nasm
push [ebp+4*n+4] ; 参数n
...
push [ebp+8] ; 参数1

```
编写的调用C相乘的函数，以及相加的函数如下：
```nasm file:asm_utils.asm
asm_add:
	push ebp
	mov ebp, esp
	
	mov eax, [ebp+8]
	add eax, [ebp+12]
	
	pop ebp
	ret

call_mul:
    push ebp
    mov ebp, esp
    
    push dword [ebp+12]
    push dword [ebp+8]
    call c_multiply
    
    add esp, 8
    pop ebp
    ret

```
运行可以看到结果：
![[Pasted image 20260420180716.png|400]]

## Assignment 2 使用C/C++编写内核
### 2.1 复现与修改
运用Makefile直接进行编译，结果在2.2中一并展示
### 2.2 实现 `print_string` 函数
实现思路：
- 显存地址 ：VGA 文本模式的显存起始地址为 0xb8000 
- 存储格式 ：每个字符占用 2 字节
	- 低字节 ：ASCII 码
	- 高字节 ：颜色属性（背景色 + 前景色）
- 使用 `static int cursor_pos` 变量记录当前光标位置
- 换行处理 ：遇到 `\n` 时，通过公式 `(cursor_pos / 80 + 1) * 80` 计算下一行第一列
所以函数实现如下：
```cpp file:setup.cpp
extern "C" void print_string(const char* str, uint8 color)
{
    static int cursor_pos = 80;
    uint8* vga = (uint8 *)0xB8000;
    for(int i=0; str[i] != '\0'; i++){
        if(str[i] == '\n'){
            cursor_pos = (cursor_pos/80 + 1) * 80;
            continue;
        }
        vga[cursor_pos*2] = (uint8)str[i];
        vga[cursor_pos*2+1] = color;
        cursor_pos++;
    }
    cursor_pos = (cursor_pos/80 + 1) * 80;
}

```
运行结果如下：
![[屏幕截图 2026-04-25 155232.png|600]]
## Assignment 3 中断的处理
### 3.1 实现页面错误中断处理
修改说明：
1. 汇编层面处理( asm_utils.asm ) ：
	- 该函数负责实现输出段错误信息的语句，可以仿照 `asm_unhandled_interrupt` 实现
2. C++中断注册 ( interrupt.cpp ) ：
	- 在 `InterruptManager::initialize` 函数中，将 IDT 的第 14 号条目指向 `asm_page_fault_handler` 
3. 接口声明 ( asm_utils.h ) ：
	- 在头文件中声明了新的汇编处理函数，以便 C++ 代码可以引用其地址
故核心代码如下：
```cpp file:intertupt.cpp
void InterruptManager::initialize()
{
    // 初始化IDT
    IDT = (uint32 *)IDT_START_ADDRESS;
    asm_lidt(IDT_START_ADDRESS, 256 * 8 - 1);
    for (uint i = 0; i < 256; ++i)
    {
        setInterruptDescriptor(i, (uint32)asm_unhandled_interrupt, 0);
    }
    setInterruptDescriptor(14, (uint32)asm_PageFault_Handler, 0);
}

```

```nasm file:asm_utils.asm
;void asm_PageFault_Handler()
asm_PageFault_Handler:
    cli
    mov esi, ASM_PageFault_INTERRUPT_INFO
    xor ebx, ebx
    mov ah, 0x0c
.output_information:
    cmp byte[esi], 0
    je .end
    mov al, byte[esi]
    mov word[gs:bx], ax
    inc esi
    add ebx, 2
    jmp .output_information
.end:
    add esp, 4
    jmp $
```

运行结果如下，可见显示出段错误的语句：
![[Pasted image 20260425173458.png|600]]
### 3.2 读取CR2 寄存器获取缺页地址
修改内容如下：
1. 汇编实现改为用cpp实现 ( `asm_utils.asm` ) ：
	- 新增 `asm_read_cr2` ：实现了读取 CR2 寄存器并返回到 eax 的功能
	- 重构 `asm_PageFault_Handler` ：
		- 移除冗余 ，删除了原有的纯汇编打印逻辑，而是用 C++ 处理函数 `C_PageFault_Handler` ，然后清理错误码  `add esp, 4` ，使得代码更简洁易读
2. 头文件更新 ( `asm_utils.h` ) ：
	- 声明了 `asm_read_cr2` 和统一后的 `asm_PageFault_Handler` 
3. C++ 逻辑完善 ( interrupt.cpp ) ：
	- 注册中断 ：在 initialize 中显式将 14 号中断绑定到 `asm_PageFault_Handler`
	- 实现 `C_PageFault_Handler` ：
		 - 调用 `asm_read_cr2()` 获取触发错误的虚拟地址
		 - 通过 stdio.print 友好地输出错误信息
核心代码如下：
```cpp file:interrupt.cpp
extern "C" void C_PageFault_Handler()
{
    uint32 vaddr = asm_read_cr2();
    char addrStr[11];
    itos(addrStr, vaddr, 16);
    stdio.print("Page fault happened at virtual address: 0x");
    stdio.print(addrStr);
    stdio.print(", halt...\n");
    asm_halt();
}
```
```nasm file:asm_utils.asm
;void asm_PageFault_Handler()
asm_PageFault_Handler:
	pushad
	call C_PageFault_Handler
	popad
	add esp, 4
	iret

; uint32 asm_read_cr2()
asm_read_cr2:
	mov eax, cr2
	ret

```
可以看到运行结果如下：
![[屏幕截图 2026-04-25 175436.png|600]]
输出了发生错误的地址
### 3.3 思考题
1. 引发段错误的方式：
	1. 访问未建立页表映射的地址
	2. 访问NULL地址
	3. 向只读页面写入
2. 内核使用的是平坦模式，当定义一个数组时，它所在的4KB页面被内核映射到物理内存中，而数组越界，可能只是小范围的超出，仍然是在同一个页面内，CPU检查时只会发现页面仍然可写，所以不会触发中断
3. 不报错：数组越界行为，以及空指针解引用也可能会不报错
   报错：访问未分配内存
## Assignment 4 时钟中断
### 4.1 字符回旋

在加载内核和初始化中断向量符后，在 `InterruptManager` 中初始化8259A芯片，首先向特定端口发送四个初始化命令字，其中ICW2指定了主片和从片的中断向量号，接着发送特定的中断屏蔽信号，注意主片的IRQ2引脚连接了从片，要保持一直开启的状态

```cpp file:interrupt.cpp
void InterruptManager::initialize8259A()
{
    // ICW 1
    asm_out_port(0x20, 0x11);
    asm_out_port(0xa0, 0x11);
    // ICW 2
    IRQ0_8259A_MASTER = 0x20;
    IRQ0_8259A_SLAVE = 0x28;
    asm_out_port(0x21, IRQ0_8259A_MASTER);
    asm_out_port(0xa1, IRQ0_8259A_SLAVE);
    // ICW 3
    asm_out_port(0x21, 4);
    asm_out_port(0xa1, 2);
    // ICW 4
    asm_out_port(0x21, 1);
    asm_out_port(0xa1, 1);
    // OCW 1 屏蔽主片所有中断，但主片的IRQ2需要开启
    asm_out_port(0x21, 0xfb);
    // OCW 1 屏蔽从片所有中断
    asm_out_port(0xa1, 0xff);
}
```

然后是开中断和关中断，在 `enableTimeInterrupter` 和 `disableTimeInterrupter` 实现；

注册中断描述符在 `setTimeInterrupt` 函数；

在asm层次需要实现中断处理函数，逻辑是保存现场，调用cpp实现的处理函数，然后返回现场，在 `asm_time_interrupt_handler` 函数实现；

而在C++中实现字符回旋的逻辑如下：

```cpp file:interrupt.cpp
void c_time_interrupt_handler(){
	// 使用 static 变量保存状态，函数退出后值依然保留
    static int x = 1;      // 当前行
    static int y = 0;      // 当前列
    static int state = 0;  // 移动状态
    static int str_index = 0;
    static int color_index = 0;
    char string[] = "6657Machine";
    uint8 color[10] = {0x0E, 0x0F, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08, 0x07, 0x06};
    // 根据当前状态更新坐标
    if (state == 0) { // 向右移动
        y++;
        if (y == 79) state = 1; // 到达最右侧
    }
    else if (state == 1) { // 向下移动
        x++;
        if (x == 24) state = 2; // 到达最下方
    }
    else if (state == 2) { // 向左移动
        y--;
        if (y == 0) state = 3;  // 到达最左侧
    }
    else if (state == 3) { // 向上移动
        x--;
        if (x == 1) state = 0;  // 回到起点
    }
    stdio.print(x, y, string[(str_index++) % 11], color[(color_index++) % 10]);
}
```
运行结果如下：
![[屏幕截图 2026-04-26 164737.png|600]]
### 4.2 自定义时钟频率
1. 核心原理与公式
	8254 定时器有一个内部的输入时钟频率，固定为 1193180 Hz 。它通过一个 16 位的“分频值（Divisor）”来产生输出信号中断频率f 与分频值 N 的关系为：
	f = N 1193180 ​ ⇒ N = f 1193180 ​
2. 实现
	向8254的控制端口 `0x43` 发送控制字，然后向通道0的数据端口 `0x40` 写入分频值，如下：
	```cpp
		void InterruptManager::setTimeInterruptFrequency(uint32 frequency)
	{
	    uint32 divisor = 1193180 / frequency;
	    asm_out_port(0x43, 0x36);
	    asm_out_port(0x40, (uint8)(divisor & 0xff));        // 低8位
	    asm_out_port(0x40, (uint8)((divisor >> 8) & 0xff)); // 高8位
	}
	```
	随后直接在 `setup.cpp` 中调用这个函数即可，然后利用Eaxmple4里的时钟中断输出作为计时器，可以看到打印的速度明显发生变化
	![[屏幕截图 2026-04-26 204223.png|600]]
## Assignment 5 键盘中断
1. 先实现汇编层次的键盘中断处理函数，依旧是调用cpp层次的函数来实现：
	```nasm file:asm_utils.asm
	asm_keyboard_interrupt_handler:
	    pushad
	    ; 发送 EOI (End of Interrupt) 信号给 8259A 中断控制器
	    mov al, 0x20
	    out 0x20, al
	    out 0xa0, al
	
	    call c_keyboard_interrupt_handler
	
	    popad
	    iret
	```
2. 实现步骤1中的cpp层次处理函数，这里需要对照扫描表将扫描码转换为对应的ASCII字符，并将其在屏幕上打印，考虑到还要兼顾光标的移动，所以直接利用STDIO类里的 `print()` 函数：
	```cpp file:interrupt.cpp
		extern "C" void c_keyboard_interrupt_handler()
	{
	    uint8 scan_code;
	    asm_in_port(0x60, &scan_code);
	    if (scan_code < 0x80)
	    {
	        // 扫描码映射表
	        static const char key_map[] = {
	            0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
	            '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
	            0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`',
	            0, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0,
	            '*', 0, ' '
	        };
	        if (scan_code < sizeof(key_map) && key_map[scan_code] != 0)
	        {
	            char c = key_map[scan_code];
	            stdio.print(c);
	        }
	    }
	}
	```
3. 实现之后，只需要在8259A主片取消IRQ1的屏蔽即可，`InterruptManager` 中已有IRQ0的地址，这里直接+1就得到IRQ1的地址：
	```cpp interrupt.cpp
	void InterruptManager::enableKeyboardInterrupt()
{
    uint8 value;
    asm_in_port(IRQ0_8259A_MASTER+1, &value);
    value = value & 0xfd; // 将 IRQ1 置 0 开启
    asm_out_port(IRQ0_8259A_MASTER+1, value);
}
	void InterruptManager::setKeyboardInterrupt(void *handler)
{
    setInterruptDescriptor(0x21, (uint32)handler, 0);
}
	```
4. 在 `setup.cpp` 中调用步骤3的两个函数，注册并启用键盘中断即可
运行后可以看到屏幕上打印了我们用键盘打的语句：
![[屏幕截图 2026-04-27 101203.png|600]]
## 课后思考题
# 总结与心得
- 学习了C/C++与汇编的混合编程方法，使用高级语言来实现确实更加易读，逻辑清晰
- 学习了项目文件组织方式
	- build目录可以存放Makefile文件以及编译生成的文件
	- include目录存放头文件
	- run目录存放调试文件和磁盘
	- src目录存放
		- boot目录，存放mbr，加载磁盘，进入内核
		- kernel目录，存放内核的建立，中断的实现
		- utils目录存放汇编文件
- 学习了Makefile的使用，方便了编译运行
- 学习使用gdb进行调试
