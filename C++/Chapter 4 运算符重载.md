## 1.1 运算符重载的概念
#### 1.1.1 什么是运算符重载

C++ 允许使用**关键字 `operator`** 加上**运算符符号**来定义**特殊名称的函数**，使得运算符能够处理用户自定义类型的数据（如复数、向量等）。

cpp

// 本质：operator op 就是一个函数名
A + B          →  operator+(A, B)  或  A.operator+(B)

- **核心理解**：重载的运算符就是**带有特殊名称的函数**，函数名由 `operator` 和运算符符号构成。
    
- **目的**：让自定义类型也能像内置类型一样使用 `+`、`-`、`*`、`<<` 等运算符，使代码更符合数学表达习惯。
    

#### 1.1.2 运算符重载的两种方法

|方法|形式|特点|
|---|---|---|
|**类成员函数**（类内定义）|`return_type operator op(param)`|左操作数是 `*this`（隐式传递）；一元运算符无参数，二元运算符只需一个显式参数（右操作数）|
|**友元函数**（类外定义）|`return_type operator op(p1, p2)`|所有操作数都显式传递；可以处理左操作数不是本类对象的情况（如 `4 + a`）|

cpp

// 成员函数形式
class Integer {
public:
    Integer operator+(const Integer& rhs) { ... }  // 左操作数是 *this
    Integer operator-() { ... }                     // 一元：操作数是 *this
};
// 友元/类外函数形式
Integer operator+(const Integer& lhs, const Integer& rhs) { ... }

#### 1.1.3 可以重载的运算符

大部分运算符都可以重载，包括：

- 算术运算符：`+` `-` `*` `/` `%`
    
- 比较运算符：`==` `!=` `<` `>` `<=` `>=`
    
- 逻辑运算符：`&&` `||` `!`
    
- 位运算符：`&` `|` `^` `~` `<<` `>>`
    
- 赋值运算符：`=` `+=` `-=` 等
    
- 自增/自减：`++` `--`
    
- 下标：`[]`
    
- 函数调用：`()`
    
- 成员访问：`->` `->*`
    
- 内存管理：`new` `new[]` `delete` `delete[]`
    
- 逗号：`,`
    

#### 1.1.4 ⚠️ 不可重载的运算符（重要考点）

|不可重载运算符|原因|
|---|---|
|`::`|作用域解析|
|`.`|成员访问|
|`.*`|通过成员指针访问成员|
|`?:`|三元条件|
|`#`|预处理符号|
|`sizeof`、`alignof`、`typeid` 等|关键字运算符|

#### 1.1.5 ⚠️ 运算符重载的限制（易错点）

1. **不能创建新运算符**：例如 `**`、`<>`、`&|`
    
2. **不能改变优先级、结合方向、操作数数量**
    
3. **`&&` 和 `||` 重载后会失去短路求值特性**（重要！）
    
4. **`->` 重载必须返回裸指针，或返回同样重载了 `->` 的对象**
    

---

## 1.2 普通运算符重载（双目与单目）

#### 1.2.1 成员函数重载示例 (双目 + 单目)

cpp

class Integer {
    int x;
public:
    Integer(int x = 0) : x(x) {}
    
    // 双目：左操作数是 *this，右操作数是 Int
    Integer operator+(const Integer& Int) {
        return Integer(x + Int.x);
    }
    
    // 双目：减法
    Integer operator-(const Integer& Int) {
        return Integer(x - Int.x);
    }
    
    // 单目：取负
    Integer operator-() {
        return Integer(-x);
    }
    
    void print() { cout << x << endl; }
};
int main() {
    Integer a(3), b(4);
    Integer c = a + b;    // a.operator+(b)，c.x = 7
    Integer d = -a;       // a.operator-()，d.x = -3
}

#### 1.2.2 参数与返回值注意事项

- **第一（左）操作数**：必须是 `*this`
    
- **第二（右）操作数**：类型任意，需注意区分 `T`、`const T&`、`T&`、`T&&`、`T*`、`const T*`
    
- **返回值**：一般是左操作数类型的**临时对象 `T`** 或左操作数自身的**引用 `T&`**（如流插入 `<<` 返回 `ostream&`）
    

---

## 1.3 自增/自减运算符（⭐重点）

#### 1.3.1 前缀与后缀的区分

这是运算符重载中**最经典的考点之一**。

||前缀 `++a`|后缀 `a++`|
|---|---|---|
|函数签名|`T& operator++()`|`T operator++(int)`|
|参数|无参数|有一个 `int` **虚拟形参**（不实际使用，仅用于区分）|
|返回值|返回**自增后对象的引用** `T&`（左值）|返回**自增前对象的副本** `T`（右值）|
|语义|先增后用|先用后增|

cpp

class Counter {
    int value;
public:
    Counter(int v = 0) : value(v) {}
    
    // 前缀 ++c：先增后用，返回引用
    Counter& operator++() {
        ++value;
        return *this;
    }
    
    // 后缀 c++：先用后增，返回副本，int 是虚拟参数
    Counter operator++(int) {
        Counter temp = *this;  // 保存当前状态
        ++value;               // 自增
        return temp;           // 返回旧值
    }
    
    void print() { cout << value << endl; }
};
int main() {
    Counter c(3);
    (++c).print();    // 输出 4，c = 4，返回引用可继续操作
    (c++).print();    // 输出 4，c = 5，返回的是临时副本
    // ++++c;          // 合法：前缀返回左值，可以连续自增
    // c++++;          // 非法：后缀返回右值（临时对象），不能再次自增
}

#### 1.3.2 ⚠️ 易错点

1. **后缀的 `int` 参数是虚拟的**——函数体内不使用，仅用于让编译器区分前缀和后缀
    
2. **前缀返回引用 `T&`，后缀返回值 `T`**——前缀更高效（不需要创建临时对象）
    
3. **`++++c` 合法，`c++++` 不合法**——因为后缀返回的是右值（临时对象），不能被再次修改
    

---

## 1.4 赋值运算符（⭐核心考点）

#### 1.4.1 简单赋值运算符

cpp

class Integer {
    int x;
public:
    Integer(int x = 0) : x(x) {}
    
    Integer& operator=(const Integer& other) {
        if (this != &other) {       // ⚠️ 必须检查自赋值
            x = other.x;
        }
        return *this;               // 返回引用，支持链式赋值 a = b = c
    }
};

**关键点**：
- 返回 `T&`，支持 `a = b = c` 链式赋值
- 必须检查**自赋值** `if (this != &other)`
- `Integer a = 3;` 是**初始化**（调用构造函数），不是赋值运算！
- `b = 5;` 中 5 通过隐式转换构造临时 `Integer(5)`，然后调用 `operator=`
#### 1.4.2 运算赋值（如 `+=`）

cpp

Integer& operator+=(const Integer& other) {
    // 方式1：直接操作
    this->x += other.x;             // [1]
    // 方式2：利用 operator+ 和 operator=
    *this = this->operator+(other); // [2]
    return *this;
}

- 方式1更高效（不创建临时对象），方式2代码复用性好
    
- 同样需要返回 `T&`
    

---

## 1.5 浅拷贝 vs 深拷贝 vs 移动赋值（⭐高频考点）

#### 1.5.1 浅拷贝（默认赋值运算符）

当类包含指针成员时，编译器自动生成的赋值运算符执行**逐成员拷贝**，指针被直接复制，导致两个对象**共享同一块动态内存**。

cpp

class IntArray {
    int *a;  // 指针成员
    int n;
public:
    IntArray(int n = 1) : n(n) { a = new int[n]; }
    ~IntArray() { delete[] a; }           // 析构释放内存
    // 未定义 operator=，使用编译器默认的浅拷贝
};
int main() {
    IntArray a(4), b;
    b = a;   // 默认赋值：b.a = a.a，两个对象指向同一块内存
    return 0; // 析构时：a 先释放，b 再释放同一块内存 → 二次释放！段错误！
}

**浅拷贝的两大问题**：

1. **内存泄漏**：b 原来的内存丢失
    
2. **二次释放**：a 和 b 析构时释放同一块内存 → 程序崩溃
    

#### 1.5.2 深拷贝（自定义赋值运算符）

```cpp
class IntArray {
    int *a;
    int n;
public:
    IntArray(int n = 1) : n(n) { a = new int[n]; }
    
    // 深拷贝赋值运算符
    IntArray& operator=(const IntArray& other) {
        if (this != &other) {           // 1. 检查自赋值
            delete[] a;                  // 2. 释放原有资源
            n = other.n;                 // 3. 复制非指针成员
            a = new int[n];              // 4. 分配新内存
            memcpy(a, other.a, sizeof(int) * n);  // 5. 复制数据
        }
        return *this;
    }
    
    ~IntArray() { delete[] a; }
};
```

**深拷贝关键步骤**：
1. 检查自赋值
2. 释放原有资源
3. 复制普通成员
4. 分配新资源
5. 复制资源内容
#### 1.5.3 移动赋值（C++11，了解）

```cpp

IntArray& operator=(IntArray&& other) {
    if (this != &other) {
        delete[] a;              // 释放自己的资源
        a = other.a; n = other.n; // 窃取资源
        other.a = nullptr;        // 置空源对象指针，防止析构时释放
        other.n = 0;
    }
    return *this;
}
```
**核心思想**：将资源所有权从一个对象转移到另一个对象，避免不必要的深拷贝。使用 `std::move()` 将左值转为右值来触发移动语义。

---
## 2.1 下标运算符 `[]`（⭐重要）

#### 2.1.1 基本规则

- **必须以成员函数形式重载**（不能是友元/类外函数）
    
- **必须同时提供 const 和非 const 两个版本**
    

cpp

class IntArray {
    int *a;
    int n;
public:
    // 非const版本：可读可写
    int& operator[](int i) {
        if (i >= 0 && i < n) return a[i];
        throw std::out_of_range("out of range");
    }
    
    // const版本：只读（用于const对象）
    const int& operator[](int i) const {
        if (i >= 0 && i < n) return a[i];
        throw std::out_of_range("out of range");
    }
};
int main() {
    IntArray a(4);
    a[0] = 10;           // 调用非const版本，可修改
    
    const IntArray b = a;
    cout << b[0];        // 调用const版本，只能读取
    // b[0] = 5;         // 错误！const版本返回const引用，不可修改
}

#### 2.1.2 ⚠️ 为什么需要两个版本？

- **const 对象只能调用 const 成员函数**
    
- 如果只提供非 const 版本，`const IntArray` 对象就无法使用 `[]`
    
- 非 const 版本返回 `T&`（可修改），const 版本返回 `const T&`（只读）
    

---

## 2.2 函数对象 `operator()`（⭐重要）
#### 2.2.1 概念

重载 `operator()` 的类称为**函数对象（Functor）**，该类的对象可以像函数一样被调用。它是 **callable** 类型的一种。

cpp

class cmp {
public:
    bool operator()(const int& a, const int& b) {
        return a < b;
    }
};
int main() {
    cmp f;
    cout << f(1, 2) << endl;  // 输出 1 (true)，f 像函数一样使用
}

#### 2.2.2 无状态 vs 有状态

|类型|特点|示例|
|---|---|---|
|无状态|不依赖对象成员，每次调用结果相同|上述 `cmp` 类|
|有状态|依赖对象内部状态，相同参数可能不同结果|见下方 `GreaterThan`|

cpp

class GreaterThan {
    int baseline;  // 阈值由构造时确定
public:
    GreaterThan(int x) : baseline(x) {}
    bool operator()(const int& x) {
        return x > baseline;
    }
};
int main() {
    GreaterThan g1(10), g2(20);
    cout << g1(15) << endl;  // 输出 1 (true, 15>10)
    cout << g2(15) << endl;  // 输出 0 (false, 15<20)
    // 相同参数 15，但不同对象返回不同结果（有状态）
}

#### 2.2.3 函数对象 vs 普通函数 vs Lambda
```cpp

vector<int> a = {5, 10, 15, 20, 25};
// 1. 函数对象
cout << *find_if(a.begin(), a.end(), GreaterThan(10)) << endl;  // 15
// 2. 普通函数
bool GreaterThan10(const int& x) { return x > 10; }
cout << *find_if(a.begin(), a.end(), GreaterThan10) << endl;   // 15
// 3. Lambda
cout << *find_if(a.begin(), a.end(), [](int x){ return x > 10; }) << endl;
```
**函数对象的优势**：既有**对象持状态**的特征，又有**函数可调用**的特征，在 STL 中广泛应用。

## 2.3 类外定义运算符重载

#### 2.3.1 为什么需要类外定义？

两种场景**必须**使用类外定义：

1. **左操作数不是本类对象**：如 `4 + a`，成员函数要求左操作数是 `*this`（本类对象），无法满足
    
2. **左操作数的类定义时不知道本类存在**：如 `cout << obj`，`ostream` 类不知道用户自定义类型
    
	```cpp
	struct Integer {
	    int x;
	    Integer(int x = 0) : x(x) {}
	    
	    // 成员函数：只能处理 a + 4（左操作数是 Integer）
	    Integer operator-(const Integer& Int) { return Integer(x - Int.x); }
	};
	// 类外定义：能处理 5 + a（左操作数是 int）
	Integer operator+(const Integer& lhs, const Integer& rhs) {
	    return Integer(lhs.x + rhs.x);
	}
	int main() {
	    Integer a(3);
	    Integer b = a + 4;   // 先隐式转换 4→Integer(4)，调用类外 operator+
	    Integer c = 5 + a;   // 必须类外定义，成员函数无法处理
	}
	```
#### 2.3.2 ⚠️ 类外定义无法访问 private 成员

当类使用 `class` 关键字（而非 `struct`）且成员为 `private` 时，类外定义的运算符函数无法直接访问。此时需要**友元函数**。

---

## 2.4 友元函数与友元类（⭐重要）

#### 2.4.1 友元函数

在类内部用 `friend` 关键字声明的**外部函数**，虽然不是类的成员，但可以访问类的**私有成员和受保护成员**。

cpp

class Integer {
    int x;  // private
public:
    Integer(int x = 0) : x(x) {}
    
    // 声明友元函数（在类内部声明，但不是成员函数）
    friend Integer operator+(const Integer& lhs, const Integer& rhs);
    friend ostream& operator<<(ostream& o, const Integer& hs);
};
// 类外实现（不是成员，不加 Integer::）
Integer operator+(const Integer& lhs, const Integer& rhs) {
    return Integer(lhs.x + rhs.x);  // 可以直接访问 private 成员 x
}
ostream& operator<<(ostream& o, const Integer& hs) {
    o << hs.x;      // 直接访问 private 成员
    return o;
}

#### 2.4.2 友元类

如果类 B 是类 A 的友元类，则 B 的**所有成员函数**都可以访问 A 的私有成员。

cpp

class A {
    friend class B;  // 声明 B 为友元类
private:
    int secret;
};
class B {
public:
    void access(A& a) { cout << a.secret; }  // 合法：B 是 A 的友元
};

#### 2.4.3 ⚠️ 哪些运算符必须用成员函数？

|必须为成员函数|原因|
|---|---|
|`=` 赋值|与默认语义保持一致|
|`[]` 下标|C++ 规定|
|`()` 函数调用|C++ 规定|
|`->` 成员访问|C++ 规定|
|类型转换运算符|如 `operator int()`|

---

## 2.5 隐式转换与 `explicit`（⭐易错考点）

#### 2.5.1 隐式转换机制

如果类型 `T` 存在构造函数 `T(T1)`，则 `T1` 类型对象可以**隐式转换**为 `T` 类型对象。

~~~cpp

class Integer {
    int x;
public:
    Integer(int x = 0) : x(x) {}  // 单参数构造函数 = 转换构造函数
    
    friend Integer operator+(const Integer& lhs, const Integer& rhs) {
        return Integer(lhs.x + rhs.x);
    }
};
int main() {
    Integer i1(3), i2;
    i2 = 1.1 + i1;     // 隐式转换链：double→int→Integer
    // 1.1(double) → 1(int) → Integer(1)
    // 然后调用 operator+(Integer(1), Integer(3))
}
~~~
**隐式转换链示例**：

- `const char* → string`：`s = "Hello";`
    
- `int → Integer`：构造函数 `Integer(int)`
    
- `double → int → Integer`：先截断再构造
    

#### 2.5.2 `explicit` 关键字

**关闭构造函数的自动隐式类型转换**，只能显式调用。

~~~cpp

class Fraction {
    int num, den;
public:
    explicit Fraction(int n = 0, int d = 1) : num(n), den(d) {}
    // explicit 禁止了 Fraction f = 3; 这种隐式转换
};
int main() {
    // Fraction f = 3;       // 错误！explicit 禁止隐式转换
    Fraction f(3);            // 正确：显式调用
    Fraction f2 = Fraction(3); // 正确：显式转换
}
~~~

#### 2.5.3 `nullptr` 的必要性

~~~cpp

void kissGirlfriend(int gfID)   { cout << "int" << endl; }
void kissGirlfriend(Girlfriend* gf) { cout << "pointer" << endl; }
int main() {
    kissGirlfriend(nullptr);  // 调用指针版本（明确的空指针字面量）
    kissGirlfriend(0);        // 调用 int 版本！（0 被解释为整数）
    // NULL 通常也定义为 0，所以也会调用 int 版本
}
~~~
**`nullptr` 的类型是 `std::nullptr_t`**，可以隐式转换为任意指针类型，但不能转换为 `int`，避免了 C 语言中 `NULL` 的歧义问题。

#### 2.5.4 重载匹配与 const（易错）

~~~cpp

class Integer {
public:
	friend ostream& operator<<(ostream& o, const Integer& hs);  // const 版本
	friend ostream& operator<<(ostream& o, Integer& hs);         // 非const版本
};
int main() {
	Integer i1(1);
	const Integer i2(2);
	cout << i1 << "," << i2 << endl;
	// i1 (非const) → 优先匹配非const版本
	// i2 (const)  → 只能匹配const版本
}
~~~
**匹配优先级**：

1. 类型直接匹配优先
    
2. const 实参匹配 const 版本
    
3. 非 const 实参优先匹配非 const 版本；无非 const 版本时隐式转为 const 匹配

## 例题1：自增运算符前后缀

**题目**：以下代码输出什么？
~~~cpp

class Number {
    int n;
public:
    Number(int x = 0) : n(x) { cout << "C" << n << " "; }
    Number(const Number& other) : n(other.n) { cout << "Copy "; }
    
    Number& operator++() {
        ++n;
        cout << "Pre++ ";
        return *this;
    }
    
    Number operator++(int) {
        Number temp = *this;
        ++n;
        cout << "Post++ ";
        return temp;
    }
    
    int get() const { return n; }
};
int main() {
    Number a(5);
    Number b = ++a;
    cout << "| a=" << a.get() << " b=" << b.get() << " | ";
    
    Number c = a++;
    cout << "| a=" << a.get() << " c=" << c.get() << " | ";
    
    ++++a;
    // a++++;  // 这行如果取消注释会怎样？
    return 0;
}
~~~
**答案与解析**：

~~~text

C5 Pre++ | a=6 b=6 | Copy Post++ | a=7 c=6 | Pre++ Pre++

- `++a`：调用前缀，先增后用，`a.n` 变为 6，返回 `a` 的引用赋给 `b`（无拷贝）
    
- `a++`：调用后缀，先用后增，先拷贝 `a`（Copy），`a.n` 变为 7，返回拷贝的临时对象赋给 `c`
    
- `++++a`：合法，前缀返回引用，可以连续自增
    
- `a++++`：如果取消注释，**编译错误**！后缀返回临时对象（右值），不能被再次自增
    
~~~
---

## 例题2：赋值运算符深拷贝

**题目**：以下代码有什么问题？如何修复？

~~~cpp

class String {
    char* str;
public:
    String(const char* s = "") {
        str = new char[strlen(s) + 1];
        strcpy(str, s);
    }
    ~String() { delete[] str; }
    void print() { cout << str << endl; }
    // 注意：没有定义拷贝构造和赋值运算符
};
int main() {
    String s1("Hello");
    String s2("World");
    s2 = s1;          // 问题1
    s2.print();       // 问题？
    return 0;         // 问题2
}
~~~
**答案与解析**：

**问题**：

1. `s2 = s1` 使用默认浅拷贝，`s2.str` 被覆盖指向 `s1.str` 的内存，原来 `s2.str` 指向的 "World" 内存**泄漏**
    
2. 析构时 `s1` 和 `s2` 都释放同一块内存，**二次释放**导致程序崩溃
    

**修复方案**（添加深拷贝赋值运算符）：

~~~cpp

String& operator=(const String& other) {
    if (this != &other) {               // 检查自赋值
        delete[] str;                    // 释放原有资源
        str = new char[strlen(other.str) + 1];  // 分配新内存
        strcpy(str, other.str);          // 复制内容
    }
    return *this;
}
~~~
---

## 例题3：下标运算符 const 版本

**题目**：分析以下代码中的错误。

~~~cpp
	class Array {
		int data[10];
	public:
		int& operator[](int i) { return data[i]; }  // 只定义了非const版本
	};
	void printArray(const Array& arr) {
		for (int i = 0; i < 10; i++) {
			cout << arr[i] << " ";  // 此处能否编译通过？为什么？
		}
	}
	int main() {
		Array a;
		a[0] = 5;
		printArray(a);
		return 0;
	}
~~~

**答案与解析**：

**编译错误！** `printArray` 的参数是 `const Array& arr`，const 对象**只能调用 const 成员函数**。但 `Array` 只定义了非 const 版本的 `operator[]`，const 对象无法调用。

**修复方法**：添加 const 版本

cpp

const int& operator[](int i) const { return data[i]; }

**原则**：下标运算符应同时提供两个版本——非 const 返回 `T&`（可读写），const 返回 `const T&`（只读）。