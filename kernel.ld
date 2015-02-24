/*
 * model.lds.S - simple linker script for stand-alone Linux booting
 *
 * Copyright (C) 2011 ARM Limited. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE.txt file.
 */

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
TARGET(binary)

ENTRY_SVC_STACK_SIZE = 0x1000;

SECTIONS
{
	. = 0xC0000000;
 .text : { *(.text) }
 .os_image : { *(.os_image)}
 . = ALIGN(8);       /* the stack must be 64-bit aligned */
 .stack      : { *(.stack) }
 .data : { *(.data) }
 .bss : { *(.bss) }

 /*define a stack for the entry*/
	. = ALIGN(0x1000);
	. += ENTRY_SVC_STACK_SIZE;
	stacktop = .;
}
