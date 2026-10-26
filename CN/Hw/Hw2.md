## 4

a. URL是 `cs453/index.html` 位于报文第一行（请求行）GET之后
b. HTTP版本：1.1 位于请求行HTTP之后
c. 持续连接，位于最后一行， `Connection:keep-alive`
d. 主机IP地址：无
e. 类型：`Netscape/7.2`在 `User-Agent`里

## 7

找到IP地址花费：$RTT_{1}+RTT_{2}+\dots+RTT_{n}$
然后本地主机和目标服务器之间的响应时间就是 $2RTT+HTML对象传输时间=2RTT_{0}$
所以一共是$2RTT_{0}+RTT_{1}+\dots+RTT_{n}$
## 8
a. $(8+1)\times2RTT_{0}+RTT_{1}+\dots+RTT_{n}=18RTT_{0}+RTT_{1}+\dots+RTT_{n}$
b. $(\lceil \frac{8}{5} \rceil+1) \times2RTT_{0}+RTT_{1}+\dots+RTT_{n}=6RTT_{0}+RTT_{1}+\dots+RTT_{n}$
c. $(8+2)RTT_{0}+RTT_{1}+\dots+RTT_{n}=10RTT_{0}+RTT_{1}+\dots+RTT_{n}$
## 15

SMTP中的MAIL FROM是握手协议的一部分，规定的格式，由RFC5321规定，主要指定一个地址，不会让收信人直接看到
而邮件报文自身的From是自身的一部分，属于邮件内容的一部分，可以让收信人看到
## 18

a. whois是一个分布式、公开可查询的在注册信息数据库，记录了域名、IP地址、AS号等互联网信息
b. 
	查询 `google.com`得到 
		服务器：`Nameservers: NS1.GOOGLE.COM Address:216.239.32.10`
		数据库：
			 Registry Server URL: [https://rdap.verisign.com/com/v1/domain/google.com](https://rdap.verisign.com/com/v1/domain/google.com)`
			 Registrar Server URL: [https://rdap.markmonitor.com/rdap/domain/GOOGLE.COM](https://rdap.markmonitor.com/rdap/domain/GOOGLE.COM)`
	查询 `baidu.com`得到
		服务器：`Nameservers:NS1.BAIDU.COM Address:110.242.68.134`
		数据库：
			Registry Server URL: [https://rdap.verisign.com/com/v1/domain/baidu.com](https://rdap.verisign.com/com/v1/domain/baidu.com)
			Registrar Server URL: [https://rdap.markmonitor.com/rdap/domain/BAIDU.COM](https://rdap.markmonitor.com/rdap/domain/BAIDU.COM)
c. 通过 `ipconfig`命令查得本地服务器为`DNS Servers . . . . . . : 10.8.8.8, 10.8.4.4`
	分别向本地、google和baidu发起三类DNS查询
	发现：NS查询只会返回一些域名，也就是知道如何获取域中主机IP地址的权威服务器的主机名；而A类查询会直接返回一个IP地址，就是查询的主机名对应的IP；MX查询的结果会返回一个邮件服务器的域名，以及这个域名的一系列的IP地址
d. 
	如图
	![[Pasted image 20261003224747.png|350]]![[Pasted image 20261003224807.png|375]]
	百度的web服务器就有多个IP地址 我的学校的域名查询总是只返回一个IP地址，无法判断是否有多个
e. 
	![[Pasted image 20261003225849.png|537]]
	如图，IP地址的范围为 202.120.0.0/15
f. 如果攻击者知道目标域名，就可以查到IP地址，然后在Whois上查询这个IP地址，就可以得到所属组织、
CIDR等信息
g. 将Whois数据库对公众开放，可以在当某个公网IP出现问题的时候大家一起对其进行查询，向所属管理者提出报警等等

## 23

### a.
$\frac{u_{s}}{N}\leq d_{min}$，则$\frac{NF}{u_{s}}\geq \frac{F}{d_{min}}$需要设计分发时间为$\frac{NF}{u_{s}}$也就是说要在服务器上传完毕的那一刻所有客户端也都下载完毕。这要求尽量使每一时刻所有客户端都在忙于下载，使分发时间取决于服务器的上传速度。那么可以设计每一个时刻服务器上传进来的数据对这个N个对等方进行分配，并且分配的量的比例是$d_{1}:d_{2}:\dots:d_{n}$，这样恰好使每个对等方在下载完毕之前永远忙于下载，速度快的客户端可以提前下载完，即使是最慢的那个，由于整个过程一直在忙于下载，所以也可以下载完。

### b.
跟上一题同理，这里的分发时间由最慢的对等方决定，那么必须要求这个对等方一直忙于下载，否则一定会超过$\frac{F}{d_{min}}$ 的时间，那么依旧可以按照分配的量的比例是$d_{1}:d_{2}:\dots:d_{n}$来设计

### c.
所以不论$\frac{u_{s}}{N}$和$d_{min}$ 的大小关系如何，只要按照上面的设计方案，最小分发时间就是$max(\frac{NF}{u_{s}},d_{min})$
## 24

### a. 
当$u_s\leq\frac{u_1+u_2+\cdots+u_N}{N}$要求构造一个分发时间为${\frac{F}{u_s}}$的方案
服务器必须至少把整个文件上传一次，所以服务器至少需要上传：$T\geq\frac{F}{u_s}$，假设$T=\frac{F}{u_s}$
那么服务器在这段时间内刚好能够上传：$u_{s}T=F$也就是服务器把整个文件上传出去
关键是服务器上传出去的这些数据，还需要通过 P2P 用户之间的上传，把文件复制给其他用户
因此必须要求所有用户尽量一直忙于上传，使得瓶颈在服务器那边
所以可以让服务器在一段时间内上传的数据$u_{s}\triangle t$划分为N份，以$u_{1}:u_{2}:..:u_{N}$的比例分配给N个对等方，让他们进行上传。这样可以使得服务器上传的数据立即就全部分配给各个对等方以总的更快的速度进行上传，所以最后服务器上传完毕的时候，所有客户端那边会更快上传完毕，总的时间就是$\frac{NF}{u_{s}}$
### b. 
同理，依然按比例把每个时刻的上传数据分配给这N个对等方，不过由于服务器的速度快，在服务器上传完成之后每个客户端应该都按比例积压了未上传的数据，只要继续上传即可，总的时间就是$\frac{NF}{\Sigma u}$

### c.
按照上述设计的方案，最小分发时间就是服务器或者对等方中成为瓶颈的那一方，$\max\left( \frac{F}{u_{s}}, \frac{NF}{\Sigma u} \right)$
## 26
### a.
可以，是可能的
其他peer可能会按照自己的策略主动给他，或者在他请求之后给他
即使他不上传，也有Optimistic Unchoking策略，偶尔会允许给他

### b.
可以通过多台计算机的不同IP地址，以不同的身份加入BitTorrent，这样每一个都有获得文件的机会，每个还都有可能获得其他人的unchoke机会，增大了获取文件的机会，更有效