### 1.6
问题：求n次多项式$y=f(x)$的值
乘法：2n
加法：2n-1
### 1.7
(1)2n-3
(2)考虑循环中第i-2次比较，即S\[i]先与$SecondMin$比较，这是每个元素都一定会执行的操作；而只有当此时$S[i]$比$SecondMin$小，才会额外执行下一次比较，所以考虑这个情况的概率：在$S[1]\to S[i]$这i个数当中，$S[i]$比前面第二小的数小的概率为$\frac{{2}}{i}$（因为前i-3次比较已经找出了最小和第二小，想要比第二小还小只能是新的最小或新的第二小，2种情况），于是对于$S[i]$来说，比较次数的期望是$2\times\frac{2}{i}+1\times \frac{i-2}{i}$，则总的比较次数的期望就是
$$
1+\Sigma_{i=3}^n\Big(2\times\frac{2}{i}+1\times \frac{i-2}{i}\Big)=
$$
$$
n-1+2\Sigma_{i=3}^n\frac {1}{i}
$$
### 1.9
二分查找的时间复杂度为$O(\log n)$，顺序查找的时间复杂度为$O(n)$；当n为奇数时，二分查找的时间复杂度不可以用$\Omega (n)$表示，于是不可以写$W(n)=\Theta(n)$
### 1.15
#### (1)
$g(n)=O(f(n))$
#### (5)
$f(n)=\log(n!)=\Sigma \log(k)$增速小于幂函数
$f(n)=O(g(n))$
### 1.18
$$n!,\ 2^{2n},\ n2^n,\ n^{\log \log n}=\Theta((\log n)^{\log n}),\ n^3,\ \log(n!) =\Theta( n\log n),$$
$$n=\Theta(\log10^n),\ 2^{\log \sqrt{ n }},\ 2^{\sqrt{ 2\log n }},\ \log n=\Theta( \Sigma\frac{1}{k}),\ \log \log n$$

### 1.19
#### (2)
$$
\begin{align}
n &\leftarrow 3^k   \\
T(3^k)&=9T(3^{k-1})+3^k \\
&=9\Big( 9T(3^{k-2})+3^{k-1} \Big)+3^k \\
&\dots \\
&=9^k(T(1))+\Sigma_{k=1}^k3^k \\
&=3^{2k}+\frac{3^{k+1}-3}{2} \\
&=n^2+\frac{3(n-1)}{2}
\end{align}
$$
#### (4)
$$
\begin{align}
T(n)&=T(n-1)+n\log_{3} \\
&=T(n-2)+(n-1)\log3+n\log3 \\
&\dots \\
&=T(1)+(\Sigma_{i=2}^n i)\log3 \\
&=1+\frac{(2+n)(n-1)}{2}
\end{align}

$$

### 1.20

由主定理，$T(n)=\Theta(n^{\log_{2}7})$
而对于$W(n)$，当a大到$f(n)=O(n^{\log_b a-\epsilon})$时$W(n)=\Theta(n^{\log_b a}=n^{\log_{4}a}=n^{\log_{2}\sqrt{ a }})$，
此时要满足阶更低，就有$\sqrt{ a }<7$即$a_{max}=48$
