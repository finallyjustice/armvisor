	
	.syntax	unified

.equ Mode_USR, 0x10
.equ Mode_FIQ, 0x11
.equ Mode_IRQ, 0x12
.equ Mode_SVC, 0x13
.equ Mode_ABT, 0x17
.equ Mode_SYS, 0x1f
.equ Mode_SVP, 0x13
.equ Mode_UNDEF, 0x1B
.equ Mode_HYP, 0x1A
.equ Mode_MON, 0x16

	.text

	.globl	start
start:
	@
	@ Program architected timer frequency
	@
	mrc	p15, 0, r0, c0, c1, 1		@ CPUID_EXT_PFR1
	lsr	r0, r0, #16
	and	r0, r0, #1			@ Check generic timer support
	beq	1f
	ldr	r0, =24000000			@ 24MHz timer frequency
	mcr	p15, 0, r0, c14, c0, 0		@ CNTFRQ
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

	@ Set all interrupts to be non-secure
	ldr r0, =0x2c001000	@ Dist GIC base
	ldr r1, [r0, #0x04] @ Type Register
	cmp	r4, #0
	andeq r1, r1, #0x1f
	movne r1, #0
	add	r2, r0, #0x080 @ Security Register 0
	mvn r3, #0
	2: str	r3, [r2]
	sub	r1, r1, #1
	add	r2, r2, #4 @ Next security register
	cmp	r1, #-1
	bne 2b

	@ Set GIC priority mask bit [7] = 1
	ldr r0, =0x2c002000	@ CPU GIC base
	mov	r1, #0x80
	str	r1, [r0, #0x4] @ GIC ICCPMR

	@ Set NSACR to allow coprocessor access from non-secure
	mrc p15, 0, r0, c1, c1, 2
	ldr r1, =0x43fff
	orr r0, r0, r1
	mcr p15, 0, r0, c1, c1, 2

	@ Now we've got rid of the secondary CPUs, set up a stack
	@ for CPU 0 so we can write most of this in C.
	ldr     sp, =stacktop
	
	# change stack for monitor mode
	cps #Mode_MON
	ldr sp, =monitor_stack_top

	// Allow non-secure access to FPU/NEON and ACTLR.SMP (Non-Secure Access Control Register (NSACR))
	mrc p15, 0, r0, c1, c1, 2
	orr r0, r0, #(1 << 10)  //CP10 access
	orr r0, r0, #(1 << 11)  //CP11
	orr r0, r0, #(1 << 18)  //ACTLR.SMP access
	mcr p15, 0, r0, c1, c1, 2   //Write

	//Go to non-secure world (Secure Configuration Register (SCR))	
	mrc p15, 0, r1, c1, c1, 0 
	orr r1, r1, #(1 << 0)       //Set SCR.NS
	bic r1, r1, #(1 << 7)       //Clear SCR.SCD
	orr r1, r1, #(1 << 8)       //Set SCR.HCE (HVC in Non-Secure kernel modes causes move to Hyp mode)
	mcr p15, 0, r1, c1, c1, 0   //Write

	//Set up HVBAR
	LDR     r0, =hypervisor_vector
	MCR     p15, 4, r0, c12, c0, 0  //Write HVBAR

	//go to hypervisor mode
	ldr     lr, =hypervisor_vector
	msr     spsr_cxsf, #Mode_HYP        //prepare going to the Hypervisor mode
	movs pc, lr                         //go to the Hypervisor Mode

	b .

.global raise
raise:
	mov pc, lr

.section ".stack"
monitor_stack_bottom:
	.rept 0x100
	.long 0x00
	.endr
monitor_stack_top:
