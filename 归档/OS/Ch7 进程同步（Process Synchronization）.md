> **核心问题**：多进程并发访问共享数据时，如何保证正确性？
## 目录

- [[#一、背景：为什么需要同步]]
- [[#二、竞争条件（Race Condition）]]
- [[#三、临界区问题]]
- [[#四、软件解决方案]]
- [[#五、硬件同步支持]]
- [[#六、互斥锁（Mutex Lock）]]
- [[#七、信号量（Semaphore）⭐⭐⭐]]
- [[#八、管程（Monitor）⭐⭐⭐]]
- [[#九、活性问题（Liveness）]]
- [[#十、经典同步问题]]
- [[#十一、不同操作系统的同步实现]]
- [[#十二、新型同步方案]]
- [[#附录：例题与解析]]

---

## 一、背景：为什么需要同步

### 1.1 并发执行的本质

现代操作系统允许进程**并发（Concurrent）甚至并行（Parallel）**执行：

- **多道程序设计**：多个进程交替使用 CPU
- **多处理器**：多个进程真正同时在不同 CPU 上运行
- **分布式系统**：进程分布在不同机器上

进程可以在任意时刻被中断、切换，执行是片段式的。

### 1.2 共享数据带来的危险

```
进程 A：attach X; add 10 to X; exit;
进程 B：attach X; minus 10 from X; exit;
初始 X = 10，正确结果应为 10
```

**实际可能得到 0、10 或 20**，取决于两个进程的执行顺序与切换时机。

**根本原因**：高级语言的"一条语句"在底层通常需要多条机器指令（load → 操作 → store），进程切换可能发生在这些指令之间。

---

## 二、竞争条件（Race Condition）

### 2.1 定义

> **竞争条件**：多个进程并发访问和操作同一数据，且最终执行结果**依赖于进程的执行顺序**。

### 2.2 经典案例：counter++ 与 counter--

生产者执行 `counter++`，消费者执行 `counter--`，两者共享整型变量 `counter`。

**底层展开：**

```
counter++ 等价于：
  r1 = counter       ; 读
  r1 = r1 + 1        ; 加
  counter = r1       ; 写

counter-- 等价于：
  r2 = counter       ; 读
  r2 = r2 - 1        ; 减
  counter = r2       ; 写
```

**一种危险交错（counter 初始为 5）：**

|时刻|操作|值|
|---|---|---|
|T0|生产者：r1 = counter|r1=5|
|T1|生产者：r1 = r1 + 1|r1=6|
|T2|消费者：r2 = counter|r2=5 ← 此时 counter 还是 5！|
|T3|消费者：r2 = r2 - 1|r2=4|
|T4|生产者：counter = r1|counter=6|
|T5|消费者：counter = r2|counter=4 ← 错误！|

**结果是 4，而不是正确答案 5。**

### 2.3 竞争条件的特点

- **不确定性**：结果依赖于调度，同一程序每次运行可能不同
- **难以调试**：只在特定时序下触发，难以复现
- **操作系统内部也存在**：内核数据结构（进程表、文件表等）同样面临此问题

---

## 三、临界区问题

### 3.1 临界区定义

**临界区（Critical Section）**：进程代码中访问共享资源（公共变量、文件、硬件等）的那段代码。

```
进程结构：
┌────────────────────┐
│   entry section    │  ← 申请进入
├────────────────────┤
│  critical section  │  ← 访问共享资源
├────────────────────┤
│    exit section    │  ← 释放
├────────────────────┤
│ remainder section  │  ← 其余代码
└────────────────────┘
```

### 3.2 解决方案必须满足的三个条件

> ⚠️ **考试重点**：三条缺一不可，缺任何一条都不能作为正确解法。

|条件|含义|直觉解释|
|---|---|---|
|**互斥（Mutual Exclusion）**|同一时刻至多一个进程在其临界区|"房间里只能有一个人"|
|**推进（Progress）**|若无进程在临界区，等待进入的进程应能在有限时间内被选中|"不能让所有人都卡在门口"|
|**有限等待（Bounded Waiting）**|一个进程申请后，其他进程进入临界区的次数有上限|"不能让某人永远等待（饥饿）"|

**附加假设**：每个进程以非零速度执行；不对 n 个进程的相对速度做假设。

---

## 四、软件解决方案

### 4.1 严格轮换（Strict Alternation）

```c
// 进程 0
while (TRUE) {
    while (turn != 0);        // 忙等待
    critical_section();
    turn = 1;
    noncritical_section();
}

// 进程 1
while (TRUE) {
    while (turn != 1);        // 忙等待
    critical_section();
    turn = 0;
    noncritical_section();
}
```

**满足**：互斥 ✓、有限等待 ✓  
**不满足**：推进 ✗

**缺陷**：若进程 0 想连续两次进入临界区，必须等进程 1 先进一次，即使进程 1 不需要。**临界区外的进程阻塞了其他进程进入**，违反推进要求。

---

### 4.2 Peterson 解决方案 ⭐

使用两个共享变量：

- `int turn`：轮到谁进入
- `boolean interested[2]`：进程是否想进入

```c
int turn;
int interested[2] = {FALSE, FALSE};

void enter_region(int process) {
    int other = 1 - process;
    interested[process] = TRUE;   // 声明想进入
    turn = other;                  // 把优先权让给对方（绅士原则）
    while (turn == other && interested[other] == TRUE)
        ;  // 忙等待：对方想进且轮到对方
}

void leave_region(int process) {
    interested[process] = FALSE;  // 声明已退出
}
```

**正确性证明（三条均满足）：**

- **互斥**：若两个进程都执行完 `turn = other` 后，`turn` 只能是最后赋值的那个值。假设 P0 和 P1 都想进入，最后 `turn = 0`（P1 设置），则 P1 的 while 条件 `turn==0 && interested[0]==TRUE` 为真，P1 等待；P0 的条件 `turn==1` 为假，P0 进入。✓
- **推进**：若 P1 不想进入（`interested[1]=FALSE`），P0 的 while 条件立即为假，P0 直接进入。✓
- **有限等待**：P1 离开后设 `interested[1]=FALSE`，P0 的 while 条件为假，P0 最多等一次。✓

**缺陷**：

1. **忙等待**浪费 CPU 时间
2. **优先级反转问题**：低优先级进程在临界区内，高优先级进程忙等待，但高优先级进程占着 CPU 让低优先级进程无法运行退出临界区，造成死锁式卡死

> 🔑 **仅适用于两个进程**，扩展到 n 个进程需要用 Lamport 面包店算法。

---

## 五、硬件同步支持

### 5.1 禁用中断

```c
while (true) {
    disable_interrupts();
    /* critical section */
    enable_interrupts();
    /* remainder */
}
```

- **原理**：单处理器上，进程切换由时钟中断触发，禁用中断则不会被切换
- **缺陷**：不适用于多处理器（其他 CPU 上的进程仍可访问共享内存）；执行效率大幅下降

### 5.2 test_and_set 指令

```c
// 原子指令定义（实际由硬件保证原子性）
boolean test_and_set(boolean *target) {
    boolean rv = *target;
    *target = TRUE;
    return rv;  // 返回旧值
}

// 用 test_and_set 实现互斥
boolean lock = FALSE;
do {
    while (test_and_set(&lock));  // 忙等待：若 lock 原来是 TRUE，说明被占用
    /* critical section */
    lock = FALSE;
    /* remainder */
} while (TRUE);
```

**工作原理**：`test_and_set` 原子地读取并将目标设为 TRUE。第一个进入的进程读到 FALSE（锁空闲），进入临界区；之后的进程读到 TRUE（锁被占），自旋等待。

**不满足有限等待**：多个进程竞争时，某个进程可能永远没有机会获得锁（无公平性保证）。

### 5.3 compare_and_swap 指令

```c
// 原子指令定义
int compare_and_swap(int *value, int expected, int new_value) {
    int temp = *value;
    if (*value == expected)
        *value = new_value;
    return temp;  // 返回旧值
}

// 实现互斥
int lock = 0;
while (true) {
    while (compare_and_swap(&lock, 0, 1) != 0);  // 期望 0，设为 1
    /* critical section */
    lock = 0;
    /* remainder */
}
```

**工作原理**：只有当 `lock == 0`（锁空闲）时，才能原子地将其设为 1（获锁），并返回 0（旧值）；若 `lock` 已为 1，CAS 不修改它，返回 1，进程继续自旋。

### 5.4 满足有限等待的 test_and_set

在 TAS 基础上增加 `waiting[n]` 数组解决公平性：

```c
boolean waiting[n];  // 初始化为 FALSE
boolean lock;        // 初始化为 FALSE

// 进程 i 的临界区协议
do {
    waiting[i] = TRUE;
    key = TRUE;
    while (waiting[i] && key)
        key = test_and_set(&lock);  // 竞争锁
    waiting[i] = FALSE;

    /* critical section */

    // 退出：找到下一个等待进程，直接让它进入（不经过 TAS 竞争）
    j = (i + 1) % n;
    while ((j != i) && !waiting[j])
        j = (j + 1) % n;
    if (j == i)
        lock = FALSE;        // 没有人等待，释放锁
    else
        waiting[j] = FALSE;  // 直接唤醒下一个进程（它不再等待）
    /* remainder */
} while (TRUE);
```

**关键思路**：退出临界区时，不是简单地释放锁，而是**直接将下一个等待进程的 `waiting[j]` 设为 FALSE**，使其从 while 循环退出，保证公平性。

**硬件指令方案的优缺点：**

|优点|缺点|
|---|---|
|适用于多处理器|仍有忙等待|
|可支持多个临界区|可能出现饥饿（基本版）|
|简单易验证|复杂进程下可能死锁|

---

## 六、互斥锁（Mutex Lock）

> 操作系统对程序员暴露的最简单同步工具，对硬件指令的封装。

```c
// 内部实现（基于 CAS）
acquire() {
    while (!available);   // 忙等待
    available = FALSE;
}

release() {
    available = TRUE;
}

// 使用方式
while (true) {
    acquire(lock);
    /* critical section */
    release(lock);
    /* remainder */
}
```

**自旋锁（Spinlock）**：基于忙等待的互斥锁。

- **优点**：不需要上下文切换，在锁持有时间极短时高效
- **缺点**：浪费 CPU 时间；不适合锁持有时间长的场景
- **适用场景**：多处理器系统中，锁持有时间短于一次上下文切换的时间

> 💡 **互斥锁 vs 二元信号量**：互斥锁**必须由加锁者解锁**；二元信号量可以由不同进程 wait 和 signal，更灵活。

---

## 七、信号量（Semaphore）⭐⭐⭐

> 信号量是最重要、最通用的同步机制，理解信号量是理解所有同步问题的基础。

### 7.1 基本定义

信号量 `S` 是一个**整型变量**，只能通过两个**原子**操作访问：

```
wait(S)   [P操作 / down() / semWait()]：
    S--;
    if S < 0: 阻塞当前进程，加入等待队列

signal(S) [V操作 / up() / semSignal()]：
    S++;
    if S <= 0: 从等待队列中取出一个进程，唤醒它
```

> ⚠️ 注意：这是**带阻塞**的实现（非忙等待），S 可以为负数！ **S 的绝对值 = 当前等待队列中的进程数。**

### 7.2 两种类型

|类型|取值范围|用途|
|---|---|---|
|**计数信号量（Counting Semaphore）**|任意非负整数|管理 n 个同类资源（初始化为 n）|
|**二元信号量（Binary Semaphore）**|仅 0 或 1|实现互斥，类似互斥锁|

### 7.3 完整实现（带阻塞队列）

```c
typedef struct {
    int value;
    struct process *list;  // 等待队列
} semaphore;

void wait(semaphore *S) {
    disable_interrupt();       // 保证原子性
    S->value--;
    if (S->value < 0) {
        add_to_queue(S->list, current_process);
        block(current_process);    // 进入阻塞态
        enable_interrupt();
    } else {
        enable_interrupt();
    }
}

void signal(semaphore *S) {
    disable_interrupt();
    S->value++;
    if (S->value <= 0) {       // 还有进程在等待
        P = remove_from_queue(S->list);
        wakeup(P);             // 将等待进程移到就绪队列
    }
    enable_interrupt();
}
```

> 🔑 **核心要点**：
> 
> - `value < 0` 说明有进程在等待，`|value|` 就是等待进程数
> - `wait` 和 `signal` 内部用**中断禁用或 CAS** 保证自身原子性，但这段"保证原子性"的代码要尽可能短
> - 在多处理器上，应用 CAS 而非中断禁用

### 7.4 信号量的两种用途

#### 用途一：互斥（Mutex）

```c
semaphore mutex = 1;   // 初始化为 1

// 进程 Pi
while (true) {
    wait(mutex);
    /* critical section */
    signal(mutex);
    /* remainder */
}
```

#### 用途二：同步（顺序控制）

```c
// 要求：语句 S1 必须在 S2 之前执行
semaphore sync = 0;   // 初始化为 0

// 进程 P1
S1;
signal(sync);         // S1 完成后，通知 P2

// 进程 P2
wait(sync);           // 等待 P1 完成 S1
S2;
```

### 7.5 强信号量 vs 弱信号量

|类型|队列策略|是否会饥饿|
|---|---|---|
|**强信号量（Strong Semaphore）**|FIFO，等待最久的先出队|不会|
|**弱信号量（Weak Semaphore）**|顺序不定|可能|

### 7.6 信号量使用时的常见错误

```c
// 错误 1：signal 和 wait 顺序颠倒 → 破坏互斥
signal(mutex);
    /* critical section */
wait(mutex);

// 错误 2：用 wait 替换 signal → 死锁
wait(mutex);
    /* critical section */
wait(mutex);   // 不释放锁，下一次自己也进不来

// 错误 3：忘记 signal → 死锁
wait(mutex);
    /* critical section */
// 忘记 signal(mutex)，其他进程永远无法进入
```

> 💡 这正是管程被发明的动机：将正确性由程序员的责任转移到语言/运行时。

---

## 八、管程（Monitor）⭐⭐⭐

### 8.1 管程的动机

信号量虽然强大，但：

1. 正确使用依赖程序员，一个 bug 可能导致死锁或破坏互斥
2. 逻辑分散在多处代码中，难以维护

管程将**共享数据及其操作封装**在一起，由编译器保证互斥，程序员只需关心逻辑。

### 8.2 管程结构

```C
monitor monitor_name{
    /* 共享变量声明 */
    int shared_var;
    condition x, y;

    function F1(...) {
        /* 操作共享变量 */
    }

    function F2(...) {
        /* 操作共享变量 */
    }

    initialization_code(...) {
        /* 初始化 */
    }
}
```

**核心特性**：

- 内部变量只能通过管程提供的函数访问（封装）
- **任何时刻管程内只有一个进程处于活跃状态**（互斥由运行时/编译器自动保证）
- 进程通过条件变量在管程内部等待/被唤醒

### 8.3 条件变量（Condition Variable）

条件变量 `x` 只支持两个操作：

```
x.wait()   ：调用进程被挂起，释放管程，加入 x 的等待队列
x.signal() ：唤醒 x 上等待的一个进程（若无人等待，则什么都不做）
```

> ⚠️ 与信号量的关键区别：
> 
> - 信号量的 `signal` 会"记住"（计数器+1），即使没有等待者也有效
> - 条件变量的 `signal` **不记录**，若无人等待则信号丢失

### 8.4 三种管程模型 ⭐⭐

当进程 P 调用 `x.signal()` 唤醒等待进程 Q 时，P 和 Q 不能同时在管程内活跃，必须有一个等待。三种模型的区别在于"谁等"：

#### Hoare 模型

```
P 调用 signal → P 立即阻塞 → Q 立即运行 → Q 退出管程 → P 恢复
```

- **优点**：Q 被唤醒时，P 设置的条件一定还满足（Q 醒来无需重新检查）
- **缺点**：P 多了一次不必要的阻塞/唤醒操作，开销大

#### Hasen 模型

```
P 调用 signal（必须在函数末尾）→ P 退出管程 → Q 运行
```

- **优点**：P 不需要额外阻塞
- **缺点**：signal 必须放在最后，使用受限

#### MESA 模型（现代主流，Java 采用）⭐

```
P 调用 signal → Q 进入管程入口等待队列 → P 继续运行 → P 退出管程 → Q 获得机会运行
```

- **优点**：灵活，`signal` 可以放在任意位置；P 无额外开销
- **重要缺陷**：Q 被唤醒时，之前满足的条件**可能已不再成立**（P 仍在运行可能改变状态）

**⚠️ MESA 模型编程范式（必须记住）**：

```java
// MESA 模型中，wait 必须放在 while 循环中！
while (!condition_satisfied) {    // 用 while，不用 if！
    x.wait();
}
// 此时条件一定满足
```

**原因**：Q 被唤醒后需要重新竞争管程入口，再次获得控制权时，之前满足的条件可能已被其他进程改变，必须重新检查。

|模型|signal 后谁继续|wait 检查用 if/while|额外开销|
|---|---|---|---|
|Hoare|被唤醒者 Q|if（条件必然满足）|P 多一次阻塞|
|Hasen|唤醒者 P（结束）|if|无|
|MESA|唤醒者 P|**while**（必须）|无|

### 8.5 用信号量实现管程

```c
semaphore mutex = 1;      // 管程入口互斥
semaphore next = 0;       // 让出管程的进程在此等待
int next_count = 0;       // 在 next 上等待的进程数

// 每个管程函数 F 的包装
wait(mutex);
    /* F 的函数体 */
if (next_count > 0)
    signal(next);         // 唤醒在 next 上等待的进程（即曾经让出的进程）
else
    signal(mutex);        // 无人等待则直接释放管程

// 条件变量 x 的实现
semaphore x_sem = 0;
int x_count = 0;

// x.wait()
x_count++;
if (next_count > 0)
    signal(next);
else
    signal(mutex);
wait(x_sem);
x_count--;

// x.signal()
if (x_count > 0) {
    next_count++;
    signal(x_sem);
    wait(next);
    next_count--;
}
```

### 8.6 Java 中的管程

Java 用 `synchronized` 关键字实现 MESA 管程：

```java
// 阻塞队列示例
class BlockingQueue<T> {
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition notFull  = lock.newCondition();  // 条件变量
    private final Condition notEmpty = lock.newCondition();

    public void put(T item) throws InterruptedException {
        lock.lock();
        try {
            while (count == capacity)  // MESA 模型：while 循环！
                notFull.await();       // x.wait()
            // 入队操作
            count++;
            notEmpty.signal();         // x.signal()
        } finally {
            lock.unlock();
        }
    }

    public T take() throws InterruptedException {
        lock.lock();
        try {
            while (count == 0)         // MESA 模型：while 循环！
                notEmpty.await();
            // 出队操作
            count--;
            notFull.signal();
            // ...
        } finally {
            lock.unlock();
        }
    }
}
```

`synchronized` + `wait()` + `notify()` / `notifyAll()` 也是 MESA 管程的另一种表达。

---

## 九、活性问题（Liveness）

同步机制如果使用不当，会导致进程永远无法推进：
### 9.1 死锁（Deadlock）

多个进程互相等待对方持有的资源，永远无法推进。

```
P0: wait(A) → wait(B) → ...
P1: wait(B) → wait(A) → ...

若 P0 持有 A，P1 持有 B：
P0 等 B，P1 等 A → 死锁
```

### 9.2 饥饿（Starvation）

某个进程永远无法获得所需资源（被其他进程反复抢占）。

- 弱信号量可能导致某进程永远不被唤醒
- 读者优先的读写问题中，写者可能饥饿

### 9.3 优先级反转（Priority Inversion）

- 高优先级进程等待低优先级进程持有的锁
- 中优先级进程不断抢占 CPU，低优先级进程无法运行退出临界区
- 结果：高优先级进程被低于自己的进程间接"阻塞"
- **解决方案**：优先级继承协议（低优先级进程暂时继承高优先级进程的优先级）

---

## 十、经典同步问题

### 10.1 生产者-消费者问题（有界缓冲区）⭐⭐

**问题**：生产者向有限缓冲区写数据，消费者从中读数据，缓冲区满时生产者等待，缓冲区空时消费者等待。

```c
// 信号量设置
semaphore mutex = 1;   // 互斥访问缓冲区
semaphore empty = n;   // 空槽数（初始化为缓冲区大小 n）
semaphore full  = 0;   // 满槽数（初始化为 0）

// 生产者
while (true) {
    produce(next_produced);
    wait(empty);          // 等待空槽
    wait(mutex);          // 进入临界区
    buffer[in] = next_produced;
    in = (in + 1) % n;
    signal(mutex);        // 退出临界区
    signal(full);         // 通知消费者有新数据
}

// 消费者
while (true) {
    wait(full);           // 等待有数据
    wait(mutex);          // 进入临界区
    next_consumed = buffer[out];
    out = (out + 1) % n;
    signal(mutex);        // 退出临界区
    signal(empty);        // 通知生产者有空槽
    consume(next_consumed);
}
```

> ⚠️ **顺序至关重要**：`wait(empty/full)` 必须在 `wait(mutex)` **之前**！ 若颠倒，一个持锁的进程可能在 `wait(empty)` 处阻塞，其他任何进程都无法获锁，死锁。

---

### 10.2 读者-写者问题 ⭐⭐

**问题**：多个读者可以同时读；写者必须独占（写时无读，读时无写）。

#### 读者优先方案

```c
semaphore rw_mutex = 1;   // 写者互斥信号量
semaphore mutex = 1;      // 保护 read_count
int read_count = 0;        // 当前读者数量

// 写者
while (true) {
    wait(rw_mutex);
    /* write */
    signal(rw_mutex);
}

// 读者
while (true) {
    wait(mutex);
    read_count++;
    if (read_count == 1)   // 第一个读者阻止写者
        wait(rw_mutex);
    signal(mutex);

    /* read */

    wait(mutex);
    read_count--;
    if (read_count == 0)   // 最后一个读者释放写者
        signal(rw_mutex);
    signal(mutex);
}
```

**问题**：只要不断有新读者来，写者可能**永远等待（写者饥饿）**。

#### 写者优先方案

增加机制：一旦有写者等待，新来的读者也需要等待。（实现更复杂，见课件图 5.23）

**两种方案都有饥饿问题**，实际系统通常采用混合策略（如读写锁）。

---

### 10.3 哲学家就餐问题 ⭐⭐

**问题**：5 位哲学家围坐，桌上 5 根筷子，每人需同时拿到左右两根筷子才能吃饭。

**朴素方案（存在死锁）**：

```c
semaphore chop[5] = {1,1,1,1,1};

void philosopher(int i) {
    while (TRUE) {
        think();
        wait(chop[i]);           // 拿左边筷子
        wait(chop[(i+1) % 5]);   // 拿右边筷子
        eat();
        signal(chop[i]);
        signal(chop[(i+1) % 5]);
    }
}
```

**死锁场景**：5 人同时拿起左边筷子，等待右边筷子，永远等不到。

**管程解决方案（无死锁）**：

```c
monitor DiningPhilosophers {
    enum {THINKING, HUNGRY, EATING} state[5];
    condition self[5];

    void pickup(int i) {
        state[i] = HUNGRY;
        test(i);                  // 尝试获取两根筷子
        if (state[i] != EATING)
            self[i].wait();       // 无法吃则等待
    }

    void putdown(int i) {
        state[i] = THINKING;
        test((i + 4) % 5);        // 通知左邻居
        test((i + 1) % 5);        // 通知右邻居
    }

    void test(int i) {
        // 当且仅当左右邻居都不在吃饭，且自己饥饿时，才可以吃
        if (state[(i+4)%5] != EATING &&
            state[i] == HUNGRY &&
            state[(i+1)%5] != EATING) {
            state[i] = EATING;
            self[i].signal();     // 唤醒自己（若自己在等待）
        }
    }
}
```

**仍可能饥饿**：某个哲学家可能因为两侧邻居交替吃饭而永远等待。

**三种防死锁方法**：

1. 最多允许 4 人同时上桌
2. 只有两根筷子都可用时才同时拿起（原子操作）
3. 非对称：奇数哲学家先拿左筷，偶数哲学家先拿右筷

---

## 十一、不同操作系统的同步实现

|操作系统|内核层|用户层|
|---|---|---|
|**Windows**|中断掩码（单CPU）/ 自旋锁（多CPU）|Dispatcher 对象：互斥体、信号量、事件、计时器|
|**Linux 2.6+**|完全可抢占；自旋锁、原子整数、读写信号量|POSIX 标准接口|
|**POSIX**|—|互斥锁 `pthread_mutex`、信号量 `sem_t`、条件变量 `pthread_cond`|
|**Java**|—|`synchronized` / `ReentrantLock` / `Semaphore` / `Condition`|

**Linux 单 CPU 的特殊处理**：在单处理器上，自旋锁被内核抢占禁用/使能取代——因为单 CPU 上"自旋"浪费时间，直接禁止抢占即可保证原子性。

---

## 十二、新型同步方案

### 12.1 事务型内存（Transactional Memory）

借鉴数据库事务：一段代码用 `atomic{...}` 标注，运行时保证其要么全部执行成功，要么完全回滚，无需显式锁。

```c
void update() {
    atomic {
        count += 10;  // 运行时自动保证原子性
    }
}
```

### 12.2 OpenMP

编译器指令方式标注临界区，由编译器自动处理同步：

```c
#pragma omp critical
{
    count += value;
}
```

### 12.3 函数式编程

通过**不可变数据**从根本上避免竞争条件——若数据从不被修改，就不需要同步。

---

## 附录：例题与解析

### 例题 1：信号量操作分析

**题目**：三个进程 P1、P2、P3 共享三个信号量 `A`（初值 0）、`B`（初值 0）、`C`（初值 1）。

```
P1: signal(C); signal(A);
P2: wait(C);   wait(A);   signal(B);   signal(C);
P3: wait(B);   signal(B);
```

P1、P2、P3 并发执行，分析：

1. 它们能否都顺利运行完毕？
2. 分析各进程的执行顺序约束。

**解析**：

初始：A=0, B=0, C=1

- P2 的第一步 `wait(C)`：C=1 > 0，通过，C 变 0
- P2 的第二步 `wait(A)`：A=0，**阻塞**
- P1 执行 `signal(C)`：C 变 1，P3 不等 C；P3 等 B，暂不影响
- P1 执行 `signal(A)`：A 变 1（或直接唤醒等待 A 的 P2）
- P2 被唤醒，`signal(B)`：B 变 1
- P3 执行 `wait(B)`：通过，B 变 0；再 `signal(B)`：B 变 1
- P2 执行 `signal(C)`：C 恢复

**结论**：

1. ✅ 三个进程都能运行完毕，不会死锁
2. 顺序约束：
    - P1 的 `signal(A)` 必须在 P2 的 `wait(A)` 之前完成（否则 P2 等待 P1）
    - P2 的 `signal(B)` 必须在 P3 的 `wait(B)` 之前完成（否则 P3 等待 P2）
    - 本质上强制了 P1 → P2 → P3 的部分顺序

---

### 例题 2：用信号量解决经典问题——变种生产者消费者

**题目**：有一个大小为 N 的循环缓冲区，M 个生产者进程和 K 个消费者进程。每个生产者每次生产**两个**数据项放入缓冲区（原子地占用两个槽），每个消费者每次消费**一个**数据项。请用信号量正确实现，并分析不会产生死锁的原因。

**解析**：

需要特别注意的是，生产者需要原子地申请两个空槽位，否则两个生产者可能各申请到一个槽，但都无法继续（类似哲学家问题）。

**错误方案**（会死锁）：

```c
// 生产者（错误）
wait(empty);  // 申请第1个槽
wait(empty);  // 申请第2个槽  ← 若此时 empty=0，与消费者死锁
wait(mutex);
// 放入两个数据
signal(mutex);
signal(full);
signal(full);
```

**正确方案**：使用额外信号量 `slots` 来解决"一次申请两个资源"问题：

```c
semaphore mutex = 1;      // 互斥访问缓冲区
semaphore empty = N;      // 空槽数
semaphore full = 0;       // 满槽数
semaphore producer_lock = 1;  // 防止生产者之间死锁

// 生产者
while (true) {
    produce two items;
    wait(producer_lock);    // 同一时刻只有一个生产者在申请槽
    wait(empty);            // 等第1个空槽
    wait(empty);            // 等第2个空槽
    signal(producer_lock);  // 已成功申请到2个槽，放开
    wait(mutex);
    // 将两个数据放入缓冲区
    signal(mutex);
    signal(full);
    signal(full);
}

// 消费者
while (true) {
    wait(full);
    wait(mutex);
    // 取出一个数据
    signal(mutex);
    signal(empty);
    consume item;
}
```

**不死锁分析**：`producer_lock` 保证了生产者申请两个槽的操作是"原子"的（宏观上），消费者不申请 `producer_lock`，所以不会构成循环等待。

---

### 例题 3：管程与条件变量

**题目**：用管程（MESA 模型）实现一个允许最多 K 个进程同时访问的资源池。进程 `acquire()` 申请一个资源，`release()` 释放一个资源，若无资源则等待。

**要求**：写出管程代码，并解释为何 wait 要放在 while 循环中。

**解答**：

```java
monitor ResourcePool {
    int available = K;   // 可用资源数
    condition not_empty; // 有资源时的条件变量

    void acquire() {
        while (available == 0) {   // MESA 必须用 while！
            not_empty.wait();
        }
        available--;
    }

    void release() {
        available++;
        not_empty.signal();        // 通知一个等待进程
    }
}
```

**为何 while 不能用 if（MESA 模型下）**：

假设 K=1，资源已被 P1 占用，P2 和 P3 都在 `not_empty` 上等待：

1. P1 调用 `release()`，`available` 变为 1，`signal()` 唤醒 P2（P2 进入入口队列）
2. **在 P2 获得管程之前**，另一个进程 P4 调用了 `acquire()` 并成功（因为此时 available=1）
3. P2 终于获得管程，此时 `available=0`！
4. 若用 `if`，P2 不再检查，直接 `available--` 变为 -1，错误！
5. 若用 `while`，P2 重新检查 `available==0`，再次 wait，正确。

---

### 例题 4：死锁分析与预防

**题目**：系统有三类资源 R1（3个）、R2（2个）、R3（2个）。四个进程的信号量操作如下：

```
P1: wait(R1); wait(R2); signal(R1); signal(R2);
P2: wait(R2); wait(R3); signal(R2); signal(R3);
P3: wait(R3); wait(R1); signal(R3); signal(R1);
P4: wait(R1); signal(R1);
```

所有信号量均初始化为资源数量（R1=3, R2=2, R3=2）。

（1）画出资源分配图，判断是否可能发生死锁。 （2）如何修改进程操作顺序以预防死锁？

**解析**：

**（1）是否可能死锁**：

P1、P2、P3 之间存在**循环等待**的可能：

- P1 持有 R1 的实例，等待 R2（若 R2 被 P2 占满）
- P2 持有 R2，等待 R3（若 R3 被 P3 占满）
- P3 持有 R3，等待 R1（若 R1 被 P1 和 P4 占满，剩余 0）

由于 R2=2（P2 最多 wait 一次），R3=2，死锁的发生依赖于具体的调度，但**不可避免地存在死锁可能性**。

**（2）预防方法**：

使用**资源排序（Resource Ordering）**：规定进程必须按资源编号从小到大申请。

```
修改 P3：原来是 wait(R3); wait(R1);
修改为：wait(R1); wait(R3);  ← 先申请编号小的
```

修改后：任何进程申请资源的顺序都是 R1 → R2 → R3，不存在 P1 等 P2、P2 等 P3、P3 等 P1 的循环，死锁被消除。

---

### 例题 5：综合题——三种同步机制比较实现

**题目**：用**三种不同方法**（互斥锁、信号量、管程）分别实现以下场景：有一个计数器 `count`，进程可以对其进行 increment（+1）或 decrement（-1），要求：

1. 操作互斥
2. `count` 永远不低于 0（即 count=0 时，decrement 需等待）

**互斥锁方案**（需要额外的条件变量支持）：

```c
mutex_lock lock;
cond_var not_zero;
int count = 0;

void increment() {
    lock.acquire();
    count++;
    cond_signal(not_zero);  // 通知等待 decrement 的进程
    lock.release();
}

void decrement() {
    lock.acquire();
    while (count == 0)
        cond_wait(not_zero, lock);  // 释放锁并等待
    count--;
    lock.release();
}
```

**信号量方案**：

```c
semaphore mutex = 1;
semaphore items = 0;  // count 的"语义信号量"

void increment() {
    wait(mutex);
    count++;  // 此处 count 只是记录值，实际保护由 items 完成
    signal(mutex);
    signal(items);  // 通知有项目可以减
}

void decrement() {
    wait(items);    // 等待 count > 0（items 信号量直接编码了 count 的值）
    wait(mutex);
    count--;
    signal(mutex);
}
```

> 注意：此方案中 `items` 的值始终等于 `count`，信号量直接充当了计数器，非常优雅。

**管程方案（MESA 模型）**：

```java
monitor Counter {
    int count = 0;
    condition not_zero;

    void increment() {
        count++;
        not_zero.signal();
    }

    void decrement() {
        while (count == 0)   // MESA：必须用 while
            not_zero.wait();
        count--;
    }
}
```

**三种方案比较**：

|方案|互斥保证|条件等待|代码复杂度|错误风险|
|---|---|---|---|---|
|互斥锁 + 条件变量|手动 acquire/release|cond_wait|中|中（忘记 release 会死锁）|
|信号量|wait/signal 配对|items 信号量隐含|低（本题）|高（顺序错误即死锁）|
|管程|自动保证|条件变量 + while|低且清晰|低（编译器保证互斥）|

---

_笔记整理自操作系统原理课件第七讲，结合《Operating System Concepts》（恐龙书）第 6-7 章_