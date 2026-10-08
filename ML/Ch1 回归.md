## 单特征

#### 模型

## 多特征

代价函数：$L(\omega) = \frac{1}{n}||X\omega-y||^2$
关于$\omega$的梯度为$\frac{\partial{L(\omega)}}{\partial{\omega}}=\vec{[\frac{\partial{L(\omega)}}{\partial \omega_{1}},\dots,\frac{\partial{L(\omega)}}{\partial \omega_{n}}]}$
当$L(\omega)$为**行向量函数**时，$\frac{\partial{L(\omega)}}{\partial{\omega}}=\vec{[\frac{\partial{L(\omega)}}{\partial \omega_{1}},\dots,\frac{\partial{L(\omega)}}{\partial \omega_{n}}]}=\begin{matrix}{}\frac{\partial{L_{1}(\omega)}}{\partial \omega_{1}},\dots,\frac{\partial{L_{p}(\omega)}}{\partial \omega_{1}} \\  \dots \\  \frac{\partial{L_{1}(\omega)}}{\partial \omega_{n}},\dots,\frac{\partial{L_{p}(\omega)}}{\partial \omega_{n}}\end{matrix}$
而$$\frac{\partial||X\omega-y||}{\partial \omega}=$$