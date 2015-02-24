.arch_extension sec
.arch_extension virt

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
  

.align 5

.globl hypervisor_vector
hypervisor_vector:
	b hyp_reset_handler
	b .
	b .
	b .
	b .
	b hyp_handler
	b .
	b .

hyp_reset_handler:
	ldr r0, =0x1c090000 @ UART base (Versatile Express)
	mov r1, #'O'        
	str r1, [r0, #0x00] @ Tx Test

	// Set hypervisor mode stack pointer
	ldr sp,=hyp_stack_top

	// Configure Kernel mode SMCs to enter Hypervisor via the Hyp Configuration Register (HCR)
	mrc p15, 4, r0, c1, c1, 0 
	orr r0, r0, #(1 << 19)  //set hcr.tsc (bit 19)
	mcr p15, 4, r0, c1, c1, 0   //write hcr

	//Set up MMU for the hypervisor
	//Hypervisor Memory Attribute Indirection Register 0 (HMAIR0)
	// 0 - 01000100
	// 1 - 11111111
	// 3 - 00000100
	ldr     r0, =0x0004ff44
	mcr     p15, 4, r0, c10, c2, 0     //Write HMAIR0

	mov     r0, #0x80000000            //Use LPAE format, covers entire address space
	mcr     p15, 4, r0, c2, c0, 2      //Write HTCR

	ldr     r1, =0x0
	ldr     r0, =hypervisor_page_table
	mcrr    p15, 4, r0, r1, c2          //rite HTTBR

	//Turn MMU on for the Hypervisor
	mrc     p15, 4, r0, c1, c0, 0
	orr     r0, r0, #1                 //Set HSCTLR.M (bit 0), enables the MMU for Hyp mode
	mcr     p15, 4, r0, c1, c0, 0      //Write HSCTLR

	LDR     r1, =0x0                    // ; Set high word of physical address
	LDR     r0, =stage2_page_table     // ; Set low word of physical address
	MCRR    p15, 6, r0, r1, c2          // ; Write VTTBR

	LDR     r0, =0x80000040             // ; Use LPAE format, start at level 1, entire address space
	MCR     p15, 4, r0, c2, c1, 2      //  ; Write VTCR
	
	MRC     p15, 4, r0, c1, c1, 0     //   ; Read HCR
	ORR     r0, r0, #(1 << 19)        //   ; Set the HCR.TSC (bit 19) to enable SMC trapping
	ORR     r0, r0, #1                //   ; Set the HCR.VM (bit 0) to enable stage 2 translation
#ORR     r0, r0, #(1 << 27)        //   ; Set the HCR.TGE (bit 27) to enable SVC trapping
	MCR     p15, 4, r0, c1, c1, 0     //   ; Write HCR

	ldr r0, =0x1c090000 @ UART base (Versatile Express)
	mov r1, #'K'        
	str r1, [r0, #0x00] @ Tx Test
	mov r1, #'\n'       
	str r1, [r0, #0x00] @ Tx Test
	mov r1, #'\r'       
	str r1, [r0, #0x00] @ Tx Test
	
	b hypervisor_main

.globl copy_guest
copy_guest:
	LDR     r0, =0x80008000   // destination
	LDR     r1, =os_image                       // Beginning of source data
	LDR     r2, =os_image_end                         //End of source data
hyp_copy_guest_loop:
	ldmia   r1!, {r3-r6}
	stmia   r0!, {r3-r6}
	cmp     r1, r2
	blt     hyp_copy_guest_loop
	mov pc, lr
	
//void guest_start()
.globl guest_start
guest_start:
	ldr r11, =0x80008000
	msr     elr_hyp, r11
	msr spsr_cxsf, #Mode_SVC
	eret

.globl hyp_handler
hyp_handler:
	push {r12}  //r12 : general purpose register
	ldr r12, =vcpu
	stmia r12!, {r0-r11}
	pop {r0}
	stmia r12!, {r0, lr}

	bl do_hvc_handler
	ldr r12, =vcpu
	ldmia r12!, {r0-r11}
	push {r0}
	mov r0, r12
	ldmia r0!, {r12, lr}
	pop {r0}
	eret
	b .	

.section ".stack"
hyp_stack_bottom:
	.rept 0x100
	.long 0x00
	.endr
hyp_stack_top:
