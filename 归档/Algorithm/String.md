# Basic Concepts
- **字符串**
- **串的长度**
- **空串(empty string)**
- **空白串(blank string)**
- **子串**：字符串中任意连续的字符串。包含子串的串为主串。 
## Abstract Data Type of String
**ADT string**:
	 数据对象
	 数据关系
	 基本操作
# Std String in Cpp
### 1. int strlen(char \*s);
### 2. char \*strcpy(char \*s1, char \*s2);
### 3. char \*strcat(char \s1, char \*s2)';
### 4. int strcmp(char \*s1, char \*s2);
### 5. IO functions
### 6. char \*strchr(char \*s, char c);
# Storage & Implementation
## Storage
## Implementation
# Pattern Matching
**子串在主串中的定位称为模式匹配(Pattern Matching)或字符串匹配(String Matching)。模式匹配成功是指在主串S中能够找到模式串T，否则，称模式串T在主串S中不存在。**
## KMP algorithm
$$ Knuth-Morris-Pratt字符串查找算法 $$
### 算法流程
 $$ \begin{gathered}
\text{设现在文本串S匹配到i位置,模式串P匹配到j位置。
如果j!=-1,且当前字符匹配失败(即S[i]!=P[j])，都令j++,i++，继续匹配下一个字符。
相对于文本串S向右移动了
j-next [j] 位。换言之,当匹配失败时,模式串向右和
此值大于等于1。}
\end{gathered} $$