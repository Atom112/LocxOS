# LocxOS 最小化 x86_64 内核

LocxOS 是一个用于学习操作系统底层的实验项目，技术栈为 C 语言 + 少量汇编。

当前版本已经完成最小可运行闭环：

- 通过 GRUB2 + Multiboot2 引导内核
- 切换到 x86_64 Long Mode
- 进入 C 语言内核入口
- 向 VGA 文本缓冲区输出字符串
- 向串口输出调试日志

## 文档导航

- 版本变更记录：[CHANGELOG.md](CHANGELOG.md)
- 总体开发路线图：[开发计划.md](开发计划.md)
- 项目结构与文件职责：[doc/项目结构与文件说明.md](doc/项目结构与文件说明.md)
- 调试与学习路径：[doc/调试与学习手册.md](doc/调试与学习手册.md)
- 代码对照学习索引：[doc/代码对照学习索引.md](doc/代码对照学习索引.md)
- 启动时序与寄存器变化：[doc/启动时序图与寄存器状态.md](doc/启动时序图与寄存器状态.md)

## 开发环境

- 主机系统：Windows
- 构建与调试：WSL（建议 Ubuntu-24.04）

在 WSL 中安装依赖：

```bash
sudo apt update
sudo apt install -y build-essential grub-common grub-pc-bin xorriso qemu-system-x86 gdb
```

建议固定使用指定发行版执行命令（避免多 WSL 发行版环境漂移）：

```bash
wsl -d Ubuntu-24.04 bash -lc "cd /mnt/c/base/LocxOS; make all CROSS="
```

## 构建与运行

使用系统 GCC（当前可用路径）：

```bash
wsl -d Ubuntu-24.04 bash -lc "cd /mnt/c/base/LocxOS; make clean; make all CROSS="
wsl -d Ubuntu-24.04 bash -lc "cd /mnt/c/base/LocxOS; make iso CROSS="
wsl -d Ubuntu-24.04 bash -lc "cd /mnt/c/base/LocxOS; make run CROSS="
```

串口模式运行（推荐调试时使用）：

```bash
wsl -d Ubuntu-24.04 bash -lc "cd /mnt/c/base/LocxOS; make run-serial CROSS="
```

预期串口输出：

- `[serial] LocxOS booting...`
- `[serial] VGA message rendered`

## GDB 调试

终端 A（启动并等待 GDB）：

```bash
wsl -d Ubuntu-24.04 bash -lc "cd /mnt/c/base/LocxOS; make debug CROSS="
```

终端 B（快速附加）：

```bash
wsl -d Ubuntu-24.04 bash -lc "cd /mnt/c/base/LocxOS; make gdb CROSS="
```

或手动 GDB：

```bash
gdb build/kernel.elf
(gdb) target remote :1234
(gdb) break kmain
(gdb) continue
```

## 清理

```bash
make clean
```
