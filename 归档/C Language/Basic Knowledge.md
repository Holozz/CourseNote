## C语言从编译到执行的过程
### 1. **预处理（Preprocessing）**

- 处理源代码中的预处理指令，例如：
    
    - `#include`：包含头文件，将头文件内容插入源文件。
        
    - `#define`：宏定义展开。
        
    - `#ifdef`、`#ifndef`：条件编译。
        
    - 删除注释等。
        
- 输出：生成一个纯C代码的中间文件（通常扩展名为`.i`）。
### 2. **编译（Compilation）**

- 将预处理后的C代码翻译成**汇编语言**（Assembly Language）。
    
- 进行词法分析、语法分析、语义分析、中间代码生成和优化。
    
- 输出：生成汇编代码文件（通常扩展名为`.s`）。
### 3. **汇编（Assembly）**

- 将汇编代码翻译成**机器指令**（二进制代码），生成目标文件。
    
- 目标文件包含机器码、符号表、重定位信息等。
    
- 输出：生成目标文件（在Windows下扩展名为`.obj`，在Linux/Unix下为`.o`）。
### 4. **链接（Linking）**

- 将一个或多个目标文件以及所需的库文件（如C标准库）合并成一个**可执行文件**。
    
- 主要任务包括：
    
    - **符号解析**：将每个符号引用与符号定义关联。
        
    - **重定位**：将目标文件中的代码和数据段分配到具体内存地址。
        
- 输出：生成可执行文件（如Windows的`.exe`，Linux的`.out`或没有扩展名）。
### 5. **执行（Execution）**

- 操作系统加载可执行文件到内存，并运行程序。
## 存储类关键字：static、extern、全局与局部变量

### 一、**核心概念总览**

| 存储类别         | 作用域    | 生命周期   | 链接性  | 默认值 |
| ------------ | ------ | ------ | ---- | --- |
| **自动变量**（局部） | 函数/块内部 | 函数调用期间 | 无链接  | 垃圾值 |
| **静态局部变量**   | 函数/块内部 | 整个程序运行 | 无链接  | 0   |
| **全局变量**     | 整个文件   | 整个程序运行 | 外部链接 | 0   |
| **静态全局变量**   | 整个文件   | 整个程序运行 | 内部链接 | 0   |
| **extern变量** | 多个文件   | 整个程序运行 | 外部链接 | -   |

### 二、**局部变量（自动变量）**

#### 1. **基本特性**
```c
	#include <stdio.h>
	
	void function() {
	    int local_var = 0;     // 局部变量（自动变量）
	    local_var++;
	    printf("local_var = %d\n", local_var);
	}
	
	int main() {
	    function();  // 输出：local_var = 1
	    function();  // 输出：local_var = 1（重新初始化）
	    
	    // 注意：每次调用函数都会重新创建和销毁
	    return 0;
	}
```

#### 2. **局部变量的内存分配**
```c
	#include <stdio.h>
	
	void demonstrate() {
	    int x = 10;           // 在栈上分配
	    char c = 'A';         // 在栈上分配
	    int arr[100];         // 大数组可能在栈上导致栈溢出
	    
	    printf("x的地址: %p\n", (void*)&x);
	    printf("c的地址: %p\n", (void*)&c);
	    
	    // 局部变量离开作用域后自动释放
	}
	
	int main() {
	    demonstrate();
	    // 此时x和c已经被释放，无法再访问
	    
	    return 0;
	}
```

### 三、**static关键字**

#### 1. **静态局部变量**
```c
	#include <stdio.h>
	
	void counter() {
	    static int count = 0;  // 静态局部变量
	    count++;
	    printf("我被调用了 %d 次\n", count);
	}
	int main() {
		for (int i = 0; i < 5; i++) counter();
		// 输出：
	    // 我被调用了 1 次
	    // 我被调用了 2 次
	    // 我被调用了 3 次
	    // 我被调用了 4 次
	    // 我被调用了 5 次
	    return 0;
	}
```

#### 2. **静态局部变量的特性**
```c
	#include <stdio.h>
	
	void test_static() {
	    // 只在第一次调用时初始化
	    static int initialized_once = 10;
	    // 即使赋新值，下次调用时仍保留
	    static int preserve_value;
	    preserve_value = 100;
	    
	    printf("initialized_once = %d\n", initialized_once);
	    printf("preserve_value = %d\n", preserve_value);
	    
	    preserve_value++;  // 修改会被记住
	}
	
	int main() {
	    test_static();  // 输出：initialized_once = 10, preserve_value = 100
	    test_static();  // 输出：initialized_once = 10, preserve_value = 101
	    test_static();  // 输出：initialized_once = 10, preserve_value = 102
	    
	    return 0;
	}
```

#### 3. **实际应用：函数状态保持**
```c
	#include <stdio.h>
	#include <stdbool.h>
	
	// 状态机：记录上次调用状态
	bool toggle() {
	    static bool state = false;
	    state = !state;
	    return state;
	}
	
	// 唯一ID生成器
	int generate_id() {
	    static int next_id = 1;
	    return next_id++;
	}
	
	// 缓存上次计算结果
	int expensive_calculation(int x) {
	    static int last_x = -1;
	    static int last_result = -1;
	    
	    if (x == last_x) {
	        printf("使用缓存结果: ");
	        return last_result;
	    }
	    
	    printf("计算新结果: ");
	    // 模拟复杂计算
	    last_result = x * x;
	    last_x = x;
	    return last_result;
	}
	
	int main() {
	    // 状态切换
	    printf("切换器: %d %d %d\n", toggle(), toggle(), toggle());
	    
	    // ID生成
	    for (int i = 0; i < 3; i++) {
	        printf("ID: %d\n", generate_id());
	    }
	    
	    // 缓存优化
	    printf("%d\n", expensive_calculation(5));  // 计算新结果: 25
	    printf("%d\n", expensive_calculation(5));  // 使用缓存结果: 25
	    printf("%d\n", expensive_calculation(3));  // 计算新结果: 9
	    
	    return 0;
	}
```

### 四、**全局变量**

#### 1. **基本全局变量**
```c
	#include <stdio.h>
	
	// 全局变量 - 在所有函数外部定义
	int global_counter = 0;        // 外部链接
	static int file_private = 100; // 静态全局变量，内部链接
	
	void increment() {
	    global_counter++;
	    file_private++;
	}
	
	void print_values() {
	    printf("global_counter = %d\n", global_counter);
	    printf("file_private = %d\n", file_private);
	}
	
	int main() {
	    print_values();  // 输出：0, 100
	    increment();
	    print_values();  // 输出：1, 101
	    increment();
	    print_values();  // 输出：2, 102
	    
	    return 0;
	}
```

#### 2. **全局变量的内存位置**
```c
	#include <stdio.h>
	
	// 全局变量在数据段（data segment）
	int initialized_global = 100;      // 在.data段
	int uninitialized_global;          // 在.bss段（初始为0）
	const int const_global = 200;      // 在.rodata段（只读）
	
	int main() {
	    // 局部变量在栈（stack）
	    int local_var = 300;
	    
	    // 动态分配在堆（heap）
	    int *heap_var = malloc(sizeof(int));
	    *heap_var = 400;
	    
	    printf("全局变量地址: %p\n", (void*)&initialized_global);
	    printf("局部变量地址: %p\n", (void*)&local_var);
	    printf("堆变量地址: %p\n", (void*)heap_var);
	    
	    free(heap_var);
	    return 0;
	}
```

### 五、**extern关键字**

#### 1. **多文件项目结构**
```
	project/
	├── main.c      // 主文件
	├── utils.c     // 工具函数
	└── utils.h     // 头文件
```

#### 2. **正确的extern用法**

**file1.c**
```c
	#include <stdio.h>
	
	// 定义全局变量
	int global_value = 100;          // 外部链接
	static int file1_only = 200;     // 内部链接，只能在本文件使用
	
	void show_from_file1() {
	    printf("file1: global_value = %d\n", global_value);
	    printf("file1: file1_only = %d\n", file1_only);
	}
```

**file2.c**
```c
#include <stdio.h>

// 声明外部全局变量（不是定义！）
extern int global_value;         // 声明来自file1.c的变量
// extern int file1_only;        // 错误！file1_only是static的

// 定义自己的全局变量
static int file2_only = 300;     // 另一个文件的静态变量

void show_from_file2() {
    printf("file2: global_value = %d\n", global_value);
    // printf("file2: file1_only = %d\n", file1_only);  // 错误！
    printf("file2: file2_only = %d\n", file2_only);
    
    // 可以修改全局变量
    global_value += 50;
}

// 错误：重复定义
// int global_value = 999;  // 链接错误：多重定义
```

**main.c**
```c
#include <stdio.h>

// 声明外部函数
extern void show_from_file1(void);
extern void show_from_file2(void);
// 声明外部变量
extern int global_value;

int main() {
    printf("=== 多文件演示 ===\n");
    
    show_from_file1();
    // 输出: file1: global_value = 100
    //       file1: file1_only = 200
    
    show_from_file2();
    // 输出: file2: global_value = 100
    //       file2: file2_only = 300
    
    // global_value在file2中被修改了
    printf("main: global_value = %d\n", global_value);  // 150
    
    return 0;
}
```

#### 3. **编译和链接**
```bash
	# 分别编译
	gcc -c file1.c -o file1.o
	gcc -c file2.c -o file2.o
	gcc -c main.c -o main.o
	
	# 链接所有目标文件
	gcc main.o file1.o file2.o -o program
	
	# 或者直接编译
	gcc main.c file1.c file2.c -o program
```

### 六、**头文件的正确用法**

#### **config.h**（头文件）
```c
	#ifndef CONFIG_H
	#define CONFIG_H
	// 只放声明，不放定义（除非是static）
	// 外部变量声明（extern）
	extern int global_config_value;
	// 函数声明
	void init_config(void);
	int get_config(void);
	// 常量定义（没问题）
	#define MAX_USERS 100
	const int DEFAULT_TIMEOUT = 30;
	// 静态全局变量的声明和定义应该放在.c文件
	// static int private_value;  // 不要放在头文件！
	// 内联函数可以放在头文件
	static inline int add(int a, int b) {
	    return a + b;
	}
	
	#endif
```

#### **config.c**
```c
	#include "config.h"
	
	// 全局变量定义
	int global_config_value = 0;      // 实际定义
	static int private_config = 42;   // 文件私有
	
	void init_config(void) global_config_value = 100;
	int get_config(void) return global_config_value + private_config;
```

#### **main.c**
```c
	#include <stdio.h>
	#include "config.h"
	
	int main() {
	    init_config();
	    printf("配置值: %d\n", get_config());
	    printf("全局配置: %d\n", global_config_value);
	    
	    // 使用头文件中的常量
	    printf("最大用户数: %d\n", MAX_USERS);
	    printf("默认超时: %d\n", DEFAULT_TIMEOUT);
	    
	    return 0;
	}
```

### 七、**综合对比表**

| 特性       | 自动变量auto  | 静态局部变量static | 全局变量         | 静态全局变量    |
| -------- | --------- | ------------ | ------------ | --------- |
| **定义位置** | 函数内部      | 函数内部         | 文件顶层         | 文件顶层      |
| **作用域**  | 块作用域      | 块作用域         | 文件作用域+extern | 文件作用域     |
| **生命周期** | 函数调用期间    | 整个程序运行       | 整个程序运行       | 整个程序运行    |
| **链接性**  | 无链接       | 无链接          | 外部链接         | 内部链接      |
| **默认值**  | 垃圾值       | 0            | 0            | 0         |
| **内存位置** | 栈(stack)  | 数据段(data)    | 数据段(data)    | 数据段(data) |
| **初始化**  | 每次调用重新初始化 | 只初始化一次       | 程序启动时初始化     | 程序启动时初始化  |
- **静态全局变量**（`static` 在函数外部）：
    - 生命周期：整个程序运行期间
    - 作用域：从定义点到文件末尾
    - 链接性：内部链接（仅本文件可见）
- **静态局部变量**（`static` 在函数内部）：
    - 生命周期：整个程序运行期间 ✅
    - 作用域：仅限于函数内部 ❌（不能在文件内其他函数访问）
    - 链接性：无链接
- **普通全局变量**：
    - 生命周期：整个程序运行期间 ✅
    - 作用域：多个文件可见 ❌（其他文件可以通过 `extern` 访问）
### 八、**常见错误与最佳实践**

#### 错误1：头文件中定义变量
```c
// ❌ 错误：在头文件中定义变量
// common.h
int shared_variable = 100;  // 每个包含此头文件的.c文件都会定义一次

// ✅ 正确：在头文件中声明，在.c文件中定义
// common.h
extern int shared_variable;  // 声明

// common.c
int shared_variable = 100;   // 定义
```

#### 错误2：重复定义
```c
	// file1.c
	int global_var = 10;
	// file2.c
	int global_var = 20;  // ❌ 链接错误：重复定义
	// file2.c（正确）
	extern int global_var;  // ✅ 声明外部变量
```

#### 最佳实践总结：
1. **头文件只放声明**：函数声明、extern变量声明、宏定义、类型定义
2. **源文件放定义**：函数定义、变量定义
3. **使用static保护私有数据**：限制作用域到当前文件
4. **全局变量少用**：优先使用函数参数和返回值
5. **初始化所有静态变量**：显式初始化，避免依赖默认值
6. **命名规范**：全局变量使用g_前缀，静态变量使用s_前缀

### 九、**记忆口诀**

```
	局部变量在栈中，函数结束它就空；
	static局部记性好，程序结束它才终。
	
	全局变量文件内，extern可跨文件用；
	static全局限文件，外部访问行不通。
	
	头文件里只声明，源文件里再定义；
	模块设计要清晰，static保护隐私区。
```

## 强制类型转换
### 整数直接进行浮点除法
在C语言中，有两个整数变量：`int a = 5, b = 2;`。如果想要得到它们相除的浮点数结果（即 5 / 2 = 2.5），应该使用 `double result = double(a / b);`
## printf()函数的输出格式
### 1. 整数输出
- `%d` 或 `%i`：输出有符号十进制整数。
- `%u`：输出无符号十进制整数。
- `%o`：输出无符号八进制整数（不带前导0）。
- `%x`：输出无符号十六进制整数（小写字母，如0x1a3f）。
- `%X`：输出无符号十六进制整数（大写字母，如0X1A3F）。
### 2. 浮点数输出
- `%f`：输出十进制浮点数，默认保留6位小数。
- `%e`：以指数形式输出浮点数，指数部分为小写e（如1.23e+02）。
- `%E`：以指数形式输出浮点数，指数部分为大写E（如1.23E+02）。
- `%g`：根据数值的大小自动选择`%f`或`%e`格式（选择较短的形式），且不输出无意义的零。
- `%G`：根据数值的大小自动选择`%f`或`%E`格式（选择较短的形式），且不输出无意义的零。
- `%a`：输出十六进制浮点数（C99标准，小写字母）。
- `%A`：输出十六进制浮点数（C99标准，大写字母）。
### 3. 字符和字符串输出
- `%c`：输出一个字符。
- `%s`：输出一个字符串。
### 4. 指针输出
- `%p`：输出指针地址（通常以十六进制表示）。
### 5. 长度修饰符

长度修饰符用于指定整数或浮点数的长度，放在`%`和格式字母之间。例如：

- `%hd`：输出短整型（short）。
- `%ld`：输出长整型（long）。
- `%lld`：输出长长整型（long long）。
- `%hu`：输出无符号短整型（unsigned short）。
- `%lu`：输出无符号长整型（unsigned long）。
- `%llu`：输出无符号长长整型（unsigned long long）。
- `%Lf`：输出长双精度浮点数（long double）。
### 6. 宽度、精度和标志
#### 标志
| 标志   | 说明                                                                                                                            | 示例（格式：`%标志10d`，值：`123`）                     |
| ---- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| `-`  | 左对齐（默认右对齐）                                                                                                                    | `123`                                       |
| `+`  | 显示正负号                                                                                                                         | `+123`                                      |
| `空格` | 正数前显示空格                                                                                                                       | `123`                                       |
| `0`  | 用0填充空白（而不是空格）                                                                                                                 | `0000000123`                                |
| `#`  | 特殊格式：  <br>`%#o`：显示前导0  <br>`%#x`：显示0x前缀  <br>`%#X`：显示0X前缀  <br>`%#f`：强制显示小数点  <br>`%#e`/`%#E`：强制显示小数点  <br>`%#g`/`%#G`：保留末尾0 | `0173`, `0x7b`, `3.141593.`, `3.141593e+00` |
#### 宽度

|表示方式|说明|示例（值：`123`）|
|---|---|---|
|`%5d`|最小宽度为5|`123`|
|`%*d`|宽度由参数指定|宽度由前一个参数指定|

#### 精度

|格式|说明|示例（值：`3.14159265`）|
|---|---|---|
|`%.2f`|保留2位小数|`3.14`|
|`%.0f`|不保留小数|`3`|
|`%.4s`|字符串最多4字符|`"hell"`|
|`%5.2f`|宽度5，精度2|`3.14`|
|`%*.*f`|宽度和精度由参数指定|宽度和精度由前两个参数指定|

## sizeof()
`sizeof` 是 C 语言中的一个**运算符**（不是函数），用于计算数据类型或对象在内存中所占的字节数。它在**编译时**求值，而不是运行时。
### 1.基本语法
~~~C
	sizeof(type)      // 计算类型的大小
	sizeof expression // 计算表达式结果类型的大小
	sizeof(expression) // 推荐加上括号，更清晰
~~~
### 2.注意
~~~C
	int main() {
	    int a = 0;
	    printf("Before: a = %d\n", a);      // a = 0
	    // sizeof 不会执行函数调用或副作用
	    int size = sizeof(a++);
	    printf("After: a = %d\n", a);       // a = 0（没有增加）
	    // 对比：普通表达式会求值
	    int b = a++;
	    printf("After ++: a = %d\n", a);    // a = 1
	    // 数组作为函数参数会退化为指针
		void print_size(int arr[])
		printf("In function: %zu\n", sizeof(arr));//指针大小，不是数组大小
		int arr[10];
		printf("In main: %zu\n", sizeof(arr));      // 40（整个数组大小）
		print_size(arr);                            // 4或8（指针大小）
		
		sizeof(true)   = 4
		sizeof(false)  = 4
		sizeof(_Bool)  = 1
		sizeof(bool)   = 1
		sizeof(1)      = 4
		sizeof((_Bool)1) = 1

	    return 0;
    }
    ~~~
### 3.结构体和对齐
~~~C
c
	
	#include <stdio.h>
	
	struct Example1 {
	    char a;      // 1字节
	    int b;       // 4字节
	    char c;      // 1字节
	};               // 总大小可能是12字节（因为对齐）
	
	struct Example2 {
	    char a;      // 1字节
	    char c;      // 1字节
	    int b;       // 4字节
	};               // 总大小可能是8字节（重新排列后）
	
	struct __attribute__((packed)) PackedStruct {
	    char a;
	    int b;
	    char c;
	};               // 总大小是6字节（取消对齐）
	
	int main() {
	    printf("Example1: %zu\n", sizeof(struct Example1));    // 12（通常）
	    printf("Example2: %zu\n", sizeof(struct Example2));    // 8
	    printf("Packed: %zu\n", sizeof(struct PackedStruct));  // 6
	    
	    // 联合体的大小等于最大成员的大小
	    union ExampleUnion {
	        int i;
	        char c;
	        double d;
	    };
	    printf("Union: %zu\n", sizeof(union ExampleUnion));    // 8
	    
	    // 枚举的大小通常是int的大小
	    enum Color { RED, GREEN, BLUE };
	    printf("Enum: %zu\n", sizeof(enum Color));             // 4
	    
	    return 0;
	}
~~~

### 4.动态内存分配中的应用
~~~C
	#include <stdio.h>
	#include <stdlib.h>
	
	int main() {
	    // 动态分配数组
	    int *arr = malloc(10 * sizeof(int));
	    if (arr == NULL) {
	        printf("内存分配失败\n");
	        return 1;
	    }
	    
	    // 计算动态数组的"逻辑"大小
	    printf("单个元素大小: %zu\n", sizeof(*arr));           // 4
	    printf("指针大小: %zu\n", sizeof(arr));                // 4或8
	    // 注意：无法通过sizeof获取动态数组的实际元素个数！
	    
	    free(arr);
	    
	    // 结构体动态分配
	    typedef struct {
	        int id;
	        char name[50];
	        float salary;
	    } Employee;
	    
	    Employee *emp = malloc(sizeof(Employee));
	    printf("Employee size: %zu\n", sizeof(Employee));
	    free(emp);
	    
	    // 动态分配数组
	    int n = 100;
	    int *dynamic_arr = malloc(n * sizeof(int));
	    free(dynamic_arr);
	    
	    return 0;
	}
~~~

### 5.常见陷阱和注意事项

#### 陷阱1：字符串 vs 字符数组
~~~c
	
	int main() {
	    char str1[] = "Hello";           // 字符数组
	    char *str2 = "Hello";            // 字符串常量指针
	    
	    printf("sizeof(str1) = %zu\n", sizeof(str1));  // 6（包含'\0'）
	    printf("sizeof(str2) = %zu\n", sizeof(str2));  // 4或8（指针大小）
	    
	    return 0;
	}
~~~
#### 陷阱2：函数参数中的数组

~~~c

	void process_array(int arr[10]) {
	    // 这里的arr是指针，不是数组！
	    printf("Size in function: %zu\n", sizeof(arr));  // 指针大小
	}
	
	int main() {
	    int arr[10];
	    printf("Size in main: %zu\n", sizeof(arr));      // 数组大小
	    process_array(arr);
	    return 0;
	}
~~~
#### 陷阱3：位域的大小
~~~c
	
	struct BitField {
	    unsigned int a : 4;   // 4位
	    unsigned int b : 5;   // 5位
	    unsigned int c : 3;   // 3位
	};
	
	int main() {
	    printf("BitField size: %zu\n", sizeof(struct BitField));  // 4（至少一个int）
	    return 0;
	}
~~~
#### 陷阱4：空结构体（C vs C++）
~~~c
	struct Empty {
	    // 没有任何成员
	};
	int main() {
	    // C语言中，空结构体的大小通常是0（但标准未定义）
	    // 某些编译器可能给1字节
	    printf("Empty struct: %zu\n", sizeof(struct Empty));
	    return 0;
	}
~~~
### 6.实用技巧

#### 1. 安全的内存分配

~~~c
	// 使用sizeof避免类型错误
	int *array = malloc(n * sizeof(*array));  // 好：即使类型改变也正确
	int *array = malloc(n * sizeof(int));     // 好，但不够灵活
	
	// 错误示例
	int *array = malloc(n * sizeof(array));   // 错：得到的是指针大小
~~~
#### 2. 遍历数组

~~~c
	int arr[] = {1, 2, 3, 4, 5};
	size_t n = sizeof(arr) / sizeof(arr[0]);
	
	for (size_t i = 0; i < n; i++) {
	    printf("%d ", arr[i]);
	}
~~~
#### 3. 结构体复制

~~~c
	struct Point {
	    int x, y;
	};
	struct Point p1 = {10, 20};
	struct Point p2;
	// 使用memcpy复制结构体
	memcpy(&p2, &p1, sizeof(struct Point));
	// 或者直接赋值（C允许结构体直接赋值）
	p2 = p1;
~~~
## Switch语句
### 一、**基本特性**
- #### 1. **表达式要求**
- 必须是**整型**或**枚举类型**（包括 `char`, `int`, `long` 等）
- 不能是浮点数、字符串、指针等
	~~~c
	
	int num = 2;
	char grade = 'A';
	enum Color {RED, GREEN, BLUE};
	
	switch(num) { ... }        // ✓
	switch(grade) { ... }      // ✓
	switch(RED) { ... }        // ✓
	switch(3.14) { ... }       // ✗ 错误！
~~~
#### 2. **case 标签**
- 必须是**常量表达式**（编译时确定）
- 不能是变量或非常量表达式
~~~c
	const int MAX = 10;
	int x = 5;
	
	switch(x) {
	    case 1: ... break;      // ✓
	    case MAX: ... break;    // ✓（MAX是const常量）
	    case x+1: ... break;    // ✗ 错误！（不是常量）
	}
~~~ 
### 二、**核心语法**

~~~c
	switch(整型表达式) {
	    case 常量1: 语句; break;
	    case 常量2: 语句; break;
	    default: 语句;  // 可选
	}
~~~
### 三、**关键规则**
1. **case 必须为常量**，不能是变量
2. **break 决定流程**：
    - 有 break：跳出 switch
    - 无 break：**穿透执行**下一个 case
3. **default 处理未匹配情况**，可置于任意位置
### 四、**常见错误**
1. 忘记写 break（非故意穿透时）
2. case 使用变量或非常量表达式
3. case 值重复
4. 在 case 内直接定义变量（需用 {} 包裹） 
## fgets()函数
### 一、基本语法

~~~c
	#include <stdio.h>
	char *fgets(char *str, int n, FILE *stream);
~~~
### 二、参数详解

| 参数       | 类型      | 说明                      |
| -------- | ------- | ----------------------- |
| `str`    | `char*` | 存储输入字符串的**缓冲区地址**       |
| `n`      | `int`   | **最大读取字符数**（包括结尾的 `\0`） |
| `stream` | `FILE*` | 输入流，通常用 `stdin` 表示标准输入  |

### 三、基本使用示例

#### 示例1：从键盘读取输入

~~~c
	char name[50];
	
	printf("请输入你的名字: ");
	fgets(name, sizeof(name), stdin);
	
	printf("你好，%s", name);
~~~
#### 示例2：从文件读取

~~~c
    FILE *file = fopen("data.txt", "r");
    char line[100];
    // 逐行读取文件
    while (fgets(line, sizeof(line), file) != NULL) {
        printf("%s", line);
    }
    fclose(file);
~~~
### 四、如何处理 fgets 读取的字符串

这是最常用的技巧：

~~~C    
	char input[100];
    printf("请输入: ");
    fgets(input, sizeof(input), stdin);
    
    // 方法1：使用 strcspn
    input[strcspn(input, "\n")] = '\0';
    
    // 方法2：使用 strchr
    char *newline = strchr(input, '\n');
    if (newline) {
        *newline = '\0';
    }
    
    // 方法3：手动检查（最安全）
    size_t len = strlen(input);
    if (len > 0 && input[len-1] == '\n') {
        input[len-1] = '\0';
    }
    
    printf("处理后的输入: '%s'\n", input);
~~~

## 函数指针
### 一、基础语法与声明

#### 1. **函数指针的基本声明**

~~~c
	// 声明一个函数指针：指向返回int、接受两个int参数的函数
	int (*func_ptr)(int, int);
	// 对比：普通函数声明
	int add(int, int);
~~~
#### 2. **函数指针赋值**

~~~c
	#include <stdio.h>
	// 目标函数
	int add(int a, int b) return a + b;
	int multiply(int a, int b) return a * b;
	int main() {
	    // 声明函数指针
	    int (*operation)(int, int);
	    // 赋值方式1：直接使用函数名
	    operation = add;
	    printf("10 + 5 = %d\n", operation(10, 5));  // 15
	    // 赋值方式2：使用取地址符（推荐）
	    operation = &multiply;
	    printf("10 * 5 = %d\n", (*operation)(10, 5));  // 50
	    
	    return 0;
	}
~~~
### 二、使用typedef简化

#### 1. **基本typedef用法**

~~~c
	#include <stdio.h>
	// 为函数指针类型定义别名
	typedef int (*MathFunc)(int, int);
	// 具体函数
	int add(int a, int b) { return a + b; }
	int subtract(int a, int b) { return a - b; }
	int multiply(int a, int b) { return a * b; }
	int main() {
	    // 使用别名声明变量
	    MathFunc operation;
	    
	    operation = add;
	    printf("10 + 5 = %d\n", operation(10, 5));  // 15
	    
	    operation = multiply;
	    printf("10 * 5 = %d\n", operation(10, 5));  // 50
	    
	    return 0;
	}
~~~
#### 2. **复杂函数指针的typedef**
~~~c
	#include <stdio.h>
	#include <stdlib.h>
	// 返回函数指针的函数
	typedef int (*Operation)(int, int);
	// 接受函数指针作为参数的函数
	typedef void (*Callback)(int result);
	// 具体函数
	int add(int a, int b) { return a + b; }
	void print_result(int result) printf("结果是: %d\n", result);
	// 接受回调函数的函数
	void calculate_and_callback(int a, int b, Operation op, Callback cb) {
	    int result = op(a, b);
	    cb(result);
	}
	
	int main() {
	    calculate_and_callback(10, 5, add, print_result);
	    return 0;
	}
~~~
## Assert()断言
- A.检查程序在运行过程中应始终成立的内部逻辑假设✅
- B.验证某些按设计逻辑“永远不应发生”的分支是否真的不会发生✅
- C.捕捉不应该或者不可能发生的非法情况✅
- D.捕捉程序中有可能出现的错误❌
### **对比表**

| 特性       | assert  | 错误处理(if-else) |
| -------- | ------- | ------------- |
| **目的**   | 捕捉编程错误  | 处理运行时错误       |
| **适用阶段** | 开发/测试阶段 | 生产环境          |
| **性能影响** | 可完全移除   | 一直存在          |
| **用户影响** | 程序终止    | 优雅降级          |
| **处理方式** | 立即终止    | 返回错误码/异常      |
### 一、**基本概念**
断言(assert)是C语言中的一个**调试辅助工具**，用于在开发阶段检查程序的逻辑错误。当断言条件为假时，程序会立即终止并输出错误信息。
### 二、**基本用法**

#### 1. **引入头文件**
	#include <assert.h>  // 必须包含这个头文件
#### 2. **基本语法**
	assert(表达式);
#### 3. **简单示例**
~~~C
	#include <stdio.h>
	#include <assert.h>
	int main() {
	    int x = 5;
	    // 断言x必须大于0
	    assert(x > 0);  // 条件为真，程序继续执行
	    printf("x = %d\n", x);
	    return 0;
	}
~~~
### 三、**断言的工作原理**

~~~c
	#include <stdio.h>
	#include <assert.h>
	// 实际工作的原理
	int main() {
	    int *ptr = NULL;
	    assert(ptr != NULL);  // 断言失败，程序终止
	    // 相当于：
	    // if (!(ptr != NULL)) {
	    //     fprintf(stderr, "Assertion failed: ptr != NULL, file %s, line %d\n", 
	    //             __FILE__, __LINE__);
	    //     abort();  // 终止程序
	    // }
	    printf("这行代码不会执行\n");
	    return 0;
	}~~~
## memset()函数
### **基本语法**
~~~c
	#include <string.h>
	void *memset(void *ptr, int value, size_t num);
~~~

| 参数      | 类型       | 说明                       |
| ------- | -------- | ------------------------ |
| `ptr`   | `void*`  | **要填充的内存起始地址**           |
| `value` | `int`    | **要设置的值**（实际只用低8位，0-255） |
| `num`   | `size_t` | **要设置的字节数**              |
###  **正确的使用场景**

~~~c
	#include <stdio.h>
	#include <string.h>
	int main() {
	    // ✅ 场景1：清零内存（安全）
	    int data[100];
	    memset(data, 0, sizeof(data));
	    // ✅ 场景2：初始化字符数组
	    char buffer[100];
	    memset(buffer, ' ', sizeof(buffer) - 1);  // 填充空格
	    buffer[sizeof(buffer) - 1] = '\0';
	    // ✅ 场景3：填充字节数组
	    unsigned char bytes[10];
	    memset(bytes, 0xFF, sizeof(bytes));  // 每个字节为 255
	    // ✅ 场景4：数组传递
		int a[4] = {0, 1, 2, 3}, b[4];
		memset(b, a, sizeof(a));
	    return 0;
	}
~~~

### **与 calloc 的区别**

| 函数                     | 作用       | 是否分配内存 | 清零能力  | 效率  |
| ---------------------- | -------- | ------ | ----- | --- |
| `memset(ptr, 0, size)` | 已存在内存的清零 | ❌ 不分配  | ✅ 清零  | 高   |
| `calloc(count, size)`  | 分配并清零内存  | ✅ 分配   | ✅ 清零  | 中   |
| `malloc(size)`         | 分配但不初始化  | ✅ 分配   | ❌ 不清零 | 高   |


~~~c
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	int main() {
	    // 方法1：使用 malloc + memset
	    int *arr1 = malloc(100 * sizeof(int));
	    memset(arr1, 0, 100 * sizeof(int));  // 需要两步
	    // 方法2：使用 calloc
	    int *arr2 = calloc(100, sizeof(int));  // 一步完成，且自动清零
	    // 性能考虑：
	    // - 小内存：两者差异不大
	    // - 大内存：calloc可能更优（操作系统可能直接分配清零的页）
	    free(arr1);
	    free(arr2);
	    
	    return 0;
	}
~~~



## strcmp()函数
### 一、**函数原型**

~~~c
	#include <string.h>
	int strcmp(const char *str1, const char *str2);
~~~
### 二、**基本功能**

比较两个字符串 `str1` 和 `str2`，根据比较结果返回整数。

### 三、**返回值规则**

- 规定：$$空字符串小于等于任何串$$

| 比较结果             | 返回值     | 说明                |
| ---------------- | ------- | ----------------- |
| **str1 < str2**  | **负整数** | str1 在字典序中小于 str2 |
| **str1 == str2** | **0**   | 两个字符串完全相等         |
| **str1 > str2**  | **正整数** | str1 在字典序中大于 str2 |

## strcpy() & strncpy()
### **重要区别对比**

| 特性            | `strcpy`      | `strncpy`            |
| ------------- | ------------- | -------------------- |
| **安全性**       | ❌ 不安全，可能缓冲区溢出 | ✅ 相对安全，可以限制长度        |
| **自动添加 '\0'** | ✅ 总是添加        | ❌ 如果源长度≥n，不添加        |
| **性能**        | 较快            | 较慢（需要检查长度）           |
| **填充行为**      | 无             | 如果源长度<n，会用'\0'填充剩余部分 |
### 函数用法
~~~C
	#include <string.h>
	// strcpy：字符串复制
	char *strcpy(char *dest, const char *src);
	// strncpy：带长度限制的字符串复制
	char *strncpy(char *dest, const char *src, size_t n);
~~~
## strlen()
### 1. **函数原型**
~~~C
	#include <string.h>
	size_t strlen(const char *str);
~~~
### 2. **基本功能**

计算字符串的长度，即从起始地址到第一个空字符 `\0` 之前的字符个数。

~~~C
	#include <stdio.h>
	#include <string.h>
	int main() {
	    char str[] = "Hello, World!";
	    size_t length = strlen(str);
	    printf("字符串: %s\n", str);
	    printf("长度: %zu\n", length);  // 13
	    // 注意：不包括 '\0'
	    char empty[] = "";
	    printf("空字符串长度: %zu\n", strlen(empty));  // 0
	    return 0;
	}
~~~
### 3. **重要特性**

#### **不计算终止符**
~~~c
	#include <stdio.h>
	#include <string.h>
	int main() {
	    // 字符串 "Hello" 实际存储: 'H','e','l','l','o','\0'
	    char str[] = "Hello";  
	    printf("strlen(\"Hello\") = %zu\n", strlen(str));  // 5
	    printf("sizeof(str) = %zu\n", sizeof(str));   // 6（包含'\0'）
	    return 0;
	}
~~~
*遇到 `\0` 立即停止*
### 4.**注意**
~~~C
	char buffer[100] = "Hello";
	sizeof(buffer) == 100（整个数组大小）
	strlen(buffer) == 5（字符串长度，不包括'\0'）
~~~
## memcpy()
### 1. **函数原型**
~~~C
	#include <string.h>
	void *memcpy(void *dest, const void *src, size_t n);
~~~
### 2. **基本功能**
从源内存地址复制 `n` 个字节到目标内存地址。
~~~c
	// 示例1：复制整数数组
	int src_arr[5] = {1, 2, 3, 4, 5};
	int dest_arr[5];
	// 复制整个数组
	memcpy(dest_arr, src_arr, 5 * sizeof(int));
	// 示例2：复制结构体
	typedef struct {
		int id;
		char name[20];
		float score;
	} Student;
	Student stu1 = {1001, "张三", 90.5};
	Student stu2;
	memcpy(&stu2, &stu1, sizeof(Student));
~~~
### 3. **与 `strcpy` 的区别**
~~~c
	char src[] = "Hello, World!";
	char dest1[20], dest2[20];
	// 使用 strcpy：复制字符串（自动处理 '\0'）
	strcpy(dest1, src);
	printf("strcpy: %s\n", dest1);
	
	// 使用 memcpy：复制指定字节数（不关心内容）
	// 必须手动指定长度（包括 '\0'）
	memcpy(dest2, src, strlen(src) + 1);
	printf("memcpy: %s\n", dest2);
	
	// 不完整的 memcpy（忘记复制 '\0'）
	char dest3[20];
	memcpy(dest3, src, strlen(src));  // 只复制了13个字节
	// dest3[13] 是未初始化的，不是 '\0'
	// printf("%s\n", dest3);  // 可能打印乱码
~~~
### 4. **重要特性**
#### **按字节复制，不关心类型**
~~~c
	    // 不同类型之间的复制
	    int numbers[] = {1, 2, 3, 4, 5};
	    unsigned char bytes[20];
	    // 将整数数组复制到字节数组
	    memcpy(bytes, numbers, 5 * sizeof(int));
	    printf("整数数组作为字节查看:\n");
	    for (int i = 0; i < 5 * sizeof(int); i++) {
	        printf("%02x ", bytes[i]);
	        if ((i + 1) % sizeof(int) == 0) printf(" ");
	    }
	    // 注意：结果依赖于系统的字节序
	    // 在小端序系统中，1 可能存储为 01 00 00 00
~~~
### 5. **最佳实践**
~~~c
	// ✅ 总是计算正确的字节数
	memcpy(dest, src, count * sizeof(element_type));
	// ✅ 对于字符串，确保复制 '\0'
	memcpy(dest, src, strlen(src) + 1);
	// ✅ 检查内存是否重叠
	if (dest > src && dest < src + n) memmove(dest, src, n);
	else memcpy(dest, src, n);
	// ✅ 确保目标缓冲区足够大
	if (n <= dest_size) memcpy(dest, src, n);
~~~
## C语言基本数据类型
| 数据类型                   | 存储大小    | 范围/说明                                                  | 格式化输出        |
| ---------------------- | ------- | ------------------------------------------------------ | ------------ |
| **char**               | 1字节     | -128 到 127 或 0 到 255                                   | `%c`, `%d`   |
| **unsigned char**      | 1字节     | 0 到 255                                                | `%c`, `%u`   |
| **signed char**        | 1字节     | -128 到 127                                             | `%c`, `%d`   |
| **short**              | 2字节     | -32,768 到 32,767                                       | `%hd`        |
| **unsigned short**     | 2字节     | 0 到 65,535                                             | `%hu`        |
| **int**                | 4字节     | -2,147,483,648 到 2,147,483,647                         | `%d`         |
| **unsigned int**       | 4字节     | 0 到 4,294,967,295                                      | `%u`         |
| **long**               | 4字节     | -2,147,483,648 到 2,147,483,647                         | `%ld`        |
| **unsigned long**      | 4字节     | 0 到 4,294,967,295                                      | `%lu`        |
| **long long**          | 8字节     | -9,223,372,036,854,775,808 到 9,223,372,036,854,775,807 | `%lld`       |
| **unsigned long long** | 8字节     | 0 到 18,446,744,073,709,551,615                         | `%llu`       |
| **float**              | 4字节     | 1.2E-38 到 3.4E+38，6位精度                                 | `%f`, `%e`   |
| **double**             | 8字节     | 2.3E-308 到 1.7E+308，15位精度                              | `%lf`, `%le` |
| **long double**        | 10/16字节 | 3.4E-4932 到 1.1E+4932，19位精度                            | `%Lf`        |

## Const关键字
### 1. **基本数据类型 + const**

```C
	// 位置1：const在类型前
	const int a = 10;     // a是常量，不能被修改
	const float pi = 3.14; // pi是常量，不能被修改
	const char c = 'A';   // c是常量，不能被修改
	// 位置2：const在类型后（与前一种等价）
	int const b = 20;     // 同上，b也是常量
	// 错误示例：
	a = 20;      // ❌ 编译错误：不能修改const变量
	pi = 3.1415; // ❌ 编译错误
```
### 2. **指针 + const（3种关键情况）**

#### **情况1：指向常量的指针（指针指向的内容不能变）**

~~~c
	const int *p;         // p指向的内容是常量
	int const *p;         // 同上，两种写法等价
	
	int x = 10;
	int y = 20;
	const int *p = &x;    // p指向x，x的值不能通过p修改
	
	*p = 30;              // ❌ 错误：不能通过p修改x的值
	p = &y;               // ✅ 正确：p可以指向其他变量
	x = 30;               // ✅ 正确：x不是const，可以直接修改
~~~
#### **情况2：常量指针（指针本身不能指向其他地址）**

~~~c
	int * const p;        // p本身是常量，不能指向其他地址
	
	int x = 10;
	int y = 20;
	int * const p = &x;   // p必须初始化，且以后不能指向其他地址
	
	*p = 30;              // ✅ 正确：可以通过p修改x的值
	p = &y;               // ❌ 错误：p是常量，不能指向其他变量
~~~
#### **情况3：指向常量的常量指针（两者都不能变）**

~~~c
	const int * const p;  // p是常量，且指向的内容也是常量
	int x = 10;
	int y = 20;
	const int * const p = &x;  // 必须初始化
	
	*p = 30;              // ❌ 错误：指向的内容是常量
	p = &y;               // ❌ 错误：指针本身是常量
	x = 30;               // ✅ 正确：x本身不是const，可以直接修改
~~~
### 3. **快速记忆口诀**
- const在*左边：指向的内容是常量（值不能变）
- const在*右边：指针本身是常量（地址不能变）
- const在*两边：都不可变

## VLA
### **一、什么是VLA？**
- VLA（Variable Length Array，变长数组）是C99标准引入的特性，允许数组的长度在运行时确定。
### **二、基本语法**

~~~c
	#include <stdio.h>
	int main() {
	    int size;
	    printf("输入数组大小: ");
	    scanf("%d", &size);
	    int arr[size];  // 这就是VLA，大小在运行时确定
	    for (int i = 0; i < size; i++) arr[i] = i * i;
	    
	    printf("数组有 %zu 个元素\n", sizeof(arr) / sizeof(arr[0]));
	    return 0;
	}
~~~
### **三、VLA的限制**

#### 1. **不能使用初始化列表**
~~~c
	int n = 5;
	int arr[n] = {0};  // ❌ 错误
	// 必须手动初始化
	for (int i = 0; i < n; i++) arr[i] = 0;
~~~
#### 2. **不能是静态存储期**

~~~c
	void func() {
	    int n = 10;
	    static int arr[n];  // ❌ 错误：VLA不能是static
	}
~~~
#### 3. **不能是全局变量**
#### 4. **不能是结构体成员**
~~~c
	struct Data {
	    int size;
	    int arr[size];  // ❌ 错误：VLA不能是结构体成员
	};
~~~
### **四、VLA与动态内存分配对比**

|特性|VLA|malloc动态数组|
|---|---|---|
|**内存位置**|栈（Stack）|堆（Heap）|
|**释放时机**|自动（函数返回时）|手动（需要free）|
|**大小限制**|受栈大小限制（较小）|受系统内存限制（较大）|
|**初始化**|不能使用初始化列表|可以使用calloc清零|
|**性能**|分配速度快|分配速度相对慢|
|**跨函数使用**|不能（局部作用域）|可以（指针传递）|

## pragma pack()
在 C/C++ 开发中，`#pragma pack(N)` 是一个非常实用的预处理指令，主要用于控制**结构体（struct）或类（class）的成员对齐方式**。
通常情况下，编译器为了提高 CPU 访问内存的效率，会自动进行“内存对齐”。但有些场景（如网络通信、读取二进制文件）要求结构体必须紧凑排列，这时就需要用到它。

---
### 1. 核心原理
`#pragma pack(N)` 中的 `N` 告诉编译器：**每个成员的对齐边界不准超过 N 字节。**
编译器在决定一个成员的偏移量时，会取以下两个值中的**较小值**：
1. 该成员自身的大小。
2. `#pragma pack(N)` 指定的 $N$ 值。
### 2. 常见用法
- **`#pragma pack(n)`**：设置当前的对齐字节数为 $n$。
- **`#pragma pack()`**：恢复到编译器默认的对齐值（通常是 8）。
- **`#pragma pack(push, n)`**：将当前的对齐状态压入栈中，并设置新的 $n$。
- **`#pragma pack(pop)`**：恢复栈顶保存的对齐状态。
推荐用法（安全做法）：
为了防止影响到后续的代码，通常建议成对使用：
```C++
	#pragma pack(push, 1) // 保存当前对齐状态，并设为 1 字节对齐
	struct MyPacket {
	    char a;    // 1字节
	    int b;     // 4字节
	#pragma pack(pop)      // 恢复之前的对齐状态
```
---
### 3. 实例对比
假设我们有以下结构体，对比在默认对齐（通常 $N=8$）和 `#pragma pack(1)` 下的大小：

```C++
	struct Test {
	    char a;
	    int b;
	    short c;
	};
```

| **状态**               | **布局计算**                                              | **总大小**   |
| -------------------- | ----------------------------------------------------- | --------- |
| **默认状态 (8字节对齐)**     | `a`(1B) + **填充(3B)** + `b`(4B) + `c`(2B) + **填充(2B)** | **12 字节** |
| **# pragma pack(1)** | `a`(1B) + `b`(4B) + `c`(2B)                           | **7 字节**  |

**解释：**
- 在默认情况下，为了让 4 字节的 `int b` 对齐到 4 的倍数地址，编译器在 `a` 后面插入了 3 个字节的空隙（Padding）。
- 在 `pack(1)` 情况下，编译器被强制要求不进行空隙填充，所有成员紧挨着排列。
---
## union类型 & BitField
### 1. Union（共用体/联合体）
`union` 的特点是：**所有成员共享同一块内存地址**。
- **空间占用**：取决于其**最大**成员的大小
- **特性**：在同一时刻，只能安全地存储和使用其中一个成员
#### 示例：
```C++
	union Data {
	    int i;
	    float f;
	    char str[4];
	};
```
在这个例子中，`Data` 的大小是 4 字节。如果你给 `i` 赋值，`f` 和 `str` 的值也会随之改变，因为它们在内存中是重叠的。
**常见用途：**
1. **节省空间**：当一组变量互斥使用时（比如一个属性可能是数字也可能是字符串）。
2. **类型转换/拆解**：例如，想查看一个 `float` 内部的二进制字节分布。
---
### 2. Bit-field（位域）
`bit-field` 允许你在结构体中**按位（bit）**来定义成员的大小。这对于操作硬件寄存器或压缩存储布尔值非常有用。
- **语法**：`类型 变量名 : 位数;`
- **限制**：类型通常为 `unsigned int` 或 `int`；不能对位域取地址（`&` 操作），因为 CPU 最小寻址单位是字节。
#### 示例：
```C++
	struct Controller {
	    unsigned int is_active : 1;  // 占 1 位 (0 或 1)
	    unsigned int mode      : 2;  // 占 2 位 (0-3)
	    unsigned int error_code: 5;  // 占 5 位 (0-31)
	}; // 整体可能只占 1 字节（取决于编译器对齐）
```
---
### 3. Union + Bit-field
这是底层开发中最经典的组合。通过 `union`，我们可以既能**整体访问**一个寄存器，又能**按位访问**其中的特定功能段。
#### 经典案例：控制 8 位寄存器

```C++
	union Register {
	    unsigned char byte;          // 整体访问 (1 字节)
	    struct {                     // 按位访问
	        unsigned char low  : 4;
	        unsigned char high : 4;
	    } bits;
	};
	Register reg;
	reg.byte = 0xFF;    // 整体设为 255
	reg.bits.low = 0x0; // 现在 byte 变成了 0xF0
```
---
### 4. 两者的对比总结

|**特性**|**Union (共用体)**|**Bit-field (位域)**|
|---|---|---|
|**核心目的**|成员**共享**内存，节省空间或重新解释数据|成员**切分**内存，精确控制到“位”|
|**内存布局**|起始地址全部相同|成员按顺序紧挨着排列（受端序影响）|
|**大小计算**|等于最大成员的大小|成员位数之和（向上取整到字节边界）|
|**寻址**|可以对成员取地址|**不能**对位域成员取地址|

---
### ⚠️ 注意事项：大端与小端 (Endianness)
在使用 `union` 和 `bit-field` 时，最隐蔽的坑是**字节序**。
- 在 **小端模式**（如 Intel CPU）下，位域的第一个成员通常存储在字节的最低位（LSB）。
- 在 大端模式 下，则可能存储在最高位（MSB）。因此，涉及跨平台传输数据时，直接使用位域映射协议包需要格外小心。