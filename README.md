<p align="center">
	<img src="LocxOS.svg" alt="LocxOS Logo" width="220" />
</p>

# LocxOS x86_64 操作系统内核

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
- 构建与调试：WSL（建议使用 Ubuntu、Debian 等常见 Linux 发行版）

## 环境配置说明

不同学习者的设备环境可能不同，以下两个信息通常不是固定值，使用前请先替换成你自己的环境：

- `<你的WSL发行版名>`：例如 `Ubuntu`、`Ubuntu-24.04`、`Debian`
- `<项目在WSL中的路径>`：例如 `/mnt/c/Users/你的用户名/LocxOS` 或 `/home/你的用户名/LocxOS`

如果你不确定自己的 WSL 发行版名，可在 PowerShell 中执行：

```powershell
wsl -l -v
```

如果你不确定项目在 WSL 中的路径，可先进入对应发行版后执行：

```bash
pwd
```

或在项目目录下执行：

```bash
cd <你的项目目录>
pwd
```

在 WSL 中安装依赖：

```bash
sudo apt update
sudo apt install -y build-essential grub-common grub-pc-bin xorriso qemu-system-x86 gdb
```

如果你有多个 WSL 发行版，建议显式指定发行版执行命令，避免环境漂移：

```bash
wsl -d <你的WSL发行版名> bash -lc "cd <项目在WSL中的路径>; make all CROSS="
```

如果你已经进入了 WSL 终端，也可以直接在项目目录中执行 `make`，不需要再写 `wsl -d ...` 前缀。

## 构建与运行

使用系统 GCC（当前可用路径）：

```bash
wsl -d <你的WSL发行版名> bash -lc "cd <项目在WSL中的路径>; make clean; make all CROSS="
wsl -d <你的WSL发行版名> bash -lc "cd <项目在WSL中的路径>; make iso CROSS="
wsl -d <你的WSL发行版名> bash -lc "cd <项目在WSL中的路径>; make run CROSS="
```

如果你已经在 WSL 项目目录中：

```bash
make clean
make all CROSS=
make iso CROSS=
make run CROSS=
```

串口模式运行（推荐调试时使用）：

```bash
wsl -d <你的WSL发行版名> bash -lc "cd <项目在WSL中的路径>; make run-serial CROSS="
```

预期串口输出：

- `[serial] LocxOS booting...`
- `[serial] VGA message rendered`

## GDB 调试

终端 A（启动并等待 GDB）：

```bash
wsl -d <你的WSL发行版名> bash -lc "cd <项目在WSL中的路径>; make debug CROSS="
```

终端 B（快速附加）：

```bash
wsl -d <你的WSL发行版名> bash -lc "cd <项目在WSL中的路径>; make gdb CROSS="
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

## 额外说明

1. README 中涉及的发行版名称和项目路径都应视为示例，不应直接假定与你的设备一致。
2. 如果你的环境已经安装了 `x86_64-elf-gcc` 交叉工具链，可以不使用 `CROSS=` 回退模式，而是直接执行 `make all`。
3. 如果使用系统 GCC 构建，请保留当前 Makefile 中的 `-fno-pie` 和 `-no-pie` 配置。
