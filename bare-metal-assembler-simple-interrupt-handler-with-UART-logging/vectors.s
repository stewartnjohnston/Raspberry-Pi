 .section ".text.boot"
 
.globl _start
_start:

.equ zerob, 0x100
.equ oneb,  0x200
.equ twob,  0x300
.equ threeb,  0x400
.equ elvalue,  0x16
.equ PBASE,  0x3F000000
.equ ENABLE_IRQS_1,  0x0000B210
.equ ENABLE_BASIC_IRQS,  0x0000B218
.equ SYSTEM_TIMER_IRQ_1, 0x00000002
.equ ARM_TIMER_IRQ, 0x00000001
.equ STACK_SIZE, 0x2000


    ldr w0, buff_scratch
    mov x1,#0x10000
    str w0, [x1]
    mrs x2,CurrentEL
    and x2,x2,#12
    mrs x0,mpidr_el1
    mov x1,#0xFF000000
    mov x3,#0x000000FF
    bic x0,x0,x1
    cbz x0,zero
    sub x1,x0,#1
    cbz x1,one
    sub x1,x0,#2
    cbz x1,two
    sub x1,x0,#3
    cbz x1,three

// The below code never gets called.
// We catch all the cores in the above code
    mrs x0,mpidr_el1
    and x0,x0,x3
    ldr w1, buff_scratch
    add x1,x1,#0x40
    str w0,[x1]
    add x1,x1,#4
    str w2,[x1]
    add x1,x1,#4
    mov w2,#0xFF
    str w2,[x1]

    b hang

zero:
    mrs x0,mpidr_el1
    and x0,x0,x3
    ldr w1, buff_scratch
    str w0,[x1]
    add x1,x1,#4
    str w2,[x1]
    add x1,x1,#4
    mov w2,#0xF0
    str w2,[x1]
    mrs x2,CurrentEL
    
    // change from EL3 to EL0
    // But first we must go from EL3 to EL2
    // then from EL2 to EL1
    // then from EL1 to EL0 
    // (can't go directly to EL0!!!)
    
    // Initialize SCTLR_EL2 and HCR_EL2 to save values before entering EL2.
                             // SCTLR_EL2, System Control Register (EL2)
    MSR   SCTLR_EL2, XZR     // Disable MMU at EL2
                             // HCR_EL2, Hypervisor Configuration Register
    MSR   HCR_EL2, XZR       // Not sure if this is good!!!

    // Determine the EL2 Execution state.
    MOV   X0, XZR
    ORR   X0, X0, #(1 << 10) // .RW = 0b1  -->  EL2 is AArch64
    ORR   X0, X0, #(1 << 0)  // .NS = 0b1  -->  Non-secure state
                             // M[4:0]=01001
                             // SCR_EL3, Secure Configuration Register
    MSR   SCR_EL3, X0

    MOV   X0, XZR
    ORR   X0, X0,   #(7 << 6) // DAIF=0111 - will disable AIF of DAIF
                              // masking means disabling
    //ORR   X0, X0, #(0 << 4) // .M[4] = 0b0  -->  Return to AArch64 state
    ORR   X0, X0, #(1 << 3)   // .M[3:1] = 0b100  -->  Return to EL2
    ORR   X0, X0, #(1 << 0)   // .M[0] = 0b1  -->  Use EL2's dedicated stack pointer
                              // SPSR_EL3, Saved Program Status Register (EL3)
    MSR   SPSR_EL3, X0
 /*  
    ldr x0, adr_stack_el0
    mov x1, #STACK_SIZE
    add x0, x0, x1
//    msr	sp_el0, x0
    
    ldr x0, adr_stack_el1
    mov x1, #STACK_SIZE
    add x0, x0, x1
//    msr	sp_el1, x0
    
//    ldr x0, adr_stack_el2
    mov x1, #STACK_SIZE
    add x0, x0, x1
//    msr	sp_el2, x0
  */
    ADRP  X0, chargeToEL2             // Program EL2 entrypoint
    ADD   X0, X0, :lo12:chargeToEL2
    MSR   ELR_EL3, X0

    ERET                             // Perform exception return to EL2
  
chargeToEL2: 
     
    mrs x2,CurrentEL

    ldr w1, buff_scratch
    add x1,x1,#0x50
    str w2,[x1]

    // Initialize the SCTLR_EL1 register before entering EL1.
    MSR   SCTLR_EL1, XZR

    // Determine the EL1 Execution state.
    MRS   X0, HCR_EL2 
    ORR   X0, X0, #(1<<31) // RW=1 EL1 Execution state is AArch64.
    MSR   HCR_EL2, X0 

    MOV   X0, #0b00101     // DAIF=0000
    ORR   X0, X0,   #(7 << 6) // DAIF=0111 - will disable AIF of DAIF
    MSR   SPSR_EL2, X0     // M[4:0]=00101 EL1h must match HCR_EL2.RW.
    ADR   X0, chargeToEL1  // el entry points to the first instruction of
    MSR   ELR_EL2, X0      // EL1 code.
    
    ERET

chargeToEL1:

    mrs x2,CurrentEL

    ldr w1, buff_scratch
    add x1,x1,#0x50
    add x1,x1,#4
    str w2,[x1]


    // Determine the EL0 Execution state.
    MOV   X0, #0b00000 // DAIF=0000 M[4:0]=00000 EL0t.
    ORR   X0, X0,   #(7 << 6) // DAIF=0111 - will disable AIF of DAIF
    MSR   SPSR_EL1, X0 
    
    ADR   x0, chargeToEL0 // el entry points to the first instruction of
    MSR   ELR_EL1, X0     // EL0 code.
    
    /*  enable interrupts from irq_vector_init */
    adr	x0, vectors  // load VBAR_EL1 with virtual
    msr	vbar_el1, x0 // vector table address
    
    bl enable_interrupt_controller
    
    bl enable_irq
    
    ERET
    
    
chargeToEL0:

    //mrs x2,CurrentEL  // Looks like EL0 does not have access to CurrentEL. 
                        // Then called in EL0 it throws an exception.
    mov sp,#0x8000
    bl notmain
hang:
    wfe
    b hang

1:  wfe
    b       1b


one:
    mrs x0,mpidr_el1
    and x0,x0,x3
    ldr w1, buff_scratch
    add x1,x1,#0x10
    str x0,[x1]
    add x1,x1,#4
    str w2,[x1]
    add x1,x1,#4
    mov w2,#0xF1
    str w2,[x1]
    b hang

two:
    mrs x0,mpidr_el1
    and x0,x0,x3
    ldr w1, buff_scratch
    add x1,x1,#0x20
    str x0,[x1]
    add x1,x1,#4
    str w2,[x1]
    add x1,x1,#4
    mov w2,#0xF2
    str w2,[x1]
    b hang

three:
    mrs x0,mpidr_el1
    and x0,x0,x3
    ldr w1, buff_scratch
    add x1,x1,#0x30
    str w0,[x1]
    add x1,x1,#4
    str w2,[x1]
    add x1,x1,#4
    mov w2,#0xF3
    str w2,[x1]
    b hang


.globl PUT32
PUT32:
  str w1,[x0]
  ret

.globl GET32
GET32:
    mov x1,x0
    ldr w0,[x0]
    ret

.globl GET64
GET64:
    mov x1,x0
    ldr x0,[x0]
    ret

.globl GETPC
GETPC:
    mov x0,x30
    ret
    
.globl GETCurrentEL
GETCurrentEL:
    mrs x0,CurrentEL
    ret
/*
void enable_interrupt_controller() {
    PUT32(ENABLE_IRQS_1, SYSTEM_TIMER_IRQ_1);
    PUT32(ENABLE_BASIC_IRQS, ARM_TIMER_IRQ);
}
*/

/*from irq.s */
.globl irq_vector_init
irq_vector_init:
        // Vector Base Address Register, EL1
        // Purpose:
        //     Holds the exception base address for any exception that is taken to EL1.
	adr	x0, vectors  // load VBAR_EL1 with virtual
	msr	vbar_el1, x0 // vector table address
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
/* end of irq.s */

/*  from entry.s */

 .macro handle_invalid_entry type
 kernel_entry
 mov x0, #\type
 mrs x1, esr_el1
 mrs x2, elr_el1
 bl show_invalid_entry_message
 b err_hang
 .endm

 .macro ventry label
 .align 7
 b \label
 .endm

 .macro kernel_entry
 sub sp, sp, #256
 stp x0, x1, [sp, #16 * 0]
 stp x2, x3, [sp, #16 * 1]
 stp x4, x5, [sp, #16 * 2]
 stp x6, x7, [sp, #16 * 3]
 stp x8, x9, [sp, #16 * 4]
 stp x10, x11, [sp, #16 * 5]
 stp x12, x13, [sp, #16 * 6]
 stp x14, x15, [sp, #16 * 7]
 stp x16, x17, [sp, #16 * 8]
 stp x18, x19, [sp, #16 * 9]
 stp x20, x21, [sp, #16 * 10]
 stp x22, x23, [sp, #16 * 11]
 stp x24, x25, [sp, #16 * 12]
 stp x26, x27, [sp, #16 * 13]
 stp x28, x29, [sp, #16 * 14]
 str x30, [sp, #16 * 15]
 .endm

 .macro kernel_exit
 ldp x0, x1, [sp, #16 * 0]
 ldp x2, x3, [sp, #16 * 1]
 ldp x4, x5, [sp, #16 * 2]
 ldp x6, x7, [sp, #16 * 3]
 ldp x8, x9, [sp, #16 * 4]
 ldp x10, x11, [sp, #16 * 5]
 ldp x12, x13, [sp, #16 * 6]
 ldp x14, x15, [sp, #16 * 7]
 ldp x16, x17, [sp, #16 * 8]
 ldp x18, x19, [sp, #16 * 9]
 ldp x20, x21, [sp, #16 * 10]
 ldp x22, x23, [sp, #16 * 11]
 ldp x24, x25, [sp, #16 * 12]
 ldp x26, x27, [sp, #16 * 13]
 ldp x28, x29, [sp, #16 * 14]
 ldr x30, [sp, #16 * 15]
 add sp, sp, #256
 eret
 .endm





.align 11
.globl vectors
vectors:
 ventry sync_invalid_el1t
 ventry irq_invalid_el1t
 ventry fiq_invalid_el1t
 ventry error_invalid_el1t

 ventry sync_invalid_el1h
 ventry el1_irq
 ventry fiq_invalid_el1h
 ventry error_invalid_el1h

 ventry sync_invalid_el0_64
 ventry irq_invalid_el0_64
 ventry fiq_invalid_el0_64
 ventry error_invalid_el0_64

 ventry sync_invalid_el0_32
 ventry irq_invalid_el0_32
 ventry fiq_invalid_el0_32
 ventry error_invalid_el0_32

sync_invalid_el1t:
 handle_invalid_entry 0

irq_invalid_el1t:
 handle_invalid_entry 1

fiq_invalid_el1t:
 handle_invalid_entry 2

error_invalid_el1t:
 handle_invalid_entry 3

sync_invalid_el1h:
 handle_invalid_entry 4

fiq_invalid_el1h:
 handle_invalid_entry 6

error_invalid_el1h:
 handle_invalid_entry 7

sync_invalid_el0_64:
 handle_invalid_entry 8

irq_invalid_el0_64:
 handle_invalid_entry 9

fiq_invalid_el0_64:
 handle_invalid_entry 10

error_invalid_el0_64:
 handle_invalid_entry 11

sync_invalid_el0_32:
 handle_invalid_entry 12

irq_invalid_el0_32:
 handle_invalid_entry 13

fiq_invalid_el0_32:
 handle_invalid_entry 14

error_invalid_el0_32:
 handle_invalid_entry 15

el1_irq:
 kernel_entry
 bl handle_irq
 kernel_exit

.globl err_hang
err_hang: b err_hang

/* end of entry.s */
.globl enable_interrupt_controller
enable_interrupt_controller:
    mov x1,#ENABLE_IRQS_1
    mov x0,#SYSTEM_TIMER_IRQ_1
    str w0, [x1]
    ret  // return to address in link registry (x30)

    

.globl dummy
dummy:
    ret

.data 
.align 8
         /* the .data section is dynamically created and its addresses cannot be easily predicted */
var1: .skip 1024  /* variable 1 in memory */
stack_el0: .skip STACK_SIZE  /* variable 1 in memory */
stack_el1: .skip STACK_SIZE  /* variable 1 in memory */
stack_el2: .skip STACK_SIZE  /* variable 1 in memory */
stack_el3: .skip STACK_SIZE  /* variable 1 in memory */

.align 8

.globl buff_scratch
buff_scratch: .word var1  /* address to var1 stored here */
adr_stack_el0: .word stack_el0  /* address to stack_el0 stored here */
adr_stack_el1: .word stack_el1  /* address to stack_el1 stored here */
adr_stack_el2: .word stack_el2  /* address to stack_el2 stored here */
adr_stack_el3: .word stack_el3  /* address to stack_el3 stored here */


