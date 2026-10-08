## CLINTCSRTest.scala
### 关键的输入信号及其测试的功能
- **中断触发条件**
    - **信号**：`io.interrupt_flag := InterruptCode.Timer0`，`io.jump_flag := false`，`io.instruction := nop`，`io.instruction_address := 0x1900`
    - **功能**：CLINT 是否能识别 外部硬件中断，在非跳转指令情况下，是否正确取 `instruction_address`
- **CSR 事前配置**
    - **信号**：`mtvec = 0x1144`，`mstatus = 0x1888`（MIE=1）
    - **功能**：CLINT 是否读取 CSR，是否只在 **MIE=1** 时响应中断
- **中断处理时对 CSR 的写入**
    - 写 `mepc`、`mcause`，修改 `mstatus`（清 MIE，保存到 MPIE）
	- 用来测试中断现场保存是否正确
- **mret 指令**： `instruction := mret`
	- **测试功能**：是否能正确从中断返回，是否恢复 `mstatus`，是否跳回 `mepc`
### 波形图及其过程
![[Pasted image 20260124180424.png]]
选择这个测试的硬件的非跳转指令的部分。即`io_jump_flag == 0`这一部分，在波形图里是62ps之前，大约10ps~20ps之间的变化明显。
#### 阶段 0：中断发生前（正常执行）
在10 ps 之前的开始阶段：

| 信号                    | 数值     | 说明    |
| --------------------- | ------ | ----- |
| `io_jump_flag`        | 0      | 非跳转   |
| `io_interrupt_flag`   | 0      | 无中断   |
| `io_interrupt_assert` | 0      | 未进入中断 |
| `instruction_address` | 0x1900 | 正常 PC |

#### 阶段 1：硬件中断被识别（中断开始）
约 10 ps 左右，你可以看到：

| 信号                             | 数值         | 含义           |
| ------------------------------ | ---------- | ------------ |
| `io_interrupt_flag`            | `00000002` | Timer0 硬件中断  |
| `io_jump_flag`                 | 0          | 非跳转指令        |
| `io_interrupt_assert`          | 1          | CLINT 决定处理中断 |
| `io_interrupt_handler_address` | `0x1144`   | 跳转到 mtvec    |
处理中断就在这里开始
#### 阶段 2：CLINT 写入 CSR（保存现场）
紧接着（同一拍或下一拍），在波形中：
-  `io_csr_bundle_mepc = 0x1904`，是因为`mepc = instruction_address + 4 = 0x1900 + 4`，说明 CLINT 正确保存“被打断指令的下一条地址”。
- `io_csr_bundle_mcause = 0x80000007`是因为最高位 `1`：中断，`7`：Timer interrupt
- `0x1888 → 0x1880`：MIE 被清 0，MPIE 保存原来的 MIE。说明关中断 + 保存中断使能状态完成。
#### 阶段 3：执行 mret（中断返回）
再往后（大约 60 ps 左右）：

| 信号                             | 数值               |
| ------------------------------ | ---------------- |
| `io_instruction`               | `30200073`（mret） |
| `io_interrupt_assert`          | 1                |
| `io_interrupt_handler_address` | `0x1904`         |
 CLINT 识别 mret，PC 被设置为 `mepc`。中断返回
#### 阶段 4：中断处理完成（状态恢复）
下一拍：
`io_csr_bundle_mstatus = 0x1888`，MIE 恢复，中断正式结束
####
在非跳转指令（`jump_flag = 0`）情况下，当 `interrupt_flag` 置为 Timer0 时，CLINT 立即断言 `interrupt_assert`，并将 PC 跳转至 `mtvec` 指定的中断入口地址。与此同时，CLINT 将当前指令的下一地址写入 `mepc`，将中断原因写入 `mcause`，并清除 `mstatus` 中的 MIE 位以屏蔽后续中断。当执行 `mret` 指令时，CLINT 将 PC 恢复为 `mepc`，并恢复 `mstatus`，完成一次完整的硬件中断处理流程。
## SimpleTrapTest.scala
### `simpletest.c` 测试 CPU 中断处理正确性
#### 主程序
`*((int*)0x4) = 0xDEADBEEF; enable_interrupt(); for(;;);`
先写内存 0x4 = 0xDEADBEEF作为“中断发生前”的标志。`enable_interrupt()`打开`mstatus.MIE`。`for(;;);`CPU 进入死循环，如果没有中断或中断机制错误，程序卡在这里
 因此只要后续内存 0x4 被改写，唯一可能就是中断被正确处理了。
#### 中断：验证跳入 trap handler 、 正确执行 、 成功返回
`void trap_handler(void *epc, unsigned int cause){     *((int*)0x4) = 0x2022; }`
trap handler 把内存 0x4 改成 0x2022
验证了： CPU 真的跳转到了 trap handler，handler 中的指令被正确执行，handler 执行完成后，CPU 没有卡死在 handler 里。
#### 测试代码
Scala 测试逐点验证结果：
1. 中断前状态`mem[0x4] == 0xDEADBEEF` → 主程序跑到了 `main`，且未被提前打断
2. 注入硬件中断`c.io.interrupt_flag.poke(0x1.U)`  → 模拟外部中断注入
3. 中断后状态`mem[0x4] == 0x2022` → trap handler 被正确执行
4. CSR 状态检查`MCAUSE == 0x80000007 MSTATUS == 0x1888` → 中断原因正确、`mret` 后状态恢复正确
#### 总结
该测试通过在主程序死循环期间注入外部中断，检查 CPU 是否能跳转至 trap handler 执行处理逻辑，并在返回后恢复 CSR 状态，从而验证中断进入、处理中断及中断返回三个关键环节的正确性。


### 波形图

![[Pasted image 20260124195823.png]]
在波形图中可以观察到，在注入外部中断前，内存地址 0x4 的值为 0xDEADBEEF，表明主程序已正常运行。当 `interrupt_flag` 被置位后，CPU 进入中断处理流程，`mcause` 被写为 0x80000007。随后，在中断处理函数中将内存地址 0x4 的值更新为 0x2022。中断返回后，`mstatus` 恢复为 0x1888，表明 CPU 成功执行了 `mret` 并从中断返回。上述信号共同证明 CPU 的中断处理机制工作正确。
## 定时器中断问题
假如我们的 CPU 上运行着某个操作系统，并在启动后向 `mtvec` 写入了中断处理程序的地址。若在执行程序时发生 定时器中断，则：
### CPU 
#### 1.判断是否可以响应中断
检查：中断标志（Timer interrupt）`mstatus.MIE == 1`。若允许，则进入中断流程
#### 2.保存被打断程序的关键信息（写 CSR）
CPU 自动写入以下 CSR：

| CSR       | 写入内容            | 作用     |
| --------- | --------------- | ------ |
| `mepc`    | 当前指令的下一条地址      | 中断返回地址 |
| `mcause`  | 定时器中断编码         | 记录中断原因 |
| `mstatus` | 清除 MIE，保存到 MPIE | 防止嵌套中断 |

#### 3.跳转到中断入口
将 PC 设置`PC = mtvec`，开始执行操作系统提供的中断入口代码
### 操作系统
真正的中断处理逻辑由操作系统完成
#### 4.中断入口代码（trap entry）
操作系统首先执行一段汇编代码，通常称为 trap entry：
- 保存通用寄存器（如 x1–x31）到内核栈
- 构造完整的进程上下文
- 区分：
    - 中断 / 异常
    - 定时器 / 外部 / 软件中断
#### 5. 执行定时器中断处理函数
操作系统的定时器中断处理程序通常会：
- 更新系统时钟（tick）
- 维护时间片
- 判断是否需要进程调度
- 可能触发 进程切换


#### 6. 中断返回前的恢复
操作系统完成中断处理后,从内核栈恢复通用寄存器，并执行`mret`。
### 中断返回
执行 `mret` 后，CPU 自动：
1. 恢复中断使能状态 `mstatus.MIE ← mstatus.MPIE`
2. 恢复执行地址 `PC ← mepc`
3. 返回被打断的程序 或返回新的调度程序（若发生切换）
### 整体协作关系总结
当定时器中断发生时，CPU 在硬件层面自动保存当前执行状态至 CSR，并跳转到操作系统在 `mtvec` 中设置的中断入口。操作系统随后保存完整上下文，执行定时器中断处理逻辑，并在处理完成后通过 `mret` 指令恢复状态，使 CPU 返回被中断的程序或调度后的新程序执行。