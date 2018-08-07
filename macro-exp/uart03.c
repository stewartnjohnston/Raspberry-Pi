
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

extern void timer_init ( void );
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

    //GETCurrentEL();  //will throw an exception at this call

    a = a + 1;
    
    while(1)
    {
    a = a + 1;
    }
    return(0);
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
