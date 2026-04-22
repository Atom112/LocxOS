/*
 * 最小内核入口（C 语言）。
 * 这里不使用标准库，所有输出都通过我们自己实现的驱动函数完成。
 */
void vga_clear(void);
void vga_write(const char* str);
void serial_init(void);
void serial_write(const char* str);

__attribute__((noreturn))
void kmain(void)
{
	/*
	 * 先初始化串口：即使图形输出异常，串口仍可作为早期调试通道。
	 */
	serial_init();
	serial_write("[serial] LocxOS booting...\r\n");

	/* VGA 文本模式输出，确认内核已经进入可见执行状态。 */
	vga_clear();
	vga_write("LocxOS boot ok");
	serial_write("[serial] VGA message rendered\r\n");

	/*
	 * 当前阶段没有调度器和中断服务流程，因此让 CPU 进入 hlt 循环。
	 * hlt 会降低空转开销，并且在有中断时可被唤醒。
	 */
	for (;;) {
		__asm__ volatile ("hlt");
	}
}
