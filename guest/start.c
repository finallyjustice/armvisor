
volatile unsigned char * const UART0_BASE = (unsigned char *)0x1c090000;

void uart_send(unsigned int c)
{
	*UART0_BASE = c;
	if(c == '\n')
		*UART0_BASE = '\r';
}

void printstr(char *s)
{
	int i = 0;
	while(s[i])
	{
		uart_send(s[i]);
		i++;
	}
}

void printint(int xx, int base, int sign)
{
	static char digits[] = "0123456789abcdef";
	char buf[16];
	int i;
	unsigned int x;

	if(sign && (sign = xx < 0))
		x = -xx;
	else
		x = xx;

	i = 0;
	do{
		buf[i++] = digits[x % base];
	}while((x /= base) != 0);

	if(sign)
		buf[i++] = '-';

	while(--i >= 0)
		uart_send(buf[i]);
}

void cprintf(char *fmt, ...)
{
	int i, c;
	unsigned int *argp;
	char *s;

	argp = (unsigned int*)(void*)(&fmt + 1);
	for(i = 0; (c = fmt[i] & 0xff) != 0; i++)
	{
		if(c != '%')
		{
			uart_send(c);
			continue;
		}
		c = fmt[++i] & 0xff;
		if(c == 0)
			break;
		switch(c)
		{
		case 'd':
			printint(*argp++, 10, 1);
			break;
		case 'x':
		case 'p':
			printint(*argp++, 16, 0);
			break;
		case 's':
			if((s = (char*)*argp++) == 0)
				s = "(null)";
			for(; *s; s++)
				uart_send(*s);
			break;
		case '%':
			uart_send('%');
			break;
		default:
			// Print unknown % sequence to draw attention.
			uart_send('%');
			uart_send(c);
			break;
		}
	}
}

void swi_handler()
{
	cprintf("[GUEST] Handle SWI instruction\n");
}

void c_start(void)
{
	printstr("[GUEST] Guest OS is booted\n");

	// guest call hypervisor call
	cprintf("[GUEST] Call HVC instruction\n");
	asm volatile(".arch_extension virt\n"
				"hvc #0");
	cprintf("[GUEST] Finish HVC instruction\n");

	// guest call system call
	cprintf("[GUEST] Call SWI instruction\n");
	asm volatile("swi #7");
	cprintf("[GUEST] Finish SWI instruction\n");
	
	// guest call smc call
	cprintf("[GUEST] Call SMC instruction\n");
	asm volatile(".arch_extension sec\n"
				"smc #0");
	cprintf("[GUEST] Finish SMC instruction\n");

	while(1);
}
