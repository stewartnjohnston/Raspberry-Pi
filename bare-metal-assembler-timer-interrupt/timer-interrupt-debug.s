
.data
led_on_flag:
 .word 0xffffffff
 
 
 
 .section .init
.text
.global exc_stack
.global _start

.global _enable_interrupts

// From the ARM ARM (Architecture Reference Manual). Make sure you get the
// ARMv5 documentation which includes the ARMv6 documentation which is the
// correct processor type for the Broadcom BCM2835. The ARMv6-M manuals
// available on the ARM website are for Cortex-M parts only and are very
// different.
//


.equ    PERIPHERAL_BASE,                                  0x3F000000
.equ    RPI_INTERRUPT_CONTROLLER_BASE,                    0xB200
.equ    RPI_ARMTIMER_BASE,                                0xB400
.equ    RPI_ARMTIMER_CONTROL_OFFSET,                      0x08
.equ    RPI_INTERRUPT_CONTROLLER_BASE_Enable_basic_IRQs,  0x18
.equ    RPI_BASIC_ARM_TIMER_IRQ,                          0x01
.equ    TIMER_FREQUENCY,         0x400

.equ RPI_ARMTIMER_CTRL_23BIT,         0x02 @( 1 << 1 )

.equ RPI_ARMTIMER_CTRL_PRESCALE_1,    0x00 @( 0 << 2 )
.equ RPI_ARMTIMER_CTRL_PRESCALE_16,   0x04 @( 1 << 2 )
.equ RPI_ARMTIMER_CTRL_PRESCALE_256,  0x08 @( 2 << 2 )

/** @brief 0 : Timer interrupt disabled - 1 : Timer interrupt enabled */
.equ RPI_ARMTIMER_CTRL_INT_ENABLE,    0x20 @( 1 << 5 )
.equ RPI_ARMTIMER_CTRL_INT_DISABLE,   0x00 @( 0 << 5 )

/** @brief 0 : Timer disabled - 1 : Timer enabled */
.equ RPI_ARMTIMER_CTRL_ENABLE,        0x80 @( 1 << 7 )
.equ RPI_ARMTIMER_CTRL_DISABLE,       0x00 @( 0 << 7 )

.equ LED_ON_FLAG_ADDRESS,   led_on_flag


// See ARM section A2.2 (Processor Modes)

.equ    CPSR_MODE_USER,         0x10
.equ    CPSR_MODE_FIQ,          0x11
.equ    CPSR_MODE_IRQ,          0x12
.equ    CPSR_MODE_SVR,          0x13
.equ    CPSR_MODE_ABORT,        0x17
.equ    CPSR_MODE_UNDEFINED,    0x1B
.equ    CPSR_MODE_SYSTEM,       0x1F

// See ARM section A2.5 (Program status registers)
.equ    CPSR_IRQ_INHIBIT,       0x80
.equ    CPSR_FIQ_INHIBIT,       0x40
.equ    CPSR_THUMB,             0x20

_start:
    ldr pc, _reset_h
    ldr pc, _undefined_instruction_vector_h
    ldr pc, _software_interrupt_vector_h
    ldr pc, _prefetch_abort_vector_h
    ldr pc, _data_abort_vector_h
    ldr pc, _unused_handler_h
    ldr pc, _interrupt_vector_h
    ldr pc, _fast_interrupt_vector_h


_reset_h:                           .word   _reset_
_undefined_instruction_vector_h:    .word   undefined_instruction_vector
_software_interrupt_vector_h:       .word   software_interrupt_vector
_prefetch_abort_vector_h:           .word   prefetch_abort_vector
_data_abort_vector_h:               .word   data_abort_vector
_unused_handler_h:                  .word   _reset_
_interrupt_vector_h:                .word   interrupt_vector
_fast_interrupt_vector_h:           .word   fast_interrupt_vector

_reset_:
    // We enter execution in supervisor mode. For more information on
    // processor modes see ARM Section A2.2 (Processor Modes)

    mov     r0, #0x8000
    mov     r1, #0x0000
    ldmia   r0!,{r2, r3, r4, r5, r6, r7, r8, r9}
    stmia   r1!,{r2, r3, r4, r5, r6, r7, r8, r9}
    ldmia   r0!,{r2, r3, r4, r5, r6, r7, r8, r9}
    stmia   r1!,{r2, r3, r4, r5, r6, r7, r8, r9}

    // We're going to use interrupt mode, so setup the interrupt mode
    // stack pointer which differs to the application stack pointer:
    mov r0, #(CPSR_MODE_IRQ | CPSR_IRQ_INHIBIT | CPSR_FIQ_INHIBIT )
    msr cpsr_c, r0
    
    ldr sp, =exc_stack
    ldr r0, =STACK_SIZE_2
    add sp, sp, r0
    @mov sp, #(63 * 1024 * 1024)

    // Switch back to supervisor mode (our application mode) and
    // set the stack pointer towards the end of RAM. Remember that the
    // stack works its way down memory, our heap will work it's way
    // up memory toward the application stack.
    mov r0, #(CPSR_MODE_SVR | CPSR_IRQ_INHIBIT | CPSR_FIQ_INHIBIT )
    msr cpsr_c, r0

    // Set the stack pointer at some point in RAM that won't harm us
    // It's different from the IRQ stack pointer above and no matter
    // what the GPU/CPU memory split, 64MB is available to the CPU
    // Keep it within the limits and also keep it aligned to a 32-bit
    // boundary!
    @mov     sp, #(64 * 1024 * 1024)   I'll set the stack pointer in _cstartup


    // The c-startup function which we never return from. This function will
    // initialise the ro data section (most things that have the const
    // declaration) and initialise the bss section variables to 0 (generally
    // known as automatics). It'll then call main, which should never return.


b _stewart
    bl      _cstartup

    // If main does return for some reason, just catch it and stay here.
_inf_loop:
    b       _inf_loop


_get_stack_pointer:
    // Return the stack pointer value
    str     sp, [sp]
    ldr     r0, [sp]

    // Return from the function
    mov     pc, lr
@------------------------ end of function _reset_ --------------------------------------------

@--------------------------------- the interrupt handlers ------
 undefined_instruction_vector:
 software_interrupt_vector:
 prefetch_abort_vector:
 data_abort_vector:
 unused_handler:
 fast_interrupt_vector:
    subs pc,lr,#4   @ do nothing and return
@--------------------------------- end of the interrupt handlers ------
 
 _cstartup:
    ldr sp, =exc_stack
    ldr r0, =STACK_SIZE
    add sp, sp, r0
    
push   {r11, lr}    /* Start of the prologue. Saving Frame Pointer and LR onto the stack */
add    r11, sp, #0  /* Setting up the bottom of the stack frame */
sub    sp, sp, #16  /* End of the prologue. Allocating some buffer on the stack */

 
/* setup gpio pin 21 to blink LED */
mov r0, #21
ldr r1, =FSEL_PIN_AS_OUTPUT
bl      set_GPFSEL

mov r0, #21
ldr r1, =GPSET0
bl      set_GPSET

 
 /* Enable the timer interrupt IRQ */
 mov r0, #PERIPHERAL_BASE
 mov r1, #RPI_INTERRUPT_CONTROLLER_BASE
 mov r2, #RPI_INTERRUPT_CONTROLLER_BASE_Enable_basic_IRQs
 add r1, r1, r2
 mov r2, #RPI_BASIC_ARM_TIMER_IRQ
 str r2, [r0,r1]                    @ write the eanble flag to the timer register
 
 /* set the timer frequency to = Clk/256 = 0x400 */
 mov r2, #TIMER_FREQUENCY
 mov r1, #RPI_ARMTIMER_BASE
 str r2, [r0,r1]                    @ write frequency to timer load register
 
 /* set the ARM timer flags */
 mov r1, #RPI_ARMTIMER_CONTROL_OFFSET
 mov r2,#0
 mov r3,#RPI_ARMTIMER_CTRL_23BIT
 and r2,r2,r3
 mov r3,#RPI_ARMTIMER_CTRL_ENABLE
 and r2,r2,r3
 mov r3,#RPI_ARMTIMER_CTRL_INT_ENABLE
 and r2,r2,r3
 mov r3,#RPI_ARMTIMER_CTRL_PRESCALE_256
 and r2,r2,r3
 str r2,[r0,r1]
 
/* enable interrupts in the cpsr registry */
bl _enable_interrupts


/* loop here for ever!  */
infinite_loop:
b infinite_loop


  
@------------------------------------------------------------------------------
interrupt_vector: 
        sub     sp, sp, #28      @ space for saving regs
                                @ (keeping 8-byte sp align)
        str     r3, [sp, #4]     @ save r3
        str     r4, [sp, #8]     @ save r4
        str     r5, [sp, #12]     @      r5
        str     r6, [sp, #16]     @      r6
        str     fp, [sp, #20]    @      fp
        str     lr, [sp, #24]    @      lr
        add     fp, sp, #24      @ set our frame pointer
   
  ldr r0, =LED_ON_FLAG_ADDRESS

  ldr r1,[r0]
  mov r2,#1
  cmp r1,r2
  bne turnOffLED

  mov r2,#0           @ reset the LED_FLAG_ADDRESS = 0
  str r2,[r0]
  
  @TURN ON pin21 LED
  mov r0, #21
  ldr r1, =GPSET0
  bl      set_GPSET
  b toExitFunction

turnOffLED:

  mov r2,#1           @ reset the LED_FLAG_ADDRESS = 1
  str r2,[r0]

  @TURN OFF pin21 LED
  mov r0, #21
  ldr r1, =GPCLR0
  bl      set_GPSET
  
toExitFunction:

        ldr     r3, [sp, #4]     @ restore r3
        ldr     r4, [sp, #8]     @ restore r4
        ldr     r5, [sp, #12]    @      r5
        ldr     r6, [sp, #16]    @      r6
        ldr     fp, [sp, #20]    @      fp
        ldr     lr, [sp, #24]    @      lr
        add     sp, sp, #28      @      sp
        bx      lr               @ return
        @ ------------------- end of function _interrupt_vector_h
@------------------------------------------------------------------------------

_enable_interrupts:
    mrs     r0, cpsr
    bic     r0, r0, #0x80
    msr     cpsr_c, r0

    mov     pc, lr


@---------------------- appended from old file -----------------------------

.equ BASE,  0x3f200000          @Base address
@.equ BASE,  array_buff         @Base address
.equ STACK_SIZE, 0x0800	@STACK_SIZE this is a small stack!
.equ STACK_SIZE_2, 0x0400	@STACK_SIZE this is a small stack!
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

@----------------------------------------------------------------------------------------------
    @ ------------------- function: function divide_int

@------------------     
@Start label
@------------------
_stewart:
    ldr sp, =exc_stack
    ldr r0, =STACK_SIZE
    add sp, sp, r0
    
push   {r11, lr}    /* Start of the prologue. Saving Frame Pointer and LR onto the stack */
add    r11, sp, #0  /* Setting up the bottom of the stack frame */
sub    sp, sp, #16  /* End of the prologue. Allocating some buffer on the stack */
    
/* enable interrupts in the cpsr registry */
bl _enable_interrupts


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

mov r0, #21
ldr r1, =GPSET0
bl      set_GPSET

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
        @ldr r1,=SET_BIT12
        @ldr r3,[r6,#GPLEV0]  @- ldr from [BASE + GPLEV0] where [0x180ac + 0x34] = 180E0
        @AND r4, r3, r1
        @cmp r4, r1
        @bne buttonPressed
        
        
        mov r0, #12
        bl      read_GPLEV @ returns r0=1 if pin high OR r0=0 pin low
        mov r1, #0
        cmp r0, r1
        beq buttonPressed  @ branch if button is pressed

	@TURN ON pin21 LED
	mov r0, #21
        ldr r1, =GPSET0
        bl      set_GPSET


	@DELAY
	mov r5,#0
	delay:@loop to large number
		add r5,r5,#1
		cmp r5,r2	
		bne delay
		
buttonPressed:
	@TURN OFF pin21 LED
	mov r0, #21
        ldr r1, =GPCLR0
        bl      set_GPSET
        
	@DELAY2
	mov r5,#0
	delay2:
		add r5,r5,#1
		cmp r5,r2	
		bne delay2
b Infinite_loop


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

    mov r1, #NUM_PIN_IN_GPSET
    bl  divide_int

    lsl r0,r0,#2     @ multiple offset by 4, 4 bytes per offset

    
    @Set bit 3 in GPSET0
    @------------------
    ldr r6,=BASE
    add r6,r6,r5 
    mov r4, #1
    lsl r4,r4,r1
@    ldr r5,[r6,r0]
@    orr r5,r5,r4
    str r4,[r6,r0]
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
    @ ------------------- function: function read_GPLEV
    @ -------- param r0 = gpio pin #
    @ -------- return
    @            r0 = 0 if input is low
    @            r0 = 1 if input is high
read_GPLEV:
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

    mov r1, #NUM_PIN_IN_GPSET
    bl  divide_int

    lsl r0,r0,#2     @ multiple offset by 4, 4 bytes per offset

    
    @Set bit 3 in GPSET0
    @------------------
    ldr r6,=BASE
    ldr r5,=GPLEV0
    add r6,r6,r5 
    mov r4, #1
    lsl r4,r4,r1
    ldr r5,[r6,r0]
    AND r5, r5, r4
    cmp r5, r4
    bne pinLow  @ pinLow = button being pressed
    mov r0,#1
    b exitDone
pinLow:
    mov r0,#0
exitDone:
    @-------------------
 
 
        ldr     r3, [sp, #4]     @ restore r4
        ldr     r4, [sp, #8]     @ restore r4
        ldr     r5, [sp, #12]    @      r5
        ldr     r6, [sp, #16]    @      r6
        ldr     fp, [sp, #20]    @      fp
        ldr     lr, [sp, #24]    @      lr
        add     sp, sp, #28      @      sp
        bx      lr              @ return 
    @ ------------------- end of function read_GPLEV     
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

XLED_ON_FLAG_ADDRESS:
 .word led_on_flag             /* address of flag */

.space STACK_SIZE
exc_stack:    
@---------------------- end of file ----------------------------------------

