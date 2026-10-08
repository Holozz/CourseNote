# Section1 实验要求与实验概述
实验要求：阅读README.md并完成四个实验任务和思考题
实验概述：学习x86汇编、计算机的启动过程、IA-32处理器架构和字符显存原理。根据所学的知识，自己编写程序，然后让计算机在启动后加载运行，增进对计算机启动过程的理解，为后面编写操作系统加载程序奠定基础。学习如何使用gdb来调试程序的基本方法
实验环境：Ubuntu22.04，x86-64架构
# Section2 实验步骤与实验结果
>代码文件均在压缩包内
## Assignment 1 MBR
### 1.1 复现 Example 1
首先创建`mbr.asm`，写入内容然后编译，生成.bin文件后写入硬盘，随后启动QEMU
```shell
	cd lab2
	code mbr.asm
	
	//编译
	nasm -f bin mbr.asm -o mbr.bin
	
	//创建虚拟硬盘
	qemu-img create hd.img 10m 
	
	//写入
	dd if=mbr.bin of=hd.img bs=512 count=1 seek=0 conv=notrunc
	
	//启动QEMU
	qemu-system-i386 -hda hd.img -serial null -parallel stdio
```
可以看到在生成了文件，并且QEMU输出
![[屏幕截图 2026-03-21 194521.png|350]]
![[屏幕截图 2026-03-21 194514.png|500]]
### 1.2 自定义输出
目标：在$(16,10)$输出学号
先计算**显存偏移**：$\text{offset}~=~2*(80*row~+~col)~=~2*(80*16+10~=~2580)~=~0x0A14$，将其赋给基址寄存器`bx`
故**显存起始位置**就是`0xB8000+0x0A14=0xB8A14`
**颜色**：背景色选择白（`KRGB=0111=0x7`），前景色选择绿（`IRGB=0010=0x2`），因此颜色属性字节是`0x72`
**字符**：学号24319050，依次把’2‘’4‘……’9‘放入字节`0xB8A14` `0xB8A16` ...... `0xB8A22`，也就是`ax`的低字节部分。此时，把颜色字节`0x72`放入每个字符字节之后也就是`ax`的高字节部分
只给出与Example 1不同之处：
```asm
	mov bx, 0x0A14
	mov ah, 0x72 ; 绿色
	
	mov al, '2'
	mov [gs:bx], ax
	add bx, 2
	
	mov al, '4'
	mov [gs:bx], ax
	add bx, 2
	
	...
	
	mov al, '0'
	mov [gs:bx], ax
```
然后同样地，编译允许，写入硬盘，启动QEMU，可以看到结果：
![[Pasted image 20260321211805.png|500]]

### 1.3 循环输出
参照思考题15，将字符串放在`string`，用`si`控制字符读取，用`cx`控制循环，用`bx`控制显存地址
代码见于压缩包文件`Assignment1.3.asm`
然后同样地，编译允许，写入硬盘，启动QEMU，可以看到结果：
![[Pasted image 20260321213307.png|500]]
## Assignment 2 实模式中断
要访问 BIOS 功能，通常需要将AH寄存器（或 AX，或 EAX，对于某些功能）设置为特定值，然后执行 INT 指令。AH（或 AX，或 EAX）中的值与所选的特定中断号结合起来请求特定的 BIOS 功能。（其他 CPU 寄存器保存函数的任何“参数”，并且通常保存函数的返回值。）
通过指定中断号和选择功能的 AH（或 AX，或 EAX）的值来创建 BIOS 功能列表是最简单的。例如，INT 0x13，AH=0 是一个重置硬盘或软盘的 BIOS 功能。
注意：INT 和 AH 值始终以十六进制格式列出。
在某种程度上，BIOS 功能是按中断号组织的，如INT 0x10 = 视频显示功能
### 2.1 光标中断
该任务需要使用实模式中断下的视频服务，要调用该功能，应给寄存器`ah`赋值相应子功能号，在其他寄存器赋相应的参数，最后用指令`int 10h`即可
- **获取光标位置**：使用子功能`ah = 03h`，光标位置的行列信息返回在寄存器`dh`和`dl`中
	```nasm file:cursor.asm
		mov ah, 03h
		mov bh, 0
		int 10h
	```
- **调整光标位置**：使用子功能`ah = 02h`，通过`dh`和`dl`寄存器设置光标位置
	```nasm file:cursor.asm
		add dh, 1
		add al, 10
		mov ah, 02h
		mov bh, 0
		int 10h
	```
然后同样地，编译允许，写入硬盘，启动QEMU，可以看到光标的位置在第2行的第11列：
![[屏幕截图 2026-03-22 152856.png|500]]
### 2.2 使用实模式中断打印学号
使用实模式中断的在光标处打印的功能，要调用该功能，可以给`ah`赋值，在其他寄存器设定相应的参数，打印出来后还需要利用`2.1`的功能将光标移动，之后反复进行这个过程打印全部学号
- **打印字符**：使用子功能`ah = 09h`，再加上参数，就会在光标处打印字符
	```nasm file:print.asm
		mov ah, 0x09 ; 设置功能为写字符
		mov bh, 0
		mov bl, 0x27 ; 设置颜色
		mov cx, 1 ; 设置字符个数
		mov al, '2'
		int 0x10
	```
- **移动光标**：参照`2.1`节
	```nasm file:print.asm
		push ax             ; 保存
		mov ah, 0x03        ; 获取光标
		mov bh, 0
		int 0x10
		
		inc dl              ; 列+1
		mov ah, 0x02        ; 设置光标
		mov bh, 0
		int 0x10
		pop ax              ; 恢复
	```
然后同样地，编译允许，写入硬盘，启动QEMU，可以看到输出：
![[屏幕截图 2026-03-22 155721.png|500]]
### 2.3 实模式的键盘中断实现键盘输入回显
使用实模式中断的获取键盘输入功能 ，要调用该功能，给`ah`赋值，得到输入的单个字符在`al`中，然后还需要利用`ah = 0x0E`打印功能将其打印输出。考虑到*实现判断`Esc` `Backspace` `Enter`字符以及打印功能*，故用函数模块实现
-  **获取输入**：使用子功能`ah = 00h`，得到输入在寄存器`al`中
	```nasm file:keyboard.asm
		loop:
			mov ah, 0x0
			int 0x16
	```
- **打印输出**：
	```nasm file:keyboard.asm
		mov ah, 0x0E ; 设置功能为写字符
		mov bh, 0
    int 0x10
		ret
	```
- **处理Enter**：
	```nasm file:keyboard.asm
	Enter:
		mov al, 0xd
		call print
		mov al, 0xa
		call print
		jmp loop
	```
- **处理Backspace**：
  ```nasm file:keyboard.asm
  Backspace:
		mov al, 0x08
		call print
		mov al, ' '
		call print
		mov al, 0x08
		call print
		jmp loop
  ```
- **处理Esc**：直接退出，无需添加命令 `Esc: (空）`
然后同样地，编译允许，写入硬盘，启动QEMU，然后在键盘上进行输入，可以看到窗口回显了字符：
![[Pasted image 20260322173817.png|500]]
## Assignment 3 汇编
### 3.1 分支逻辑
需要注意除法时应在给寄存器`eax`赋值之后将其扩展以适配32位除法，以及将运算结果（`eax`内）存入目标位置
```nasm file:student.asm
	mov eax, [a1]

	cmp eax, 40
	jge ge40
	
	cmp eax, 18
	jge ge18
	
	jmp else
	
	ge40:
	    add eax, 3
	    cdq
	    mov ecx, 5
	    idiv ecx
	    mov [if_flag], eax
	    jmp exit
	ge18:
	    imul eax, 2
	    mov ecx, 80
	    sub ecx, eax
	    mov [if_flag], ecx
	    jmp exit
	else:
	    shl eax, 5
	    mov [if_flag], eax
	    jmp exit
	exit:
```
### 3.2 循环逻辑
需要注意`while_flags`的变量类型，是字符指针，则在汇编里`[while_flags]`表示指针值，取出放在基址寄存器或者变址寄存器中
```nasm file:student.asm
		mov eax, [a2]
		mov ebx, [while_flag]; 基址寻址，使用ebx存放地址
	loop:
		cmp eax, 25
		mov [a2], eax
		jge ex
		
		call my_random
		mov ecx, [a2]
		shl ecx, 1
		mov [ebx+ecx], al
	    
		mov eax, [a2]
		inc eax
		
		jmp loop
	ex:
```
### 3.3 函数
要注意`print_a_char`函数默认从`edx`寄存器取参数，要用`dl`存字符；并且会修改栈指针，需要手动调整回去
```nasm file:student.asm
	mov ecx, 0
	mov ebx, [your_string]
	loop:
		cmp byte [ebx+ecx], 0
		je end_loop		
		pushad
		
		mov dl, [ebx+ecx]
		add dl, 9
		push edx
		
		call print_a_char
		add esp, 4
		
		popad
		inc ecx
		jmp loop
	end_loop:
		ret
```
三个部分实现后可以看到测试通过：
![[屏幕截图 2026-03-24 003059.png|500]]
## Assignment 4 汇编小程序
完整代码文件在压缩包内
### 字符回旋程序
输出字符的原理可以直接参考Assignment 1.3，只需要考虑如何把输出的位置改变为显示屏的一圈。以及另外做出一个能够延时的函数。
- 输出位置的改变：依靠四个函数，分别检查是否打印到右下左上边界，逻辑都是类似的，判断是否到达边界，如果到了则改变`dir`变量，并且将相应的坐标进行更改，如果未到达就正常按照当前`dir`方向打印，如下
	```nasm file:round.asm
	.try_right: ;其他三个方向也都类似
    mov ax, [x]        ;取当前横坐标
    inc ax
    cmp ax, [right]    ;判断是否到达边界
    jg .right_boundary
    inc word [x]
    jmp .move_done
.right_boundary:
    mov byte [dir], 1   ;改变方向
    inc word [y]
    jmp .move_done
	```
- 延时打印：使用`int 0x15`中断，延时0.1秒
	```nasm file:round.asm
	.skip_col_reset:
    ; 延时 0.1 秒 (INT 15h AH=86h)
    mov ah, 0x86
    mov cx, 0
    mov dx, 100000          ; 100000微秒 = 0.1秒
    int 0x15
	```
- 循环变化字符和颜色：分别使用变量存储字符串和颜色的十六进制值，每次打印时使用`si`和`di`寄存器进行寻址即可，注意索引超出范围时进行取余以实现循环
	```nasm file:round.asm
	 ; 获取当前字符和颜色
    mov si, [string_index]
    mov al, [string + si]
    mov di, [color_index]
    mov ah, [colors + di]

    ; 打印
    mov [gs:bx], ax

    ; 字符串索引
    inc word [string_index]
    cmp word [string_index], string_len
    jl .skip_str_reset
    mov word [string_index], 0
.skip_str_reset:

    ; 颜色索引
    inc word [color_index]
    cmp word [color_index], color_len
    jl .skip_col_reset
    mov word [color_index], 0
.skip_col_reset:
	```
然后同样地，编译允许，写入硬盘，启动QEMU，可以看到结果：
	![[屏幕截图 2026-03-28 124455.png|500]]
### 选做1
要实现向内绕圈，可以在前面的基础上实现。延时功能和循环功能部分无需改动，只需在判断到达边界的时候，不仅要改变打印方向，还要把边界向内收缩，并且判断到达上边界时并不停止，而是继续绕圈打印即可。最后再给出判断停止，即打印满了的条件。下面只给出一个边界判断的改动，其他都类似
```nasm file:swirl.asm
.try_right:
    mov ax, [x]
    inc ax
    cmp ax, [right]
    jg .right_boundary
    inc word [x]
    jmp .move_done
.right_boundary:
    mov byte [dir], 1
    inc word [top]    ;添加这一行：使得边界收缩
    inc word [y]
    jmp .check_reset
.check_reset:         ;判断是否打印满屏幕
    mov ax, [top]
    cmp ax, [bottom]
    jg .reset
    mov ax, [left]
    cmp ax, [right]
    jg .reset
    jmp .move_done
.reset:               ;若打印完成，重置
    mov word [x], 0
    mov word [y], 0
    mov word [top], 0
    mov word [bottom], 24
    mov word [left], 0
    mov word [right], 79
    mov byte [dir], 0
    jmp .move_done

.move_done:
    jmp main_loop
```
最后可以看到运行结果：
![[屏幕截图 2026-03-28 134308.png|500]]
### 选做2（额外思考题）
对于**寄存器不足**的问题，有以下的办法：
- 使用内存中的变量，如我使用内存变量存储方向、字符串、颜色等，每次使用时就临时赋给寄存器，使用完后不占用寄存器
- 利用不同的段寄存器，访问不同的内存部分，如使用DS寄存器访问数据段的变量，用GS访问显存段来打印
- 再不够时，可以用栈来保存寄存器的状态，临时使用完成后再弹栈恢复

字符和颜色的变化依旧沿用刚才的设置，对边界的判断也是依旧，**但是**，方向的改变不依赖于达到边界（超出边界时游戏就失败了），而是根据键盘的输入。每次移动打印位置时要检查两样东西：是否到边界和键盘的输入
```nasm file:snake.asm
	main_loop:
    ; 计算下一个位置
    mov ax, [x]
    mov bx, [y]
    mov dl, [dir]

    cmp dl, 0
    je .right
    cmp dl, 1
    je .left
    cmp dl, 2
    je .up
    cmp dl, 3
    je .down

.right:
    inc ax
    jmp .check_bound
.left:
    dec ax
    jmp .check_bound
.up:
    dec bx
    jmp .check_bound
.down:
    inc bx
    jmp .check_bound

.check_bound:
    ; 检查边界 0<=x<80, 0<=y<25
    cmp ax, 0
    jl .game_over
    cmp ax, 80
    jge .game_over
    cmp bx, 0
    jl .game_over
    cmp bx, 25
    jge .game_over

    ; 有效，更新坐标
    mov [x], ax
    mov [y], bx
    
    ;后面继续计算在窗口的实际偏移位置，再依旧变址寻址获取字符和颜色，打印之后检查键盘输入
```
后面需要检查键盘输入，前面已知这需要使用`int 0x16`中断，下面只给出检查“上”键的片段，其他三个方向类似
```nasm file:snake.asm
	; 检查键盘输入（非阻塞）
    mov ah, 0x00
    int 0x16
    cmp ah, SCAN_UP
    je .set_up

.set_up:
    cmp byte [dir], DIR_DOWN
    je .no_key         ; 禁止反向
    mov byte [dir], DIR_UP
    jmp .no_key

.no_key:
    jmp main_loop
```
最后，就可以通过键盘来操作🐍的运动了！
![[屏幕截图 2026-03-28 125615.png|500]]
## 课后思考题
1. 
   为了兼顾可读性、可操控性与硬件效率。高级语言便于人类使用，但是不够底层，对计算机硬件的操控性不精细；机器语言是二进制代码，CPU可以直接执行，但是人类无法阅读编写；处于中间的汇编语言提供接口，与机器指令一一对应，经过汇编器可以翻译为机器码，而且有对硬件精细操控的能力，而且可由人类编写效率更高的高级语言编译而来。
2. 
   主要应用于80386至奔腾4系列处理器 ，IA-32处理器系列主要包括：8086、80286、80386、Pentium系列。该架构兼容早期16位指令集，支持实模式和保护模式两种工作模式。IA-32架构包含8个32位通用寄存器（EAX/EBX等）、段寄存器（CS/SS等）和标志寄存器（EFLAGS），采用小端字节序存储数据，并通过存储管理单元实现逻辑地址到物理地址的三级转换机制。
   eax部分：ax是eax的低16位，ah是ax高8位，al是ax的低8位
   esp用途：始终指向栈顶，在`push` `pop` `call` `ret`时自动修改
3. 
   CF：进位标志，无符号运算产生进位借位时的标志
   PF：奇偶校验
   AF：辅助进位标志
   SF：符号标志
   OF：溢出标志
   ZF：零标志
   DF：方向标志，字符串指令增减的方向
   IF：中断标志，为1时允许响应屏蔽中断
   TF：陷阱标志，为1时每执行一条指令触发单步中断
4. 
   **线性地址**：段机制转换后、分页机制转换前的中间地址。在分段部件中逻辑地址是段中的偏移地址，然后加上基地址就是线性地址。如果启用了分页机制，那么线性地址可以再经过变换以产生一个物理地址。 如果没有启用分页机制，那么线性地址直接就是物理地址。
   **实模式寻址**：物理地址 = 段地址<<4 + 偏移地址
   **地址空间大小**：20位地址线，一共 $2^{20}=1MB$ 的空间
5. 
	- 寻址方式：
		1. 立即数寻址
		2. 寄存器寻址
		3. 直接寻址
		4. 寄存器间接寻址
		5. 基址+偏移寻址
		6. 基址+变址寻址
	- 语法：`[base + index*scale + displacement]`
6. 
   默认段寄存器：在取指令、栈操作、数据访问时会使用CS、SS、DS寄存器。
   使用**段覆盖前缀**显式指定段寄存器
7. 
	```asm
   mov [sp], ax
   sub sp, 2
   ;错误原因：先mov，此时sp还指向旧栈顶，直接写入会覆盖掉原有数据
   
   sub sp, 2
   mov sp, ax
   ;错误原因：sp是寄存器本身，[sp]才是取出其中的内容，即指向的地址
	```
8. 区别
   `jmp`：是无条件跳转，不保存返回地址，不改变`esp`，不能返回
   `call`：调用子程序，自动将下一条指令压栈，`esp`减少，可以用`ret`返回
9. 
   ```asm
   cmp ax, 16
   jne else
   mov bx, 17
   else:
	   mov cx, bx
   end:
   ```
10. 对应汇编语句
	```asm
	; 'pushad':
	push eax
	push ecx
	push edx
	push ebx
	push esp
	push ebp
	push esi
	push edi
	; 'popad':
	pop edi
	pop esi
	pop ebp
	add esp
	pop ebx
	pop edx
	pop ecx
	pop eax    
	```
11. 
    **错误**：push 时先压 AX 后压 BX，但只pop了ax，弹出的是BX 的原始值，并且导致栈不平衡，少 pop 了一次，ret 时从错误的地址返回
	**结果**： `my_function` 返回后，AX = 原始BX的值，BX = 原始BX - 10， `add ax, 10` 执行后AX = 原始BX + 10
12. 
	**错误**：压栈是先bx后ax，出栈时先出的就是ax赋给了bx，bx赋给了ax，导致值交换。
	**结果**：bx变成ax，ax变成bx并且执行`add ax, 10`变成bx原值加10
13. 
    *正确*
	**结果**：ax与bx值交换后ax加10，之后进入死循环
14. 依旧沿用实验任务4中循环打印字符的方法来打印。需要更改的地方是：
	- 每次更新打印位置都是斜向的，也就是要同时改变x和y变量的值
	- 达到边界时，不是垂直地改变方向。而是如果边界是上下边界则将y方向上的速度取反向，如果是左右边界则将x方向上的速度取反向
	实际代码如下（不包括初始化、清屏和仿照实验任务4里的获取字符及其颜色，和延时打印的部分）
	```nasm file:bounce.asm
	main_loop:
    ; 计算下一个位置
    mov ax, [x]
    mov bx, [y]
    ; 加载速度并扩展到16位
    mov cl, [vx]
    movsx cx, cl
    mov dl, [vy]
    movsx dx, dl
    
    add ax, cx          ; x + vx
    add bx, dx          ; y + vy
    
    ; 水平边界
    cmp ax, 0
    jge .check_right
    ; x < 0，反射并修正
    neg byte [vx]
    mov ax, [x]            ; 重新加载当前 x
    mov cl, [vx]
    movsx cx, cl
    add ax, cx
    jmp .check_y
    
	.check_right:
	    cmp ax, 79
	    jle .check_y
	    ; x >= 80，反射并修正
	    neg byte [vx]
	    mov ax, [x]
	    mov cl, [vx]
	    movsx cx, cl
	    add ax, cx
	
	.check_y:
	    ; 垂直边界
	    cmp bx, 0
	    jge .check_bottom
	    ; y < 0，反射并修正
	    neg byte [vy]
	    mov bx, [y]
	    mov dl, [vy]
	    movsx dx, dl
	    add bx, dx
	    jmp .bound_ok
	
	.check_bottom:
	    cmp bx, 24
	    jle .bound_ok
	    ; y >= 25，反射并修正
	    neg byte [vy]
	    mov bx, [y]
	    mov dl, [vy]
	    movsx dx, dl
	    add bx, dx
	
	.bound_ok:
	    ; 更新坐标
	    mov [x], ax
	    mov [y], bx
	    
	    ; 计算显存偏移 (y*80 + x)*2
	    mov ax, [y]
	    mov bx, 80
	    mul bx
	    add ax, [x]
	    shl ax, 1
	    mov bx, ax

    ; 获取字符和颜色
    ; 打印字符

    ; 更新字符串索引
    ; 更新颜色索引

    ; 延时 0.05 秒
    jmp main_loop
	```
15. 
	1. 错误原因：代码缺少`org 0x7c00`指令，导致在执行`mov al, [si + string]`时是从代码编译的起始偏移开始，导致实际访问的内存错误
	2. 两种修改方法：
		-  添加`org 0x7c00`语句
		-  修改`ds`寄存器，即添加
			```asm
			mov ax, 0x7c0
			mov ds, ax
			```
			这样段基址就是0x7c0，在计算物理地址时同样可以得到正确偏移地址
	3. 寄存器`cx`：除了在`mov`使用，还用于`loop print_hello_world`，在loop指令中，ecx默认为循环计数器，故等价于
		```asm
		dec cx
		jnz print_hello_world
		```
	4. 内存访问方式
		`[si + string]`：这是**变址寻址**，默认段寄存器是`ds`，变址寄存器`si`，偏移地址为`si+string`，线性地址公式为`ds<<4 + (si + string)`
		`[gs:bx]`：这是**基址寻址**，显式指定段寄存器为`gs`，偏移地址为`bx`，线性地址为`gs<<4 + bx`
16. 即上文Assignment2部分
17. 即上文Assignment3部分

# Section3 实验总结与心得
### 总结
这次实验学习了IA-32处理器架构，其中许多寄存器的作用和用法，理解实模式和保护模式的核心差异；学习了NASM汇编基本语法并且实际上手写了汇编程序并运行；了解了实模式段地址寻址方式和x86启动过程；编写运行了MBR程序，完成了四个实验任务。中间遇到的大部分困难是不熟悉汇编语言，不能熟练使用汇编编程造成的，如实现字符串的回旋打印时根本分不清寄存器及其用法，导致有思路也无法落实到语句。
### 心得
汇编语言和高级语言有共同点，但也有很大的差异，在做完Assignment4之后发觉：用汇编写程序实在麻烦，一些赋值和条件语句既不够简洁也不够强大；但是又想到，如果使用高级语言如C++，就对这个向内绕圈打印的任务毫无头绪，汇编语言却能很精准地实现在屏幕的某一个坐标点上进行打印字符及其颜色！虽然语言更底层，但是能做到对计算机系统更深更精确的操控。