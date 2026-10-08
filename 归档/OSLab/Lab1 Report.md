## **Section 1** **实验要求与实验概述**

实验要求：熟悉现代 Linux 内核的编译过程和启动过程，并在自行编译内核的基础上构建简单应用。通过编译内核，掌握 OS 的构建流程，深入理解：
1) 内核如何组织代码（模块化设计、子系统划分）
2) 如何与硬件交互（驱动程序、中断处理、内存管理）
3) 如何管理系统资源（进程调度、内存分配、文件系统）
实验概述：
- 实验任务1：环境配置
- 实验任务2：编译Linux内核
- 实验任务3：Qemu启动内核并开启远程调试
- 实验任务4：制作initramfs
- 实验任务5：编译并启动BusyBox
- 实验任务6：完成Linux0.11内核的编译启动和调试
- 实验任务7：认识麒麟（Kylin OS）
- 实验任务8：探索麒麟OS内核
## **Section** **2** **实验步骤与实验结果**

### ------------------------- 实验任务1 -------------------------

- 任务要求：搭建OS内核开发环境包括代码编辑环境、编译环境、运行环境、调试环境等。
- 思路分析：根据文档指引进行下载安装虚拟机、ISO文件、换源以及进入虚拟机后的环境配置。注意：Ubuntu版本的选择、在虚拟机终端中命令的细微差异等。
- 实验步骤：
	1. 下载安装VirtualBox和Ubuntu22.04并根据网上教程启动虚拟机，之后换源
		```shell
		sudo mv /etc/apt/sources.list /etc/apt/sources.list.backup
		sudo gedit /etc/apt/sources.list
		sudo apt update
		```
		如下图所示，打开gedit后输入换的源![[屏幕截图 2026-03-09 111113.png|500]]
	2.  配置C/C++环境
		```shell
			sudo apt install binutils
			sudo apt install gcc
			gcc -v
		```
	    查询版本，结果如下图所示，表示安装成功
		![[Pasted image 20260309111859.png | 500]]
	3. 安装其他工具
		```shell
			sudo apt install nasm
			sudo apt install qemu
			sudo apt install cmake
			sudo apt install libncurses5-dev
			sudo apt install bison
			sudo apt install flex
			sudo apt install libssl-dev
			sudo apt install libc6-dev-i386
		```
		如图所示
		![[屏幕截图 2026-03-03 174828.png|400]]

### ------------------------- 实验任务2 -------------------------   
- 任务要求：下载并编译i386内核
- 思路分析：直接按照教程编译
- 实验步骤：
	1. 下载内核
		```shell
		mkdir ~/lab1
		cd ~/lab1
		wget https://mirrors.tuna.tsinghua.edu.cn/kernel/v5.x/linux-5.10.19.tar.xz
		xz -d linux-5.10.19.tar.xz
		tar -xvf linux-5.10.19.tar
		cd linux-5.10.19
		```
	2. 编译内核
		~~~shell
		make i386_defconfig
		make menuconfig
		make -j8
		ls -lh arch/x86/boot/bzImage
		ls -lh vmlinux
		~~~
		结果如下图所示
		![[屏幕截图 2026-03-03 185844.png|500]]

### ------------------------- 实验任务3 -------------------------
- 任务要求：使用qemu和gdb工具启动内核并调试
- 思路分析：根据文档指引进行命令行操作，注意分别在不同的窗口中运行qemu和gdb
- 实验步骤
	1. 启动qemu
		```shell
		qemu-system-i386 -kernel linux-5.10.19/arch/x86/boot/bzImage -s -S -append "console=ttyS0" -nographic
		```
	2. gdb调试
	   ```shell
	   gdb
	   file linux-5.10.19/vmlinux
	   target remote:1234
	   break start_kernel
	   c
	   ```

	   随后qemu界面开始运行，如下图所示![[屏幕截图 2026-03-07 123002.png|500]]
- 思考题：
	1. 用info或list查询start_kernel函数的位置
		```shell
		list line start_kernel
		```
	2. 查看寄存器状态
		```shell
		info registers
		info registers eax ebx esp
		```
 可以看到输出如下图所示![[屏幕截图 2026-03-07 110444.png]]
 显示`start_kernel`函数位于849行，以及各寄存器的状态。
### ------------------------- 实验任务4 -------------------------
- 任务要求：制作initramfs文件作为临时根文件系统用于挂载真实根文件系统，来验证内核启动流程
- 思路分析：写一个简单的HelloWorld程序来制作initramfs并加载
- 实验步骤：
	1. HelloWorld程序
		```shell
		code helloworld.c
		//程序内容如下
		#include <stdio.h>
		void main()
		{
		    printf("lab1: Hello World\n");
		    fflush(stdout);
		    /* 让程序打印完后继续维持在用户态 */
		    while(1);
		}
		//回到shell
		gcc -o helloworld -m32 -static helloworld.c
		file helloworld
		```
		可以看到，编译后文件夹里出现了可执行文件；以及命令行输出包含`ELF 32-bit`和 `statically linked`，说明操作成功。
	2. 制作initramfs

		```shell
		echo helloworld | cpio -o --format=newc > hwinitramfs
		qemu-system-i386 -kernel linux-5.10.19/arch/x86/boot/bzImage -initrd hwinitramfs -s -S -append "console=ttyS0 rdinit=helloworld" -nographic
		gdb
		file linux-5.10.19/vmlinux
		target remote:1234
		break start_kernel
		c
		```   
		
		可以看到gdb窗口中输出了lab1: Hello World，说明加载成功
		![[屏幕截图 2026-03-03 233424.png|500]]
### ------------------------- 实验任务5 -------------------------
- 任务要求：编译并启动BusyBox来构建简单OS
- 思路分析：下载BusyBox源码，解压并编译；再用制作的initramfs启动BusyBox
- 实验步骤：
	1. 下载并解压BusyBox
		```shell
		wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
		ls -ld busybox-1.36.1.tar.bz2   //检查是否下载成功
		tar -xjf busybox-1.36.1.tar.bz2
		ls -ld busybox-1.36.1           //检查是否解压成功
		```
		出现以下输出说明下载并解压成功
		![[Pasted image 20260310165226.png|600]]
	2. 编译BusyBox
		```shell
		cd busybox-1.36.1
		make defconfig
		make menuconfig //进入图形界面勾选
		make -j8
		make install
		```
		根据教程进行勾选，注意使用键盘按键控制![[屏幕截图 2026-03-07 125511.png|400]]
	3. 制作initramfs
		```shell
		mkdir mybusybox
		mkdir -pv mybusybox/{bin,sbin,etc,proc,sys,usr/{bin,sbin}}
		cp -av busybox-1.36.1/_install/* mybusybox/
		cd mybusybox
		```
		然后打开init文件写一个shell脚本：
		```shell
		#!/bin/sh
		mount -t proc none /proc
		mount -t sysfs none /sys
		echo -e "\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds\n"
		exec /bin/sh
		```
		如图所示
		![[Pasted image 20260310171202.png|550]]
		保存退出回到shell，输入：
		```shell
		chmod u+x init
		find . -print0 | cpio --null -ov --format=newc | gzip -9 > ~/lab1/initramfs-busybox-x86.cpio.gz
		```
		打包成cpio文件以供Linux内核做initramfs启动执行
		可以在文件夹中看到该gz文件：
		![[Pasted image 20260310171537.png|500]]
	4. 加载BusyBox
		```shell
		qemu-system-i386 -kernel linux-5.10.19/arch/x86/boot/bzImage -initrd initramfs-busybox-x86.cpio.gz -nographic -append "console=ttyS0" -m size=2048
		```
		进入BusyBoxShell
		```busybox shell
		ls
		uname -a
		cat /proc/cpuinfo
		cat /proc/meminfo
		ps
		```
		可以看到输出如下图
		![[屏幕截图 2026-03-07 132624.png|500]]
		![[屏幕截图 2026-03-07 132717.png|300]]![[屏幕截图 2026-03-07 132639.png|250]]
		思考题：在`start_kernel`函数处单步执行几步并观察内核初始化的前几个函数调用，如下图所示
			![[屏幕截图 2026-03-12 191419.png|500]]
### ------------------------- 实验任务6 -------------------------
- 任务要求：找到Linux0.11的内核代码，编译，然后使用qemu加载、启动内核，并在hdc中创建文件
- 思路分析：仿照前五个实验对内核进行编译启动等，注意内核版本的不同，以及一些命令的差异。
- 实验步骤：
	1. 获得Linux 0.11内核代码
		通过gitee仓库拉取到lab1文件夹里
		```shell
		cd ~/lab1
		git clone https://gitee.com/vladi/sysuos-2026-spring-i386/blob/homework/lab1/src/Linux-0.11-lab1.tar.gz         //拉取
		tar -xzf Linux-0.11-lab1.tar.gz -C ~/lab1     //解压
		mv Linux-0.11-lab1 Linux-0.11
		```
	2. 编译32位版本的linux 0.11内核
		```shell
		cd Linux-0.11
		vim Makefile //编辑CFLAGS
		make
		```
		可以看到更改后的Makefile内容以及编译输出
		![[屏幕截图 2026-03-10 185201.png|500]]
		![[Pasted image 20260310191118.png|500]]
	3. 使用QEMU加载、启动内核
		```shell
		qemu-system-i386 -m 16 -boot a -fda Image -hda hdc-0.11.img -s -S
		```
	4. 利用gdb进行远程调试并进行挂载
		从tool/system处加载符号表，再远程连接qemu；
		自行设置源码目录为/home/vladi/lab1/linux-0.11，设置汇编代码的形式；
		再在0x7c00，main和0x7dfe处设断点，随后执行调试
		```gdb-shell
		file tools/system
		target remote :1234
		directory /home/vladi/lab1/Linux-0.11
		set disassembly-flavor intel
		break *0x7c00
		break main
		n
		n
		x/2bx 0x7dfe
		```
		过程如图，可以看到
		![[屏幕截图 2026-03-07 155232.png|500]]
		随后关闭qemu，找到hdc-0.11.img硬盘镜像文件，进行挂载：
		```shell
		fdisk hdc-0.11.img
		mkdir hdc
		df -h
		sudo mount -t minix -o loop,offset=512 hdc-0.11.img hdc
		df -h
		ll hdc
		```
		观察到如下图所示的输出，说明挂载成功
		![[屏幕截图 2026-03-07 161509.png|500]]
	5. 在hdc中创建文件
		```shell
		cd hdc/usr
		sudo touch hello.txt
		sudo vim hello.txt
		cd ~
		sudo umount /dev/loop12
		df -h
		cd lab1/Linux-0.11
		qemu-system-i386 -m 16 -boot a -fda Image -hda hdc-0.11.img
		```
		观察到如下输出
		![[屏幕截图 2026-03-07 163242.png|500]]
		再重新启动qemu，查看是否有hello.txt文件：
		![[屏幕截图 2026-03-07 163601.png|500]]
		使用`cat`指令，观察到输出了hello.txt中之前输入的内容。
### ------------------------- 实验任务7 -------------------------
- 任务要求：下载安装麒麟操作系统并在VirtualBox虚拟机中运行，认识不同Linux发行版和不同CPU架构之间的差异
- 思路分析：到官网下载麒麟V11服务器版本，注意版本的要求，以及麒麟系统安装后环境的配置，和一些命令的不同
- 实验步骤：
	1. 了解系统基本信息
		```shell
		cat /etc/os-release
		uname -a
		cat /proc/cpuinfo
		free -h
		df -h
		```
		看到以下输出说明是麒麟Linux高级服务器版V11
		![[屏幕截图 2026-03-08 001017.png]]
		![[屏幕截图 2026-03-08 001037.png|550]]
		![[屏幕截图 2026-03-08 001058.png|550]]
		思考题：
		- Ubuntu和Kylin的操作系统名称和版本的异同：
			- Ubuntu：Ubuntu 22.04.5 LTS
			- Kylin：Kylin Linux Advanced Server V11(Swan25)
		- CPU架构信息和不同架构输出差异：
			- 都是x86_64
			- 都主要输出processor, vendor_id, cpu family, model等信息
		- 内核版本差异：
			- Ubuntu: `Linux version 6.8.0-101-generic (buildd@lcy02-amd64-087) (x86_64-linux-gnu-gcc-12 (Ubuntu 12.3.0-1ubuntu1~22.04.2) 12.3.0, GNU ld (GNU Binutils for Ubuntu) 2.38) `
			- Kylin: `Linux version 6.6.0-32.7.v2505.ky11.x86_64 (KYLINSOFT@7066681e4dc1) (gcc (GCC) 12.3.1 (kylin 12.3.1-62.p01.ky11)`
	2. 包管理器对比：yum/dnf VS apt
		```shell
		yum search gcc
		yum info gcc
		rpm -qa | grep gcc
		cat /etc/yum.repos.d/*.repo
		```
		输出如下图所示，表明麒麟操作系统使用的是麒麟官方软件源
		![[屏幕截图 2026-03-08 001412.png|500]]
		![[屏幕截图 2026-03-08 001432.png|500]]
		![[屏幕截图 2026-03-08 001556.png|500]]
		![[屏幕截图 2026-03-08 001607.png|500]]
	3. 了解CPU架构
		```shell
		uname -a
		lscpu
		gcc -dumpmachine
		```
		输出如下图
		![[屏幕截图 2026-03-08 001640.png|500]]
		![[屏幕截图 2026-03-08 001709.png|300]]
		思考题：
		- ARM是RISC精简指令集结构，每条指令的长度固定、执行周期短，需要的硬件消耗就小，功耗更低，成本也低，因此适合电池容量小、需要便携的移动设备。
		- x86是CISC复杂指令集结构，指令复杂、数量多、长度不固定，需要的硬件消耗更大，能提供更好的性能，因此适合支持高功耗的计算机、服务器。
### ------------------------- 实验任务8 -------------------------
- 任务要求：在麒麟操作系统中探索正在运行的内核，通过实际操作加深对内核机制的理解
- 思路分析：仿照前面几个实验任务对Ubuntu系统的探索，并注意在麒麟中的差异
- 实验步骤：
	1. 探索/proc虚拟文件系统
		```shell
		cat /proc/version
		cat /proc/uptime
		cat /proc/meminfo
		cat /proc/self/status
		cat /proc/filesystem
		cat /proc/cmdline
		```
		观察到如下输出
		![[屏幕截图 2026-03-08 002724.png|500]]
		![[屏幕截图 2026-03-08 002743.png|500]]
		![[屏幕截图 2026-03-08 002808.png|500]]
		![[屏幕截图 2026-03-08 002822.png|500]]
		- 思考题：
			1. 查看`/proc/`目录下的数字目录及其代表含义
				```shell
				cat /proc/1/status
				```
				观察到如下输出
				![[屏幕截图 2026-03-08 003412.png|250]]![[Pasted image 20260311170449.png|250]]
				1代表这是ID为1的进程，系统初始化进程 **`systemd`** 的当前状态信息，并且这个文件是虚拟文件系统的一部分；
				2则是内核线程 **`kthreadd`**，它是内核的线程守护进程，负责创建和管理其他内核线程
			2. 对比麒麟OS上`/proc/cpuinfo`的输出和本地x86的
				![[Pasted image 20260311172331.png|400]]
				通过与本地x86的输出对比，差异项主要在processor数量、siblings和cpu cores、microcode、cpu MHz、cpuid level、core id和apicid等等
			3. 找出当前系统中占用内存最多的五个进程
				```shell
				​ps aux --sort=-%mem | head -6
				```
				![[屏幕截图 2026-03-08 003358.png|500]]
				可见占用内存最多的前五个进程为`kwin_x11`, `Xorg`, `kylin-screenshot`, `ukui_sidebar`和`ukui-panel`
	2. 分析系统启动日志
		```shell
		journalctl -k --no-pager | head -50
		journalctl -k --no-pager | grep -i "boot"# 查看与启动相关的信息
		journalctl -k --no-pager | grep -i "cpu"# 查看CPU初始化信息
		journalctl -k --no-pager | grep -i "memory"# 查看内存初始化信息
		journalctl -k --no-pager | grep -i "driver"# 查看设备驱动加载信息
		```
		可观察到内核启动的输出及其关键阶段
		![[屏幕截图 2026-03-08 110810.png|500]]
		![[屏幕截图 2026-03-08 110911.png|500]]
		![[屏幕截图 2026-03-08 110924.png|500]]
		![[屏幕截图 2026-03-08 110937.png|500]]
		![[屏幕截图 2026-03-08 110945.png|500]]
		- 思考题：
			1. 关键阶段：
				1. 物理内存布局探测，由`BIOS-provided physical RAM map`可见
				2. 虚拟化环境检测与时钟初始化，由`Hypervisor detected: KVM`可见
				3. ACPI表解析，以`ACPI`开头的行即是
			2. 与gdb调试`start_kernel`联系：
				日志记录了gdb调试时候的工作执行，在调试过程中，内核检测到自身处于某种状态，或者正在执行某种动作，都会将当前信息输出记录到日志里
	3. 理解内核模块
		```shell
		lsmod
		modinfo.ext4
		modinfo.ext4 | -i "description"
		modinfo.ext4 | -i "auth"
		modinfo.ext4 | -i "depends"
		```
		可以观察到如下输出，以及`description`、`author`、`depends`等字段
		![[屏幕截图 2026-03-08 111653.png|500]]
		![[屏幕截图 2026-03-08 111719 1.png|500]]
		![[屏幕截图 2026-03-08 111906.png|500]]
		创建内核模块源文件
		```shell
		mkdir -p ~/lab1/mymodule
		cd ~lab1/mymodule
		vi hello_module.c 
		```
		创建Makefile
		```makefile
		cobj-m += hello_module.o
		KDIR := /lib/modules/$(shell uname -r)/build
		all:
			make -C $(KDIR) M=$(PWD) modules
		clean:
		make -C $(KDIR) M=$(PWD) clean
		```
		编译并加载
		```shell
		make
		file hello_module.ko
		sudo insmod hello_module.ko
		journalctl -k --no-pager | tail -5
		lsmod | grep hello
		sudo rmmod heelo_module
		journalctl -k --no-pager | tail -3
		```
		可以观察到生成了`hello_module.ko`文件，以及模块输出`Hello! This module is running on Kylin OS.`和`Goodbye! Module unloaded from Kylin OS.`
		![[Pasted image 20260311194831.png|400]]
		![[屏幕截图 2026-03-08 125629.png|500]]
		![[屏幕截图 2026-03-08 125641.png|500]]
		- 思考题：
			1. 用户态程序使用`printk`输出函数，输出到内核日志缓冲区。不能使用`printf`函数的原因：`printf`是C库函数，依赖用户态运行环境，而内核运行在特权级，不支持C库，不能访问用户态。
			2. `MODULE_LICENSE("GPL")`的作用是声明模块采用的许可证，使内核与GPL兼容，从而可以调用`EXPORT_SYMBOL_GPL` 导出的内核符号。如果将`GPL`改为`Unknown`，可以看到`dmesg`输出如下
				![[屏幕截图 2026-03-11 205833.png|500]]
			3. `__init` 和 `__exit` 宏的作用
				- **`__init`**：标记模块初始化函数，执行完毕后，内核会释放该函数占用的内存，将其回收。若模块被编译进内核，`__init` 标记的函数在系统启动后也会被释放。
				- **`__exit`**：标记模块卸载函数，如果模块被编译进内核，该函数会被丢弃，不占用内存，有助于减小运行时内核映像的体积。
	4. 观察系统调用
		```shell
		sudo yum install -y strace
		strace ls /tmp 2>&1 | head -30
		strace cat /proc/version 2>&1 \ head -30
		strace -c ls /tmp
		```
		观察系统调用以及其种类和次数
		![[屏幕截图 2026-03-08 130344.png|500]]
		![[屏幕截图 2026-03-08 130518 1.png|500]]
		- 思考题：
			1. `ls`主要使用了`openat` `getdents64` `close` `stat` `mmap` `write`等系统调用，其中`openat`用于打开文件或目录，`getdents64`用于读取目录项，`write`用于将结果输出到终端
			2. 编写C程序并用`starce`统计系统调用
				```c
				#include <stdio.h>
				int main() {
					printf("Hello, world!\n");
					return 0;
				}
				```
				```shell
				gcc -o hello hello.c -static
				strace -c ./hello
				```
				![[屏幕截图 2026-03-08 131339.png|500]]
				可以看到一共17个系统调用
	5. 使用QEMU体验架构运行
		```shell
		ls /usr/bin/qemu-system-*
		sudo yum install qemu-system-aarch64
		qemu-system-aarch64 -M virt -cpu cortex-a57 -m 2G \
		  -kernel ~/桌面/Image \
		  -initrd ~/桌面/initrd.img \
		  -append "root=/dev/sda1 console=ttyAMA0" \
		  -drive file=~/桌面/ubuntu-22.04-server-cloudimg-arm64.img,format=qcow2,if=virtio \
		  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
		  -nographic
		```
		结果成功看到qemu运行BusyBox系统
		![[屏幕截图 2026-03-08 132500.png|500]]
		![[屏幕截图 2026-03-08 195848.png|500]]
		![[屏幕截图 2026-03-08 195930.png|500]]
		- 思考题：因为在跨架构模拟运行内核的时候，QEMU必须把每条指令翻译为主机架构的指令再执行，这个行为非常耗费时间。而同架构虚拟化就可以用KVM硬件虚拟化加速。
## **Section 3 实验总结与心得体会**

### 实验中的一些困难
首先是在环境搭建阶段，第一个问题就是要选择对应统一的版本。一开始安装virtualbox的增强功能就是因为版本和Ubuntu虚拟机版本不一样导致失败。此外还有各种工具的下载，需要细细跟着教程来，不难但是比较耗费精力。而且如有遗漏或失误，也很难排查。

在调试阶段，使用 QEMU 配合 GDB 进行远程调试是我认为这个实验中最难的部分之一。虽然命令本身并不复杂，还可以询问大模型每条指令的含义，但是来回之间总有一些命令不理解，有纰漏；以及要同时开两个命令行窗口一边运行qemu一边gdb调试，这是之前未有的尝试。这个部分里有一个需要设置断点、查看寄存器状态以及单步执行的操作，在这个地方我重复做了很多遍，甚至到最后整个实验做完还回来继续完善，就是因为单步执行总是不太顺利。需要对内核启动流程有基本认识，我看到大量汇编代码时都无法判断当前执行的情况，也就无从debug。特别是在 `start_kernel` 附近进行单步调试，折腾了很长时间……

另外，关于最后两个麒麟操作系统的部分。一开始光是下载操作系统的iso文件我就下载了三次，因为指导文档中也无明确的要求具体版本，但是后面的一些操作都体现版本的差异，为此我反复下载了几次。以及为了和本地主机共享鼠标和剪切板，需要安装VirtualBox的增强功能，在麒麟操作系统中的安装要比Ubuntu里麻烦许多。此外，麒麟操作系统很难用，交互逻辑不太好，也不流畅。
### 过程中的收获

通过完整地从源码编译 Linux 内核、启动系统并进行调试，对操作系统的整体结构有了更加直观的认识，例如内核初始化、文件系统挂载、用户态和内核态的区别等，都通过实际操作观察到。特别是在 GDB 中进入 `start_kernel` 函数后，可以看到内核初始化的一系列函数调用，虽然这个过程让我重复试错很多遍，但确实加深对内核初始化的函数调用理解。

在构建 BusyBox 系统时，也初步理解了 Linux 系统启动的基本流程：内核启动后会加载 initramfs 作为临时根文件系统，然后执行其中的 `init` 程序，再逐步完成系统初始化。

通过对 `/proc` 文件系统、内核模块以及系统调用的简单探索，也进一步理解了 Linux 内核与用户程序之间的交互方式。例如 `/proc` 目录中的内容实际上是内核在运行时动态生成的信息，通过读取这些文件可以直接获取系统状态；而 `strace` 则能够清楚地展示用户程序在执行过程中调用了哪些系统调用。

此外，在整个过程中还多次利用vim工具编写了c文件，makefile文件或脚本文件，并且手动编译生成了可执行文件等等，对编译链接的过程的认识也更加深入。

总体来看，本次实验最大的收获在于实际动手进行操作。通过实际编译内核、启动系统并进行调试，更加直观地理解操作系统的启动过程和基本结构。同时也学会通过搜索、询问大模型等方法实际解决问题的能力。