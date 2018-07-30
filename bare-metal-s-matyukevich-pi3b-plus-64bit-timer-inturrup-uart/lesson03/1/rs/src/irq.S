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
	msr    daifclr, #2 \\ enable the IRQ
	ret

.globl disable_irq
disable_irq:
        // see above
	msr	daifset, #2
	ret
