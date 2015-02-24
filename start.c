#include "uart.h"
#include "arm_asm.h"

struct cpu_t vcpu;

void do_hvc_handler()
{
	//cprintf("hvc_handler!: 0x%x\n", vcpu.lr);
	printstr("hvc_handler\n");
	printstr("hvc_handler2\n");
	//while(1);
}

void hypervisor_main()
{
	//cprintf("Hello World!\n");
	printstr("Nihao\n");
	copy_guest();
	guest_start(0, 2272, 0x80000100);

	while(1);
}
