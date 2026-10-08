# Section1 实验要求与实验概述

实验要求：阅读README.md并完成实验任务和思考题

实验概述：
	在前面的章节中，我们已经实现了一个具有中断处理、内存管理、进程管理和系统调用等功能的原型操作系统。然而，我们的操作系统还缺少一个非常重要的组件——文件系统。文件系统是操作系统中负责管理持久化存储数据的子系统，它为用户和程序提供了一种方便的方式来组织、存储和访问磁盘上的数据。
	在本章中，我们将在前面实验的基础上，实现一个简化的 FAT16 文件系统。我们首先从磁盘驱动开始，实现 ATA PIO 模式的磁盘读写驱动程序。然后，在磁盘驱动之上构建一个简化的 FAT16 文件系统，包括文件分配表（FAT）、目录项管理、文件的创建/读取/写入/删除等操作。最后，我们将文件系统集成到 Shell 中进行演示。

本章涉及的关键概念包括：
- **磁盘 I/O**：通过 ATA PIO 模式直接控制磁盘的读写。
- **文件分配表（FAT）**：用链式结构管理磁盘上的数据块（簇）分配。
- **目录条目**：记录文件名、大小、属性和起始簇号等元数据。
- **文件操作**：实现 format、create、read、write、delete 和 list 等基本文件操作。

实验目标：
	1. 实现 ATA PIO 磁盘驱动程序，理解 LBA 寻址与 16 位端口 I/O
	2. 构建简化 FAT16 文件系统，理解 FAT 链、目录条目、超级块等核心数据结构
	3. 实现文件的基本操作（创建、写入、读取、删除）并分析其执行流程
	4. 扩展文件系统功能（追加写入、碎片率统计、文件重命名）
	5. 实现交互式 Shell 与文件系统一致性检查（fsck）

> 实验环境：**Ubuntu22.04，x86-64架构**

# Section2 实验步骤与实验结果

> 实验代码均附于压缩包内
## Assignment 1 磁盘驱动与FAT16基础

### 1.1 复现并理解磁盘驱动

#### 1.1.1 编译运行

在 `src/1/build/` 目录下依次执行以下命令：

```bash
make image      # 创建 10MB 磁盘镜像 hd.img
make build      # 编译 MBR、bootloader、kernel，写入镜像
make run        # 启动 QEMU 运行操作系统
```

运行后可以看到 FAT16 文件系统演示的 12 步流程：格式化 → 创建文件 → 写入 → 列出目录 → 读取 → 删除 → 覆盖写 → 显示信息：
![[Pasted image 20260629161855.png|600]]
#### 1.1.2 ATA PIO 磁盘读写流程分析
磁盘驱动由 `DiskDriver` 类实现，定义在 `disk.h` 中，实现在 `disk.cpp` 中。它通过 ATA PIO（Programmed Input/Output，程序控制输入输出）模式直接与磁盘控制器通信。ATA PIO 模式下的所有数据传输都由 CPU 执行 I/O 指令完成
下面是端口定义等
```cpp file:disk.h
// ATA PIO 端口定义
#define ATA_DATA       0x1F0
#define ATA_ERROR      0x1F1
#define ATA_SECT_CNT   0x1F2
#define ATA_LBA_LOW    0x1F3
#define ATA_LBA_MID    0x1F4
#define ATA_LBA_HIGH   0x1F5
#define ATA_DRIVE_HEAD 0x1F6
#define ATA_STATUS     0x1F7
#define ATA_COMMAND    0x1F7

// ATA 命令
#define ATA_CMD_READ   0x20
#define ATA_CMD_WRITE  0x30

// ATA 状态位
#define ATA_STATUS_BSY  0x80
#define ATA_STATUS_DRDY 0x40
#define ATA_STATUS_DRQ  0x08
#define ATA_STATUS_ERR  0x01

```

（1）`waitReady()` — 轮询状态寄存器等待磁盘就绪

```cpp file:disk.cpp
void DiskDriver::waitReady()
{
    uint8 status;
    do
    {
        asm_in_port(ATA_STATUS, &status);
    } while (status & ATA_STATUS_BSY);
}
```

实现逻辑：
- 通过 `asm_in_port` 函数从状态端口 0x1F7 读取状态字节。
- 循环检查 `BSY` 位（Bit 7，值 0x80）：只要该位为 1 ，就代表磁盘控制器正忙，继续循环等待
- 当 `BSY` 位清零后，磁盘控制器空闲，可以接受下一条命令

（2）`selectSector()` — 设置 LBA 地址和扇区数

```cpp
void DiskDriver::selectSector(uint32 lba, uint8 count)
{
    waitReady();
    asm_out_port(ATA_SECT_CNT, count);// 扇区数 → 0x1F2
    asm_out_port(ATA_LBA_LOW, (uint8)(lba & 0xFF));// LBA[7:0] → 0x1F3
    asm_out_port(ATA_LBA_MID, (uint8)((lba >> 8) & 0xFF));// LBA[15:8] → 0x1F4
    asm_out_port(ATA_LBA_HIGH, (uint8)((lba >> 16) & 0xFF));// LBA[23:16] → 0x1F5
    asm_out_port(ATA_DRIVE_HEAD, (uint8)(0xE0 | ((lba >> 24) & 0x0F))); // 0x1F6
}
```

实现逻辑：
- 先调用 `waitReady()` 确保磁盘空闲。
- 向 0x1F2 写入 `count`，设置本次操作要传输的扇区数量
- 向 0x1F3~0x1F5 依次写入 LBA 地址的低、中、高字节
- 向 0x1F6 写入 `0xE0 | (LBA[27:24])`：
	- Bit 7 必须为 1，说明是LBA 模式
	- Bit 6 为 0（主盘）
	- Bit 4 为 0（主盘选择）
	- Bits 3-0 为 LBA 地址的最高 4 位

（3）`readSectors()` — 读取扇区

```cpp file:disk.h
bool DiskDriver::readSectors(uint32 lba, uint32 count, void *buffer)
{
    uint16 *buf = (uint16 *)buffer;
    for (uint32 s = 0; s < count; ++s)
    {
        selectSector(lba + s, 1);           // 步骤1: 选择扇区
        asm_out_port(ATA_COMMAND, ATA_CMD_READ); // 步骤2: 发送 READ 命令 (0x20)

        uint8 status;
        do {
            asm_in_port(ATA_STATUS, &status);
        } while (!(status & ATA_STATUS_DRQ)); // 步骤3: 等待 DRQ 置位

        for (int i = 0; i < 256; ++i)         // 步骤4: 读取一个扇区
        {
            asm_in_port_word(ATA_DATA, &buf[s * 256 + i]);
        }
    }
    return true;
}
```

完整读取流程：
1. 循环处理每个扇区：每次读取一个扇区
2. 选择扇区：调用 `selectSector(lba + s, 1)`，每次读取 1 个扇区
3. 发送命令：向命令寄存器 0x1F7 写入 READ 命令 `0x20`。磁盘控制器开始从盘片上读取数据到内部缓冲区
4. 等待数据就绪：循环读取状态寄存器 0x1F7，直到 `DRQ` 位（Bit 3，值 0x08）置位。DRQ 表示数据请求就绪——磁盘控制器已将数据准备好，等待 CPU 通过数据端口取走
5. 读取数据：通过 `asm_in_port_word` 从数据寄存器 0x1F0 读取 256 次，每次读取 2 字节，存入buffer

（4）`writeSectors()` — 写入流程与读取流程的异同

```cpp file:disk.h
bool DiskDriver::writeSectors(uint32 lba, uint32 count, const void *buffer)
{
    const uint16 *buf = (const uint16 *)buffer;
    for (uint32 s = 0; s < count; ++s)
    {
        selectSector(lba + s, 1);
        asm_out_port(ATA_COMMAND, ATA_CMD_WRITE);    // 发送 WRITE 命令 (0x30)

        uint8 status;
        do {
            asm_in_port(ATA_STATUS, &status);
        } while (!(status & ATA_STATUS_DRQ));         // 等待 DRQ 置位

        for (int i = 0; i < 256; ++i)                 // 写入一个扇区
        {
            asm_out_port_word(ATA_DATA, buf[s * 256 + i]);
        }
    }
    return true;
}
```

相同：
- 都需要调用 `selectSector()` 
- 都需要等待 `DRQ` 
- 都循环 256 次来不断传输 2 字节

不同：
- 命令：读取发送 `ATA_CMD_READ`，写入发送 `ATA_CMD_WRITE`
- 数据方向：读取使用 `asm_in_port_word`，写入使用 `asm_out_port_word`
- 缓冲区类型：读取使用 `uint16 *buf`（可写），写入使用 `const uint16 *buf`（只读）。

#### 1.1.3 为什么数据寄存器使用 16 位 I/O
1. 速度提升：每次 16 位 I/O 指令传输 2 字节，只需 256 次操作即可传输一个扇区，可以提升传输效率，减少端口访问开销
2. **ATA 数据寄存器**：ATA 标准规定数据寄存器 0x1F0 是 16 位宽的数据端口，一次要传输完整的 16 位
### 1.2 分析 FAT16 文件系统布局

#### 1.2.1 磁盘完整布局图
结合 `fat16.h` 中的定义：
```cpp file:fat16.h
// FAT16 布局常量
#define FAT_SECTORS       32      // FAT 表占用的扇区数
#define ROOT_DIR_SECTORS  32      // 根目录区占用的扇区数
#define MAX_ROOT_ENTRIES  512     // 最大根目录条目数 (32*16)
#define ENTRIES_PER_SECTOR 16     // 每扇区目录条目数 (512/32)
#define FAT_ENTRIES       8192    // FAT 表条目总数 (32*256)
#define DATA_START_OFFSET 65      // 数据区相对 FS_START_SECTOR 的偏移
#define SECTOR_SIZE       512     // 每扇区字节数

#define FAT16_FREE        0x0000
#define FAT16_EOF         0xFFF8
#define FAT16_BAD         0xFFF7

#define MAX_FILENAME      11      // 8.3 格式文件名长度

// 文件属性
#define ATTR_NONE         0x00
#define ATTR_READONLY     0x01
#define ATTR_HIDDEN       0x02
#define ATTR_SYSTEM       0x04
#define ATTR_DIRECTORY    0x10
#define ATTR_ARCHIVE      0x20
#define ATTR_DELETED      0xE5    // 已删除标记（首字节）
```
本实验中磁盘镜像为 10MB（20160 扇区），文件系统从扇区 500 开始，布局如下：

| 扇区        | 内容                   | 大小                |
| --------- | -------------------- | ----------------- |
| 0         | MBR (主引导记录)          | 1 扇区 (512B)       |
| 1~5       | Bootloader + 页表      | 5 扇区 (2560B)      |
| 6~150     | Kernel 内核代码          | 145 扇区 (~72KB)    |
| 151~499   | 未使用 (保留)             | 349 扇区            |
| 500       | SuperBlock (超级块/BPB) | 1 扇区 (512B)       |
| 501~532   | FAT 表                | 32 扇区 (16KB)      |
| 533~564   | 根目录区                 | 32 扇区 (16KB)      |
| 565~20659 | 数据区                  | 20095 扇区 (~9.8MB) |

- `FS_START_SECTOR = 500`：文件系统起始扇区，避开系统区域。
- `FAT_SECTORS = 32`：FAT 表占 32 个扇区。
- `ROOT_DIR_SECTORS = 32`：根目录区占 32 个扇区。
- `DATA_START_OFFSET = 65`：数据区相对 FS_START_SECTOR 的偏移量（1 + 32 + 32 = 65）。
- 数据区从扇区 `500 + 65 = 565` 开始。

#### 1.2.2 FAT 表条目分析
- 每个条目大小：2 字节（16 位）
- 条目总数：`FAT_ENTRIES = 8192`，计算方式：32 扇区 × (512 字节/扇区 ÷ 2 字节/条目) = 32 × 256 = 8192
- 最多管理的数据簇数：8192 - 2 = 8190 个（簇 0 和簇 1 为保留簇，分别标记为 `0xFFF8` 和 `0xFFFF`）。每个簇 = 1 扇区 = 512 字节，所以数据区总容量为 8190 × 512B ≈ 4MB。
#### 1.2.3 根目录区容量

- 最多存放文件数：`MAX_ROOT_ENTRIES = 512`，计算方式：32 扇区 × (512 字节/扇区 ÷ 32 字节/条目) = 32 × 16 = 512
- 每个目录条目大小为32 字节，`struct DirEntry`：

```
偏移  大小  字段
0     8     filename[8]    文件名（8.3 格式，空格填充）
8     3     extension[3]   扩展名（空格填充）
11    1     attributes     文件属性
12    14    reserved[14]   保留字段
26    2     firstCluster   起始簇号
28    4     fileSize       文件大小（字节）
```
#### 1.2.4 FAT 链分析
- `FAT[5] = 8`：簇 5 的下一个簇是簇 8
- `FAT[8] = 12`：簇 8 的下一个簇是簇 12
- `FAT[12] = 0xFFF8`~`0xFFFF`（EOF），表示文件结束
#### 1.2.5 `clusterToSector()` 

```cpp
uint32 FAT16::clusterToSector(uint16 cluster)
{
    return FS_START_SECTOR + DATA_START_OFFSET + (cluster - 2);
}
```
- `FS_START_SECTOR = 500`是文件系统的起始扇区号，`DATA_START_OFFSET = 65`代表从文件系统起始到数据区起始的偏移， `(cluster - 2)`簇号到数据区内部扇区偏移的转换
- 因此簇号到扇区号的转换公式为：
$$
\text{sector} = \text{FS\_START\_SECTOR} + \text{DATA\_START\_OFFSET} + (\text{cluster} - 2)
$$

- 为什么簇号从 2 开始：簇 0 和簇 1 是保留簇，不用于数据存储。簇 0 通常标记为 `0xFFF8`（媒体类型），簇 1 标记为 `0xFFFF`（表示 EOF/保留）
## Assignment 2 文件操作实现分析

### 2.1 文件创建与写入

#### 2.1.1 `createFile("hello.txt")` 执行流程
- `toFAT16Name`把文件名转换为 8.3 格式
	```cpp
	void FAT16::toFAT16Name(const char *name, char *fat16Name)
	{
	    // 初始化为空格
	    for (int i = 0; i < 11; ++i) fat16Name[i] = ' ';
	    // 复制文件名部分 (最多8字符)，转大写
	    int i = 0, j = 0;
	    while (name[i] && name[i] != '.' && j < 8){
	        char c = name[i];
	        if (c >= 'a' && c <= 'z') c = c - 'a' + 'A';
	        fat16Name[j] = c;
	        ++i; ++j;
	    }
	
	    // 跳过文件名中超出8字符的部分
	    while (name[i] && name[i] != '.') ++i;
	    // 复制扩展名部分 (最多3字符)，转大写
	    if (name[i] == '.'){
	        ++i;
	        j = 8;
	        while (name[i] && j < 11){
	            char c = name[i];
	            if (c >= 'a' && c <= 'z') c = c - 'a' + 'A';
	            fat16Name[j] = c;
	            ++i; ++j;
	        }
	    }
	}
	```
	1. 先初始化输出为空格
	2. 将文件名复制上去（大写，最多8个字符）
	3. 随后跳过超出8个字符的部分
	4. 复制扩展名，转大写，放在输出字符串的末尾
	检查文件是否已存在
	```cpp
	if (findEntry(name) >= 0){
	    printf("Error: file '%s' already exists\n", name);
	    return false;
	}
	```
	`findEntry()` 遍历根目录区所有条目，将 8.3 格式化的目标文件名与每个有效条目逐一比较（跳过已删除条目 `0xE5` 和空条目 `0x00`）。若匹配返回条目索引，否则返回 -1
- `findFreeEntry()` — 查找空闲目录条目
	```cpp
	int FAT16::findFreeEntry(){
	    DirEntry entry;
	    for (int i = 0; i < MAX_ROOT_ENTRIES; ++i){
	        readDirEntry(i, &entry);
	        if ((uint8)entry.filename[0] == 0x00 ||        // 从未使用
	            (uint8)entry.filename[0] == ATTR_DELETED)  // 已删除可复用
	            return i;
	    }
	    return -1;
	}
	```
	遍历根目录 512 个条目，返回第一个空闲条目（首字节为 `0x00` 表示从未使用，或为 `0xE5` 表示已删除可复用）
- 初始化目录条目
	```cpp
	DirEntry entry;
	memset(&entry, 0, sizeof(DirEntry));         // 清零
	char fat16Name[11];
	toFAT16Name(name, fat16Name);
	memcpy(fat16Name, entry.filename, 8);        // 写入文件名
	memcpy(fat16Name + 8, entry.extension, 3);   // 写入扩展名
	entry.attributes = ATTR_ARCHIVE;             // 属性 = 存档
	entry.firstCluster = 0;                      // 空文件，无簇
	entry.fileSize = 0;                          // 大小为 0
	writeDirEntry(idx, &entry);                  // 写入磁盘
	```

#### 2.1.2 `writeFile("hello.txt", data, size)` 执行流程
- 确定目标条目
	```cpp
	bool FAT16::writeFile(const char *name, const char *data, uint32 size){
			...
			int idx = findEntry(name);
			if (idx < 0){
				// 文件不存在，先创建（与 createFile 相同逻辑）
				idx = findFreeEntry();
				...
			}
			else{
				// 文件已存在，读取现有条目，释放旧簇链
				readDirEntry(idx, &entry);
				if (entry.firstCluster >= 2)freeClusterChain(entry.firstCluster);
			}
			...
		}
	```
- 计算所需簇数
	```cpp
	uint32 clustersNeeded = (size + SECTOR_SIZE - 1) / SECTOR_SIZE;
	```
- `allocateCluster()` 查找空闲簇
	```cpp
	uint16 FAT16::allocateCluster(){
	    for (int i = 2; i < FAT_ENTRIES; ++i){   // 从簇 2 开始
	        if (fatTable[i] == FAT16_FREE){       // 找到空闲簇
	            fatTable[i] = FAT16_EOF;         // 标记为 EOF
	            return (uint16)i;
	        }
	    }
	    return 0; // 磁盘满
	}
	```
	采用**首次适配（First Fit）** 策略进行查找，扫描内存中的 FAT 缓存表。找到空闲簇后立即标记为 EOF，防止后续分配冲突
- FAT 链构建过程（簇2：A，簇3：B）：
	```
	循环迭代 i=0:
	  allocateCluster() → 返回簇 2
	  firstCluster = 2, prevCluster = 2
	  将前 512 字节写入扇区 clusterToSector(2)
	
	循环迭代 i=1:
	  allocateCluster() → 返回簇 3
	  fatTable[prevCluster] = fatTable[2] = 3    // 簇 2 → 簇 3
	  将后 88 字节写入扇区 clusterToSector(3)
	  prevCluster = 3
	
	FAT 链: 簇 2 → 簇 3 → EOF
	```
- 写入数据到磁盘
	```cpp
	uint8 sectorBuf[SECTOR_SIZE];
	memset(sectorBuf, 0, SECTOR_SIZE);                       // 清零缓冲区
	uint32 copySize = size - i * SECTOR_SIZE;
	if (copySize > SECTOR_SIZE) copySize = SECTOR_SIZE;      // 截断到 512
	memcpy((void *)(data + i * SECTOR_SIZE), sectorBuf, copySize); // 复制数据
	disk->writeSectors(clusterToSector(cluster), 1, sectorBuf);   // 写入磁盘
	```
	每次循环：清零扇区缓冲区 → 复制对应数据片段 → 通过 `disk->writeSectors()` 写入磁盘
- 写完数据后更新目录条目并同步 FAT
	```cpp
	entry.firstCluster = firstCluster;
	entry.fileSize = size;
	writeDirEntry(idx, &entry);   // 更新目录条目
	syncFAT();                    // 将内存中的 FAT 表写回磁盘
	```
	为什么 调用`syncFAT()` ：
		FAT 表在内存中维护了一份缓存（`uint16 fatTable[8192]`），所有分配（`allocateCluster`）和释放（`freeClusterChain`）操作只修改这份内存缓存。如果不调用 `syncFAT()` 将缓存写回磁盘扇区 501~532，断电或重启后 FAT 表将与实际磁盘数据不一致，导致文件数据丢失或文件系统损坏

#### 2.1.3 覆盖写时旧簇链的释放

当对已存在文件调用 `writeFile()` 时：
```cpp
else{
    readDirEntry(idx, &entry);
    if (entry.firstCluster >= 2){
        freeClusterChain(entry.firstCluster);   // ← 释放旧数据
    }
}
```

`freeClusterChain()` 的实现：
```cpp
void FAT16::freeClusterChain(uint16 startCluster){
    uint16 current = startCluster;
    while (current >= 2 && current < FAT16_BAD){
        uint16 next = fatTable[current];    // 保存下一个簇号
        fatTable[current] = FAT16_FREE;     // 标记为 0x0000（空闲）
        current = next;                     // 继续下一个簇
    }
}
```

该函数沿着 FAT 链遍历：读取当前簇的 FAT 条目（它保存了下一个簇号），将当前簇标记为 `FAT16_FREE`（0x0000），然后移动到下一个簇。直到 `current < 2` 或 `current >= 0xFFF7`（遇到 EOF 标记 `0xFFF8~0xFFFF`）。释放完成后，这些簇可被后续的 `allocateCluster()` 重新分配
### 2.2 文件读取与删除

#### 2.2.1 `readFile("hello.txt", buffer, maxSize)` 执行流程
- 查找文件的簇号和大小
	```cpp
	int idx = findEntry(name);         // 在根目录查找文件条目
	DirEntry entry;
	readDirEntry(idx, &entry);         // 读取完整的 32 字节目录条目
	```
	
	从 `entry.firstCluster` 获取起始簇号，`entry.fileSize` 获取文件大小
	```cpp
	uint32 readSize = entry.fileSize;
	if (readSize > maxSize) readSize = maxSize;   // 不超过用户缓冲区
	```

- 沿 FAT 链逐簇读取
	```cpp
	uint16 cluster = entry.firstCluster;
	uint32 bytesRead = 0;
	uint8 sectorBuf[SECTOR_SIZE];
	
	while (cluster >= 2 && cluster < FAT16_BAD && bytesRead < readSize)
	{
	    disk->readSectors(clusterToSector(cluster), 1, sectorBuf);  // 读扇区
	
	    uint32 copySize = readSize - bytesRead;
	    if (copySize > SECTOR_SIZE) copySize = SECTOR_SIZE;
	
	    memcpy(sectorBuf, buffer + bytesRead, copySize);  // 复制到用户缓冲区
	    bytesRead += copySize;
	
	    cluster = fatTable[cluster];  // 获取 FAT 链中的下一个簇号
	}
	```
	每次迭代：根据当前簇号计算扇区号 → 将扇区读入临时缓冲区 → 计算本次拷贝量（不超过扇区大小和剩余需要量）→ 拷贝到用户缓冲区 → 从 FAT 表获取下一个簇号，移动链指针
	
- 循环终止条件（满足任一即停止）：
	1. `cluster < 2` 或 `cluster >= 0xFFF7`：FAT 链已到达末尾（EOF）或遇到无效值
	2. `bytesRead >= readSize`：已读取足够的数据
	
#### 2.2.2 `deleteFile("data.bin")` 执行流程

```cpp
bool FAT16::deleteFile(const char *name)
{
    int idx = findEntry(name);
    DirEntry entry;
    readDirEntry(idx, &entry);

    // 步骤1: 释放簇链
    if (entry.firstCluster >= 2)
    {
        freeClusterChain(entry.firstCluster);
        syncFAT();   // 立即同步 FAT 到磁盘
    }

    // 步骤2: 标记目录条目为已删除
    entry.filename[0] = (char)ATTR_DELETED;  // 首字节设为 0xE5
    writeDirEntry(idx, &entry);

    return true;
}
```

- `freeClusterChain()` ：该函数`entry.firstCluster` 开始沿着 FAT 链遍历，读取当前簇的 FAT 条目（它保存了下一个簇号），将当前簇标记为 `FAT16_FREE`（0x0000），保存 `next = fatTable[current]`，将 `fatTable[current]` 设为 `FAT16_FREE`（0x0000），`current = next`，循环直到遇到 EOF 标记

- 目录条目删除标记 0xE5：
	- `entry.filename[0] = (char)ATTR_DELETED;` 将目录条目的第一个字节改为0xE5`

- 删除后文件数据是否真的被擦除：
	并没有。是因为 `deleteFile()` 仅仅：
	1. 将 FAT 表中的簇标记为 `FAT16_FREE`。
	2. 将目录条目的首字节改为 `0xE5`。
	所以文件的实际数据仍然保留在磁盘的数据扇区中，直到这些扇区被新文件覆盖写入才算是真的”消失“
### 2.3 自定义文件操作测试
1. 创建至少 5 个文件并写入不同内容
	```cpp
	// 创建 5 个文件
	fs->createFile("test1.txt");
	fs->createFile("test2.txt");
	fs->createFile("test3.txt");
	fs->createFile("notes.dat");
	fs->createFile("doc.txt");
	
	// 写入不同内容
	fs->writeFile("test1.txt", "Content of file 1: Hello World!", 30);
	fs->writeFile("test2.txt", "File 2 data: 1234567890", 22);
	fs->writeFile("test3.txt", "The third file contains this text.", 35);
	fs->writeFile("notes.dat", "Binary note: \x01\x02\x03\x04", 18);
	fs->writeFile("doc.txt",   "Documentation: FAT16 filesystem lab.", 36);
	```
2. 列出所有文件，验证文件名和大小
	```cpp
	printf("[Test 2] Listing all files:\n");
	fs->listFiles();
	// 预期输出 5 个文件及各自大小
	```
3. 读取每个文件并打印内容，验证数据一致性
	```cpp
	char buffer[256];
	const char *files[] = {"test1.txt", "test2.txt", "test3.txt", "notes.dat", "doc.txt"};
	for (int i = 0; i < 5; i++)
	{
	    memset(buffer, 0, sizeof(buffer));
	    int n = fs->readFile(files[i], buffer, sizeof(buffer) - 1);
	    if (n > 0)
	    {
	        buffer[n] = '\0';
	        printf("  %s (%d bytes): %s\n", files[i], n, buffer);
	    }
	}
	```
	预期每种文件读出的内容与写入时一致，字节数匹配
4. 删除部分文件后重建同名文件
	```cpp
	// 删除 test2.txt 和 notes.dat
	fs->deleteFile("test2.txt");
	fs->deleteFile("notes.dat");
	printf("[After delete] ");
	fs->listFiles();   // 应只剩 3 个文件
	
	// 重建 test2.txt（验证已删除条目被复用）
	fs->createFile("test2.txt");
	fs->writeFile("test2.txt", "REBORN test2", 13);
	printf("[After recreate] ");
	fs->listFiles();   // test2.txt 重新出现，大小变为 13
	```
	验证 `findFreeEntry()` 正确复用了首字节为 `0xE5` 的已删除条目空间。
- 运行结果如下，可见成功地输出了先前设定的文件名和大小，以及文件内容；并且在删除文件2后重新创建，也是成功重建
	![[Pasted image 20260629203840.png|600]]

---

## Assignment 3 文件系统功能扩展

### 3.1 文件追加写入 `appendFile()`
函数签名：
```cpp
bool FAT16::appendFile(const char *name, const char *data, uint32 size);
```

- 实现：
	- 情况 1：文件不存在— 行为与 `writeFile()` 完全相同，直接调用 `writeFile(name, data, size)` 创建并写入新文件
	
	- 情况 2：文件已存在— 在文件末尾追加数据：
		```
		1. 查找文件目录条目，获取 firstCluster 和 fileSize
		2. 沿 FAT 链遍历到最后一个簇
		3. 计算最后一个簇的已用空间 = fileSize % SECTOR_SIZE
		4. 计算最后一个簇的剩余空间 = SECTOR_SIZE - 已用空间
		5. 分步处理：
		   a. 如果剩余空间 > 0：先在最后一个簇的剩余空间中填入部分数据
		   b. 如果还有数据未写完：分配新簇，链接到 FAT 链末尾，继续写入
		6. 更新 fileSize = 原 fileSize + size
		7. 写回目录条目，调用 syncFAT()
		```

- 代码实现：
	```cpp
	bool FAT16::appendFile(const char *name, const char *data, uint32 size){
	    if (!mounted){
		    printf("Error: filesystem not mounted\n");
		    return false;
		}
	    // Case 1: file does not exist → same as writeFile
	    int idx = findEntry(name);
	    if (idx < 0) return writeFile(name, data, size);
	
	    // Case 2: file exists → append
	    DirEntry entry;
	    readDirEntry(idx, &entry);
	    uint32 oldSize = entry.fileSize;
	
	    if (size == 0) return true;  // nothing to append
	
	    // Find the last cluster in the FAT chain
	    uint16 cluster = entry.firstCluster;
	    uint16 prevCluster = 0;
	    while (cluster >= 2 && cluster < FAT16_BAD &&
	           fatTable[cluster] >= 2 && fatTable[cluster] < FAT16_BAD){
	        // Not yet at the last cluster (next is not EOF)
	        prevCluster = cluster;
	        cluster = fatTable[cluster];
	    }
	    // Now 'cluster' is the last cluster, or firstCluster if only one cluster
	
	    uint32 bytesWritten = 0;
	    uint32 remainingInLast = SECTOR_SIZE - (oldSize % SECTOR_SIZE);
	    if (remainingInLast > 0 && remainingInLast < SECTOR_SIZE){
	        // Fill the remaining space in the last cluster
	        uint8 sectorBuf[SECTOR_SIZE];
	        disk->readSectors(clusterToSector(cluster), 1, sectorBuf);
	        uint32 copySize = (size < remainingInLast) ? size : remainingInLast;
	        memcpy((void *)(data), sectorBuf + (oldSize % SECTOR_SIZE), copySize);
	        disk->writeSectors(clusterToSector(cluster), 1, sectorBuf);
	        bytesWritten = copySize;
	    }
	
	    // Allocate new clusters for remaining data
	    while (bytesWritten < size){
	        uint16 newCluster = allocateCluster();
	        if (newCluster == 0) { printf("Error: disk full\n"); break; }
	
	        // Link: last cluster → new cluster
	        if (cluster >= 2) fatTable[cluster] = newCluster;
	        else entry.firstCluster = newCluster;
	        cluster = newCluster;
	
	        // Write data to this new cluster
	        uint8 sectorBuf[SECTOR_SIZE];
	        memset(sectorBuf, 0, SECTOR_SIZE);
	        uint32 copySize = size - bytesWritten;
	        if (copySize > SECTOR_SIZE) copySize = SECTOR_SIZE;
	        memcpy((void *)(data + bytesWritten), sectorBuf, copySize);
	        disk->writeSectors(clusterToSector(cluster), 1, sectorBuf);
	        bytesWritten += copySize;
	    }
	
	    // Update directory entry and sync
	    entry.fileSize = oldSize + bytesWritten;
	    writeDirEntry(idx, &entry);
	    syncFAT();
	    return true;
	}
	```
	边界条件：
	- 追加到空文件（`fileSize = 0`，`firstCluster = 0`）：需处理 `cluster = 0` 的特殊情况
	- 最后一个簇恰好已满（`remainingInLast = 0`）：直接分配新簇
	- 跨簇边界追加大量数据时需要分配多个新簇

- 测试：
	```cpp
	// 追加写入测试
	fs->writeFile("log.txt", "Line 1\n", 7);         // 创建并写入第一行
	fs->appendFile("log.txt", "Line 2\n", 7);        // 追加第二行
	fs->appendFile("log.txt", "Line 3\n", 7);        // 追加第三行
	
	// 读取验证
	char buf[256];
	n = fs->readFile("log.txt", buf, sizeof(buf) - 1);
	buf[n] = '\0';
	printf("log.txt content:\n%s\n", buf);
	```
- 运行结果如下，可以看到成功向文件中追加写入：
	![[Pasted image 20260629205918.png|400]]

### 3.2 磁盘空间统计

#### 3.2.1 `getFileClusterCount()`

函数签名：
```cpp
int FAT16::getFileClusterCount(const char *name);
```

- 实现思路：
	```
	1. findEntry(name) 查找文件目录条目
	2. 从 entry.firstCluster 获取起始簇号
	3. 沿 FAT 链遍历，计数每个非 EOF 簇
	4. 返回簇数
	```
- 代码实现：
	```cpp
	int FAT16::getFileClusterCount(const char *name){
	    if (!mounted) return -1;
	
	    int idx = findEntry(name);
	    if (idx < 0) return -1;
	
	    DirEntry entry;
	    readDirEntry(idx, &entry);
	
	    if (entry.fileSize == 0) return 0;
	
	    int count = 0;
	    uint16 cluster = entry.firstCluster;
	    while (cluster >= 2 && cluster < FAT16_BAD){
	        count++;
	        cluster = fatTable[cluster];  // walk the chain
	    }
	    return count;
	}
	```

#### 3.2.2 `getFragmentation()`
函数签名：
```cpp
float FAT16::getFragmentation();
```
- 碎片率 = 不连续的簇分配次数 / 总簇分配次数
- 实现逻辑：
	```
	1. 遍历根目录所有有效文件条目
	2. 对每个文件沿 FAT 链遍历：
	   - 总分配次数++（每经过一个簇）
	   - 若当前簇的后继簇 != 当前簇 + 1，则是不连续的，不连续计数++
	1. 返回 (float)不连续次数 / 总分配次数
	```
- 代码实现：
	```cpp
	float FAT16::getFragmentation(){
	    if (!mounted) return 0.0f;
	    int totalTransitions = 0;
	    int nonContiguous = 0;
	
	    DirEntry entry;
	    for (int i = 0; i < MAX_ROOT_ENTRIES; ++i){
	        readDirEntry(i, &entry);
	        if ((uint8)entry.filename[0] == 0x00) break;
	        if ((uint8)entry.filename[0] == ATTR_DELETED) continue;
	        if (entry.firstCluster < 2) continue;
	
	        uint16 cluster = entry.firstCluster;
	        while (cluster >= 2 && cluster < FAT16_BAD){
	            uint16 next = fatTable[cluster];
	            if (next >= 2 && next < FAT16_BAD){
	                totalTransitions++;
	                if (next != cluster + 1)nonContiguous++;
	            }
	            cluster = next;
	        }
	    }
	
	    if (totalTransitions == 0) return 0.0f;
	    return (float)nonContiguous / (float)totalTransitions;
	}
	```
- 测试：
	```cpp
	// 初始状态
	int frag = (int)(fs->getFragmentation() * 100);
	printf("Fragmentation: %d%%", frag);
	// 创建多个文件
	fs->createFile("a.txt"); fs->writeFile("a.txt", data, 1000);  // 2簇
	fs->createFile("b.txt"); fs->writeFile("b.txt", data, 1000);  // 2簇
	fs->createFile("c.txt"); fs->writeFile("c.txt", data, 1000);  // 2簇
	frag = (int)(fs->getFragmentation() * 100);
	printf("After create: %d%%", frag);
	// 删除 b.txt 后创建需要更多簇的文件
	fs->deleteFile("b.txt");
	fs->createFile("d.txt"); fs->writeFile("d.txt", data, 2000);  // 4簇
	printf("After delete+recreate: %.2f\n", fs->getFragmentation()); // 应增加
	frag = (int)(fs->getFragmentation() * 100);
	printf("After delete+recreate: %d%%", frag); // 应增加

	```
- 运行结果如下，可以看到在重建文件之后的碎片率确实增加了：
	![[Pasted image 20260629215059.png|400]]
### 3.3 文件重命名 `renameFile()`
函数签名：
```cpp
bool FAT16::renameFile(const char *oldName, const char *newName);
```

- 实现逻辑：
	```
	1. 验证旧文件存在：findEntry(oldName)
	2. 验证新文件名不冲突：findEntry(newName) == -1
	3. 将新文件名转换为 8.3 格式
	4. 读取旧文件的目录条目
	5. 仅修改 filename[8] 和 extension[3] 字段
	6. 写回目录条目（不修改 firstCluster、fileSize、attributes）
	7. 不需要修改 FAT 表，也不需要 syncFAT()
	```
- 代码实现：
	```cpp
	bool FAT16::renameFile(const char *oldName, const char *newName){
	    if (!mounted) { printf("Error: filesystem not mounted\n"); return false; }
	
	    // Verify old file exists
	    int oldIdx = findEntry(oldName);
	    if (oldIdx < 0){
	        printf("Error: file '%s' not found\n", oldName);
	        return false;
	    }
	
	    // Verify new name does not conflict
	    if (findEntry(newName) >= 0){
	        printf("Error: file '%s' already exists\n", newName);
	        return false;
	    }
	    // Read old entry, modify only the name fields
	    DirEntry entry;
	    readDirEntry(oldIdx, &entry);
	
	    char fat16Name[11];
	    toFAT16Name(newName, fat16Name);
	    memcpy(fat16Name, entry.filename, 8);// copy new 8-char filename
	    memcpy(fat16Name + 8, entry.extension, 3);// copy new 3-char extension
	    writeDirEntry(oldIdx, &entry);  // write back (same index)
	    return true;
	}
	```

- 设计要点：
	1. 仅修改目录条目中的名称字段：`filename[8]` 和 `extension[3]`，不触碰 `firstCluster`、`fileSize`、`attributes`、`reserved[14]` 等其他字段
	2. 不修改 FAT 表：重命名只改变文件在目录中的名称表示，数据块和 FAT 链不变
	3. 不移动数据

- 边界条件检查：
	- 旧文件不存在 → 报错返回 false
	- 新文件名已被占用 → 报错返回 false（避免数据丢失）
	- 新文件名转换后的 8.3 格式完全相同 → 可视为有效或报错

- 测试：
	```cpp
	fs->createFile("oldname.txt");
	fs->writeFile("oldname.txt", "test content", 12);
	
	printf("Before rename:\n");
	fs->listFiles();   // 显示 oldname.txt
	
	fs->renameFile("oldname.txt", "newname.txt");
	
	printf("After rename:\n");
	fs->listFiles();   // 显示 newname.txt，oldname.txt 消失
	
	// 验证数据完整性
	char content[64];
	int n = fs->readFile("newname.txt", content, sizeof(content) - 1);
	content[n] = '\0';
	printf("Content: %s\n", content);  // 应输出 "test content"
	```
- 运行结果如下，可以看到刚刚创建的 `oldname.txt`在改名之后正常列出
	![[Pasted image 20260629221625.png|600]]

## Assignment 4 选做

### 4.1 交互式 Shell

#### 实现思路

将原来的自动演示 Shell 改为轮询键盘的交互式 Shell。不依赖键盘中断（中断驱动在 QEMU 中不稳定易崩溃），改用 CPU 轮询 8042 PS/2 键盘控制器的状态端口 0x64 和数据端口 0x60 来获取按键。

#### 涉及的修改文件

| 文件 | 改动 |
|------|------|
| `include/shell.h` | 新增 `InteractiveShell` 类声明（`getChar()`、`parseAndExecute()`、9 个命令处理函数） |
| `src/kernel/shell.cpp` | 完整实现交互式 Shell，含扫描码表、轮询输入、命令解析 |
| `src/kernel/stdio.cpp` | `print(const char *str)` 函数新增 `case '\b'` 退格处理 |
| `src/kernel/setup.cpp` | 子进程中改用 `InteractiveShell`，移除键盘中断注册 |
| `include/interrupt.h` | 移除之前添加的 `enableKeyboardInterrupt`、`setKeyboardInterrupt` 声明 |
| `src/kernel/interrupt.cpp` | 移除键盘中断处理函数及扫描码表 |
| `src/utils/asm_utils.asm` | 移除 `asm_keyboard_interrupt_handler` |

#### 核心实现

1. 扫描码表（shell.cpp 文件顶部）

```cpp
static const char scanCodeTable[] = {
    0,   0,   '1','2','3','4','5','6','7','8','9','0','-','=',  8,   // 0x00-0x0E (0x0E=Backspace)
    0,   'q','w','e','r','t','y','u','i','o','p','[',']','\n', 0,   // 0x0F-0x1D (0x1C=Enter)
    'a','s','d','f','g','h','j','k','l',';', 39, '`',  0, 92,       // 0x1E-0x2B
    'z','x','c','v','b','n','m',',','.','/',  0,  0,   0,  ' ',     // 0x2C-0x39 (0x39=Space)
};
```

表覆盖了扫描码 0x02~0x39，包含字母（a-z）、数字（0-9）、常用符号（空格、回车、退格等）。不可打印键映射为 0（忽略）。

2. 轮询函数 `getChar()`

```cpp
char InteractiveShell::getChar()
{
    while (true)
    {
        uint8 status;
        asm_in_port(0x64, &status);         // 读 8042 状态端口
        if (status & 0x01)                   // bit 0 = 输出缓冲区满
        {
            uint8 scanCode;
            asm_in_port(0x60, &scanCode);    // 读 8042 数据端口
            if (!(scanCode & 0x80))          // bit 7 = 0 → 按下事件（丢弃释放事件）
            {
                if (scanCode < sizeof(scanCodeTable))
                {
                    char ch = scanCodeTable[scanCode];
                    if (ch != 0)
                        return ch;
                }
            }
        }
    }
}
```

与中断方式的关键区别：CPU 不停循环等待按键，无信号量、无全局变量、无 ISR 崩溃风险。

3. 主循环

```cpp
void InteractiveShell::run()
{
    // 清屏、打印 Logo、尝试挂载文件系统 ...

    while (true)
    {
        printPrompt();   // "fat16> "
        inputPos = 0;

        // 逐字轮询输入直到回车
        while (true)
        {
            char ch = getChar();
            if (ch == '\n')                            // Enter
            {
                inputBuffer[inputPos] = '\0';
                printf("\n");
                break;
            }
            else if (ch == 8)                          // Backspace
            {
                if (inputPos > 0)
                {
                    inputPos--;
                    printf("\b \b");                   // 依赖 stdio 新增的 \b 支持
                }
            }
            else if (inputPos < INPUT_BUF_SIZE - 1)
            {
                inputBuffer[inputPos++] = ch;
                printf("%c", ch);                      // 回显
            }
        }
        parseAndExecute(inputBuffer);
        printf("\n");
    }
}
```

4. `stdio.cpp` 新增 `\b` 处理

原 `print(const char *str)` 只处理 `\n`，退格 `\b` 会显示为乱码。新增 case：

```cpp
case '\b':
    {
        uint cur = getCursor();
        if (cur > 0)
        {
            cur--;
            moveCursor(cur);
            print(' ');
            moveCursor(cur);
        }
    }
    break;
```

5. 命令解析器

```cpp
void InteractiveShell::parseAndExecute(const char *line)
{
    while (*line == ' ') line++;                // 跳过前导空格
    if (*line == '\0') return;                  // 空行

    char cmd[32];
    int i = 0;
    while (*line && *line != ' ' && i < 31)
        cmd[i++] = *line++;
    cmd[i] = '\0';

    while (*line == ' ') line++;
    const char *args = (*line) ? line : nullptr;

    // 分派到各命令处理函数
    if      (strcmp(cmd, "ls") == 0)     cmd_ls(args);
    else if (strcmp(cmd, "cat") == 0)    cmd_cat(args);
    else if (strcmp(cmd, "touch") == 0)  cmd_touch(args);
    else if (strcmp(cmd, "write") == 0)  cmd_write(args);
    else if (strcmp(cmd, "rm") == 0)     cmd_rm(args);
    else if (strcmp(cmd, "info") == 0)   cmd_info();
    else if (strcmp(cmd, "format") == 0) cmd_format();
    else if (strcmp(cmd, "fsck") == 0)   cmd_fsck();
    else if (strcmp(cmd, "help") == 0)   cmd_help();
    else printf("Unknown command: %s\n", cmd);
}
```

#### 测试

编译运行后，在 `fat16>` 提示符下依次执行以下命令，验证每种操作的正确性：

```
format          # 格式化文件系统，输入 y 确认
info            # 查看初始磁盘信息（空闲簇 > 0，0 个文件）

touch a.txt     # 创建空文件
ls         

write a.txt Hello_World!     # 写入内容
cat a.txt                     # 输出 "Hello_World!"
write a.txt Overwritten       # 覆盖写
cat a.txt                     # 输出 "Overwritten"

rm a.txt        # 删除
ls              # 只剩 a.txt 和 b.txt
```
![[屏幕截图 2026-06-29 235306 1.png|600]]
![[Pasted image 20260629235800.png|600]]

---

### 4.2 子目录支持（未具体实现

子目录需要修改 FAT16 类的几乎所有文件操作函数，增加路径参数。以下为核心设计
#### 设计思路

1. 目录条目标记：`attributes` 字段设为 `ATTR_DIRECTORY = 0x10`，`firstCluster` 指向子目录的目录条目数据簇。

2. 子目录初始化：`mkdir` 时分配一个新簇，写入两个默认条目：
   - `"."` — `firstCluster` 指向自身
   - `".."` — `firstCluster` 指向父目录簇号（根目录为 0）

1. 路径解析：将 `"dir1/subdir/file.txt"` 按 `/` 分割为分量数组，逐级导航目录链。

2. 函数扩展：`findEntry`、`readDirEntry`、`writeDirEntry`、`findFreeEntry` 等需增加父目录簇号参数；`createFile`、`writeFile`、`readFile`、`deleteFile`、`listFiles` 等需增加路径参数。

3. 目录删除约束：`rmdir` 前检查目录是否为空（仅含 `.` 和 `..`）。


### 4.3 大文件支持与多扇区批量 I/O（未具体实现

#### 大文件验证

本实现的 `readFile`/`writeFile` 已经支持跨簇文件（通过 FAT 链逐簇读写）。可创建超过 512 字节的文件来验证——分配多个簇后 FAT 链自动构建，读取时沿链逐簇读取

测试方法：创建 1500 字节文件（需 3 个簇），写入可验证的字节模式，读回逐字节比对。

#### 多扇区批量 I/O 优化（设计）

当前 `DiskDriver::readSectors`/`writeSectors` 已支持一次传输多个扇区（通过 `count` 参数）。优化思路：在 `readFile`/`writeFile` 中检测连续簇（`fatTable[cluster] == cluster + 1`），将连续扇区合并为一次多扇区 I/O 调用，减少端口操作次数。

性能度量：在 `DiskDriver` 中新增 `ioCount` 计数器，每次调用 `asm_in_port_word`/`asm_out_port_word` 时递增。优化前后对比 `ioCount` 值即为性能提升的直接度量。

---

### 4.4 文件系统一致性检查 `fsck()`（还有缺陷

#### 实现位置

`fat16.h` 新增 `FSCKReport` 结构体 + `fsck()` 声明；`fat16.cpp` 新增完整实现。`shell.cpp` 的 `cmd_fsck()` 直接调用。

#### FSCKReport 结构体

```cpp
struct FSCKReport
{
    int errorCount;             // 错误总数
    int warningCount;           // 警告总数
    int lostClusters;           // FAT 标记为使用但无文件引用
    int crossLinkedClusters;    // 被多个文件同时引用
    int brokenChains;           // FAT 链存在循环或无效链接
    int sizeMismatches;         // fileSize 与 FAT 链实际簇数不一致
};
```

#### Phase 1：建立引用位图并验证文件 FAT 链

```cpp
uint16 refCount[FAT_ENTRIES];
memset(refCount, 0, sizeof(refCount));

for (int i = 0; i < MAX_ROOT_ENTRIES; ++i)
{
    readDirEntry(i, &entry);
    if (entry.filename[0] == 0x00) break;
    if (entry.filename[0] == ATTR_DELETED) continue;

    // Floyd 快慢指针检测循环
    uint16 slow = entry.firstCluster, fast = entry.firstCluster;
    uint16 cluster = entry.firstCluster;
    int chainClusters = 0;

    while (cluster >= 2 && cluster < FAT16_BAD)
    {
        refCount[cluster]++;           // 引用计数 +1
        chainClusters++;

        // Floyd cycle detection
        if (slow >= 2 && slow < FAT16_BAD)
            slow = fatTable[slow];
        if (fast >= 2 && fast < FAT16_BAD)
        {
            fast = fatTable[fast];
            if (fast >= 2 && fast < FAT16_BAD)
                fast = fatTable[fast];
        }
        if (slow >= 2 && fast >= 2 && slow == fast)
        {
            printf("  ERROR: FAT chain cycle at cluster %d\n", slow);
            report.brokenChains++;
            report.errorCount++;
            break;
        }
        cluster = fatTable[cluster];
    }

    // 检查 fileSize 与实际簇数一致
    if (entry.fileSize > 0)
    {
        int expected = (entry.fileSize + SECTOR_SIZE - 1) / SECTOR_SIZE;
        if (chainClusters != expected)
        {
            printf("  WARNING: size mismatch (expected %d, got %d)\n",
                   expected, chainClusters);
            report.sizeMismatches++;
            report.warningCount++;
        }
    }
}
```

#### Phase 2：扫描 FAT 表检测丢失簇和交叉链接

```cpp
for (int i = 2; i < FAT_ENTRIES; ++i)
{
    if (refCount[i] >= 2)
    {
        printf("  ERROR: Cluster %d is cross-linked (%d refs)\n", i, refCount[i]);
        report.crossLinkedClusters++;
        report.errorCount++;
    }
    else if (refCount[i] == 0 && fatTable[i] != FAT16_FREE)
    {
        printf("  WARNING: Lost cluster %d (marked 0x%04x)\n", i, fatTable[i]);
        report.lostClusters++;
        report.warningCount++;
    }
}
```

#### 测试方法

```
fat16> format
fat16> touch a.txt
fat16> write a.txt hello
fat16> touch b.txt
fat16> write b.txt world
fat16> fsck
# 输出：Filesystem is clean.

fat16> rm a.txt
fat16> fsck
# 输出：Filesystem is clean.（删除正确释放了簇）
```

运行结果：这里没明白，执行 `fsck()`之后就直接退出QEMU了

## 思考题（选做）

1. 真实 FAT16 的 BPB 存储在哪？与本实验 SuperBlock 的区别？ 真实的 BPB 存储在卷的第一个扇区（MBR 之后的卷引导记录 VBR 中），包含 OEM 名称、扇区大小、每簇扇区数、保留扇区数、FAT 份数、根目录条目数、总扇区数等重要参数。本实验的 SuperBlock 是简化版，只包含魔数、扇区大小、FAT/根目录扇区数等基础信息，省略了大量 BPB 标准字段。

2. FAT16 最大卷大小及 FAT32 的突破？ FAT16 使用 16 位簇号，最多 2^16 = 65536 个簇。标准簇大小 32KB 时最大卷 2GB。FAT32 使用 28 位簇号（高 4 位保留），最大可管理约 2^28 = 268M 个簇，支持数 TB 的卷

3. PIO vs DMA？ PIO 模式下 CPU 必须执行每条 I/O 指令来传输数据，大文件读写时 CPU 完全被占用。DMA 模式下 CPU 只需配置 DMA 控制器（源地址、目标地址、传输大小），然后可以执行其他任务，DMA 控制器自动在磁盘和内存间传输数据，完成时通过中断通知 CPU。

4. FAT 表缓存的扩展性？ 本实现将整个 FAT 表（16KB）缓存在内存中。对于 FAT32 的大卷，FAT 表可达数 MB 甚至数十 MB，全部缓存不可行。改进策略：使用页缓存（page cache）只缓存活跃部分的 FAT 条目，配合 LRU 淘汰策略

5. 日志文件系统 vs FAT？ 日志文件系统（如 Ext4）将元数据变更先写入日志区，确认日志写入成功后才更新实际数据区。若中途断电，重启后可重放日志恢复一致性。FAT 无日志机制，断电可能导致 FAT 表与目录条目不一致（如簇已分配但目录未更新），需 `fsck` 扫描修复

6. 0xE5 删除标记对数据恢复和安全的影响？ 使用 `0xE5` 标记删除但未擦除数据，使得数据恢复软件可以通过扫描数据区恢复"已删除"的文件。这对数据恢复有利（如误删重要文件），但对数据安全不利（如删除的密码文件可被恢复
# 总结与心得

- 本次实验从零开始构建了一个完整的简化 FAT16 文件系统。从最底层的 ATA PIO 磁盘驱动开始，通过 `in`/`out` 汇编指令直接操控磁盘控制器的 I/O 端口，理解了 CPU 如何与外部存储设备进行数据交换。LBA 28 位寻址、DRQ 状态轮询、扇区级读写——这些底层的细节让我对"操作系统如何读写磁盘"有了真实认识

- 在磁盘驱动之上，实现了一个利用 FAT 链管理数据簇的文件系统雏形。FAT 表就像一个单向链表，目录条目记录链头，FAT 条目串起链节。`allocateCluster` 的首选适配策略、`freeClusterChain` 的链表释放、`syncFAT` 的缓存回写——这些看似简单的操作组合起来，便支撑起了文件的创建、写入、读取和删除

- 在扩展功能（Assignment 3）中，`appendFile` 需要处理最后一个簇的剩余空间，文件系统里很多边界条件——空文件的 `firstCluster = 0`、跨簇边界的扇区不足、追加时恰好填满一个簇——都需要逐一考虑

- 本次调试中也踩了不少坑。自定义 `printf` 不支持 `%f` 导致碎片率输出变成字面量 `2f`，排查了很久才发现是格式串问题而非逻辑错误……键盘中断驱动在 QEMU 中不稳定直接导致虚拟机崩溃，最终改用 8042 轮询方式才让交互式 Shell 正常运行

- 交互式 Shell 的实现（Assignment 4.1）让我对 8042 PS/2 键盘控制器有了基本的了解——状态端口 0x64 的 bit 0 表示输出缓冲区有数据，数据端口 0x60 读取扫描码，按下的扫描码最高位为 0、释放为 1，查表转换为 ASCII。但是最后仍未完全实现 `fsck`，由于期末其他事务就搁置了

- 总的来说，这次实验让我对 FAT16 文件系统的内部机制有了从数据结构到硬件交互的全面理解。与之前实现的中断、内存管理、进程管理等模块结合，这个自制 OS 的雏形越来越像一个真实的操作系统了
