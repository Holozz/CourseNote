> [!info] 课程信息
> **课程**：C++ 语言程序设计 | **讲师**：田海博 | **学院**：中山大学计算机学院
> **章节**：Chapter 9 — 标准模板库（STL） | **Tags**：#cpp #stl #容器 #迭代器 #算法

## 目录

- [[#一、STL 概述]]
    - [[#1.1 STL 是什么]]
    - [[#1.2 STL 的历史]]
    - [[#1.3 STL 的四大组件]]
    - [[#1.4 泛型编程思想]]
- [[#二、顺序容器]]
    - [[#2.1 顺序容器概览]]
    - [[#2.2 vector — 动态连续数组]]
    - [[#2.3 list — 双链表]]
    - [[#2.4 deque — 双端队列]]
    - [[#2.5 顺序容器的构造函数]]
    - [[#2.6 访问容器元素]]
    - [[#2.7 插入元素]]
    - [[#2.8 删除元素]]
    - [[#2.9 容器的比较操作]]
    - [[#2.10 容量操作与赋值交换]]
- [[#三、关联容器]]
    - [[#3.1 关联容器概览]]
    - [[#3.2 std：：pair]]
    - [[#3.3 map — 关联数组]]
    - [[#3.4 multimap — 允许重复键的关联数组]]
    - [[#3.5 set — 集合]]
    - [[#3.6 multiset — 允许重复的集合]]
    - [[#3.7 unordered_set 和 unordered_map — 哈希表容器]]
    - [[#3.8 关联容器复杂度总结]]
- [[#四、迭代器]]
    - [[#4.1 迭代器的概念]]
    - [[#4.2 迭代器的分类]]
    - [[#4.3 迭代器的基本操作]]
    - [[#4.4 auto 和 decltype]]
    - [[#4.5 反向迭代器原理]]
    - [[#4.6 迭代器失效规则 ⚠️]]
- [[#五、算法]]
    - [[#5.1 算法概述]]
    - [[#5.2 算法分类]]
    - [[#5.3 常用算法示例]]
    - [[#5.4 算法需要的迭代器类型一览]]
- [[#六、容器适配器]]
    - [[#6.1 什么是适配器]]
    - [[#6.2 stack — 栈]]
    - [[#6.3 queue — 队列]]
    - [[#6.4 priority_queue — 优先队列]]
    - [[#6.5 适配器操作总结]]
- [[#七、知识点速查]]

---

## 一、STL 概述

### 1.1 STL 是什么

> **通俗理解**：STL（Standard Template Library，标准模板库）就是 C++ 的"工具箱"——里面有装东西的箱子（容器）、拿东西的夹子（迭代器）、以及干活用的各种工具（算法）。你不需要自己造轮子，拿起就用。

> **严谨定义**：在 C++20 标准中，STL 指的是以下三章所定义的库：
> - **容器库**（Containers library, Chapter 26）
> - **迭代器库**（Iterators library, Chapter 27）
> - **算法库**（Algorithms library, Chapter 28）

> [!important] 关键结论
> STL 是 C++ 对计算机语言界最突出的贡献。模板编程并不容易，直到 STL 出现，泛型编程才成为主流技术。C++ 大多数语法和技术都是"拿来主义"，但 STL 是 C++ 原创的核心竞争力。

> [!warning] 术语注意
> "STL"这个称呼是历史原因导致的，目前的 C++ 标准中已经没有"STL"这个字眼——它已经融入了 C++ 标准库的正式体系中。但我们习惯上仍称之为 STL。

---

### 1.2 STL 的历史

**创始人**：亚历山大·斯特潘诺夫（Alexander Stepanov），1993 年在 HP 实验室开发出 STL 原型（当时叫"Generic C++ Components"），后被 C++ 标准委员会正式采纳。

> **Stepanov 的编程信条**：
> 
> > "程序设计是基于精确的数学训练的。"
> 
> 他的个人网站（http://www.stepanovpapers.com/）至今仍保留着他的学术论文和编程思想。

**Bjarne Stroustrup 的回忆**（C++ 之父）：

> 1993 年底，我偶然发现了一种关于容器及其应用的全新思路——这套由 Alex Stepanov 开发的宝贝叫做"STL大法"。当时 Alex 还在 HP 实验室捣鼓代码，不过这位老兄早年在贝尔实验室和 Andrew Koenig 共事时，我们俩就经常凑在一起讨论模板机制和库设计。他总像个传教士似的念叨着"模板要更通用！性能要更炸裂！"，虽然成功让我卷起了袖子优化模板机制，但谢天谢地，他没能说服我把模板改成 Ada 泛型那副德行——要不然，后来哪会有 STL 这个改变 C++ 江湖的神器问世啊！

> **参考资料**：_Evolving a language in and for the real world: C++ 1991-2006_

---

### 1.3 STL 的四大组件

STL 的设计基于四个核心抽象：

| 组件 | 英文 | 通俗理解 | 典型例子 |
|------|------|----------|----------|
| **容器** | Containers | 存放数据的"盒子" | `vector`, `list`, `map`, `set` |
| **迭代器** | Iterators | 定位数据的"指针" | `begin()`, `end()`, `rbegin()` |
| **算法** | Algorithms | 操作数据的"工具" | `sort()`, `find()`, `copy()` |
| **适配器** | Adapters | 改造接口的"转换器" | `stack`, `queue`, `priority_queue` |

> [!tip] 核心设计哲学
> **"算法与容器的分离"** 是 STL 最伟大的设计思想。算法通过迭代器操作数据，不关心数据到底在什么容器中——这种解耦使得算法可以通用于任意容器。

---

### 1.4 泛型编程思想

> **通俗理解**：泛型编程（Generic Programming）就像写一份"万能操作手册"——不针对具体车型（类型），而是根据"有轮子的东西"（概念/concept）来写操作说明。

STL 中泛型体现在三个层面：
- **容器泛化**：`vector<int>` 存 int，`vector<string>` 存 string，同一个类模板
- **迭代器泛化**：用同一套接口 `++`、`*` 遍历任意容器
- **算法泛化**：`sort()` 通过迭代器对任意容器排序

---

## 二、顺序容器

### 2.1 顺序容器概览

> **严谨定义**（C++ 标准）：Containers are objects that store other objects.（容器是存储其他对象的对象）

容器分为四种：
1. **序列式容器**（Sequence containers）：元素按线性顺序排列
2. **关联式容器**（Associative containers）：元素按键排序/查找
3. **无序关联式容器**（Unordered associative containers）：基于哈希的关联容器
4. **容器适配器**（Container adaptors）：对已有容器的接口改造

C++ 标准提供的顺序容器：

| 容器 | 底层实现 | 特性 | 头文件 |
|------|----------|------|--------|
| `vector` | 动态数组 | 尾端快速插入/删除，支持随机访问 | `<vector>` |
| `list` | 双链表 | 任意位置快速插入/删除，**不支持**随机访问 | `<list>` |
| `deque` | 指针数组（分段连续） | 两端快速插入/删除，支持随机访问 | `<deque>` |
| `array` (C++11) | 固定长度数组 | 大小固定，支持随机访问 | `<array>` |
| `forward_list` (C++11) | 单向链表 | 单向遍历，节省内存 | `<forward_list>` |

**三大核心顺序容器的底层结构对比**：

```
vector:  ■■■■■■■■■■■□  (一块连续内存，尾端扩展/收缩)
list  :  ■→■→■→■→■→■   (节点指针链，双向链接)
deque :  [■■■]→[■■■]→[■■■]  (分段连续，指针数组索引)
```

| 特性 | vector | list | deque |
|------|--------|------|-------|
| 随机访问 | ✅ O(1) | ❌ O(n) | ✅ O(1) |
| 尾端插入/删除 | ✅ O(1) | ✅ O(1) | ✅ O(1) |
| 头端插入/删除 | ❌ O(n) | ✅ O(1) | ✅ O(1) |
| 中间插入/删除 | ❌ O(n) | ✅ O(1) | ❌ O(n) |

**各容器复杂度速查**：

| 操作 | vector | list | deque | array |
|------|:------:|:----:|:-----:|:-----:|
| 随机访问 (`[]`/`at`) | O(1) | — | O(1) | O(1) |
| 尾端插入 (`push_back`) | O(1) 均摊 | O(1) | O(1) | — |
| 头端插入 (`push_front`) | — | O(1) | O(1) | — |
| 中间插入 (`insert`) | O(n) | O(1) | O(n) | — |
| 中间删除 (`erase`) | O(n) | O(1) | O(n) | — |
| 查找（遍历查找） | O(n) | O(n) | O(n) | O(n) |
| 排序 (`sort`) | O(n log n) | O(n log n)* | O(n log n) | O(n log n) |

> `*` list 有自己的 `sort()` 成员函数（O(n log n)），不能用全局 `std::sort`——因为 `std::sort` 要求随机访问迭代器，而 list 只有双向迭代器。

> [!warning] vector 的 `push_back` 是**均摊 O(1)**，不是严格 O(1)
> 当 vector 容量不够时，需要重新分配内存并把所有元素拷贝过去——这一次操作是 O(n)。但由于容量按倍数增长（通常 2 倍），均摊到每次插入仍然是 O(1)。

---

### 2.2 vector — 动态连续数组

> **通俗理解**：`vector` 就像一个会自动伸缩的数组——不够用了就自动在后面多分配一块空间。

`vector<T>` 是逻辑上连续、动态可变长的泛型数组。

**基本用法示例**：

```cpp
#include <vector>
#include <iostream>
using namespace std;

int main()
{
    vector<int> ivec = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};

    ivec.front() = 100;       // 将第 0 个元素修改为 100
    cout << "the first element: " << ivec[0] << endl;

    ivec[1] = 102;            // 通过下标赋值
    ivec.at(2) = 103;         // 通过 at() 赋值（带越界检查）

    cout << "the second element: " << ivec.at(1) << endl;
    cout << "the third element: " << ivec[2] << endl;

    ivec.back() = 999;        // 修改最后一个元素

    cout << "the last element: " << ivec[9] << endl;
}
```

输出结果：

```
100 102 103 3 4 5 6 7 8 999
```

> [!important] 关键：front/at/back 返回引用
> `front()`、`at()`、`back()` 这三个函数的返回值都是**左值引用**（`T&`），因此可以出现在赋值号的左边。这是 C++ 区别于 C 的重要特性——C 语言中函数永远返回右值。

> [!warning] operator[] vs at()
> - `operator[]`：**不检查**下标越界，越界行为未定义
> - `at(int)`：**检查**下标越界，越界时抛出 `std::out_of_range` 异常

---

### 2.3 list — 双链表

> **通俗理解**：`list` 就像一列手拉手的小朋友，每个人（节点）知道自己前面和后面是谁。可以在任意位置"插队"非常快，但要数到第 5 个小朋友必须从第一个开始数。

- 底层实现：**双向链表**
- 优点：任意位置 O(1) 插入/删除
- 缺点：不支持 `operator[]` 和 `at()`（不支持随机访问）

---

### 2.4 deque — 双端队列

> **通俗理解**：`deque` 的底层是一组连续的小数组，由一个指针数组指向它们。这使得它既能在两端快速插入/删除（不像 vector 头端插入要搬全家），又能随机访问（不像 list）。

deque 底层实现的关键：**指针数组**指向若干连续内存块，每个连续内存块有若干指针指向当前位置和边界位置。这种结构使得 deque 适合**两端频繁插入和删除**的场景。

---

### 2.5 顺序容器的构造函数

| 形式 | 说明 |
|------|------|
| `C<T> c;` | 创建空容器 |
| `C<T> c(cx);` | 创建容器 c 作为 cx 的副本（同类型且元素类型相同） |
| `C<T> c(b, e);` | 用迭代器 [b, e) 范围内的元素初始化 c（**半开区间**） |
| `C<T> c(n, t);` | 创建 c，存放 n 个值为 t 的元素 |
| `C<T> c(n);` | 创建 c，存放 n 个值初始化的元素 |
| `C<T> c({...});` 或 `C<T> c = {...};` | **C++11** 初始化列表，最为便利 |

**实例**：

```cpp
// 1) 分配指定数目，值初始化
vector<int> ivec1(10);                        // 10 个 0

// 2) 分配指定数目，指定初始值
vector<int> ivec2(10, 1);                     // 10 个 1

// 3) 用迭代器范围初始化（数组指针也可作迭代器）
int ia[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
vector<int> ivec3(ia, ia + 10);               // 值为 0~9

// 4) 复制构造
vector<int> ivec4(ivec3);                     // 与 ivec3 相同

// 5) 初始化列表（C++11）
vector<int> ivec5 = {1, 2, 3, 4};            // 值为 1~4
```

> [!warning] 注意半开区间
> `c(b, e)` 使用 **[b, e) 半开区间**——包含 b 但不包含 e。这意味着 `ivec3(ia, ia+10)` 包含 `ia[0]` 到 `ia[9]`，不包含 `ia[10]`。

---

### 2.6 访问容器元素

**直接访问**：

| 形式 | 返回值 | 备注 |
|------|--------|------|
| `c.back()` | 最后一个元素的引用 | 容器为空 → 未定义行为 |
| `c.front()` | 第 0 个元素的引用 | 容器为空 → 未定义行为 |
| `c[index]` | 下标为 index 的元素的引用 | list 不提供此操作，越界 → 未定义 |
| `c.at(index)` | 下标为 index 的元素的引用 | list 不提供，越界 → 抛出 `out_of_range` |

**通过迭代器访问**：

| 形式 | 返回值 | 备注 |
|------|--------|------|
| `c.begin()` / `c.cbegin()` | 指向第 0 个元素的迭代器 | `cbegin` 返回常迭代器（只读），C++11 |
| `c.end()` / `c.cend()` | 指向最后一个元素**下一位置**的迭代器 | 不是最后一个元素！ |
| `c.rbegin()` / `c.crbegin()` | 指向最后一个元素的**逆向**迭代器 | |
| `c.rend()` / `c.crend()` | 指向第 0 个元素**前一位置**的逆向迭代器 | |

```
正向迭代器方向  begin()  ---------------->  end()
容器元素:       [0] [1] [2] [3] ...  [n-1]   (end 指向末尾的后一位置)
逆向迭代器方向  rend()   <----------------  rbegin()
```

> [!tip] const 迭代器
> 若容器 c 为 const 对象，则这些操作返回 `const_iterator`（只读）。C++11 引入的 `cbegin()`/`cend()` 总返回常迭代器。

---

### 2.7 插入元素

| 形式 | 效果 |
|------|------|
| `c.insert(iter, t)` | 在 iter **之前**插入值为 t 的元素，返回指向新元素的迭代器 |
| `c.insert(iter, n, t)` | 在 iter 之前插入 n 个值为 t 的元素 |
| `c.insert(iter, b, e)` | 在 iter 之前插入 [b, e) 范围内的元素 |
| `c.push_back(t)` | 在尾端添加值为 t 的元素（vector、list、deque 均支持） |
| `c.push_front(t)` | 在头端添加值为 t 的元素（list、deque 支持，**vector 不支持**） |

**示例**：

```cpp
vector<int> ivec;
int iarr[] = {100, 100, 100};

// 尾端插入 1~10
for (int i = 1; i < 11; i++)
    ivec.push_back(i);
// ivec: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

// 头端插入 20
ivec.insert(ivec.begin(), 20);
// ivec: [20, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

// 在第 4 个元素之前插入两个 30
ivec.insert(ivec.begin() + 4, 2, 30);
// ivec: [20, 1, 2, 3, 30, 30, 4, 5, 6, 7, 8, 9, 10]

// 将数组全部插入到尾端
ivec.insert(ivec.end(), iarr, iarr + 3);
// ivec: [20, 1, 2, 3, 30, 30, 4, 5, 6, 7, 8, 9, 10, 100, 100, 100]
```

> [!warning] vector 不支持 push_front
> `vector` 没有 `push_front` 方法！如果要在头端插入，只能用 `insert(begin(), t)`，但这会移动所有元素（O(n)）。

---

### 2.8 删除元素

| 形式 | 效果 |
|------|------|
| `c.clear()` | 删除所有元素 |
| `c.erase(iter)` | 删除 iter 所指元素，返回被删元素**下一元素**的迭代器 |
| `c.erase(b, e)` | 删除 [b, e) 范围内的所有元素 |
| `c.pop_back()` | 删除最后一个元素（容器为空 → 未定义行为） |
| `c.pop_front()` | 删除第一个元素（容器为空 → 未定义；**vector 不支持**） |

> [!warning] erase 后迭代器失效
> 调用 `erase(iter)` 后，iter 及其之后的所有迭代器**全部失效**（对 vector 和 deque）。正确做法是使用 erase 返回的新迭代器。

**示例**：

```cpp
deque<int> ideq = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

ideq.pop_front();   // 删除第一个 → [2, 3, 4, 5, 6, 7, 8, 9, 10]
ideq.pop_back();    // 删除最后一个 → [2, 3, 4, 5, 6, 7, 8, 9]

auto iter = ideq.begin();
ideq.erase(ideq.erase(iter + 1));  // 删除第 1、第 2 个 → [2, 5, 6, 7, 8, 9]
// 注意：嵌套 erase 的执行顺序——内层先删除 iter+1，返回下一位置；
//       外层再删除返回的位置（即原来的第 2 个元素）

ideq.erase(ideq.begin(), ideq.begin() + 3);  // 删除前 3 个 → [7, 8, 9]
ideq.clear();        // 清空
```

---

### 2.9 容器的比较操作

STL 容器支持完整的六种比较运算符：`==`、`!=`、`<`、`<=`、`>`、`>=`

| 比较 | 规则 |
|------|------|
| `==` | 两个容器**元素个数相同**且**对应位置每个元素都相等** |
| `!=` | 与 `==` 相反 |
| `<`, `<=`, `>`, `>=` | **字典序**比较：若一个容器的所有元素与另一容器开头一段对应相等，则较短的容器小于另一容器；否则，第一对不相等元素的比较结果即为容器的比较结果 |

**示例**（list1: 1~10, list2: 1~5, list3: 1~5, list4: 1,2,3,4,5,12,7）：

```cpp
ilist2 == ilist3   → true（完全相同）
ilist1 < ilist2    → true（list1 前 5 个元素等于 list2，list1 更长，按字典序 list1 > list2？错！）
// 实际上：list1 开头等于 list2 全部 → 较短的 list2 < list1
// 所以 ilist1 < ilist2 → false，ilist2 < ilist1 → true
```

> [!tip] 容器比较的本质
> 比较的是元素序列的**字典序**，而非容器对象本身。这使得比较操作独立于容器的实现细节。

> [!example] 例题：容器比较
> <summary>题目：判断以下比较的结果（true 还是 false）</summary>
> 
> ```cpp
> vector<int> a = {1, 2, 3, 4, 5};
> vector<int> b = {1, 2, 3};
> vector<int> c = {1, 2, 3, 0, 5};
> // (1) a < b   (2) b < a   (3) a < c   (4) c < a
> ```

> <summary>答案</summary>
> 
> (1) `a < b` → **false**  (2) `b < a` → **true**（b 是 a 的前缀，较短者小）
> (3) `a < c` → **false**（a[3]=4 vs c[3]=0 → a > c）  (4) `c < a` → **true**
> </details>

---

### 2.10 容量操作与赋值交换

**容量操作**：

| 形式 | 说明 |
|------|------|
| `c.empty()` | 容器为空返回 true |
| `c.size()` | 返回当前元素数目，类型为 `C::size_type` |
| `c.max_size()` | 返回理论上可存放的最大元素数 |
| `c.resize(n)` | 调整大小为 n；若缩小则删除多余元素，若增大则在尾端增加值初始化元素 |
| `c.resize(n, t)` | 同 `resize(n)`，但新增元素取值为 t |

**赋值与交换**：

| 形式 | 说明 |
|------|------|
| `c1 = c2` | 删除 c1 所有元素，复制 c2 的元素（同类型） |
| `c.assign(b, e)` | 删除 c 所有元素，复制 [b, e) 范围内的元素（类型兼容即可） |
| `c.assign(n, t)` | 删除 c 所有元素，放入 n 个值为 t 的元素 |
| `c1.swap(c2)` | 交换 c1 和 c2 的所有元素（实际上是**交换名称**，O(1)） |

> [!important] swap 的高效性
> `swap` 不实际复制元素，而是交换两个容器的内部指针/数据结构。因此 swap 是 O(1) 操作！

---

## 三、关联容器

### 3.1 关联容器概览

> **通俗理解**：关联容器就像一本**字典**——你通过"词条"（key）来查找"解释"（value），而不是通过"位置"（下标）。

关联容器的核心概念：

| 术语 | 含义 | 举例 |
|------|------|------|
| **Map / Dict（映射/字典）** | Key→Value 的对应关系 | 学号 → 姓名 |
| **Key（关键字）** | 查找依据 | "05110000" |
| **Value（映射值）** | 查找结果 | "Zhang San" |
| **Pair / Item（对/项）** | 一个键值对 | (05110000, Zhang San) |
| **Set（集合）** | 仅含 key，元素无顺序、不重复 | {1, 3, 5, 7} |

C++ 标准提供的关联容器：

| 容器 | 说明 | 头文件 |
|------|------|--------|
| `map` | 按键排序的关联数组（键不可重复） | `<map>` |
| `multimap` | 支持重复键的 map | `<map>` |
| `set` | 键即值的集合（不重复） | `<set>` |
| `multiset` | 可重复的集合 | `<set>` |
| `unordered_map` | 无序的 map（哈希表实现） | `<unordered_map>` |
| `unordered_set` | 无序的 set（哈希表实现） | `<unordered_set>` |

> [!info] 底层实现
> - **有序容器**（map、set、multimap、multiset）：基于**红黑树**（平衡二叉搜索树）
> - **无序容器**（unordered_map、unordered_set）：基于**哈希表**

---

### 3.2 std::pair

`std::pair<T1, T2>`（定义于 `<utility>`）是 map 的基本单位，代表一个由类型 T1 和类型 T2 组成的有序对。

```cpp
#include <utility>

// 构造 pair
std::pair<string, int> p1("hello", 1);   // 构造函数
auto p2 = std::make_pair("hello", 1);    // make_pair（推荐）

// 访问
cout << p1.first  << endl;   // "hello"
cout << p1.second << endl;   // 1
```

---

### 3.3 map — 关联数组

> **通俗理解**：`map` 就像一个**自动排序的字典**。你往里放 (key, value)，它会自动按 key 排序，可以通过 key 快速查找。

**构造函数**：

| 形式 | 说明 |
|------|------|
| `map<K, T> m;` | 创建空 map |
| `map<K, T> m(mx);` | 复制构造 |
| `map<K, T> m(b, e);` | 用迭代器范围初始化 |
| `map<K, T> m = {{...}, {...}};` | **C++11** 初始化列表（最便利） |

**插入元素**：

```cpp
map<string, int> m = {{"hello", 1}};

// 方法 1：insert
m.insert({"h", 10});
m.insert(std::pair{"Kageyama", 180});

// 方法 2：operator[]（推荐！简洁明了）
m["me"] = 10;
```

> [!tip] 推荐使用 operator[]
> 由于插入和修改都可以用 `m[key] = value` 这种写法，既简洁又统一。如果 key 不存在则插入，如果已存在则修改。

**查找元素**：

| 形式 | 返回值 |
|------|--------|
| `m.find(k)` | 若存在 → 指向该元素的迭代器；否则 → `m.end()` |
| `m.count(k)` | k 在容器中的出现次数（对 map，只能是 0 或 1） |

**删除元素**：

| 形式 | 说明 |
|------|------|
| `m.erase(k)` | 删除键为 k 的元素，返回删除个数（0 或 1） |
| `m.erase(iter)` | 删除 iter 所指元素 |
| `m.erase(b, e)` | 删除 [b, e) 范围内的元素 |

> [!warning] map 的插入顺序
> map 中的元素**按 key 排序**存储，不是按插入顺序。在 multimap 中，如果 key 相同，则按插入顺序排列（先插入的在前面）。

> [!example] 例题：map 综合操作
> <summary>题目：分析以下代码的输出</summary>
> 
> ```cpp
> map<string, int> phoneBook;
> phoneBook["Alice"] = 12345;
> phoneBook["Bob"]   = 67890;
> phoneBook["Charlie"] = 11111;
> phoneBook["Alice"] = 99999;              // 覆盖
> auto r1 = phoneBook.insert({"David", 22222});
> auto r2 = phoneBook.insert({"Alice", 33333});
> cout << r1.second << " " << r2.second << endl;
> cout << phoneBook["Alice"] << endl;
> for (auto& e : phoneBook)
>     cout << e.first << ":" << e.second << " ";
> ```
> <summary>答案</summary>
> 
> ```
> 1 0
> 99999
> Alice:99999 Bob:67890 Charlie:11111 David:22222
> ```
> - `[]` 覆盖 Alice 的旧值；`insert` 对已存在的 Alice 返回 `second=false`
> - map 按键排序输出（字母序）
> </details>

---

### 3.4 multimap — 允许重复键的关联数组

multimap 与 map 的区别：

| 特性 | map | multimap |
|------|-----|----------|
| 下标操作 `[]` | ✅ 支持 | ❌ 不支持 |
| `insert` | 键已存在则**不插入** | 每次调用都新增元素（相同键相邻存放） |
| `erase(k)` | 删除该键的元素 | 删除该键**所有**元素，返回删除个数 |
| `count(k)` | 返回 0 或 1 | 返回实际出现次数 |
| `find(k)` | 指向该元素的迭代器 | 指向该键**第一个**元素的迭代器 |

**遍历 multimap 中同一键的所有元素**：

```cpp
// 方法 1：count + find
auto cnt = m.count(key);
auto iter = m.find(key);
for (int i = 0; i < cnt; i++, iter++)
    cout << iter->second << endl;

// 方法 2：lower_bound + upper_bound
for (auto it = m.lower_bound(key); it != m.upper_bound(key); ++it)
    cout << it->second << endl;

// 方法 3：equal_range（最优雅）
auto range = m.equal_range(key);
for (auto it = range.first; it != range.second; ++it)
    cout << it->second << endl;
```

**界限操作**：

| 形式 | 说明 |
|------|------|
| `m.lower_bound(k)` | 返回指向第一个键 **>= k** 的元素的迭代器 |
| `m.upper_bound(k)` | 返回指向第一个键 **> k** 的元素的迭代器 |
| `m.equal_range(k)` | 返回包含 `lower_bound` 和 `upper_bound` 的 pair |

---

### 3.5 set — 集合

> **通俗理解**：`set` 就像一个**自动排序且不重复的袋子**。放进去的东西会自动排好序，重复的东西放不进去。

set 与 map 的对比：

| 特性 | map | set |
|------|-----|-----|
| 元素类型 | `pair<const K, T>` | 即 key 本身 |
| 下标操作 `[]` | ✅ | ❌ |
| `value_type` | `pair` 类型 | 与 `key_type` 相同 |
| `mapped_type` | 有 | **没有定义** |
| 主要用途 | 字典/映射 | 去重 + 排序 |

```cpp
std::set<int> s = {1, 2, 3, 4};

auto iter1 = s.find(3);
auto iter2 = s.insert(3);  // 返回指向已有 3 的迭代器，没有实际插入
auto b = (iter1 == iter2); // b == true！插入失败但返回已有的迭代器
```

> [!warning] set 的 insert 返回值
> `set::insert` 返回 `pair<iterator, bool>`——iterator 指向元素（已有或新插入），bool 指示是否真的发生了插入。

---

### 3.6 multiset — 允许重复的集合

`multiset` 与 `set` 的关系，就像 `multimap` 与 `map` 的关系——允许重复元素。

| 特性 | set | multiset |
|------|:---:|:--------:|
| 重复元素 | ❌ | ✅ |
| `insert` 返回值 | `pair<iter, bool>` | 仅 `iter`（总是插入成功） |
| `erase(k)` | 删除该键，返回 0 或 1 | 删除该键**所有**元素，返回删除个数 |
| `count(k)` | 0 或 1 | 实际出现次数 |

```cpp
multiset<int> ms = {3, 1, 2, 1, 3, 1};
// 内部自动排序：{1, 1, 1, 2, 3, 3}

ms.count(1);  // 3（出现了 3 次）
ms.erase(1);  // 删除全部 3 个 1，返回 3
```

---

### 3.7 unordered_set 和 unordered_map — 哈希表容器

> **通俗理解**：有序容器（map/set）像一本按拼音排序的字典——查找时按目录一页页翻。无序容器（unordered_map/set）像一个**有编号的储物柜**——你算一下"hash 值"就知道去哪个柜子找，不用一个一个翻。

#### 3.7.1 核心原理

**底层实现**：**哈希表**（Hash Table）——由一个桶数组 + 哈希函数 + 冲突解决（通常用链地址法）组成。

```
插入 "Alice" → hash("Alice") = 42 → 放入桶 #42
查找 "Alice" → hash("Alice") = 42 → 去桶 #42 找
```

#### 3.7.2 复杂度

| 操作 | 平均 | 最坏 |
|------|:---:|:---:|
| 查找 (`find`) | **O(1)** | O(n) |
| 插入 (`insert`) | **O(1)** | O(n) |
| 删除 (`erase`) | **O(1)** | O(n) |

> [!warning] 最坏情况 O(n)
> 当哈希函数不好或数据特殊，大量元素冲突到同一个桶时，退化成链表遍历 → O(n)。好的哈希函数 + 合适的负载因子（load factor）可以极大降低冲突概率。

#### 3.7.3 基本用法

```cpp
#include <unordered_map>
#include <unordered_set>

// unordered_map
unordered_map<string, int> um;
um["hello"] = 1;
um.insert({"world", 2});

auto it = um.find("hello");
if (it != um.end())
    cout << it->first << ": " << it->second << endl;  // hello: 1

// unordered_set
unordered_set<int> us = {3, 1, 4, 1, 5};
// 元素不重复，不保证顺序：可能是 {5, 1, 3, 4}
us.insert(9);   // O(1) 平均

if (us.find(3) != us.end())
    cout << "found!" << endl;   // O(1) 平均
```

#### 3.7.4 自定义哈希函数

```cpp
// 如果要存自定义类型，需要提供哈希函数和相等比较
struct Point {
    int x, y;
    bool operator==(const Point& other) const {
        return x == other.x && y == other.y;
    }
};

// 自定义哈希
struct PointHash {
    size_t operator()(const Point& p) const {
        return hash<int>()(p.x) ^ (hash<int>()(p.y) << 1);
    }
};

unordered_set<Point, PointHash> points;
```

#### 3.7.5 有序 vs 无序容器选择指南

| 需求 | 选择 |
|------|------|
| 需要元素**有序**遍历 | `map` / `set` |
| 需要**范围查询**（`lower_bound`/`upper_bound`） | `map` / `set` |
| **只关心快速查找**，不关心顺序 | `unordered_map` / `unordered_set` |
| 数据量极大且哈希函数好 | `unordered_map` / `unordered_set`（O(1) vs O(log n)） |
| 需要稳定的迭代器（插入不使其他迭代器失效） | `map` / `set`（红黑树插入不会使其他迭代器失效） |

> [!tip] 经验法则
> 默认用 `unordered_map`/`unordered_set`（O(1) 更快）；当你发现需要有序遍历或范围查询时，再换 `map`/`set`。

> [!example] 例题：set vs unordered_set 选择
> <details>
> <summary>题目：以下场景用 `set` 还是 `unordered_set`？</summary>
> 
> (1) 需要从小到大顺序输出所有元素
> (2) 只需频繁判断"某值是否存在"，数据量 100 万
> (3) 需要快速找到"值 >= 50 的第一个元素"
> (4) 插入大量元素时不想影响已有迭代器
> </details>
> <details>
> <summary>答案</summary>
> 
> (1) **set**（有序遍历） (2) **unordered_set**（O(1) 更快）
> (3) **set**（`lower_bound()` 仅有序容器支持） (4) **set**（rehash 会使无序容器迭代器全失效）
> </details>

---

### 3.8 关联容器复杂度总结

| 容器 | 底层 | 查找 | 插入 | 删除 | 有序？ | 键重复？ |
|------|------|:---:|:---:|:---:|:---:|:---:|
| `map` | 红黑树 | O(log n) | O(log n) | O(log n) | ✅ | ❌ |
| `multimap` | 红黑树 | O(log n) | O(log n) | O(log n) | ✅ | ✅ |
| `set` | 红黑树 | O(log n) | O(log n) | O(log n) | ✅ | ❌ |
| `multiset` | 红黑树 | O(log n) | O(log n) | O(log n) | ✅ | ✅ |
| `unordered_map` | 哈希表 | **O(1)** | **O(1)** | **O(1)** | ❌ | ❌ |
| `unordered_set` | 哈希表 | **O(1)** | **O(1)** | **O(1)** | ❌ | ❌ |

> 有序容器的 O(log n) 来自红黑树的高度；无序容器的 O(1) 来自哈希表的直接索引（均平均情况，最坏 O(n)）。

---

## 四、迭代器

### 4.1 迭代器的概念

> **通俗理解**：迭代器（Iterator）就是**被包装了的指针**。它比指针更安全、更通用，能遍历各种容器而无需关心容器的内部实现。

> **严谨定义**：迭代器是每种容器各自定义的一个或多个不同于容器的类（如 `vector<T>::iterator`），它主要用于访问、修改、增加、删除容器中的元素。

**为什么需要迭代器？**
- 不同容器的内部结构不同（数组/链表/树/哈希表），不能直接用指针访问
- 迭代器提供**统一的接口**（`++`、`*`、`==`）来遍历所有容器
- 算法通过迭代器操作容器，实现**算法与容器的解耦**

---

### 4.2 迭代器的分类

按照功能从弱到强，C++ 定义了六种迭代器：

| 类别 | 功能 | 说明 |
|------|------|------|
| **输入迭代器** (InputIterator) | 读取、`++`（只向前） | 一次遍历，如从输入流读取 |
| **输出迭代器** (OutputIterator) | 写入、`++`（只向前） | 一次遍历，如写入输出流 |
| **前向迭代器** (ForwardIterator) | 读取/写入、`++` | 可多次遍历，如 `forward_list` 的迭代器 |
| **双向迭代器** (BidirectionalIterator) | + `--` | 可前后移动，如 `list` 的迭代器 |
| **随机访问迭代器** (RandomAccessIterator) | + `+n`, `-n`, `[]`, `<` 等 | 任意跳转，如 `vector`、`deque` 的迭代器 |
| **连续迭代器** (ContiguousIterator) | 内存连续 | **C++17** 新增，如 `vector`、`array` 的迭代器 |

```cpp
vector<int>::iterator it1;          // 随机访问迭代器
list<int>::iterator it2;            // 双向迭代器
forward_list<int>::iterator it3;    // 前向迭代器
```

---

### 4.3 迭代器的基本操作

```cpp
#include <iostream>
#include <vector>
using std::vector;

int main()
{
    vector<int> ivec(10, 2);                   // 10 个值为 2 的元素
    vector<int>::iterator iter;                 // 声明正向迭代器
    vector<int>::reverse_iterator riter;        // 声明反向迭代器

    iter = ivec.begin();       // 指向第 0 个元素
    *iter += 10;               // 第 0 个元素：2 + 10 = 12

    riter = ivec.rend();       // rend 指向第 0 个元素的前一位置
    *(riter - 1) += 10;        // 第 0 个元素：12 + 10 = 22

    iter = ivec.end();         // end 指向最后一个元素的下一位置
    *(iter - 1) = 100;         // 最后一个元素改为 100

    riter = ivec.rbegin();     // rbegin 指向最后一个元素
    *riter -= 20;              // 最后一个元素：100 - 20 = 80
}
// 最终：22, 2, 2, 2, 2, 2, 2, 2, 2, 80
```

```
正向：   begin() →  [0] [1] [2] ... [n-1]  ← end()
反向：   rend()  ←  [0] [1] [2] ... [n-1]  → rbegin()
```

> [!tip] 迭代器操作的本质
> 迭代器重载了指针运算符（`*`、`++`、`--`、`==`、`!=` 等），使得它可以像指针一样使用。但迭代器的 `++` 不是简单的地址递增，而是**移动到容器中的下一个元素**。

> [!example] 例题：vector 迭代器操作
> <summary>题目：写出以下程序的输出</summary>
> 
> ```cpp
> vector<int> v = {5, 10, 15, 20, 25};
> auto it = v.begin();
> *it = 100;  *(it + 2) = 200;  *(v.end() - 1) = 300;
> for (auto x : v) cout << x << " ";  cout << endl;
> auto rit = v.rbegin();
> *rit += 50;  *(rit + 1) += 50;
> for (auto x : v) cout << x << " ";  cout << endl;
> ```
> <summary>答案</summary>
> 
> ```
> 100 10 200 20 300
> 100 10 250 70 300
> ```
> **解析**：`*it`→v[0]=100；`*(it+2)`→v[2]=200；`*(end()-1)`→v[4]=300（end 指向末尾后一位）；`*rit`→v[4]=350（rbegin 指向尾）；`*(rit+1)`→v[3]=70


---

### 4.4 auto 和 decltype

C++11 引入的类型推导极大简化了迭代器的使用：

```cpp
vector<int> ivec(10, 2);

// 传统写法：冗长
for (vector<int>::iterator it = ivec.begin(); it != ivec.end(); ++it)
    cout << *it << ",";

// C++11 auto：简洁
for (auto it = ivec.begin(); it != ivec.end(); ++it)
    cout << *it << ",";

// C++11 范围 for：最简洁
for (auto& val : ivec)
    cout << val << ",";
```

**auto vs decltype**：

| 关键字 | 作用 | 示例 |
|--------|------|------|
| `auto` | 从初始化器**推导**变量类型 | `auto x = 10;` → x 为 int |
| `decltype` | 从表达式**获取**类型（不计算表达式） | `decltype(ivec.begin()) iter;` → iter 类型为该表达式类型 |

```cpp
decltype(ivec.begin()) iter;  // 声明迭代器而无需写出全名
```

> [!tip] 灵活使用 auto 和 decltype
> 可以减少程序对模板实参的依赖，提升程序的通用性和可读性。

---

### 4.5 反向迭代器原理（选讲）

反向迭代器的核心思想：**`++` 操作实际执行 `--` 指针**。

```cpp
template <typename T>
class ReverseIterator {
    T* p;
public:
    ReverseIterator(T* x) : p(x) {}
    ReverseIterator& operator++() { --p; return *this; }        // ++ → 指针前移
    ReverseIterator operator++(int) {                           // 后缀 ++
        ReverseIterator tmp(*this);
        operator++();
        return tmp;
    }
    bool operator==(const ReverseIterator& rhs) const { return p == rhs.p; }
    bool operator!=(const ReverseIterator& rhs) const { return p != rhs.p; }
    T& operator*() { return *p; }
};
```

> [!important] 关键理解
> 反向迭代器的 `++` 是向容器的**前一个元素**移动。因此：
> - `rbegin()` 指向最后一个元素，`++` 后指向倒数第二个
> - `rend()` 指向第一个元素的前一位置，被视为"终点"
> - 遍历时仍用 `++`，但实际效果是从尾到头

---

### 4.6 迭代器失效规则 ⚠️

迭代器在使用中可能因容器内部结构变化而**失效**——继续使用失效的迭代器是**未定义行为**。这是 STL 最常见的 bug 来源之一。

**各容器迭代器失效规则**：

| 容器 | `push_back` | `insert` | `erase` | `clear` |
|------|:----------:|:--------:|:-------:|:-------:|
| **vector** | 若触发 reallocation → **全部失效**；否则仅 `end()` | 插入点及之后全部失效 | 被删元素及之后**全部失效** | 全部失效 |
| **deque** | 全部迭代器有效，但 `end()` 失效 | 全部迭代器可能失效 | 被删元素及之后全部失效 | 全部失效 |
| **list** | 不失效 | 不失效 | 仅被删元素失效 | 全部失效 |
| **map/set** | — | 不失效 | 仅被删元素失效 | 全部失效 |
| **unordered_map/set** | 若触发 rehash → 全部失效；否则不失效 | 同左 | 仅被删元素失效 | 全部失效 |

> [!important] 核心规律
> - **连续存储**的容器（vector、deque）：插入/删除会使后续迭代器失效（因为元素被搬移了）
> - **节点存储**的容器（list、map、set）：插入不使其他迭代器失效，删除仅使被删那个失效

**修复模式**：

```cpp
// ❌ 错误：erase 后继续 ++it
for (auto it = v.begin(); it != v.end(); ++it)
    if (should_delete(*it))
        v.erase(it);                 // it 失效，++it 未定义行为！

// ✅ 正确：用 erase 返回的迭代器
for (auto it = v.begin(); it != v.end(); /* 空 */) {
    if (should_delete(*it))
        it = v.erase(it);            // erase 返回下一个有效位置
    else
        ++it;
}
```

> [!example] 例题：erase 后迭代器失效
> <summary>题目：以下代码有什么问题？如何修正？</summary>
> 
> ```cpp
> vector<int> v = {10, 20, 30, 40, 50};
> for (auto it = v.begin(); it != v.end(); ++it)
>     if (*it == 30) v.erase(it);
> ```
> <summary>答案</summary>
> 
> `erase(it)` 后 it 失效，`++it` 是未定义行为。修正：`it = v.erase(it);` 并在 else 分支才 `++it`。
> 
> ```cpp
> for (auto it = v.begin(); it != v.end(); /* 空 */) {
>     if (*it == 30) it = v.erase(it);
>     else ++it;
> }
> ```

---

## 五、算法

### 5.1 算法概述

STL 算法库（`<algorithm>` 和 `<numeric>`）提供了 100+ 通用算法，它们通过**迭代器**操作数据，与容器类型无关。

> [!important] 核心设计
> 算法不关心数据在什么容器里，只关心迭代器能提供什么操作。算法需要的迭代器能力越弱，适用的容器范围就越广。

### 5.2 算法分类

| 类别 | 典型算法 | 头文件 |
|------|----------|--------|
| **非修改序列操作** | `find`, `count`, `search`, `equal`, `all_of`, `any_of`, `none_of` | `<algorithm>` |
| **修改序列操作** | `copy`, `fill`, `transform`, `replace`, `reverse`, `remove`, `unique` | `<algorithm>` |
| **排序和相关** | `sort`, `stable_sort`, `partial_sort`, `nth_element`, `binary_search`, `lower_bound`, `upper_bound`, `merge` | `<algorithm>` |
| **堆操作** | `make_heap`, `push_heap`, `pop_heap`, `sort_heap` | `<algorithm>` |
| **集合操作** | `set_union`, `set_intersection`, `set_difference` | `<algorithm>` |
| **数值算法** | `accumulate`, `inner_product`, `partial_sum`, `adjacent_difference`, `iota` | `<numeric>` |

### 5.3 常用算法示例

```cpp
#include <algorithm>
#include <numeric>
#include <vector>
using namespace std;

vector<int> v = {3, 1, 4, 1, 5, 9, 2, 6};

// —— 查找 ——
auto it = find(v.begin(), v.end(), 5);         // 线性查找 O(n)
int cnt = count(v.begin(), v.end(), 1);        // 计数，cnt = 2

// —— 排序 ——
sort(v.begin(), v.end());                      // 升序 O(n log n)
sort(v.begin(), v.end(), greater<int>());      // 降序，传入比较器

// —— 二分查找（要求已排序！）——
bool exist = binary_search(v.begin(), v.end(), 4);       // O(log n)
auto lb = lower_bound(v.begin(), v.end(), 4);            // 第一个 >= 4
auto ub = upper_bound(v.begin(), v.end(), 4);            // 第一个 > 4

// —— 修改 ——
reverse(v.begin(), v.end());                   // 翻转
fill(v.begin(), v.begin() + 3, 0);             // 填充 [0,3) 为 0
replace(v.begin(), v.end(), 1, 99);            // 全部 1 替换为 99

// —— 去重（配合 erase，经典 "erase-remove" 惯用法）——
sort(v.begin(), v.end());
auto last = unique(v.begin(), v.end());         // 把重复元素移到末尾
v.erase(last, v.end());                         // 真正删除

// —— 变换 ——
vector<int> v2(v.size());
transform(v.begin(), v.end(), v2.begin(),
          [](int x) { return x * x; });         // v2 中每个元素是 v 中对应元素的平方

// —— 数值 ——
int sum = accumulate(v.begin(), v.end(), 0);    // 求和，初始值 0
```

> [!warning] 不是所有容器都能用全局 `std::sort`
> `std::sort` 要求**随机访问迭代器**，所以 `list` 和 `forward_list` 不能用！它们有自己的成员函数 `sort()`：
> ```cpp
> list<int> l = {3, 1, 2};
> l.sort();                        // ✅ 成员函数 sort
> // sort(l.begin(), l.end());     // ❌ 编译错误！
> ```

### 5.4 算法需要的迭代器类型一览

| 算法 | 最低迭代器要求 | 复杂度 |
|------|:-----------:|:-----:|
| `find`, `count` | 输入迭代器 | O(n) |
| `copy`, `transform` | 输入 + 输出迭代器 | O(n) |
| `fill` | 前向迭代器 | O(n) |
| `replace`, `reverse` | 双向迭代器 | O(n) |
| `sort`, `nth_element` | **随机访问**迭代器 | O(n log n) |
| `binary_search`, `lower_bound` | **随机访问** 或 **双向**迭代器 | O(log n) |
| `accumulate` | 输入迭代器 | O(n) |

> [!tip] 记住这个规律
> 算法对迭代器的要求越弱，能用的容器就越多。`find` 只要输入迭代器 → 所有容器都能用。`sort` 要随机访问 → 只有 vector/deque/array 能用。


## 六、容器适配器

### 6.1 什么是适配器

容器适配器是对已有容器的**接口改造**——底层用现成的容器，但暴露不同的操作接口，实现受限但专门化的数据结构。

> **通俗理解**：底层容器像一个万能工具箱，适配器则像一个"专用工具套装"——只给你需要用到的几样工具，帮你避免误操作。

### 6.2 stack — 栈

后进先出（LIFO），默认底层容器为 `deque`。

```cpp
#include <stack>
stack<int> stk;

stk.push(1);         // 入栈
stk.push(2);
stk.push(3);
stk.top();           // 查看栈顶 → 3
stk.pop();           // 出栈（不返回值！）
stk.size();          // 元素个数
stk.empty();         // 是否为空
```

> [!warning] `pop()` 不返回值！
> 这是 C++ STL 的一个经典设计决策——`pop()` 返回 `void`，要获取值请先用 `top()`。

### 6.3 queue — 队列

先进先出（FIFO），默认底层容器为 `deque`。

```cpp
#include <queue>
queue<int> q;

q.push(1);           // 入队（队尾）
q.push(2);
q.push(3);
q.front();           // 查看队首 → 1
q.back();            // 查看队尾 → 3
q.pop();             // 出队（队首出队）
```

### 6.4 priority_queue — 优先队列

每次出队的是**优先级最高**的元素（默认大顶堆，最大元素优先），默认底层容器为 `vector`。

```cpp
#include <queue>
priority_queue<int> pq;

pq.push(3);
pq.push(1);
pq.push(5);
pq.top();            // 查看最大的 → 5
pq.pop();            // 移除 5
pq.top();            // 现在最大的 → 3

// 小顶堆：最小元素优先
priority_queue<int, vector<int>, greater<int>> min_pq;
min_pq.push(3);
min_pq.push(1);
min_pq.push(5);
min_pq.top();        // 最小的 → 1
```

### 6.5 适配器操作总结

| 适配器 | 入 | 出 | 查看 | 底层默认 | 特点 |
|--------|----|----|------|----------|------|
| `stack` | `push()` | `pop()` | `top()` | `deque` | LIFO |
| `queue` | `push()` | `pop()` | `front()` / `back()` | `deque` | FIFO |
| `priority_queue` | `push()` | `pop()` | `top()` | `vector` | 按优先级（堆） |

> [!tip] 可以换底层容器
> ```cpp
> stack<int, vector<int>> stk;           // 用 vector 做底层
> queue<int, list<int>> q;               // 用 list 做底层（deque 更常见）
> ```

---

## 七、知识点速查

| 知识点 | 核心内容 | 要点提示 |
|--------|----------|----------|
| **STL 定义** | 容器库 + 迭代器库 + 算法库 | C++20 标准中的三章 |
| **STL 创始人** | Alexander Stepanov (1993) | "程序设计是基于精确的数学训练" |
| **vector** | 动态连续数组，`<vector>` | 支持随机访问，不支持 `push_front`；`push_back` 均摊 O(1) |
| **list** | 双向链表，`<list>` | 不支持随机访问（`[]`/`at`），不能用 `std::sort`（用 `l.sort()`） |
| **deque** | 分段连续的双端队列，`<deque>` | 两端快速插入，支持随机访问 |
| **顺序容器查找** | vector/list/deque 查找 | 均为 **O(n)** 遍历查找（它们不是为查找设计的） |
| **front()/back()** | 返回首/尾元素的**引用** | 容器为空 → UB |
| **operator[] vs at()** | `[]` 不检查越界，`at()` 检查并抛异常 | vector 和 deque 支持，list 不支持 |
| **insert(iter, val)** | 在 iter **之前**插入 | 返回指向新元素的迭代器 |
| **erase(iter)** | 删除 iter 所指元素 | 返回下一有效迭代器 |
| **迭代器失效** | vector/deque 连续存储→易失效；list/map/set 节点存储→仅被删者失效 | 最易出 bug 的地方！ |
| **容器比较** | `==` 和字典序 `<` | 较短者为前缀 → 较短者小 |
| **swap(c1, c2)** | O(1) 交换名称 | 不复制元素 |
| **map** | 有序关联数组，红黑树 | `[]` 可覆盖，`insert` 不覆盖重复键；查找 **O(log n)** |
| **set** | 有序不重复集合，红黑树 | 无 mapped_type；查找 **O(log n)** |
| **multimap/multiset** | 允许重复键/元素 | 不支持 `[]`，`equal_range` 获取同键范围 |
| **unordered_map/set** | 无序，哈希表 | 查找 **O(1) 平均**、O(n) 最坏；无 `lower_bound`；rehash 使迭代器全失效 |
| **有序 vs 无序选择** | 需要排序/范围查询 → map/set；只需快速查找 → unordered | 默认优先 unordered（O(1)），需要排序再换 |
| **迭代器分类** | Input→Output→Forward→Bidirectional→Random Access→Contiguous | 从弱到强；算法对迭代器要求越弱，适用容器越广 |
| **auto / decltype** | auto 推导类型，decltype 获取类型 | C++11，简化迭代器声明 |
| **反向迭代器** | `++` 实际执行 `--` 指针 | rbegin→rend 从尾到头遍历 |
| **半开区间** | `[begin, end)` | end 指向末尾的下一位置 |
| **stack/queue** | LIFO / FIFO 适配器 | 默认 deque 底层；`pop()` 不返回值 |
| **priority_queue** | 堆适配器 | 默认大顶堆；`greater<int>` 改小顶堆 |
| **常用算法** | `find`/`count`/`sort`/`binary_search`/`lower_bound`/`unique`/`accumulate` | `<algorithm>` + `<numeric>` |
| **list 不能用 std::sort** | list 只有双向迭代器 | 用成员函数 `l.sort()` |

> [!tip] 核心思想总结
> STL 的精髓在于 **"算法与容器的分离"**——通过迭代器这一抽象层，算法不再与具体容器绑定，实现了真正的泛型编程。理解这一点就理解了 STL 设计的灵魂。

---

> **参考**：C++20 标准草案 Chap 26-28 | 中山大学 MOOC 课程组 | The Standard Template Library (Stepanov, 1993)
