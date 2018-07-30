#include "arm/sysregs.h"

#include "mm.h"

.section ".text.boot"

.globl _start
_start:

        //  Read the mpidr_el1 - Multiprocessor Affinity Register
        //  I do not understand the below logic
        //  Processor affinity - run the same process on the same core
        //                     - below we want to only run the master core 
        //                       and have all other cores hang.
	mrs	x0, mpidr_el1
	and	x0, x0, #0xFF // Check processor id (is it infinity level 0)
	cbz	x0, master    // Hang for all non-primary CPU (branch if x0 is zero)
	b	proc_hang

proc_hang: 
	b 	proc_hang

master:
        // EL1  Exception Level 1
        // sctlr_el1 - System Control Register, EL1
        // Provides top level control of the system, including its memory system at EL1.
        // Configurations: SCTLR_EL1 is architecturally mapped to AArch32 register SCTLR(NS)
        // SCTLR_EL1 is a 32-bit register.
        // The below calls will disable the MMU (Memory Management Unit)
	ldr	x0, =SCTLR_VALUE_MMU_DISABLED
	msr	sctlr_el1, x0		

	// Hypervisor Configuration Register
	// Purpose:
        //     Provides configuration control for virtualization, including whether
        //     various Non-secure operations are trapped to EL2.
        //     HCR_EL2 is part of the Hypervisor and virtualization registers functional
        //     group.
        // The below functions will: set lower exception levels to AArch64 not AArch32
	ldr	x0, =HCR_VALUE
	msr	hcr_el2, x0

	//  Secure Configuration Register
	//  Purpose
        //     Defines the configuration of the security state. SCR_EL3 specifies:
        //     - Security state of EL0 and EL1, either Secure or Non-secure.
        //     - Register width at lower exception levels.
        //     - The exception level that the processor takes exceptions at, if an IRQ,
        //       FIQ, or external abort occurs.
        //     SCR_EL3 is part of the Security registers functional group.
        // The below function will:
        //         - set Register width control for lower exception levels AARCH64
        //         - EL0 and EL1 are in Non-secure state, memory accesses
        //           from those exception levels cannot access Secure memory.
	ldr	x0, =SCR_VALUE
	msr	scr_el3, x0

	//  Saved Program Status Register (EL3)
	//  Purpose:
	//      - Holds the saved process state when an exception is taken to EL3.
	//  The below function will:
	//      - bit 0 = 1 - means the exception SP is determined by the EL
	//                  - in our case the exception handler will have
	//                    its own stack pointer and space
	//      - bit 2 = 1 - this will hold the exception level
	//      - bits 7,8,9 - mask the - FIQ, IRQ and SError
	ldr	x0, =SPSR_VALUE
	msr	spsr_el3, x0

	//  ELR_EL3, Exception Link Register (EL3)
	//  Purpose:
	//     When taking an exception to EL3, holds the address to return to.
	// 
	adr	x0, el1_entry		
	msr	elr_el3, x0

	eret				

el1_entry:
	adr	x0, bss_begin
	adr	x1, bss_end
	sub	x1, x1, x0
	bl 	memzero

	mov	sp, #LOW_MEMORY
	bl	kernel_main
	b 	proc_hang // should never come here
