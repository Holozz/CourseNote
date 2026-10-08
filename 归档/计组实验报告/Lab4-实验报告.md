# AXI4-Lite主从机
## 一、基本特点
AXI4-Lite 核心约束是： **单拍事务**的一次 AR就对应一次 R，一次 AW就对应一次 W一次 B。并且无 burst、无乱序、无多 outstanding，五个独立通道全部采用 VALID / READY 握手。
## 二、通道与职责划分
五个通道的职责

|通道|方向|功能|
|---|---|---|
|Write Address (AW)|Master → Slave|发送写地址|
|Write Data (W)|Master → Slave|发送写数据 + 字节使能|
|Write Response (B)|Slave → Master|返回写完成状态|
|Read Address (AR)|Master → Slave|发送读地址|
|Read Data (R)|Slave → Master|返回读数据|

允许 AW 和 W 顺序相关但信号独立
## 三、Slave 端实现逻辑

### Slave 总体思路
- 使用一个 **FSM 串行化处理事务**
- **一次只处理一个请求**
- 将 AXI 总线事务 **转换为内部简单读写接口**
### Slave 状态机设计
`Idle  ├─ ARVALID → ReadAddr → ReadData → Idle  └─ AWVALID → WriteAddr → WriteData → WriteResp → Idle`
###  Slave 读流程
**ReadAddr**：
- 拉高 `ARREADY`
- 与 `ARVALID` 握
- 锁存 `ARADDR`
- 拉高 `bundle.read`（请求内部设备）
**ReadData**：
- 等待 `bundle.read_valid`（内部设备返回数据）
- 拉高 `RVALID`，提供 `RDATA`
- 与 Master `RREADY` 握手
- 回到 `Idle`
 关键点
- `read_valid` 只允许 **1 cycle 脉冲**
- Slave 不主动结束事务，必须等 Master `RREADY`
### Slave 写流程
**WriteAddr**
- 拉高 `AWREADY`
- 与 `AWVALID` 握手
- 锁存写地址
**WriteData**
- 拉高 `WREADY`
- 与 `WVALID` 握手
- 锁存 `WDATA`、`WSTRB`
- 拉高 `bundle.write`（写内部设备）
**WriteResp**
- 拉高 `BVALID`
- 等待 `BREADY`
- 回到 `Idle`
## 四、Master 端实现逻辑
### Master 总体思路
- 外部用 `bundle.read / bundle.write` 发起请求
- Master 自己负责：
    - 发地址
    - 发/收数据
    - 等响应
- 用 `busy` 阻止并发请求
###  Master 状态机设计
`Idle  ├─ read  → ReadAddr → ReadData → Idle  └─ write → WriteAddr → WriteData → WriteResp → Idle`
同样是 **严格顺序 FSM**，不支持并发 outstanding
###  Master 读流程
**ReadAddr**
- 拉高 `ARVALID`
- 与 `ARREADY` 握手
- 转入 `ReadData`
**ReadData**
- 拉高 `RREADY`
- 等 `RVALID
- 采样 `RDATA`
- 拉高 `read_valid`（1 cycle）
- 回到 `Idle`
###  Master 写流程
**WriteAddr**
- 拉高 `AWVALID`
- 与 `AWREADY` 握手
**WriteData**
- 拉高 `WVALID`
- 与 `WREADY` 握手
**WriteResp**
- 拉高 `BREADY`
- 等 `BVALID`
- 拉高 `write_valid`（1 cycle）
- 回到 `Idle`
# BusTest
## 测试原理
###  测试目标
- **AXI4-Lite Master / Slave 在长期、连续、随机事务下是否仍然正确**
- **在 Slave 临时“不可用”（busy / 断连）时，Master 是否能正确等待并恢复**
- **协议层是否存在时序错误、死锁、漏握手、状态机卡死等问题**
压力、随机、鲁棒性
###  核心测试思想
#### （1）随机连续事务
- 随机生成 **读 / 写事务**
- 随机地址、随机数据
- 连续发起 **1000 次事务**
- 不关心性能，只关心**每一笔是否最终正确完成**
#### （2）人为制造“总线阻塞 / 从设备忙”
`c.io.detach.poke(true.B)`会：
- **断开 master ↔ slave**
- master 实际上对着一个 DummySlave
- slave 对着 DummyMaster
等价于：
- 总线被其他 master 占用
- 外设暂时无法响应
- AXI READY/VALID 长时间不握手
#### （3）事务队列 + 顺序校验
测试维护一个软件队列：
`slave_trans_to_expect :+= ("write"/"read", addr, data)`
- 每发起一次事务，就记录期望
- 当 slave 端真的看到 `read` / `write` 信号：
    - 校验地址
    - 校验数据
    - 校验字节使能
只要顺序、内容一致，就认为该事务成功
### 核心测试机制
该测试套件通过 **Chisel 仿真环境**验证 AXI4-Lite 总线的各个组件及其交互：
1. 主从交互模拟：使用 `AXI4LiteMasterBundle` 和 `AXI4LiteSlaveBundle` 模拟主设备和从设备通过总线通信
2. 事务驱动：通过 `FlexibleTestHelper` 辅助类注入读/写事务，然后观察信号变化
3. 周期级别验证：逐周期 (`c.clock.step()`) 检查总线信号的正确性和时序关系
4. 状态机追踪：通过 `busy`、`write_valid`、`read_valid` 等信号追踪事务的生命周期
## 预期结果

| 测试类                             | 测试目标                  | 预期结果                                        |
| ------------------------------- | --------------------- | ------------------------------------------- |
| **TimerTestF**                  | Timer 模块的读写功能         | 写入限制值到 0x990315，读回数据验证无误                    |
| **MemoryTestF**                 | 内存模块的读写操作             | 写入 0xDEADBEEF 到地址 0x8，读回数据一致                |
| **ROMLoaderTestF**              | ROM 加载器通过 AXI 传输程序到内存 | 成功将 32 个 ROM 字加载到内存，每个写事务验证地址和数据            |
| **FunctionalTest - Write**      | 写事务的完整流程和时延测试         | 检查数据在从设备正确显示，`write_valid` 仅脉冲 1 周期，输出总耗周期数 |
| **FunctionalTest - Read**       | 读事务的完整流程和时延测试         | 验证从设备收到读请求，主设备正确接收响应，输出总耗周期数                |
| **FunctionalTest - Continuous** | 1000 个随机读写事务的压力测试     | 所有事务成功完成，输出总周期数和随机种子用于复现                    |
