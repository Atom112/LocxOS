.section .text
.code32
.global enable_long_mode
.global long_mode_entry

.extern p4_table
.extern stack_top
.extern kmain

/*
 * 在 32 位环境中开启 long mode：
 * 1) CR3 指向页表
 * 2) CR4 开 PAE
 * 3) EFER 开 LME
 * 4) CR0 开 PG(+保持 PE)
 * 5) 远跳转刷新流水线并进入 64 位代码段
 */
enable_long_mode:
	/* 加载 P4 表物理地址到 CR3。 */
	mov $p4_table, %eax
	mov %eax, %cr3

	/* CR4.PAE = 1（bit5），64 位分页前置条件。 */
	mov %cr4, %eax
	or $0x20, %eax
	mov %eax, %cr4

	/* 通过 MSR 设置 EFER.LME（bit8）。 */
	mov $0xC0000080, %ecx
	rdmsr
	or $0x00000100, %eax
	wrmsr

	/* CR0.PG(bit31)=1 开分页；CR0.PE(bit0)=1 保护模式保持开启。 */
	mov %cr0, %eax
	or $0x80000001, %eax
	mov %eax, %cr0

	/* 加载最小 GDT，并远跳转到 64 位代码段选择子 0x08。 */
	lgdt gdt64_descriptor
	ljmp $0x08, $long_mode_entry

halt_after_switch:
	hlt
	jmp halt_after_switch

.align 8
gdt64:
	/* 空描述符。 */
	.quad 0x0000000000000000
	/* 64 位代码段描述符。 */
	.quad 0x00AF9A000000FFFF
	/* 数据段描述符。 */
	.quad 0x00AF92000000FFFF
gdt64_end:

gdt64_descriptor:
	/* GDTR: limit + base（此处 base 以 32 位低位提供即可满足当前布局）。 */
	.word gdt64_end - gdt64 - 1
	.long gdt64
	.long 0

.code64
long_mode_entry:
	/* 设置数据段寄存器，建立基础执行上下文。 */
	mov $0x10, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %ss

	/* 清空帧指针，设置 64 位栈指针后进入 C 入口。 */
	xor %rbp, %rbp
	mov $stack_top, %rsp
	call kmain

halt64:
	/* kmain 标记为 noreturn，若返回则停机。 */
	hlt
	jmp halt64

.section .note.GNU-stack,"",@progbits
