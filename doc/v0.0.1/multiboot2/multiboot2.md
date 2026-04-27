# Multiboot2 协议基础

参考资料：https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html

在一台纯净无操作系统的机器（裸机）上运行你的代码，你不得不面临一个难题：主板 BIOS/UEFI 首先启动以后怎么才会乖乖把接力棒交给你？在古老的年代，你需要自己去手写复杂的 Bootloader （还要压缩进可怜的 512 字节主引导扇区里），既要读硬盘又要初始化屏幕等。

后来针对这问题诞生了 **GRUB 启动管理器** 及其它推崇的标准：**Multiboot**。

如果你的系统使用 Multiboot(2) 标准构建，你就可以白嫖 GRUB 内置极其强大的硬盘引导和前期系统硬件初始化功能：GRUB 识别后就会主动读取你的内核加载入内存，最后将处理器的控制权极其干净利落地交到内核入口点手中。

## 什么是 Multiboot 协议的魔法标志？

Multiboot 协议的规定非常简单直接：只要在 ELF 二进制文件的头部（通常指的是文件前 32768 个字节内的某个受保护区域），藏有一组格式特定的**魔法特征结构体 (Multiboot Header)** 就可以了。GRUB 只会在解析硬盘镜像寻找这特殊的“字符串”，只要它搜到了且对得上暗号，它就承认这是一个标准的 Multiboot OS 而毫不犹豫去加载执行它！

来看一下 kernel/arch/x86_64/boot.s 中我们针对 Multiboot 2 设定的头部暗号：

```c
.section .multiboot
.align 8
multiboot_header:
/* 魔数：固定值 0xE85250D6。 */
.long 0xE85250D6
/* 架构字段：0 表示 i386 */
.long 0
/* 头部总长度。 */
.long multiboot_header_end - multiboot_header
/* 校验和：让 magic + arch + length + checksum == 0 (mod 2^32)。 */
.long -(0xE85250D6 + 0 + (multiboot_header_end - multiboot_header))

.align 8
/* 结束标签（type=0,size=8）。 */
.short 0
.short 0
.long 8
multiboot_header_end:
```

### 控制字段详解

1.  **魔数 (Magic Number)**：
    Multiboot2 的标准身份特征数字是固定 0xE85250D6 （第一代的 Multiboot 则是 0x1BADB002 ）。这就相当于给 GRUB 的指纹扫描接口对暗号。
2.  **架构 (Architecture)**：
    数字 0 指代 32位 i386（包含受到遗留兼容性支持的 x86_64 体系）。这正是目前基于大多数 PC/QEMU 环境我们所处的环境结构。这里我们依赖于 GRUB 加载它为一个 32位 保护模式的系统，之后它会任由我们用汇编自力更生把它升格转换为 64位 的模式（ Long Mode ）。
3.  **头部长度 (Header Length)**：
    头部的物理占用空间字节偏移数（用结尾的地址减去其实地址即可）。
4.  **校验和 (Checksum)**：
    反篡改和反冲突位。协议要求 魔数 + 架构版本 + 记录长度 + 本校验和值 加在一起必须严格等于 0（这会发生 32位 有符号数溢出归零效果）。如果不为零，GRUB 认为该头无效而拒绝加载。所以我们在代码里用负号直接求这几个数原本加值的负数进行抵消。

### 标签结构 (Tags)

Multiboot 2 相比于初代引入了极其灵活强大的的扩展“标签（Tags）”。你可以在这个数组之后添加一些额外的控制结构块：比如要求 GRUB 必须向你传递关于当前硬件显卡 Framebuffer 显示特性的细节、要告诉关于主板内存大小拓扑状况表等信息。

由于我们的入门型内核暂时非常简单，为了顺利通关验证只塞了一个最简单要求： **结束标签**。
结束标记的格式固定：Type=0 (.short 0), 标志位=0 (.short 0), 占用 Size=8 字节大小 (.long 8) 即可完美收卷。

这套简单的魔法结构体一经编译链接被打包进最优先的段内，就是我们启动流程中极其坚实的桥头堡保障！
