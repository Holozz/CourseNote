---
banner: "![[8d2f5358de8d2f5358de.jpg]]"
---

> [!info] 课程信息 中山大学计算机学院 · 田海博主讲  
> Tags: #CPP #模板 #泛型编程 #函数模板 #类模板 #非类型参数 #数组引用

## 目录

- [[#一、泛型编程（Generic Programming）]]
    - [[#1.1 什么是泛型编程]]
    - [[#1.2 编译时多态（静态多态）]]
    - [[#1.3 实例化（Instantiation）]]
- [[#二、函数模板（Function Template）]]
    - [[#2.1 问题引入：冗余的重载]]
    - [[#2.2 函数模板的定义与使用]]
    - [[#2.3 模板实参推断（Argument Deduction）]]
    - [[#2.4 隐式类型转换的禁用]]
    - [[#2.5 显式全特化（Explicit Specialization）]]
    - [[#2.6 模板重载与重载决议]]
- [[#三、类模板（Class Template）]]
    - [[#3.1 类模板的定义]]
    - [[#3.2 类模板外定义成员函数]]
    - [[#3.3 类模板的实例化]]
    - [[#3.4 模板的文件组织]]
- [[#四、非类型模板形参（Non-type Template Parameter）]]
    - [[#4.1 两类模板形参]]
    - [[#4.2 非类型形参的约束]]
    - [[#4.3 完整示例：数组实现的栈]]
- [[#五、数组的引用与模板推导]]
    - [[#5.1 数组引用做形参]]
    - [[#5.2 模板自动推导数组长度]]
    - [[#5.3 对比：传统指针退化的方式]]
- [[#六、例题精选]]
- [[#七、知识点速查总结]]

---

## 一、泛型编程（Generic Programming）

### 1.1 什么是泛型编程

> **通俗理解**：泛型编程就像"万能模具"——你设计一个模具，倒入不同的材料（数据类型），就能造出不同的产品（实例代码）。模具本身不关心材料是什么，只管结构。

> **严谨定义**：**泛型编程（Generic Programming）** 是一种编程范式，它使得算法和数据结构独立于任何特定数据类型。不同类型的对象可以被**相同的代码**操作，数据类型本身被参数化。

**现实类比**：

|场景|非泛型|泛型|
|---|---|---|
|排序|写 `sortInt`、`sortDouble`、`sortString`... |写一个 `sort<T>`，编译器根据 T 自动生成对应版本|
|容器|`IntStack`、`DoubleStack`、`StringStack`... |写一个 `Stack<T>`，可容纳任意类型|

在 C++ 中，泛型编程通过 **模板（template）** 实现，包括：

- **函数模板（Function Template）**：参数化的是函数
- **类模板（Class Template）**：参数化的是类

---

### 1.2 编译时多态（静态多态）

> **模板的本质**：模板是一种**编译时多态（静态多态）**——类型参数化，多态行为在**编译期间**确定，没有运行时开销。

与第 6 章讲的"虚函数运行时多态"对比：

||编译时多态（模板）|运行时多态（虚函数）|
|---|---|---|
|**实现方式**|模板（template）|虚函数（virtual）+ 继承|
|**绑定时机**|编译期|运行期|
|**性能**|零运行时开销|需查虚函数表（vtable），有间接调用开销|
|**灵活性**|类型在编译期必须确定|可以在运行时决定实际类型|
|**典型场景**|通用算法、容器|插件系统、扩展接口|

> 💡 **一句话总结**：模板侧重"同一套代码处理不同数据类型"；虚函数侧重"同一套接口表现出不同行为"。二者互补而非互斥——实际项目中往往同时使用（如泛型容器 + 多态元素）。

---

### 1.3 实例化（Instantiation）

> **实例化（Instantiation）**：由编译器将通用 **模板代码** 转换为具体类型版本的 **实例代码** 的过程。

关键理解：

- **模板本身不是代码**，它是"代码生成器"——只有模板的声明/定义存在时，编译器才持有蓝图
- **只有被使用了**，模板才被实例化（编译期按需生成）
- **不同类型的实例化产生不同的具体代码**，就像你写了多个手工版本一样

```cpp
// 模板（蓝图）
template <typename T>
T max(T a, T b) { return a > b ? a : b; }

// 使用模板时，编译器自动生成：
// max(int, int)    —— 一份代码
// max(double, double) —— 另一份代码
// max(string, string) —— 再一份代码
```

> ⚠️ **易错点**：编译器必须能看到模板的**完整定义**（不仅是声明）才能实例化。这是模板的文件组织与普通函数不同的关键原因（见 3.4 节）。

---

## 二、函数模板（Function Template）

### 2.1 问题引入：冗余的重载

考虑交换两个变量的值的 `Swap` 函数：

```cpp
void Swap(int &v1, int &v2) {
    int temp; temp = v1; v1 = v2; v2 = temp;
}

void Swap(double &v1, double &v2) {
    double temp; temp = v1; v1 = v2; v2 = temp;
}

void Swap(string &v1, string &v2) {
    string temp; temp = v1; v1 = v2; v2 = temp;
}
```

**三个函数除了类型名不同，代码完全一致。** 这就是"代码重复"的经典场景，也是函数模板的用武之地。

> 💡 **核心思路**：既然代码逻辑相同，只有类型不同，为什么不把"类型"本身变成一个参数呢？

---

### 2.2 函数模板的定义与使用

**一般形式**：

```cpp
template <模板形参表>
返回值类型 函数名(形式参数列表) {
    函数体语句
}
```

- `模板形参表` 不能为空
- 形参表中出现的每个模板形参，必须在函数形式参数列表中**使用到**（否则编译器无法推断）

**模板形参表的形式**：

```cpp
template <typename T1, typename T2, ...>
```

其中 `typename` 也可以写作 `class`，二者在此处**完全等价**（但推荐用 `typename` 表意更明确）。

**Swap 函数模板**：

```cpp
template <typename T>
void Swap(T &v1, T &v2) {
    T temp;
    temp = v1;
    v1 = v2;
    v2 = temp;
}
```

这一个模板，能取代前面三个手动重载版本！

**使用方式**：与普通函数调用一样，不需要额外的语法。

```cpp
int main() {
    string s1("rabbit"), s2("bear");
    int iv1 = 3, iv2 = 5;
    double dv1 = 2.8, dv2 = 8.5;

    Swap(s1, s2);     // 调用 Swap(string&, string&)
    Swap(iv1, iv2);   // 调用 Swap(int&, int&)
    Swap(dv1, dv2);   // 调用 Swap(double&, double&)
}
```

---

### 2.3 模板实参推断（Argument Deduction）

调用函数模板时，编译器经历两个步骤：

**第一步：模板实参推断（Template Argument Deduction）**

编译器根据函数调用中的**实参类型**，确定模板形参 `T` 的具体类型。例如 `Swap(s1, s2)` 中实参都是 `string`，推断出 `T = string`。

**第二步：实例化（Instantiation）**

确定模板实参后，编译器用具体类型**替代**模板形参，生成一份"真实代码"，然后编译它。

```cpp
// Swap(s1, s2) 的实例化结果（编译器生成的等价代码）：
void Swap(string &v1, string &v2) {
    string temp;
    temp = v1;
    v1 = v2;
    v2 = temp;
}
```

> ⚠️ **关键规则**：模板实参推断过程中**不进行常规隐式类型转换**。这意味着：
> 
> - `Swap(3, 4.5)` → ❌ **编译错误**：实参 `int` 和 `double` 推导出冲突的 `T`
> - 必须 `Swap<int>(3, 4.5)` 或 `Swap(3, static_cast<int>(4.5))`，或确保两个实参类型一致

---

### 2.4 隐式类型转换的禁用

这是**高频易错点**，必须彻底理解：

```cpp
template <typename T>
T max(T a, T b) { return a > b ? a : b; }

int main() {
    max(3, 5);        // ✅ T = int，正常
    max(3.0, 5.0);    // ✅ T = double，正常
    // max(3, 5.0);   // ❌ 编译错误！int 和 double 类型不匹配
}
```

**为什么会出错？** 编译器从第一个实参 `3` 推出 `T = int`，从第二个实参 `5.0` 推出 `T = double`，`T` 产生了冲突。

**解决方法**：

```cpp
max<double>(3, 5.0);                 // ① 显式指定 T，3 被隐式转为 double
max(static_cast<double>(3), 5.0);    // ② 手动类型转换
```

> 💡 **设计原理**：模板不允许实参推断阶段隐式转换，是为了**避免歧义和意外**——编译器不知道你是想要 `max<int>` 还是 `max<double>`，与其猜测，不如报错让你明确指定。

---

### 2.5 显式全特化（Explicit Specialization）

> **特化**：对某个**特定类型**提供一份特殊的实现版本，使该类型不走通用模板的逻辑。

**为何需要特化？** 通用模板通用于所有类型，但某些类型可能需要"特殊处理"。

```cpp
// 通用模板
template <typename T>
void Swap(T &v1, T &v2) {
    T temp;
    temp = v1;
    v1 = v2;
    v2 = temp;
}

// 针对 int 的特化版本
template <>
void Swap(int &v1, int &v2) {
    int temp;
    temp = v1;
    v1 = v2;
    v2 = temp;
    v1 += 10;   // int 特有的额外操作
    v2 += 10;
}
```

**关键语法**：

- `template <>`：空模板形参列表，表示这是特化
- 函数签名中 `T` 被替换为具体类型 `int`
- 当传入实参是 `int` 类型时，编译器优先选择特化版本

**调用规则**：编译器在重载决议时，**优先匹配特化版本**，其次才是通用模板。

---

### 2.6 模板重载与重载决议

对函数模板进行重载，可以：
1. 定义名字相同而**形参表不同**的函数模板
2. 定义与函数模板同名的**非模板函数**（普通函数）

当调用时，编译器按以下**优先级**（重载协议）确定调用谁：

```
① 非模板函数（普通函数）：形参完全匹配调用实参
    ↓ 找不到
② 函数模板实例化（含特化）：先匹配特化 → 再匹配通用模板
    ↓ 找不到
③ 非模板函数：实参经隐式转换后匹配
    ↓ 找不到
④ 编译错误
```

> ⚠️ **核心记忆**：**完全匹配的非模板函数优先级最高**；模板实例化时**不进行隐式转换**，只有非模板函数才会尝试隐式转换。

**完整示例**：

```cpp
// 通用函数模板
template <typename T>
void demoPrint(const T v1, const T v2) {
    cout << "first version: " << v1 << " " << v2 << endl;
}

// 对 char 的特化
template <>
void demoPrint(const char v1, const char v2) {
    cout << "special version: " << v1 << " " << v2 << endl;
}

// 函数模板的重载（不同形参数量）
template <typename T>
void demoPrint(const T v) {
    cout << "second version: " << v << endl;
}

// 非模板函数（普通函数），与模板同名
void demoPrint(const double v1, const double v2) {
    cout << "non-template version: " << v1 << " " << v2 << endl;
}
```

**调用测试**：

```cpp
string s1("rabbit"), s2("bear");
char c1('k'), c2('b');
int iv1 = 3, iv2 = 5;
double dv1 = 2.8, dv2 = 8.5;

demoPrint(iv1, iv2);   // → first version（通用模板，T=int）
demoPrint(c1, c2);     // → special version（char 特化优先）
demoPrint(iv1);        // → second version（单参数模板重载）
demoPrint(dv1, dv2);   // → non-template version（double 完全匹配非模板函数）
demoPrint(iv1, dv2);   // → non-template version（int 隐式转为 double，匹配非模板）
```

**逐条分析最后两条**：

- `demoPrint(dv1, dv2)`：非模板函数 `demoPrint(double, double)` 完全匹配 → 最高优先级，直接调用
- `demoPrint(iv1, dv2)`：`int` + `double` → 模板推断 `T` 冲突，无法实例化 → 进入第③步：对非模板函数做隐式转换（`int→double`） → 匹配 `demoPrint(double, double)`

> 🔑 **关键结论**：函数模板是不进行隐式转换的，只有非模板函数才进行隐式转换！

---

## 三、类模板（Class Template）

### 3.1 类模板的定义

> **使用情景**：定义可以容纳任意类型元素的通用容器类——栈（Stack）、队列（Queue）、链表（List）等。

**类模板的一般形式**：

```cpp
template <模板形参表>
class 类模板名 {
    类成员声明
    ...
};
```

模板形参表中，每项是以下三者之一：**类型形参**（`typename T`）、**非类型形参**（`int N`）、**模板形参**（高级话题）。

**完整示例：链表实现的栈类模板**

```cpp
template <typename ElementType>
class Stack {
public:
    Stack();
    ~Stack();
    void push(ElementType obj);     // 栈中元素类型由 ElementType 决定
    void pop();
    ElementType getTop() const;
    bool isEmpty() const;
private:
    struct Node {
        ElementType element;       // 结点中存放的元素
        Node* next;                // 指向下一结点的指针
    };
    Node* top;                     // 栈顶结点
};
```

> 💡 `ElementType` 是一个"占位符"——在模板定义时它代表"某种不确定的类型"，在实例化时才被具体类型取代。

---

### 3.2 类模板外定义成员函数

**在类模板外定义成员函数的一般形式**：

```cpp
template <模板形参表>
返回值类型 类模板名<模板形参名列表>::函数名(函数形参表) {
    函数实现 ...
}
```

> ⚠️ **易错点**：类名后面必须带 `<模板形参名列表>`！而且即使函数实现中没有用到任何模板形参，也必须写全。

**各成员函数实现**：

```cpp
// push：向栈内压入元素
template <typename ElementType>
void Stack<ElementType>::push(ElementType obj) {
    Node* temp = new Node;
    temp->element = obj;
    temp->next = top;
    top = temp;
}

// pop：从栈顶弹出元素
template <typename ElementType>
void Stack<ElementType>::pop() {
    if (top == nullptr)
        throw std::logic_error("pop from empty Stack");
    Node* temp = top;
    top = top->next;
    delete temp;
}

// getTop：获取栈顶元素
template <typename ElementType>
ElementType Stack<ElementType>::getTop() const {
    if (top == nullptr)
        throw std::logic_error("getTop from empty Stack");
    return top->element;
}

// isEmpty：判断栈是否为空
template <typename ElementType>
bool Stack<ElementType>::isEmpty() const {
    return top == nullptr;    // 即使没用到 ElementType 也需要写全！
}
```

---

### 3.3 类模板的实例化

> **关键区别**：类模板本身是一个"类蓝图"，不是具体类，不能直接创建对象。只有**实例化**后才得到具体类，才能用来创建对象。

**实例化的一般形式**：

```cpp
类模板名 <模板实参表>
```

**不同实例化产生完全不同的类**：

```cpp
Stack<int> stack_int;       // 实例化为 "int 栈"
Stack<double> stack_double; // 实例化为 "double 栈"  
Stack<string> stack_string; // 实例化为 "string 栈"
// Stack<int> 和 Stack<double> 是**两个不同的类**！
```

**完整使用示例**：

```cpp
int main() {
    Stack<int> stack;           // 实例化一个保存 int 型元素的栈
    for (int i = 1; i < 9; i++)
        stack.push(i);          // 向栈中压入 8 个元素

    while (!stack.isEmpty()) {  // 栈不为空时循环
        cout << stack.getTop() << " ";
        stack.pop();
    }
    return 0;
}
// 输出：8 7 6 5 4 3 2 1
```

---

### 3.4 模板的文件组织

> ⚠️ **这是最容易犯错的工程问题**：模板不能用"声明在 `.hpp`，实现在 `.cpp`"的传统方式！

**原因**：编译器要实例化模板，必须能看到模板的**完整定义**（就像你做菜必须看到完整的菜谱，不能只看菜名）。

C++ 提供两种编译模型：

#### 包含编译模式（Inclusion Compilation Model）✅ 推荐

**做法**：将模板的声明和实现**全部放在 `.hpp` 头文件**中（或头文件 `#include` 实现文件）。客户端只需 `#include` 一个头文件。

```cpp
// Stack.hpp
#ifndef STACK_HPP
#define STACK_HPP

template <typename T>
class Stack {
    // ... 完整定义和实现都在这里
};

#endif

// client.cpp
#include "Stack.hpp"    // 一行搞定
```

#### 分离编译模式（Separate Compilation Model）

使用 `export` 关键字声明模板定义需要被记住，但**并非所有编译器都支持**，不推荐。

> 💡 **实践建议**：模板代码一律放在 `.hpp` 头文件中，使用包含编译模式。这是业界主流做法，也是 C++ 标准库（STL）的方式。

---

## 四、非类型模板形参（Non-type Template Parameter）

### 4.1 两类模板形参

|类别|形式|含义|实例化时|
|---|---|---|---|
|**类型模板形参**|`typename T`|T 代表某种类型|用具体类型替换|
|**非类型模板形参**|`int N`|N 代表一个常量值|用编译时常量替换|

> 💡 **通俗理解**：类型形参 → "这是什么种类的盒子"；非类型形参 → "这盒子的尺寸是多大"。

### 4.2 非类型形参的约束

> **非类型模板形参**：相当于模板内部的**编译时常量**。对模板进行实例化时，非类型形参由相应**模板实参的值**代替。

**约束**：对应的模板实参**必须是编译时常量表达式**。也就是说：

- ✅ `Stack<int, 10>` → `10` 是字面量常量
- ✅ `constexpr int N = 5; Stack<int, N>` → `N` 是编译时常量
- ❌ `int n; cin >> n; Stack<int, n>` → `n` 是运行时变量，编译错误！

---

### 4.3 完整示例：数组实现的栈

使用非类型模板形参 `N` 指定栈的最大容量，避免动态内存分配：

```cpp
template <typename ElementType, int N>
class Stack {
public:
    Stack() : count(0) {}
    void push(ElementType obj) {
        if (count >= N) throw std::logic_error("Stack full");
        elements[count++] = obj;
    }
    void pop() {
        if (count == 0) throw std::logic_error("Stack empty");
        count--;
    }
    ElementType getTop() const {
        if (count == 0) throw std::logic_error("Stack empty");
        return elements[count - 1];
    }
    bool isEmpty() const { return count == 0; }
private:
    ElementType elements[N];   // N 决定了数组大小！
    int count;
};

int main() {
    Stack<int, 10> stack;      // 实例化为容量为 10 的 int 栈
    for (int i = 1; i < 9; i++)
        stack.push(i);
    // ...使用方式不变
}
```

> 💡 **设计优势**：容量 `N` 在编译期确定，不需要动态内存分配（无 `new`/`delete`），栈数组直接嵌入对象内存中，性能更好。这正是 `std::array<T, N>` 的实现原理。

**与链表实现的对比**：

|     | 链表实现 `Stack<T, N>` | 数组实现 `Stack<T, N>` |
| --- | ------------------ | ------------------ |
| 大小  | 动态，无上限             | 编译期确定，固定容量         |
| 内存  | 堆（heap）分配          | 直接嵌入对象（栈或静态区）      |
| 参数  | 仅类型参数              | 类型 + 大小            |
| 原理  | `std::vector`      | `std::array`       |

---

## 五、数组的引用与模板推导

### 5.1 数组引用做形参

先回顾普通数组做函数参数的问题：

```cpp
void f(int b[]) {      // b 退化为指针 (int*)
    b++;               // ✅ 可以，b 是指针变量
    cout << &b;        // 输出指针变量的地址（在栈上）
}

void f(int (&b)[3]) {  // b 是数组的引用
    // b++;            // ❌ 错误：引用不能递增，本质是"别名"
    cout << &b;        // 输出与原数组相同的地址！
}

int main() {
    int a[3] = {1, 2, 3};
    cout << &a;         // 假设输出 0xFF24
    f(a);
}
```

**两种方式的本质区别**：

|特征|`f(int b[])`|`f(int (&b)[3])`|
|---|---|---|
|b 的类型|`int*`（指针变量）|`int(&)[3]`（数组引用）|
|&b 的语义|指针变量自身的地址|被引用数组的地址 = 实参地址|
|长度检查|❌ 不检查|✅ 实参必须正好是 3 个元素|
|b 可否自增|✅ 可以|❌ 不可以（引用被绑定）|

### 5.2 模板自动推导数组长度

结合函数模板与非类型形参，可以让编译器**自动推导数组长度**——这是非类型模板形参的经典应用：

```cpp
// 数组引用 + 模板自动推导长度
template <typename T, int N>
void printValues(T (&arr)[N]) {
    for (int i = 0; i != N; ++i)
        cout << arr[i] << endl;
}

int main() {
    int intArr[6] = {1, 2, 3, 4, 5, 6};
    double dblArr[4] = {1.2, 2.3, 3.4, 4.5};

    printValues(intArr);   // T=int,  N=6（自动推导！）
    printValues(dblArr);   // T=double, N=4（自动推导！）
}
```

> 🔑 **三个参数同时推导**：`T` 从数组元素类型推导，`N` 从数组长度推导——一步到位，无需手动指定！

**另一种等价写法——数组指针**：

```cpp
template <typename T, int N>
void printValues(T (*arr)[N]) {   // arr 是指向数组的指针
    for (int i = 0; i != N; ++i)
        cout << (*arr)[i] << endl;
}

int main() {
    int intArr[6] = {1, 2, 3, 4, 5, 6};
    printValues(&intArr);          // 传数组地址，T=int, N=6
}
```

> ⚠️ 区别：`T (&arr)[N]` 传的是数组引用 → 调用 `printValues(intArr)`；`T (*arr)[N]` 传的是数组指针 → 调用 `printValues(&intArr)`。前者更简洁，所以引用版本更常用。

---

### 5.3 对比：传统指针退化的方式

```cpp
// 传统方式：数组退化为指针，长度必须单独传递
template <typename T>
void printValues(T* arr, int N) {   // N 是运行时参数
    for (int i = 0; i != N; ++i)
        cout << arr[i] << endl;
}

int main() {
    int intArr[6] = {1, 2, 3, 4, 5, 6};
    printValues(intArr, 6);    // 必须手动传长度！
    // printValues(intArr, 5)  // ⚠️ 可以传错，编译器不会报错！
}
```

**三种方式的优劣对比**：

|数组引用 + 模板|数组指针 + 模板|普通指针 + 参数|
|---|---|---|---|
|长度安全性|✅ 编译期保证|✅ 编译期保证|❌ 运行时可能出错|
|写法简洁性|⭐⭐⭐|⭐⭐|⭐|
|灵活性|只能处理固定长度数组|同左|可处理指针/动态数组|

---

## 六、例题精选

### 例题 1：模板实参推断

```cpp
template <typename T>
T add(T a, T b) { return a + b; }

int main() {
    cout << add(1, 2) << endl;          // (1)
    cout << add(1.5, 2.5) << endl;      // (2)
    // cout << add(1, 2.5) << endl;     // (3)
    cout << add<int>(1, 2.5) << endl;   // (4)
    cout << add<double>(1, 2.5) << endl;// (5)
}
```

**问题：分析每条语句能否编译，若能，输出什么？若不能，原因是什么？**
<summary>📝 解析</summary>

- **(1)** `add(1, 2)` → ✅ `T = int`，输出 `3`
- **(2)** `add(1.5, 2.5)` → ✅ `T = double`，输出 `4.0`
- **(3)** `add(1, 2.5)` → ❌ **编译错误**：两个实参类型不一致（`int` + `double`），模板推断 `T` 冲突——从第一个推出 `T=int`，从第二个推出 `T=double`
- **(4)** `add<int>(1, 2.5)` → ✅ 显式指定 `T=int`，`2.5` 被隐式转为 `int` → `2`，输出 `3`（注意小数截断！）
- **(5)** `add<double>(1, 2.5)` → ✅ 显式指定 `T=double`，`1` 被隐式转为 `1.0`，输出 `3.5`

> ⚠️ **(4) 是易错点**：显式指定 `T=int` 后 `2.5` 会截断为 `2`，结果是 `3` 而非 `3.5`！显式指定时一定要想清楚类型转换的后果

---

### 例题 2：模板重载优先级

```cpp
// 普通函数（非模板）
void show(int a, int b) {
    cout << "Normal: " << a + b << endl;
}

// 函数模板
template <typename T>
void show(T a, T b) {
    cout << "Template: " << a << " " << b << endl;
}

// 函数模板特化（针对 char）
template <>
void show(char a, char b) {
    cout << "Special: " << a << b << endl;
}

int main() {
    show(1, 2);       // ①
    show(1.0, 2.0);   // ②
    show('a', 'b');   // ③
    show(1, 2.0);     // ④
}
```

**问题：写出 ①②③④ 各调用哪个版本，并输出结果。**

<summary>📝 解析</summary>

**①** `show(1, 2)`：
- 非模板函数 `show(int, int)` **完全匹配** → 优先级最高 → 调用它
- **输出**：`Normal: 3`

**②** `show(1.0, 2.0)`：
- 无非模板函数匹配（`double` 不能直接匹配 `int`）
- 模板可实例化 `show<double>(double, double)` → 调用模板
- **输出**：`Template: 1 2`（注意：`double` 输出格式）

**③** `show('a', 'b')`：
- 先查非模板函数：`show(int, int)`，`char` 到 `int` 需要隐式转换（不是完全匹配）
- 再查模板：通用模板 `T=char` 可完全匹配，但**特化版本 `show(char, char)` 优先于通用模板**
- **输出**：`Special: ab`

**④** `show(1, 2.0)`：
- 非模板函数不匹配（`int` + `double` 对不上 `int, int`）
- 模板无法推断（`int` vs `double`，T 冲突）
- 回到非模板函数尝试隐式转换：`2.0` (double) → `2` (int)，成功匹配！
- **输出**：`Normal: 3`

> 🔑 重载决议的核心链：完全匹配的非模板 → 模板（先特化后通用）→ 隐式转换后的非模板 → 编译错误。**④ 是高频陷阱**：看似模板无法匹配，但"回退"到非模板并做了隐式转换！


---

### 例题 3：类模板成员函数实现

```cpp
#include <iostream>
using namespace std;

template <typename T>
class Counter {
public:
    Counter(T start) : value(start) { count++; }
    ~Counter() { count--; }

    T get() const { return value; }
    void set(T v) { value = v; }
    static int getCount() { return count; }

private:
    T value;
    static int count;
};

// (A) 补充静态成员定义
// ???

int main() {
    Counter<int> c1(10);
    Counter<double> c2(3.14);
    Counter<int> c3(20);

    cout << Counter<int>::getCount() << endl;       // (1)
    cout << Counter<double>::getCount() << endl;    // (2)
}
```

**问题：补全 (A) 处的代码，并写出 (1)(2) 的输出。**
<summary>📝 解析</summary>

**(A) 补充定义**：

```cpp
template <typename T>
int Counter<T>::count = 0;    // 必须带模板前缀！
```

> ⚠️ **易错点**：`count` 是类模板的静态成员，属于**每个实例化类型独立一份**。不能在定义外面漏掉 `template <typename T>`。

**(1) 和 (2) 的输出**：

- `Counter<int>` 有两个实例 (`c1`, `c3`)，一个析构后还剩 → **取决于何时查询**
- **关键概念**：`Counter<int>` 和 `Counter<double>` 是**两个不同的类**！它们各自有独立的 `count`。

假设在创建和析构之间查询，输出为：`2` 和 `1`。

> 🔑 核心理解：`Counter<int>` 和 `Counter<double>` 的 `count` 是**完全独立的两份变量**，互不影响。类模板的每次实例化都是一个"新类"，拥有自己的一套静态成员。


---

### 例题 4：非类型模板形参传参判断

```cpp
template <typename T, int SIZE>
class Buffer {
    T data[SIZE];
public:
    int size() const { return SIZE; }
};

const int N = 100;
constexpr int M = 200;

int main() {
    int runtime = 50;

    Buffer<int, 10>    b1;    // ①
    Buffer<int, N>     b2;    // ②
    Buffer<int, M>     b3;    // ③
    Buffer<int, N*2>   b4;    // ④
    // Buffer<int, runtime> b5; // ⑤

    cout << b1.size() << endl;
    cout << b2.size() << endl;
    cout << b4.size() << endl;
}
```

**问题：判断 ①②③④⑤ 各是否合法，并写出合法部分的输出。**

<summary>📝 解析</summary>

**合法性判断**：

- **①** `Buffer<int, 10>` → ✅ 字面量 `10` 是编译时常量
- **②** `Buffer<int, N>` → ✅ `N` 是 `const` 常量（`= 100`），编译时常量
- **③** `Buffer<int, M>` → ✅ `M` 是 `constexpr`，明确编译时常量
- **④** `Buffer<int, N*2>` → ✅ `N*2` 是编译时常量表达式（`100*2 = 200`）
- **⑤** `Buffer<int, runtime>` → ❌ `runtime` 是**运行时变量**，不是编译时常量！

**输出**：

```
10
100
200
```

> 💡 **易错**：`const` 和 `constexpr` 都算编译时常量，可以用于非类型模板形参。但 `const int x = rand()`（运行期 `const`，见 C 语言的"只读变量"）在 C++ 中仍可以作为编译时常量（如果初始化器是常量表达式）——关键是初始值，不是关键字。



---

### 例题 5：综合题——写出排序函数模板

**要求：编写一个函数模板 `mySort`，对任意类型的数组进行从小到大排序，要求：**

1. 用冒泡排序实现
2. 支持 `int`、`double`、`string` 等支持 `<` 运算符的类型
3. 使用非类型模板形参推导数组长度

**请完成代码。**

 <summary>📝 参考实现</summary>

```cpp
#include <iostream>
#include <string>
using namespace std;

template <typename T, int N>
void mySort(T (&arr)[N]) {
    for (int i = 0; i < N - 1; ++i) {
        for (int j = 0; j < N - 1 - i; ++j) {
            if (arr[j + 1] < arr[j]) {   // 使用 < 运算符
                T temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
}

int main() {
    int intArr[] = {5, 2, 8, 1, 9};
    mySort(intArr);
    for (int i = 0; i < 5; ++i) cout << intArr[i] << " ";
    cout << endl;  // 输出：1 2 5 8 9

    double dblArr[] = {3.14, 1.41, 2.72, 0.58};
    mySort(dblArr);
    for (int i = 0; i < 4; ++i) cout << dblArr[i] << " ";
    cout << endl;  // 输出：0.58 1.41 2.72 3.14

    string strArr[] = {"banana", "apple", "cherry", "date"};
    mySort(strArr);
    for (int i = 0; i < 4; ++i) cout << strArr[i] << " ";
    cout << endl;  // 输出：apple banana cherry date

    return 0;
}
```

> 🔑 **设计要点**：
> 
> 1. `T (&arr)[N]` 一箭双雕——类型和长度同时推导
> 2. `N` 在函数体内直接可用，不需要额外的 `sizeof` 计算
> 3. 任意支持 `<` 运算符的类型都可以排序——这就是泛型的威力


---

### 例题 6：综合题——模板与重载决议陷阱

```cpp
#include <iostream>
using namespace std;

template <typename T>
void print(T val) {
    cout << "Template: " << val << endl;
}

void print(int val) {
    cout << "Normal int: " << val << endl;
}

template <>
void print<double>(double val) {     // 注意：这是对 print(T) 的显式特化
    cout << "Special double: " << val << endl;
}

void print(double val) {              // 这是另一个普通函数
    cout << "Normal double: " << val << endl;
}

int main() {
    print(42);        // ①
    print(3.14);      // ②
    print<int>(42);   // ③
    print<>(3.14);    // ④
    print("hello");   // ⑤
}
```

**问题：写出 ①②③④⑤ 各调用哪个版本，分析其中涉及的重载决议规则。**

<summary>📝 解析</summary>

**逐条分析**：

**①** `print(42)` → 非模板 `print(int)` **完全匹配** → 最高优先级 → `Normal int: 42`

**②** `print(3.14)` → 有两个候选：
- 非模板 `print(double)` **完全匹配** → 最高优先级
- 输出：`Normal double: 3.14`
- （模板特化 `print<double>` 没有被选中——因为非模板函数优先级更高）

**③** `print<int>(42)` → 显式指定调用模板版本 `print<int>` → 绕过了重载决议中"非模板优先"的规则 → `Template: 42`

**④** `print<>(3.14)` → `<>` 表示"只用模板实例化，不要非模板" → 模板中，先查特化 `print<double>` 完全匹配 → `Special double: 3.14`

**⑤** `print("hello")` → 无非模板可匹配 → 模板 `T=const char*` 可实例化 → `Template: hello`

> 🔑 **核心总结**：
> 
> - ② vs ④ 的关键区别：`print(3.14)` 非模板优先；`print<>(3.14)` 强制走模板路径
> - `<>` 语法明确告诉编译器：只从模板中寻找，不要考虑普通函数
> - 特化 `print<double>` 在 ② 中被"遮蔽"——这是特化常见的陷阱



---

### 例题 7：综合题——编写一个 Pair 类模板

**要求：**

1. `Pair<T1, T2>` 有两个数据成员 `first`(T1) 和 `second`(T2)
2. 提供构造函数、getter/setter
3. 提供一个 `swap` 成员函数，交换 `first` 和 `second`（只有当 `T1 == T2` 时才能交换，否则编译报错）
4. 在 `main` 中测试 `Pair<string, int>` 和 `Pair<int, int>`，并展示交换功能
<summary>📝 参考实现</summary>

```cpp
#include <iostream>
#include <string>
using namespace std;

template <typename T1, typename T2>
class Pair {
public:
    Pair() : first(T1()), second(T2()) {}
    Pair(T1 f, T2 s) : first(f), second(s) {}

    T1 getFirst()  const { return first; }
    T2 getSecond() const { return second; }
    void setFirst(T1 f)  { first = f; }
    void setSecond(T2 s) { second = s; }

    // swap 要求 T1 == T2，否则模板实例化时出错
    void swap() {
        // 编译期断言：T1 和 T2 必须是同一类型
        T1 temp = first;
        first = second;   // 若 T1 != T2，此行编译错误！
        second = temp;
    }

private:
    T1 first;
    T2 second;
};

int main() {
    // 测试 Pair<string, int>
    Pair<string, int> p1("Alice", 20);
    cout << p1.getFirst() << ": " << p1.getSecond() << endl;
    // p1.swap();  // ❌ 编译错误：string 和 int 不能互换

    // 测试 Pair<int, int>（可交换）
    Pair<int, int> p2(10, 20);
    cout << "Before: " << p2.getFirst() << ", " << p2.getSecond() << endl;
    p2.swap();
    cout << "After:  " << p2.getFirst() << ", " << p2.getSecond() << endl;

    return 0;
}
```

**输出**：

```
Alice: 20
Before: 10, 20
After:  20, 10
```

> 🔑 **设计要点**：
> 
> 1. 多模板形参 `template <typename T1, typename T2>` 让 Pair 支持异类型
> 2. `swap()` 对 `Pair<string, int>` 调用时编译器会报错——这是**编译期类型安全**
> 3. 模板的有趣特性：错误只在你试图实例化非法组合时才暴露，不是定义模板时



---

## 七、知识点速查总结

|知识点|核心概念|高频易错|
|---|---|---|
|**泛型编程**|编译时多态，类型参数化|区别于虚函数运行时多态|
|**函数模板**|`template <typename T>` 后跟函数定义|形参必须使用所有模板形参|
|**模板实参推断**|编译器根据调用实参确定 T|**不进行隐式类型转换**！|
|**显式全特化**|`template <>` + 具体类型实现|空 `<>` 表示特化，针对特定类型优先级高于通用模板|
|**重载决议**|非模板完全匹配 → 模板（特化→通用）→ 非模板隐式转换|模板不参与隐式转换！|
|**类模板**|`template <typename T> class X {}`|类外定义成员必须带 `X<T>::`|
|**类模板实例化**|`Stack<int>` 和 `Stack<double>` 是**不同的类**|静态成员每类型独享一份|
|**文件组织**|模板定义必须**全部放在头文件**中（包含编译模式）|编译器需要完整定义才能实例化|
|**非类型模板形参**|`template <typename T, int N>`，N 必须是编译时常量|运行时变量不能做模板实参|
|**数组引用推导**|`T (&arr)[N]` 同时推导类型和长度|比普通指针退化更安全|

### 重载决议优先级速记

```
① 完全匹配的非模板函数
        ↓ 没有
② 模板实例化（先特化，后通用）
        ↓ 实例化失败或没有
③ 非模板函数 + 隐式类型转换
        ↓ 没有
④ 编译错误
```

> [!summary] 本章核心思想
> 
> 模板是 C++ 泛型编程的基石，核心理念是 **"写一次代码，适用于无数类型"**。
> 
> - **函数模板**：让算法独立于类型，减少代码重复
> - **类模板**：让容器独立于元素类型，实现通用数据结构
> - **非类型形参**：让编译期常量也成为参数（如数组大小），实现零开销抽象
> - **数组引用**：结合模板完美解决"数组长度丢失"的历史问题
> 
> 理解模板的关键在于理解**编译期 vs 运行期**的时间观——模板的一切工作在编译期完成，实例化一旦结束，运行时代码和手写版本毫无区别。这正是 C++ "零开销抽象（Zero-cost Abstraction）"哲学的完美体现。
