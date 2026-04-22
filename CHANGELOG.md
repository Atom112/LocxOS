# Changelog

本文件用于记录 LocxOS 的可见变更，便于学习回顾和阶段复盘。


## [Unreleased]

### Planned

- M1：中断与异常基础（IDT、#DE/#GP/#PF）
- M2：时钟中断与 tick 计数
- M3：物理内存管理（PMM）

## [0.2.0] - 2026-04-22

### Added

- 新增串口驱动 `COM1`（初始化与轮询发送）：[kernel/arch/x86_64/serial.c](kernel/arch/x86_64/serial.c)
- 新增 QEMU 串口运行目标：`make run-serial`
- 新增调试目标：`make debug`（`-s -S`）与 `make gdb`（自动附加断点）
- 新增中文文档目录与学习手册：
  - [doc/项目结构与文件说明.md](doc/项目结构与文件说明.md)
  - [doc/调试与学习手册.md](doc/调试与学习手册.md)
  - [doc/代码对照学习索引.md](doc/代码对照学习索引.md)
  - [doc/启动时序图与寄存器状态.md](doc/启动时序图与寄存器状态.md)
- 新增根目录开发路线图：[开发计划.md](开发计划.md)

### Changed

- 内核入口增加串口日志输出并保留 VGA 输出确认：
  - [kernel/kernel.c](kernel/kernel.c)
- `README` 改为中文并补全 WSL 开发/调试流程：
  - [README.md](README.md)
- `Makefile` 补充 freestanding 内核构建参数，显式禁用 PIE（`-fno-pie` / `-no-pie`）以适配系统 GCC 回退路径。

### Fixed

- 修复系统 GCC 默认 PIE 导致的内核链接失败问题。
- 为汇编文件增加 `.note.GNU-stack`，消除可执行栈告警。

## [0.1.0] - 2026-04-22

### Added

- 最小可运行 x86_64 内核启动链路：
  - GRUB2 + Multiboot2 引导
  - 32 位入口到 64 位 Long Mode 切换
  - C 入口 `kmain`
- 最小页表初始化（低端 1GiB 恒等映射，2MiB 大页）：
  - [kernel/arch/x86_64/paging.s](kernel/arch/x86_64/paging.s)
- Long Mode 初始化流程：
  - [kernel/arch/x86_64/long_mode_init.s](kernel/arch/x86_64/long_mode_init.s)
- VGA 文本输出驱动：
  - [kernel/arch/x86_64/vga.c](kernel/arch/x86_64/vga.c)
- 链接脚本与 ISO 打包流程：
  - [kernel/arch/x86_64/linker.ld](kernel/arch/x86_64/linker.ld)
  - [iso/boot/grub/grub.cfg](iso/boot/grub/grub.cfg)
  - [Makefile](Makefile)

### Verified

- 在 Windows + WSL 环境完成 `make all / make iso / make run` 基本验证。
