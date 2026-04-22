/* 输出为 x86_64 ELF，可被 GRUB 直接加载。 */
OUTPUT_FORMAT(elf64-x86-64)
/* 内核入口符号，定义在 boot.s。 */
ENTRY(_start)

SECTIONS
{
	/* 把内核放在 1MiB 附近是传统且安全的教学起点。 */
	. = 1M;

	/* 强制保留 Multiboot2 头，防止被链接器优化丢弃。 */
	.multiboot : ALIGN(8)
	{
		KEEP(*(.multiboot))
	}

	/* 代码段。 */
	.text : ALIGN(4K)
	{
		*(.text*)
	}

	/* 只读数据段（字符串常量等）。 */
	.rodata : ALIGN(4K)
	{
		*(.rodata*)
	}

	/* 已初始化全局数据段。 */
	.data : ALIGN(4K)
	{
		*(.data*)
	}

	/* 未初始化数据段（含启动栈、页表等）。 */
	.bss : ALIGN(4K)
	{
		*(COMMON)
		*(.bss*)
	}

	/* 丢弃对当前裸机目标无意义的节。 */
	/DISCARD/ :
	{
		*(.comment)
		*(.eh_frame*)
	}
}
