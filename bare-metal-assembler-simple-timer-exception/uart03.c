
//-------------------------------------------------------------------------
//-------------------------------------------------------------------------

// 2  outer corner
// 4
// 6
// 8  TX out
// 10 RX in

extern void PUT32 ( unsigned int, unsigned int );
extern unsigned int GET32 ( unsigned int );
extern unsigned int GET64 ( unsigned int );
extern unsigned int GETPC ( void );

extern void enable_interrupt_controller ( void );
extern void enable_irq ( void );

extern unsigned int GETCurrentEL ( void );
extern void BRANCHTO ( unsigned int );
extern void dummy ( unsigned int );

extern void uart_init ( void );
extern unsigned int uart_lcr ( void );
extern void uart_flush ( void );
extern void uart_send ( unsigned int );
extern unsigned int uart_recv ( void );
extern unsigned int uart_check ( void );
extern void hexstring ( unsigned int );
extern void hexstrings ( unsigned int );
extern void uart_send_string(char *str);
extern void timer_init ( void );
extern unsigned int timer_tick ( void );


extern unsigned int timer_tick ( void );

//------------------------------------------------------------------------
int notmain ( void )
{
    unsigned int a;
    unsigned int one = 0x10;
    unsigned int two = 0x20;
    unsigned int three = 0x30;
    unsigned int changingEL = 0x50;
    
    unsigned int buff = GET32(0x10000);
    
    a = GET32(buff);
    a = GET32(buff + 4);
    a = GET32(buff + 8);
    a = GET32(buff + one);
    a = GET32(buff + one + 4);
    a = GET32(buff + one + 8);
    a = GET32(buff + two);
    a = GET32(buff + two + 4);
    a = GET32(buff + two + 8);
    a = GET32(buff + three);
    a = GET32(buff + three + 4);
    a = GET32(buff + three + 8);
    a = GET32(buff + changingEL);
    a = GET32(buff + changingEL + 4);

    
    uart_init();

    hexstring(0x12345678);
    hexstring(GETPC());

    hexstring(GET32(buff));
    hexstring(GET32(buff + 4));
    hexstring(GET32(buff + 8));
    hexstring(GET32(buff + one));
    hexstring(GET32(buff + one + 4));
    hexstring(GET32(buff + one + 8));
    hexstring(GET32(buff + two));
    hexstring(GET32(buff + two + 4));
    hexstring(GET32(buff + two + 8));
    hexstring(GET32(buff + three));
    hexstring(GET32(buff + three + 4));
    hexstring(GET32(buff + three + 8));
    
    hexstring(0x12345678);
    uart_send_string("Exception from EL3 to EL2 EL=");
    hexstring(GET32(buff + changingEL));
    uart_send_string("Exception from EL2 to EL1 EL=");
    hexstring(GET32(buff + changingEL + 4));
    hexstring(0x12345678);
    
    int b = 0;
    a = 0;

    while(1)
    {
       a = a + 1;
       if(a > 100000)
       {
            //uart_send_string("loop 1");
            hexstring(b);
            uart_flush();

            a = 0;
            b = b + 1;
            if(b > 500)
                break;
       }
    }
    
    hexstring(0x111112);
    hexstring(0x111113);
    hexstring(0x111114);
    hexstring(0x111115);
    hexstring(0x111116);
    hexstring(0x111117);
    uart_flush();


    a = 0;
    b = 0;

    while(1)
    {
       a = a + 1;
       if(a > 100000)
       {
            //uart_send_string("loop 1");
            hexstring(b);
            uart_flush();

            a = 0;
            b = b + 1;
            if(b > 500)
                break;
       }
    }

    return(0);
}

void show_invalid_entry_message(int type, unsigned long esr,
                                unsigned long address) {
    uart_send_string("show_invalid_entry_message");
    uart_send_string("type:");
    hexstring(type);
    uart_send_string("esr_el1:");
    hexstring(esr);
    uart_send_string("return address elr_el1:");
    hexstring(address);
    
    uart_flush();
}
/*  in vector.c
void enable_interrupt_controller()
{
	PUT32(ENABLE_IRQS_1, SYSTEM_TIMER_IRQ_1);
}
*/
#define PBASE 0x3F000000
#define TIMER_C1        (PBASE+0x00003010)
#define TIMER_CS        (PBASE+0x00003000)
#define TIMER_CS_M1	(1 << 1)
#define IRQ_PENDING_1		(PBASE+0x0000B204)
#define SYSTEM_TIMER_IRQ_1	(1 << 1)

#define ARM_TIMER_LOAD        (PBASE+0x0000B400)
#define ARM_TIMER_CTRL        (PBASE+0x0000B408)
#define ARM_TIMER_CLR         (PBASE+0x0000B40C)

#define CTRL_23BIT (1 << 1)      // 23-bit counter
#define CTRL_INT_ENABLE (1 << 5) // Timer interrupt enabled
#define CTRL_ENABLE (1 << 7)     // Timer enabled


void handle_timer_irq( void ) 
{
	//curVal += interval;
	PUT32(ARM_TIMER_CLR, 1);
	uart_send_string("Timer interrupt received Pogo\n\r");
}

void handle_irq(void)
{
	unsigned int irq = GET32(IRQ_PENDING_1);
	switch (irq) {
		case (SYSTEM_TIMER_IRQ_1):
			handle_timer_irq();
			break;
		default:
			uart_send_string("Unknown pending irq:");
			hexstring(irq);
	}
}

void timer_init ( void )
{
  PUT32(ARM_TIMER_LOAD, 0x0400000);
  PUT32(ARM_TIMER_CTRL, CTRL_ENABLE | CTRL_INT_ENABLE | CTRL_23BIT);
}


//-------------------------------------------------------------------------
//-------------------------------------------------------------------------


//-------------------------------------------------------------------------
//
// Copyright (c) 2014 David Welch dwelch@dwelch.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//-------------------------------------------------------------------------
