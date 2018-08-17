//#include "arm/sysregs.h"

//#include "mm.h"

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
        wfe
	b 	proc_hang

master:
        // EL1  Exception Level 1
        // sctlr_el1 - System Control Register, EL1
        // Provides top level control of the system, including its memory system at EL1.
        // Configurations: SCTLR_EL1 is architecturally mapped to AArch32 register SCTLR(NS)
        // SCTLR_EL1 is a 32-bit register.
        // The below calls will disable the MMU (Memory Management Unit)
        .equ SCTLR_VALUE_MMU_DISABLED,  0x30D00800 // B110000110100000000100000000000
	ldr	x0, =SCTLR_VALUE_MMU_DISABLED
	msr	sctlr_el1, x0		

	// Hypervisor Configuration Register
	// Purpose:
        //     Provides configuration control for virtualization, including whether
        //     various Non-secure operations are trapped to EL2.
        //     HCR_EL2 is part of the Hypervisor and virtualization registers functional
        //     group.
        // The below functions will: set lower exception levels to AArch64 not AArch32
        .equ HCR_VALUE,  0x80000000 // B10000000000000000000000000000000
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
        .equ SCR_VALUE,  0x431 // B10000110001
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
	.equ SPSR_VALUE,  0x1C5 // B111000101
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

	.equ LOW_MEMORY,  0x400000 // Not sure how this value was calculated
	mov	sp, #LOW_MEMORY  // 0x400000
	
        //bl irq_vector_initx
	//bl timer_initx
	//bl enable_interrupt_controllerx
	//bl enable_irqx
	
	bl	kernel_main
	b 	proc_hang // should never come here

.equ PBASE,  0x3F000000
.equ TIMER_CLO,  0x00003004
.equ TIMER_C1,   0x00003010

.equ ENABLE_IRQS_1,  0x0000B210
.equ ENABLE_BASIC_IRQS,  0x0000B218
.equ SYSTEM_TIMER_IRQ_1, 0x00000002
.equ ARM_TIMER_IRQ, 0x00000002
 
// void enable_interrupt_controller()
//{
//	put32(ENABLE_IRQS_1, SYSTEM_TIMER_IRQ_1);
//}

.globl enable_interrupt_controllerx
enable_interrupt_controllerx:
    mov x0,#PBASE
    mov x1,#ENABLE_IRQS_1 //0x0000B210
    add x1, x0, x1
    mov x2, #ARM_TIMER_IRQ  //0x01 = set to enable ARM timer IRQ
    str x2, [x1]
    
    ret  // return to address in link registry (x30)
    
.globl timer_initx
timer_initx:
        mov w0,#PBASE
        mov w1,#TIMER_CLO //0x3F00B218=Basic Interrupt enable Register
        add x1, x0, x1
	ldr w2,[x1]
	
//	add w2, w2, #0x30D40
	add w2, w2, #0x200000

        mov w0,#PBASE
        mov w1,#TIMER_C1 //0x3F00B218=Basic Interrupt enable Register
        add x1, x0, x1
	str w2,[x1]
	mov x0, x2
	ret

.globl irq_vector_init
irq_vector_init:
	adr	x0, vectors		// load VBAR_EL1 with virtual
	msr	vbar_el1, x0		// vector table address
	ret

.globl enable_irq
enable_irq:
        // set DAIF, Interrupt Mask Bits
        // Purpose:
        //     Allows access to the interrupt mask bits.
	msr    daifclr, #2 // enable the IRQ
	ret

.globl disable_irq
disable_irq:
        // see above
	msr	daifset, #2
	ret	
	
.globl memzero
memzero:
	str xzr, [x0], #8
	subs x1, x1, #8
	b.gt memzero
	ret
