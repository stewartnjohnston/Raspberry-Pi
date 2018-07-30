
//-------------------------------------------------------------------
//-------------------------------------------------------------------


.globl _start
_start:
    b skip
    b hang
    b hang
    b hang
    b hang
    b hang
    b hang
    b hang

    b hang
    b hang
    b hang
    b hang
    b hang
    b hang
    b hang
    b hang


.balign 0x80
    b hang
    
.balign 0x80
    b hang

.balign 0x80    
    b hang
    
.balign 0x80
    b hang

.balign 0x80
    b irq_handler

skip:

    //set EL1 to aarch64
    mov x1,#0x80000000
	msr	hcr_el2,x1

    //disable traps
    //before 00C50838
    //Just set the res1 bits
    ldr x0,=0x00C00800
	msr	sctlr_el1,x0
    //after 0x00C00800

	mov	x0,#0x3c5  
	msr	spsr_el2,x0
    //ldr x0,=enter_el1
	adr	x0,enter_el1
	msr	elr_el2, x0
	eret
enter_el1:

  	//mov x0,#0x80000
    ldr x0,=_start
   	msr vbar_el1,x0


    mov sp,#0x08000000
    bl notmain
hang: b hang

.globl PUT32
PUT32:
  str w1,[x0]
  ret

.globl GET32
GET32:
    ldr w0,[x0]
    ret

.globl enable_irq
enable_irq:

    ldr x0,=_start
   	msr vbar_el1,x0

    //ldr x1,=0x00080000
    //msr vbar_el2,x1
    //msr vbar_el3,x1
    //route to EL3
    //mrs x0,scr_el3
    //orr x0,x0,#8
    //orr x0,x0,#4
    //orr x0,x0,#2
    //msr scr_el3,x0
    //clear/enable irq bit in PSTATE
    msr daifclr,#2
    ret

irq_handler:
    //19 up are callee saved
    //so we have to preserve all below?
    stp x0,x1,[sp,#-16]!
    stp x2,x3,[sp,#-16]!
    stp x4,x5,[sp,#-16]!
    stp x6,x7,[sp,#-16]!
    stp x8,x9,[sp,#-16]!
    stp x10,x11,[sp,#-16]!
    stp x12,x13,[sp,#-16]!
    stp x14,x15,[sp,#-16]!
    stp x16,x17,[sp,#-16]!
    stp x18,x19,[sp,#-16]!

    //mrs x0,esr_el1 //0x60000000 not reporting EC
    bl c_irq_handler

    ldp x18,x19,[sp],#16
    ldp x16,x17,[sp],#16
    ldp x14,x15,[sp],#16
    ldp x12,x13,[sp],#16
    ldp x10,x11,[sp],#16
    ldp x8,x9,[sp],#16
    ldp x6,x7,[sp],#16
    ldp x4,x5,[sp],#16
    ldp x2,x3,[sp],#16
    ldp x0,x1,[sp],#16
    eret

.globl DOWFI
DOWFI:
    wfi
    //msr daifset,#2
    ret



