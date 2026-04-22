#include <stdint.h>

/* COM1 基址，传统 PC 串口地址。 */
#define COM1_PORT 0x3F8

/* 向 I/O 端口写 1 字节。 */
static inline void outb(uint16_t port, uint8_t value)
{
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

/* 从 I/O 端口读 1 字节。 */
static inline uint8_t inb(uint16_t port)
{
    uint8_t value;
    __asm__ volatile ("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

void serial_init(void)
{
    /*
     * 下面是 16550 UART 的常见初始化流程：
     * 1) 先禁用中断
     * 2) 打开 DLAB，以设置波特率分频
     * 3) 设置分频为 3（115200 / 3 = 38400）
     * 4) 8N1 数据格式
     * 5) 启用 FIFO
     * 6) 打开 DTR/RTS/OUT2
     */
    outb(COM1_PORT + 1, 0x00);
    outb(COM1_PORT + 3, 0x80);
    outb(COM1_PORT + 0, 0x03);
    outb(COM1_PORT + 1, 0x00);
    outb(COM1_PORT + 3, 0x03);
    outb(COM1_PORT + 2, 0xC7);
    outb(COM1_PORT + 4, 0x0B);
}

static int serial_transmit_empty(void)
{
    /* LSR(bit5)=1 表示发送保持寄存器可写。 */
    return (inb(COM1_PORT + 5) & 0x20) != 0;
}

void serial_write(const char* str)
{
    for (uint64_t i = 0; str[i] != '\0'; ++i) {
        /* 轮询等待硬件可发送。这个实现简单但会阻塞 CPU。 */
        while (!serial_transmit_empty()) {
        }
        outb(COM1_PORT, (uint8_t)str[i]);
    }
}