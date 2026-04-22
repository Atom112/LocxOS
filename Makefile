# 交叉编译工具链前缀。
# 默认使用 x86_64-elf-*，如果想临时改为系统 gcc，可在命令行传 CROSS=
CROSS ?= x86_64-elf-

# C 编译与链接都通过 gcc 驱动，便于统一参数。
CC := $(CROSS)gcc
LD := $(CROSS)gcc

# 构建产物路径约定：所有中间文件和最终文件都放到 build/ 下。
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj
ISO_DIR := $(BUILD_DIR)/iso
KERNEL_ELF := $(BUILD_DIR)/kernel.elf
ISO_IMAGE := $(BUILD_DIR)/LocxOS.iso

# C 源文件：内核入口 + 输出设备（VGA/串口）。
C_SOURCES := \
	kernel/kernel.c \
	kernel/arch/x86_64/vga.c \
	kernel/arch/x86_64/serial.c

# 汇编源文件：启动入口、长模式切换、页表初始化。
ASM_SOURCES := \
	kernel/arch/x86_64/boot.s \
	kernel/arch/x86_64/long_mode_init.s \
	kernel/arch/x86_64/paging.s

C_OBJECTS := $(patsubst %.c,$(OBJ_DIR)/%.o,$(C_SOURCES))
ASM_OBJECTS := $(patsubst %.s,$(OBJ_DIR)/%.o,$(ASM_SOURCES))
OBJECTS := $(C_OBJECTS) $(ASM_OBJECTS)

# CFLAGS 说明：
# -ffreestanding  : 告诉编译器这是裸机环境，不依赖宿主运行时。
# -fno-stack-protector / -fno-pie : 禁用不适合早期内核的保护/PIE。
# -mno-red-zone   : 内核中断场景下避免 red zone 被破坏。
CFLAGS := -std=gnu11 -O2 -Wall -Wextra -ffreestanding -fno-stack-protector -fno-pic -fno-pie -m64 -mno-red-zone
ASFLAGS := -m64 -ffreestanding
# -no-pie 同样用于链接阶段；链接脚本决定镜像布局。
LDFLAGS := -nostdlib -ffreestanding -no-pie -z max-page-size=0x1000 -T kernel/arch/x86_64/linker.ld

.PHONY: all clean iso run run-serial debug gdb

# 默认目标：生成内核 ELF。
all: $(KERNEL_ELF)

$(KERNEL_ELF): $(OBJECTS)
	@mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

$(OBJ_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(CC) $(ASFLAGS) -c $< -o $@

iso: $(ISO_IMAGE)

# 组装 ISO：把 kernel.elf 与 grub.cfg 放到标准目录，再由 grub-mkrescue 打包。
$(ISO_IMAGE): $(KERNEL_ELF) iso/boot/grub/grub.cfg
	@mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL_ELF) $(ISO_DIR)/boot/kernel.elf
	cp iso/boot/grub/grub.cfg $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $@ $(ISO_DIR)

# 图形窗口启动。
run: $(ISO_IMAGE)
	qemu-system-x86_64 -cdrom $(ISO_IMAGE)

# 串口日志直接输出到终端，便于早期调试。
run-serial: $(ISO_IMAGE)
	qemu-system-x86_64 -cdrom $(ISO_IMAGE) -serial stdio

# 调试模式：-s 开 1234 gdb 端口，-S 让 CPU 在第一条指令前暂停。
debug: $(ISO_IMAGE)
	qemu-system-x86_64 -cdrom $(ISO_IMAGE) -serial stdio -s -S

# 一键附加 gdb，自动在 kmain 下断点。
gdb: $(KERNEL_ELF)
	gdb $(KERNEL_ELF) -ex "target remote :1234" -ex "b kmain" -ex "c"

# 清理所有构建产物。
clean:
	rm -rf $(BUILD_DIR)
