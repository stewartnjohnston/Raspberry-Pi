.data
array_buff:
 .word 0xffffffff
 
 
.section .init
.text
.global exc_stack
.global _start

.equ STACK_SIZE, 0x0400	@STACK_SIZE this is a small stack!



_start:



array_buff_bridge:
 .word array_buff             /* address of array_buff, or in other words - array_buff[0] */

.space STACK_SIZE
exc_stack:

