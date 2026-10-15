---
cssclasses:
---

<div class="cover">
  <h1>2024级本科生《计算机组成原理实验》实验报告</h1>
  <h2>Lab1</h2>
  <div class="info">
    <p>班级：计科1班</p>
    <p>姓名：韩宇</p>
    <p style="margin-bottom: 400px;">学号：24319050</p>
    <p class="date" style="font-size: 1em">日期：10/14</p>
  </div>
</div>

<div style="page-break-after: always;"></div>

---

## 一、实验目的

1. 理解单周期 CPU 的数据通路，掌握取指、译码、执行、访存和写回模块之间的连接
2. 使用 ChiselTest 对取指、译码和执行部件进行单元测试，理解输入激励、时钟推进和输出断言的作用
3. 运行完整程序，通过内存或寄存器调试接口检查 CPU 的执行结果，并结合 VCD 波形分析关键信号

## 二、实验内容

### 1. CPU 的设计

本实验使用 `lab1` 中的 32 位 RISC-V 单周期 CPU，程序入口地址为 `0x00001000`，`CPU.scala` 将五个功能模块和寄存器堆连接成完整的数据通路

这里的五个模块是同一条指令的功能划分，没有五级流水线中的级间寄存器，一条指令在一个 CPU 周期内经过相应模块完成运算或访存，在时钟沿更新 PC 和寄存器状态

| 模块 | 对应文件 | 主要功能 |
| --- | --- | --- |
| 取指 | `InstructionFetch.scala` | 保存 PC 并输出指令地址，指令有效时顺序执行更新为 `PC + 4`，跳转时更新为目标地址；指令无效时保持 PC，并输出 `0x00000013` 空操作指令 |
| 译码 | `InstructionDecode.scala` | 提取 opcode、寄存器编号和立即数，生成 ALU 操作数选择、内存读写使能、寄存器写使能及写回来源等控制信号 |
| 执行 | `Execute.scala` | 选择寄存器、PC 或立即数作为 ALU 输入，完成算术逻辑运算及访存地址计算；比较分支条件，输出跳转标志与跳转地址 |
| 访存 | `MemoryAccess.scala` | 将 ALU 结果作为数据地址，load 指令按字节、半字或字读取并扩展数据，store 指令生成写数据和字节写掩码 |
| 写回 | `WriteBack.scala` | 在 ALU 结果、内存读取结果和 `PC + 4` 中选择写回数据，交给寄存器堆写入目标寄存器 |

寄存器堆提供两个读取端口和一个写入端口，译码模块决定读哪个寄存器、写哪个寄存器以及是否允许写入，写回模块提供最终写入的数据，`x0` 保持为 0

以 `lw x3, 4(x1)` 为例，取指模块提供指令，译码模块选出 `x1` 和立即数 4，执行模块计算 `x1 + 4`，访存模块读取该地址的 32 位数据，写回模块将读取结果写入 `x3`

整机测试中的 `TestTopModule` 使用 `CPU_clkdiv` 产生 CPU 时钟，CPU 每 4 个测试顶层时钟周期运行一次，外部 `Memory` 使用顶层时钟和 `SyncReadMem`，为同步取指、数据读取及调试读取提供时序配合，测试中的 `clock.step(1000)` 推进的是顶层时钟

### 2. 测试内容与运行方式

分别运行 `ExecuteTest.scala`、`InstructionDecoderTest.scala` 和 `InstructionFetchTest.scala`，译码部分重点分析 L 类中的 `lw` 指令

实验要求中的取指测试在当前项目中实际命名为 `InstructionFetchTest.scala`，`InstructionFetch.scala` 是被测模块的实现文件

`CPUTest.scala` 中没有名为 `CPUTest` 的测试类，实际定义了 `FibonacciTest`、`QuicksortTest` 和 `ByteAccessTest`，运行整机测试时需要选择这三个类

在 `lab1` 目录中运行以下命令

```powershell
sbt "testOnly riscv.singlecycle.ExecuteTest riscv.singlecycle.InstructionDecoderTest riscv.singlecycle.InstructionFetchTest riscv.singlecycle.FibonacciTest riscv.singlecycle.QuicksortTest riscv.singlecycle.ByteAccessTest"
```

项目的 `TestAnnotations.annos` 已启用 `VerilatorBackendAnnotation` 和 `WriteVcdAnnotation`，运行测试会在 `test_run_dir` 中生成对应 VCD 文件

## 三、实验结果

### 1. 测试执行结果

本次使用 JDK 17、sbt 1.9.6 和 Verilator，于 2026-10-14 重新运行上述六项测试，测试结果为 6 项成功、0 项失败、0 个测试套件中止

| 测试类 | 测试内容 | 结果 |
| --- | --- | --- |
| `ExecuteTest` | 101 组随机加法，以及相等、不相等两种 `beq` 情况 | 通过 |
| `InstructionDecoderTest` | L、S、I、B、RM 以及 `lui`、`jal`、`jalr`、`auipc` 的控制信号 | 通过 |
| `InstructionFetchTest` | 101 次随机顺序执行或跳转，检查 PC 更新 | 通过 |
| `FibonacciTest` | 递归计算 `fib(10)`，检查内存地址 4 的值为 55 | 通过 |
| `QuicksortTest` | 对 10 个数排序，检查地址 4 至 40 中依次保存 0 至 9 | 通过 |
| `ByteAccessTest` | 检查字节写入后的寄存器值为 `0xDEADBEEF`、`0xEF` 和 `0x15EF` | 通过 |

下图整理自本次测试日志，完整日志保存在项目的 `lab1/lab1-report-tests.log`

![[计组实验报告/Source/Lab1/test-results.png]]

### 2. 译码模块测试：L 类指令

#### 测试思路与对应代码

`poke` 将测试输入送入模块，`expect` 比较实际输出与预期值，不一致时测试失败，`clock.step()` 推进一个时钟周期，随后切换下一条测试指令

译码模块是组合逻辑，测试在设置指令后直接检查控制输出，最后的 `clock.step()` 将这组输入与下一组输入分隔开，不要求译码结果等到时钟上升沿才产生

```scala
// lw x3, 4(x1)
c.io.instruction.poke(0x0040A183L.U)
c.io.ex_aluop1_source.expect(ALUOp1Source.Register)
c.io.ex_aluop2_source.expect(ALUOp2Source.Immediate)
c.io.ex_immediate.expect(4.U)
c.io.regs_reg1_read_address.expect(1.U)
c.io.reg_write_enable.expect(true.B)
c.io.reg_write_address.expect(3.U)
c.io.wb_reg_write_source.expect(RegWriteSource.Memory)
c.io.memory_read_enable.expect(true.B)
c.io.memory_write_enable.expect(false.B)
c.clock.step()
```

`0x0040A183` 的各字段如下

| 指令字段 | 数值 | 含义 |
| --- | --- | --- |
| `instruction(6, 0)` | `0000011` | L 类 load 指令 |
| `instruction(14, 12)` | `010` | 读取一个 32 位字，即 `lw` |
| `instruction(19, 15)` | 1 | 基址寄存器为 `x1` |
| `instruction(11, 7)` | 3 | 目标寄存器为 `x3` |
| `instruction(31, 20)` | 4 | 地址偏移量为 4，符号扩展后仍为 4 |

这条指令执行 `x3 ← Memory[x1 + 4]`，因此各个 `expect` 的设置如下

| 输出信号 | 预期值及编码 | 设置原因 |
| --- | --- | --- |
| `ex_aluop1_source` | `Register = 0` | 地址计算的第一个操作数来自基址寄存器 |
| `ex_aluop2_source` | `Immediate = 1` | 第二个操作数来自立即数偏移量 |
| `ex_immediate` | `0x00000004` | 偏移量为 4 |
| `regs_reg1_read_address` | 1 | 需要读取 `x1` 的数据 |
| `reg_write_enable` | 1 | load 完成后需要写入寄存器 |
| `reg_write_address` | 3 | 读取的数据写入 `x3` |
| `wb_reg_write_source` | `Memory = 1` | 写回的是内存数据，ALU 结果仅用作访存地址 |
| `memory_read_enable` | 1 | 需要读取内存 |
| `memory_write_enable` | 0 | 该指令不修改内存 |

这里的寄存器读取地址 1 表示寄存器编号，不表示 `x1` 的内容等于 1，实际有效地址要在整机中由寄存器数据与立即数相加得到

#### 波形位置与关键信号

波形来自本次测试生成的 `InstructionDecode.vcd`，图中黄色区域为 `2 ≤ t < 4 ps`，对应第一条 L 类指令

![[计组实验报告/Source/Lab1/decoder-load.png]]

在 `2 ps`，复位撤销，`instruction` 从 0 变为 `0040A183`，`ex_immediate` 变为 `00000004`，源寄存器编号变为 1，目标寄存器编号变为 3

同一区间内，`ex_aluop1_source = 0`、`ex_aluop2_source = 1`，`reg_write_enable` 和 `memory_read_enable` 均由 0 变为 1，`wb_reg_write_source` 由 0 变为 1，`memory_write_enable` 保持 0，与上述断言逐项一致

`3 ps` 为该组输入对应的时钟上升沿，控制信号保持稳定；`4 ps` 切换为 `sw x10, 4(x0)`，此时内存读使能变为 0，内存写使能变为 1，寄存器写使能变为 0，load 和 store 的控制差异在波形中可直接比较

### 3. 取指模块测试

#### 测试思路与对应代码

测试将入口地址设为 `0x1000`，将 `instruction_valid` 设为真，在 `0 to 100` 的闭区间内进行 101 次测试，每次随机选择顺序执行或跳转

```scala
val entry = 0x1000
var pre = entry
var cur = pre
c.io.instruction_valid.poke(true.B)

for (x <- 0 to 100) {
  Random.nextInt(2) match {
    case 0 =>
      cur = pre + 4
      c.io.jump_flag_id.poke(false.B)
      c.clock.step()
      c.io.instruction_address.expect(cur)
      pre = pre + 4
    case 1 =>
      c.io.jump_flag_id.poke(true.B)
      c.io.jump_address_id.poke(entry)
      c.clock.step()
      c.io.instruction_address.expect(entry)
      pre = entry
  }
}
```

没有跳转时，下一条 32 位指令位于当前地址之后 4 字节，预期值为 `pre + 4`；发生跳转时，预期值为输入的目标地址 `entry`

测试在 `clock.step()` 后检查 PC，验证的是时钟沿后的地址更新，当前用例没有单独覆盖 `instruction_valid = false` 时的暂停行为

#### 波形与结果

![[计组实验报告/Source/Lab1/fetch-pc.png]]

本次随机测试中，`10 ps` 将跳转标志设为 0，`11 ps` 上升沿将 PC 从 `0x1000` 更新为 `0x1004`，`13 ps` 继续更新为 `0x1008`

`14 ps` 将跳转标志设为 1，目标地址为 `0x1000`，`15 ps` 上升沿将 PC 从 `0x1008` 更新为 `0x1000`，随后连续跳转期间 PC 保持在目标地址

复位结束后 `instruction_valid` 保持为 1，101 次地址断言均通过，随机选择未固定种子，后续重跑时跳转出现的位置可能不同

### 4. 执行模块测试

#### 测试思路与对应代码

加法部分输入 `add x3, x2, x1`，产生 101 组随机操作数，用 Scala 的加法计算期望结果，再检查执行模块的 ALU 输出，同时检查普通加法不会产生跳转

```scala
c.io.instruction.poke(0x001101b3L.U)
for (x <- 0 to 100) {
  val op1 = scala.util.Random.nextInt(429496729)
  val op2 = scala.util.Random.nextInt(429496729)
  val result = op1 + op2
  c.io.reg1_data.poke(op1.U)
  c.io.reg2_data.poke(op2.U)
  c.clock.step()
  c.io.mem_alu_result.expect(result.U)
  c.io.if_jump_flag.expect(0.U)
}
```

分支部分设置 `PC = 2`、立即数为 2，预期跳转目标为 `PC + immediate = 4`，分别输入相等与不相等的寄存器数据

```scala
c.io.instruction.poke(0x00208163L.U) // beq x1, x2, 2
c.io.instruction_address.poke(2.U)
c.io.immediate.poke(2.U)
c.io.aluop1_source.poke(1.U)
c.io.aluop2_source.poke(1.U)
c.clock.step()

c.io.reg1_data.poke(9.U)
c.io.reg2_data.poke(9.U)
c.clock.step()
c.io.if_jump_flag.expect(1.U)
c.io.if_jump_address.expect(4.U)

c.io.reg1_data.poke(9.U)
c.io.reg2_data.poke(19.U)
c.clock.step()
c.io.if_jump_flag.expect(0.U)
c.io.if_jump_address.expect(4.U)
```

两寄存器都为 9 时，`beq` 条件成立，跳转标志为 1；数据分别为 9 和 19 时，条件不成立，跳转标志为 0，目标地址仍然计算为 4，但取指模块不会采用这个地址

该测试的加法和分支断言均通过，现有用例覆盖这些输入下的运算及分支判断，未覆盖所有 ALU 运算、32 位溢出或所有分支条件

### 5. 整机测试：Fibonacci 程序

#### 程序内容与测试思路

选择 `csrc/fibonacci.c` 进行分析，程序以 `fib(1) = fib(2) = 1` 为递归出口，计算 `fib(10)`，将结果 55 写入内存地址 `0x00000004`

```c
int fib(int a) {
  if (a == 1 || a == 2) return 1;
  return fib(a - 1) + fib(a - 2);
}

int main() {
  *(int *)(4) = fib(10);
}
```

递归调用涉及参数传递、函数跳转、返回地址保存、栈读写和加法计算，整机运行同时使用取指、译码、执行、访存和写回通路

`TestTopModule("fibonacci.asmbin")` 读取编译后的指令镜像，`ROMLoader` 从入口地址 `0x1000` 开始将程序写入内存，加载完成后将 `instruction_valid` 置为真，CPU 开始执行程序

启动代码 `csrc/init.S` 调用 `main`，`main` 返回后执行 `loop: j loop`，因此程序计算结束后仍然有时钟活动，PC 停留在自跳转循环地址

#### Chisel 测试中的检查

```scala
test(new TestTopModule("fibonacci.asmbin"))
  .withAnnotations(TestAnnotations.annos) { c =>
    for (i <- 1 to 50) {
      c.clock.step(1000)
      c.io.mem_debug_read_address.poke((i * 4).U)
    }

    c.io.mem_debug_read_address.poke(4.U)
    c.clock.step()
    c.io.mem_debug_read_data.expect(55.U)
  }
```

前面的循环累计推进 50000 个顶层时钟周期，为加载和程序运行预留时间，每隔 1000 个周期改变调试读取地址，源码标注其用途为 `Avoid timeout`，这些地址变化不属于 CPU 执行程序时的实际访存

最终将调试读取地址设为 4，推进一个顶层周期，再断言读出值等于 55，`Memory` 的调试端口使用 `SyncReadMem`，地址设置后需要经过时钟沿才能得到对应数据

#### 程序执行与结果写入波形

本次 VCD 中，`instruction_valid` 在 `283 ps` 变为 1，程序进入执行阶段，递归计算完成后出现以下写入过程

![[计组实验报告/Source/Lab1/fibonacci-store.png]]

图中显示返回指令 `00008067` 后切换到存储指令 `00A02223`，即 `sw x10, 4(x0)`，返回值通过 `x10` 送入内存写数据通路

在 `22755 ps`，相关信号值如下

| 信号 | 波形值 | 对应操作 |
| --- | --- | --- |
| `instruction_address` | `0x00001210` | 当前程序位置 |
| `instruction` | `0x00A02223` | 将 `x10` 的内容存到地址 4 |
| `CPU memory address` | `0x00000004` | ALU 计算得到的写入地址 |
| `CPU write_data` | `0x00000037` | 十进制 55，即 `fib(10)` |
| `CPU write_enable` | 1 | 允许内存写入 |
| `write_strobe[3:0]` | `1111` | 写入一个完整的 32 位字 |

写使能、地址和数据在后续顶层上升沿保持有效，`Memory` 将 `0x37` 写入地址 4，随后进入 `main` 的返回流程

这里的 CPU 存储接口与 `mem_debug_read_address` 是两套接口，前者执行程序的 load/store，后者由测试代码选择待检查的内存位置

#### 最后几个周期的检查波形

![[计组实验报告/Source/Lab1/fibonacci-final.png]]

| 时间位置 | 调试读取地址 | 调试读取数据 | CPU 状态 |
| --- | --- | --- | --- |
| `99988–100001 ps` | `0x000000C4` | `0x00000000` | 程序已返回，执行自跳转循环 |
| `100002 ps` | 改为 `0x00000004` | 仍为 `0x00000000` | 设置结果地址，等待同步读时钟沿 |
| `100003 ps` | `0x00000004` | 变为 `0x00000037` | 顶层时钟上升沿后读出结果，满足 `expect(55.U)` |

末尾 PC 为 `0x0000100C`，指令为 `0x0000006F`，即 `jal x0, 0` 自跳转，CPU 内存写使能为 0，结果早已写入内存，最后的数据变化来自测试端口改为读取地址 4

`expect` 是软件断言，本身没有独立的硬件信号线，波形展示的是执行断言时的地址 4 和数据 `0x37`，是否通过由测试日志确认

本报告的波形图均从本次生成的 VCD 实际信号变化绘制，总线用十六进制显示，VCD 声明的时间单位为 `1 ps`，顶层时钟每周期占 2 个时间刻度，这一刻度是仿真器的时间安排，不能直接作为 FPGA 实际工作频率

## 四、问题&总结

1. 环境配置步骤分散

   之前的实验记录中，VS Code、Scala、Metals、MSYS2、Verilator 和命令行环境的配置分布在不同条目，查找与核对依赖关系需要来回跳转，建议将 Windows 环境整理成按顺序执行的配置清单，并给出 Java、sbt、Verilator 和编译工具的检查命令

2. sbt 启动受到环境和锁文件影响

   本次重跑先遇到用户缓存目录的锁文件访问限制，获得执行权限后又遇到 Windows 命名管道锁错误 `ServerAlreadyBootingException`，最终使用 JDK 17 直接启动 `sbt-launch.jar`，传入 `-Dsbt.server.forcestart=true` 和 `-Dsbt.server.autostart=false`，完成六项测试，处理时没有修改 CPU 源码

3. 波形定位需要区分时钟与接口

   整机 VCD 的时间跨度较长，直接查看全图时无法看清结果写入和末尾检查，需要分别放大存储指令附近与最后几个周期，分析时要区分顶层时钟、CPU 分频时钟，以及 CPU 访存接口和测试调试读取接口

4. 实验指导与用例可补充的内容

   建议指导书使用当前项目的 `InstructionFetchTest.scala` 文件名，并列出 `CPUTest.scala` 中三个测试类的实际运行命令；波形部分给出信号路径、数值进制和结果检查区间，避免把仿真刻度当作硬件频率

   现有取指和执行测试使用随机输入，未固定随机种子，复现时具体波形可能改变，后续可以固定种子，并补充取指暂停、负立即数、ALU 边界值和字节访存符号扩展等用例

本次三个部件测试和三个整机程序测试均通过，译码波形与 L 类控制信号断言一致，取指波形符合顺序更新和跳转更新，Fibonacci 的存储波形与最后调试读取共同记录了地址 4 写入并读出 55 的过程
