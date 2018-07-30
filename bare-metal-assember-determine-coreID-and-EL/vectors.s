 
.globl _start
_start:

.equ zerob, 0x100
.equ oneb,  0x200
.equ twob,  0x300
.equ threeb,  0x400
.equ elvalue,  0x16

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

.globl dummy
dummy:
    ret

.data 
.align 8
         /* the .data section is dynamically created and its addresses cannot be easily predicted */
var1: .skip 1024  /* variable 1 in memory */
var2: .word 40  /* variable 2 in memory */

.align 8

.globl buff_scratch
buff_scratch: .word var1  /* address to var1 stored here */
adr_var2: .word var2  /* address to var2 stored here */

