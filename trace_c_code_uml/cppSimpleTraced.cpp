/*
 *  cSimpleTraced.c
 *
 *  Copyright 2008 Aurelian Melinte. 
 *  Released under GPL 3.0 or later. 
 *
 *  Call monitoring demo. 
 */
 
#define _GNU_SOURCE  /*strerror_r*/
#include <unistd.h>  /*sleep*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>  /*strerror_r*/
#include <errno.h>
#include <assert.h>
#include <signal.h>
#include <pthread.h>

#define ERRBUF_LEN (255) 

static int  _do_exit = 0;

void
f4(int id)
{
    printf("%s %d\n", __FUNCTION__, id);
}

static inline int 
f3(int id)
{
    printf("%s %d\n", __FUNCTION__, id);
    f4(id);
    return 80;
}

int 
f2(int id)
{
    printf("%s %d\n", __FUNCTION__, id);
    f3(70+id);
    return 70;
}

static int 
f1(int id)
{
    printf("%s %d\n", __FUNCTION__, id);
    f2(60+id); 
    return 60;
}

static int 
f5(int i1,int i2,int i3,int i4,int i5, int i6, int i7, int i8, int i9, int ia, int ib, int ic)
{
    int id = i1 +  i2 + i3 + i4 + i5 + i6 + i7 + i8 + i9 + ia + ib + ic;
    printf("%s %d\n", __FUNCTION__, id);
    f2(60+id); 
    return 60;
}



static char *
wrap_strerror_r(int err, char *buf, int len)
{
    char *src = NULL;
    
    memset(buf, 0, len);
    src = strerror_r(err, buf, len); 

    return src ? src : buf; 
}



static void 
sigexit(int signo)
{
    _do_exit = 1;
}

static void 
set_signal(int signo, void (*handler)(int))
{
    struct sigaction sa;

    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = (void (*)(int))handler;
    sigaction(signo, &sa, NULL);
}

class C
{
public:
    C() {printf("C::C() this=%p \n", this);}
    C(int i): _id(i) {printf("C::C(this=%p int=%d)\n", this, _id);}
    ~C() {printf("C::~C(this=%p)\n",this);}
    
     int cf1(int i) {printf("C::cf1(this=%p)\n", this); return 21;}
    
protected:
    int _id; 
}; 


class E
{
public:
    E() {printf("E::E() this=%p \n", this);}
    E(int i): _id(i) {printf("E::E(this=%p int=%d)\n", this, _id);}
    ~E() {printf("E::~E(this=%p)\n",this);}
    
     int ef1(int i) {printf("E::ef1(this=%p)\n", this); return 21;}
    
protected:
    int _id; 
}; 


class B
{
public:
    C c;
    B() {printf("B::B() this=%p \n", this);}
    B(int i): _id(i) {printf("B::B(this=%p int=%d)\n", this, _id);}
    ~B() {printf("B::~B(this=%p)\n",this);}
    int bf1(int i) {printf("D::~df1()\n"); return c.cf1(i);}
    
    virtual int m1(int i, int j) {printf("B::m1(this=%p)\n", this); f1(i); return 20;}
    virtual int m2(int i) {printf("B::m2(this=%p)\n", this); f1(i); return 21;}
    
protected:
    int _id; 
}; 


class D : public B
{
public:
    E e;
    D() {printf("D::D() this=%p \n", this);}
    D(int i) {printf("D::D(int=%d) this=%p\n",this, _id);}
    int df1(int i) {printf("D::~df1()\n"); return e.ef1(i);}
    virtual ~D() {printf("D::~D()\n");}
    
    virtual int m1(int i, int j) {printf("D::m1()\n"); m2(j+10); return 30;}
}; 

int
main(int argc, char *argv[])
{

    set_signal(SIGINT,  sigexit);
    set_signal(SIGQUIT, sigexit);
    
    printf("%s: main(argc=%d)\n", argv[0], argc);
    
//    f5(1,2,3,4,5,6,7,8,9,10,11,12);
    
    B *b = new B(22);
    
    //b->m1(0,1);
    //b->m2(0);
    b->bf1(0);
    
    delete b;

    printf("%s: done.\n", argv[0]);
    return EXIT_SUCCESS;
}

