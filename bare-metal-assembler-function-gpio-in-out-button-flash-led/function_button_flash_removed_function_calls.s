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

set_gpio_pin_21_output:
set_gpio_pin_12_input:

@------------------     
@Start label
@------------------
_start:
   
    
@------------------
@load register with BASE
@------------------
ldr r0,=BASE
@------------------
@Load register with WAIT_CYCLES
@------------------
ldr r2,=WAIT_CYCLES


    @ ------------------- function set_gpio_pin_21_output 
    @Set bit 3 in GPFSEL2
    @------------------
    ldr r1,=SET_BIT3     @- write SET_BIT3 to GPFSEL2   x/4xw [BASE + GPFSEL2]
    str r1,[r0,#GPFSEL2] @- str 0x08,[BASE + 0x08] where [0x180ac + 0x08] = 180B4
    @------------------
    @Set bit 21 in GPSET0
    @------------------
    ldr r1,=SET_BIT21    @- write SET_BIT21 to GPSET0   x/4xw [BASE + GPSET0]
    str r1,[r0,#GPSET0]  @- str 0x200000,[BASE + 0x1c] where [0x180ac + 0x1c] = 180C8
    @ ------------------- end function set_gpio_pin_21_output 
        

    @ ------------------- function: function set_gpio_pin_21_output 
    @Set bits to zero in GPFSEL1
    @------------------
    ldr r1,=SET_BIT0     @- write SET_BIT0 to GPFSEL1   x/4xw [BASE + GPFSEL1]
    str r1,[r0,#GPFSEL1] @- str 0x00,[BASE + 0x04] where [0x180ac + 0x04] = 180B0
    @------------------ set gpio pin 12 for pull up
    ldr r1,=SET_BIT2     @- write SET_BIT2 to GPPUD   x/4xw [BASE + GPPUD]
    str r1,[r0,#GPPUD]   @- str 0x02,[BASE + 0x94] where [0x180ac + 0x94] = 18140
    @------------------ Wait 150 cycles – this provides the required set-up time for the control signal
    mov r10,#0
    delay0:@loop to large number
		add r10,r10,#1
		cmp r10,r2	
		bne delay0
    @------------------ set gpio pin 12 for pull up
    ldr r1,=SET_BIT12      @- write SET_BIT12 to GPPUDCLK0   x/4xw [BASE + GPPUDCLK0]
    str r1,[r0,#GPPUDCLK0] @- str 0x001000,[BASE + 0x98] where [0x180ac + 0x98] = 18144
    mov r5,#0
    delaya:@loop to large number
		add r5,r5,#1
		cmp r5,r2	
		bne delaya
    @------------------ reset GPPUD and back zero
    mov r1,#0              @- write 0x00 to GPPUD   x/4xw [BASE + GPPUD]
    str r1,[r0,#GPPUD]     @- str 0x00,[BASE + 0x94] where [0x180ac + 0x94] = 18140
    str r1,[r0,#GPPUDCLK0] @- str 0x00,[BASE + 0x98] where [0x180ac + 0x98] = 18144
    @------------------ done setting gpio pin 12 for pull up --------------
        
    sub    sp, r11, #0  /* Start of the epilogue. Readjusting the Stack Pointer */
    @ ------------------- end of function set_gpio_pin_12_input 





		

@Load register with COUNTER
@------------------
ldr r2,=COUNTER
ldr r1,=SET_BIT21
ldr r0,=BASE


@------------------
@MAKE LED BLINK
@------------------
@Infinite loop
@------------------
Infinite_loop:

        @Check if button on pin 12 is pressed (voltage has been pulled down)
        ldr r1,=SET_BIT12
        ldr r3,[r0,#GPLEV0]  @- ldr from [BASE + GPLEV0] where [0x180ac + 0x34] = 180E0
        AND r4, r3, r1
        cmp r4, r1
        bne buttonPressed

	@TURN ON
	ldr r1,=SET_BIT21
	str r1,[r0,#GPSET0]	
	@DELAY
	mov r5,#0
	delay:@loop to large number
		add r5,r5,#1
		cmp r5,r2	
		bne delay
		
	buttonPressed:
	@TURN OFF
	ldr r1,=SET_BIT21	
	str r1,[r0,#GPCLR0]
	@DELAY2
	mov r5,#0
	delay2:
		add r5,r5,#1
		cmp r5,r2	
		bne delay2
b Infinite_loop


array_buff_bridge:
 .word array_buff             /* address of array_buff, or in other words - array_buff[0] */

.space STACK_SIZE
exc_stack:

