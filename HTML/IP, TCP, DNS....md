# Routers路由器
- To route data from one place to another, we need to make _routing decisions_. That is, someone needs to program how data is transferred from point A to point B.
- You can imagine how data could take multiple paths from point A and point B, such that when a router is congested, data can flow through another path. $Packets$ of data are transferred from one router to another, from one computer to another.
# TCP/IP
- _TCP/IP_ are two protocols that allow computers to transfer data between them over the internet.
## IP
- _IP_ or _internet protocol_ is a way by which computers can identify one another across the internet. Every computer has a unique address in the world. Addresses are in this form:
    ```
    #.#.#.#
    ```
- Numbers range from _`0`_ to  _`255`_. IP addresses are 32-bits, meaning that these addresses could accommodate over 4 billion addresses. Newer versions of IP addresses, implementing 128-bits, can accommodate far more computers!
## Packets
Packets are structured as follows:

```
0                   1                   2                   3  
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|Version|  IHL  |Type of Service|          Total Length         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|         Identification        |Flags|      Fragment Offset    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Time to Live |    Protocol   |         Header Checksum       |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                       Source Address                          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Destination Address                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Options                    |    Padding    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## TCP (Transmission Control Protocol)
- _TCP_, or transmission control protocol, helps keep track of the sequence of packets being sent.  
    TCP，即传输控制协议，有助于跟踪正在发送的数据包的顺序。
- Further, TCP is used to distinguish web services from one another. For example, `80` is used to denote HTTP and `443` is used to denote HTTPS. These numbers are _port numbers_.  
    此外，TCP 用于区分不同的网络服务。例如， `80` 用于表示 HTTP， `443` 用于表示 HTTPS。这些数字是端口号。
- When information is sent from one location to another, a source IP address, a destination IP address, and a TCP port number are sent.  
    当信息从一个地点发送到另一个地点时，会发送源 IP 地址、目标 IP 地址和 TCP 端口号。
- These protocols are also used to fragment large files into multiple parts or packets. For example, a large photo of a cat can be sent in multiple packets. When a packet is lost, TCP/IP can request missing packets again from the origin server.  
    这些协议也用于将大文件分割成多个部分或数据包。例如，一张猫的大照片可以分成多个数据包发送。当某个数据包丢失时，TCP/IP 可以从源服务器再次请求缺失的数据包。
- TCP will acknowledge when all the data has been transmitted and received.  
    TCP 将在所有数据都传输和接收后进行确认。
### 主要特点

1. **面向连接**
    - 在传输数据前，通信双方必须建立连接（通过“三次握手”）。
    - 确保两端都准备好收发数据。
2. **可靠传输**
    - TCP 通过**确认应答机制**保证数据不会丢失。
    - 发送方丢包 → 自动重传。
    - 接收方按顺序组装数据（乱序会重新排序）。
3. **全双工通信**
    - 双方可以同时收发数据。
    - 相当于两条数据通道同时工作。
4. **面向字节流**
    - TCP 不关心数据分成多少“消息”，只把它当作一串连续的字节流。
    - 发送时分段（Segment），接收时重新组合。
---
### 工作过程
#### 连接建立（**三次握手**）
目的：建立双方的序列号和确认号，保证后续通信可靠。
1. **SYN**：客户端 → 服务器，发送连接请求（SYN=1，seq=x）。
2. **SYN-ACK**：服务器 → 客户端，确认请求（ACK=x+1，SYN=1，seq=y）。
3. **ACK**：客户端 → 服务器，确认连接（ACK=y+1）。
---
# DNS(_Domain Name System_)
## 定义
DNS = **域名系统**  
作用：把域名（例如 `www.google.com`）翻译成 IP 地址 （例如 `142.250.190.78`）。 
## 为什么需要 DNS？

- IP 就像**电话号码**，但记一堆数字很难。
- DNS 就像**电话簿**，你只记名字（域名），它帮你查号码（IP）。
- 域名和 IP 一一对应（有时一个域名对应多个 IP，用于负载均衡）。

## 工作原理（查询过程）

1. **输入域名**  
    你在浏览器输入 `www.example.com`。
2. **本地缓存**  
    系统先查自己本地是否有该域名的 IP（DNS 缓存）。
3. **递归查询**（一般由你的网络服务商的 DNS 服务器完成）：
    1. **根域名服务器(Root Server)**  
        告诉你 `.com` 顶级域名服务器在哪。
    2. **顶级域名服务器(TLD Server)**  
        告诉你 `example.com` 的权威 DNS 服务器在哪。
    3. **权威 DNS 服务器（Authoritative Server）**  
        返回最终的 IP 地址，比如 `93.184.216.34`。
4. **返回结果并缓存**  
    DNS 服务器把 IP 返回给你，并缓存一段时间（由 TTL 决定）。
5. **浏览器发起 TCP/UDP 请求**  
    浏览器用拿到的 IP 连接服务器(比如 TCP 80/443 端口)
## DNS 查询方式
- **递归查询（Recursive Query）**  
    客户端只发一次请求，DNS 服务器帮你一步步找，直到找到最终 IP。
- **迭代查询（Iterative Query）**  
    DNS 服务器给你“下一步去找谁”，由客户端自己一步步去问。