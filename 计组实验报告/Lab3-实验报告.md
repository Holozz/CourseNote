## CPU关键思路
这是一个5级流水 RISC-V CPU，总体思路是：  
将指令执行拆分为多个阶段，通过流水寄存器连接，用控制逻辑处理控制冒险和数据冒险，在无转发能力的情况下功能正确。
流水阶段与模块对应关系如下：
1. **IF（Instruction Fetch）**
    - `InstructionFetch`：维护 PC，取指
    - 支持：
        - `pc_stall`：停止 PC 递增
        - `jump_flag / jump_address`：来自 EX 的跳转/分支结果
    - 指令进入 `IF2ID`
2. **ID（Instruction Decode）**
    - `InstructionDecode`：译码、生成控制信号
    - `RegisterFile`：读 rs1 / rs2
    - IF/ID 之间有 `stall` 和 `flush` 控制
    - 输出送入 `ID2EX`
3. **EX（Execute）**
    - `Execute`：ALU、分支判断、CSR 运算、中断响应
    - **跳转是否发生在 EX 决定**（典型设计）
    - 产生：
        - `if_jump_flag`
        - `if_jump_address`
    - 结果进入 `EX2MEM`
4. **MEM（Memory Access）**
    - `MemoryAccess`：访存
    - 同时负责外设/内存地址划分（`device_select`）
    - 结果进入 `MEM2WB`
5. **WB（Write Back）**
    - `WriteBack`：选择写回数据来源（ALU / MEM / CSR）
    - 写回寄存器堆
此外：
- **CLINT + CSR**：处理异常、中断、CSR 访问
- 中断同样可能引发控制流改变，本质上属于“跳转”
## Control控制逻辑
`Control` 任务：
**在 ID 阶段，根据 EX / MEM 阶段的状态，判断是否需要**： *stall* 或 *flush*
### Control 的输入信号
**控制冒险相关**：`jump_flag`
- 来自 EX
- 表示：
    - 分支成立
    - 或跳转指令
    - 或中断跳转
- 含义：**IF 和 ID 中的指令已经走错路**
**数据冒险相关（RAW）**
来自流水线寄存器的写回信息：

| 阶段  | 信号                               |
| --- | -------------------------------- |
| EX  | `rd_ex`, `reg_write_enable_ex`   |
| MEM | `rd_mem`, `reg_write_enable_mem` |
ID 阶段正在使用的寄存器：`rs1_id, rs2_id`
### Control 的工作模式
#### 跳转 / 中断发生

```scala
	when (jump_flag) {   
		if2id_flush := true   
		id2ex_flush := true   
		pc_stall    := false   
		if2id_stall := false 
	}
```

**含义：**
- IF、ID 中的指令全部作废
- PC 立即跳转
- 不允许 stall 干扰跳转
**本质：** 控制冒险 → 清空错误路径
####  数据冒险（无跳转）
```scala
	elsewhen (hazard_flag) {
	    if2id_flush := false
		id2ex_flush := true   
		pc_stall    := true   
		if2id_stall := true 
	}
```
说明：

|信号|作用|
|---|---|
|`pc_stall = 1`|PC 不前进|
|`if2id_stall = 1`|IF/ID 保持不变|
|`id2ex_flush = 1`|EX 插入 bubble|
|`if2id_flush = 0`|保留 ID 指令|

`EX    ← bubble ID    ← 原指令（等） IF    ← 原指令（等）`
####  无冒险（正常执行）
`otherwise {   全部 := false }`
没有问题，流水线就正常前进。
## CSR指令冒险
### 是否会产生控制冒险？
会，但被统一当作“跳转类事件”处理，不需要单独机制。
原因：
- CSR 本身（如 `csrrw`、`csrrs`）**不改变 PC**
- 但 **异常 / 中断相关 CSR（mepc、mtvec、mcause）一定伴随控制流改变**
- 在你的设计中：
    - 中断/异常由 `CLINT + EX` 产生
    - 最终通过 `ex.io.if_jump_flag` 进入 `Control`
    - 被当作普通 `jump_flag` 处理
也就是说**CSR 引发的控制流改变已经被折叠进 jump_flag，不存在“CSR 特有的控制冒险问题”。**
### 是否会产生数据冒险？
#### CSR ↔ GPR（通用寄存器）
会，但你的流水线已经用“普通寄存器冒险规则”覆盖了。
例如：
`csrrw x1, mstatus, x2 add   x3, x1, x4`， CSR 指令写的是 **x1（GPR）**，写回发生在 WB，下一条在 ID 读 x1
`hazard_flag` 逻辑：
`rd_ex / rd_mem 与 rs1_id / rs2_id 比较`
**完全能覆盖 CSR → GPR 的 RAW 冒险**  
#### GPR → CSR
`add   x1, x2, x3 csrrw mstatus, x0, x1`， CSR 写数据来自 `x1`。CSR 写发生在 EX，如果前一条还没写回。
**普通 GPR RAW 冒险**，已经被 `hazard_flag` 捕获。
### CLINT 与流水线同时访问 CSR 的冲突
设计选择：
`// If the pipeline and the CLINT are going to read and write the CSR at the same time, // let the pipeline write first.`
通过 `Mux(io.reg_write_enable_ex && addr == CSR, io.reg_write_data_ex, csr_reg)`实现了同一周期里EX 写 CSR，CLINT 读 CSR。CLINT 看到的是新值。
这是一个显式的“单周期旁路（bypass）”设计，而且是正确的。
结论： **CLINT ↔ CSR 的冲突被正确解决，不会冒险问题。**
### 特别的处理措施
不需要。原因如下
1. CSR 指令数量少
2. 实验不考察 CSR forwarding
3. 中断路径已统一进 jump 逻辑
4. CSR↔CSR RAW 在测试中被默认避免
### 总结
> CSR 指令在本设计中可能引发控制冒险和数据冒险，但控制冒险已被统一为跳转处理逻辑；CSR 与通用寄存器之间的数据冒险可由现有的寄存器冒险检测机制覆盖。CSR 寄存器之间的 RAW 冒险在理论上存在，但不要求实现 CSR forwarding的情况下无需额外控制逻辑。