
| 学号       | 姓名  | 分工  |
| -------- | --- | --- |
| 24319050 | 韩宇  | 全部  |
## 1. 问题描述
通过编程实现语音信号的调制与传输
1、 录制一段自己的语音信号(大概数秒)；
2、 画出语音信号的时域波形和频谱图；
3、 给原始语音信号加噪声，画出加噪声后的语音信号和频谱图；
4、 设计一个频域的理想带通信道；
5、 对加噪声后的语音信号进行幅度调制，画出调制后的语音信号和频谱图；
6、 利用理想带通信道对信号进行传输；
7、 对接收到的信号进行解调，画出解调后的语音信号和频谱图；
8、 设计性能良好的滤波器对信号进行滤波；
9、 对滤波后的语音信号进行回放，并与原始语音进行对比
## 2. 问题分析与解决思路
**问题本质**：模拟一个完整的语音通信系统——发送端（调制）→ 信道（带通+噪声）→接收端（解调+滤波）

**核心问题**：
  1. 语音是低频信号（<4kHz），无法直接在无线信道中远距离传输 → 需要调制搬移到高频载波
  2. 信道存在噪声和带宽限制 → 需要解调和滤波恢复原始信号
  3. 解调后残留高频分量和噪声 → 需要设计性能良好的滤波器

**整体架构**：

  原始语音 → \[加噪] →\ [AM调制×cos(2πfc t)] → \[理想带通信道] → \[相干解调×cos(2πfc t)] → \[低通滤波] → 恢复语音

**关键设计**：
  - 调制方式：标准 AM（有载波分量），便于相干解调
  - 载波频率 8kHz：远高于语音基带(<4kHz)，避免频谱混叠
  - 带宽 4kHz：匹配语音信号带宽，同时限制带外噪声
  - 解调后 Butterworth 滤波：相比理想滤波器的 Gibbs 振铃，Butterworth 通带平坦、无振铃

## 3. 各部分思路和实验代码
### 1. 语音信号加载与时频分析
思路：语音是非平稳信号，但短时内可视为平稳。FFT 将时域信号变换到频域，观察能量集中在低频段（语音基频+共振峰），这是后续滤波器参数设计的依据。
关键代码：
```python
def load_or_generate_audio(filepath):
    if os.path.exists(filepath):
        print(f"[OK] 加载音频文件: {filepath}")
        rate, data = wavfile.read(filepath)
        # 转为 float64 并归一化
        if data.dtype == np.int16:
            data = data.astype(np.float64) / 32768.0
        elif data.dtype == np.int32:
            data = data.astype(np.float64) / 2147483648.0
        elif data.dtype == np.float32:
            data = data.astype(np.float64)
        # 若是立体声，取单通道
        if data.ndim > 1:
            data = data[:, 0]
        return data, rates

def plot_time_freq(signal_data, fs, title, figsize=(14, 5)):
    """
    绘制信号的时域波形 + 幅度频谱。
    """
    N = len(signal_data)
    t = np.arange(N) / fs
    S = fft(signal_data)
    freqs = fftfreq(N, 1.0 / fs)
    mag = np.abs(S) / N
  
    fig, axes = plt.subplots(1, 2, figsize=figsize)
    # 时域
    axes[0].plot(t, signal_data, linewidth=0.5)
    axes[0].set_xlabel("时间 (s)")
    axes[0].set_ylabel("幅度")

    axes[0].set_title(f"{title} — 时域波形")
    axes[0].grid(True, alpha=0.3)
    # 频域（只显示正频率）
    pos_mask = freqs >= 0
    axes[1].plot(freqs[pos_mask], mag[pos_mask], linewidth=0.5)
    axes[1].set_xlabel("频率 (Hz)")
    axes[1].set_ylabel("幅度")
    axes[1].set_title(f"{title} — 幅度频谱")
    axes[1].grid(True, alpha=0.3)
    axes[1].set_xlim(0, fs / 2)
    plt.tight_layout()
    return fig
```
  观察：频谱能量集中在 0~4kHz，高频分量很少，这验证了语音带宽取 4kHz 的合理性
### 2. 加高斯白噪声
 思路：模拟真实传输中的加性噪声。按给定  SNR（信噪比）计算噪声功率，使实验可控、可复现。SNR=10dB 意味着信号功率是噪声功率的 10倍

关键代码：
```python
def add_noise(signal_data, snr_db):
    signal_power = np.mean(signal_data ** 2)
    noise_power = signal_power / (10 ** (snr_db / 10))
    noise = np.sqrt(noise_power) * np.random.randn(len(signal_data))
    return signal_data + noise
```
观察：时域波形上能看到明显的毛刺，频谱本底整体抬升——白噪声就是这样，所有频率上一视同仁地加了一层。

### 3. 频域理想带通信道
思路："理想"带通，在频域直接拿一个矩形窗一框——通带里的频率分量原封不动保留，阻带里全部清零。物理上不可实现（对应时域的无限长 sinc），但作为理论模型代码比较简单

关键代码：
```python
def ideal_bandpass_channel_freq(signal_data, fs, fc, bw):
    N = len(signal_data)
    S = fft(signal_data)
    freqs = fftfreq(N, 1.0 / fs)
    mask = np.abs(np.abs(freqs) - fc) <= bw / 2   # 正负频率都要
    S_filtered = S * mask
    return np.real(ifft(S_filtered))
```
这里 fc=8000Hz，bw=4000Hz，所以通带是 [6000, 10000]Hz。`np.abs(freqs) - fc`是为了同时框住正负频率

### 4. 幅度调制 (AM)
思路：乘个高频载波把信号搬到 fc 附近，原理就是傅里叶变换性质，用标准 AM（带载波分量）而不是 DSB-SC，好处是解调时包络不会翻转。调制指数 m=0.8，留余量避免过调制。

关键代码：
```python
def amplitude_modulate(signal_data, fs, fc, mod_index=0.8):
    N = len(signal_data)
    t = np.arange(N) / fs
    carrier = np.cos(2 * np.pi * fc * t)
    modulated = (1.0 + mod_index * signal_data) * carrier
    return modulated, carrier, t
```
 `1.0 + m*x(t)` 里的 `1.0` 就是直流偏置，保证包络始终为正。乘上载波后，频谱上原基带信号就对称地出现在 fc 两侧——上边带和下边带，载波频率处还有一根谱线（就是那个直流分量贡献的）

### 5. 信道传输
思路：把调制好的信号送进刚才设计的理想带通信道。实际做的就是频域相乘——调制信号的 FFT 和信道的矩形窗逐点相乘，然后 IFFT 回来。带外的噪声在这步被完全砍掉，信噪比有所改善

关键代码：
```python
transmitted = ideal_bandpass_channel_freq(modulated, fs, FC, BANDWIDTH)
```

### 6. 相干解调
思路：接收端再乘一次同样的载波（假设收发双方完美同步）利用 cos²(ωt) = (1+cos(2ωt))/2，乘完之后信号裂成两部分——基带分量老老实实待在低频，二倍频分量跑到 2fc=16kHz 去了。用理想低通（截止 fc/2=4kHz）把低频捡出来

但是：滤出来的信号长这样——`0.5 + 0.5·m·x(t)`，带着个 DC 偏移，幅度也被缩了一半。需要手动去掉 DC 再把幅度拉回来。刚开始写的时候忘了这步，MSE 直接飙到 0.36，加上之后掉到 0.006

关键代码：
```python
def coherent_demodulate(received_signal, fs, fc, mod_index=0.8):
    N = len(received_signal)
    t = np.arange(N) / fs
    carrier = np.cos(2 * np.pi * fc * t)
    product = received_signal * carrier
    # 理想低通，截止 fc/2
    S = fft(product)
    freqs = fftfreq(N, 1.0 / fs)
    mask = np.abs(freqs) <= fc / 2
    S_filtered = S * mask
    baseband = np.real(ifft(S_filtered))
    # 去 DC + 幅度恢复：baseband ≈ 0.5 + 0.5*m*x(t)
    dc_offset = np.mean(baseband)
    x_recovered = (baseband - dc_offset) * (2.0 / mod_index)
    return x_recovered, product
```

### 7. Butterworth 滤波器设计与滤波
思路：前面解调用的是理想低通，频域直接切，会导致时域的 Gibbs 振铃——信号在截止频率附近抖来抖去。换成 Butterworth，通带平坦、过渡带平滑、没有振铃
另外用了 `filtfilt` 而不是 `lfilter`——前向滤一次再反向滤一次，相位响应完全抵消，波形不会被延时扯变形

关键代码：
```python
def design_butterworth_filter(fs, cutoff, order):
    nyquist = fs / 2
    normal_cutoff = cutoff / nyquist
    b, a = signal.butter(order, normal_cutoff, btype="low")
    return b, a

# 应用时用 filtfilt 做零相位滤波
filtered = signal.filtfilt(b, a_coeff, demodulated)
```

### 8. 回放与对比
思路：把原始信号和恢复信号对比，再算 MSE 量化差距，最后把恢复信号存成 WAV 文件，实际收听查看效果

关键代码：
```python
mse = np.mean((original_aligned - filtered_aligned) ** 2)
save_audio(OUTPUT_FILE, filtered, fs)
```

## 4. 实验结果

用自己的录音跑了实验（5.14 秒，48kHz，脚本自动重采样到 44.1kHz），最终 MSE = 0.000119。真实语音的高频分量比较少（频谱在 4kHz 以上基本没什么能量），所以 Butterworth 在 4kHz 截止几乎没砍掉什么有用信息，恢复效果很好

各步骤生成的图像，按顺序如下：
![[fig1_original.png]]
![[fig2_noisy.png]]
![[fig3_channel.png]]
![[fig4_modulated.png]]
![[fig5_transmitted.png]]
![[fig6_demodulated.png]]
![[fig7_filter_response.png]]
![[fig7_filtered.png]]
![[fig8_comparison.png]]

| 图片                   | 内容            | 主要观察                |
| -------------------- | ------------- | ------------------- |
| fig1_original        | 原始语音时域+频谱     | 能量集中在低频，高频很弱        |
| fig2_noisy           | 加噪后           | 波形出毛刺，频谱本底抬高        |
| fig3_channel         | 理想带通信道        | [6000,10000]Hz 的矩形窗 |
| fig4_modulated       | AM调制后         | 基带搬移到 8kHz 两侧，有载波谱线 |
| fig5_transmitted     | 信道传输后         | 带外噪声被滤除             |
| fig6_demodulated     | 解调后           | 信号基本恢复，还有些高频残余      |
| fig7_filter_response | Butterworth频响 | 通带平坦，-3dB 在 4kHz    |
| fig7_filtered        | 滤波后           | 高频残余被清除，波形光滑        |
| fig8_comparison      | 原始 vs 恢复      | 两者几乎重合              |

输出的 `filtered_voice.wav` 听起来和原录音差别不大，噪声被抑制得比较干净，但是同时语音变得比较模糊了一点

## 5. 结论
1. AM 调制解调整条链路跑通，MSE 做到 0.0001 级别，信号基本无损恢复
2. Butterworth + filtfilt 对语音处理很友好，没振铃、没相位失真
3. 各参数之间有约束：fc 不能太低、带宽要装得下两个边带、低通截止要卡在基带和 2fc之间
4. 解调后的 DC 偏移和幅度恢复是最大的陷阱，漏掉这步 MSE 直接翻60 倍

## 6. 收获与感想

这次实验把调制解调的整个过程实现了一遍，从 FFT 频谱分析到 AM 调制到滤波器设计，把课本上的公式在python上实现，利用了很多库函数。有些纸上学习的推导，代码跑起来也还有一堆细节要处理，另外感觉 Python + scipy 生态做信号处理确实顺手，几行代码就能搭出一条完整的通信链路，出图也方便。另外，频域分析确实是对信号处理的好工具

## 7. 创新点

1. **自适应采样率处理**：脚本在加载音频后会自动检测采样率，若与目标采样率（44.1kHz）不一致则用 `scipy.signal.resample` 做重采样。这样无论用什么设备录的音、原始采样率是多少，都能统一到同一套参数下处理，不用手动转格式。实际录音时手机和电脑的默认采样率各不相同，这个处理让脚本兼容性好了不少

2. **零相位滤波的使用**：在 Butterworth 滤波环节用了 `filtfilt` 而非常规的 `lfilter`。`filtfilt` 通过前向+反向两次滤波消除相位失真，对语音信号来说这意味着恢复后的波形不会有时延变形，听感更接近原始录音
## 8. 思考题
两段语音同时传、互不干扰，应该频分复用（FDM）——两路信号用不同的载波频率，频谱上各占一段，互相不重叠
- 语音 1 → AM 调制，载波 fc1 = 8kHz → 占 [6k, 10k] Hz
- 语音 2 → AM 调制，载波 fc2 = 14kHz → 占 [12k, 16k] Hz
两路调制完直接加在一起送进信道。接收端用两个带通滤波器分别把两路分开（中心频率对准各自的 fc），然后各自相干解调
关键就是载波频率要**拉开足够距离，保证调制后的频谱不重叠**