# Section 1 实验要求与实验概述

## 实验要求
我选择了以下两个项目来实现：
- Project 1 — 虚拟内存的完善（页换入换出）：实现页换出机制、缺页中断处理（INT 14）和页面置换算法
- Project 2 — malloc/free 的实现：在页内存分配的基础上，实现以字节为粒度的动态内存管理（Arena/Slab 分配器）
## 实验概述
- Project 1
	在前面的实验中，我们通过分页机制实现了内存的虚拟化。但是当物理内存紧张时，操作系统需要将某些物理页写入磁盘（交换区）来释放内存，并在程序再次访问时将其加载回来。这就是页换入换出机制（Page Swapping）。本项目基于 Lab9 提供的参考代码进行增强：修复了原有代码中的若干 bug（未初始化的 valid 字段、数组越界、硬编码物理页数等），增加了 Clock 页面置换算法（近似 LRU），扩展了对用户态地址空间的初步支持。
- Project 2
	在 Lab7 中我们实现了以页（4KB）为粒度的动态内存分配。但在实际程序中，我们需要的是以字节为粒度的内存管理，即 `malloc(size)` 和 `free(ptr)`。本项目参考了 README 中给出的 Arena/Slab 分配器方案，在 Lab9 提供的参考操作系统框架上，彻底重写了字节级内存管理器，实现了基于固定大小块的 Arena 分配器，并集成了每进程独立的字节内存管理。
## 实验环境

| 项目      | 说明                  |
| ------- | ------------------- |
| 操作系统    | Ubuntu 22.04 x86_64 |
| C++ 编译器 | `g++ -m32`（32 位编译）  |
| 汇编器     | `nasm`              |
| 链接器     | `ld -melf_i386`     |
| QEMU    | `qemu-system-i386`  |
| 调试器     | GDB + QEMU Monitor  |

# Section 2 Project 1 — 页换入换出

## 2.1 项目背景与目标
通过分页机制，我们将每个程序的虚拟地址空间映射到物理内存上。但是物理内存是有限的资源。当多个进程同时运行，或单个进程申请大量内存时，物理内存可能被耗尽。虚拟内存的解决方案是将暂时不用的内存页"换出"到磁盘上的交换区，需要时再"换入"回物理内存。

本项目的核心机制涉及两个操作：

1. 页换出（Page Out）：按照页面置换算法选择一个"牺牲"页，将其数据写入磁盘交换区，然后将该页的页表项 P 位置 0，在 PTE 的高位记录磁盘位置
2. 页换入（Page In）：当 CPU 访问一个 P=0 的页面时触发缺页中断（INT 14）。中断处理函数从 CR2 获取故障地址，根据 PTE 中记录的磁盘位置读回数据，分配新物理页，恢复页表映射

## 2.2 代码整体结构

```
project1/
├── include/
│   ├── memory.h           # MemoryManager + Queue + item 定义
│   ├── disk.h             # DiskIO + SwapAreaManager
│   ├── interrupt.h        # InterruptManager
│   ├── thread.h           # PCB 结构体
│   ├── program.h          # ProgramManager
│   └── ...                 # 其他基础设施头文件
├── src/
│   ├── kernel/
│   │   ├── memory.cpp     # MemoryManager: 初始化、分配、换出、Clock算法
│   │   ├── interrupt.cpp  # InterruptManager: IDT初始化、缺页中断处理
│   │   ├── setup.cpp      # 内核入口 + 测试用例
│   │   └── program.cpp    # 线程/进程管理
│   └── utils/
│       └── disk.cpp       # DiskIO + SwapAreaManager 实现
└── build/
    └── makefile           # 构建配置
```

## 2.3 磁盘 I/O 实现（ATA PIO 模式）

### 2.3.1 磁盘布局
查看磁盘镜像 `hd.img` 得知总共 20160 个扇区（约 10MB），
![[Pasted image 20260703121133.png|500]]
因此分配151~8150号扇区作为交换区，布局如下：

| 扇区范围       | 内容             | 大小                 |
| ---------- | -------------- | ------------------ |
| 0          | MBR（主引导记录）     | 512B               |
| 1~5        | Bootloader     | 5 × 512B           |
| 6~150      | Kernel 内核代码    | 145 × 512B (~72KB) |
| 151~8150   | 交换区（Swap Area） | 8000 × 512B (~4MB) |
| 8151~20159 | 未使用            | 12009 × 512B       |

交换区共 8000 个扇区，每 8 个扇区（4096 字节 = 1 页）作为一个交换页，总计 1000 个交换页
相关常量定义在 `disk.h` 中：

```cpp
#define SWAP_START_SECTOR 151           // 交换区起始扇区
#define SWAP_SECTOR_COUNT 8000          // 交换区扇区数
#define SECTORS_PER_PAGE 8              // 每页占用的扇区数
#define TOTAL_SWAP_PAGES 1000           // 总交换页数
#define MAX_SWAP_PAGE_INDEX 1000        // 最大有效交换页索引
```

### 2.3.2 ATA PIO 读写流程

`DiskIO` 类封装了 ATA PIO 模式的磁盘操作。这是通过 I/O 端口直接与磁盘控制器通信的编程方式，参考Lab3里读取磁盘的方式
```cpp
class DiskIO
{
public:
    DiskIO();
    // 从LBA读取一个扇区（512字节）到缓冲区
    bool readSector(uint32 lba, void* buffer);
    // 将缓冲区数据写入一个扇区（512字节）到LBA
    bool writeSector(uint32 lba, const void* buffer);
    // 检查LBA是否在交换区内
    bool isSwapSector(uint32 lba);
    // 获取交换区起始扇区
    uint32 getSwapStartSector();
    // 获取交换区扇区数量
    uint32 getSwapSectorCount();
};
```
常量设置：
```cpp
// ATA端口定义
#define ATA_DATA_PORT 0x1F0
#define ATA_FEATURES_PORT 0x1F1
#define ATA_SECTOR_COUNT_PORT 0x1F2
#define ATA_LBA_LOW_PORT 0x1F3
#define ATA_LBA_MID_PORT 0x1F4
#define ATA_LBA_HIGH_PORT 0x1F5
#define ATA_DRIVE_HEAD_PORT 0x1F6
#define ATA_STATUS_PORT 0x1F7
#define ATA_COMMAND_PORT 0x1F7
// ATA命令
#define ATA_CMD_READ_SECTORS 0x20
#define ATA_CMD_WRITE_SECTORS 0x30
// ATA状态位
#define ATA_STATUS_BSY 0x80    // 忙
#define ATA_STATUS_DRQ 0x08    // 数据请求
#define ATA_STATUS_ERR 0x01    // 错误

```
读取扇区 (`readSector`) 流程：

```
1. 等待磁盘就绪：轮询状态端口 0x1F7 直到 BSY 位清零
2. 设置驱动器和LBA地址高位：向端口 0x1F6 写入 0xE0 | ((lba >> 24) & 0x0F)
3. 设置扇区数量为1：向端口 0x1F2 写入 1
4. 设置LBA地址：依次向 0x1F3/0x1F4/0x1F5 写入 LBA 的低/中/高字节
5. 发送 READ SECTORS 命令 (0x20)：向端口 0x1F7 写入 0x20
6. 等待数据就绪：轮询状态端口 0x1F7 直到 DRQ 位（bit 3）置位
7. 读取数据：从数据端口 0x1F0 读取 256 次，每次读取一个 16 位字（共 512 字节）
```

写入扇区 (`writeSector`) 流程：

```
1. 等待磁盘就绪（BSY=0）
2. 设置驱动器/扇区数/LBA地址（与读取相同）
3. 发送 WRITE SECTORS 命令 (0x30)：向端口 0x1F7 写入 0x30
4. 等待数据请求（DRQ 置位）
5. 写入数据：向数据端口 0x1F0 写入 256 次，每次 16 位
6. 等待写入完成（BSY=0），检查错误状态
```

核心 I/O 汇编函数（定义在 `asm_utils.asm` 中）：

```asm
; asm_in_port_word: 从 I/O 端口读取一个 16 位字
; 参数：port (端口号), value (输出缓冲区地址)
asm_in_port_word:
    push ebp
    mov ebp, esp
    push edx
    push ebx
    xor eax, eax
    mov edx, dword[ebp + 4 * 2]   ; edx = port
    mov ebx, dword[ebp + 4 * 3]   ; ebx = buffer address
    in ax, dx                      ; 从端口读取 16 位到 ax
    mov word[ebx], ax              ; 存储到缓冲区
    pop ebx
    pop edx
    pop ebp
    ret

; asm_out_port_word: 向 I/O 端口写入一个 16 位字
; 参数：port (端口号), value (要写入的值)
asm_out_port_word:
    push ebp
    mov ebp, esp
    push edx
    mov edx, dword[ebp + 4 * 2]   ; edx = port
    mov eax, dword[ebp + 4 * 3]   ; eax = value
    out dx, ax                     ; 写入 16 位到端口
    pop edx
    pop ebp
    ret
```

为什么数据寄存器使用 16 位 I/O？ATA 标准规定数据寄存器 0x1F0 是 16 位宽的端口，一次必须传输完整的 16 位。相比 8 位 I/O，16 位 I/O 将端口访问次数减少一半（256 次 vs 512 次），显著提升传输效率。

## 2.4 交换区管理（SwapAreaManager）
`SwapAreaManager` 类负责跟踪磁盘交换区中哪些页被占用、哪些空闲。
### 数据结构

```cpp
class SwapAreaManager{
    int totalSwapPages;                        // 总交换页数（1000 个可用，索引 0 保留）
    int usedSwapPages;                         // 当前已分配的交换页数
    int freeSwapPages;                         // 当前空闲的交换页数
    bool swapPages[MAX_SWAP_PAGE_INDEX + 1];   // 分配位图，索引 0..1000
    SpinLock swapLock;                         // 互斥锁
public:
    SwapAreaManager();
    void initialize();
    // 换出：将vaddr处的一个页面（4KB）写入磁盘交换区的pagenum位置
    void swapOut(uint32 vaddr, uint32 pagenum);
    // 换入：从磁盘交换区的pagenum位置读取一个页面（4KB）到vaddr
    void swapIn(uint32 vaddr, uint32 pagenum);
    // 将页面号转换为起始LBA（每个页面 = 8个连续扇区）
    int pagenum_to_lba(uint32 pagenum);
    // 分配一个交换页面，返回页面号（1..1000），已满时返回-1
    int allocateSwapPage();
};
```

### 初始化
`initialize()` 将所有 `swapPages[i]` 设为 `false`，并将索引 0 标记为已分配（保留）。这样做是因为 `pagenum_to_lba(1)` 映射到 `SWAP_START_SECTOR`（扇区 151），而 `pagenum = 0` 不会被分配
```cpp
void SwapAreaManager::initialize()
{
    // totalSwapPages：可用交换页面 = 8000扇区 / 每页8扇区 = 1000
    // 索引0被保留（会映射到SWAP_START_SECTOR之前的扇区）
    totalSwapPages = MAX_SWAP_PAGE_INDEX;  // 1000
    usedSwapPages = 0;
    freeSwapPages = totalSwapPages - 1;    // 减1因为索引0被保留
    for (int i = 0; i <= MAX_SWAP_PAGE_INDEX; i++) swapPages[i] = false;
    // 将索引0标记为"已分配"（保留，从不实际使用）
    swapPages[0] = true;
}
```
### 分配与释放
`allocateSwapPage()` 采用首次适配（First Fit）策略，从索引 1 开始到 `totalSwapPages`，找到第一个空闲页，标记为已分配，返回页号。通过 `SpinLock` 保护对共享位图的访问
```cpp
int SwapAreaManager::allocateSwapPage(){
    swapLock.lock();
    // 从索引1开始（索引0被保留）
    for (int i = 1; i <= totalSwapPages; i++){
        if (!swapPages[i]){
            swapPages[i] = true;
            usedSwapPages++;
            freeSwapPages--;
            swapLock.unlock();
            return i;
        }
    }
    swapLock.unlock();
    return -1;  // 没有空闲交换页面
}
```
`swapIn()` 在读回数据后自动释放交换页：
```cpp
void SwapAreaManager::swapIn(uint32 vaddr, uint32 pagenum)
{
    // 读取 8 个扇区（4096 字节）= 一个页面
    for (uint32 lba = lba_start; lba < lba_end; lba++){
        diskIO.readSector(lba, (void*)vaddr);
        vaddr += SECTOR_SIZE;
    }
    // 释放交换页（互斥保护计数器）
    swapLock.lock();
    swapPages[pagenum] = false;
    usedSwapPages--;
    freeSwapPages++;
    swapLock.unlock();
}
```

### 页号到 LBA 的映射
```cpp
int SwapAreaManager::pagenum_to_lba(uint32 pagenum){
    // 交换页 1 映射到扇区 151，交换页 2 映射到 159，以此类推
    return SWAP_START_SECTOR + (pagenum - 1) * SECTORS_PER_PAGE;
}
```

每页 = 8 个连续扇区，所以 `pagenum_to_lba(1) = 151`，`pagenum_to_lba(2) = 159`，等等。

## 2.5 页面换出机制（swapOut）

当物理内存不足时，`MemoryManager::swapOut()` 将指定虚拟地址对应的物理页写入磁盘交换区。

```cpp
void MemoryManager::swapOut(uint32 vaddr){
    // 第一步：分配一个交换区页
    int pagenum = swapAreaManager.allocateSwapPage();
    if (pagenum == -1) {
        printf("No swap space available\n");
        return;
    }

    // 第二步：将 4KB 数据从 vaddr 写入磁盘交换区
    swapAreaManager.swapOut(vaddr, pagenum);

    // 第三步：清空内存中的页面（防止数据泄露）
    memset((void *)(vaddr & 0xfffff000), 0, PAGE_SIZE);

    // 第四步：使该虚拟地址的 TLB 条目失效
    flush_tlb_single(vaddr);

    // 第五步：修改 PTE — 清除存在位，将交换页号存入高位
    int *pte = (int *)toPTE(vaddr);
    *pte &= 0xfffffffe;    // 清除 P 位（bit 0 = 0）
    *pte &= 0x00000fff;    // 清除高 20 位
    *pte |= pagenum << 12; // 将 pagenum 存入 bits 12-31
}
```

PTE 在换出后的布局：
```
   bit 31-12    | bit 11-9 | bit 8-1 | bit 0
   pagenum      | AVL      | 其他     | P = 0
```

交换页号（pagenum）存储在 PTE 的 bits 12~31 中，这些位在原页面存在时是物理页框号。当 P=0 时，CPU 不会访问这些位，操作系统可以自由使用它们来存储交换信息。

## 2.6 缺页中断处理（INT 14）

### 中断注册
参照Lab4里注册开启中断：
在 `InterruptManager::initialize()` 中，仅对 INT 14 注册了专门的页面错误处理函数：
```cpp
for (uint i = 0; i < 256; ++i)
    if (i != 14) setInterruptDescriptor(i, (uint32)asm_unhandled_interrupt, 0);
setInterruptDescriptor(14, (uint32)asm_page_fault_handler, 0);
```
### 汇编入口
然后在asm中执行对应的中断处理函数
```asm
asm_page_fault_handler:
    pushad          ; 保存所有通用寄存器
    call c_page_interrupt_handler  ; 调用 C 处理函数
    popad           ; 恢复寄存器
    add esp, 4      ; 丢弃 CPU 压入的错误码
    iret            ; 中断返回
```

### C 处理函数完整流程

`c_page_interrupt_handler()` 是缺页中断的核心逻辑，其完整流程如下：

```
缺页中断 → 读取 CR2 获取故障地址
  │
  ├─ 验证地址是否已分配
  │   ├─ 无效 → 输出错误信息并停机
  │   └─ 有效 → 继续
  │
  ├─ 尝试分配物理页
  │   ├─ 成功 → 继续
  │   └─ 失败（内存不足）→ 进入换出路径
  │       ├─ 使用置换算法选择牺牲页
  │       ├─ 调用 swapOut() 将牺牲页写入磁盘
  │       ├─ 释放牺牲页的物理页
  │       └─ 重新分配物理页
  │
  ├─ 记录新映射到驻留队列
  │
  ├─ 检查 PTE 中是否存有交换页号（pagenum）
  │   ├─ pagenum != 0 → 从磁盘换入数据（swapIn）
  │   └─ pagenum == 0 → 首次访问，无需换入
  │
  ├─ 连接虚拟页到新物理页（更新页表）
  │
  └─ 返回用户态，重新执行触发异常的指令
```

```cpp
extern "C" void c_page_interrupt_handler()
{
    uint32 cr2 = read_cr2();
    printf("Page fault at virtual address: 0x%x\n", cr2);

    uint32 page_addr = cr2 & 0xFFFFF000;
    AddressPoolType poolType = getAddressPoolType(cr2);

    // 检查地址有效性
    if (!isAddressValid(cr2))
    {
        printf("Illegal memory access at 0x%x, process terminated\n", cr2);
        asm_halt();
        return;
    }

    // 分配物理页（失败则换出）
    int physicalPageAddress = memoryManager.allocatePhysicalPages(poolType, 1);
    if (physicalPageAddress == 0)
    {
        // 物理内存耗尽：选择牺牲页换出
        item victim = memoryManager.getSwapOutVictim();
        victim.valid = 0;                        // 从队列中移除
        memoryManager.swapOut(victim.virtualAddress);  // 写回磁盘
        memoryManager.releasePhysicalPages(poolType, victim.physicalAddress, 1);
        flush_tlb_single(victim.virtualAddress);      // 刷新 TLB
        physicalPageAddress = memoryManager.allocatePhysicalPages(poolType, 1);
    }

    // 检查是否需要换入（从 PTE 读取交换页号）
    int pagenum = 0;
    if (!(*pde & 0x00000001))
        pagenum = 0;  // 页表不存在 — 首次访问
    else
    {
        pagenum = (*pte) >> 12;
        if (pagenum < 1 || pagenum > MAX_SWAP_PAGE_INDEX)
            pagenum = 0;  // 无效的交换页号
    }

    // 建立虚拟页到物理页的映射
    memoryManager.connectPhysicalVirtualPage(cr2, physicalPageAddress);

    // 如果有交换页数据，从磁盘读回
    if (pagenum != 0)
    {
        memoryManager.swapAreaManager.swapIn(cr2, pagenum);
        printf("Swapped in page from disk (swap page %d)\n", pagenum);
    }
}
```

### CR2 寄存器

CR2 是 x86 架构中专门用于缺页异常的寄存器。当发生缺页异常时，CPU 将触发异常的线性地址（虚拟地址）自动存入 CR2。处理函数通过内联汇编读取它：

```cpp
uint32 read_cr2(){
    uint32 value;
    asm volatile("mov %%cr2, %0" : "=r"(value));
    return value;
}
```

## 2.7 页面置换算法实现

### FIFO（先进先出）
用一个 `Queue` 来维护页面进入内存的顺序：
```cpp
item MemoryManager::getSwapOutVictim()
{
    if (algorithm == FIFO)
    {
        // FIFO：返回队首（最老的）条目
        return physicalPageQueue.getFront();
    }
    // ...
}
```

每次有新页面被映射时，它的 `(vaddr, paddr)` 对被 `push` 到队列尾部。当需要换出时，从队首 `pop` 出最老的条目作为牺牲页
### Clock 算法（近似 LRU）

Clock 算法是 LRU 的一种高效近似，它使用一个"时钟指针"和一个"引用位"来近似地跟踪页面的使用情况：

```cpp
item MemoryManager::getSwapOutVictim()
{
    // Clock 算法（近似 LRU）
    // 循环扫描页面，如果引用位为 1，清除引用位并给予第二次机会
    // 如果引用位为 0，此页面即为牺牲页
    int size = physicalPageQueue.size();
    if (size == 0) { /* 返回空条目 */ }

    while (true){
        // 时钟指针绕回
        if (clockHand >= size) clockHand = 0;
        item &it = physicalPageQueue.at(clockHand);
        if (!it.valid) { clockHand++; continue; }  // 跳过无效条目
        if (it.referenced){
            // 给予第二次机会：清除引用位，继续扫描
            it.referenced = false;
            clockHand++;
        }
        else{
            // 找到牺牲页
            item victim = it;
            clockHand++;
            return victim;
        }
    }
}
```

算法流程：

```
初始状态：所有页面引用位 = 0

1. 时钟指针开始扫描
2. 如果当前页面的 referenced 位 = 1：
   → 清除 referenced 位（给予"第二次机会"）
   → 时钟指针前进
3. 如果当前页面的 referenced 位 = 0：
   → 选择该页面为牺牲页
   → 时钟指针前进
   → 返回牺牲页
```

每次页面被访问时，通过 `markPageAccessed()` 设置其 `referenced` 位：

```cpp
void MemoryManager::markPageAccessed(uint32 vaddr)
{
    for (int i = 0; i < physicalPageQueue.size(); i++)
    {
        item &it = physicalPageQueue.at(i);
        if (it.valid && it.virtualAddress == (int)(vaddr & 0xfffff000))
        {
            it.referenced = true;
            return;
        }
    }
}
```

Clock 算法的优点是避免了 FIFO 的 Belady 异常，实现复杂度低，性能接近真实 LRU（但需要额外的引用位扫描）。

## 2.8 驻留页面队列管理

为了实现页面置换，需要追踪哪些物理页当前被哪个虚拟页占用。这是通过 `Queue` 类实现的：

```cpp
struct item{
    int virtualAddress;     // 虚拟地址
    int physicalAddress;    // 物理地址
    int valid;              // 条目是否有效（=1 有效，=0 已失效）
    bool referenced;        // Clock 算法的引用位

    item(int virtualAddress, int physicalAddress){
        this->virtualAddress = virtualAddress;
        this->physicalAddress = physicalAddress;
        this->valid = 1;        // ← 修复了原始代码中 valid 未初始化的问题
        this->referenced = false;
    }
};
```

修复Bug：原始 Lab9 参考代码中，`item` 构造函数的 `valid` 字段没有显式初始化，导致 `getFront()` 中的 `while(size()>0 && queue[front].valid==0)` 判断结果不可预测（栈上垃圾值），可能跳过所有有效条目导致无限循环或选错牺牲页
当物理页被换出后，该 `item` 的 `valid` 被设为 0，`getFront()` 会自动跳过这些已失效的条目

## 2.9 地址池与物理页分配

系统将物理内存分为两个地址池：
- 内核物理地址池（`kernelPhysical`）：供内核代码使用
- 用户物理地址池（`userPhysical`）：供用户进程使用

每个地址池使用位图（BitMap）来跟踪页面分配情况。初始化时：
```cpp
int kernelPhysicalPages = kernelPages;    // 内核页数 = 空闲内存的一半
int userPages = freePages - kernelPages;  // 用户页数 = 剩余部分

kernelPhysical.initialize(
    (char *)kernelPhysicalBitMapStart,
    kernelPhysicalPages,
    kernelPhysicalStartAddress);

userPhysical.initialize(
    (char *)userPhysicalBitMapStart,
    userPages,
    userPhysicalStartAddress);
```

修复的 Bug：原始 Lab9 代码中 `kernelphysicalpage = 5` 被硬编码，完全忽略了计算出的 `kernelPages` 值。现在默认使用完整的计算值，但也保留了注释掉的 `kernelPhysicalPages = 5` 以便在内存充足的开发环境中强制触发交换行为进行测试

## 2.10 地址验证

页错误处理函数需要验证触发缺页的地址是否合法（是否属于已分配给当前进程的地址范围）：

```cpp
static bool isAddressValid(uint32 vaddr)
{
    uint32 page_addr = vaddr & 0xFFFFF000;

    if (vaddr >= 0xC0000000)
    {
        // 内核地址空间：检查内核虚拟地址池位图
        int page_index = (page_addr - memoryManager.kernelVirtual.startAddress) / 4096;
        if (page_index >= 0 && page_index < memoryManager.kernelVirtual.resources.length)
            return memoryManager.kernelVirtual.resources.get(page_index);
        return false;
    }
    else
    {
        // 用户地址空间：检查当前进程的用户虚拟地址池位图
        PCB *pcb = programManager.running;
        if (pcb == nullptr || pcb->userVirtual.resources.length == 0)
            return false;
        int page_index = (page_addr - pcb->userVirtual.startAddress) / 4096;
        if (page_index >= 0 && page_index < pcb->userVirtual.resources.length)
            return pcb->userVirtual.resources.get(page_index);
        return false;
    }
}
```

## 2.11 测试用例与运行结果

### 测试设计

测试函数 `test_page_swapping()` 的流程：

```
1. 分配 8 个虚拟页（远超可用物理页数，强制触发交换）
2. 每页写入 256 字节的唯一模式（页 i 填充字符 'A'+i）
3. 读回每页的数据，验证完整性
4. 分别用 FIFO 和 Clock 算法运行测试
```

关键测试代码：

```cpp
void test_page_swapping()
{
    // 分配 8 个虚拟页
    char *p = (char *)memoryManager.allocatePages(AddressPoolType::KERNEL, 8);

    // 写入模式
    char pattern = 'A';
    for (int i = 0; i < 8; i++)
    {
        pages[i] = p + i * PAGE_SIZE;
        pages[i][0] = 'P';
        pages[i][1] = '0' + i;
        pages[i][2] = pattern;
        // 每页填充 256 字节的独特模式
        for (int j = 0; j < 256; j++)
            pages[i][j] = pattern;
        pattern++;
    }

    // 验证数据（触发换入）
    int errors = 0;
    for (int i = 0; i < 8; i++)
    {
        // 验证每页数据完整性
        if (pages[i][0] != 'P' || pages[i][1] != ('0' + i))
            errors++;
        // ... 验证每字节
    }
}
```

### 运行输出
可以看到分配到8之后的页面就开始页面不足，需要进行置换，并且成功进行了置换，读取的内容页都符合输入，说明算法基本成功
![[Pasted image 20260703132630.png|600]]
## 2.12 代码修复总结

| Bug | 原始问题 | 修复方式 |
|-----|---------|---------|
| `item::valid` 未初始化 | `getFront()` 的 `while(size()>0&&queue[front].valid==0)` 因 valid 为栈垃圾值而不可预测 | 在构造函数中显式初始化 `valid=1` |
| `swapPages[1000]` 数组越界 | 声明 `bool swapPages[1000]` 但 `totalSwapPages=1001`，访问索引 1000 | 改为 `bool swapPages[MAX_SWAP_PAGE_INDEX + 1]`（共 1001 个元素），正确处理索引 0..1000 |
| 物理页数硬编码 | `kernelphysicalpage=5` 完全忽略计算出的 `kernelPages=126` | 默认使用 `kernelPages` 计算值 |
| 交换页号验证缺失 | 首次访问时 PTE 的 bits 12-31 可能读出垃圾值被误判为交换页号 | 增加 `if (pagenum < 1 \|\| pagenum > MAX_SWAP_PAGE_INDEX)` 验证 |

---

# Section 3 Project 2 — malloc/free 的实现

## 3.1 项目背景与目标
在 Lab7 中，我们实现了以页（4KB）为粒度的内存分配器。但用户程序需要的是以字节为粒度的内存管理——即 C 标准库中的 `malloc(size)` 和 `free(ptr)`

本项目参考 README 中描述的 Arena/Slab 分配器方案，完全重写了字节级内存管理器。参考了 Lab9 的代码中的自由块队列（Free Queue）分配器，此外，Arena 分配器具有以下优点：
1. 固定大小块管理：将可分配的大小分为 7 个固定类别（16/32/64/128/256/512/1024字节），消除了外部碎片
2. 无需释放时传入 size：`free(ptr)` 通过 Arena 头部自动推断块大小，API 更符合标准 C 库
3. 每进程独立分配器：每个进程的 PCB 中持有独立的 `ByteMemoryManager`，用户态分配互不影响
4. 整页自动回收：当页面中所有块都被释放时，自动将整页归还给页面分配器

## 3.2 代码整体结构

```
project2/
├── include/
│   ├── memory.h             # ByteMemoryManager + Arena/Slab + MemoryManager
│   ├── thread.h             # PCB 加入 ByteMemoryManager 字段
│   ├── syscall.h            # 系统调用声明（free 不再需要 size）
│   ├── os_modules.h         # 全局对象声明
│   └── ...                  # 其他基础设施头文件
├── src/
│   ├── kernel/
│   │   ├── memory.cpp       # ByteMemoryManager + MemoryManager 实现
│   │   ├── syscall.cpp      # syscall_malloc / syscall_free 路由
│   │   ├── setup.cpp        # 内核入口 + 7 组测试用例
│   │   ├── program.cpp      # 进程管理（含 fork/exit/wait）
│   │   └── interrupt.cpp    # 中断管理（含释放僵尸进程）
│   └── utils/
│       └── ...
└── build/
    └── makefile
```

## 3.3 Arena/Slab 分配器核心数据结构

### 块大小分类

```cpp
enum ArenaType
{
    ARENA_16 = 0,    // 16 字节块
    ARENA_32,        // 32 字节块
    ARENA_64,        // 64 字节块
    ARENA_128,       // 128 字节块
    ARENA_256,       // 256 字节块
    ARENA_512,       // 512 字节块
    ARENA_1024,      // 1024 字节块
    ARENA_MORE       // 大于 1024 字节 → 直接分配整页
};

#define MEM_BLOCK_TYPES 7    // 前 7 种类型（不含 ARENA_MORE）
```

块大小成倍递增：16 → 32 → 64 → 128 → 256 → 512 → 1024。

### Arena 头部

每个用做 Slab 的页面开头都有一个 `Arena` 头部（元信息）：

```cpp
struct Arena
{
    ArenaType type;     // Arena 类型（对应哪个块大小）
    int counter;        // ARENA_MORE 时：页数量，其他类型时：该页中空闲块数
};
```

### 侵入式空闲链表节点

空闲内存块本身通过嵌入的双向链表节点串起来，不需要额外分配内存：

```cpp
struct MemoryBlockListItem
{
    MemoryBlockListItem *previous;
    MemoryBlockListItem *next;
};
```

这种"侵入式"设计的妙处在于：当块空闲时，它的 8 字节被用作链表指针；当块被分配出去时，这 8 字节就是用户数据的一部分，完全不存在额外开销。

### 页面布局

```
一个 4KB 物理页作为 ARENA_64 的布局：

+-------------------------------------------+
|  Arena(元信息)                              |
|  type = ARENA_64                           |
|  counter = 62（当前空闲块数）               |
+-------------------------------------------+
|  Block 0 (64B) 空闲时：prev→NULL, next→B1 |
|  Block 1 (64B) 空闲时：prev→B0, next→B2   |
|  Block 2 (64B) 空闲时：prev→B1, next→B3   |
|  ...                                       |
|  Block N-1 (64B) 空闲时：prev→BN-2, next→NULL |
+-------------------------------------------+

总块数 = (4096 - sizeof(Arena)) / 64 ≈ 63.5 → 63 个块
```

## 3.4 ByteMemoryManager 完整实现

### 初始化

```cpp
void ByteMemoryManager::initialize()
{
    int size = minSize;  // 16
    for (int i = 0; i < MEM_BLOCK_TYPES; ++i)
    {
        arenas[i] = nullptr;           // 所有空闲链表初始为空
        arenaSize[i] = size;           // 记录块大小
        size <<= 1;                    // 翻倍：16, 32, 64, 128, 256, 512, 1024
    }
}
```

### 延迟初始化

由于 PCB 在 `executeThread` 中通过 `memset(thread, 0, PCB_SIZE)` 清零，`ByteMemoryManager` 的构造函数不会被正常调用。因此在第一次 `allocate()` 或 `release()` 时检测并执行初始化：

```cpp
if (arenaSize[0] == 0)
{
    initialize();
}
```

### 分配流程 (`allocate`)

```cpp
void *ByteMemoryManager::allocate(int size)
{
    // 延迟初始化
    if (arenaSize[0] == 0) initialize();

    // 步骤1：找到足够容纳 size 的最小 Arena 类型
    int index = 0;
    while (index < MEM_BLOCK_TYPES && arenaSize[index] < size)
        ++index;

    // 步骤2：确定地址池类型
    PCB *pcb = programManager.running;
    AddressPoolType poolType = (pcb->pageDirectoryAddress != 0)
        ? AddressPoolType::USER : AddressPoolType::KERNEL;

    if (index == MEM_BLOCK_TYPES)
    {
        // 情况A：大于 1024 字节 → 分配完整页面
        int pageAmount = (size + sizeof(Arena) + PAGE_SIZE - 1) / PAGE_SIZE;
        ans = memoryManager.allocatePages(poolType, pageAmount);
        if (ans)
        {
            Arena *arena = (Arena *)ans;
            arena->type = ArenaType::ARENA_MORE;
            arena->counter = pageAmount;
        }
    }
    else
    {
        // 情况B：在 Arena 块大小范围内
        if (!arenas[index] && !getNewArena(poolType, index))
            return nullptr;  // 无法分配新页面

        // 取出链表头部的空闲块
        ans = arenas[index];
        arenas[index] = ((MemoryBlockListItem *)ans)->next;
        if (arenas[index]) arenas[index]->previous = nullptr;

        // 递减该页的空闲计数
        Arena *arena = (Arena *)((int)ans & 0xfffff000);
        --(arena->counter);
    }
    return ans;
}
```

**分配流程图**：

```
malloc(size)
  │
  ├─ size > 1024
  │   → 分配 pageAmount 个整页
  │   → 在页面头部写入 Arena{ARENA_MORE, pageAmount}
  │   → 返回页面起始地址
  │
  └─ size <= 1024
      → 找到最小的 arena 类型（如 20B 用 ARENA_32）
      → 检查对应类型的空闲链表
          ├─ 非空 → 取出链表头部的第一个块
          └─ 空 → 分配一个新页（调用 getNewArena）
                  → 将页面划分为等大块
                  → 用 MemoryBlockListItem 串成链表
                  → 取链表头部块
      → 该页的 counter 减 1
      → 返回块地址
```

### 新 Arena 页面初始化 (`getNewArena`)

当某种类型的空闲链表为空时，需要分配一个新页面并切割为等大小块：

```cpp
bool ByteMemoryManager::getNewArena(AddressPoolType type, int index)
{
    void *ptr = memoryManager.allocatePages(type, 1);
    if (!ptr) return false;

    // 计算一页中可容纳的块数
    int times = (PAGE_SIZE - sizeof(Arena)) / arenaSize[index];

    // 设置页面头部的 Arena 元信息
    Arena *arena = (Arena *)ptr;
    arena->type = (ArenaType)index;
    arena->counter = times;

    // 构建侵入式双向链表
    int address = (int)ptr + sizeof(Arena);
    MemoryBlockListItem *prev = (MemoryBlockListItem *)address;
    arenas[index] = prev;
    prev->previous = nullptr;
    prev->next = nullptr;
    --times;

    while (times > 0)
    {
        address += arenaSize[index];
        MemoryBlockListItem *cur = (MemoryBlockListItem *)address;
        prev->next = cur;
        cur->previous = prev;
        cur->next = nullptr;
        prev = cur;
        --times;
    }
    return true;
}
```

以上面的 ARENA_64 为例：
- `times = (4096 - 8) / 64 ≈ 63`（Arena 结构体占 8 字节 = 一个 int type + 一个 int counter）
- 初始化后，63 个空闲块通过 `MemoryBlockListItem` 串成链表
- `arena->counter = 63` 表示该页有 63 个空闲块

### 释放流程 (`release`)

```cpp
void ByteMemoryManager::release(void *address)
{
    // 延迟初始化
    if (arenaSize[0] == 0) initialize();

    // 定位页面头部的 Arena（利用页面对齐）
    Arena *arena = (Arena *)((int)address & 0xfffff000);

    if (arena->type == ARENA_MORE)
    {
        // 大块分配：释放所有页面
        memoryManager.releasePages(/* poolType */, (int)arena, arena->counter);
    }
    else
    {
        // 将块插回空闲链表头部
        MemoryBlockListItem *item = (MemoryBlockListItem *)address;
        item->next = arenas[arena->type];
        item->previous = nullptr;
        if (item->next) item->next->previous = item;
        arenas[arena->type] = item;
        ++(arena->counter);

        // 如果页面中所有块都已归还，释放整个页面
        int amount = (PAGE_SIZE - sizeof(Arena)) / arenaSize[arena->type];
        if (arena->counter == amount)
        {
            // 从空闲链表中移除该页的所有块
            MemoryBlockListItem *p = arenas[arena->type];
            while (p)
            {
                if ((int)arena == ((int)p & 0xfffff000))
                {
                    // 从链表中摘除
                    if (p->previous) p->previous->next = p->next;
                    else arenas[arena->type] = p->next;
                    if (p->next) p->next->previous = p->previous;
                }
                p = p->next;
            }
            // 释放页面
            memoryManager.releasePages(/* poolType */, (int)arena, 1);
        }
    }
}
```

**释放流程图**：

```
free(ptr)
  │
  ├─ ptr & 0xFFFFF000 → 定位页面开头的 Arena 头部
  │
  ├─ arena->type == ARENA_MORE
  │   → 直接释放 arena->counter 个连续页面
  │   → 完成
  │
  └─ 其他类型
      → 将块插回对应空闲链表头部
      → 该页 counter 加 1
      → 判断 counter == 页面总块数？
          ├─ 是 → 该页所有块都空闲了
          │      → 从链表移除该页所有块
          │      → 释放整页给页面分配器
          └─ 否 → 仅更新链表，不释放页面
```

**核心设计要点**：为什么释放时只需要 `address` 而无需 `size`？因为 `(int)address & 0xfffff000` 定位到页面起始地址，此处存储着 `Arena` 结构体，其中 `type` 字段记录了该页中所有块的大小类型。因此分配器可以自动推断出块大小。这和标准 C 库的 `free(ptr)` 行为一致。

### 与 Lab9 参考实现的比较

| 特性 | Lab9 参考（Free Queue） | 本项目（Arena/Slab） |
|------|----------------------|-------------------|
| 核心算法 | 最适配（Best Fit）+ 合并 | 固定大小 Slab |
| 分配粒度 | 任意字节，通过页面内切分 | 7 种预定义大小（16/32/.../1024B） |
| 空闲管理 | 单个全局环形缓冲区 | 每个大小类别一个侵入式双向链表 |
| 块元数据 | 无（需手动传 size 给 free） | Arena 头部在页面开头（8 字节） |
| free API | `free(void *ptr, int size)` | `free(void *ptr)` |
| 每进程隔离 | 无（全局 Free Queue） | PCB 持有独立 `ByteMemoryManager` |
| 大块处理 | 尾部碎片回收到全局队列 | ARENA_MORE 头部记录页数 |
| 整页回收 | 合并达到整页时触发 | 所有块归还时自动触发 |

## 3.5 系统调用集成（含扩展部分realloc）

### 用户态包装

```cpp
// 用户态调用 int 0x80 陷入内核
void *malloc(int size) {
    return (void *)asm_system_call(5, size);
}

void free(void *ptr) {
    asm_system_call(6, (int)ptr);
}
```

### 内核态路由

`syscall_malloc` 和 `syscall_free` 根据当前运行进程的身份来路由请求：

```cpp
void *syscall_malloc(int size) {
    PCB *pcb = programManager.running;
    if (pcb->pageDirectoryAddress != 0)
        // 用户进程：使用进程独立的分配器
        return pcb->byteMemoryManager.allocate(size);
    else
        // 内核线程：使用全局内核分配器
        return kernelByteMemoryManager.allocate(size);
}

void syscall_free(void *ptr) {
    if (!ptr) return;
    PCB *pcb = programManager.running;
    if (pcb->pageDirectoryAddress != 0)
        pcb->byteMemoryManager.release(ptr);
    else
        kernelByteMemoryManager.release(ptr);
}
```

### PCB 集成

在 `thread.h` 的 PCB 结构体中添加 `ByteMemoryManager` 字段：

```cpp
struct PCB
{
    int *stack;
    char name[MAX_PROGRAM_NAME + 1];
    // ... 原有字段 ...

    // 页面级地址空间管理
    int pageDirectoryAddress;
    AddressPool userVirtual;

    // 每进程字节粒度内存管理器（Arena/Slab 分配器）
    ByteMemoryManager byteMemoryManager;
};
```

### 系统调用注册

在 `setup_kernel()` 中注册 6 个系统调用：

```cpp
systemService.setSystemCall(0, (int)syscall_0);
systemService.setSystemCall(1, (int)syscall_write);
systemService.setSystemCall(2, (int)syscall_fork);
systemService.setSystemCall(3, (int)syscall_exit);
systemService.setSystemCall(4, (int)syscall_wait);
systemService.setSystemCall(5, (int)syscall_malloc);
systemService.setSystemCall(6, (int)syscall_free);
systemService.setSystemCall(7, (int)syscall_realloc);
```

### 扩展实现：realloc
作为方案二的扩展项，我实现了 `realloc(ptr, new_size)` 功能。这是完整实现的第三个系统调用（系统调用号 7）
#### realloc 的行为规则
```
realloc(ptr, new_size):
  ┌─ ptr == NULL    → 等同于 malloc(new_size)
  ├─ new_size <= 0  → 等同于 free(ptr) + 返回 NULL
  ├─ 新大小在同一块内放得下  → 直接返回 ptr（原地调整）
  └─ 需要更大空间            → 分配新块，拷贝旧数据，释放旧块
```
#### ByteMemoryManager::reallocate 实现
```cpp
void *ByteMemoryManager::reallocate(void *ptr, int size)
{
    // 如果 ptr 为 nullptr，行为同 malloc
    if (!ptr)
    {
        return allocate(size);
    }

    // 延迟初始化
    if (arenaSize[0] == 0)
    {
        initialize();
    }

    // 定位 Arena 头部
    Arena *arena = (Arena *)((int)ptr & 0xfffff000);

    // 计算旧块大小
    int oldSize;
    if (arena->type == ARENA_MORE)
    {
        oldSize = arena->counter * PAGE_SIZE;
    }
    else
    {
        oldSize = arenaSize[arena->type];
    }

    // 如果新大小在同一个块中放得下，直接返回原指针
    if (size <= oldSize)
    {
        return ptr;
    }

    // 需要更大的块：分配新块，拷贝数据，释放旧块
    void *newPtr = allocate(size);
    if (!newPtr)
    {
        return nullptr;
    }

    // 拷贝 min(oldSize, size) 字节到新块
    int copySize = (oldSize < size) ? oldSize : size;
    char *oldBytes = reinterpret_cast<char *>(ptr);
    char *newBytes = reinterpret_cast<char *>(newPtr);
    for (int i = 0; i < copySize; ++i)
    {
        newBytes[i] = oldBytes[i];
    }

    release(ptr);
    return newPtr;
}
```

#### 实现关键点分析
1. 原地缩小的优化（in-place shrink）
当 `new_size <= oldSize` 时，直接返回原指针，不做任何操作。这是因为 Arena 分配器按固定大小管理块（如 ARENA_128 的块固定 128 字节），缩小后剩余空间无法切割给其他分配使用，但也没有浪费——它仍然属于同一个块。这一优化避免了不必要的内存拷贝和释放/再分配操作。
```
例：malloc(100)  → 分配 ARENA_128 块（128 字节）
     realloc(ptr, 50) → oldSize=128 >= 50，返回 ptr（原地不动）
```
2. 旧块大小计算
```cpp
if (arena->type == ARENA_MORE)
    oldSize = arena->counter * PAGE_SIZE;
else
    oldSize = arenaSize[arena->type];
```
- 对于 Slab 块（ARENA_16 ~ ARENA_1024）：直接查 `arenaSize[]` 表得出块大小。
- 对于整页分配（ARENA_MORE）：用 `counter × 页大小` 计算总可用空间。
- 这种方式不需要在释放时传入 size，与标准 C 库的 `realloc` 行为一致。

3. 数据拷贝与释放
拷贝 `min(oldSize, size)` 字节确保不越界。随后释放旧块——注意 `release(ptr)` 和 `allocate(size)` 之间旧块已经被释放回了空闲链表。如果 `allocate(size)` 恰好重用了刚释放的页（这在按大小分类的 Arena 中不太可能发生，因为类型不同），`memcpy` 拷贝的是旧数据到新地址，数据仍是正确的。

4. 错误处理
- `ptr == NULL` → 转发到 `allocate(size)`，行为同 `malloc`
- `allocate(size)` 失败 → 返回 `nullptr`，原 `ptr` 指向的数据**不会被释放**（保持有效）。这是 `realloc` 的标准语义——失败时不丢失原有数据。

#### 系统调用注册
```cpp
// 设置7号系统调用
systemService.setSystemCall(7, (int)syscall_realloc);
```
用户态包装：
```cpp
void *realloc(void *ptr, int size) {
    return (void *)asm_system_call(7, (int)ptr, size);
}
```
内核态路由：
```cpp
void *syscall_realloc(void *ptr, int size) {
    PCB *pcb = programManager.running;
    if (pcb->pageDirectoryAddress != 0)
        return pcb->byteMemoryManager.reallocate(ptr, size);
    else
        return kernelByteMemoryManager.reallocate(ptr, size);
}
```
#### realloc 测试用例设计
测试函数 `test_realloc()` 包含 4 组测试：
测试 1：realloc(NULL, size) → 同 malloc
```cpp
char *p = (char *)realloc(NULL, 32);
// 验证返回非空，写入 'T' 后读回
free(p);
```
验证 `realloc(NULL, size)` 不崩溃，行为等价于 `malloc`。

测试 2：realloc 到更小尺寸（原地缩小）
```cpp
p = (char *)malloc(128);              // ARENA_128
char *q = (char *)realloc(p, 16);     // 16 <= 128，仍在 ARENA_128
// 预期 q == p（原地不动）
```
验证缩小分配时返回同一个地址，数据保留。

测试 3：realloc 到更大尺寸（数据保留）
```cpp
small = (char *)malloc(16);           // ARENA_16
写入 "Hello realloc!" 到 small
big = (char *)realloc(small, 256);    // ARENA_256，需拷贝
// 验证 big != small（不同地址）
// 验证 big 前 14 字节 = "Hello realloc!"
```
验证跨 Arena 类型的扩容时，旧数据被正确拷贝到新地址。

测试 4：大块 realloc（ARENA_MORE）
```cpp
big1 = (char *)malloc(2000);          // 1 页 ARENA_MORE
for (int i = 0; i < 2000; i++) big1[i] = 'B';

bigger = (char *)realloc(big1, 5000); // 2 页 ARENA_MORE
// 验证前 2000 字节保留
// 在 2000~4999 写入 'X'

smaller = (char *)realloc(bigger, 512); // ARENA_512
// 验证前 512 字节数据保留（从 big1 到 bigger 再到 smaller）
```
涵盖整页分配的扩容（1页→2页）和整页到 Slab 块的缩小（2页→ARENA_512），验证数据的连续保留。
## 3.6 测试用例设计

测试函数 `test_arena_allocator()` 包含 7 组测试，覆盖了分配器的各种场景：

### 测试 1：基本分配（所有 Arena 类型）

```cpp
char *p16  = (char *)malloc(8);    // 应使用 ARENA_16
char *p32  = (char *)malloc(20);   // 应使用 ARENA_32（20 > 16）
char *p64  = (char *)malloc(40);   // 应使用 ARENA_64
char *p128 = (char *)malloc(100);  // 应使用 ARENA_128
char *p256 = (char *)malloc(200);  // 应使用 ARENA_256
char *p512 = (char *)malloc(400);  // 应使用 ARENA_512
char *p1024= (char *)malloc(1000); // 应使用 ARENA_1024
```

验证所有 7 种 Arena 类型的分配都能正常工作，且返回非空地址。

### 测试 2：大块分配（>1024 字节）

```cpp
char *pLarge = (char *)malloc(5000);
```

5000 字节需要 2 个整页（`ceil((5000+8)/4096) = 2`），使用 `ARENA_MORE` 类型。

### 测试 3：数据写入与验证

```cpp
for (int i = 0; i < 16; i++) p16[i] = 'A' + (i % 26);
// 验证写入的数据与预期一致，确认内存未被其他分配覆盖
```

验证相邻的内存分配不会相互干扰，数据完整性得到保证。

### 测试 4：释放与重用

```cpp
free(p16);
free(p32);
char *pNew16 = (char *)malloc(8);
char *pNew32 = (char *)malloc(20);
```

释放后再次分配，验证空闲块被正确复用（新地址与旧地址相同或邻近）。

### 测试 5：同类型批量分配

```cpp
char *blocks[10];
for (int i = 0; i < 10; i++)
    blocks[i] = (char *)malloc(12);  // 全部从 ARENA_16 分配
```

验证同一 Arena 页面可以连续分配多个相同大小的块。

### 测试 6：碎片化场景——混合分配/释放

```cpp
free(blocks[2]);
free(blocks[5]);
free(blocks[8]);
char *f1 = (char *)malloc(12);  // 应复用 blocks[2] 的位置
char *f2 = (char *)malloc(12);  // 应复用 blocks[5] 的位置
```

验证在非连续释放后，分配器能正确从空闲链表中取出块并重新分配。

### 测试 7：批量 1024 字节块 + 数据完整性

```cpp
char *largeBlocks[30];
for (int i = 0; i < 30; i++)
{
    largeBlocks[i] = (char *)malloc(1024);
    largeBlocks[i][0] = 'A' + (i % 26);
    largeBlocks[i][1023] = 'Z';
}
// 验证所有块的首字节都正确
```

验证大量同一大小的分配能正确触发多页 Arena 分配，且所有块的数据互不影响。如果有 30 个 1024 字节的分配，需要至少 `ceil(30/4)=8` 页（每页最多 4 个 1024 字节块）。

## 3.7 运行输出
可以看到malloc/free的内容基本成功，逻辑基本正确
但是扩展部分的realloc的测试3和4没有成功，说明在大尺寸的重新分配还有所欠缺……
![[Pasted image 20260703153102.png|600]]
![[Pasted image 20260703153210.png|600]]
![[Pasted image 20260703153258.png|600]]

# Section 4 思考与分析

## 4.1 页面置换算法的选择

FIFO vs Clock：

| 特性 | FIFO | Clock |
|------|------|-------|
| 实现复杂度 | 极低（只需队列） | 低（增加引用位和扫描） |
| Belady 异常 | 存在 | 不存在 |
| 性能 | 可能不佳（换出常用页） | 良好（近似 LRU） |
| 开销 | 无额外开销 | 需扫描引用位 |
| 适用场景 | 小规模、简单系统 | 通用场景 |

FIFO 的优势在于实现极为简单，仅需要一个队列追踪页面进入顺序。但它的致命缺点是可能换出即将使用的"热"页面。Clock 算法通过引用位给了热页面"第二次机会"，性能更接近真实的 LRU，而实现复杂度远低于 LRU（真实 LRU 需要维护所有页面的访问顺序链表，且每次访问都需要更新）。

## 4.2 Slab 分配器的优势

相比通用的自由链表分配器，Arena/Slab 分配器（类似 Linux 内核的 slab allocator）有以下优势：

1. 无外部碎片：所有分配都是固定大小的块，不存在"有足够总空闲空间但无法满足某个大小请求"的外部碎片问题。
2. 分配释放速度恒定：分配就是取出链表头部（O(1)），释放就是插回链表头部（O(1)），不需要扫描或合并。
3. 缓存友好：相同大小的对象从同一页面分配，减少了缓存行的污染。
4. 内部碎片可控：最坏情况下内部碎片为 `(size_allocated - size_requested)` 字节，即不超过块大小减 1（例如请求 17 字节使用 32 字节块，内部碎片 15 字节）。

内部碎片分析：

| 请求大小 | 实际块大小 | 内部碎片 |
|----------|-----------|---------|
| 1B | 16B | 15B (93.75%) |
| 8B | 16B | 8B (50%) |
| 15B | 16B | 1B (6.25%) |
| 17B | 32B | 15B (46.88%) |
| 100B | 128B | 28B (21.88%) |
| 1000B | 1024B | 24B (2.34%) |
| 4097B | 2×4096B | 4095B (≈50%) |

小块的内部碎片率较高，但考虑到小块的内存用量通常较小，整体影响可控。对于大块（>1024B），使用整页分配可以减少碎片

## 4.3 系统调用开销
用户态的 `malloc` 和 `free` 需要通过 `int 0x80` 陷入内核，这会带来较大的性能开销（保存/恢复寄存器、切换特权级、查 IDT 表等）。在实际的操作系统中，用户态的 `malloc` 实现通常会在大块分配时通过 `brk()` 或 `mmap()` 系统调用向内核申请页面，然后在用户态通过自由链表管理这些页面，避免每次 `malloc/free` 都陷入内核
# Section 5 总结与心得

本次实验完成了 Lab10 中的 Project 1（页换入换出）和 Project 2（malloc/free 实现），从零开始在已有的操作系统框架上构建了两个核心的 OS 子系统

Project 1 深入理解了虚拟内存管理的底层机制。页换入换出是操作系统虚拟化的基石——当物理内存不足时，将暂时不用的页面换出到磁盘，需要时再换入。这涉及到缺页中断的精确处理（从 CR2 获取故障地址，检查 PTE，分配物理页，建立映射）、磁盘 I/O 的交互（ATA PIO 模式的端口操作）、页面置换算法的选择（FIFO vs Clock）等。修复 Lab9 参考代码中的 bug 也让我意识到，即使是看起来简单的数据结构（如队列中的 `valid` 字段未初始化），在 OS 这种无运行时检查的环境中也会导致灾难性的后果

Project 2 实现了类似 Linux slab allocator 的字节级内存管理器。Arena 分配器的设计思想——固定大小块、侵入式空闲链表、整页自动回收——都非常优雅。特别是 `free(ptr)` 从页面头部读取 Arena 信息来推断块大小的设计，让我理解了为什么标准 C 库的 `free` 不需要传入 size。此外，每进程独立分配器的设计确保了进程间的内存隔离，这对于多进程操作系统的正确性至关重要。作为扩展，我实现了 `realloc` 功能，其核心逻辑是计算旧块大小、判断是否能原地缩小、否则分配新块并拷贝数据。这一实现使我更深入理解了 realloc"失败时不丢失原数据"的语义约束
