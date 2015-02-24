	.syntax	unified
	.arch_extension sec
	.arch_extension virt

	.text

	.globl	start
start:
	b reset	
	ldr pc, UndefAddr
	ldr pc, SWIAddr
	ldr pc, PAbortAddr
	ldr pc, DAbortAddr
	ldr pc, ReservedAddr
	ldr pc, IRQAddr
	ldr pc, FIQAddr
	
	UndefAddr:      .word UndefHandler
	SWIAddr:        .word SWIHandler
	PAbortAddr:     .word PAbortHandler
	DAbortAddr:     .word DAbortHandler
	ReservedAddr:   .word 0
	IRQAddr:        .word IRQHandler
	FIQAddr:        .word FIQHandler

reset:
	/*@
	@ Program architected timer frequency
	@
	mrc	p15, 0, r0, c0, c1, 1		@ CPUID_EXT_PFR1
	lsr	r0, r0, #16
	and	r0, r0, #1			@ Check generic timer support
	beq	1f
	ldr	r0, =24000000			@ 24MHz timer frequency
	mcr	p15, 0, r0, c14, c0, 0		@ CNTFRQ*/
1:
	@
	@ CPU initialisation
	@
	mrc	p15, 0, r4, c0, c0, 5		@ MPIDR (ARMv7 only)
	and	r4, r4, #15			@ CPU number

2:
	@
	@ UART initialisation (38400 8N1)
	@
	ldr	r0, =0x1c090000			@ UART base (Versatile Express)
	mov	r1, #0x10			@ ibrd
	str	r1, [r0, #0x24]
	mov	r1, #0xc300
	orr	r1, #0x0001			@ cr
	str	r1, [r0, #0x30]

	@ Now we've got rid of the secondary CPUs, set up a stack
	@ for CPU 0 so we can write most of this in C.
	ldr     sp, =stacktop

	@Write Secure World Vector Base Address
	@ ---------------------------------------
	LDR r0, =start
	MCR p15, 0, r0, c12, c0, 0

hvc #0
hvc #0
hvc #0
#smc #0
#CPS #0x10
#swi #0
	@ And call the C entrypoint
	bl      c_start
	@ Never reached
1:	b 1b

	@
	@ Function for C code to make semihosting calls:
	@
#.globl __semi_call
#__semi_call:
#	svc     0x123456
#	mov pc, lr

@------------------------------------------------------------
@ Vector handler
@ -----------------------------------------------------------
UndefHandler:
	b UndefHandler

SWIHandler:
	push {lr}
	bl swi_handler
	pop {lr}
	mov pc, lr

PAbortHandler:
	b PAbortHandler

DAbortHandler:
	b DAbortHandler

IRQHandler:
	b IRQHandler

FIQHandler:
	b FIQHandler

.global raise
raise:
	mov pc, lr	
