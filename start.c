#include "uart.h"
#include "arm_asm.h"

struct cpu_t vcpu;
unsigned int reason;
unsigned int ret_addr;

void do_hvc_handler()
{
	cprintf("Exception class (0x%x): 0x%x - 0x%x, 0x%x\n", reason>>26, reason, ret_addr, vcpu.lr);
	while(1);
}

void hypervisor_main()
{
	cprintf("Hello World!\n");
	copy_guest();
	guest_start(0, 2272, 0x80000100);

	//while(1);
}
