// Typical exception vector table code.
.balign 0x800
Vector_table_el3:
curr_el_sp0_sync: // The exception handler for a synchronous
 // exception from the current EL using SP0.
.balign 0x80
curr_el_sp0_irq: // The exception handler for an IRQ exception
 // from the current EL using SP0.
.balign 0x80
curr_el_sp0_fiq: // The exception handler for an FIQ exception
 // from the current EL using SP0.
.balign 0x80
curr_el_sp0_serror: // The exception handler for the system error
 // exception from the current EL using SP0.
.balign 0x80
curr_el_spx_sync: // The exception handler for a synchronous
 // exception from the current EL using the
// current SP.
.balign 0x80
curr_el_spx_irq: // The exception handler for an IRQ exception from
 // the current EL using the current SP.
.balign 0x80
curr_el_spx_fiq: // The exception handler for an FIQ from
 // the current EL using the current SP.
.balign 0x80
curr_el_spx_serror: // The exception handler for a System Error
 // exception from the current EL using the
// current SP.
.balign 0x80
lower_el_aarch64_sync: // The exception handler for a synchronous
 // exception from a lower EL (AArch64).
.balign 0x80
lower_el_aarch64_irq: // The exception handler for an IRQ from a lower EL
 // (AArch64).
.balign 0x80
lower_el_aarch64_fiq: // The exception handler for an FIQ from a lower EL
 // (AArch64).
.balign 0x80
lower_el_aarch64_serror: // The exception handler for a System Error
 // exception from a lower EL(AArch64).
.balign 0x80
lower_el_aarch32_sync: // The exception handler for a synchronous
 // exception from a lower EL(AArch32).
.balign 0x80
lower_el_aarch32_irq: // The exception handler for an IRQ exception
 // from a lower EL (AArch32).
.balign 0x80
lower_el_aarch32_fiq: // The exception handler for an FIQ exception from
 // a lower EL (AArch32).
.balign 0x80
lower_el_aarch32_serror: // The exception handler for a System Error
 // exception from a lower EL(AArch32)
