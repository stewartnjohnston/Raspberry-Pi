#ifndef	_TIMER_H
#define	_TIMER_H

unsigned int timer_init ( void );
void handle_timer_irq ( void );
void timer_set_curVal ( unsigned int x );



#endif  /*_TIMER_H */
