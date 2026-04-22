/*
 * Multiboot2 头部必须放在可被引导器扫描到的位置（通常在内核镜像前部）。
 * GRUB 通过这个头判断镜像是否可按 Multiboot2 协议加载。
 */
.section .multiboot
.align 8
multiboot_header:
	/* 魔数：固定值 0xE85250D6。 */
	.long 0xE85250D6
	/* 架构字段：0 表示 i386（Multiboot2 对 x86_64 内核通常仍使用该值）。 */
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

.section .text
.code32
.global _start
.global stack_top
.extern setup_page_tables
.extern enable_long_mode

_start:
	/* 早期启动先关中断，避免未初始化 IDT 时被打断。 */
	cli
	/* 使用我们在 .bss 里准备的临时栈。 */
	mov $stack_top, %esp
	/* 初始化最小页表，为进入 long mode 做准备。 */
	call setup_page_tables
	/* 开启长模式并跳到 64 位入口。 */
	call enable_long_mode

halt32:
	/* 理论上不应回到这里；若回到这里就停机自旋。 */
	hlt
	jmp halt32

.section .bss
.align 16
stack_bottom:
	/* 16 KiB 启动栈。 */
	.skip 16384
stack_top:

/* 声明该目标不需要可执行栈，避免链接器告警。 */
.section .note.GNU-stack,"",@progbits
