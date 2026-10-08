
## 目录

1. [抽象数据类型（ADT）](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E4%B8%80%E6%8A%BD%E8%B1%A1%E6%95%B0%E6%8D%AE%E7%B1%BB%E5%9E%8Badt)
2. [类的声明与成员访问控制](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E4%BA%8C%E7%B1%BB%E7%9A%84%E5%A3%B0%E6%98%8E%E4%B8%8E%E6%88%90%E5%91%98%E8%AE%BF%E9%97%AE%E6%8E%A7%E5%88%B6)
3. [成员函数：声明、实现与内联](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E4%B8%89%E6%88%90%E5%91%98%E5%87%BD%E6%95%B0%E5%A3%B0%E6%98%8E%E5%AE%9E%E7%8E%B0%E4%B8%8E%E5%86%85%E8%81%94)
4. [C++ 新特性预备：bool / 函数重载 / 默认实参](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E5%9B%9Bc-%E6%96%B0%E7%89%B9%E6%80%A7%E9%A2%84%E5%A4%87)
5. [构造函数与析构函数](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E4%BA%94%E6%9E%84%E9%80%A0%E5%87%BD%E6%95%B0%E4%B8%8E%E6%9E%90%E6%9E%84%E5%87%BD%E6%95%B0)
6. [this 指针](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E5%85%ADthis-%E6%8C%87%E9%92%88)
7. [静态成员](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E4%B8%83%E9%9D%99%E6%80%81%E6%88%90%E5%91%98)
8. [动态对象与 new / delete](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E5%85%AB%E5%8A%A8%E6%80%81%E5%AF%B9%E8%B1%A1%E4%B8%8E-new--delete)
9. [=default 与 =delete](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E4%B9%9Ddefault-%E4%B8%8E-delete)
10. [对象成员初始化：初始化器列表](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E5%8D%81%E5%AF%B9%E8%B1%A1%E6%88%90%E5%91%98%E5%88%9D%E5%A7%8B%E5%8C%96%E5%88%9D%E5%A7%8B%E5%8C%96%E5%99%A8%E5%88%97%E8%A1%A8)
11. [对象的内存布局与静态联编](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E5%8D%81%E4%B8%80%E5%AF%B9%E8%B1%A1%E7%9A%84%E5%86%85%E5%AD%98%E5%B8%83%E5%B1%80%E4%B8%8E%E9%9D%99%E6%80%81%E8%81%94%E7%BC%96)
12. [拷贝构造函数：浅拷贝与深拷贝](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E5%8D%81%E4%BA%8C%E6%8B%B7%E8%B4%9D%E6%9E%84%E9%80%A0%E5%87%BD%E6%95%B0%E6%B5%85%E6%8B%B7%E8%B4%9D%E4%B8%8E%E6%B7%B1%E6%8B%B7%E8%B4%9D)
13. [深入 const](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E5%8D%81%E4%B8%89%E6%B7%B1%E5%85%A5-const)
14. [综合例题（高难度）](https://claude.ai/chat/7e3ca3dd-fcda-4fa9-ad6b-fc272985eb82#%E5%8D%81%E5%9B%9B%E7%BB%BC%E5%90%88%E4%BE%8B%E9%A2%98%E9%AB%98%E9%9A%BE%E5%BA%A6)

---

## 一、抽象数据类型（ADT）

### 核心概念

|概念|说明|
|---|---|
|**抽象**|从众多事物中提取共同本质特征，舍弃非本质特征|
|**ADT**|对现实事物的数字化描述；包含**属性（property）**和**方法（method）**|
|**类（class）**|ADT 的 C++ 实现；是数据类型的"蓝图"，本身不含实际数据|
|**对象（object）**|类定义的变量，即类的**实例（instance）**|
|**封装**|将内部数据和实现细节隐藏，只暴露公共接口|

### C 语言 struct 的局限

```c
// C：数据与操作分离——无法封装
struct Date { int year, month, day; };
void Set(struct Date*, int, int, int);  // 函数是"散的"
```

C++ 的 `class`/`struct` 可将**数据 + 函数**统一封装在一起，实现**信息隐藏**。

---

## 二、类的声明与成员访问控制

### 语法骨架

```cpp
class 类名 {
  访问说明符:
    数据成员声明;
    函数成员声明;
};   // ← 分号不能省！
```

### 访问说明符

|关键字|可访问范围|默认（class）|
|---|---|---|
|`public`|任何地方|否|
|`private`|类内部 + 友元|**是**|
|`protected`|类内部 + 子类 + 友元|否|

> ⚠️ **易错点**：`class` 默认 `private`，`struct` 默认 `public`。二者其余语义完全一致。

### 典型 DATE 类声明

```cpp
class DATE {
public:
    void Set(int, int, int);
    int getMonth() const;
    int getDay()   const;
    int getYear()  const;
    void Print()   const;
    void Increment();
    void Decrement();
private:
    int month, day, year;
};
```

> **设计原则**：数据成员放 `private`，操作接口放 `public`，防止外部直接破坏对象内部状态一致性（如将 `length` 设为负数）。

---

## 三、成员函数：声明、实现与内联

### 三种定义方式

#### 1. 类内定义（隐式内联）

```cpp
class DATE {
public:
    void Set(int y, int m, int d) {
        year = y; month = m; day = d;   // 直接访问私有成员
    }
};
```

#### 2. 类外定义（使用作用域解析符 `::`）

```cpp
// DATE.hpp 中声明
void Set(int, int, int);

// DATE.cpp 中实现
void DATE::Set(int y, int m, int d) {
    year = y; month = m; day = d;
}
```

> ⚠️ **易错**：`DATE.cpp` 开头必须 `#include "DATE.hpp"`，否则编译器不认识 `DATE` 这个标识符。

#### 3. `const` 成员函数

```cpp
int getYear() const;   // 声明时加 const
int DATE::getYear() const { return year; }  // 实现时也要加 const
```

- `const` 成员函数中，`this` 类型从 `DATE* const` 变为 `const DATE* const`。
- **不能修改任何非静态数据成员**（除 `mutable` 成员）。
- 只有 `const` 成员函数才能被 `const` 对象调用。

---

## 四、C++ 新特性预备

### 4.1 bool 类型

```cpp
bool b = 7;     // 非零 → true
bool c = 0;     // 零 → false
cout << true;   // 输出 1
cout << false;  // 输出 0
```

### 4.2 函数重载

**同名、参数不同**（类型或数量），返回值类型**不参与**函数签名。

```cpp
void Swap(int& x, int& y);
void Swap(double& x, double& y);
```

> ⚠️ **易错**：仅返回类型不同不构成重载，编译报错。

### 4.3 默认实参

```cpp
void func(int n=1, float b=1.2, char c='@');
// 默认值只能从右侧开始！
// void func(int n=1, float b, char c='@');  // 错！
```

**实现时不重复写默认值**：

```cpp
void func(int n, float b, char c) { ... }  // 定义处不写默认值
```

> ⚠️ **易错**：默认实参必须从最右边的参数向左连续定义，中间不能跳过。

---

## 五、构造函数与析构函数

### 5.1 构造函数规则汇总

|规则|说明|
|---|---|
|名字与类名相同||
|无返回类型（连 `void` 都不写）||
|可以重载|多个构造函数，参数不同|
|用户定义后编译器不再自动生成默认构造|**⚠️ 高频易错**|
|可使用默认实参|减少重载数量|

#### 无参构造函数

```cpp
DATE::DATE() {
    year = 2000; month = 1; day = 1;
}
```

#### 有参构造函数

```cpp
DATE::DATE(int y, int m, int d) {
    year = y; month = m; day = d;
}
```

#### 默认实参构造函数

```cpp
// 声明
DATE(int y=2000, int m=1, int d=1);

// 实现（不重复默认值）
DATE::DATE(int y, int m, int d) {
    year = y; month = m; day = d;
}
```

> ⚠️ **易错点**：若同时声明了 `DATE()` 和 `DATE(int=2000, int=1, int=1)`，则 `DATE d;` 将**产生二义性**编译错误。

### 5.2 析构函数

```cpp
~DATE();              // 声明：波浪号 + 类名，无参数，无返回值
DATE::~DATE() { ... } // 实现
```

- 对象离开作用域（栈对象）或执行 `delete`（堆对象）时**自动调用**。
- **不能直接显式调用**析构函数（特殊情况除外）。
- 堆对象若不 `delete` 则**析构函数不会被调用**，导致资源泄漏。

#### 析构顺序

```
构造顺序：obj1 → obj2 → obj3
析构顺序：obj3 → obj2 → obj1   （栈：LIFO）
```

---

## 六、this 指针

```cpp
class Box {
public:
    Box(double l, double b, double h) {
        length = l;
        breadth = b;
        this->height = h;   // 形参与成员重名时必须用 this
    }
    int compare(Box box) {
        return this->Volume() > box.Volume();
    }
};
```

**关键点**：

- 每个**非静态**成员函数都隐含 `this` 指针，指向当前对象。
- `static` 成员函数**没有** `this` 指针，无法直接访问非静态成员。
- 友元函数**没有** `this` 指针（因为它不是类成员）。
- 形参与数据成员重名时，**必须用 `this->member`** 区分。

---

## 七、静态成员

### 7.1 静态数据成员

```cpp
class DATE {
private:
    static int count;  // 类内声明
};

// 类外定义（必须且仅一次，不加 static）
int DATE::count = 0;
```

- 所有对象**共享**同一份静态数据，不属于任何单个对象。
- **不通过构造函数初始化**，必须在类外单独定义。
- 访问：`DATE::count` 或 `obj.count`（不推荐后者）。

### 7.2 静态成员函数

```cpp
class DATE {
public:
    static void getCount() {
        cout << count;     // 只能访问 static 成员
        // cout << year;   // 错！非静态成员不可访问
    }
};

// 调用（不需要对象）
DATE::getCount();
```

> ⚠️ **高频考点**：静态成员函数**没有 this 指针**，故不能访问非静态成员；静态数据成员必须类外定义一次。

---

## 八、动态对象与 new / delete

### 8.1 内存区域回顾

|区域|存储内容|
|---|---|
|代码区（text）|函数机器指令，只读|
|全局数据区（data）|全局变量、static 变量、常量|
|栈区（stack）|局部变量、函数参数、自动对象|
|堆区（heap）|`new`/`malloc` 分配的动态对象|

### 8.2 new / delete 语法

```cpp
// 单个对象
int *p = new int(7);         // 分配并初始化
delete p;                    // 释放

// 数组
int *arr = new int[10]{1,2,3}; // 剩余补零
delete []arr;                  // 必须用 [] 形式！

// 类对象
DATE *d = new DATE(2024, 1, 1); // 调用构造函数
delete d;                       // 调用析构函数后释放
```

> ⚠️ **高频易错**：
> 
> - `new[]` 分配的数组必须用 `delete[]` 释放；若用 `delete`，编译通过但行为未定义（可能只析构首元素）。
> - `new` 失败时抛出 `std::bad_alloc` 异常，**不返回 NULL**。
> - `delete` 后指针仍指向原地址（野指针），建议立即置 `nullptr`。

### 8.3 内存泄漏三种常见情形

```cpp
// 情形1：指针被覆盖
int *p = new int(7);
p = nullptr;  // 泄漏！

// 情形2：指针离开作用域
void f() {
    int *p = new int(7);
}  // 泄漏！

// 情形3：异常中断
void g() {
    int *p = new int(7);
    throw_something();  // 若抛异常，delete p 不执行 → 泄漏
    delete p;
}
```

### 8.4 野指针

```cpp
int *p1 = new int(10);
int *p2 = p1;
delete p1;       // p1 和 p2 同时失效
cout << *p2;     // 错！野指针
delete p2;       // 错！二次释放，行为未定义
```

---

## 九、=default 与 =delete

### =default

令编译器为**特殊成员函数**生成默认实现：

```cpp
class A {
public:
    A(int x) { ... }   // 有参构造，编译器不再自动生成默认构造
    A() = default;     // 显式要求编译器生成默认构造
};
```

> ⚠️ **限制**：`=default` 只能用于编译器能自动生成的**特殊成员函数**（默认构造、析构、拷贝构造、赋值运算符等），不能用于普通函数或带默认参数的构造函数。

### =delete

禁用某个函数：

```cpp
class A {
public:
    A(int x) : m(x) {}
    A(const A&) = delete;             // 禁用拷贝构造
    A& operator=(const A&) = delete;  // 禁用赋值
    int m;
};
A a1(1), a2(2);
a1 = a2;      // 编译错误！
A a3(a1);     // 编译错误！
```

> ⚠️ **易错**：`=delete` 的函数定义必须是**首次声明**，不能先声明后再 `=delete`。

---

## 十、对象成员初始化：初始化器列表

### 10.1 语法

```cpp
struct Ray {
    Ray(Vector3 o, Vector3 d) : origin(o), direction(d) {}
    Vector3 origin;
    Vector3 direction;
};
```

### 10.2 必须使用初始化器列表的情况

|情况|原因|
|---|---|
|`const` 数据成员|常量只能初始化，不能赋值|
|引用类型数据成员|引用必须在定义时初始化|
|没有无参构造函数的类成员|无法在函数体中再次构造|

### 10.3 初始化顺序陷阱（⚠️ 高频考点）

**成员初始化顺序由类中声明顺序决定，与初始化器列表的书写顺序无关！**

```cpp
class foo {
public:
    int i, j;
    foo(int x) : j(x), i(j) {}  // 危险！i 先于 j 声明，故先初始化 i
                                  // 此时 j 尚未初始化，i 值未定义！
};
```

正确写法：

```cpp
foo(int x) : i(x), j(i) {}  // 先初始化 i（先声明），再用 i 初始化 j
```

### 10.4 默认成员初始化器（C++11）

```cpp
struct S {
    int a[2] = {1, 2};        // 默认值
    std::string s{'H', 'C'};  // 直接初始化
    const int c;              // const 必须由初始化器列表提供
    S() : c(42) {}
};
```

---

## 十一、对象的内存布局与静态联编

### 内存分布规则

|成员类型|存储位置|
|---|---|
|非静态数据成员|对象内（栈/堆，取决于对象位置）|
|静态数据成员|全局数据区|
|成员函数（代码）|代码区，所有对象共享|
|虚函数指针|对象内（本课程暂不涉及）|

### 静态联编

```
date1.Increment()
→ 编译器翻译为：DATE::Increment(&date1)
```

优势：

- 对象布局与 C 结构体兼容（便于跨语言调用）
- 高效率（直接调用，无间接开销）

---

## 十二、拷贝构造函数：浅拷贝与深拷贝

### 12.1 拷贝构造函数语法

```cpp
C::C(const C& other);   // 标准形式（必须是引用，必须是 const）
```

> ⚠️ **为什么参数必须是引用？**：若按值传参，调用拷贝构造时本身又需要拷贝构造，导致无限递归。

### 12.2 触发拷贝构造的三种场景

```cpp
C objb(obja);          // ① 直接初始化
C objb = obja;         // ② 等价于①，不是赋值！
void f(C temp);        // ③ 对象按值传参时，初始化 temp
f(obja);               // → 调用拷贝构造
```

> ⚠️ `C objb = obja;` 是**拷贝构造**，不是赋值运算符；只有已存在对象的 `objb = obja;` 才是赋值。

### 12.3 浅拷贝的问题

```cpp
class NAME {
    char* str;  // 指针成员
};
```

默认拷贝构造（浅拷贝）：`name.str = myname->str`（共享同一块内存）

**后果**：

- `name` 析构后 `str` 指向的内存被释放，`myname->str` 成为悬空指针（use-after-free）
- `delete myname` 时对同一块内存**二次释放**（double-free），行为未定义

### 12.4 深拷贝实现

```cpp
NAME::NAME(const NAME& other) {
    if (other.str == nullptr) { str = nullptr; return; }
    str = new char[strlen(other.str) + 1];
    strcpy(str, other.str);
}
```

### 12.5 深拷贝"三件套"（⚠️ 高频考点）

含有指针成员的类，必须同时实现：

1. **深拷贝构造函数**（`new` 新空间，`strcpy`/`memcpy` 复制内容）
2. **赋值运算符重载**（先自赋值检查，再释放旧资源，再深复制）
3. **析构函数**（释放动态申请的内存）

```cpp
NAME& NAME::operator=(const NAME& other) {
    if (this == &other) return *this;  // ① 自赋值检查
    if (str != nullptr) delete[] str; // ② 释放旧资源
    if (other.str == nullptr) { str = nullptr; return *this; }
    str = new char[strlen(other.str) + 1]; // ③ 申请新资源
    strcpy(str, other.str);                // ④ 深复制
    return *this;
}
```

---

## 十三、深入 const

### 13.1 const 成员函数

```cpp
int getYear() const;   // this: const DATE* const
```

- **不能修改**任何非静态数据成员
- `const` 对象只能调用 `const` 成员函数

### 13.2 const 数据成员

```cpp
class Test {
    const int c;  // 必须通过初始化器列表初始化
    Test(int x) : c(x) {}
};
```

### 13.3 const 引用

```cpp
const int& r = 15;      // 可以绑定右值（编译器创建临时空间）
int& r2 = 15;           // 错！非 const 引用不能绑定右值

int b = 10;
const int& a = b;       // a 是 b 的 const 别名
b = 11;  // a 也变为 11，它们是同一地址

double d = 3.14;
const int& a = d;       // 隐式转换：int temp = d; const int& a = temp;
d = 11; // a 仍为 3，因为绑定的是临时变量！
```

> ⚠️ **易错**：`const` 引用发生**隐式类型转换**时，绑定的是**临时变量**，原值修改不影响引用。

---

## 十四、综合例题（高难度）

---

### 题目 1：构造函数二义性

```cpp
class A {
public:
    A() { cout << "default\n"; }
    A(int x = 0) { cout << "default_param\n"; }
};
int main() {
    A a;   // 能编译通过吗？
}
```

**答**：**编译错误**。`A a;` 既可匹配 `A()` 也可匹配 `A(int=0)`，产生二义性（ambiguous call）。

---

### 题目 2：初始化器列表顺序陷阱

```cpp
#include <iostream>
using namespace std;
class C {
public:
    int a, b, c;
    C(int x) : c(x), b(c * 2), a(b + 1) {}
    void print() { cout << a << " " << b << " " << c << endl; }
};
int main() {
    C obj(5);
    obj.print();
}
```

**问**：输出什么？

**答**：按声明顺序 `a → b → c` 初始化：

- 先 `a = b + 1`：此时 `b` 未初始化，`a` 值**未定义**
- 再 `b = c * 2`：此时 `c` 未初始化，`b` 值**未定义**
- 最后 `c = x = 5`

输出结果**未定义**（UB）。正确写法应将初始化器列表与声明顺序一致：`a(x+11), b(x*2+1), c(x)`（倒推）或调整声明顺序。

---

### 题目 3：浅拷贝 double-free

```cpp
class Buf {
public:
    Buf(int n) : data(new int[n]), size(n) {}
    ~Buf() { delete[] data; }
    int* data;
    int  size;
};
int main() {
    Buf b1(10);
    Buf b2 = b1;   // 使用默认拷贝构造
    // b1, b2 析构时发生什么？
}
```

**答**：发生 **double-free**！默认拷贝构造浅复制，`b1.data == b2.data`，析构时同一地址被 `delete[]` 两次，行为未定义（程序崩溃或内存破坏）。

**修复**：实现深拷贝构造函数：

```cpp
Buf(const Buf& other) : size(other.size), data(new int[other.size]) {
    memcpy(data, other.data, size * sizeof(int));
}
```

---

### 题目 4：静态成员综合

```cpp
#include <iostream>
using namespace std;
class Counter {
public:
    Counter() { ++total; }
    Counter(const Counter&) { ++total; }
    ~Counter() { --total; }
    static int total;
    static int getTotal() { return total; }
};
int Counter::total = 0;

Counter make() {
    Counter c;
    return c;
}

int main() {
    Counter a, b;
    cout << Counter::getTotal() << endl;  // (1)
    Counter c = make();
    cout << Counter::getTotal() << endl;  // (2)
    {
        Counter d(a);
        cout << Counter::getTotal() << endl;  // (3)
    }
    cout << Counter::getTotal() << endl;  // (4)
}
```

**分析**（注意编译器 RVO/NRVO 优化）：

- `(1)`：`a`, `b` 构造 → total = 2；输出 `2`
- `c = make()`：`make()` 内构造 `c_local`（total=3），现代编译器 NRVO 优化，直接在 `c` 的位置构造，`c_local` 不析构也不额外拷贝构造；输出 `3`（若无优化：构造+拷贝构造+析构 → 仍为 3）
- `(3)`：`d(a)` 拷贝构造 → total = 4；输出 `4`
- `d` 离开块作用域析构 → total = 3；`(4)` 输出 `3`

> **考点**：拷贝构造函数也增加计数；静态成员由所有对象共享；栈对象离开作用域自动析构。

---

### 题目 5：const 成员函数与重载

```cpp
class Box {
public:
    int get() { return val; }
    int get() const { return -val; }
private:
    int val = 10;
};

int main() {
    Box b;
    const Box cb;
    cout << b.get() << " " << cb.get() << endl;
}
```

**答**：`10 -10`

`const` 成员函数与非 `const` 成员函数可以构成重载；`const` 对象调用 `const` 版本，非 `const` 对象调用非 `const` 版本。

---

### 题目 6：delete 与 new[] 不匹配

```cpp
class Obj {
public:
    Obj()  { cout << "C "; }
    ~Obj() { cout << "D "; }
};
int main() {
    Obj* p = new Obj[3];
    delete p;   // 应为 delete[] p
}
```

**答**：`delete p`（不带 `[]`）：只析构第一个对象，其余两个对象的析构函数**不被调用**，动态内存管理信息可能被破坏，行为未定义。正确应使用 `delete[] p`，输出 `C C C D D D`。

---

### 题目 7：=delete 的使用场景

```cpp
class Singleton {
public:
    static Singleton& getInstance() {
        static Singleton inst;
        return inst;
    }
    Singleton(const Singleton&) = delete;
    Singleton& operator=(const Singleton&) = delete;
private:
    Singleton() {}
};
int main() {
    Singleton& s1 = Singleton::getInstance();
    Singleton  s2 = s1;   // 能编译吗？
    Singleton  s3;        // 能编译吗？
}
```

**答**：

- `Singleton s2 = s1;`：调用拷贝构造 → 已 `=delete` → **编译错误**
- `Singleton s3;`：构造函数为 `private` → **编译错误**

此为标准单例模式写法。

---

### 题目 8：综合——深拷贝 + 赋值运算符

```cpp
class Stack {
public:
    Stack() : head(nullptr) {}
    Stack(const Stack& other); // 需要实现
    ~Stack();
    void push(int val);
    // ...
private:
    struct Node { int val; Node* next; };
    Node* head;
};
```

**问**：实现拷贝构造函数（深拷贝链表）。

**参考答案**：

```cpp
Stack::Stack(const Stack& other) : head(nullptr) {
    if (other.head == nullptr) return;
    // 逐节点复制
    Node* src = other.head;
    Node* prev = nullptr;
    while (src != nullptr) {
        Node* node = new Node{src->val, nullptr};
        if (prev == nullptr) head = node;
        else prev->next = node;
        prev = node;
        src = src->next;
    }
}
```

> 注意：赋值操作符同样需要实现，且须先 `clear()` 释放旧链表，再深复制；析构函数须遍历链表逐节点 `delete`。

---

## 知识点速查表（考前必看）

|知识点|核心记忆|
|---|---|
|`class` vs `struct`|默认 `private` vs `public`；其余完全等价|
|构造函数被定义后|编译器**不再自动生成**默认构造函数|
|`=default` 只用于|特殊成员函数（无参构造、析构、拷贝构造、赋值）|
|`=delete` 定义位置|必须是**首次声明**处|
|`static` 数据成员|类外单独定义一次，不能重复 `static` 关键字|
|`static` 函数成员|无 `this`，不能访问非静态成员|
|初始化器列表顺序|按**声明顺序**，不按列表书写顺序|
|`new[]` 配对|必须用 `delete[]`，否则 UB|
|浅拷贝危害|double-free + use-after-free|
|深拷贝三件套|拷贝构造 + 赋值运算符 + 析构函数|
|`C objb = obja`|拷贝构造，**不是**赋值运算|
|`const` 引用+隐式转换|绑定临时变量，原变量修改不影响引用|
|`const` 成员函数|`this` 变为 `const T* const`，不可改数据成员|
|友元函数|无 `this` 指针，不是类成员，可访问私有成员|
|`new` 失败|抛 `std::bad_alloc`，不返回 `NULL`|
|析构函数|无参、无返回值、不能显式调用、不能重载|