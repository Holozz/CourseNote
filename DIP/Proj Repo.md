---
cssclasses:
---

<div class="cover">
  <h1>2024级本科生《数字图像处理》实验报告</h1>
  <h2>Proj 03-02 03-05 03-06</h2>
  <div class="info">
    <p>班级：计科1班</p>
    <p>姓名：韩宇</p>
    <p style="margin-bottom: 100px;">学号：24319050</p>
    <p style="margin-bottom: 300px;"> Abstract</p>
    <p class="date" style="font-size: 1em">日期：{{date}}</p>
  </div>
</div>

<div style="page-break-after: always;"></div>

---
## 说明
实验报告内容如下：每个题目按Project 00-00的要求（就是后面的正文）写中文文档，并按题目序号将所有文档整合成实验报告。实验报告的开头需要写明小组每个成员的贡献（比如XXX负责了XX实验的XX模块等）。

 题目难度不大，同学们在实验报告中主要说明自己针对题目进行的新颖特别的思考/尝试/代码实现，以及实现了怎样的性能和效果，包括但不限于，是不是速度更快了？精度更高了？能泛化到更多的测试样例上？以及其他等等。

邮件请使用正常附件，不要使用超级附件，会影响下载

以小组为单位发送附件到邮箱 dip_cse_sysu@163.com邮件主题、附件压缩包、和实验报告都命名为【姓名1学号1_姓名2学号2_姓名3学号3_第X次project】（X为汉字一二三四，例如【张三13333333_李四13333334_第一次project】）。

附件和主题必须包含关键词“第X次project”（X为汉字一二三四），否则会影响附件下载和打分，望周知。邮件正文不要空白，避免被邮箱误判为垃圾邮件。

压缩包附件需要包括实验报告PDF+可运行代码，Matlab或Python代码皆可。实验报告（注1：可运行代码是指你的代码在课室电脑上点击运行后，无需其他任何操作就能输出预期结果）（注2：教室电脑系统是window，使用mac的同学注意压缩包解压后是否有乱码。）（注3：代码中建议使用文件夹中的相对路径，否则在教室电脑运行时会因为路径问题报错）
## Technical Discussion
One to two pages (max). This section should include the techniques used and the principal equations (if any) implemented.
## Discussion of results
Discussion of results. One to two pages (max). A discussion of results should include major findings in terms of the project objectives, and make clear reference to any images generated
## Results
Includes all the images generated in the project. Number images individually so they can be referenced in the preceding discussions.
## Appendix
Program listings. Includes listings of all programs written by the student. Standard routines and other material obtained from other sources should be acknowledged by name, but their listings should not be included.
## Layout
The entire report must be in standard sheet size format (8.5 x 11 inches in the U.S.) All sheets should be stapled in three locations to form a binding booklet-like support on the left margin. Alternatively, sheets can be assembled using a commercial plastic binding product with a clear plastic cover.

## A note on program implementation:
As noted earlier, the objective of the computer
programs used in the following projects is to teach the student how to manipulate
images. There are numerous packages that perform some of the functions required to
implement the projects. However, the use of "canned" routines as the only method to
implement an entire project is discouraged. For example, if the students are using
MATLAB and the Image Processing Toolbox, a balanced approach is to use MATLAB's
programming environment to write M functions to implement the projects, using some of
MATLAB's own functions in the process. A good example is the implementation of the 2-
D Fourier Fast Transform. The student should use the MATLAB function that computes
the 2-D FFT directly, but write functions for operations such as centering the transform,
multiplying it by a filter function, and obtaining the spectrum.