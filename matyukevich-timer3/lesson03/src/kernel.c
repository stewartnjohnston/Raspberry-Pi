#include "printf.h"
#include "timer.h"
#include "irq.h"
#include "mini_uart.h"

extern unsigned int timer_initx ( void );
extern void enable_interrupt_controllerx ( void );

void kernel_main(void)
{
        /*
        unsigned int i = 0;
	irq_vector_init();
	i = timer_initx();
	timer_set_curVal(i);

	enable_interrupt_controllerx();  // this does not works
	enable_irq();
        */
	uart_init();
	init_printf(0, putc);
	
        printf("crapper\n\r");


	while (1){
		uart_send(uart_recv());
	}	
}
