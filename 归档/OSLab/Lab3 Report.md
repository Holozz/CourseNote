# Section1 实验要求与实验概述
实验要求：阅读README.md并完成四个实验任务和思考题
实验概述：学习如何从16位的实模式跳转到32位的保护模式，然后在平坦模式下运行32位程序。同时学习如何使用I/O端口和硬件交互，为后面保护模式编程打下基础。
实验目标：学习如何从硬盘读取更多程序（突破 MBR 512B 限制），理解 LBA（逻辑块寻址）方式读写硬盘的原理和实现，掌握 I/O 端口读写指令（in/out）与硬件交互，理解全局描述符表（GDT）的结构和作用，实现从实模式切换到保护模式的完整流程，在保护模式下运行32位程序（平坦内存模型
>实验环境：**Ubuntu22.04，x86-64架构**
# Section2 实验步骤与实验结果
> 实验代码均附于压缩包内
## Assignment 1 磁盘加载
### 1.1 复现Example 1
利用已有的 `makefile` 快捷编译运行：
```shell
make build
make run
```
可以看到运行窗口：
![[Pasted image 20260411195106.png|500]]
### 1.2 CHS方式读取硬盘
CHS模式是直接使用磁头、柱面和扇区来读取硬盘的，用C、H、S分别代表磁头柱面扇区index，用nH、nS表示磁头的数量和每个磁道里扇区的数量，注意LBA是从0开始的，则LBA逻辑扇区号可以表示为
$$
\begin{aligned}
& LBA~=~NH*NS*C~+~NS*H~+~S~-~1\\
& 反解出\\
& C=\left( \frac{LBA}{NS*NH} \right)\\
& H=\left( \frac{LBA}{NS}|| NH\right)\\
& S=(LBA||NS)+1
\end{aligned}
$$
具体在代码中要使用BIOS的 `int13h` 中断：
```nasm file:mbr_chs.asm
	mov ax, 0x0205
	mov cx, 0x0002
	mov dx, 0x0080
	mov bx, 0x7e00
	mov ax, 0
	mov es, ax
	mov ax, 0x0205
	
	int 0x13
```
可以看到同样的窗口运行：
![[屏幕截图 2026-04-11 200518.png|500]]
### 1.3 加载校验
新建 `bootloader_magic.asm` ，在最后先计算魔数在内存中的偏移地址：$5*512B~-~4~=~2556B$，然后放置一个4字节的魔数
```nasm file:bootloader_magic.asm
	...
	times 2556 - ($ - $$) db 0
	dd 0xCAFEBABE
```
新建 `mbr_magic.asm` ，在加载完扇区后计算魔数在内存中的地址：`0x7e00+2556=0x87FC` ，然后使用 `cmp dword [0x87fc], 0xCAFEBABE` 进行对比，输出校验结果
```nasm file:mbr_magic.asm
	;校验
	mov eax, [0x87FC]        ; 魔数地址 = 0x7e00 + 2560 - 4
	cmp eax, 0xCAFEBABE
	je .boot_ok
	;校验失败
	mov esi, msg_err
	mov bl, 0x04             ; 红色
	call print_string
	jmp 0x0000:0x7e00
	  
	.boot_ok:
	; 校验成功
	mov esi, msg_ok
	mov bl, 0x02             ; 绿色
	call print_string
	jmp 0x0000:0x7e00
	
	; 打印字符串函数 (esi=str, bl=color)
	print_string:
	    mov ax, 0xb800
	    mov gs, ax
	    xor edi, edi
	    .loop:
	        mov al, [esi]
	        test al, al
	        jz .done
	        mov ah, bl
	        mov [gs:edi], ax
	        inc esi
	        add edi, 2
	        jmp .loop
	    .done:
	        ret
	  
	msg_ok  db "BOOT OK", 0
	msg_err db "BOOT ERR", 0

```
随后分别尝试正确的地址和错误的地址进行校验：
![[屏幕截图 2026-04-11 213320.png|200]]![[屏幕截图 2026-04-11 214222 1.png|400]]
更改验证地址，故意试错：
![[屏幕截图 2026-04-11 213342.png|200]]![[屏幕截图 2026-04-11 215446.png|400]]

## Assignment 2 保护模式分析
### 2.1 调试保护模式
使用 `gdb` 工具设置断点，进行调试
1. 加载 `GDT` 
   在保护模式开始处设置断点，然后查看 `pgdt` 的值
   ![[屏幕截图 2026-04-12 173310.png|500]]
   如图，可以看到 `pgdt` 的前两字节为GDT的界限 `limit = 0x27 = 39`
   另外还可以查看五个段描述符的内容，与设想一致
   ![[屏幕截图 2026-04-12 174023.png|500]]
2. 打开A20地址线
   ![[屏幕截图 2026-04-12 175414.png|500]]
   如图，设置断点在 `0x7e89` `0x7e8d` 然后执行，命中之后查看 `eax` 寄存器状态，可以看到低位上的值是 `0x02` 证明A20地址线打开
3. 设置CR0的PE位
   先设置断点 `0x7e97` 命中，随后查看CR0的状态，尚为 `0x10`
   ![[屏幕截图 2026-04-12 180549.png|500]]
   随后继续执行，再次查看，发现CR0变为 `0x11` ，即PE = 1，保护模式开启
4. 远跳转进入保护模式
	利用已经生成的符号表，直接设置断点
	```gdb
		b protect_mode_begin
		c
		monitor info registers
	```
	可以看到CS选择子变为 `0x20` 说明成功跳转
	![[屏幕截图 2026-04-12 181553.png|500]]
### 2.2 手工解析段描述符
在保护模式开始处设置断点然后查看段描述符的内容
![[屏幕截图 2026-04-12 200642.png|500]]
- 可以看到数据段的内容为 `0x 00cf 9300 0000 ffff` 
  **段线性基地址**：63~56 `00` 39~32 `00` 31~16 `00` 说明Base = 0
  **段界限**：51~48 `f` 15~0 `ffff` 说明Limit = 0xffff
  **粒度**：55 从 `0xcf` 的最高位提取，为 `1` G = 1
  **D/B位**：54，为1，说明操作数大小32位
  **P**：47，为1，说明段存在
  **DPL**：45~46 从 `0x92` 提取，为00b，说明最高优先级
  **S位**：44，为1，说明非系统段
  **TYPE**：40~43 `0x92` 提取，为0x2，说明数据段可读写
- **存储方式**：如图，可以看到数据段的低位字节放在内存的低地址，所以是小端存储
### 2.3 自定义段描述符
向原来的 `bootloader.asm` 进行添加，根据给定的基地址、段界限等确定段描述符内容
```nasm file:bootloader.asm
	; 新增或者改动
	mov dword [GDT_START_ADDRESS+0x28], 0x70001FFF
	mov dword [GDT_START_ADDRESS+0x2c], 0x00409200
	mov word [pgdt], 47 
	mov byte [fs:0], 'H'
	mov byte [fs:1], 'I'
	mov byte [fs:2], ','
	mov byte [fs:3], '2'
	mov byte [fs:4], '4'
	mov byte [fs:5], '3'
	mov byte [fs:6], '1'
	mov byte [fs:7], '9'
	mov byte [fs:8], '0'
	mov byte [fs:9], '5'
	mov byte [fs:10], '0'
	
	mov ax, DATA_SELECTOR   ; 平坦模式数据段
	mov ds, ax
	mov esi, 0x7000         ; DS:0x7000 = 物理地址 0x7000
	mov ebx, 80 * 2 * 4     ; 换行显示
	mov ecx, 11             ; 长度
	mov ah, 0x0c            ; 换个颜色（红色），方便区分
	.new_output_loop:
		mov al, [ds:esi]
		mov word[gs:ebx], ax
		add ebx, 2
		inc esi
		loop .new_output_loop
	
```
随后同样进行调试输出，可以看到输出了学号
![[Pasted image 20260412211950.png|500]]
## Assignment 3 32位保护模式编程
### 3.1 移植Lab2程序到保护模式
由于进入保护模式后，BIOS的实模式中断向量表（IVT）已经失效，在之前使用的中断方法行不通，需要改为直接操作硬件，此时应该放弃 `int` 指令，使用32位空循环实现延时，并且直接通过显存映射。在实模式下直接输出字符到qemu显存中的代码，直接照搬的话也不行，因为段寄存器的值代表的是段选择子，不是段基地址，需要再修改段寄存器。
首先设置段寄存器的值：
```nasm file:bootloader.asm
	;初始化变量
mov dword [x], 0
mov dword [y], 2        ; 从第 3 行开始旋转
mov byte [dir], 0       ; 0:右, 1:下, 2:左, 3:上
mov dword [str_idx], 0  ; 学号索引 (0-7)
mov dword [color_idx], 0; 颜色索引 (0-9)

.rotate_loop:
    ; 计算显存偏移地址：edi = (y * 80 + x) * 2
    mov eax, [y]
    imul eax, 80
    add eax, [x]
    shl eax, 1
    mov edi, eax

    ; 获取学号 "24319050"
    mov esi, my_id          ; 学号字符串基址
    add esi, [str_idx]
    mov al, [esi]           ; 取出一个字符

    ; 获取当前颜色
    mov esi, color_table    ; 颜色表基址
    add esi, [color_idx]
    mov ah, [esi]           ; 取出一个颜色属性

    ; 写入显存
    mov [gs:edi], ax

    ; 延时循环
    mov ecx, 0x200000
.delay:
    loop .delay

    ; 更新学号索引 
    inc dword [str_idx]
    cmp dword [str_idx], 8
    jne .skip_str_reset
    mov dword [str_idx], 0
.skip_str_reset:

    ; 更新颜色索引 
    inc dword [color_idx]
    cmp dword [color_idx], 10
    jne .skip_color_reset
    mov dword [color_idx], 0
.skip_color_reset:

    ; 更新坐标 
    call update_coords
    jmp .rotate_loop

; --- 坐标更新函数 ---
update_coords:
    mov al, [dir]
    cmp al, 0
    je .move_right
    cmp al, 1
    je .move_down
    cmp al, 2
    je .move_left
    cmp al, 3
    je .move_up
    ret

.move_right:
    inc dword [x]
    cmp dword [x], 79
    jne .done
    mov byte [dir], 1
    ret
.move_down:
    inc dword [y]
    cmp dword [y], 24
    jne .done
    mov byte [dir], 2
    ret
.move_left:
    dec dword [x]
    cmp dword [x], 0
    jne .done
    mov byte [dir], 3
    ret
.move_up:
    dec dword [y]
    cmp dword [y], 2        ; 回到第 3 行时转弯
    jne .done
    mov byte [dir], 0
    ret
.done:
    ret

jmp $

x        dd 0
y        dd 2
dir      db 0
str_idx  dd 0
color_idx dd 0
my_id    db '24319050'

color_table db 0x41, 0x72, 0x13, 0x04, 0xA5, 0x96, 0x27, 0x89, 0x03A, 0x5B
```
效果演示：
![[屏幕截图 2026-04-12 230225.png|500]]
### 3.2 实现32位十六进制内存转储函数
函数模块：
- `print_nibble` / `print_bytes`：打印地址，以及打印地址中的内容的函数，需要先保存 `eax` 寄存器，然后取出 `edx` 寄存器的低4位，通过 `hex_table` 转换内容存储在 `ax`，然后用 `[gs:ebx]` 写显存，最后自增 `ebx` ，弹出先前保存的 `eax`
-  `hd_line` ：外层循环，每次循环就打印一行输出。会先计算本行的显存偏移，然后调用 `print_nibble` 输出地址，并确定本行有多少字节要输出
-  `byte_loop` ：内层循环，用来输出每行的地址中的内容
-  `byte_done` ：打印一行结束，恢复寄存器，推进到下一行
核心代码：
```nasm file:bootloader.asm

.hd_line:
    test ecx, ecx
    jz   .hd_done
    ; 计算本行显存起始偏移
    mov  eax, [cur_row]
    imul eax, 160
    mov  ebx, eax                  ; ebx显存写指针
    ; 输出地址
    mov  eax, esi
    and  eax, 0xffff               ; 取低16位地址
    mov  edx, eax
    shr  edx, 12
    call .print_nibble

    mov  edx, eax
    shr  edx, 8
    call .print_nibble

    mov  edx, eax
    shr  edx, 4
    call .print_nibble

    mov  edx, eax
    call .print_nibble
    ; ':' + ' '
    mov  word [gs:ebx], 0x0e3a    ; ':'
    add  ebx, 2
    mov  word [gs:ebx], 0x0e20    ; ' '
    add  ebx, 2
    ; 计算本行实际字节数，存入 EDI
    mov  edi, 16
    cmp  ecx, edi
    jge  .use16
    mov  edi, ecx                  ; 不足16字节取实际剩余数
.use16:
    push edi                       ; 保存本行字节数
    push esi                       ; 保存行起始地址（用于之后 esi 推进）

.byte_loop:
    test edi, edi
    jz   .byte_done

    movzx eax, byte [esi]         ; 读1字节
    ; 高4位 → 十六进制字符
    mov  edx, eax
    shr  edx, 4
    call .print_bytes
    ; 低4位 → 十六进制字符
    mov  edx, eax
    call .print_bytes
    ; 空格
    mov  word [gs:ebx], 0x0f20
    add  ebx, 2

    inc  esi
    dec  edi
    jmp  .byte_loop
.byte_done:
    pop  esi                       ; 恢复行起始（不用了，但保持栈平衡）
    pop  edi                       ; 恢复本行字节数
    ; ECX 减去本行字节数，ESI 推进
    sub  ecx, edi
    add  esi, edi
    ; 换行
    inc  dword [cur_row]
    jmp  .hd_line

.print_nibble:  ;.print_bytes基本类似，只更改了颜色
    push eax
    and edx, 0x0F               ; 只保留低 4 位
    mov al, [hex_table + edx]   ; 查表
    mov ah, 0x0E
    mov [gs:ebx], ax
    add ebx, 2
    pop eax
    ret

```
运行可以看到如下结果
![[屏幕截图 2026-04-12 234946.png|500]]
可以看到，输出在 `0x8800` 的内容（`0x ffff 0000 0093 cf00`）与Assignment2.2中分析的一致
## Assignment 4 综合应用
设计一个保护模式下的简易内存浏览器，思路是在原来 `hex_dump` 的基础上加上循环打印，翻页功能等模块
- `browser_loop`：主循环，里面分别调用一系列函数来清屏、打印标题、打印地址、打印内容，就相当于每一次循环打印一页
- `draw_title` / `draw_hint` ：打印标题、当前地址以及按键提示
- `hex_dump`：直接使用前一个任务
- `read_key`：等待按键并读取
核心代码：
```nasm file:bootloader.asm
browser_loop:
    call clear_screen
    call draw_title
    call draw_hint
    mov dword [cur_row], 3
    mov esi, [view_addr]
    mov ecx, 256
    call hex_dump

    call read_key              ; 返回扫描码在 AL

    cmp al, 0x10               ; q
    je  browser_quit
    cmp al, 0x50               ; ↓
    je  browser_next
    cmp al, 0x24               ; j
    je  browser_next
    cmp al, 0x48               ; ↑
    je  browser_prev
    cmp al, 0x25               ; k
    je  browser_prev

    jmp browser_loop           ; 其他键忽略

browser_next:
    add dword [view_addr], 256
    jmp browser_loop

browser_prev:
    ; 防止地址下溢（不允许低于0）
    mov eax, [view_addr]
    cmp eax, 256
    jb  browser_loop           ; 已经在最前，忽略
    sub dword [view_addr], 256
    jmp browser_loop

browser_quit:
    ; 清屏后显示退出信息
    call clear_screen
    mov ebx, 80*12*2
    mov esi, quit_msg
    mov ecx, quit_msg_end - quit_msg
    mov ah, 0x0c               ; 亮红色
.qloop:
    mov al, [esi]
    mov word [gs:ebx], ax
    add ebx, 2
    inc esi
    loop .qloop
    hlt                        ; 停机

clear_screen:
    pushad
    mov ecx, 80*25             ; 共2000个字符格
    xor ebx, ebx               ; 从偏移0开始
.cs_loop:
    mov word [gs:ebx], 0x0720  ; 属性0x07（白字黑底）+ 空格
    add ebx, 2
    loop .cs_loop
    popad
    ret

draw_title:
    pushad
    xor ebx, ebx               ; 第0行偏移=0

    ; 输出固定前缀
    mov esi, title_prefix
    mov ecx, title_prefix_end - title_prefix
    mov ah, 0x1f               ; 蓝底白字
.tp_loop:
    mov al, [esi]
    mov word [gs:ebx], ax
    add ebx, 2
    inc esi
    loop .tp_loop

    ; 输出8位十六进制地址（view_addr完整32位）
    mov eax, [view_addr]
    ; 输出8个nibble（从高到低）
    mov ecx, 8
.addr_loop:
    push ecx
    ; 取当前最高nibble
    mov edx, eax
    shr edx, 28                ; 取最高4位
    and edx, 0x0f
    mov dl, [hex_table + edx]
    mov dh, 0x1e               ; 蓝底黄字
    mov word [gs:ebx], dx
    add ebx, 2
    shl eax, 4                 ; 下一个nibble到最高位
    pop ecx
    loop .addr_loop

    ; 输出后缀提示
    mov esi, title_suffix
    mov ecx, title_suffix_end - title_suffix
    mov ah, 0x1f
.ts_loop:
    mov al, [esi]
    mov word [gs:ebx], ax
    add ebx, 2
    inc esi
    loop .ts_loop

    popad
    ret

draw_hint:
    pushad
    mov ebx, 80*1*2            ; 第1行
    mov esi, hint_msg
    mov ecx, hint_msg_end - hint_msg
    mov ah, 0x0b               ; 青色
.hint_loop:
    mov al, [esi]
    mov word [gs:ebx], ax
    add ebx, 2
    inc esi
    loop .hint_loop
    popad
    ret
; read_key 等待键盘按下，返回扫描码在 AL
; 只响应 make code（按下），忽略 break code（松开，≥0x80）
read_key:
.wait:
    in  al, 0x64               ; 读键盘状态寄存器
    test al, 0x01              ; bit0=1 表示输出缓冲有数据
    jz  .wait                  ; 没数据继续等
    in  al, 0x60               ; 读扫描码
    test al, 0x80              ; bit7=1 是 break code（松键）
    jnz .wait                  ; 忽略松键，继续等下一个
    ret

hex_dump: ...

```
![[屏幕截图 2026-04-13 184621.png|500]]
![[屏幕截图 2026-04-13 184731.png|500]]
## 课后思考题
1. 
   计算机 BIOS 在启动最后阶段，只会自动从硬盘的第一个扇区加载 512 字节到内存的 0x7C00 位置并运行。这 512 字节就是MBR，但是512 字节的空间非常小，只能存放简单的信息和指令。对于复杂的操作系统内核显得不够用，所以为了解决 512 字节不够用的问题，让MBR从硬盘中读取一段更大的程序到内存里 。而这段被 MBR 搬运过来的程序就是 **Bootloader**。因为它是被MBR主动加载的，所以大小就不受限制了，可以完成更复杂的工作
2. 四种方式：程序查询、程序中断、DMA、通道
   使用LBA方式属于程序查询方式，实现起来比较简单，适合在引导程序使用
3. 
   因为`out 立即数, al`这种形式的`out`指令语句只支持8位的端口号，而这里`0x1f3`已经超过了8位的范围`0~255`，所以必须利用寄存器形式来操作
4. `GDT`相当于一个数组，存放着段描述符
   `段描述符`是数组中的元素，存放了一个内存段的信息
   `GDTR`相当于是 `GDT` 的指示牌，告诉CPU对应的GDT的位置信息
   `段选择子` 相当于GDT数组的index，告诉CPU在GDT的什么位置取对应的段描述符
5. 线性地址和物理地址的区别：
	线性地址是CPU在保护模式下用 `base + offset` 计算出来的，是一个连续的空间
	物理地址是计算机实际寻址用的，是主板上内存真正的”地址“信息
6. 是汇编语言的一个伪指令，用来给一个数值或表达式定义一个别名
7.  数据段描述符：原始数据高32位 0x00cf9200 ，低32位 0x0000ffff
	- 解析结果 ：
		- 基地址 ： 0x00000000 (平坦模式)
		- 段界限 ： 0xfffff 。配合 G=1 (4KB粒度)，整个段大小为 4GB 
		- S=1 ：存储器段（非系统段）
		- TYPE=0x2 (0010b) ： 可读、可写、向上扩展 的数据段
		- DPL=0 ：内核级权限
		- D/B=1 ：32 位段
	栈段描述符： 原始数据高32位 0x00409600 ，低32位 0x00000000
	- 解析结果 ：
		 - 基地址 ： 0x00000000 
		- 段界限 ： 0x00000 。配合 G=0 (字节粒度)，该段长度极小（实际开发中栈段通常也设为4GB 平坦模式，这里是为了演示）
		- S=1 ：存储器段
		- TYPE=0x6 (0110b) ： 可读、可写、向下扩展的段
		- 注意 ：对于栈段， E=1 表示向下扩展（Expand-down），偏移地址必须大于段界限
		- DPL=0 ：内核级权限。
	视频段描述符：原始数据高32位 0x0040920b ，低32位 0x80007fff
	- 解析结果 ：
		- 基地址 ： 0x000B8000 (显存的物理起始地址)
		- 段界限 ： 0x07fff (即 32KB)。配合 G=0 (字节粒度)，该段大小正好覆盖了标准的 VGA 文本模式显存区域。
		- S=1 ：存储器段。
		- TYPE=0x2 (0010b) ： 可读、可写 的数据段。
		- DPL=0 ：内核级权限。
		- 作用 ：当你将选择子加载进 GS 时， gs:0 就直接指向了物理地址 0xB8000
8. 汇编角度解释调用过程：
   首先在调用之前，将参数压栈，再执行 `call` 指令；
   然后将调用者的栈基址保存，设置新的栈基址，作为新函数的起点
   然后执行函数，其中的参数地址都是通过栈基址＋偏移访问的，执行完返回结果
   最后返回函数，恢复栈顶
9. 参见Assignment 1.1
10. 参见Assignment 1.2
11. 参见Assignment 2.1
12. 参见Assignment 3的两个程序
# Section3 实验总结与心得
### 总结
这次实验学习了三级引导链（BIOS → MBR → Bootloader → Kernel），实现了从实模式到保护模式的转变，突破了512字节的限制；掌握了LBA方式读写硬盘（I/O 端口 0x1F0~0x1F7），以及段描述符相关的概念和GDT的结构（Base、Limit、G、DPL、Type）；在保护模式下访问了4GB内存空间，以及使用qemu和gdb调试保护模式；在32位保护模式下实现了自己的程序
### 心得
从实模式变为保护模式，在汇编语言编写上的本质区别不大，只是使用的寄存器位数发生了变化。但是在调试保护模式的时候，费了很大力气，需要在各种位置设置断点，而断点的位置又得仔细琢磨才行。中间反复进行演算，甚至一句句敲si命令单步执行来测试，对段描述符的相关内容的掌握会帮助这里的理解，不然就像盲人摸象一样。Assignment 3的两个程序都比较困难，主要是在不能使用BIOS中断的情况下实现相应功能，需要做好函数模块化，循环逻辑以及直接向显存输出的实现，即使是询问大模型，得到的代码也推敲了很久才掌握，汇编语言不好写也不好读……总之是又一次对操作系统理解的进一步深入和对汇编语言的进一步熟悉
另外，学会对makefile的使用让这次实验中的调试过程大为方便，只需要输入make指令就能执行预设的命令，比起一句一句输入复杂冗长的命令要高效很多


