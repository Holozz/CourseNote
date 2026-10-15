## 测试用例
### 测试思路
`InstructionFetchTest`通过给IF一个跳转信号，看其算出来的PC是否正确。 手动控制`jump_flag_id`和`jump_address_id`，再去验证`instruction_address`的正确性。  
#### 变量含义
- `entry = 0x1000`：作为程序入口地址 / 跳转目标地址
- `pre`：上一周期的 PC
- `cur`：当前周期期望的 PC
- `instruction_valid = true`：告诉 IF：指令存储器是“可用的”，PC 可以正常推进，否则 PC 可能会停住（这是 IF 模块的保护逻辑）。
####  主测试循环
`for (x <- 0 to 100) {   Random.nextInt(2) match {`
	连续测试 100 多个周期，每个周期随机选择不跳转或跳转
以覆盖任意跳转/不跳转交替出现的情况 ，避免只在固定模式下碰巧正确
### Expect值设置
顺序执行时为PC+4；跳转时为跳转目标地址。  
这两类场景通过随机方式在多个时钟周期内交替出现，从而覆盖连续跳转、跳转后顺序 执行等组合情况。  
####
这个测试属于模块级测试，测试对象为IF模块，并测试PC 的更新逻辑，跳转控制信号 对 PC 的优先级，不涉及指令译码，寄存器堆，ALU 运算，访存行为因此，该测试验证的是 CPU 前端取指阶段的数据通路与控制逻辑是否正确，而非整机功能。  
### 加载方式
测试的加载是通过人工驱动 PC 控制信号（`jump_flag_id`、`jump_address_id`），直接验证 IF 模块输出的指令地址是否正确。
### 测试执行结果
测试过程中在 100 多个时钟周期内随机产生跳转与非跳转情况每个周期使用 `expect` 断言当前 `instruction_address`
执行结果：非跳转情况下，PC 始终按 4 字节对齐顺序递增；跳转发生时，PC 在下一时钟沿立即更新为目标地址；所有断言均通过，测试未出现失败。
## 关键信号变化
1. **clock信号**：50MHz时钟（20ns周期），在时间轴10ps、30ps、50ps...处有边沿，在时钟上升沿更新PC
2. **io_instruction_address[31:0]**：
    - 初始值：`00000000`，后续持续变化：`00001004`，···，`0000100C`，（发生跳转，不再是+4）`00001010`
    - 这符合顺序执行时PC+4以及跳转指令的预期
3. **io_jump_address_id[31:0]**：固定值：`00001000`（0x1000，即测试中的entry地址）
4. **io_jump_flag_id**：初始为`reset`状态，在多个周期内保持为0。波形中可见跳转标志的脉冲信号，从0拉高到1。
5. **io_instruction_valid**：始终为`00000000`（可能表示指令无效或未使用）
## 波形图
![[屏幕截图 2026-01-24 143544.png]]
## CSRC文件下的`fibonacci.c`
#### 程序内容
核心两点：
1. 递归计算 Fibonacci
2. 结果写到内存地址 `4`
    - `*(int *)(4)` 是**物理地址 0x4**
    - 程序结束前，把 `55` 存进内存地址 `0x00000004`
#### chisel部分的检查
前面的 for 循环给 CPU 足够时间跑完递归程序
最后检查是
`c.io.mem_debug_read_address.poke(4.U) c.clock.step() c.io.mem_debug_read_data.expect(55.U)`
这里**断言expect** 期望读到 `55`
#### 波形图及其分析
![[屏幕截图 2026-01-24 164600.png]]
关键信号是：
- `clock`
- `io_mem_debug_read_address`
- `io_mem_debug_read_data`
CPU先跑递归（大多数时间），此时，
- `io_mem_debug_read_address`  被测试代码反复 poke 成 `4, 8, 12, ...`
- `io_mem_debug_read_data`基本是 `0`
然后`main` 执行 store，当程序执行到：
`*(int *)(4) = fib(10);`
硬件层面MEM 阶段`memWrite = 1` `addr = 0x4` `writeData = 55`，内存中地址 4 的内容变为 55。
最后几个周期检查结果时的波形。最后两行测试代码
`c.io.mem_debug_read_address.poke(4.U) c.clock.step() c.io.mem_debug_read_data.expect(55.U)`
倒数第 2 周期`io_mem_debug_read_address = 0x00000004`
最后一个周期（expect 发生时）地址仍然是 `4`，`io_mem_debug_read_data = 0x00000037`（十进制 55）
## 其他问题
对于使用VSCode的配置环境说明不太清晰，主要是实验文档的结构有点混乱，包括下载vscode插件scala，metals，下载库MSYS2，安装docker，安装Verilator，配置命令行环境，很多同类或者在步骤上是相继的配置操作反而在文档里不相邻，或是放在了两个很远的条目里（其实也还好，就是需要仔细找到再捋清楚）。