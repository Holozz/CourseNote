## 目录

- [[#一、多态的概念]]
    - [[#1.1 什么是多态]]
    - [[#1.2 多态的三种形式]]
    - [[#1.3 静态绑定 vs 动态绑定]]
- [[#二、函数重载（多态之一）]]
- [[#三、虚函数与动态类型（多态之核心）]]
    - [[#3.1 静态类型与动态类型]]
    - [[#3.2 虚函数的基本用法]]
    - [[#3.3 "一旦为虚，永远为虚"]]
    - [[#3.4 Override 覆盖 vs Overwrite 隐藏]]
    - [[#3.5 虚函数的意义：开放扩展]]
- [[#四、抽象类与纯虚函数]]
    - [[#4.1 问题引入：抽象概念的困境]]
    - [[#4.2 纯虚函数]]
    - [[#4.3 抽象类]]
    - [[#4.4 抽象类的语法约束]]
    - [[#4.5 接口（Interface）在 C++ 中的模拟]]
- [[#五、虚析构函数]]
- [[#六、RTTI 运行时类型识别]]
    - [[#6.1 typeid 运算符]]
    - [[#6.2 dynamic_cast 类型转换]]
- [[#七、final 关键字（C++11）]]
- [[#八、多态的实现原理（选讲）]]
    - [[#8.1 虚函数表（vtable）]]
    - [[#8.2 内存布局]]
- [[#九、例题精选]]

---

## 一、多态的概念

### 1.1 什么是多态

> **通俗理解**：同一个"名字"（标识符），根据使用场景或对象的实际类型，表现出不同的行为。

> **严谨定义**：程序语言中，**多态（Polymorphism）** 特指一个标识符指代不同类型的数据，即由具体的数据类型决定该标识符的语义。

**经典比喻**（课件原话）：

> 一桌兄弟吃饭，你发出消息"吃饭"：
> 
> - 兄弟1（中国人）：去拿筷子
> - 兄弟2（美国人）：去拿刀叉
> - 兄弟3（印度人）：伸出了手

这里 `Brother&` 类型对象的"吃饭"行为，由它指代的**实际对象类型**的程序定义决定。这就是多态的精髓。

---

### 1.2 多态的三种形式

|多态形式|标识符|典型机制|
|---|---|---|
|**函数重载**|函数名|编译器根据参数类型选择不同版本|
|**方法覆盖**|基类指针/引用|虚函数 + 动态绑定|
|**泛型/模板**|模板名（如 `vector`）|参数化类型，编译期展开|

---

### 1.3 静态绑定 vs 动态绑定

**绑定**：将标识符指派到具体函数/方法的过程。

||静态绑定|动态绑定|
|---|---|---|
|**时机**|编译期|运行期|
|**速度**|快|略慢（需查虚表）|
|**适用**|函数重载、模板|虚函数（方法覆盖）|
|**C++ 默认**|✅ 默认是静态绑定|需要 `virtual` 关键字触发|

> ⚠️ **易错点**：C++ 默认是静态绑定！即使派生类重写了函数，用基类指针调用，不加 `virtual` 也不会触发多态。

---

## 二、函数重载（多态之一）

函数重载是**同一作用域**内，同名函数有不同的参数列表（类型、数量、顺序）。

```cpp
int abs(int x) {
    return (x >= 0 ? x : -x);
}

double abs(double x) {
    return (x >= 0.0 ? x : -x);
}

int main() {
    cout << abs(-5);    // 调用 int 版本
    cout << abs(3.14);  // 调用 double 版本
}
```

**设计意义**：

- **使用角度**：调用者用同一名字，编译器根据实参选择行为
- **设计角度**：由形参数量和类型决定不同的函数定义
- **本质**：静态绑定，编译时已确定调用哪个版本（称为"重载决议"）

---

## 三、虚函数与动态类型（多态之核心）

### 3.1 静态类型与动态类型

> **静态类型**：编译时分析得到的表达式类型，程序执行时**不会更改**。

> **动态类型**：若某个泛左值表达式指代某个**多态对象**，则其最终派生对象的类型称为其动态类型。

```cpp
struct B { virtual ~B() {} };  // 多态类型（含虚函数）
struct D : B {};

D d;          // 最终派生对象
B* ptr = &d;  // (*ptr) 的静态类型是 B
              // (*ptr) 的动态类型是 D
```

> 💡 **关键**：只有多态类型（含有至少一个虚函数的类）的指针/引用才有"动态类型"之说。

---

### 3.2 虚函数的基本用法

**虚函数**：在基类成员函数声明前加 `virtual` 关键字。

```cpp
class Fruit {
public:
    virtual void say() {
        printf("I'm a fruit!\n");
    }
};

class Apple : public Fruit {
public:
    void say() {    // 自动继承虚函数属性，不需要再写 virtual
        printf("I'm an apple!\n");
    }
};

int main() {
    Apple a;
    Fruit* fPtr = &a;
    fPtr->say();   // 输出: I'm an apple!（动态绑定）
}
```

**对比无 virtual 的情况**：

```cpp
// 若 Fruit::say() 没有 virtual
Fruit* fPtr = &a;
fPtr->say();  // 输出: I'm a fruit!（静态绑定，按声明类型调用）
```

> ⚠️ **易错点**：`fPtr` 的静态类型是 `Fruit*`，如果 `say` 不是虚函数，编译器直接翻译为 `call Fruit::say(fPtr)`，完全忽略 `a` 实际上是 `Apple` 类型！

---

### 3.3 "一旦为虚，永远为虚"

这是虚函数最重要的规则之一：

> **含义1**：在公有继承层次中，某个类的成员函数声明为 `virtual`，则其**直接或间接**派生类中的**相同签名**函数，都是虚函数，不论是否再次用 `virtual` 声明。

> **含义2**：任何虚函数都可以被派生类再次重新定义，重新定义后依然是虚函数。因此，**虚函数既可以被继承，也可以被重新定义**。

```cpp
class A {
public:
    virtual void f();  // 声明为虚函数
};

class B : public A {
public:
    void f();  // 这里 f 依然是虚函数（不用再写 virtual）
};

class C : public B {
public:
    void f();  // 这里 f 仍然是虚函数
};
```

---

### 3.4 Override 覆盖 vs Overwrite 隐藏

这是 **最容易混淆** 的概念，必须掌握：

||覆盖（Override）|隐藏（Overwrite/Overload）|
|---|---|---|
|**基类函数**|有 `virtual`|无 `virtual`（或参数不同）|
|**函数名**|相同|相同|
|**参数列表**|完全相同|相同或不同|
|**效果**|动态绑定，调用实际类型的函数|静态绑定，基类指针调用基类函数|

**完整对比表**（来自课件）：

|类型|作用域|是否虚函数|函数名|函数签名|
|---|---|---|---|---|
|重载（Overload）|相同|-|相同|不同|
|隐藏（Overwrite）|不同|否|相同|相同或不同|
|覆盖（Override）|不同|是|相同|相同|

**关键记忆**：

- 用基类**指针或引用**访问：覆盖调用派生类函数；隐藏调用基类函数
- 派生类对象**赋值给基类对象**（切片）：按基类行为调用

---

### 3.5 虚函数的意义：开放扩展

```cpp
class Animal {
public:
    virtual void eat() { printf("I eat something.\n"); }
};

class Cat : public Animal {
public:
    void eat() override { printf("I like fish!\n"); }
};

class Dog : public Animal {
public:
    void eat() override { printf("I like bones!\n"); }
};

// 这个函数对所有 Animal 的子类都有效！
void whatDoYouPrefer(Animal* a) {
    a->eat();  // 动态绑定，调用实际类型的 eat()
}
```

> **开放扩展（Open for Extension）**：设计师根据基类写的函数（模块），不仅适用于已知的 `Cat`、`Dog`，还可以扩展到 `Bear`、`Elephant`，甚至未知的动物类型，**无需修改已有代码**！

---

## 四、抽象类与纯虚函数

### 4.1 问题引入：抽象概念的困境

考虑如下代码：

```cpp
Animal &&ani = Animal();  // 问题：Animal 是什么具体动物？
ani.eat();                // Animal 本身都不知道自己是什么！
```

**两个问题**：

1. `ani` 指代的是一（个/只/条？）（动物/猫/狗/四不像？）
2. `Animal` 都不知道自己是什么，真的知道喜欢吃什么吗？

**早期笨办法**（课件提到）：

- 保护构造函数，阻止 client 构造抽象对象
- 基类虚函数抛出异常，强迫派生类覆盖

这很丑陋。C++ 有更优雅的解决方案：**纯虚函数 + 抽象类**。

---

### 4.2 纯虚函数

> **纯虚函数**：在虚函数声明后加 `= 0`，表示该函数**只有声明，没有（强制要求的）实现**。

```cpp
class Animal {
public:
    virtual void eat() = 0;  // 纯虚函数
};
```

**特殊规则**：

- 纯虚函数可以（但不建议）给出定义体
- 若**纯虚析构函数**，则**必须提供定义**（否则链接错误）

---

### 4.3 抽象类

> **抽象类（Abstract Class）**：定义或继承了**至少一个纯虚函数**的类。

**核心规则**：

1. **抽象类不能被实例化**（不能创建对象）
2. 抽象类的子类仍是抽象类，除非**所有纯虚函数都被覆写为非纯虚**
3. 能声明为指针或引用，指代派生类对象

```cpp
struct Abstract {
    virtual void f() = 0;   // 纯虚
};

struct Concrete : Abstract {
    void f() override {}    // 覆写，不再是纯虚
    virtual void g();       // 新增虚函数
};

struct Abstract2 : Concrete {
    void g() override = 0;  // 将继承来的虚函数再次变为纯虚，所以 Abstract2 又是抽象类
};

int main() {
    // Abstract a;   // ❌ 错误：抽象类不能实例化
    Concrete b;      // ✅
    Abstract& a = b; // ✅ 基类引用指向派生类对象
    a.f();           // 虚派发到 Concrete::f()
}
```

---

### 4.4 抽象类的语法约束

抽象类**能**做的事：

- ✅ 声明为指针或引用
- ✅ 作为基类

抽象类**不能**做的事：

- ❌ `Animal a;`——不能声明对象
- ❌ `(Animal)dog`——不能显式转为抽象类对象
- ❌ `func(Animal)`——不能作为函数参数类型（传值）
- ❌ `Animal func()`——不能作为函数返回值类型（传值）

> 💡 **一句话总结**：抽象类**为多态而生**，只能作为基类指针/引用存在！

---

### 4.5 接口（Interface）在 C++ 中的模拟

C++ 没有 `interface` 关键字，但可以用特殊的抽象类来模拟（类比 Java 接口）：

**Java 接口特征** → **C++ 模拟方式**：

|Java 接口特征|C++ 模拟方式|
|---|---|
|成员函数全为抽象方法|成员函数全为纯虚函数|
|可以有静态成员|✅ 可以有静态成员|
|不包含自己的数据|不包含非静态数据成员|
|无构造函数|不需要构造函数|
|可以有默认方法（Java 8+）|有虚析构函数即可|
|多实现无歧义|用**虚继承**保证唯一，多继承不会命名冲突|

```cpp
class Shape {           // 接口
public:
    virtual void draw() = 0;
    // virtual ~Shape() {}  // 应当添加虚析构
};

class Shape2D : public virtual Shape {  // 抽象类（继承接口）
public:
    static int count;
    virtual float getArea() = 0;
    virtual float getPerimeter() = 0;
};

class Circle : public virtual Shape2D { // 具体类（实现接口）
public:
    Circle(float r = 1) : r(r) { count++; }
    void draw() override { cout << "Circle, r = " << r << endl; }
    float getArea() override { return 3.14f * r * r; }
    float getPerimeter() override { return 2 * 3.14f * r; }
    ~Circle() { count--; }
private:
    float r;
};
```

**接口优势**：

- 继承接口的派生类**必须**覆盖实现所有接口成员（编译器强制）
- 没有数据和业务逻辑，可以无歧义地被多重继承
- 可用于标记特征（如 `SYSUer` 接口标记所有与中大有关的人）

> ⚠️ **易错点**：若 `Circle` 没有实现 `Shape2D` 的所有纯虚函数，`Circle` 仍是抽象类，实例化时会产生**编译错误**。虚函数有声明但无定义是**链接错误**。

---

## 五、虚析构函数

**为什么需要虚析构函数？**

```cpp
Shape2D* c1 = new Circle();
delete c1;  // ❌ 危险！若 Shape2D 析构函数不是虚函数
            //    只调用 Shape2D::~Shape2D()，不调用 Circle::~Circle()
            //    → 内存泄漏！
```

**原因**：`delete c1` 时，编译器看到 `c1` 是 `Shape2D*`，若析构函数不是虚函数，只会静态绑定到 `Shape2D` 的析构函数，派生类的析构不会执行。

**解决方案**：

```cpp
class Shape {
public:
    virtual ~Shape() {}  // 虚析构函数！
};
```

**规则**（来自课件）：

> **任何包含虚函数的基类，其析构函数必须为"公开且虚"，或"受保护且非虚"。否则很容易导致内存泄漏。**

**原理**：虽然析构函数不继承，但若基类析构函数为 `virtual`，则派生类的析构函数始终**覆盖**它，从而可以通过基类指针 `delete` 动态分配的多态类型对象，正确调用派生类析构函数。

---

## 六、RTTI 运行时类型识别

### 6.1 typeid 运算符

> **RTTI（Run Time Type Identification）**：通过运行时类型识别，程序能够使用基类的指针或引用来**检查**其所指对象的**实际派生类型**。

C++ 提供两个操作符：`typeid` 和 `dynamic_cast`。

**使用前需包含头文件**：`#include <typeinfo>`

**两种语法**：

```cpp
// 语法1：typeid(类型)
// 指代表示该类型的 type_info 对象

// 语法2：typeid(表达式)
// 若表达式是多态类型对象的泛左值表达式，返回动态类型的 type_info
// 若不是多态类型，编译期静态推导

struct B { virtual ~B() {} };  // 多态类型
struct D : B {};

D d;
B* p = &d;

cout << typeid(*p).name();          // 输出 D 的类型名（动态类型）
cout << typeid(B).name();           // 输出 B 的类型名（静态）
cout << (typeid(*p) == typeid(D));  // true
```

> ⚠️ **易错点**：`typeid` 对多态类型指针解引用才能得到动态类型！`typeid(p)` 得到的是指针本身的类型（`B*`），`typeid(*p)` 才是动态类型。

---

### 6.2 dynamic_cast 类型转换

> **`dynamic_cast`**：沿继承层级**向上、向下及侧向**安全转换指针或引用。

**语法**：

```cpp
dynamic_cast<新类型>(表达式)
```

**转换结果**：

- 转型成功：返回新类型的值
- 转型失败，新类型是**指针**：返回 `nullptr`
- 转型失败，新类型是**引用**：抛出 `std::bad_cast` 异常

```cpp
Animal* a = new DonaldDuck();  // 向上转型（安全，隐式即可）
Duck* d = dynamic_cast<Duck*>(a);    // 向下转型
Actor* c = dynamic_cast<Actor*>(d);  // 侧向转型（跨继承分支）
delete c;
```

> ⚠️ **易错点**：`dynamic_cast` 只能用于**多态类型**（含虚函数的类）。对非多态类型使用会编译错误。

**对比 `static_cast`**：`static_cast` 向下转型不做运行时检查，不安全；`dynamic_cast` 运行时检查，失败时返回 `nullptr`，更安全。

---

## 七、final 关键字（C++11）

> **`final`**：指定某个虚函数**不能在子类中被覆盖**，或某个**类不能被继承**。

```cpp
struct Base {
    virtual void foo();
};

struct A : Base {
    void foo() final;    // foo 不能再被覆盖
    // void bar() final; // ❌ 错误：bar 非虚函数，不能用 final
};

struct B final : A {    // B 不能被继承
    // void foo() override; // ❌ 错误：foo 在 A 中是 final
};

struct C : B {          // ❌ 错误：B 是 final，不能被继承
};
```

**使用场景**：

- 希望封闭某个虚函数的扩展点
- 希望某个类不再被继承（类似 Java 的 `final class`）

---

## 八、多态的实现原理（选讲）

### 8.1 虚函数表（vtable）

C++ 多态通过**虚函数表（Virtual Function Table，vtable）** 实现：

**三个核心对象**：

|对象|说明|
|---|---|
|**数据对象**|包含指向虚函数表的指针（`vfp`）|
|**虚函数表（vtable）**|每种多态类型**共享一张**；索引对应虚函数声明顺序；`-1` 位置存实际类型描述对象（`type_info`）|
|**类型描述类（type_info）**|每种类型一个实例，存储类型信息|

**三个关键指针**：

|指针|说明|
|---|---|
|`*ptr`|多态类型指针（指向实际对象）|
|`*vfp`|指向实际类型虚函数表的指针（嵌在对象中）|
|`*type_info`|指向类型描述对象的指针（在 vtable 中）|

---

### 8.2 内存布局

以单继承为例（`CA` 为基类，`CB` 为派生类，所有成员函数为虚函数）：

```
CB 对象内存布局:
┌─────────────┐
│   vfp ──────┼──→ CB 的 vtable:
├─────────────┤       [-1]: type_info for CB
│  CA 的数据   │       [0]:  CB::f1()
├─────────────┤       [1]:  CB::f2()
│  CB 的数据   │       ...
└─────────────┘

CA 对象内存布局:
┌─────────────┐
│   vfp ──────┼──→ CA 的 vtable:
├─────────────┤       [-1]: type_info for CA
│  CA 的数据   │       [0]:  CA::f1()
└─────────────┘
```

**调用过程**：`ptr->f1()` 实际上是：

1. 从 `ptr` 指向的对象中取出 `vfp`
2. 在 `vfp` 指向的虚函数表中查找 `f1` 的函数指针
3. 调用该函数指针

**注意事项**：

- 多态类型 `sizeof` 结果**包括 vfp 指针空间**
- 无非静态数据成员的类 `sizeof(T) = 1`，被继承后可被优化不占空间

---

## 九、例题精选

### 例题 1：覆盖 vs 隐藏判断

```cpp
class Base {
public:
    void f(int x) { cout << "Base::f(int)" << endl; }
    virtual void g(int x) { cout << "Base::g(int)" << endl; }
    virtual void h(int x) { cout << "Base::h(int)" << endl; }
};

class Derived : public Base {
public:
    void f(int x) { cout << "Derived::f(int)" << endl; }    // (A)
    void g(double x) { cout << "Derived::g(double)" << endl; } // (B)
    void h(int x) { cout << "Derived::h(int)" << endl; }    // (C)
};

int main() {
    Derived d;
    Base* p = &d;
    p->f(1);   // (1)
    p->g(1);   // (2)
    p->h(1);   // (3)
    d.g(1.0);  // (4)
    d.g(1);    // (5)
}
```

**请判断 (A)(B)(C) 各属于什么关系，并写出 (1)~(5) 的输出。**

<details> <summary>📝 解析</summary>

**关系判断**：

- **(A) `f(int)`**：`Base::f` 无 `virtual` + 同名同参 → **隐藏（Overwrite）**
- **(B) `g(double)`**：`Base::g` 有 `virtual` 但参数不同（`int` vs `double`）→ **隐藏（Overwrite）**（参数不同不构成覆盖）
- **(C) `h(int)`**：`Base::h` 有 `virtual` + 同名同参 → **覆盖（Override）**

**输出**：

1. `p->f(1)` → 静态类型 `Base*`，`f` 非虚 → `Base::f(int)` → 输出 `Base::f(int)`
2. `p->g(1)` → `g` 是虚函数，但 `Derived::g(double)` 与 `Base::g(int)` 参数不同，不构成覆盖，所以 `Derived` 没有覆盖 `Base::g(int)` → 输出 `Base::g(int)`
3. `p->h(1)` → `h` 是虚函数，`Derived::h(int)` 覆盖了它 → 动态绑定 → 输出 `Derived::h(int)`
4. `d.g(1.0)` → 直接调用 `Derived::g(double)` → 输出 `Derived::g(double)`
5. `d.g(1)` → `int` 隐式转 `double`，调用 `Derived::g(double)` → 输出 `Derived::g(double)`

> ⚠️ 关键：(B) 参数类型不同（`int` vs `double`）导致不构成覆盖，而是隐藏，所以通过 `Base*` 调用 `g(int)` 仍然调用基类版本！

</details>

---

### 例题 2：虚析构函数与内存泄漏

```cpp
class Base {
public:
    Base() { cout << "Base()" << endl; }
    ~Base() { cout << "~Base()" << endl; }  // 注意：非虚析构
};

class Derived : public Base {
public:
    Derived() : data(new int[100]) { cout << "Derived()" << endl; }
    ~Derived() { delete[] data; cout << "~Derived()" << endl; }
private:
    int* data;
};

int main() {
    Base* p = new Derived();
    delete p;  // (?)
}
```

**问题**：

1. 输出什么？
2. 有没有内存泄漏？
3. 如何修复？

<details> <summary>📝 解析</summary>

**输出**：

```
Base()
Derived()
~Base()
```

**分析**：

- `delete p` 时，`p` 的静态类型是 `Base*`
- `Base::~Base()` 是非虚析构函数
- 静态绑定，只调用 `Base::~Base()`
- `~Derived()` 没有被调用！

**内存泄漏**：`Derived::data` 指向的 `int[100]` 没有被释放 → **有内存泄漏**！

**修复**：将 `Base` 的析构函数改为虚函数：

```cpp
virtual ~Base() { cout << "~Base()" << endl; }
```

修复后输出：

```
Base()
Derived()
~Derived()
~Base()
```

析构顺序是**从派生类到基类**，先 `~Derived()` 再 `~Base()`。

</details>

---

### 例题 3：抽象类语法判断

```cpp
class Shape {
public:
    virtual void draw() = 0;
    virtual ~Shape() {}
};

class Shape2D : public virtual Shape {
public:
    static int count;
    virtual float getArea() = 0;
    virtual float getPerimeter() = 0;
};

int Shape2D::count = 0;

Shape fun1(int);       // ①
void fun2(Shape2D a);  // ②
Shape& fun3(Shape2D& a); // ③

int main() {
    Shape2D x;   // ④
    Shape* p;    // ⑤
    return 0;
}
```

**判断 ①②③④⑤ 各是否合法，并说明原因。**

<details> <summary>📝 解析</summary>

- **①** `Shape fun1(int)` → ❌ **非法**：函数返回值类型为抽象类 `Shape`（传值），抽象类不能作为返回值类型
- **②** `void fun2(Shape2D a)` → ❌ **非法**：函数参数为抽象类 `Shape2D`（传值），抽象类不能作为参数类型
- **③** `Shape& fun3(Shape2D& a)` → ✅ **合法**：参数和返回值都是引用，引用不需要实例化对象
- **④** `Shape2D x` → ❌ **非法**：`Shape2D` 是抽象类（含纯虚函数 `getArea`、`getPerimeter`），不能实例化
- **⑤** `Shape* p` → ✅ **合法**：指针可以声明，不需要实例化对象，可以后续指向派生类对象

> 💡 抽象类只能出现在**指针**或**引用**的场合，传值均非法！

</details>

---

### 例题 4：typeid 与 dynamic_cast

```cpp
#include <typeinfo>
#include <iostream>
using namespace std;

class Animal { public: virtual ~Animal() {} };
class Dog : public Animal { public: virtual void bark() { cout << "Woof!" << endl; } };
class Cat : public Animal {};

int main() {
    Animal* a1 = new Dog();
    Animal* a2 = new Cat();

    // (1) 判断实际类型
    if (typeid(*a1) == typeid(Dog)) cout << "a1 is a Dog" << endl;

    // (2) 向下转型
    Dog* d = dynamic_cast<Dog*>(a1);
    if (d) d->bark();

    // (3) 向下转型失败
    Dog* d2 = dynamic_cast<Dog*>(a2);
    cout << (d2 == nullptr ? "d2 is null" : "d2 is not null") << endl;

    // (4) 注意：typeid(a1) 与 typeid(*a1) 的区别
    cout << typeid(a1).name() << endl;   // (A)
    cout << typeid(*a1).name() << endl;  // (B)

    delete a1; delete a2;
}
```

**问题**：写出所有输出，并解释 (A) 和 (B) 的区别。

<details> <summary>📝 解析</summary>

**输出**：

```
a1 is a Dog
Woof!
d2 is null
P6Animal        (或类似的指针类型名，依编译器)
3Dog            (或类似的 Dog 类型名，依编译器)
```

**解析**：

- **(1)**：`*a1` 是多态类型的泛左值表达式，`typeid(*a1)` 运行时求值，得到动态类型 `Dog` 的 `type_info`，成立。
- **(2)**：`a1` 实际指向 `Dog` 对象，`dynamic_cast<Dog*>(a1)` 成功，返回有效指针。
- **(3)**：`a2` 实际指向 `Cat` 对象，`dynamic_cast<Dog*>(a2)` 失败，返回 `nullptr`。
- **(A)**：`typeid(a1)` —— `a1` 是指针，类型是 `Animal*`，编译期静态推导，得到 `Animal*` 的 type_info
- **(B)**：`typeid(*a1)` —— `*a1` 是多态类型的表达式，运行时动态求值，得到 `Dog` 的 type_info

> ⚠️ 高频易错：`typeid(ptr)` 和 `typeid(*ptr)` 结果完全不同！前者是指针类型，后者才是动态类型！

</details>

---

### 例题 5：虚函数继承链综合题

```cpp
class A {
public:
    virtual void f() { cout << "A::f" << endl; }
    void g() { cout << "A::g" << endl; }
};

class B : public A {
public:
    void f() override { cout << "B::f" << endl; }
    virtual void g() { cout << "B::g" << endl; }  // 注意：B 新声明 g 为虚函数
};

class C : public B {
public:
    void f() { cout << "C::f" << endl; }
    void g() { cout << "C::g" << endl; }
};

int main() {
    C c;
    A* pa = &c;
    B* pb = &c;

    pa->f();  // (1)
    pa->g();  // (2)
    pb->f();  // (3)
    pb->g();  // (4)
    c.f();    // (5)
    c.g();    // (6)
}
```

<details> <summary>📝 解析</summary>

**分析**：

- `A::f` 是虚函数，"一旦为虚永远为虚"，`B::f`、`C::f` 都是虚函数，且都覆盖了 `A::f`
- `A::g` 是**非虚函数**
- `B::g` 在 B 中**新声明为虚函数**，但这与 `A::g` 是完全独立的（隐藏关系）
- `C::g` 覆盖了 `B::g`（`B::g` 是虚的，`C::g` 同名同参）

**输出**：

1. `pa->f()` → `f` 在 `A` 中是虚函数，`C` 覆盖了它 → **C::f**
2. `pa->g()` → `g` 在 `A` 中是非虚函数，静态绑定到 `A::g` → **A::g**
3. `pb->f()` → `f` 是虚函数，`C` 覆盖了它 → **C::f**
4. `pb->g()` → `g` 在 `B` 中是虚函数，`C::g` 覆盖了 `B::g` → **C::g**
5. `c.f()` → 直接调用 `C::f` → **C::f**
6. `c.g()` → 直接调用 `C::g` → **C::g**

> 🔑 关键：`A::g` 和 `B::g` 是隐藏关系，不是覆盖关系！通过 `A*` 调用 `g` 永远是 `A::g`（静态绑定），通过 `B*` 调用 `g` 才能触发虚函数机制。

</details>

---

### 例题 6：纯虚函数与接口设计

设计一个图形库，要求：

1. `IDrawable` 接口：只有 `draw()` 方法
2. `Shape2D` 抽象类：继承 `IDrawable`，新增 `getArea()` 和 `getPerimeter()` 纯虚函数，有静态计数器 `count`
3. `Rectangle` 具体类：实现所有纯虚函数

请完成代码，并在 `main` 中正确使用多态指针，完成创建、调用和释放。

<details> <summary>📝 参考实现</summary>

```cpp
#include <iostream>
using namespace std;

// 接口
class IDrawable {
public:
    virtual void draw() = 0;
    virtual ~IDrawable() {}  // 必须有虚析构！
};

// 抽象类
class Shape2D : public virtual IDrawable {
public:
    static int count;
    virtual float getArea() = 0;
    virtual float getPerimeter() = 0;
    virtual ~Shape2D() {}
};
int Shape2D::count = 0;

// 具体类
class Rectangle : public virtual Shape2D {
public:
    Rectangle(float w, float h) : w(w), h(h) { count++; }
    
    void draw() override {
        cout << "Rectangle: " << w << " x " << h << endl;
    }
    float getArea() override { return w * h; }
    float getPerimeter() override { return 2 * (w + h); }
    
    ~Rectangle() {
        count--;
        cout << "Rectangle destructed" << endl;
    }
private:
    float w, h;
};

int main() {
    // 用抽象类指针实现多态
    Shape2D* s = new Rectangle(3.0f, 4.0f);
    s->draw();
    cout << "Area: " << s->getArea() << endl;
    cout << "Count: " << Shape2D::count << endl;
    
    // 正确释放：因为 IDrawable/Shape2D 都有虚析构函数
    delete s;  // 会调用 Rectangle::~Rectangle()
    
    cout << "Count after delete: " << Shape2D::count << endl;
    return 0;
}
```

**输出**：

```
Rectangle: 3 x 4
Area: 12
Count: 1
Rectangle destructed
Count after delete: 0
```

> ⚠️ 关键设计点：
> 
> 1. `IDrawable` 必须有虚析构函数，否则通过 `IDrawable*` 删除会内存泄漏
> 2. 使用**虚继承**（`public virtual`）防止多重继承时数据成员重复
> 3. `Rectangle` 必须实现所有纯虚函数，否则 `Rectangle` 也是抽象类

</details>

---

## 知识点速查总结

|知识点|关键词|易错点|
|---|---|---|
|多态定义|标识符指代不同类型|区分静态/动态绑定|
|函数重载|同作用域同名不同参|编译期决议，属于静态绑定|
|虚函数|`virtual`，动态绑定|必须通过指针/引用才触发多态|
|一旦为虚永远为虚|继承链中无需重写 `virtual`|派生类同名同参自动是虚函数|
|覆盖 vs 隐藏|参数相同+虚 vs 其他|隐藏不触发多态！|
|纯虚函数|`= 0`|纯虚析构必须有定义|
|抽象类|含纯虚函数|不能实例化，不能传值|
|接口模拟|全纯虚+虚继承|需要虚析构|
|虚析构函数|`virtual ~T()`|含虚函数的基类必须有虚析构|
|typeid|`typeinfo` 头文件|`typeid(p)` vs `typeid(*p)`|
|dynamic_cast|安全向下转型|失败返回 nullptr / 抛 bad_cast|
|final|C++11，封闭虚函数/类|非虚函数不能 final|
|vtable|每类一张，运行时查表|sizeof 包含 vfp 指针|