.data
array_buff:
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
.word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 .word 0xffffffff
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
.section .init
.text
.global exc_stack
.global _start
@------------------
@SETUP VALUES
@------------------
.equ BASE,  0x3f200000          @Base address
@.equ BASE,  array_buff         @Base address
.equ STACK_SIZE, 0x0400	@STACK_SIZE this is a small stack!
.equ GPPUD, 0x94		@GPPUD register offset  (used for gpio 12)
.equ GPPUDCLK0, 0x98		@GPPUDCLK0 register offset  (used for gpio 12)
.equ GPFSEL1, 0x04		@FSEL1 register offset  (used for gpio 12)
.equ GPFSEL2, 0x08		@FSEL2 register offset  (used for gpio 21)
.equ GPLEV0,  0x34		@GPLEV0 register offset  (used for gpio 12)
.equ GPSET0,  0x1c		@GPSET0 register offset (used for both gpio 12 and 21)
.equ GPCLR0,0x28		@GPCLR0 register offset (used for both gpio 12 and 21)
.equ SET_BIT3,   0x08	  	@sets bit three b1000	(used for gpio 21)	
.equ SET_BIT0,   0x00		@set NO bits    b0000	(used for gpio 12)	
.equ SET_BIT2,   0x02		@set bit two    b0010	(used for gpio 12 set pull up in GPPUD)	
.equ SET_BIT21,  0x200000 	@sets bit 21  @-- flash gpio pin 21
.equ SET_BIT12,  0x001000 	@sets bit 12  @-- flash gpio pin 12
.equ COUNTER, 0xf0000
.equ WAIT_CYCLES, 0x0096        @Wait 150 cycles  150=0x0096
.equ FSEL_PIN_AS_INPUT,             0x00 @
.equ FSEL_PIN_AS_OUTPUT,            0x01 @
.equ GPPUD_ENABLE_PULL_UP_CONTROL,  0x02 @
.equ GPPUD_CLEAR,                   0x00 @
.equ GPPUDCLK_SET,                  0x01 @
.equ GPPUDCLK_CLEAR,                0x00 @
.equ EOR_MASK, 0xffffffff



@------------------     
@Start label
@------------------
_start:
    ldr sp, =exc_stack
    ldr r0, =STACK_SIZE
    add sp, sp, r0
    
push   {r11, lr}    /* Start of the prologue. Saving Frame Pointer and LR onto the stack */
add    r11, sp, #0  /* Setting up the bottom of the stack frame */
sub    sp, sp, #16  /* End of the prologue. Allocating some buffer on the stack */
    
    
@------------------
@load register with BASE
@------------------
ldr r6,=BASE
@------------------
@Load register with WAIT_CYCLES
@------------------

mov r0, #21
ldr r1, =FSEL_PIN_AS_OUTPUT
bl      set_GPFSEL

mov r0, #12
bl      set_gpio_high_forInput

@ldr r6,=BASE
@bl      set_gpio_pin_12_input
		

@Load register with COUNTER
@------------------
ldr r2,=COUNTER
ldr r6,=BASE


@------------------
@MAKE LED BLINK
@------------------
@Infinite loop
@------------------
Infinite_loop:

        @Check if button on pin 12 is pressed (voltage has been pulled down)
        ldr r1,=SET_BIT12
        ldr r3,[r6,#GPLEV0]  @- ldr from [BASE + GPLEV0] where [0x180ac + 0x34] = 180E0
        AND r4, r3, r1
        cmp r4, r1
        bne buttonPressed

	@TURN ON
	ldr r1,=SET_BIT21
	str r1,[r6,#GPSET0]	
	@DELAY
	mov r5,#0
	delay:@loop to large number
		add r5,r5,#1
		cmp r5,r2	
		bne delay
		
	buttonPressed:
	@TURN OFF
	ldr r1,=SET_BIT21	
	str r1,[r6,#GPCLR0]
	@DELAY2
	mov r5,#0
	delay2:
		add r5,r5,#1
		cmp r5,r2	
		bne delay2
b Infinite_loop

@ ------------------- function: function set_gpio_pin_21_output ------------------------------------------------
    @ -------- param r0 = gpio base
set_gpio_pin_21_output:
    push   {r11, lr}    /* Start of the prologue. Saving Frame Pointer and LR onto the stack */
    add    r11, sp, #0  /* Setting up the bottom of the stack frame */
    sub    sp, sp, #16  /* End of the prologue. Allocating some buffer on the stack */

    ldr r0,=BASE
    @Set bit 3 in GPFSEL2
    @------------------
    ldr r1,=SET_BIT3     @- write SET_BIT3 to GPFSEL2   x/4xw [BASE + GPFSEL2]
    str r1,[r0,#GPFSEL2] @- str 0x08,[BASE + 0x08] where [0x180ac + 0x08] = 180B4
    @------------------
    @Set bit 21 in GPSET0
    @------------------
    ldr r1,=SET_BIT21    @- write SET_BIT21 to GPSET0   x/4xw [BASE + GPSET0]
    str r1,[r0,#GPSET0]  @- str 0x200000,[BASE + 0x1c] where [0x180ac + 0x1c] = 180C8
        
    sub    sp, r11, #0  /* Start of the epilogue. Readjusting the Stack Pointer */
    pop    {r11, pc}    /* End of the epilogue. Restoring Frame pointer from the stack, jumping to previously saved LR via direct load into PC */
    @ ------------------- end of function set_gpio_pin_21_output ------------------------------------------------


@----------------------------------------------------------------------------------------------
    @ ------------------- function: function divide_int
    @ -------- Input
    @ -------- param r0 = dividend
    @ -------- param r1 = divisor
    @ -------- Output 
    @ -------- r0  quotient
    @ -------- r1  remainder
    @ ---------    Where   dividend/divisor = quotient and remainder
divide_int:  
        sub     sp, sp, #28      @ space for saving regs
                                @ (keeping 8-byte sp align)
        str     r3, [sp, #4]     @ save r3
        str     r4, [sp, #8]     @ save r4
        str     r5, [sp, #12]     @      r5
        str     r6, [sp, #16]     @      r6
        str     fp, [sp, #20]    @      fp
        str     lr, [sp, #24]    @      lr
        add     fp, sp, #24      @ set our frame pointer

    mov   r3, r1   @ move divisor to r3
    mov   r1, r0   @ move dividend to r1       
    mov   r0, #0   @ set the quotient count to zero
    
continue:             @ loop subracting divisor from dividend
    cmp   r1, r3
    blt   done        @ when remainder is less than divisor we are done
    add   r0, r0, #1
    sub   r1, r1, r3 @ count how many time be subracted the divisor
    b     continue
done:

        ldr     r3, [sp, #4]     @ restore r3
        ldr     r4, [sp, #8]     @ restore r4
        ldr     r5, [sp, #12]    @      r5
        ldr     r6, [sp, #16]    @      r6
        ldr     fp, [sp, #20]    @      fp
        ldr     lr, [sp, #24]    @      lr
        add     sp, sp, #28      @      sp
        bx      lr               @ return    @ ------------------- end of function divide_int
@----------------------------------------------------------------------------------------------
    

@----------------------------------------------------------------------------------------------
    @ ------------------- function: function set_GPFSEL
    @ -------- param r0 = gpio pin #
    @ -------- param r1 = GPFSEL flag (000=input, 001=output)
    .equ   NUM_PIN_IN_SEL, 10  @ constant: number of pins in a select register
    .equ   NUM_PIN_IN_SEL, 10  @ constant: number of pins in a select register

set_GPFSEL:
        sub     sp, sp, #32      @ space for saving regs
                                @ (keeping 8-byte sp align)
        str     r3, [sp, #4]     @ save r3
        str     r4, [sp, #8]     @ save r4
        str     r5, [sp, #12]    @      r5
        str     r6, [sp, #16]    @      r6
        str     r7, [sp, #20]    @      r7
        str     fp, [sp, #24]    @      fp
        str     lr, [sp, #28]    @      lr
        add     fp, sp, #28      @ set our frame pointer

    mov r7, r1           @ backup the GPFSEL flag to r4

    mov r1, #NUM_PIN_IN_SEL
    bl  divide_int

    lsl r0,r0,#2     @ multiple offset by 4, 4 bytes per offset

    mov r3, r1       @ need to multiply (remainder) pin
    add r1, r1, r3, lsl #1 @ position by 3
    
    @Set bit 3 in GPFSEL
    @------------------
    ldr r6,=BASE
    ldr r5,=EOR_MASK
    mov r4, #7
    lsl r4,r4,r1
    eor r4,r4,r5
    ldr r5,[r6,r0]
    and r5,r5,r4
    
    lsl r7,r7,r1    @ shift the flags their pin position
    orr r5,r5,r7
    
    str r5,[r6,r0]
    @-------------------
    
        ldr     r3, [sp, #4]     @ restore r3
        ldr     r4, [sp, #8]     @ restore r4
        ldr     r5, [sp, #12]    @      r5
        ldr     r6, [sp, #16]    @      r6
        ldr     r7, [sp, #20]    @      r7
        ldr     fp, [sp, #24]    @      fp
        ldr     lr, [sp, #28]    @      lr
        add     sp, sp, #32      @      sp
        bx      lr              @ return 
    @ ------------------- end of function set_GPFSEL     
@----------------------------------------------------------------------------------------------


@----------------------------------------------------------------------------------------------
    @ ------------------- function: function set_GPSET
    @ -------- param r0 = gpio pin #
    @ -------- param r1 = The GPSET0 or GPCLR0 register address
    .equ   NUM_PIN_IN_GPSET, 32  @ constant: number of pins in a GPSET register
set_GPSET:
        sub     sp, sp, #28      @ space for saving regs
                                @ (keeping 8-byte sp align)
        str     r3, [sp, #4]     @ save r3
        str     r4, [sp, #8]     @ save r4
        str     r5, [sp, #12]    @      r5
        str     r6, [sp, #16]    @      r6
        str     fp, [sp, #20]    @      fp
        str     lr, [sp, #24]    @      lr
        add     fp, sp, #24      @ set our frame pointer



    mov r4, r0           @ backup pin # to r4
    mov r5, r1           @ backup The GPSET0 or GPCLR0 register address to r5

    mov r1, #NUM_PIN_IN_SEL
    bl  divide_int

    lsl r0,r0,#2     @ multiple offset by 4, 4 bytes per offset

    
    @Set bit 3 in GPSET0
    @------------------
    ldr r6,=BASE
    add r6,r6,r5 
    mov r4, #1
    lsl r4,r4,r1
    ldr r5,[r6,r0]
    orr r5,r5,r4
    str r5,[r6,r0]
    @-------------------
 
 
        ldr     r3, [sp, #4]     @ restore r4
        ldr     r4, [sp, #8]     @ restore r4
        ldr     r5, [sp, #12]    @      r5
        ldr     r6, [sp, #16]    @      r6
        ldr     fp, [sp, #20]    @      fp
        ldr     lr, [sp, #24]    @      lr
        add     sp, sp, #28      @      sp
        bx      lr              @ return 
    @ ------------------- end of function set_GPSET     
@----------------------------------------------------------------------------------------------


@----------------------------------------------------------------------------------------------
    @ ------------------- function: function set_GPPUD
    @ -------- param r0 = GPPUD flag
    .equ   NUM_PIN_IN_GPSET, 32  @ constant: number of pins in a GPSET register
set_GPPUD:

    ldr r6,=BASE
    str r0,[r6,#GPPUD] @- str 0x00,[BASE + 0x04] where [0x180ac + 0x04] = 180B0

    bx      lr              @ return 
        @ ------------------- end of function set_GPPUD     
@----------------------------------------------------------------------------------------------

 @----------------------------------------------------------------------------------------------
    @ ------------------- function: function wait_cycles
    @ -------- param r0 = wait cycles
wait_cycles:
        sub     sp, sp, #12      @ space for saving regs
                                @ (keeping 8-byte sp align)
        str     r1, [sp, #4]     @ save r1
        str     r2, [sp, #8]     @ save r2
        add     fp, sp, #8      @ set our frame pointer

        mov     r1,#0

        repeat:@loop to large number
		add r1,r1,#1
		cmp r0,r1	
		bne repeat
 
        ldr     r1, [sp, #4]     @ restore r1
        ldr     r2, [sp, #8]     @ restore r2
        add     sp, sp, #12      @      sp
        bx      lr              @ return 
    @ ------------------- end of function wait_cycles     
@----------------------------------------------------------------------------------------------

@----------------------------------------------------------------------------------------------
    @ ------------------- function: function set_GPPUDCLK
    @ -------- param r0 = gpio pin #
    @ -------- param r1 = the flag:
    @                1 - set
    @                0 - clear
    .equ   NUM_PIN_IN_GPSET, 32  @ constant: number of pins in a GPSET register
set_GPPUDCLK:
        sub     sp, sp, #28      @ space for saving regs
                                @ (keeping 8-byte sp align)
        str     r1, [sp, #4]     @ save r1
        str     r4, [sp, #8]     @ save r4
        str     r5, [sp, #12]    @      r5
        str     r6, [sp, #16]    @      r6
        str     fp, [sp, #20]    @      fp
        str     lr, [sp, #24]    @      lr
        add     fp, sp, #24      @ set our frame pointer



    mov r4, r1           @ move flag r4

    mov r1, #NUM_PIN_IN_GPSET
    bl  divide_int

    lsl r0,r0,#2     @ multiple offset by 4, 4 bytes per offset

    
    @Set pin bit in GPPUDCLK0
    @------------------
    ldr r5,=GPPUDCLK0
    ldr r6,=BASE
    add r6,r6,r5 
    lsl r4,r4,r1
    str r4,[r6,r0]
    @-------------------
 
 
        ldr     r1, [sp, #4]     @ restore r1
        ldr     r4, [sp, #8]     @ restore r4
        ldr     r5, [sp, #12]    @      r5
        ldr     r6, [sp, #16]    @      r6
        ldr     fp, [sp, #20]    @      fp
        ldr     lr, [sp, #24]    @      lr
        add     sp, sp, #28      @      sp
        bx      lr              @ return 
    @ ------------------- end of function set_GPPUDCLK     
@----------------------------------------------------------------------------------------------



@----------------------------------------------------------------------------------------------
    @ ------------------- function: function set_gpio_high_forInput
    @ -------- param r0 = gpio pin #
set_gpio_high_forInput:
        sub     sp, sp, #28      @ space for saving regs
                                 @ (keeping 8-byte sp align)
        str     r3, [sp, #4]     @ save r3
        str     r4, [sp, #8]     @ save r4
        str     r5, [sp, #12]    @      r5
        str     r6, [sp, #16]    @      r6
        str     fp, [sp, #20]    @      fp
        str     lr, [sp, #24]    @      lr
        add     fp, sp, #24      @ set our frame pointer

    mov r3,r0      @- backup pin#

    ldr r1,=FSEL_PIN_AS_INPUT
    bl   set_GPFSEL
    

    ldr r0,=GPPUD_ENABLE_PULL_UP_CONTROL
    bl   set_GPPUD
    
    ldr r0,=WAIT_CYCLES
    bl   wait_cycles
    
    mov r0,r3    
    ldr r1,=GPPUDCLK_SET
    bl   set_GPPUDCLK
    
    ldr r0,=WAIT_CYCLES
    bl   wait_cycles

    @mov r0,r3    
    ldr r0,=GPPUD_CLEAR
    bl   set_GPPUD

    mov r0,r3    
    ldr r1,=GPPUDCLK_CLEAR
    bl   set_GPPUDCLK
 
        ldr     r3, [sp, #4]     @ restore r4
        ldr     r4, [sp, #8]     @ restore r4
        ldr     r5, [sp, #12]    @      r5
        ldr     r6, [sp, #16]    @      r6
        ldr     fp, [sp, #20]    @      fp
        ldr     lr, [sp, #24]    @      lr
        add     sp, sp, #28      @      sp
        bx      lr              @ return 
    @ ------------------- end of function set_gpio_high_forInput     
@----------------------------------------------------------------------------------------------

set_gpio_pin_12_input:
    push   {r11, lr}    /* Start of the prologue. Saving Frame Pointer and LR onto the stack */
    add    r11, sp, #0  /* Setting up the bottom of the stack frame */
    sub    sp, sp, #16  /* End of the prologue. Allocating some buffer on the stack */

    @Set bits to zero in GPFSEL1
    @------------------
    ldr r6,=BASE
    ldr r1,=SET_BIT0     @- write SET_BIT0 to GPFSEL1   x/4xw [BASE + GPFSEL1]
    str r1,[r6,#GPFSEL1] @- str 0x00,[BASE + 0x04] where [0x180ac + 0x04] = 180B0
    @------------------ set gpio pin 12 for pull up
    ldr r1,=SET_BIT2     @- write SET_BIT2 to GPPUD   x/4xw [BASE + GPPUD]
    str r1,[r6,#GPPUD]   @- str 0x02,[BASE + 0x94] where [0x180ac + 0x94] = 18140
    @------------------ Wait 150 cycles – this provides the required set-up time for the control signal
    ldr r7,=WAIT_CYCLES
    mov r5,#0
    delay0:@loop to large number
		add r5,r5,#1
		cmp r5,r7	
		bne delay0
    @------------------ set gpio pin 12 for pull up
    ldr r1,=SET_BIT12      @- write SET_BIT12 to GPPUDCLK0   x/4xw [BASE + GPPUDCLK0]
    str r1,[r6,#GPPUDCLK0] @- str 0x001000,[BASE + 0x98] where [0x180ac + 0x98] = 18144
    mov r5,#0
    delaya:@loop to large number
		add r5,r5,#1
		cmp r5,r7	
		bne delaya
    @------------------ reset GPPUD and back zero
    mov r1,#0              @- write 0x00 to GPPUD   x/4xw [BASE + GPPUD]
    str r1,[r6,#GPPUD]     @- str 0x00,[BASE + 0x94] where [0x180ac + 0x94] = 18140
    str r1,[r6,#GPPUDCLK0] @- str 0x00,[BASE + 0x98] where [0x180ac + 0x98] = 18144
    @------------------ done setting gpio pin 12 for pull up --------------
        
    sub    sp, r11, #0  /* Start of the epilogue. Readjusting the Stack Pointer */
    pop    {r11, pc}    /* End of the epilogue. Restoring Frame pointer from the stack, jumping to previously saved LR via direct load into PC */
    @ ------------------- end of function set_gpio_pin_12_input ------------------------------------------------



array_buff_bridge:
 .word array_buff             /* address of array_buff, or in other words - array_buff[0] */

.space STACK_SIZE
exc_stack:

