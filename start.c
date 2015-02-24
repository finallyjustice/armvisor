#include "uart.h"
#include "arm_asm.h"

struct cpu_t vcpu;
unsigned int reason;
unsigned int ret_addr;

void do_hvc_handler()
{
	//cprintf("Exception class (0x%x): 0x%x - 0x%x\n", reason>>26, reason, ret_addr);
	
	switch (reason>>26)
	{
		case REASON_MCR_CP15:
			cprintf("[VMM] MCR or MRC access to CP15: 0x%x\n", ret_addr);
			while(1);
			break;

		case REASON_SVC:
			cprintf("[VMM] Supervisor Call Exception routed to hyper mode: 0x%x\n", ret_addr);
			while(1);
			break;

		case REASON_HVC:
			cprintf("[VMM] Hypervisor Call: 0x%x\n", ret_addr);
			break;

		case REASON_SMC:
			cprintf("[VMM] Trapped SMC Instruction: 0x%x\n", ret_addr);
			asm volatile(".arch_extension sec\n"
						".arch_extension virt\n"
						"mrs r1, elr_hyp\n"
						"add r1, #0x4\n"
						"msr elr_hyp, r1\n");
			break;

		case REASON_UNKNOWN:
			cprintf("[VMM] Unknown Reason: 0x%x\n", ret_addr);
			while(1);
			break;

		default:
			cprintf("[VMM] Other Reasons(0x%x): 0x%x\n", reason>>26, ret_addr);
			while(1);
	}

	//while(1);
}

void hypervisor_main()
{
	cprintf("[VMM] init armvisor\n");
	cprintf("[VMM] setup the guest image\n");
	guest_setup();
	cprintf("[VMM] start the guest VM\n");
	guest_boot();

	cprintf("You should never come here!\n");
	//while(1);
}
