.align 14
.globl hypervisor_page_table
hypervisor_page_table:
	//0x0040000000000449
	.long 0x00000449
	.long 0x00400000

	.long 0x40000449
	.long 0x00400000
		
	.long 0x80000745
	.long 0x00000000

	.long 0xC0000745
	.long 0x00000000

.align 14
.globl stage2_page_table
stage2_page_table:
	//0x00400000000004C9
	.long 0x000004C9
	.long 0x00400000 

	.long 0x40000449
	.long 0x00400000

	.long 0x800007C5
	.long 0x00000000
