#include "utils.h"
#include "printf.h"
#include "peripherals/timer.h"

const unsigned int interval = 200000;
unsigned int curVal = 0;
unsigned int count = 0;
unsigned int i = 0;

void timer_set_curVal ( unsigned int x )
{
        curVal = x;
}
unsigned int timer_init ( void )
{
	unsigned int curValx = get32(TIMER_CLO);
	curValx += interval;
	put32(TIMER_C1, curVal);
	return curValx;
}

void handle_timer_irq( void ) 
{
        i++;
	count = get32(TIMER_CLO);
	curVal += interval;
	put32(TIMER_C1, curVal);
	put32(TIMER_CS, TIMER_CS_M1);
	printf("Timer interrupt received blake2 curVal=%x  i=%x count=%x\n\r",
	curVal, i, count);
}
