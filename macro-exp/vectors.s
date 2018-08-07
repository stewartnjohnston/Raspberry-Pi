 
.globl _start
_start:

.equ zerob, 0x100
.equ oneb,  0x200
.equ twob,  0x300
.equ threeb,  0x400
.equ elvalue,  0x16
.equ STACK_SIZE, 0x1000

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
    
        /* Set stack pointers for each EL (exception level) */    
    ldr w0, adr_stack_el0
    mov x1, #STACK_SIZE
    add x0, x0, x1
    msr	sp_el0, x0
    
    ldr w0, adr_stack_el1
    mov x1, #STACK_SIZE
    add x0, x0, x1
    msr	sp_el1, x0
    
    ldr w0, adr_stack_el2
    mov x1, #STACK_SIZE
    add x0, x0, x1
    msr	sp_el2, x0


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
    //ORR   X0, X0,   #(7 << 6) // DAIF=0111 - will disable AIF of DAIF
    MSR   SPSR_EL1, X0 
    
    /*  enable interrupts from irq_vector_init */
    adr	x0, vectors  // load VBAR_EL1 with virtual
    msr	vbar_el1, x0 // vector table address
    
    bl enable_interrupt_controller
    
    bl enable_irq
    
    ADR   x0, chargeToEL0 // el entry points to the first instruction of
    MSR   ELR_EL1, X0     // EL0 code.
    
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

    

.globl dummy
dummy:
    ret
/*
void enable_interrupt_controller() {
    PUT32(ENABLE_IRQS_1, SYSTEM_TIMER_IRQ_1);
    PUT32(ENABLE_BASIC_IRQS, ARM_TIMER_IRQ);
}
*/   

.equ PBASE,  0x3F000000
.equ ENABLE_IRQS_1,  0x0000B210
.equ ENABLE_BASIC_IRQS,  0x0000B218
.equ SYSTEM_TIMER_IRQ_1, 0x00000002
.equ ARM_TIMER_IRQ, 0x00000001
 
.globl enable_interrupt_controller
enable_interrupt_controller:
    mov w0,#PBASE
    mov w1,#ENABLE_IRQS_1
    add x1, x0, x1
    mov x2, #SYSTEM_TIMER_IRQ_1
    str x2, [x0]
    
    mov w1,#ENABLE_BASIC_IRQS
    add x1, x0, x1
    mov x2, #ARM_TIMER_IRQ
    str x2, [x0]
    
    ret  // return to address in link registry (x30)
    
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

.data 
.align 8
         /* the .data section is dynamically created and its addresses cannot be easily predicted */
var1: .skip 1024  /* variable 1 in memory */
stack_el0: .skip STACK_SIZE  /* variable 1 in memory */

.align 8

.globl buff_scratch
buff_scratch: .word var1  /* address to var1 stored here */
adr_stack_el0: .word stack_el0  /* address to stack_el0 stored here */
adr_stack_el1: .word stack_el0  /* address to stack_el1 stored here */
adr_stack_el2: .word stack_el0  /* address to stack_el2 stored here */
adr_stack_el3: .word stack_el0  /* address to stack_el3 stored here */



