#ifndef __UART_H__
#define __UART_H__

void uart_send(unsigned int c);
void printstr(char *s);
void printint(int xx, int base, int sign);
void cprintf(char *fmt, ...);

#endif
