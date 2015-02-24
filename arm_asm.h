#ifndef __ARM_ASM_H__
#define __ARM_ASM_H__

typedef unsigned long u32;
typedef unsigned short u16;
typedef unsigned char u8;

#define Mode_USR 0x10
#define Mode_FIQ 0x11
#define Mode_IRQ 0x12
#define Mode_SVC 0x13
#define Mode_ABT 0x17
#define Mode_SYS 0x1F
#define Mode_SVP 0x13
#define Mode_UNDEF 0x1B
#define Mode_HYP 0x1A
#define Mode_MON 0x16

#define REASON_UNKNOWN  0x00
#define REASON_MCR_CP15 0x03
#define REASON_SVC      0x11
#define REASON_HVC      0x12
#define REASON_SMC      0x13

struct cpu_t
{
	//general registers
	u32 r0;
	u32 r1;
	u32 r2;
	u32 r3;
	u32 r4;
	u32 r5;
	u32 r6;
	u32 r7;
	u32 r8;
	u32 r9;
	u32 r10;
	u32 r11;
	u32 r12;
	u32 lr;
};

#endif
