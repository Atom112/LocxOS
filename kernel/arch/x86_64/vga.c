#include <stddef.h>
#include <stdint.h>

/* VGA 文本模式固定为 80x25，每个字符占 2 字节（字符 + 颜色属性）。 */
enum {
	VGA_WIDTH = 80,
	VGA_HEIGHT = 25,
	VGA_COLOR_LIGHT_GREY = 0x07,
	VGA_COLOR_BLACK = 0x00
};

/* 0xB8000 是传统 PC 文本模式显存地址。 */
static volatile uint16_t* const vga_buffer = (uint16_t*)0xB8000;
/* 维护一个简单光标位置，用于顺序写字符串。 */
static size_t vga_row = 0;
static size_t vga_col = 0;
static uint8_t vga_color = (VGA_COLOR_BLACK << 4) | VGA_COLOR_LIGHT_GREY;

/* 把字符和颜色打包成 VGA 单元格式。 */
static uint16_t vga_entry(unsigned char c, uint8_t color)
{
	return ((uint16_t)color << 8) | (uint16_t)c;
}

void vga_clear(void)
{
	/* 逐格写空格，实现最朴素可靠的清屏。 */
	for (size_t y = 0; y < VGA_HEIGHT; ++y) {
		for (size_t x = 0; x < VGA_WIDTH; ++x) {
			vga_buffer[y * VGA_WIDTH + x] = vga_entry(' ', vga_color);
		}
	}

	/* 清屏后把逻辑光标复位到左上角。 */
	vga_row = 0;
	vga_col = 0;
}

void vga_write(const char* str)
{
	for (size_t i = 0; str[i] != '\0'; ++i) {
		const char c = str[i];

		if (c == '\n') {
			/* 换行：列归零，行加一。 */
			vga_col = 0;
			vga_row = (vga_row + 1) % VGA_HEIGHT;
			continue;
		}

		vga_buffer[vga_row * VGA_WIDTH + vga_col] = vga_entry((unsigned char)c, vga_color);
		++vga_col;

		if (vga_col >= VGA_WIDTH) {
			/* 到达行尾后自动换行。 */
			vga_col = 0;
			vga_row = (vga_row + 1) % VGA_HEIGHT;
		}
	}
}
