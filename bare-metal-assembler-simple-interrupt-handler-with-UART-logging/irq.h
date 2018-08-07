#ifndef _P_IRQ_H
#define _P_IRQ_H

#ifndef _ENTRY_H
#define _ENTRY_H

#include "base.h"

#define S_FRAME_SIZE 256 // size of all saved registers

#define SYNC_INVALID_EL1t 0
#define IRQ_INVALID_EL1t 1
#define FIQ_INVALID_EL1t 2
#define ERROR_INVALID_EL1t 3

#define SYNC_INVALID_EL1h 4
#define IRQ_INVALID_EL1h 5
#define FIQ_INVALID_EL1h 6
#define ERROR_INVALID_EL1h 7

#define SYNC_INVALID_EL0_64 8
#define IRQ_INVALID_EL0_64 9
#define FIQ_INVALID_EL0_64 10
#define ERROR_INVALID_EL0_64 11

#define SYNC_INVALID_EL0_32 12
#define IRQ_INVALID_EL0_32 13
#define FIQ_INVALID_EL0_32 14
#define ERROR_INVALID_EL0_32 15

#endif




#define IRQ_BASIC_PENDING (PBASE + 0x0000B200)
#define IRQ_PENDING_1 (PBASE + 0x0000B204)
#define IRQ_PENDING_2 (PBASE + 0x0000B208)
#define FIQ_CONTROL (PBASE + 0x0000B20C)
#define ENABLE_IRQS_1 (PBASE + 0x0000B210)
#define ENABLE_IRQS_2 (PBASE + 0x0000B214)
#define ENABLE_BASIC_IRQS (PBASE + 0x0000B218)
#define DISABLE_IRQS_1 (PBASE + 0x0000B21C)
#define DISABLE_IRQS_2 (PBASE + 0x0000B220)
#define DISABLE_BASIC_IRQS (PBASE + 0x0000B224)

#define SYSTEM_TIMER_IRQ_0 (1 << 0)
#define SYSTEM_TIMER_IRQ_1 (1 << 1)
#define SYSTEM_TIMER_IRQ_2 (1 << 2)
#define SYSTEM_TIMER_IRQ_3 (1 << 3)

#define ARM_TIMER_IRQ (1 << 0)

//void enable_interrupt_controller(void);

void irq_vector_init(void);
void enable_irq(void);
void disable_irq(void);

#endif /*_P_IRQ_H */
