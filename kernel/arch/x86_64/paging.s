.section .text
.code32
.global setup_page_tables
.global p4_table
.global pdpt_table
.global pd_table

/*
 * 构建最小四级分页结构（这里只用到前三级）：
 * P4[0]    -> PDPT
 * PDPT[0]  -> PD
 * PD[0..511] 使用 2MiB 大页映射低端 1GiB（恒等映射）
 */
setup_page_tables:
	/* P4[0] = PDPT | P(bit0) | RW(bit1) */
	mov $pdpt_table, %eax
	or $0x3, %eax
	mov %eax, p4_table
	movl $0, p4_table + 4

	/* PDPT[0] = PD | P | RW */
	mov $pd_table, %eax
	or $0x3, %eax
	mov %eax, pdpt_table
	movl $0, pdpt_table + 4

	/* ecx 作为页目录索引，填满 512 项。 */
	xor %ecx, %ecx
fill_pd_entries:
	/* 每项映射基址 = index * 2MiB。 */
	mov %ecx, %eax
	shl $21, %eax
	/* 标志：P|RW|PS(大页,bit7) => 0x83 */
	or $0x83, %eax
	mov %eax, pd_table(,%ecx,8)
	/* 高 32 位清零（当前映射范围在 4GiB 以下）。 */
	movl $0, pd_table + 4(,%ecx,8)

	incl %ecx
	cmpl $512, %ecx
	jne fill_pd_entries

	ret

.section .bss
.align 4096
p4_table:
	/* 每张页表 4KiB，对齐到 4KiB 是硬件要求。 */
	.skip 4096

.align 4096
pdpt_table:
	.skip 4096

.align 4096
pd_table:
	.skip 4096

.section .note.GNU-stack,"",@progbits
