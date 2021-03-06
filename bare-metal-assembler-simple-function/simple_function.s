.section .init
.text
.global exc_stack
.global _start

.equ STACK_SIZE, 0x0400	@STACK_SIZE this is a small stack!

non_leaf_function:
    push   {r11, lr}    /* Start of the prologue. Saving Frame Pointer and LR onto the stack */
    add    r11, sp, #0  /* Setting up the bottom of the stack frame */
    sub    sp, sp, #16  /* End of the prologue. Allocating some buffer on the stack */

    @ body of the function
    
    add     r0, r0, r1
    
    mov     r1, #5
    bl     leaf_function          /* Calling/branching to function */
        
    sub    sp, r11, #0  /* Start of the epilogue. Readjusting the Stack Pointer */
    pop    {r11, pc}    /* End of the epilogue. Restoring Frame pointer from the stack, jumping to previously saved LR via direct load into PC */

non_leaf_function_that_fails_toCallAleaf:
    push   {r11, lr}    /* Start of the prologue. Saving Frame Pointer and LR onto the stack */
    add    r11, sp, #0  /* Setting up the bottom of the stack frame */
    sub    sp, sp, #16  /* End of the prologue. Allocating some buffer on the stack */

    @ body of the function
    
    add     r0, r0, r1
    
        
    sub    sp, r11, #0  /* Start of the epilogue. Readjusting the Stack Pointer */
    pop    {r11, pc}    /* End of the epilogue. Restoring Frame pointer from the stack, jumping to previously saved LR via direct load into PC */


leaf_function:
    push   {r11}        /* Start of the prologue. Saving Frame Pointer onto the stack */
    add    r11, sp, #0  /* Setting up the bottom of the stack frame */
    sub    sp, sp, #12  /* End of the prologue. Allocating some buffer on the stack */
    @ body of the function
    
    add     r0, r0, r1
    
    add    sp, r11, #0  /* Start of the epilogue. Readjusting the Stack Pointer */
    pop    {r11}        /* restoring frame pointer */
    bx     lr           /* End of the epilogue. Jumping back to main via LR register */
	
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
    
    mov     r0, #1
    mov     r1, #3
    bl      leaf_function
    
    mov     r0, #8
    mov     r1, #1
    bl      non_leaf_function_that_fails_toCallAleaf

    mov     r0, #7
    mov     r1, #8
    bl      non_leaf_function
    
Infinite_loop:

	mov r5,#0
b Infinite_loop


.space STACK_SIZE
exc_stack:

